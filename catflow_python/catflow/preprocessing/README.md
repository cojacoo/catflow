# CATFLOW Preprocessing Tools

Python implementation of the `preprocessing_RCatflow` package for creating hillslope geometries, soil layers, and macropore structures for CATFLOW simulations.

## Overview

This module provides comprehensive tools for setting up CATFLOW simulations, including:

- **Hillslope geometry creation** with various curvature types
- **Fine simulation grids** for high-resolution macropore simulation
- **Random walk macropore simulation** with layer-specific properties
- **Multi-layer soil profiles** with standard or custom hydraulic parameters
- **Discretization tools** for mapping to CATFLOW meshes
- **Visualization functions** for all components

## Installation

The preprocessing tools are part of the `catflow` package:

```python
from catflow.preprocessing import (
    create_hillslope_profile,
    make_simgrid,
    simulate_macropores,
    create_soil_layers,
    assign_soil_properties,
    plot_hillslope,
    plot_macropores,
    plot_soil_layers
)
```

## Quick Start

### 1. Create Hillslope Profile

```python
from catflow.preprocessing import create_hillslope_profile

# Simple linear hillslope
profile = create_hillslope_profile(
    length=50.0,          # 50 m long
    slope_angle=10,       # 10° average slope
    curvature='linear',   # straight slope
    width=2.0,            # 2 m wide
    n_points=20
)
```

**Available curvature types**:
- `'linear'`: Straight slope
- `'convex'`: Steep top, gentle bottom
- `'concave'`: Gentle top, steep bottom
- `'complex'`: Sinusoidal variation (realistic)

### 2. Create Fine Simulation Grid

```python
from catflow.preprocessing import make_simgrid

# High-resolution grid for macropore simulation
simgrid = make_simgrid(
    profile=profile,
    depth=3.0,         # 3 m deep
    dx_max=0.1,        # 10 cm horizontal
    dz_max=0.05        # 5 cm vertical
)

print(f"Grid: {simgrid['shape']}")  # (nz, nx)
```

### 3. Define Soil Layers

```python
from catflow.preprocessing import (
    create_soil_layers,
    assign_soil_properties,
    get_standard_soils
)

# Two-layer system
layer_boundaries = [
    {'type': 'depth', 'value': 1.0, 'name': 'topsoil_bottom'}
]

layer_indices = create_soil_layers(simgrid['z'], layer_boundaries)

# Use standard soil types
soils = get_standard_soils()
soil_types = {
    0: soils['sandy_loam'],    # Upper 0-1 m
    1: soils['clay_loam']      # Lower 1-3 m
}

soil_props = assign_soil_properties(layer_indices, soil_types)
```

**Available standard soils** (from Carsel & Parrish 1988):
- `sand`, `loamy_sand`, `sandy_loam`
- `loam`, `silt_loam`
- `sandy_clay_loam`, `clay_loam`, `silty_clay_loam`
- `sandy_clay`, `silty_clay`, `clay`

### 4. Simulate Macropores

```python
from catflow.preprocessing import simulate_macropores

# Vertical macropores with random walk
macropores = simulate_macropores(
    simgrid=simgrid,
    n_pores_per_m2=5,              # 5 per m²
    mean_length=1.5,               # Average 1.5 m long
    std_length=0.4,                # Std dev 0.4 m
    p_lateral=0.2,                 # 20% lateral step probability
    min_separation=10,             # 10 cells minimum apart
    conductivity_multiplier=3.0,   # 3× K in macropores
    seed=42                        # Reproducible
)

print(f"Simulated {macropores['n_pores']} macropores")
```

**Layer-specific macropore properties**:

```python
# Different properties in each layer
layer_depths = [1.0]  # boundary at 1m
layer_props = [
    {'p_lateral': 0.1, 'conductivity': 1e-5},  # upper: vertical
    {'p_lateral': 0.3, 'conductivity': 1e-6}   # lower: tortuous
]

macropores = simulate_macropores(
    simgrid,
    layer_depths=layer_depths,
    layer_properties=layer_props,
    ...
)
```

### 5. Discretize for CATFLOW

```python
from catflow.preprocessing import (
    discretize_for_catflow,
    map_macropores_to_coarse_grid
)

# Create coarse CATFLOW mesh
discretization = discretize_for_catflow(
    simgrid=simgrid,
    n_xsi=51,           # 51 nodes laterally
    n_eta=31,           # 31 nodes vertically
    method='adaptive'   # Finer near boundaries
)

# Map macropores to coarse grid
coarse_macropores = map_macropores_to_coarse_grid(
    macropores, simgrid, discretization
)
```

### 6. Visualize

```python
from catflow.preprocessing import (
    plot_hillslope,
    plot_macropores,
    plot_soil_layers,
    plot_combined_overview
)

# Individual plots
plot_hillslope(profile, simgrid)
plot_macropores(simgrid, macropores)
plot_soil_layers(simgrid, layer_indices, soil_props)

# Comprehensive overview
plot_combined_overview(
    profile, simgrid, layer_indices,
    macropores, soil_props
)
```

## Complete Example

See `examples/demo_hillslope_preprocessing.ipynb` for a full worked example including:
- Two-layer hillslope creation
- Macropore simulation
- CATFLOW model setup
- Running simulation
- Results analysis

## API Reference

### Hillslope Functions

#### `create_hillslope_profile(length, slope_angle, curvature, width, n_points)`

Create hillslope surface profile.

**Parameters**:
- `length` (float): Horizontal length [m]
- `slope_angle` (float): Average slope angle [degrees]
- `curvature` (str): 'linear', 'convex', 'concave', or 'complex'
- `width` (float or array): Hillslope width [m]
- `n_points` (int): Number of points defining profile

**Returns**: dict with keys `x`, `y`, `z`, `width`

#### `make_simgrid(profile, depth, dx_max, dz_max)`

Create fine Cartesian simulation grid.

**Parameters**:
- `profile` (dict): From `create_hillslope_profile`
- `depth` (float): Depth below surface [m]
- `dx_max` (float): Maximum horizontal resolution [m]
- `dz_max` (float): Maximum vertical resolution [m]

**Returns**: dict with keys `x`, `z`, `width`, `dx`, `dz`, `shape`

#### `discretize_for_catflow(simgrid, n_xsi, n_eta, method)`

Create CATFLOW discretization from fine grid.

**Parameters**:
- `simgrid` (dict): From `make_simgrid`
- `n_xsi` (int): Number of lateral nodes
- `n_eta` (int): Number of vertical nodes
- `method` (str): 'uniform' or 'adaptive'

**Returns**: dict with keys `xsi`, `eta`, `x_nodes`, `z_nodes`

### Macropore Functions

#### `simulate_macropores(simgrid, n_pores_per_m2, mean_length, std_length, p_lateral, ...)`

Simulate vertical macropores using random walk.

**Parameters**:
- `simgrid` (dict): From `make_simgrid`
- `n_pores_per_m2` (float): Average number per m²
- `mean_length` (float): Mean vertical length [m]
- `std_length` (float): Standard deviation [m]
- `p_lateral` (float): Probability of lateral step
- `min_separation` (int): Minimum cell separation
- `conductivity_multiplier` (float): K multiplier in macropores
- `layer_depths` (list): Layer boundaries for multi-layer [m]
- `layer_properties` (list): Properties per layer
- `seed` (int): Random seed

**Returns**: dict with keys `multiplier`, `n_pores`, `lengths`, `positions`

#### `map_macropores_to_coarse_grid(macropores, simgrid, discretization)`

Map macropores from fine to coarse grid.

**Returns**: ndarray with conductivity multipliers on coarse grid

### Soil Layer Functions

#### `create_soil_layers(z_grid, layer_boundaries)`

Create layer assignment for grid.

**Parameters**:
- `z_grid` (ndarray): 2D elevation coordinates
- `layer_boundaries` (list of dict): Boundaries with:
  - `type`: 'depth' or 'elevation'
  - `value`: depth or elevation [m]
  - `name`: optional layer name

**Returns**: ndarray with layer indices

#### `assign_soil_properties(layer_indices, soil_types)`

Assign hydraulic properties to layers.

**Parameters**:
- `layer_indices` (ndarray): From `create_soil_layers`
- `soil_types` (dict): Maps layer index to parameters:
  - `Ks`: Saturated conductivity [m/s]
  - `theta_s`: Saturated water content [-]
  - `theta_r`: Residual water content [-]
  - `alpha`: Van Genuchten α [1/m]
  - `n`: Van Genuchten n [-]

**Returns**: dict with 2D arrays for each property

#### `get_standard_soils()`

Get dictionary of standard soil types.

**Returns**: dict with keys for 11 USDA soil texture classes

### Visualization Functions

#### `plot_hillslope(profile, simgrid, title)`

Plot hillslope profile and grid.

#### `plot_macropores(simgrid, macropores, title)`

Plot macropore distribution.

#### `plot_soil_layers(simgrid, layer_indices, soil_properties, title)`

Plot soil layers and hydraulic properties.

#### `plot_combined_overview(profile, simgrid, layer_indices, macropores, soil_properties)`

Create comprehensive multi-panel overview.

## Comparison with R Package

| Feature | R Package | Python Package | Status |
|---------|-----------|----------------|--------|
| Hillslope creation | `make.geometry()` | `create_hillslope_profile()` | ✅ |
| Simulation grid | `make.simgrid()` | `make_simgrid()` | ✅ |
| Macropore simulation | `sim.mak()` | `simulate_macropores()` | ✅ |
| Discretization | `discretize.eta/xsi()` | `discretize_for_catflow()` | ✅ |
| Soil assignment | `assign.mac.soil()` | `assign_soil_properties()` | ✅ |
| Visualization | `plot.catf.grid()` | `plot_*()` functions | ✅ |
| File I/O | `.geo`, `.rb`, `.pob` files | Direct Python objects | 🔄 |

**Legend**: ✅ Implemented | 🔄 Different approach | ⏳ Planned

## Advanced Usage

### Custom Soil Properties

```python
# Define custom soil type
custom_soil = {
    'name': 'My Custom Soil',
    'Ks': 5e-6,
    'theta_s': 0.38,
    'theta_r': 0.08,
    'alpha': 4.0,
    'n': 1.6
}

soil_types = {
    0: custom_soil
}
```

### Variable Hillslope Width

```python
# Create hillslope with varying width
widths = np.linspace(1.0, 3.0, 20)  # 1m to 3m
profile = create_hillslope_profile(
    length=50,
    slope_angle=10,
    curvature='complex',
    width=widths,  # Array instead of scalar
    n_points=20
)
```

### Multi-Layer Macropores

```python
# Three layers with different macropore properties
layer_depths = [0.5, 1.5]  # Boundaries at 0.5m and 1.5m
layer_props = [
    {'p_lateral': 0.05, 'conductivity': 2e-5},  # 0-0.5m: very vertical
    {'p_lateral': 0.20, 'conductivity': 1e-5},  # 0.5-1.5m: moderate
    {'p_lateral': 0.40, 'conductivity': 5e-7}   # 1.5m+: very tortuous
]

macropores = simulate_macropores(
    simgrid,
    n_pores_per_m2=8,
    mean_length=2.0,
    layer_depths=layer_depths,
    layer_properties=layer_props
)
```

## Performance Notes

- **Fine grids**: Use dx=0.05-0.1m, dz=0.02-0.05m for macropore simulation
- **Coarse grids**: Typical CATFLOW mesh: 31-51 nodes per direction
- **Macropore simulation**: ~1 second for 1000×100 grid with 20 macropores
- **Memory**: Fine 2000×500 grid ≈ 8 MB (1M cells × 8 bytes)

## Troubleshooting

### Grid resolution warnings

```
Warning: Check results! dx.max does not hold
```

**Solution**: The specified `dx_max` couldn't be exactly satisfied. Check `simgrid['dx']` for actual resolution.

### Macropore separation

If fewer macropores than expected are simulated, the `min_separation` constraint may be too strict. Reduce it or increase hillslope width.

### Layer boundary artifacts

Ensure layer boundaries are within the simulation domain:
- For `type='depth'`: `0 < value < depth`
- For `type='elevation'`: `z_bottom < value < z_surface`

## References

### R Package

Wienöfer, J. and Zehe, E. (2014). *preprocessing_RCatflow: R package for preprocessing CATFLOW input files*. R package version 1.0.

### Theory

- **Random walk macropores**: Zehe, E., & Blöschl, G. (2004). *Water Resources Research*, 40(1).
- **Van Genuchten parameters**: Carsel, R. F., & Parrish, R. S. (1988). *Water Resources Research*, 24(5), 755-769.
- **CATFLOW model**: Maurer, T. (1997). *Physikalisch begründete, zeitkontinuierliche Modellierung des Wassertransports in kleinen ländlichen Einzugsgebieten*.

## License

Part of the CATFLOW Python package.

## Contact

For issues or questions about the preprocessing tools, please create an issue at the main repository.

---

**Python CATFLOW Preprocessing** • November 2025
