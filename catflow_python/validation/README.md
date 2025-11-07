

# CATFLOW Validation Framework

## Overview

This directory contains tools and test cases for validating the Python CATFLOW implementation against the original Fortran CATFLOW model.

## Directory Structure

```
validation/
├── README.md                    # This file
├── COMPARISON_PLAN.md          # Detailed comparison strategy
├── benchmark_cases/            # Test case generators
│   └── generate_1d_column.py  # 1D vertical column case
├── comparison_tools/           # Analysis scripts
│   ├── fortran_io.py          # Read/write Fortran files
│   └── compare_results.py     # Statistical comparison
└── results/                    # Comparison results (generated)
```

## Quick Start

### Step 1: Generate Benchmark Case

```bash
cd benchmark_cases
python generate_1d_column.py
```

This creates:
- `1d_column_infiltration/python/` - Python case and results
- `1d_column_infiltration/fortran/` - Fortran input files (template)

### Step 2: Run Fortran CATFLOW

```bash
cd 1d_column_infiltration/fortran
# Adapt the input files as needed for your Fortran CATFLOW installation
../../model/catflow < catflow.in
```

### Step 3: Compare Results

```bash
cd comparison_tools
python compare_results.py \
    ../benchmark_cases/1d_column_infiltration/python/python_results.npz \
    ../benchmark_cases/1d_column_infiltration/fortran/psi.out \
    --output-dir ../results/1d_column
```

This produces:
- Statistical comparison table
- Comparison plots (side-by-side, differences, scatter, etc.)
- Time series evolution plots

## Test Cases

### 1. 1D Vertical Column Infiltration

**File**: `benchmark_cases/generate_1d_column.py`

**Setup**:
- Vertical column: 1 m depth
- Soil: Loamy sand (Van Genuchten)
- BC top: ψ = -0.1 m (wet infiltration)
- BC bottom: ψ = -1.0 m (drainage)
- Initial: ψ = -0.5 m (uniform)
- Duration: 1 hour

**Purpose**: Simplest case to validate core numerics without geometric complexity

**Expected Agreement**: RMSE < 0.01 m

### 2. More test cases to be added...

## Comparison Tools

### fortran_io.py

Utilities for reading/writing Fortran CATFLOW files:

```python
from comparison_tools.fortran_io import read_fortran_matrix_output

# Read Fortran output
results = read_fortran_matrix_output('psi.out')
times = results['times']
psi_data = results['data']  # List of 2D arrays

# Read water balance
balance = read_fortran_balance('bilanz.csv')
```

Functions:
- `read_fortran_matrix_output()` - Read .out files (psi, theta, etc.)
- `read_fortran_balance()` - Read bilanz.csv
- `write_fortran_initial_conditions()` - Write .ini files
- `write_fortran_soil_file()` - Write .bod files
- `compare_with_python_results()` - Align Fortran/Python data

### compare_results.py

Comprehensive comparison and visualization:

```bash
python compare_results.py <python_npz> <fortran_out> [options]

Options:
  --variable VAR        Variable to compare (default: psi)
  --output-dir DIR      Output directory (default: comparison_output)
```

Produces:
- Statistical metrics (RMSE, MAE, max error, correlation, etc.)
- Comparison plots:
  - Side-by-side fields
  - Difference maps
  - Scatter plots
  - Histograms
  - Vertical/lateral profiles
- Time series evolution

## Validation Workflow

### Phase 1: Unit Tests (✅ COMPLETE)

```bash
cd tests
python test_van_genuchten.py
```

All 6 tests pass ✅

### Phase 2: 1D Column (Current)

1. **Generate case**:
   ```bash
   python benchmark_cases/generate_1d_column.py
   ```

2. **Run Python** (done automatically by generator)

3. **Run Fortran**:
   - Adapt generated input files
   - Run Fortran CATFLOW
   - Ensure output format matches expectations

4. **Compare**:
   ```bash
   python comparison_tools/compare_results.py \
       benchmark_cases/1d_column_infiltration/python/python_results.npz \
       benchmark_cases/1d_column_infiltration/fortran/psi.out
   ```

5. **Analyze differences**:
   - Check statistics table
   - Examine plots
   - If RMSE > 0.05 m, investigate sources

### Phase 3: 2D Hillslope

To be implemented...

## Comparison Metrics

### Statistical Metrics

- **RMSE** (Root Mean Square Error): Overall accuracy
- **MAE** (Mean Absolute Error): Average error magnitude
- **Max error**: Worst-case difference
- **Mean error**: Systematic bias
- **Correlation**: Spatial pattern similarity
- **R²**: Goodness of fit
- **Percentiles**: Error distribution

### Acceptance Criteria

| Metric | Excellent | Good | Acceptable | Poor |
|--------|-----------|------|------------|------|
| RMSE(ψ) | < 0.01 m | < 0.05 m | < 0.1 m | > 0.1 m |
| RMSE(θ) | < 0.005 | < 0.01 | < 0.02 | > 0.02 |
| Mass balance | < 0.01% | < 0.1% | < 1% | > 1% |
| Correlation | > 0.99 | > 0.95 | > 0.90 | < 0.90 |

## Troubleshooting

### Issue: No common timesteps found

**Cause**: Different output times between models

**Solution**:
- Check Python output times in config
- Adjust Fortran output frequency
- Use time interpolation (not yet implemented)

### Issue: Different mesh sizes

**Cause**: Mesh generation differs

**Solution**:
- Use same discretization (n_eta, n_xsi)
- Check mesh generation independently
- Compare coordinate arrays

### Issue: Large RMSE but good spatial pattern

**Cause**: Systematic offset or different steady-state

**Solution**:
- Check boundary conditions are identical
- Check soil parameters exactly match
- Look at mean error (bias)

### Issue: Reading Fortran file fails

**Cause**: Format differences

**Solution**:
- Check file format in Fortran CATFLOW version
- Adapt `fortran_io.py` read functions
- Add debug prints to see what's being read

## Expected Differences

### Acceptable Differences

1. **Round-off errors**: O(1e-6) due to floating-point arithmetic
2. **Iteration counts**: Different solvers may converge in different iterations
3. **Time step sizes**: If using adaptive stepping

### Unacceptable Differences

1. **Spatial patterns**: Should match even if magnitudes differ slightly
2. **Mass balance**: Both should conserve mass to < 0.1%
3. **Steady-state**: Should converge to same values
4. **Convergence failure**: If one fails to converge, investigate

## Debugging Strategy

If large differences found:

### Level 1: Check Inputs

1. **Verify soil parameters match**:
   ```python
   # Python
   print(soil_params)
   # Fortran: check .bod file
   ```

2. **Verify boundary conditions match**:
   ```python
   print(boundary_conditions)
   # Fortran: check control file
   ```

3. **Verify initial conditions match**:
   ```python
   print(initial_psi)
   # Fortran: check .ini file
   ```

### Level 2: Single Timestep

1. Take one timestep with both models
2. Compare intermediate results:
   - Matrix A (spy plot)
   - RHS vector b
   - Solution ψ^(n+1)

### Level 3: Component Isolation

1. Test soil model separately (already done ✅)
2. Test mesh generation
3. Test matrix assembly
4. Test solver

### Level 4: Progressive Complexity

1. Start with coarsest mesh
2. Start with shortest duration
3. Use fixed time steps
4. Gradually increase complexity

## Contributing

To add new test cases:

1. Create generator script in `benchmark_cases/`
2. Follow the pattern of `generate_1d_column.py`
3. Document in this README
4. Add to COMPARISON_PLAN.md

## References

- Fortran CATFLOW documentation: `../background_info/`
- Python implementation: `../catflow/`
- Test suite: `../tests/`

## Status

- [x] Unit tests (Van Genuchten) ✅
- [x] Comparison framework ✅
- [x] 1D column generator ✅
- [x] Fortran I/O readers ✅
- [x] Statistical comparison ✅
- [ ] Run first comparison
- [ ] Debug and iterate
- [ ] 2D hillslope case
- [ ] Complex validation

## Contact

For issues or questions about the validation framework, see the main README.md.

---

**Last Updated**: 2024-12-01
**Status**: Framework complete, ready for first comparison run
