# Roadmap to 100% Working CATFLOW Streamlined

**Current Status**: 40% complete (infrastructure done, 1/37 physics files converted)
**Goal**: Fully working, validated CATFLOW with streamlined code

---

## File Inventory: 37 Source Files

### ✅ Converted (1 file)
- [x] **KOEFF.f** → koeff.f90 (hydraulic conductivity averaging)

### Priority 1: Core Solver (CRITICAL - 6 files)

**Without these, model cannot run at all:**

1. [ ] **CATFLOW.f** (600+ lines)
   - Main program
   - Initialization
   - Time loop
   - **CRITICAL**: This is the entry point

2. [ ] **STEPS.f** (400+ lines)
   - Time stepping logic
   - Solver selection
   - Convergence checking
   - **CRITICAL**: Heart of the model

3. [ ] **HG.f** / **HG_OPERA.f**
   - Matrix operations
   - Linear system solver
   - **CRITICAL**: Numerical engine

4. [ ] **KOEFFRB.f** / **KOEFFBR.f**
   - Boundary condition coefficients
   - Works with KOEFF.f
   - **CRITICAL**: BC application

5. [ ] **KINNEN.f**
   - Internal flux calculations
   - Element-to-element flow
   - **CRITICAL**: Flow physics

6. [ ] **KSENKEN.f**
   - Sink/source terms
   - Root water uptake
   - **CRITICAL**: Source/sink handling

**Estimated time**: 2-3 weeks
**Required for**: Basic infiltration simulation

---

### Priority 2: Surface & Atmosphere (4 files)

**Needed for realistic rainfall-runoff:**

7. [ ] **OBERFLW.f** (300+ lines)
   - Surface flow routing
   - Kinematic wave
   - Ponding dynamics
   - **CRITICAL for rainfall-runoff**

8. [ ] **ETINTZ.f** (500+ lines)
   - Evapotranspiration
   - Interception
   - Energy balance
   - **CRITICAL for water balance**

9. [ ] **CALBNA.f**
   - Climate data processing
   - Boundary condition time series
   - **NEEDED for forcing**

10. [ ] **RD_RB.f** / **RDRBF.f**
    - Read boundary conditions
    - File I/O for BCs
    - **NEEDED for forcing**

**Estimated time**: 2 weeks
**Required for**: Full surface hydrology

---

### Priority 3: Mass Balance & Validation (3 files)

**Needed to verify model is working correctly:**

11. [ ] **BALANC.f** (400+ lines)
    - Mass balance calculation
    - Water budget tracking
    - Error checking
    - **CRITICAL for validation**

12. [ ] **CALGEO.f**
    - Geometric calculations
    - Control volume setup
    - **NEEDED for balance**

13. [ ] **rd_wr.f**
    - Output routines
    - Result writing
    - **NEEDED to see results**

**Estimated time**: 1 week
**Required for**: Validation and diagnostics

---

### Priority 4: Particle Tracking (4 files)

**Optional - for solute transport:**

14. [ ] **P_STEPB.f**
    - Particle time stepping
    - Advection-dispersion
    - **OPTIONAL** (can skip initially)

15. [ ] **PTKINJ2.f**
    - Particle injection
    - **OPTIONAL**

16. [ ] **PMASS.f**
    - Particle mass calculation
    - **OPTIONAL**

17. [ ] **V_INTB.f** / **V_STRB.f**
    - Particle velocity interpolation
    - **OPTIONAL**

**Estimated time**: 2 weeks (if needed)
**Required for**: Solute transport simulations

---

### Priority 5: Supporting Functions (19 files)

**These support the core routines:**

18. [ ] **BODTAB.f** - Soil property tables
19. [ ] **ADDSTEPS.f** - Additional time step operations
20. [ ] **C_IPOB.f** - Interpolation
21. [ ] **DCG.f** - Solver utilities
22. [ ] **FIL_IO.f** - File I/O management
23. [ ] **GGCROSS.f** - Grid crossing detection
24. [ ] **RDMINF.f** - Read main input
25. [ ] **RDZRBF.f** - Read time series
26. [ ] **TCALW.f** - Time calculations
27. [ ] **ZUFALL.f** - Random numbers
28. [ ] **REL_SECW.f** - Relative permeability
29. [ ] **POINT_IN_POLYGON.f** - Geometry
30. [ ] **BACHW.f** - Channel routing
31. [ ] Others...

**Estimated time**: 2-3 weeks
**Required for**: Full functionality

---

## Conversion Strategy: How to Reach 100%

### Phase-by-Phase Approach

#### **Phase 4a: Core Solver (IMMEDIATE - 3 weeks)**

Convert Priority 1 files in order:

1. **Week 1**: STEPS.f, HG.f
   - Time stepping and solver
   - Most complex numerics

2. **Week 2**: KINNEN.f, KOEFFRB.f, KSENKEN.f
   - Flux calculations
   - BC application
   - Sources/sinks

3. **Week 3**: CATFLOW.f
   - Main program
   - Integration of all components
   - **FIRST WORKING MODEL**

**Milestone**: Can run simple infiltration test

---

#### **Phase 4b: Surface Hydrology (2 weeks)**

Convert Priority 2 files:

4. **Week 4**: OBERFLW.f, ETINTZ.f
   - Surface routing
   - ET calculations

5. **Week 5**: CALBNA.f, RD_RB.f
   - Climate forcing
   - BC file reading

**Milestone**: Can run rainfall-runoff scenarios

---

#### **Phase 4c: Validation (1 week)**

Convert Priority 3 files:

6. **Week 6**: BALANC.f, CALGEO.f, rd_wr.f
   - Mass balance tracking
   - Output generation

**Milestone**: Can verify conservation, produce results

---

#### **Phase 5: Testing & Validation (2 weeks)**

7. **Week 7**: Create test cases
   - Simple infiltration
   - Rainfall-runoff
   - ET scenarios

8. **Week 8**: Validation against original
   - Bit-for-bit comparison
   - Performance benchmarking
   - Bug fixes

**Milestone**: Validated working model

---

#### **Phase 6: Optional & Documentation (2-3 weeks)**

9. **Week 9-10**: Optional features
   - Particle tracking (if needed)
   - Advanced solvers
   - Additional BC types

10. **Week 11**: Documentation
    - User guide
    - API documentation
    - Examples

**Milestone**: Production-ready code

---

## What Makes This Achievable?

### ✅ Hard Work Already Done

**Module architecture** (40% of effort):
- All data structures modernized
- Memory management solved
- Build system working
- **Pattern established**

### 🔧 Mechanical Work Remaining

**Physics conversion** (60% of effort):
- Follow established template
- Replace `include` → `use module`
- Test each subroutine
- **Straightforward, just time-consuming**

### Example: Converting a Typical Subroutine

**Before (Fortran 77):**
```fortran
      subroutine example(ih, dt)
      include 'dim.inc'      ! 155 lines
      include 'hgfest.inc'   ! 259 lines
      include 'hgvari.inc'   ! 200 lines
      include 'soil.inc'     ! 51 lines

      ! Physics code...
      end
```

**After (Fortran 90) - following KOEFF pattern:**
```fortran
subroutine example(ih, dt)
    use state_data_module, only: needed_vars
    use mesh_geometry_module, only: needed_geom
    use soil_hydraulics_module, only: needed_soil
    implicit none

    integer(4), intent(in) :: ih
    real(8), intent(in) :: dt

    ! Same physics code (unchanged!)
end subroutine
```

**Key point**: The physics code itself doesn't change!

---

## Realistic Timeline to 100%

### Aggressive Schedule (Full-Time Work)

```
Week 1-3:  Core solver (Priority 1)          → 50% complete
Week 4-5:  Surface hydrology (Priority 2)    → 65% complete
Week 6:    Validation setup (Priority 3)     → 75% complete
Week 7-8:  Testing & validation              → 90% complete
Week 9-11: Cleanup & documentation           → 100% complete

TOTAL: ~11 weeks full-time
```

### Realistic Schedule (Part-Time Work)

```
Month 1-2:  Core solver                      → 50% complete
Month 3:    Surface hydrology                → 65% complete
Month 4:    Validation                       → 75% complete
Month 5:    Testing                          → 90% complete
Month 6:    Documentation                    → 100% complete

TOTAL: ~6 months part-time
```

### Minimal Working Model (Fast Track)

```
Week 1-2:  STEPS, HG, KINNEN only
Week 3:    Simplified CATFLOW main
Week 4:    Basic validation

TOTAL: 4 weeks to minimal working model
       (no surface flow, simplified ET)
```

---

## Why This is Feasible

### 1. Foundation is Solid ✅

- All data structures work
- Memory management tested
- Build system automated
- **No more architectural decisions**

### 2. Physics Unchanged ✅

- Only wrapping code changes
- Core algorithms identical
- **No new science needed**

### 3. Pattern Established ✅

- KOEFF shows the way
- Repeat for each file
- **Mechanical process**

### 4. Incremental Testing ✅

- Test each subroutine
- Catch bugs early
- **Safe, step-by-step**

---

## Validation Strategy

### Level 1: Unit Tests (Per Subroutine)

```fortran
! Test each converted subroutine
call test_koeff()     ! ✅ Already done
call test_steps()     ! Compare old vs new
call test_kinnen()    ! Verify fluxes
```

### Level 2: Integration Tests

```fortran
! Test combined functionality
call test_one_timestep()
call test_infiltration()
call test_drainage()
```

### Level 3: Full Model Validation

```fortran
! Compare against original CATFLOW
- Simple infiltration: bit-identical results
- Rainfall event: same hydrograph
- Long-term simulation: same water balance
```

---

## Risk Mitigation

### Risk 1: Bug Introduction

**Mitigation**:
- Convert one file at a time
- Test immediately after conversion
- Keep original code for comparison
- **Bit-for-bit validation**

### Risk 2: Missing Dependencies

**Mitigation**:
- Dependency graph already mapped
- Follow Priority order
- **Test compile after each file**

### Risk 3: Time Overrun

**Mitigation**:
- Start with Priority 1 (minimal working model)
- Can stop at any milestone
- **Each phase adds functionality**

---

## Milestones to Track Progress

### Milestone 1: Core Solver Working (50%)
- ✅ Can solve Richards equation
- ✅ Can run one timestep
- ✅ Convergence achieved
**DELIVERABLE**: Simple infiltration test passes

### Milestone 2: Surface Hydrology (70%)
- ✅ Rainfall input working
- ✅ Surface routing functional
- ✅ ET calculations working
**DELIVERABLE**: Rainfall-runoff simulation

### Milestone 3: Validated Model (90%)
- ✅ Mass balance closes
- ✅ Results match original
- ✅ Performance acceptable
**DELIVERABLE**: Full working model

### Milestone 4: Production Ready (100%)
- ✅ All features working
- ✅ Documentation complete
- ✅ Test suite passing
**DELIVERABLE**: Release version

---

## What Success Looks Like

### Minimum Success (Milestone 1)

```bash
$ ./catflow_streamlined simple_infiltration.inp
Initializing...
Time step 1: dt = 3600 s, iterations = 5, converged
Time step 2: dt = 3600 s, iterations = 4, converged
...
Simulation complete: 100 steps, 100% convergence
Mass balance error: 0.001%
```

### Full Success (Milestone 4)

```bash
$ ./catflow_streamlined complex_hillslope.inp
CATFLOW Streamlined v2.0
- Modern Fortran 90 modules
- 98% memory reduction
- 3x faster compilation
- Identical physics to original

Results written to: hillslope_results.nc
Mass balance: PERFECT (< 1e-10%)
Performance: 20% faster than original
```

---

## Bottom Line

**Current**: 40% complete (infrastructure ✅, 1/37 files ✅)

**To 100%**: Convert remaining 36 files following established pattern

**Time Required**:
- Minimal working model: **4 weeks** (Priority 1 only)
- Full featured model: **11 weeks** full-time or **6 months** part-time
- Production ready: **+2 weeks** for testing/docs

**Key Insight**: The hard conceptual work is done. The remaining work is mechanical but time-consuming - converting each of 36 files following the KOEFF template.

**Next Steps**:
1. Decide on target (minimal vs full model)
2. Start with Priority 1 files (core solver)
3. Test incrementally
4. Achieve first working model in ~4 weeks

---

**The path to 100% is clear, feasible, and well-defined!** 🎯
