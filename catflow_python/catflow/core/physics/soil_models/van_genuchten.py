"""
Van Genuchten-Mualem soil hydraulic model.

Implements the widely-used Van Genuchten (1980) water retention model
combined with the Mualem (1976) hydraulic conductivity model.
"""

import numpy as np
from catflow.core.physics.soil_models.base import SoilHydraulicModel


class VanGenuchten(SoilHydraulicModel):
    """
    Van Genuchten-Mualem soil hydraulic model.

    Water retention:
        Se = [1 + (α|ψ|)^n]^(-m)
        θ(ψ) = θ_r + (θ_s - θ_r) * Se

    Hydraulic conductivity:
        K(Se) = Ks * Se^L * [1 - (1 - Se^(1/m))^m]^2

    where:
        m = 1 - 1/n
        L = 0.5 (pore connectivity parameter)

    Parameters Required
    -------------------
    theta_s : float
        Saturated water content [-]
    theta_r : float
        Residual water content [-]
    alpha : float
        Van Genuchten parameter [1/m]
    n : float
        Van Genuchten parameter [-], n > 1
    Ks : float
        Saturated hydraulic conductivity [m/s]
    L : float, optional
        Pore connectivity parameter [-], default 0.5

    References
    ----------
    Van Genuchten, M. Th. (1980). A closed-form equation for predicting
    the hydraulic conductivity of unsaturated soils. Soil Science Society
    of America Journal, 44(5), 892-898.
    """

    def __init__(self, L=0.5):
        """
        Initialize Van Genuchten model.

        Parameters
        ----------
        L : float, optional
            Pore connectivity parameter, default 0.5
        """
        self.L = L

    def theta_from_psi(self, psi, params):
        """
        Calculate water content from pressure head.

        Parameters
        ----------
        psi : np.ndarray
            Pressure head [m]
        params : dict
            Must contain: theta_s, theta_r, alpha, n

        Returns
        -------
        theta : np.ndarray
            Volumetric water content [-]
        """
        theta_s = params['theta_s']
        theta_r = params['theta_r']
        alpha = params['alpha']
        n = params['n']

        m = 1.0 - 1.0 / n

        # Ensure psi is array
        psi = np.atleast_1d(psi)

        # Calculate effective saturation
        Se = np.where(
            psi >= 0.0,
            1.0,  # Saturated
            (1.0 + (alpha * np.abs(psi))**n)**(-m)
        )

        # Calculate water content
        theta = theta_r + (theta_s - theta_r) * Se

        return theta

    def K_from_theta(self, theta, params):
        """
        Calculate hydraulic conductivity from water content.

        Parameters
        ----------
        theta : np.ndarray
            Volumetric water content [-]
        params : dict
            Must contain: theta_s, theta_r, Ks, n

        Returns
        -------
        K : np.ndarray
            Hydraulic conductivity [m/s]
        """
        theta_s = params['theta_s']
        theta_r = params['theta_r']
        Ks = params['Ks']
        n = params['n']

        m = 1.0 - 1.0 / n

        # Ensure theta is array
        theta = np.atleast_1d(theta)

        # Calculate effective saturation
        Se = (theta - theta_r) / (theta_s - theta_r)
        Se = np.clip(Se, 0.0, 1.0)

        # Van Genuchten-Mualem conductivity
        # K = Ks * Se^L * [1 - (1 - Se^(1/m))^m]^2
        term = 1.0 - Se**(1.0/m)
        term = np.clip(term, 0.0, 1.0)  # Avoid numerical issues

        K = Ks * Se**self.L * (1.0 - term**m)**2

        # Avoid very small negative values from numerical errors
        K = np.maximum(K, 0.0)

        return K

    def capacity(self, psi, params):
        """
        Calculate specific moisture capacity C = dθ/dψ.

        Parameters
        ----------
        psi : np.ndarray
            Pressure head [m]
        params : dict
            Must contain: theta_s, theta_r, alpha, n

        Returns
        -------
        C : np.ndarray
            Specific moisture capacity [1/m]
        """
        theta_s = params['theta_s']
        theta_r = params['theta_r']
        alpha = params['alpha']
        n = params['n']

        m = 1.0 - 1.0 / n

        # Ensure psi is array
        psi = np.atleast_1d(psi)

        # C = 0 for saturated conditions
        C = np.zeros_like(psi)

        # For unsaturated conditions (psi < 0)
        mask = psi < 0.0
        if np.any(mask):
            psi_unsat = psi[mask]
            abs_psi = np.abs(psi_unsat)

            # Calculate derivative
            # Se = [1 + (α|ψ|)^n]^(-m)
            # dSe/dψ = -m * [1 + (α|ψ|)^n]^(-m-1) * n * (α|ψ|)^(n-1) * α * (-1)
            #        = m * n * α^n * |ψ|^(n-1) / [1 + (α|ψ|)^n]^(m+1)

            term = (alpha * abs_psi)**n
            dSe_dpsi = (m * n * alpha**n * abs_psi**(n-1)) / (1.0 + term)**(m+1)

            # C = dθ/dψ = (θ_s - θ_r) * dSe/dψ
            C[mask] = (theta_s - theta_r) * dSe_dpsi

        return C

    def get_parameters_dict(self, theta_s, theta_r, alpha, n, Ks):
        """
        Create parameter dictionary.

        Convenience method to create properly formatted parameter dict.

        Parameters
        ----------
        theta_s : float
            Saturated water content [-]
        theta_r : float
            Residual water content [-]
        alpha : float
            Van Genuchten parameter [1/m]
        n : float
            Van Genuchten parameter [-]
        Ks : float
            Saturated hydraulic conductivity [m/s]

        Returns
        -------
        params : dict
            Parameter dictionary
        """
        return {
            'theta_s': theta_s,
            'theta_r': theta_r,
            'alpha': alpha,
            'n': n,
            'Ks': Ks
        }
