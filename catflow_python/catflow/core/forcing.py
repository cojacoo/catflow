"""
Atmospheric forcing for CATFLOW simulations.

Time-varying rainfall and evapotranspiration boundary conditions.
"""

import numpy as np
from scipy.interpolate import interp1d


class WeatherForcing:
    """
    Time series of atmospheric forcing (rainfall and ET).

    Provides rainfall and potential evapotranspiration at any time
    through interpolation and accumulation over timesteps.

    Parameters
    ----------
    times : array_like
        Time points [s]
    rainfall : array_like
        Rainfall intensity [m/s] at each time
    pet : array_like
        Potential evapotranspiration [m/s] at each time (positive = loss)

    Examples
    --------
    >>> # Constant rainfall for 2 days
    >>> weather = WeatherForcing.constant_rain(
    ...     rain_start=0,
    ...     rain_end=2*86400,
    ...     intensity=15e-3 / 86400  # 15 mm/day
    ... )
    >>>
    >>> # Get forcing over a timestep
    >>> rain, pet = weather.get_forcing(0, 3600)  # First hour
    """

    def __init__(self, times, rainfall, pet):
        """Initialize weather forcing from time series."""
        self.times = np.asarray(times, dtype=float)
        self.rainfall = np.asarray(rainfall, dtype=float)
        self.pet = np.asarray(pet, dtype=float)

        if len(self.times) != len(self.rainfall) or len(self.times) != len(self.pet):
            raise ValueError("times, rainfall, and pet must have same length")

        # Create interpolators
        self._rain_interp = interp1d(
            self.times, self.rainfall,
            kind='linear',
            bounds_error=False,
            fill_value=(self.rainfall[0], self.rainfall[-1])
        )

        self._pet_interp = interp1d(
            self.times, self.pet,
            kind='linear',
            bounds_error=False,
            fill_value=(self.pet[0], self.pet[-1])
        )

    def get_forcing(self, t_start, t_end):
        """
        Get integrated forcing over time interval.

        Parameters
        ----------
        t_start : float
            Start time [s]
        t_end : float
            End time [s]

        Returns
        -------
        mean_rain : float
            Mean rainfall rate [m/s] over interval
        mean_pet : float
            Mean PET rate [m/s] over interval
        """
        dt = t_end - t_start
        if dt <= 0:
            return 0.0, 0.0

        # Simple approach: evaluate at midpoint
        t_mid = 0.5 * (t_start + t_end)
        rain = float(self._rain_interp(t_mid))
        pet = float(self._pet_interp(t_mid))

        return rain, pet

    @classmethod
    def constant_rain(cls, rain_start, rain_end, intensity, pet_rate=0.0):
        """
        Create constant rainfall event.

        Parameters
        ----------
        rain_start : float
            Start time of rain [s]
        rain_end : float
            End time of rain [s]
        intensity : float
            Rainfall intensity [m/s]
        pet_rate : float, optional
            Constant PET rate outside rain period [m/s]

        Returns
        -------
        forcing : WeatherForcing
        """
        # Create time series with on/off transitions
        times = [0.0, rain_start, rain_end, rain_end + 1e6]
        rainfall = [0.0, intensity, 0.0, 0.0]
        pet = [pet_rate, 0.0, pet_rate, pet_rate]

        return cls(times, rainfall, pet)

    @classmethod
    def piecewise(cls, periods):
        """
        Create piecewise constant forcing.

        Parameters
        ----------
        periods : list of tuples
            Each tuple is (t_start, t_end, type, rate) where:
            - type is 'rain' or 'pet'
            - rate is in m/s

        Returns
        -------
        forcing : WeatherForcing

        Examples
        --------
        >>> weather = WeatherForcing.piecewise([
        ...     (0, 2*86400, 'rain', 15e-3/86400),      # 2 days rain
        ...     (2*86400, 9*86400, 'pet', 3e-3/86400)   # 7 days ET
        ... ])
        """
        # Extract all transition times
        times_set = set([0.0])
        for t_start, t_end, _, _ in periods:
            times_set.add(t_start)
            times_set.add(t_end)

        # Add far future
        max_time = max(t_end for _, t_end, _, _ in periods)
        times_set.add(max_time + 1e6)

        times = sorted(times_set)

        # Evaluate rain and pet at each time
        rainfall = []
        pet = []

        for t in times:
            rain_val = 0.0
            pet_val = 0.0

            for t_start, t_end, ftype, rate in periods:
                if t_start <= t < t_end:
                    if ftype == 'rain':
                        rain_val = rate
                    elif ftype == 'pet':
                        pet_val = rate

            rainfall.append(rain_val)
            pet.append(pet_val)

        return cls(times, rainfall, pet)

    @classmethod
    def from_daily(cls, times_days, rainfall_mm, pet_mm):
        """
        Create from daily data.

        Parameters
        ----------
        times_days : array_like
            Time in days
        rainfall_mm : array_like
            Daily rainfall [mm/day]
        pet_mm : array_like
            Daily PET [mm/day]

        Returns
        -------
        forcing : WeatherForcing
        """
        times_s = np.asarray(times_days) * 86400.0  # Convert to seconds
        rain_ms = np.asarray(rainfall_mm) * 1e-3 / 86400.0  # mm/day -> m/s
        pet_ms = np.asarray(pet_mm) * 1e-3 / 86400.0

        return cls(times_s, rain_ms, pet_ms)

    def get_total_rain(self, t_start, t_end, dt=3600.0):
        """
        Get total rainfall depth over period.

        Parameters
        ----------
        t_start : float
            Start time [s]
        t_end : float
            End time [s]
        dt : float
            Integration timestep [s]

        Returns
        -------
        total_rain : float
            Total rainfall depth [m]
        """
        times = np.arange(t_start, t_end, dt)
        total = 0.0

        for t in times:
            rain, _ = self.get_forcing(t, min(t + dt, t_end))
            total += rain * min(dt, t_end - t)

        return total

    def get_total_pet(self, t_start, t_end, dt=3600.0):
        """
        Get total potential ET depth over period.

        Parameters
        ----------
        t_start : float
            Start time [s]
        t_end : float
            End time [s]
        dt : float
            Integration timestep [s]

        Returns
        -------
        total_pet : float
            Total PET depth [m]
        """
        times = np.arange(t_start, t_end, dt)
        total = 0.0

        for t in times:
            _, pet = self.get_forcing(t, min(t + dt, t_end))
            total += pet * min(dt, t_end - t)

        return total
