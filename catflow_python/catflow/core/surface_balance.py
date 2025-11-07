"""
Surface water balance for CATFLOW simulations.

Manages ponding, infiltration, runoff, and evapotranspiration at the surface.
"""

import numpy as np


class SurfaceWaterBalance:
    """
    Surface water balance manager.

    Tracks ponded water depth, computes infiltration (limited by soil capacity),
    handles runoff, and applies ET with soil moisture stress.

    Parameters
    ----------
    mesh : CurvilinearHillslopeMesh
        Computational mesh
    max_ponding_depth : float, optional
        Maximum ponding depth before runoff occurs [m] (default: 0.05 m)
    psi_stress_start : float, optional
        Pressure head where ET stress begins [m] (default: -1.5 m)
    psi_wilting_point : float, optional
        Pressure head at wilting point [m] (default: -150 m)

    Attributes
    ----------
    ponding : ndarray
        Current ponding depth [m] at each surface node
    cumulative_rain : float
        Total rainfall received [m³]
    cumulative_infiltration : float
        Total infiltration [m³]
    cumulative_runoff : float
        Total runoff [m³]
    cumulative_et : float
        Total actual ET [m³]
    """

    def __init__(self, mesh, max_ponding_depth=0.05,
                 psi_stress_start=-1.5, psi_wilting_point=-150.0):
        """Initialize surface water balance."""
        self.mesh = mesh
        self.n_surface_nodes = mesh.shape[1]
        self.max_ponding = max_ponding_depth
        self.psi_stress = psi_stress_start
        self.psi_wilt = psi_wilting_point

        # State
        self.ponding = np.zeros(self.n_surface_nodes)

        # Cumulative fluxes
        self.cumulative_rain = 0.0
        self.cumulative_infiltration = 0.0
        self.cumulative_runoff = 0.0
        self.cumulative_et = 0.0

    def update(self, dt, rainfall, pet, infiltration_capacity,
               psi_surface, soil_width):
        """
        Update surface water balance for timestep.

        Parameters
        ----------
        dt : float
            Timestep [s]
        rainfall : float
            Rainfall rate [m/s] (uniform over domain)
        pet : float
            Potential ET rate [m/s] (uniform over domain)
        infiltration_capacity : ndarray
            Maximum infiltration rate [m/s] at each surface node
        psi_surface : ndarray
            Current pressure head at surface [m] at each node
        soil_width : ndarray
            Width of hillslope [m] at each surface node

        Returns
        -------
        bc_flux : ndarray
            Actual flux to apply as top BC [m/s] (+ = into soil, - = out)
        total_runoff : float
            Total surface runoff [m³/s]
        total_actual_et : float
            Total actual ET [m³/s]

        Notes
        -----
        The water balance is:
        1. Add rainfall to ponding
        2. Infiltrate up to capacity (limited by ponding)
        3. Generate runoff if ponding exceeds threshold
        4. Apply ET from soil (reduced when dry, zero if ponded)
        """
        bc_flux = np.zeros(self.n_surface_nodes)

        # 1. Add rainfall to ponding
        rain_depth = rainfall * dt
        self.ponding += rain_depth

        # Track rainfall
        rain_volume = np.sum(rain_depth * soil_width)
        self.cumulative_rain += rain_volume

        # 2. Infiltration (limited by both capacity and available ponding)
        # Infiltration rate cannot exceed ponding availability
        infiltration_rate = np.minimum(
            infiltration_capacity,
            self.ponding / dt
        )

        # Apply infiltration
        infiltration_depth = infiltration_rate * dt
        self.ponding = np.maximum(0.0, self.ponding - infiltration_depth)

        # Infiltration goes into soil (positive flux)
        bc_flux += infiltration_rate

        # Track infiltration
        infil_volume = np.sum(infiltration_depth * soil_width)
        self.cumulative_infiltration += infil_volume

        # 3. Runoff when ponding exceeds threshold
        excess_depth = np.maximum(0.0, self.ponding - self.max_ponding)
        runoff_volume = np.sum(excess_depth * soil_width)
        total_runoff = runoff_volume / dt

        # Remove runoff from ponding
        self.ponding = np.minimum(self.ponding, self.max_ponding)

        # Track runoff
        self.cumulative_runoff += runoff_volume

        # 4. Evapotranspiration (only where no ponding)
        # Compute ET capacity with soil moisture stress
        et_stress = self._compute_et_stress(psi_surface)
        actual_et_rate = pet * et_stress

        # Only apply ET where there's no ponding
        no_ponding = self.ponding < 1e-6
        actual_et_rate = np.where(no_ponding, actual_et_rate, 0.0)

        # ET removes water from soil (negative flux)
        bc_flux -= actual_et_rate

        # Track ET
        et_volume = np.sum(actual_et_rate * dt * soil_width)
        total_actual_et = et_volume / dt
        self.cumulative_et += et_volume

        return bc_flux, total_runoff, total_actual_et

    def _compute_et_stress(self, psi_surface):
        """
        Compute ET stress factor based on soil moisture.

        ET is reduced linearly from field capacity to wilting point:
        - psi > psi_stress_start: no stress (factor = 1.0)
        - psi < psi_wilting: full stress (factor = 0.0)
        - Between: linear interpolation

        Parameters
        ----------
        psi_surface : ndarray
            Pressure head at surface [m]

        Returns
        -------
        stress_factor : ndarray
            Stress reduction factor (0 to 1)
        """
        stress = (psi_surface - self.psi_wilt) / (self.psi_stress - self.psi_wilt)
        return np.clip(stress, 0.0, 1.0)

    def get_water_balance(self):
        """
        Get cumulative water balance.

        Returns
        -------
        balance : dict
            Dictionary with keys:
            - 'rain': Total rainfall [m³]
            - 'infiltration': Total infiltration [m³]
            - 'runoff': Total runoff [m³]
            - 'et': Total ET [m³]
            - 'balance_error': Imbalance [m³]
        """
        balance_error = (self.cumulative_rain -
                        self.cumulative_infiltration -
                        self.cumulative_runoff)

        return {
            'rain': self.cumulative_rain,
            'infiltration': self.cumulative_infiltration,
            'runoff': self.cumulative_runoff,
            'et': self.cumulative_et,
            'balance_error': balance_error
        }

    def reset(self):
        """Reset state and cumulative fluxes."""
        self.ponding[:] = 0.0
        self.cumulative_rain = 0.0
        self.cumulative_infiltration = 0.0
        self.cumulative_runoff = 0.0
        self.cumulative_et = 0.0


def compute_infiltration_capacity(psi_surface, Ks, theta_s, theta_r, alpha, n):
    """
    Compute maximum infiltration rate based on current soil state.

    Uses Van Genuchten hydraulic conductivity at current saturation.

    Parameters
    ----------
    psi_surface : ndarray
        Pressure head at surface [m]
    Ks : ndarray
        Saturated hydraulic conductivity [m/s]
    theta_s : float or ndarray
        Saturated water content [-]
    theta_r : float or ndarray
        Residual water content [-]
    alpha : float or ndarray
        Van Genuchten alpha parameter [1/m]
    n : float or ndarray
        Van Genuchten n parameter [-]

    Returns
    -------
    infiltration_capacity : ndarray
        Maximum infiltration rate [m/s]

    Notes
    -----
    For saturated or ponded conditions (psi >= 0), capacity = Ks.
    For unsaturated conditions, capacity = Ks * K_r(psi) where K_r
    is the relative conductivity from Van Genuchten model.
    """
    # Van Genuchten effective saturation
    m = 1.0 - 1.0 / n

    # For unsaturated: Se = [1 + (alpha * |psi|)^n]^(-m)
    # For saturated: Se = 1
    Se = np.where(
        psi_surface < 0,
        np.power(1.0 + np.power(alpha * np.abs(psi_surface), n), -m),
        1.0
    )

    # Mualem-Van Genuchten relative conductivity
    # K_r = Se^L * [1 - (1 - Se^(1/m))^m]^2
    # With L = 0.5 (standard Mualem value)
    L = 0.5
    term = 1.0 - np.power(Se, 1.0 / m)
    Kr = np.power(Se, L) * np.power(1.0 - np.power(term, m), 2.0)

    # Capacity is Ks * Kr
    # For saturated (psi >= 0), Kr = 1, so capacity = Ks
    capacity = Ks * Kr

    return capacity
