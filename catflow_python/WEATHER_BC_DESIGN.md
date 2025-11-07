# Time-Varying Weather Boundary Conditions - Design Document

**Date**: 2025-11-03
**Issue**: Static boundary conditions incompatible with realistic weather forcing

---

## Problem Statement

Current CATFLOW implementation uses static boundary conditions set at model initialization. This prevents:
1. Time-varying rainfall and evapotranspiration
2. Realistic surface water balance
3. Infiltration capacity limits
4. Surface ponding and runoff

**Example of current flaw**:
```python
# This BC never changes during simulation!
bc = {
    'top': {'type': 'neumann', 'value': -rainfall_rate},  # Fixed forever
    'bottom': {'type': 'dirichlet', 'value': -2.5}
}
```

---

## Design Goals

1. **Time-varying forcing**: Weather data (rainfall, ET) varies with time
2. **Surface water balance**: Track ponding, infiltration capacity, runoff
3. **Adaptive timesteps**: Weather forcing must work with dynamic dt
4. **Physical realism**: Respect soil hydraulic limits, capillary gradients
5. **Simple API**: Easy to use for common scenarios

---

## Proposed Architecture

### 1. Weather Forcing Class

```python
class WeatherForcing:
    """
    Time series of atmospheric forcing.

    Provides rainfall and potential evapotranspiration at any time
    through interpolation/accumulation.
    """

    def __init__(self, times, rainfall, pet):
        """
        Parameters
        ----------
        times : array_like
            Time points [s]
        rainfall : array_like
            Rainfall intensity [m/s] at each time
        pet : array_like
            Potential ET [m/s] at each time (positive = loss from soil)
        """

    def get_forcing(self, t_start, t_end):
        """
        Get integrated forcing over time interval.

        Returns
        -------
        total_rain : float
            Total rainfall depth [m] over interval
        mean_pet : float
            Mean PET rate [m/s] over interval
        """
```

**Simple constructors for common cases**:
```python
# Constant rainfall for period
weather = WeatherForcing.constant_rain(
    rain_start=0,
    rain_end=2*86400,  # 2 days
    intensity=15e-3 / 86400  # 15 mm/day in m/s
)

# Daily weather data
weather = WeatherForcing.from_daily(
    dates=['2025-01-01', '2025-01-02', ...],
    rainfall_mm=[15, 20, 0, 0, ...],
    pet_mm=[2, 2, 3, 3, ...]
)

# Hourly data from file
weather = WeatherForcing.from_file('weather.csv')
```

---

### 2. Surface Water Balance Manager

```python
class SurfaceWaterBalance:
    """
    Manages surface ponding and infiltration/ET.

    Tracks:
    - Ponded water depth on surface
    - Actual infiltration (limited by soil)
    - Surface runoff
    - Actual evapotranspiration
    """

    def __init__(self, mesh, max_ponding_depth=0.05):
        """
        Parameters
        ----------
        max_ponding_depth : float
            Maximum ponding before runoff occurs [m]
        """
        self.ponding = np.zeros(mesh.shape[1])  # Depth per column
        self.max_ponding = max_ponding_depth

    def update(self, dt, rainfall, pet, infiltration_capacity, psi_surface):
        """
        Update surface water balance for timestep.

        Parameters
        ----------
        dt : float
            Timestep [s]
        rainfall : float
            Rainfall rate [m/s]
        pet : float
            Potential ET rate [m/s]
        infiltration_capacity : array
            Max infiltration rate [m/s] for each surface node
        psi_surface : array
            Current pressure head at surface [m]

        Returns
        -------
        bc_flux : array
            Actual flux to apply as BC [m/s] (+ = into soil)
        runoff : float
            Surface runoff rate [m/s]
        actual_et : float
            Actual ET rate [m/s]
        """

        # Initialize BC flux
        bc_flux = np.zeros_like(self.ponding)

        # Add rainfall to ponding
        self.ponding += rainfall * dt

        # Infiltration (limited by capacity and ponding availability)
        infiltration = np.minimum(infiltration_capacity, self.ponding / dt)
        self.ponding -= infiltration * dt
        bc_flux += infiltration  # Positive = into soil

        # Runoff if ponding exceeds threshold
        excess = np.maximum(0, self.ponding - self.max_ponding)
        runoff = np.mean(excess) / dt
        self.ponding -= excess

        # Evapotranspiration (only if no ponding)
        # Limit ET by soil moisture availability
        et_capacity = self._compute_et_capacity(psi_surface, pet)
        actual_et = np.where(self.ponding < 1e-6, et_capacity, 0.0)
        bc_flux -= actual_et  # Negative = out of soil

        return bc_flux, runoff, actual_et

    def _compute_et_capacity(self, psi_surface, pet):
        """
        Reduce ET when soil is dry.

        Uses simple stress function:
        - psi > -1.5 m: full ET
        - psi < -150 m (wilting): no ET
        - linear reduction between
        """
        psi_field = -1.5  # Field capacity
        psi_wilt = -150.0  # Wilting point

        stress = np.clip((psi_surface - psi_wilt) / (psi_field - psi_wilt), 0, 1)
        return pet * stress
```

---

### 3. Infiltration Capacity Calculation

```python
def compute_infiltration_capacity(psi_surface, Ks, theta_s, theta_r, alpha, n):
    """
    Estimate maximum infiltration rate based on soil properties.

    Uses Green-Ampt approximation or direct from K(psi).

    For unsaturated surface:
        i_max ≈ Ks * (1 + |psi| * (theta_s - theta) / depth)

    For saturated/ponded surface:
        i_max ≈ Ks (conductivity limit)
    """
    # Simple approach: use hydraulic conductivity at current saturation
    Se = compute_effective_saturation(psi_surface, alpha, n)
    Kr = relative_conductivity(Se, n)  # Van Genuchten K_r(Se)

    return Ks * Kr
```

---

### 4. Modified Richards2D Equation

**Current**:
```python
class Richards2D:
    def __init__(self, mesh, soil_model, boundary_conditions):
        self.bc = boundary_conditions  # STATIC - PROBLEM!
```

**New**:
```python
class Richards2D:
    def __init__(self, mesh, soil_model, boundary_conditions=None):
        self.bc = boundary_conditions  # Can be None for dynamic BC

    def apply_boundary_conditions(self, A, b, psi, bc_override=None):
        """
        Apply boundary conditions to system.

        Parameters
        ----------
        bc_override : dict, optional
            Override default BC for this timestep
            Format: {'top': flux_array, 'bottom': psi_value, ...}
        """
        bc = bc_override if bc_override is not None else self.bc

        # Apply top BC (can be spatially variable flux array)
        if 'top' in bc:
            if isinstance(bc['top'], dict):
                # Old format: {'type': 'neumann', 'value': scalar}
                self._apply_static_bc(A, b, 'top', bc['top'])
            else:
                # New format: flux array
                self._apply_flux_array(A, b, 'top', bc['top'])
```

---

### 5. Modified CatflowModel

```python
class CatflowModel:
    def __init__(self, mesh, soil_model, soil_params, equation,
                 time_stepper, initial_conditions,
                 weather_forcing=None,  # NEW
                 surface_balance=None):  # NEW

        self.weather = weather_forcing
        self.surface = surface_balance or SurfaceWaterBalance(mesh)

        # Mass balance tracking
        self.cumulative_rain = 0.0
        self.cumulative_et = 0.0
        self.cumulative_runoff = 0.0
        self.cumulative_infiltration = 0.0

    def run(self, t_start, t_end, dt_initial, ...):
        """Run with time-varying weather."""

        while self.current_time < t_end:
            # Get weather forcing for this timestep
            if self.weather is not None:
                rain, pet = self.weather.get_forcing(
                    self.current_time,
                    self.current_time + dt
                )

                # Compute infiltration capacity from current state
                psi_surface = self.psi[0, :]  # Top row
                Ks_surface = self.soil_params['Ks'][0, :]

                infil_cap = compute_infiltration_capacity(
                    psi_surface, Ks_surface,
                    self.soil_params['theta_s'],
                    self.soil_params['theta_r'],
                    self.soil_params['alpha'],
                    self.soil_params['n']
                )

                # Update surface water balance
                bc_flux, runoff, actual_et = self.surface.update(
                    dt, rain, pet, infil_cap, psi_surface
                )

                # Create dynamic BC for this timestep
                bc_override = {
                    'top': bc_flux,  # Spatially variable flux
                    'bottom': self.equation.bc['bottom']  # Keep original
                }

                # Update mass balance
                self.cumulative_rain += np.sum(rain) * dt * self.mesh.area
                self.cumulative_et += np.sum(actual_et) * dt * self.mesh.area
                self.cumulative_runoff += runoff * dt * self.mesh.area
                self.cumulative_infiltration += np.sum(bc_flux) * dt * self.mesh.area

            else:
                bc_override = None  # Use static BC

            # Solve timestep with dynamic BC
            psi_new, converged, n_iter = self.time_stepper.step(
                self.equation,
                self.psi,
                self.current_time,
                dt,
                self.soil_params,
                bc_override=bc_override  # NEW parameter
            )

            # ... rest of time loop
```

---

### 6. Modified Time Stepper

```python
class PicardIteration:
    def step(self, equation, psi_old, t, dt, soil_params, bc_override=None):
        """
        Solve one timestep with optional BC override.

        Parameters
        ----------
        bc_override : dict, optional
            Override boundary conditions for this step
        """

        for iteration in range(self.max_iterations):
            # Assemble system
            A, b = equation.assemble(psi_old, dt, soil_params)

            # Apply BC (possibly overridden)
            equation.apply_boundary_conditions(A, b, psi_old, bc_override)

            # Solve
            psi_new = self.linear_solver.solve(A, b)

            # Check convergence
            # ...
```

---

## Implementation Plan

### Phase 1: Core Weather Infrastructure (Priority 1)

1. **Create `catflow/core/forcing.py`**:
   - `WeatherForcing` class with interpolation
   - Simple constructors (constant_rain, from_daily, etc.)
   - Tests for interpolation/accumulation

2. **Create `catflow/core/surface_balance.py`**:
   - `SurfaceWaterBalance` class
   - Ponding tracking
   - Infiltration capacity calculation
   - ET stress function

### Phase 2: Model Integration (Priority 1)

3. **Modify `catflow/core/equations.py`**:
   - Add `bc_override` parameter to `apply_boundary_conditions()`
   - Support spatially variable flux arrays
   - Backward compatible with static BC

4. **Modify `catflow/core/time_stepping.py`**:
   - Add `bc_override` to `step()` signature
   - Pass to equation assembly

5. **Modify `catflow/core/model.py`**:
   - Add `weather_forcing` and `surface_balance` parameters
   - Update BC each timestep in main loop
   - Track mass balance (rain, ET, runoff, infiltration)

### Phase 3: Examples and Documentation (Priority 2)

6. **Create example**: `examples/rainfall_with_weather.py`
   - 2 days rain + 7 days ET
   - Show proper water balance
   - Demonstrate API

7. **Update documentation**:
   - Weather forcing guide
   - Surface balance explanation
   - Migration guide from static BC

### Phase 4: Advanced Features (Priority 3)

8. **Surface routing** (optional):
   - 1D shallow water along hillslope
   - Lateral redistribution of ponded water
   - Coupled with subsurface

9. **Snow module** (optional):
   - Snow accumulation/melt
   - Additional surface storage

---

## API Examples

### Simple rainfall event

```python
# Define weather: 2 days rain, 7 days ET
weather = WeatherForcing.piecewise([
    (0,      2*86400, 'rain', 15e-3/86400),  # 2 days @ 15 mm/day
    (2*86400, 9*86400, 'pet',   3e-3/86400)   # 7 days @ 3 mm/day ET
])

# Create model with weather
model = CatflowModel(
    mesh=mesh,
    soil_model=soil_model,
    soil_params=params,
    equation=equation,
    time_stepper=stepper,
    initial_conditions=psi_init,
    weather_forcing=weather  # NEW
)

# Run - BC updates automatically
results = model.run(t_start=0, t_end=9*86400, ...)

# Check water balance
print(f"Rain:         {model.cumulative_rain:.3f} m³")
print(f"Infiltration: {model.cumulative_infiltration:.3f} m³")
print(f"Runoff:       {model.cumulative_runoff:.3f} m³")
print(f"ET:           {model.cumulative_et:.3f} m³")
print(f"Storage Δ:    {model.cumulative_infiltration - model.cumulative_et:.3f} m³")
```

### Daily weather data

```python
weather = WeatherForcing.from_daily(
    dates=pd.date_range('2025-01-01', periods=30),
    rainfall_mm=[15, 20, 5, 0, 0, 10, ...],  # Daily rain
    pet_mm=[2, 2, 3, 3, 4, 3, ...]            # Daily PET
)
```

### Hourly weather from file

```python
# CSV with columns: time, rainfall_mm_hr, pet_mm_hr
weather = WeatherForcing.from_csv(
    'weather_hourly.csv',
    time_col='time',
    rain_col='rainfall_mm_hr',
    pet_col='pet_mm_hr'
)
```

---

## Benefits

1. **Physical realism**: Proper surface water balance, infiltration limits
2. **Flexible**: Easy to specify weather scenarios
3. **Mass conservative**: Tracks all fluxes
4. **Backward compatible**: Can still use static BC if no weather provided
5. **Extensible**: Easy to add snow, interception, etc.

---

## Testing Strategy

1. **Unit tests**:
   - WeatherForcing interpolation
   - SurfaceWaterBalance ponding logic
   - Infiltration capacity calculation

2. **Integration tests**:
   - Constant rain vs old static BC (should match)
   - Mass balance closure (rain = infiltration + runoff)
   - ET reduces soil moisture

3. **Benchmarks**:
   - Compare with analytical solutions (Green-Ampt)
   - Compare with observations if available

---

## Migration from Current Code

**Old approach** (static BC):
```python
bc = {
    'top': {'type': 'neumann', 'value': -rainfall_rate},
    'bottom': {'type': 'dirichlet', 'value': -2.5}
}
equation = Richards2D(mesh, soil_model, bc)
model = CatflowModel(..., equation=equation, ...)
```

**New approach** (dynamic weather):
```python
# Bottom BC still static
bc = {
    'bottom': {'type': 'dirichlet', 'value': -2.5}
}
equation = Richards2D(mesh, soil_model, bc)

# Add weather forcing
weather = WeatherForcing.constant_rain(...)
model = CatflowModel(..., equation=equation, weather_forcing=weather)
```

**Backward compatible**: If no `weather_forcing` provided, uses old static BC behavior.

---

## Next Steps

1. Review and approve this design
2. Implement Phase 1 (weather infrastructure)
3. Implement Phase 2 (model integration)
4. Create examples demonstrating proper rainfall + ET
5. Update all existing examples

---

**END OF DESIGN DOCUMENT**
