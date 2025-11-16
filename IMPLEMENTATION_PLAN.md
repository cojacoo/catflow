# CATFLOW Modernization Implementation Plan
## From Legacy Fortran to Modern Python-Fortran Ecosystem

**Date:** November 16, 2025
**Goal:** Modern, tested, Python-integrated CATFLOW with validated hydrological functionality
**Timeline:** 3-4 months
**Strategy:** Fortran core first, Python bindings second, ecosystem integration third

---

## Overview

This plan focuses on **functional milestones** that validate complete hydrological processes, not isolated functions. Each checkpoint represents a working simulation capability that can be tested against physical expectations and legacy CATFLOW results.

### Three-Phase Strategy

1. **Phase 1: Fortran Core Validation** (4-6 weeks)
   - Complete input system
   - Validate against original CATFLOW
   - Bit-exact reproduction of legacy results

2. **Phase 2: Python Integration** (4-6 weeks)
   - f2py bindings
   - Pythonic API
   - Example workflows

3. **Phase 3: Ecosystem & Advanced Features** (4-6 weeks)
   - Pre/post-processing tools
   - Visualization suite
   - Parameter estimation
   - Integration with scientific Python stack

---

## Phase 1: Fortran Core Validation (4-6 weeks)

**Goal:** Modernized Fortran CATFLOW runs identically to original version

### Milestone 1.1: Complete Input System ✓/✗

**Objective:** Read all legacy CATFLOW input files without stubs

**Tasks:**
- [ ] Convert input file readers from F77 to F90 (using StmtTree or manual)
  - [ ] RDMINF.f → input_module.f90 (main input file)
  - [ ] RDGEOM.f → geometry_reader_module.f90 (grid geometry)
  - [ ] RDBOD.f → soil_reader_module.f90 (soil properties)
  - [ ] RDRB.f → boundary_reader_module.f90 (boundary conditions)
  - [ ] RDINI.f → initial_conditions_module.f90 (initial state)
- [ ] Convert time series interpolation (strahl function)
- [ ] Remove all stub functions from input_stubs.f90
- [ ] Integrate with existing module structure

**Validation:**
- [ ] Successfully read 3+ legacy CATFLOW input files
- [ ] Print diagnostic output showing all parameters loaded correctly
- [ ] Compare parsed values with manual inspection of input files

**Success Criteria:**
- No stub functions remain
- All legacy input formats supported
- Input validation with clear error messages

**Estimated Time:** 1-2 weeks

---

### Milestone 1.2: 1D Vertical Infiltration ✓/✗

**Objective:** Simulate simple vertical infiltration into uniform soil column

**Physical Process:**
- Constant infiltration rate at surface
- Free drainage at bottom
- Homogeneous soil (van Genuchten)
- Initially unsaturated

**Test Case Setup:**
```
Geometry:     1D column, 1.0 m deep, 50 cells
Soil:         Loam (van Genuchten parameters)
Top BC:       Constant flux 1e-5 m/s (36 mm/hr)
Bottom BC:    Free drainage (gradient = 0)
Initial:      Pressure head = -2.0 m (unsaturated)
Duration:     24 hours
Time step:    Adaptive (60-3600 seconds)
```

**Tasks:**
- [ ] Create minimal input file for 1D column
- [ ] Configure geometry (1 × 50 grid)
- [ ] Set uniform soil properties
- [ ] Set simple boundary conditions
- [ ] Initialize state variables
- [ ] Run simulation to completion
- [ ] Extract results (theta, psi profiles)

**Validation:**
- [ ] Mass balance error < 1e-10 (relative)
- [ ] Wetting front advances monotonically
- [ ] Final moisture profile physically reasonable
- [ ] Convergence achieved at each time step
- [ ] Compare with analytical Green-Ampt solution (approximate)

**Success Criteria:**
- Simulation completes without errors
- Mass balance satisfied
- Results match physical expectations

**Estimated Time:** 3-5 days

---

### Milestone 1.3: Infiltration with Water Table ✓/✗

**Objective:** Simulate infiltration into saturated-unsaturated zone with water table

**Physical Process:**
- Infiltration into column with initial water table
- Capillary rise above water table
- Water table response to infiltration

**Test Case Setup:**
```
Geometry:     1D column, 2.0 m deep, 100 cells
Soil:         Sand (high conductivity)
Top BC:       Constant flux 5e-6 m/s
Bottom BC:    Constant pressure head = 0.0 m (saturated)
Initial:      Hydrostatic equilibrium from water table at 1.5 m
Duration:     48 hours
```

**Tasks:**
- [ ] Implement hydrostatic initial conditions
- [ ] Set saturated bottom boundary
- [ ] Run simulation with mixed saturated/unsaturated zones
- [ ] Track water table position over time

**Validation:**
- [ ] Initial condition is in hydrostatic equilibrium
- [ ] Water table rises in response to infiltration
- [ ] Saturation maintained below water table
- [ ] Pressure head continuous across water table
- [ ] Mass balance < 1e-10

**Success Criteria:**
- Water table dynamics physically correct
- No numerical oscillations at saturation front
- Smooth transition across water table

**Estimated Time:** 2-3 days

---

### Milestone 1.4: Atmospheric Boundary Condition ✓/✗

**Objective:** Simulate realistic atmospheric BC with switching between infiltration and evaporation

**Physical Process:**
- Time-varying rainfall/evaporation
- Atmospheric BC switches to seepage face when saturated
- Surface ponding prevention

**Test Case Setup:**
```
Geometry:     1D column, 1.5 m deep, 75 cells
Soil:         Loam
Top BC:       Atmospheric (time series: rainfall → evaporation)
              - 0-6h:  Rainfall 20 mm/hr
              - 6-12h: No flux
              - 12-24h: Evaporation 2 mm/hr
Bottom BC:    Free drainage
Initial:      Pressure = -3.0 m (dry)
Duration:     24 hours
```

**Tasks:**
- [ ] Implement time series interpolation (strahl function)
- [ ] Implement atmospheric BC logic
- [ ] Handle BC switching (infiltration ↔ seepage face)
- [ ] Test with rainfall event followed by drying

**Validation:**
- [ ] Surface stays unsaturated during infiltration (or switches to seepage)
- [ ] Water content decreases during evaporation period
- [ ] BC switching occurs smoothly
- [ ] Mass balance accounts for all fluxes
- [ ] Time series interpolation correct at all times

**Success Criteria:**
- Realistic soil moisture response to atmospheric forcing
- No numerical artifacts at BC switches
- Fluxes match applied time series

**Estimated Time:** 3-5 days

---

### Milestone 1.5: Layered Soil Profile ✓/✗

**Objective:** Simulate infiltration through heterogeneous soil layers

**Physical Process:**
- Multiple soil layers with different properties
- Capillary barrier effects
- Flux continuity at interfaces

**Test Case Setup:**
```
Geometry:     1D column, 1.5 m deep, 100 cells
Soil layers:  0.0-0.3 m: Sand (high K)
              0.3-0.7 m: Clay (low K) - capillary barrier
              0.7-1.5 m: Loam (medium K)
Top BC:       Constant flux 1e-5 m/s
Bottom BC:    Free drainage
Initial:      Uniform pressure = -1.5 m
Duration:     72 hours
```

**Tasks:**
- [ ] Implement layered soil property assignment
- [ ] Test K(ψ) and C(ψ) calculations for each layer
- [ ] Verify flux continuity at layer interfaces
- [ ] Monitor moisture buildup above low-K layer

**Validation:**
- [ ] Water accumulates above clay layer (capillary barrier)
- [ ] Hydraulic properties change discontinuously at interfaces
- [ ] Flux is continuous across interfaces
- [ ] Each layer responds according to its parameters
- [ ] Mass balance < 1e-10

**Success Criteria:**
- Clear capillary barrier effect visible
- Physically correct behavior in each layer
- No numerical instability at interfaces

**Estimated Time:** 2-4 days

---

### Milestone 1.6: 2D Hillslope Flow ✓/✗

**Objective:** Simulate 2D subsurface flow on a hillslope with lateral redistribution

**Physical Process:**
- Vertical infiltration + lateral subsurface flow
- Development of saturated zone along impermeable base
- Seepage face at hillslope toe
- Realistic hillslope hydrology

**Test Case Setup:**
```
Geometry:     2D hillslope, 10 m long × 2 m deep
              Slope: 10%, cells: 50 × 40
Soil:         Uniform loam
Top BC:       Uniform infiltration 5e-6 m/s
Bottom BC:    Impermeable (no-flow)
Left BC:      No-flow (watershed divide)
Right BC:     Seepage face (hillslope outlet)
Initial:      Pressure = -2.0 m
Duration:     48 hours
```

**Tasks:**
- [ ] Set up 2D curvilinear coordinate grid
- [ ] Implement lateral boundary conditions
- [ ] Calculate 2D fluxes (ξ and η directions)
- [ ] Test seepage face BC at outlet
- [ ] Extract 2D moisture and flux fields

**Validation:**
- [ ] Saturated zone develops along impermeable bottom
- [ ] Lateral flow toward outlet
- [ ] Seepage face activates at hillslope toe
- [ ] Upper unsaturated zone shows primarily vertical flow
- [ ] Mass balance for entire hillslope < 1e-10
- [ ] Compare with 1D column (should match if no lateral flow)

**Success Criteria:**
- Realistic hillslope moisture distribution
- Proper lateral flow patterns
- Seepage face BC works correctly
- 2D solver stable and accurate

**Estimated Time:** 5-7 days

---

### Milestone 1.7: Runoff Production ✓/✗

**Objective:** Simulate surface runoff generation (saturation excess and infiltration excess)

**Physical Process:**
- Surface ponding when infiltration capacity exceeded
- Saturation excess runoff at seepage faces
- Surface flow routing (if implemented) or storage

**Test Case Setup:**
```
Geometry:     2D hillslope, 10 m × 2 m, slope 15%
Soil:         Layered (sand over clay)
Top BC:       High-intensity rainfall 50 mm/hr (> K_sat)
Bottom BC:    Impermeable
Left BC:      No-flow
Right BC:     Seepage face
Initial:      Pressure = -1.0 m
Duration:     12 hours
```

**Tasks:**
- [ ] Implement surface runoff generation logic
- [ ] Track infiltration vs rainfall rate
- [ ] Monitor saturation excess at seepage faces
- [ ] Calculate runoff volume
- [ ] (Optional) Implement surface flow routing if available

**Validation:**
- [ ] Infiltration limited by K_sat during intense rainfall
- [ ] Surface runoff generated when rainfall > infiltration
- [ ] Saturation excess at hillslope toe
- [ ] Runoff volume = rainfall - infiltration - storage change
- [ ] Mass balance includes surface water

**Success Criteria:**
- Runoff generation mechanisms work correctly
- Runoff timing and volume physically reasonable
- Mass balance closure including surface water

**Estimated Time:** 3-5 days (or skip if surface flow not yet implemented)

---

### Milestone 1.8: Macropore Flow ✓/✗

**Objective:** Simulate preferential flow through macropores

**Physical Process:**
- Dual-permeability system (matrix + macropores)
- Fast flow through macropore network
- Matrix-macropore exchange
- Bypass of low-conductivity layers

**Test Case Setup:**
```
Geometry:     1D column, 1.0 m deep, with macropore parameters
Soil:         Loam with macropore fraction
Macropores:   Volume fraction 5%, higher conductivity
Top BC:       Pulse rainfall 100 mm/hr for 1 hour
Bottom BC:    Free drainage
Initial:      Dry soil, pressure = -5.0 m
Duration:     12 hours
```

**Tasks:**
- [ ] Configure macropore parameters in input
- [ ] Verify macropore flow calculations active
- [ ] Monitor macropore vs matrix flow
- [ ] Compare with non-macropore simulation

**Validation:**
- [ ] Faster wetting front with macropores
- [ ] Moisture content higher in macropore-affected regions
- [ ] Physically reasonable partitioning between matrix/macropore
- [ ] Mass balance accounts for both domains
- [ ] Without macropores (fraction=0), reverts to standard Richards

**Success Criteria:**
- Macropore effects visible and physically correct
- Dual-permeability model working
- Correct bypass of low-K layers

**Estimated Time:** 3-5 days

---

### Milestone 1.9: Validation Against Original CATFLOW ✓/✗

**Objective:** Bit-exact (or near-exact) reproduction of legacy CATFLOW results

**Test Cases:**
- [ ] Run 3-5 legacy CATFLOW test cases with original input files
- [ ] Compare outputs point-by-point (theta, psi, fluxes)
- [ ] Verify identical mass balance
- [ ] Check convergence behavior (iterations, timesteps)

**Tasks:**
- [ ] Obtain original CATFLOW executable and test datasets
- [ ] Run original CATFLOW on test cases
- [ ] Run modernized CATFLOW on same test cases
- [ ] Automated comparison script (compare arrays, statistics)
- [ ] Document any differences and root causes

**Validation:**
- [ ] Theta fields match within 1e-6 (relative)
- [ ] Psi fields match within 1e-6 (relative)
- [ ] Cumulative mass balance identical to machine precision
- [ ] Time step sequence identical (if same dt criteria)
- [ ] If differences exist, documented and physically justified

**Success Criteria:**
- Modern CATFLOW is scientifically equivalent to original
- Any numerical differences are negligible and understood
- Confidence in modernized code for production use

**Estimated Time:** 1 week

---

### Phase 1 Summary

**Deliverables:**
- [ ] Fully functional Fortran CATFLOW (no stubs)
- [ ] Validated against 8+ hydrological test cases
- [ ] Bit-exact (or near-exact) with original CATFLOW
- [ ] Comprehensive test suite (Fortran unit tests + integration tests)
- [ ] Documentation of all test cases and validation results

**Total Time Estimate:** 4-6 weeks

---

## Phase 2: Python Integration (4-6 weeks)

**Goal:** Elegant Python interface for setup, execution, and analysis

### Milestone 2.1: f2py Core Bindings ✓/✗

**Objective:** Low-level f2py wrappers for essential Fortran modules

**Tasks:**
- [ ] Create f2py signature file (.pyf) or use automatic generation
- [ ] Wrap state_data_module (theta, psi, fluxes)
- [ ] Wrap mesh_geometry_module (grid coordinates)
- [ ] Wrap soil_properties_module (soil parameters)
- [ ] Wrap boundary_conditions_module (BC arrays)
- [ ] Wrap hg_module (main solver)
- [ ] Build Python extension module (catflow.core)
- [ ] Test array access (read/write Fortran data from Python)

**Validation:**
- [ ] Import catflow.core successfully
- [ ] Allocate Fortran arrays from Python
- [ ] Read theta, psi arrays as NumPy arrays (zero-copy)
- [ ] Modify arrays in Python, changes visible in Fortran
- [ ] Call hg() solver from Python
- [ ] No memory leaks (valgrind or similar)

**Success Criteria:**
- Complete two-way data exchange Python ↔ Fortran
- Zero-copy array access
- Stable and robust interface

**Estimated Time:** 1 week

---

### Milestone 2.2: Pythonic API - Model Class ✓/✗

**Objective:** High-level Model class for intuitive simulation setup

**Implementation:**
```python
from catflow import Model

# Simple constructor
model = Model.vertical_column(depth=2.0, cells=50, soil='loam')

# Set boundary conditions
model.bc.top = 'flux', 1e-5
model.bc.bottom = 'free_drainage'

# Set initial conditions
model.ic.pressure = -2.0

# Run
results = model.run(duration='24h', output_interval='1h')
```

**Tasks:**
- [ ] Create Model class (python/catflow/model.py)
- [ ] Implement .vertical_column() constructor
- [ ] Implement bc attribute (BoundaryConditions wrapper)
- [ ] Implement ic attribute (InitialConditions wrapper)
- [ ] Implement .run() method (calls Fortran solver)
- [ ] Handle unit conversions (hours → seconds, mm/hr → m/s)
- [ ] Error handling (Fortran errors → Python exceptions)

**Validation:**
- [ ] Reproduce Milestone 1.2 (1D infiltration) from Python
- [ ] Results identical to pure Fortran run
- [ ] API intuitive and self-documenting
- [ ] Error messages clear and helpful

**Success Criteria:**
- 1D infiltration in <10 lines of Python
- Results match Fortran validation
- Code is readable and Pythonic

**Estimated Time:** 1 week

---

### Milestone 2.3: Results Class with xarray ✓/✗

**Objective:** Rich results object with metadata and easy analysis

**Implementation:**
```python
results = model.run(...)

# Access as xarray DataArrays
results.theta           # (time, z) or (time, z, x)
results.psi
results.K

# Smart selection
results.theta.sel(time='12h', depth=0.5)

# Export
results.to_netcdf('output.nc')
results.to_dataframe()
```

**Tasks:**
- [ ] Create Results class (python/catflow/results.py)
- [ ] Wrap Fortran output as xarray.Dataset
- [ ] Add coordinate arrays (time, z, x with units)
- [ ] Add metadata (simulation parameters, soil properties)
- [ ] Implement .to_netcdf(), .to_dataframe(), .to_csv()
- [ ] Implement analysis methods (.mass_balance(), .infiltration_rate())

**Validation:**
- [ ] xarray selection works correctly (.sel, .isel)
- [ ] Metadata complete and accurate
- [ ] NetCDF export/import round-trip successful
- [ ] Analysis methods give correct values (mass balance check)

**Success Criteria:**
- Results are self-describing (rich metadata)
- Easy to work with (xarray interface)
- Export to standard formats

**Estimated Time:** 1 week

---

### Milestone 2.4: Plotting and Visualization ✓/✗

**Objective:** Beautiful, publication-ready plots with minimal code

**Implementation:**
```python
# Simple plotting
results.plot.profile('theta', time='12h')
results.plot.timeseries('theta', depth=0.5)
results.plot.contour('psi', time='24h')   # 2D
```

**Tasks:**
- [ ] Create plotting module (python/catflow/plotting.py)
- [ ] Implement .plot.profile() (1D profiles)
- [ ] Implement .plot.timeseries() (time series at point)
- [ ] Implement .plot.contour() (2D fields)
- [ ] Implement .plot.animation() (time evolution)
- [ ] Sensible defaults (colors, labels, units)
- [ ] Matplotlib + (optional) Plotly backends

**Validation:**
- [ ] All plot types work without errors
- [ ] Plots are physically meaningful
- [ ] Axis labels include units
- [ ] Publication-quality aesthetics

**Success Criteria:**
- Create informative plot in 1 line of code
- Plots look professional (ready for papers/presentations)

**Estimated Time:** 1 week

---

### Milestone 2.5: Complete Python Workflows ✓/✗

**Objective:** End-to-end examples demonstrating all major features

**Example Workflows:**

**Example 1: Vertical Infiltration**
```python
from catflow import Model

model = Model.vertical_column(depth=1.0, soil='sand')
model.bc.top = 'flux', 1e-5
model.bc.bottom = 'free_drainage'
model.ic.pressure = -5.0

results = model.run(duration='12h', output_interval='30min')
results.plot.profile('theta', time=['3h', '6h', '12h'])
```

**Example 2: Rainfall Event**
```python
import pandas as pd

# Time-varying rainfall
rainfall = pd.Series(
    [0, 10, 30, 50, 20, 5, 0],  # mm/hr
    index=pd.timedelta_range('0h', '6h', freq='1h')
)

model = Model.vertical_column(depth=2.0, soil='loam')
model.bc.top = 'flux', rainfall / 1000 / 3600  # convert to m/s
results = model.run(duration='24h')
results.plot.timeseries('theta', depth=0.5)
```

**Example 3: Hillslope 2D**
```python
model = Model.hillslope_2d(length=10, depth=2, slope=0.1)
model.bc.top = 'flux', 5e-6
model.bc.right = 'seepage'
results = model.run(duration='48h', output_interval='2h')
results.plot.contour('theta', time='24h')
```

**Example 4: Parameter Sensitivity**
```python
import numpy as np

Ks_values = np.logspace(-7, -4, 10)
results_list = []

for Ks in Ks_values:
    soil = SoilProfile.van_genuchten(
        theta_s=0.43, theta_r=0.078,
        alpha=0.036, n=1.56, Ks=Ks
    )
    model = Model.vertical_column(depth=1.0, soil=soil)
    model.bc.top = 'flux', 1e-5
    results = model.run(duration='24h')
    results_list.append(results)

# Plot sensitivity
for Ks, res in zip(Ks_values, results_list):
    res.plot.timeseries('theta', depth=0.5, label=f'Ks={Ks:.2e}')
```

**Tasks:**
- [ ] Write 5+ complete example scripts
- [ ] Convert examples to Jupyter notebooks
- [ ] Ensure all examples run without errors
- [ ] Add explanatory text and outputs to notebooks
- [ ] Include figures in notebooks

**Validation:**
- [ ] Examples reproduce Fortran validation cases
- [ ] Notebooks execute completely
- [ ] Results physically meaningful
- [ ] Code is pedagogical (good for teaching)

**Success Criteria:**
- New user can run first example in 5 minutes
- Examples cover all major CATFLOW features
- Notebooks suitable for tutorials/courses

**Estimated Time:** 1 week

---

### Milestone 2.6: Python Package Distribution ✓/✗

**Objective:** Professional Python package installable via pip/conda

**Tasks:**
- [ ] Create pyproject.toml with build system
- [ ] Create setup.py with f2py integration
- [ ] Configure fpm build as part of Python install
- [ ] Add package metadata (README, LICENSE, etc.)
- [ ] Write installation instructions
- [ ] Test installation on clean systems (Linux, macOS)
- [ ] (Optional) Publish to Test PyPI
- [ ] (Optional) Publish to PyPI

**Package Structure:**
```
catflow/
├── pyproject.toml
├── setup.py
├── README.md
├── LICENSE
├── src/               # Fortran source
├── python/catflow/    # Python package
├── examples/          # Example scripts/notebooks
├── tests/             # Python tests
└── docs/              # Sphinx documentation
```

**Validation:**
- [ ] `pip install .` works on Linux
- [ ] `pip install .` works on macOS
- [ ] Import catflow in fresh Python environment
- [ ] Run examples after installation
- [ ] Uninstall cleanly

**Success Criteria:**
- Simple installation for end users
- Works on major platforms
- Professional package structure

**Estimated Time:** 3-5 days

---

### Phase 2 Summary

**Deliverables:**
- [ ] Complete Python API (Model, Results, plotting)
- [ ] 5+ example scripts and Jupyter notebooks
- [ ] Installable Python package
- [ ] Documentation (docstrings, examples)
- [ ] Validated against Fortran results

**Total Time Estimate:** 4-6 weeks

---

## Phase 3: Ecosystem & Advanced Features (4-6 weeks)

**Goal:** Pre/post-processing tools and integration with scientific Python ecosystem

### Milestone 3.1: Input File Generators ✓/✗

**Objective:** Create CATFLOW input files from Python

**Implementation:**
```python
from catflow import InputGenerator

gen = InputGenerator()
gen.geometry.column_1d(depth=2.0, cells=50)
gen.soil.uniform('loam')
gen.bc.top = 'flux', 1e-5
gen.bc.bottom = 'free_drainage'
gen.ic.pressure = -2.0
gen.write('simulation.dat')

# Or from GIS data
gen.geometry.from_dem('hillslope.tif', resolution=0.5)
gen.soil.from_raster('soil_map.tif', lookup=soil_database)
```

**Tasks:**
- [ ] Create InputGenerator class
- [ ] Support all CATFLOW input file formats
- [ ] Generate geometry from DEMs (rasterio integration)
- [ ] Map soil properties from GIS layers
- [ ] Validate generated input files
- [ ] Test roundtrip (generate → read → compare)

**Success Criteria:**
- Generate valid CATFLOW inputs programmatically
- GIS integration for realistic hillslopes
- Reduces manual input file editing

**Estimated Time:** 1-2 weeks

---

### Milestone 3.2: Advanced Post-Processing ✓/✗

**Objective:** Tools for in-depth analysis of results

**Features:**
```python
# Water balance analysis
balance = results.water_balance()
print(balance.infiltration, balance.runoff, balance.storage_change)

# Wetting front detection
front = results.wetting_front(threshold=0.1)
front.plot()

# Residence time distribution
rtd = results.residence_time_distribution()

# Breakthrough curves
btc = results.breakthrough_curve(location='outlet')
```

**Tasks:**
- [ ] Implement water balance diagnostics
- [ ] Wetting front tracking
- [ ] Flow path analysis
- [ ] Residence time calculations
- [ ] Statistical analysis tools

**Success Criteria:**
- Rich analysis capabilities
- Useful for research applications
- Well-documented with examples

**Estimated Time:** 1-2 weeks

---

### Milestone 3.3: Parameter Estimation Framework ✓/✗

**Objective:** Calibrate soil parameters from observations

**Implementation:**
```python
from catflow import ParameterEstimation
from scipy.optimize import minimize

# Observed data
obs_theta = pd.read_csv('observations.csv')

# Define parameters to calibrate
params = ParameterEstimation.Parameters(
    Ks=(1e-7, 1e-4),      # bounds
    alpha=(0.01, 0.1),
    n=(1.1, 3.0)
)

# Objective function
def objective(param_values):
    soil = params.create_soil(param_values)
    model = Model.vertical_column(depth=2.0, soil=soil)
    results = model.run(duration='24h')
    sim_theta = results.theta.sel(depth=0.5)
    return np.sum((sim_theta - obs_theta)**2)

# Optimize
result = minimize(objective, params.initial, bounds=params.bounds)
best_params = params.create_soil(result.x)
```

**Tasks:**
- [ ] Create parameter estimation utilities
- [ ] Interface with scipy.optimize
- [ ] Support multiple objectives (RMSE, NSE, etc.)
- [ ] Uncertainty quantification (optional)
- [ ] Example calibration workflows

**Success Criteria:**
- Easy parameter calibration
- Works with standard optimization libraries
- Example successfully calibrates to synthetic data

**Estimated Time:** 1-2 weeks

---

### Milestone 3.4: Integration with Scientific Ecosystem ✓/✗

**Objective:** Seamless integration with NumPy, Pandas, xarray, Dask

**Features:**
```python
# NumPy integration
theta_array = np.asarray(results.theta)  # zero-copy

# Pandas integration
df = results.to_dataframe()
df.groupby('depth').mean()

# xarray integration (already done in Phase 2, extend here)
results.theta.resample(time='3h').mean()  # temporal resampling
results.theta.groupby('time.hour').mean()  # diurnal patterns

# Dask for large datasets (parallel/out-of-core)
import dask.array as da
theta_dask = da.from_array(results.theta.values, chunks='auto')
```

**Tasks:**
- [ ] Ensure NumPy array protocol compliance
- [ ] Pandas integration examples
- [ ] xarray advanced features (groupby, resample)
- [ ] (Optional) Dask support for large simulations
- [ ] Document integration patterns

**Success Criteria:**
- Works naturally with scientific Python tools
- Examples demonstrate integration
- No performance bottlenecks in data exchange

**Estimated Time:** 3-5 days

---

### Milestone 3.5: Visualization Suite ✓/✗

**Objective:** Advanced visualization beyond basic plots

**Features:**
```python
# Interactive plots (Plotly)
results.plot.interactive_profile('theta')

# 3D visualization (for 2D hillslopes)
results.plot.surface_3d('psi', time='24h')

# Animations
results.plot.animation('theta', filename='moisture.gif', fps=5)

# Subplots and multi-variable
fig = results.plot.dashboard(
    variables=['theta', 'psi', 'K'],
    time='12h'
)

# Export for ParaView/QGIS
results.export_vtk('output.vtk')
results.export_geotiff('theta_final.tif', variable='theta')
```

**Tasks:**
- [ ] Plotly backend for interactivity
- [ ] Animation generation (matplotlib or plotly)
- [ ] VTK export for ParaView
- [ ] GeoTIFF export for QGIS
- [ ] Multi-panel dashboard plots

**Success Criteria:**
- Rich visualization options
- Export to standard formats (VTK, GeoTIFF)
- Interactive plots work in Jupyter

**Estimated Time:** 1-2 weeks

---

### Milestone 3.6: Documentation and Tutorials ✓/✗

**Objective:** Comprehensive documentation for users and developers

**Content:**
- [ ] User guide (installation, quickstart, concepts)
- [ ] API reference (auto-generated from docstrings, Sphinx)
- [ ] Tutorials (Jupyter notebooks)
  - [ ] Tutorial 1: Your first CATFLOW simulation
  - [ ] Tutorial 2: Working with boundary conditions
  - [ ] Tutorial 3: 2D hillslope modeling
  - [ ] Tutorial 4: Parameter sensitivity analysis
  - [ ] Tutorial 5: Calibration and validation
- [ ] Developer guide (contributing, code structure)
- [ ] Theory documentation (Richards equation, numerics)
- [ ] FAQ and troubleshooting

**Tasks:**
- [ ] Set up Sphinx documentation
- [ ] Write user guide
- [ ] Auto-generate API docs
- [ ] Convert examples to tutorials
- [ ] Host documentation (ReadTheDocs or GitHub Pages)

**Success Criteria:**
- Complete and searchable documentation
- Tutorials suitable for beginners
- API reference complete
- Documentation website online

**Estimated Time:** 2 weeks

---

### Phase 3 Summary

**Deliverables:**
- [ ] Input file generators (from Python, from GIS)
- [ ] Advanced post-processing tools
- [ ] Parameter estimation framework
- [ ] Rich visualization suite
- [ ] Comprehensive documentation
- [ ] Integration with scientific Python ecosystem

**Total Time Estimate:** 4-6 weeks

---

## Testing Strategy

### Unit Tests (Fortran)
- [ ] Test each module independently
- [ ] Van Genuchten functions (theta(psi), K(psi))
- [ ] Geometric transformations
- [ ] Solver components (CG, ADI, tridiagonal)

### Integration Tests (Fortran)
- [ ] Each milestone 1.2-1.8 becomes an integration test
- [ ] Automated comparison with reference solutions
- [ ] Mass balance checks
- [ ] Convergence verification

### Python Tests (pytest)
- [ ] Test f2py bindings (array access, memory)
- [ ] Test Model class (setup, run, results)
- [ ] Test Results class (selection, export)
- [ ] Test plotting (generates figures without errors)
- [ ] Test examples (all examples run successfully)

### Validation Tests
- [ ] Comparison with original CATFLOW (Milestone 1.9)
- [ ] Comparison with analytical solutions (where available)
- [ ] Comparison with published benchmark problems
- [ ] Physical plausibility checks (non-negative theta, monotonic K(psi), etc.)

---

## Success Metrics

### Technical Metrics
- [ ] 100% of legacy CATFLOW functionality preserved
- [ ] Mass balance error < 1e-10 for all tests
- [ ] Python API covers all major use cases
- [ ] Installation success rate > 95%
- [ ] Test coverage > 80% (Python code)
- [ ] Zero memory leaks (Fortran-Python interface)

### Usability Metrics
- [ ] First simulation in < 10 lines of Python
- [ ] Installation time < 5 minutes
- [ ] Example to plot < 2 minutes
- [ ] Documentation complete and searchable
- [ ] Jupyter notebooks execute without errors

### Community Metrics (post-release)
- [ ] Used in 1+ hydrology course
- [ ] Used in 3+ research projects
- [ ] PyPI downloads > 100/month (after 6 months)
- [ ] 5+ external contributors
- [ ] 2+ publications using modernized CATFLOW

---

## Timeline Summary

| Phase | Duration | Key Deliverables |
|-------|----------|------------------|
| **Phase 1: Fortran Core** | 4-6 weeks | Complete input system, 8 validated test cases, bit-exact with original |
| **Phase 2: Python Integration** | 4-6 weeks | Python API, f2py bindings, examples, pip package |
| **Phase 3: Ecosystem** | 4-6 weeks | GIS integration, advanced tools, documentation, visualization |
| **Total** | **12-18 weeks** | **Production-ready Python-Fortran CATFLOW** |

---

## Risk Mitigation

### Risk 1: f2py Integration Complexity
**Mitigation:** Start with simple test cases, incremental complexity, extensive testing

### Risk 2: Performance Bottlenecks in Python-Fortran Interface
**Mitigation:** Zero-copy arrays, minimize data transfers, profile early

### Risk 3: Differences from Original CATFLOW
**Mitigation:** Systematic validation at each milestone, maintain original as reference

### Risk 4: Cross-Platform Build Issues
**Mitigation:** Test on Linux and macOS early, use CI/CD, clear build instructions

### Risk 5: User Adoption
**Mitigation:** Excellent documentation, simple examples, responsive to feedback

---

## Resources Needed

### Software
- [x] Fortran compiler (gfortran)
- [x] Python 3.8+ (with NumPy, f2py)
- [ ] fpm (Fortran Package Manager)
- [ ] Scientific Python stack (xarray, Pandas, Matplotlib)
- [ ] Testing frameworks (pytest, test-drive)
- [ ] Documentation tools (Sphinx, Jupyter)
- [ ] (Optional) StmtTree for F77 conversion

### Data
- [ ] Legacy CATFLOW test cases and reference outputs
- [ ] Soil parameter databases (Carsel & Parrish, etc.)
- [ ] Example hillslope geometries and DEMs
- [ ] Published benchmark problems

### Expertise
- [x] Fortran programming (modernization)
- [x] Python programming (API design)
- [x] Hydrological modeling (CATFLOW physics)
- [ ] Software engineering (testing, CI/CD, packaging)
- [ ] Technical writing (documentation)

---

## Next Actions

### This Week (Week 1)
- [ ] Complete Milestone 1.1: Input system conversion
  - Use StmtTree to convert input readers
  - Remove all stubs
  - Test with 3 legacy input files

### Next Week (Week 2)
- [ ] Complete Milestone 1.2: 1D vertical infiltration
- [ ] Complete Milestone 1.3: Water table dynamics
- [ ] Set up Fortran unit testing framework

### Weeks 3-4
- [ ] Complete Milestones 1.4-1.6 (atmospheric BC, layered soil, 2D hillslope)
- [ ] Begin validation against original CATFLOW

### Weeks 5-6
- [ ] Complete Phase 1 (Milestones 1.7-1.9)
- [ ] Begin Phase 2 (f2py bindings)

---

## Conclusion

This plan provides a clear roadmap from modernized Fortran code to a complete Python-Fortran ecosystem. Each milestone validates real hydrological functionality, ensuring scientific correctness throughout. The phased approach allows for incremental progress with clear success criteria at each stage.

**The end goal:** A researcher can `pip install catflow`, set up a hillslope in 10 lines of Python, and get publication-ready plots in seconds - all powered by robust, validated Fortran numerics.

**Status:** Ready to begin Phase 1, Milestone 1.1

**Last Updated:** November 16, 2025
