# Fortran vs Python CATFLOW - Numerical Comparison Plan

## Overview

This document outlines the strategy for validating the Python CATFLOW implementation against the original Fortran CATFLOW model.

## Objectives

1. **Verify correctness** of Python implementation
2. **Quantify numerical differences** (if any)
3. **Identify sources of discrepancies**
4. **Establish acceptable error bounds**
5. **Document performance characteristics**

## Comparison Strategy

### Phase 1: Unit-Level Validation (✅ COMPLETE)

**Status**: All 6 Van Genuchten tests pass

- [x] Van Genuchten θ(ψ) function
- [x] Van Genuchten K(θ) function
- [x] Specific moisture capacity C(ψ)
- [x] Boundary conditions (saturation, residual)
- [x] Consistency checks

### Phase 2: Simple Test Cases

#### Test Case 1: 1D Vertical Column Infiltration

**Rationale**: Simplest case to validate core numerics without geometric complexity

**Setup**:
- 1D vertical column (1m depth)
- Uniform soil (Van Genuchten parameters)
- Constant infiltration at top
- Free drainage at bottom
- Initial condition: uniform suction

**Why this case**:
- Eliminates curvilinear coordinate complications
- Has analytical/semi-analytical solutions for validation
- Tests Richards equation solver fundamentals
- Tests time stepping and convergence

**Implementation**:
- Python: Degenerate 2D mesh (1 node wide)
- Fortran: Single hillslope with minimal lateral extent

**Comparison Metrics**:
1. Pressure head profiles at multiple times
2. Water content profiles
3. Infiltration rate (top flux)
4. Drainage rate (bottom flux)
5. Total water storage
6. Mass balance error
7. Number of iterations per timestep
8. Computational time

**Acceptance Criteria**:
- ψ differences < 0.01 m (1 cm)
- θ differences < 0.01 [-] (volumetric)
- Mass balance error < 0.1% for both
- Flux differences < 5%

#### Test Case 2: 1D Vertical Column Drainage

**Setup**:
- Same geometry as Test 1
- Initial condition: saturated
- No infiltration (atmospheric BC at top)
- Free drainage at bottom

**Why this case**:
- Tests drying process (opposite of infiltration)
- Tests nonlinear convergence in different regime
- Validates capacity function in drying

#### Test Case 3: Steady-State Flow on Sloped Hillslope

**Setup**:
- 2D hillslope with simple geometry
- Uniform soil
- Constant recharge (steady-state)
- Fixed head at bottom

**Why this case**:
- Tests curvilinear coordinates
- Tests metric tensor calculations
- Has steady-state analytical solution for validation
- Eliminates time-stepping differences

**Comparison Metrics**:
- 2D pressure head field
- 2D water content field
- Flow vectors (should be parallel to surface at steady-state)
- Mass balance (inflow = outflow)

#### Test Case 4: Transient Flow on Hillslope

**Setup**:
- Same geometry as Test 3
- Time-varying infiltration
- Transient simulation (24 hours)

**Why this case**:
- Complete test of all components
- Tests curvilinear + time stepping + nonlinearity
- Most similar to real simulations

### Phase 3: Complex Validation Cases

#### Test Case 5: Schaefer Catchment (if available in Fortran)

**Setup**:
- Use existing Schaefer test case from background_info/
- Compare with published results

## Implementation Approach

### Step 1: Create Benchmark Case Generator

Create a tool that generates **identical** inputs for both models:

```python
# validation/benchmark_cases/generate_1d_column.py

def generate_1d_column_case():
    """
    Generate inputs for 1D column test.

    Creates:
    - Python: mesh, initial conditions, soil params
    - Fortran: .geo, .ini, .bod, catflow.in files
    """
    pass
```

### Step 2: Run Both Models

```bash
# Run Python
python validation/run_python_benchmark.py --case 1d_column

# Run Fortran
cd validation/fortran_runs/1d_column
../../../model/catflow < catflow.in

# Or create wrapper script
python validation/run_fortran_benchmark.py --case 1d_column
```

### Step 3: Compare Outputs

```python
# validation/comparison_tools/compare_results.py

def compare_models(python_results, fortran_results):
    """
    Statistical comparison of model outputs.

    Metrics:
    - RMSE (Root Mean Square Error)
    - MAE (Mean Absolute Error)
    - Max absolute error
    - Correlation coefficient
    - Mass balance comparison
    """
    pass
```

### Step 4: Visualize Differences

```python
# validation/comparison_tools/visualize_comparison.py

def plot_comparison(python_results, fortran_results):
    """
    Create comparison plots:
    - Side-by-side fields
    - Difference maps
    - Time series comparison
    - Error evolution
    - Convergence comparison
    """
    pass
```

## File Format Compatibility

### Reading Fortran Output in Python

Fortran CATFLOW outputs (from your analysis):
- `relsat.out` - Relative saturation
- `psi.out` - Pressure head
- `theta.out` - Water content
- `bilanz.csv` - Water balance

Format:
```
time hillslope_id n_eta n_xsi
[matrix data]
```

Need to implement:
```python
# validation/comparison_tools/fortran_io.py

def read_fortran_matrix_output(filename):
    """Read Fortran CATFLOW matrix output."""
    pass

def read_fortran_balance(filename):
    """Read Fortran CATFLOW balance file."""
    pass
```

### Writing Fortran Input from Python

Need to generate:
- `.geo` files - Geometry (hang1.geo format)
- `.bod` files - Soil parameters
- `.ini` files - Initial conditions
- `catflow.in` - Control file

## Detailed Comparison Metrics

### 1. Field Comparison

For each output variable (ψ, θ, K):

```python
def compute_field_metrics(python_field, fortran_field):
    """
    Compute comprehensive field comparison metrics.
    """
    metrics = {
        'rmse': np.sqrt(np.mean((python_field - fortran_field)**2)),
        'mae': np.mean(np.abs(python_field - fortran_field)),
        'max_error': np.max(np.abs(python_field - fortran_field)),
        'mean_error': np.mean(python_field - fortran_field),  # Bias
        'correlation': np.corrcoef(python_field.flat, fortran_field.flat)[0,1],
        'relative_rmse': rmse / np.std(fortran_field),  # Normalized by variability
    }
    return metrics
```

### 2. Mass Balance Comparison

```python
def compare_mass_balance(python_balance, fortran_balance):
    """
    Compare water balance components.

    Components:
    - Storage change
    - Infiltration
    - Drainage
    - ET (when implemented)
    - Cumulative error
    """
    pass
```

### 3. Convergence Comparison

```python
def compare_convergence(python_history, fortran_history):
    """
    Compare convergence behavior.

    Metrics:
    - Average iterations per timestep
    - Maximum iterations
    - Failed timesteps
    - Time step adaptation patterns
    """
    pass
```

### 4. Performance Comparison

```python
def compare_performance(python_time, fortran_time, mesh_size):
    """
    Performance metrics.

    Reports:
    - Total wall time
    - Time per timestep
    - Time per node per timestep
    - Memory usage
    """
    pass
```

## Expected Sources of Differences

### 1. Numerical Discretization

**Potential Differences**:
- Finite difference approximations (order of accuracy)
- Gradient calculations (central vs forward/backward differences)
- Time discretization (explicit vs implicit components)

**How to check**:
- Print intermediate calculations
- Compare matrix assembly
- Check timestep-by-timestep

### 2. Linear Solver

**Potential Differences**:
- Fortran: Custom DCG solver
- Python: SciPy CG

**How to check**:
- Compare with same convergence tolerances
- Check number of iterations
- Compare residuals

### 3. Metric Tensor Calculations

**Potential Differences**:
- Coordinate transformation implementation
- Gradient calculations
- Jacobian computation

**How to check**:
- Compare mesh generation independently
- Verify g_ξ, g_η values node-by-node
- Check metric coefficients in assembly

### 4. Boundary Conditions

**Potential Differences**:
- Implementation of Dirichlet/Neumann BCs
- Treatment of corner nodes
- No-flow conditions

**How to check**:
- Compare BC application code
- Check boundary node equations

### 5. Time Stepping

**Potential Differences**:
- Adaptive stepping criteria
- Under-relaxation strategies
- Convergence criteria

**How to check**:
- Use fixed time steps initially
- Compare iteration counts
- Print Picard iteration history

## Debugging Strategy (If Large Differences Found)

### Level 1: Component Isolation

1. **Test soil model in isolation**
   - Compare θ(ψ), K(θ), C(ψ) for same inputs
   - Already done ✅

2. **Test mesh generation**
   - Compare node coordinates
   - Compare metric coefficients
   - Visualize both meshes overlaid

3. **Test matrix assembly**
   - For a single node, compare coefficient values
   - Check harmonic mean calculations
   - Verify metric tensor application

### Level 2: Single Timestep

1. Set identical initial conditions
2. Take one timestep with both models
3. Compare:
   - Matrix A structure (spy plot)
   - RHS vector b
   - Solution ψ^(n+1)
   - Residual norms

### Level 3: Controlled Progression

1. Start with very simple case (1D, coarse grid)
2. Gradually increase complexity:
   - Finer grid
   - 2D geometry
   - Curvilinear coordinates
   - Longer simulations

## Acceptance Criteria

### Excellent Agreement (Target)

- RMSE(ψ) < 0.01 m
- RMSE(θ) < 0.005
- Mass balance error < 0.01% for both
- Max error < 0.05 m (5 cm)

### Acceptable Agreement

- RMSE(ψ) < 0.05 m (5 cm)
- RMSE(θ) < 0.01
- Mass balance error < 0.1%
- Max error < 0.1 m (10 cm)
- Similar spatial patterns

### Needs Investigation

- RMSE(ψ) > 0.1 m
- Different spatial patterns
- Systematic bias
- Mass balance errors > 1%

## Timeline

### Week 1: Setup
- [x] Fix Van Genuchten tests ✅
- [ ] Create benchmark case generator
- [ ] Implement Fortran I/O readers
- [ ] Set up comparison framework

### Week 2: 1D Tests
- [ ] Generate 1D column case
- [ ] Run both models
- [ ] Compare results
- [ ] Debug if needed

### Week 3: 2D Tests
- [ ] Generate simple hillslope case
- [ ] Run both models
- [ ] Compare results
- [ ] Analyze differences

### Week 4: Documentation
- [ ] Document all differences found
- [ ] Create comparison report
- [ ] Write recommendations

## Deliverables

1. **Benchmark Cases** (in validation/benchmark_cases/)
   - 1d_column/
   - 1d_drainage/
   - 2d_hillslope_steady/
   - 2d_hillslope_transient/

2. **Comparison Tools** (in validation/comparison_tools/)
   - fortran_io.py
   - compare_results.py
   - visualize_comparison.py
   - metrics.py

3. **Reports**
   - comparison_report.md
   - validation_figures/

4. **Scripts**
   - run_all_benchmarks.sh
   - generate_comparison_report.py

## Next Immediate Steps

1. ✅ **Fix capacity test** - DONE
2. **Create 1D column benchmark generator** - Start here
3. **Implement Fortran output reader**
4. **Run first comparison**

---

**Created**: 2024-12-01
**Status**: In Progress
**Last Updated**: 2024-12-01
