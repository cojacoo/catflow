"""
Abstract base class for soil hydraulic models.

Defines the interface for all soil water retention and hydraulic
conductivity models used in CATFLOW.
"""

from abc import ABC, abstractmethod
import numpy as np


class SoilHydraulicModel(ABC):
    """
    Abstract base class for soil hydraulic models.

    Soil hydraulic models define the relationships between:
    - Pressure head (ψ) and water content (θ)
    - Water content (θ) and hydraulic conductivity (K)
    - Specific moisture capacity C = dθ/dψ

    Examples of implementations include Van Genuchten, Brooks-Corey,
    or custom user-defined relationships.
    """

    @abstractmethod
    def theta_from_psi(self, psi, params):
        """
        Calculate water content from pressure head.

        This is the soil water retention curve θ(ψ).

        Parameters
        ----------
        psi : np.ndarray
            Pressure head [m]
        params : dict
            Dictionary of soil parameters specific to the model.
            Common parameters include:
            - theta_s: Saturated water content [-]
            - theta_r: Residual water content [-]
            Plus model-specific parameters

        Returns
        -------
        theta : np.ndarray
            Volumetric water content [-], same shape as psi
        """
        pass

    @abstractmethod
    def K_from_theta(self, theta, params):
        """
        Calculate hydraulic conductivity from water content.

        This is the unsaturated hydraulic conductivity function K(θ).

        Parameters
        ----------
        theta : np.ndarray
            Volumetric water content [-]
        params : dict
            Dictionary of soil parameters, must include:
            - Ks: Saturated hydraulic conductivity [m/s]
            Plus model-specific parameters

        Returns
        -------
        K : np.ndarray
            Hydraulic conductivity [m/s], same shape as theta
        """
        pass

    @abstractmethod
    def capacity(self, psi, params):
        """
        Calculate specific moisture capacity.

        This is C = dθ/dψ, needed for the Richards equation.

        Parameters
        ----------
        psi : np.ndarray
            Pressure head [m]
        params : dict
            Dictionary of soil parameters

        Returns
        -------
        C : np.ndarray
            Specific moisture capacity [1/m], same shape as psi
        """
        pass

    def K_from_psi(self, psi, params):
        """
        Calculate hydraulic conductivity from pressure head.

        Convenience method that combines theta_from_psi and K_from_theta.

        Parameters
        ----------
        psi : np.ndarray
            Pressure head [m]
        params : dict
            Dictionary of soil parameters

        Returns
        -------
        K : np.ndarray
            Hydraulic conductivity [m/s]
        """
        theta = self.theta_from_psi(psi, params)
        return self.K_from_theta(theta, params)

    def effective_saturation(self, theta, params):
        """
        Calculate effective saturation.

        Se = (θ - θ_r) / (θ_s - θ_r)

        Parameters
        ----------
        theta : np.ndarray
            Volumetric water content [-]
        params : dict
            Must contain 'theta_s' and 'theta_r'

        Returns
        -------
        Se : np.ndarray
            Effective saturation [-], range [0, 1]
        """
        theta_s = params['theta_s']
        theta_r = params['theta_r']
        Se = (theta - theta_r) / (theta_s - theta_r)
        return np.clip(Se, 0.0, 1.0)
