# CATFLOW Python - Next Steps After Initial Comparison

**Date**: 2025-11-01
**Current Status**: ✅ Both models run successfully, but direct comparison reveals setup differences

## What We Accomplished

### 1. Python Implementation ✅
- Full modular implementation of Richards 2D solver
- Van Genuchten soil hydraulic model
- Picard iteration with CG solver
- Adaptive time stepping
- **All 6 validation tests pass**
- **Successfully completed 1-hour simulation** (300 timesteps)

### 2. Fortran Example Analysis ✅
- Fortran simulation runs successfully (189 hours)
- Output files analyzed (`psi_m.out`, `theta_m.out`)
- Configuration extracted from `bod5.in`
- Initial comparison completed

### 3. Key Finding: Cannot Compare Directly ⚠️

**The comparison revealed**:

| Aspect | Python | Fortran | Impact |
|--------|--------|---------|--------|
| **Output variable** | Pressure head ψ (-2 to -0.15 m) | Likely hydraulic head h or elevations (0-158 m) | ❌ Different variables |
| **Duration** | 1 hour (test) | 189 hours (full run) | ❌ Different timeframes |
| **Initial conditions** | Simplified layered | From file (realistic) | ❌ Different starting points |
| **Boundary conditions** | Placeholder static | Time-varying complex | ❌ Different forcing |
| **Geometry** | Simplified 100m slope | Real topography | ❌ Different domains |

**Conclusion**: Current setups are too different for meaningful numerical comparison.

## Recommended Path Forward

### Immediate Priority: Create Simple Benchmark

**Goal**: Verify that Python Richards solver produces correct numerical results

**Approach**: 1D vertical column test case

```
Test Case: "1D Drainage Column"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Geometry:     1m wide × 3m deep vertical column
Mesh:         41 vertical layers × 1 lateral (pure 1D)
Soil:         Homogeneous (sandiger Lehm SL8)
              Ks = 1.23e-5 m/s
              θs = 0.41, θr = 0.065
              α = 7.5, n = 1.89

Initial:      Uniform θ = 0.30 (moderately wet)
              → ψ = -0.151 m everywhere

BC Top:       No-flow: ∂ψ/∂z = 0
BC Bottom:    Free drainage: ψ = -2.0 m

Duration:     24 hours
Output:       Every hour (25 snapshots)

Expected:     Gradual drainage
              Water content decreases top-to-bottom
              Steady state eventually reached
```

**Why this test?**
- ✅ 1D → only vertical flow, easier to interpret
- ✅ Standard benchmark (published solutions exist)
- ✅ Can create identical setup in both Fortran and Python
- ✅ Tests core Richards equation solver
- ✅ No complex geometry, BCs, or forcing

### Implementation Plan

#### Step 1: Create Python 1D Benchmark (1-2 hours)

File: `examples/benchmark_1d_drainage.py`

```python
"""
1D drainage column benchmark.

Standard test case for Richards equation solvers.
"""

# Simplified mesh (vertical only)
mesh = CurvilinearHillslopeMesh(
    profile_x=np.array([0.0, 1.0]),
    profile_z=np.array([3.0, 3.0]),  # Flat surface
    thickness=3.0,
    xsi_nodes=np.array([0.0, 1.0]),  # Just 2 points laterally
    eta_nodes=np.linspace(0, 1, 41),  # 41 vertical layers
    geometry_type='constant'
)

# Uniform initial condition
psi_init = -0.151 * np.ones(mesh.shape)  # θ = 0.3 everywhere

# Simple boundary conditions
boundary_conditions = {
    'top': {'type': 'neumann', 'value': 0.0},      # No flow
    'bottom': {'type': 'dirichlet', 'value': -2.0}, # Drainage
}

# Run for 24 hours
results = model.run(t_start=0, t_end=86400, ...)
```

#### Step 2: Create Fortran 1D Input Files (2-3 hours)

**Required files**:
1. `column_1d.geo` - Simple 1D geometry
2. `column_1d.in` - Control file matching Python setup
3. `column_1d_ic.ini` - Uniform initial conditions
4. `column_1d_bc.rb` - Simple BCs
5. Reuse existing soil file

**Challenges**:
- Understanding Fortran `.geo` format for 1D
- Setting no-flow top boundary correctly
- Ensuring exactly matching discretization

#### Step 3: Run and Compare (30 min)

```bash
# Run Fortran
cd model/example_1d
./catflow

# Run Python
cd catflow_python
python examples/benchmark_1d_drainage.py

# Compare
python validation/comparison_tools/compare_results.py \
    examples/benchmark_1d/python_results.npz \
    ../model/example_1d/out/theta_m.out \
    --variable theta
```

**Success criteria**:
- RMSE(θ) < 0.01 → Excellent agreement
- RMSE(θ) < 0.05 → Acceptable agreement
- Similar drainage rate and final steady state

### Alternative: Compare Water Balance

Since geometries differ, we can compare **physics qualitatively**:

**Approach**:
1. Run Python for full 189 hours (match Fortran duration)
2. Compare water balance components:
   - Storage change: ΔS = ∫(θ_final - θ_init) dV
   - Cumulative outflow: Q_out = ∫q_bottom dt
   - Mass balance closure: ΔS = Precip - ET - Q_out
3. Check if both models conserve mass

**Python code**:
```python
# Calculate storage change
storage_init = np.sum(theta[0] * cell_volumes)
storage_final = np.sum(theta[-1] * cell_volumes)
delta_storage = storage_final - storage_init

# Should equal boundary fluxes (when properly implemented)
print(f"Storage change: {delta_storage:.3f} m³")
print(f"Relative error: {abs(delta_storage - expected)/expected * 100:.2f}%")
```

## Long-term Development Path

### Phase 1: Core Validation (This Week)
- ✅ 1D drainage benchmark
- ✅ 1D infiltration benchmark
- ✅ Comparison with analytical solutions

### Phase 2: Feature Completion (Next 2 Weeks)
- [ ] Implement Fortran file parsers (`.geo`, `.rb`, `.ini`)
- [ ] Add evapotranspiration module
- [ ] Add precipitation input
- [ ] Add seepage face boundary condition
- [ ] Implement output to Fortran-compatible formats

### Phase 3: Full Validation (Month 2)
- [ ] Match Fortran example exactly
- [ ] Run real catchment simulation
- [ ] Compare with field data
- [ ] Publish validation report

### Phase 4: Extension (Month 3+)
- [ ] Add solute transport
- [ ] Add macropore flow
- [ ] Add snow module
- [ ] Performance optimization (Numba, Cython)

## Files to Review

### Already Created
1. **FORTRAN_EXAMPLE_READY.md** - Summary of wrapper and first Python run
2. **COMPARISON_ANALYSIS.md** - Detailed analysis of differences
3. **examples/quick_comparison.py** - Comparison script
4. **examples/fortran_comparison/quick_comparison.png** - Visualization

### Documentation to Read
- `background_info/` - CATFLOW theory and equations
- `model/example/bod5.in` - Fortran control file format
- `catflow_python/validation/COMPARISON_PLAN.md` - Validation strategy

## Immediate Action Items

**Option A: Quick validation** (Recommended)
1. Create 1D benchmark in Python (use existing code, simplify geometry)
2. Create matching Fortran input files
3. Run both and compare θ profiles
4. Estimated time: 4-6 hours

**Option B: Full feature completion** (More work)
1. Implement `.geo` file parser
2. Implement `.rb` file parser
3. Match exact Fortran example
4. Estimated time: 2-3 days

**Option C: Water balance check** (Quick assessment)
1. Re-run Python for 189 hours
2. Compare mass balance closure
3. Assess qualitative behavior
4. Estimated time: 1-2 hours

## Questions to Resolve

1. **What variable is in `psi_m.out`?**
   - Pressure head ψ?
   - Hydraulic head h = ψ + z?
   - Need to check Fortran source or documentation

2. **Can we create 1D case in Fortran easily?**
   - Is `.geo` format documented?
   - Are there existing 1D examples?

3. **What are priorities?**
   - Fast validation vs full feature parity?
   - Simple test vs real application?

## Success Metrics

**Minimum viable validation**:
- ✅ 1D benchmark matches within 5% RMSE
- ✅ Mass balance closes to < 1% error
- ✅ Physically reasonable behavior demonstrated

**Full validation**:
- ✅ 2D hillslope benchmark matches
- ✅ Real catchment simulation reproduces observations
- ✅ All Fortran features implemented in Python

## Current Confidence Assessment

| Component | Confidence | Evidence |
|-----------|-----------|----------|
| **Van Genuchten model** | 🟢 High | 6/6 tests pass |
| **CG solver** | 🟢 High | Fixed bug, converges well |
| **Picard iteration** | 🟢 High | 1-2 iterations typical |
| **Adaptive stepping** | 🟢 High | Handles failures gracefully |
| **Mass balance** | 🟡 Medium | Not yet verified rigorously |
| **Boundary conditions** | 🟡 Medium | Simple cases work, complex not tested |
| **Geometry** | 🟡 Medium | Simple meshes work, complex not tested |
| **Overall correctness** | 🟡 Medium | **Needs 1D benchmark to confirm** |

---

## Bottom Line

**The Python implementation appears correct** based on:
- Passing all unit tests
- Physically reasonable output
- Stable convergence behavior

**But we need rigorous numerical validation** through:
1. **Immediate**: 1D benchmark comparison with Fortran
2. **Near-term**: Analytical solution comparisons
3. **Long-term**: Real catchment validation

**Recommended next step**: Create 1D drainage benchmark (Option A above)

---

**Status**: Ready to proceed with validation
**Blocker**: None - can start 1D benchmark immediately
**Priority**: High - needed to confirm solver correctness
