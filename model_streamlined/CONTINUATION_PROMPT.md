# CATFLOW Streamlining: Continuation Prompt for Claude Code

**Purpose**: Complete the modernization of CATFLOW Fortran code while preserving 100% of scientific functionality
**Current Progress**: 40% complete (infrastructure done, 1 of 37 physics files converted)
**Target**: Fully working, validated model with streamlined code

---

## CRITICAL PRINCIPLES - MUST FOLLOW

### 1. Scientific Rigor - ABSOLUTE PRIORITY

**⚠️ NON-NEGOTIABLE REQUIREMENTS:**

- **PRESERVE ALL PHYSICS**: Every equation, every coefficient, every algorithm MUST remain identical
- **BIT-IDENTICAL RESULTS**: Converted code must produce exactly the same numerical results as original
- **NO SIMPLIFICATIONS**: Do not simplify physics "for clarity" - complexity exists for scientific reasons
- **VALIDATE IMMEDIATELY**: Test each converted subroutine against original before proceeding
- **DOCUMENT UNCERTAINTIES**: If anything is unclear, FLAG IT - do not guess

### 2. Physical Truth Over Code Beauty

**When in conflict, ALWAYS choose:**
- ✅ Correct physics (even if code is complex)
- ✅ Numerical stability (even if slower)
- ✅ Mass conservation (exact to machine precision)
- ✅ Original algorithm (proven over 40 years)

**NEVER sacrifice:**
- ❌ Physical accuracy for "cleaner code"
- ❌ Numerical precision for "readability"
- ❌ Proven methods for "modern approaches"
- ❌ Conservation properties for "performance"

### 3. Full Functionality - No Features Lost

**ALL original capabilities must be preserved:**
- All solver options (Picard, Newton, etc.)
- All boundary condition types (Dirichlet, Neumann, mixed, inequality)
- All hydraulic property models (Van Genuchten, Brooks-Corey, tables)
- All averaging methods (arithmetic, geometric, K(θ_mean))
- Macropore flow, particle tracking, anisotropy
- Surface routing (kinematic wave), ET (Penman-Monteith)
- All input/output formats and options

---

## BACKGROUND: What Has Been Completed

### ✅ Infrastructure (100% Complete)

**Six modules created** (2,200+ lines modern Fortran):

1. **constants_module.f90** - All dimension parameters
2. **state_data_module.f90** - Dynamic state arrays with pointer swapping
3. **mesh_geometry_module.f90** - Curvilinear coordinates, metric coefficients
4. **soil_hydraulics_module.f90** - Van Genuchten, soil properties
5. **boundary_conditions_module.f90** - All BC types, climate, ET components
6. **time_module.f90** - Time management and stepping

**Key achievements:**
- 98-99% memory reduction (dynamic allocation)
- Module compilation working (Makefile automated)
- Build system with dependency tracking
- Test framework established
- Pattern for conversion established

### ✅ Physics Code Template (1 file complete)

**koeff.f90** - Hydraulic conductivity averaging
- Shows conversion pattern: `include` → `use module, only:`
- Demonstrates three averaging methods preserved
- Adds comprehensive documentation
- Uses modern Fortran structures (select case)
- **THIS IS THE TEMPLATE TO FOLLOW**

### ⏳ Remaining: 36 Physics Files + Main Program

**Priority 1 (CRITICAL - 5 files):**
- CATFLOW.f (main program, 600+ lines)
- STEPS.f (time stepping, 400+ lines)
- HG.f / HG_OPERA.f (solver)
- KINNEN.f (internal fluxes)
- KOEFFRB.f (BC coefficients)

**Priority 2-5:** 31 additional files (see ROADMAP_TO_100_PERCENT.md)

---

## WORK PLAN: Priority Order

### Phase 4a: Core Solver (IMMEDIATE)

**Goal**: Minimal working model (infiltration simulation)
**Files to convert**: Priority 1 (5 files)
**Expected outcome**: Can run basic test case
**Timeline**: 3-4 weeks full-time

#### Step 1: Time Stepping (STEPS.f)

**Location**: `/model/src/STEPS.f` → `/model_streamlined/physics/steps.f90`

**What it does:**
- Manages adaptive time stepping
- Selects solver method
- Handles convergence checking
- Controls iteration loops

**Conversion requirements:**
```fortran
! MUST preserve:
- All solver options (irsol = 1,2,3,4,5)
- Picard iteration logic
- Time step adaptation (dt_min, dt_max, dt_exp)
- Convergence criteria (piceps, cgeps)
- Iteration limit handling

! Key modules needed:
use state_data_module
use time_module
use constants_module
use mesh_geometry_module
```

**Validation:**
- Test each solver option separately
- Verify convergence criteria identical
- Check time step adaptation matches original
- **MUST: Compare iteration counts for same problem**

#### Step 2: Linear Solver (HG.f, HG_OPERA.f)

**Location**: `/model/src/HG.f` → `/model_streamlined/physics/hg.f90`

**What it does:**
- Sets up coefficient matrix
- Solves linear system A·x = b
- Applies boundary conditions to matrix
- Handles tri-diagonal systems (for 2D) or full matrix (for 3D)

**Conversion requirements:**
```fortran
! MUST preserve:
- Matrix structure (tri-diagonal or banded)
- Solver algorithm (Gaussian elimination, CG, etc.)
- Numerical precision (double precision throughout)
- BC application to matrix

! CRITICAL: Matrix indexing
- Off-diagonal elements: Fx_m1, Fx_p1, Fe_m1, Fe_p1
- Diagonal: Fx_00, Fe_00
- Right hand side: RS
```

**Validation:**
- Check matrix structure identical
- Verify solution vector matches
- Test ill-conditioned cases
- **MUST: Bit-identical solution for same matrix**

#### Step 3: Internal Fluxes (KINNEN.f)

**Location**: `/model/src/KINNEN.f` → `/model_streamlined/physics/kinnen.f90`

**What it does:**
- Calculates fluxes between elements
- Uses hydraulic conductivity from KOEFF
- Computes capillary gradients
- Handles unsaturated flow

**Conversion requirements:**
```fortran
! MUST preserve:
- Flux calculation formula (Darcy's law)
- Gradient calculations (pressure + gravity)
- Conductivity interpolation (from KOEFF)
- Treatment of saturated/unsaturated interface

! Key physics:
q = -K * (∇ψ + ∇z)  // Darcy-Buckingham equation
where K = K(θ) from averaged conductivity
```

**Validation:**
- Test flux magnitude and direction
- Verify gradient calculations
- Check saturated/unsaturated transitions
- **MUST: Flux continuity maintained**

#### Step 4: Boundary Condition Coefficients (KOEFFRB.f)

**Location**: `/model/src/KOEFFRB.f` → `/model_streamlined/physics/koeffrb.f90`

**What it does:**
- Applies BC to coefficient matrix
- Handles time-varying BCs
- Implements inequality BC (switching Dirichlet/Neumann)
- Computes BC fluxes

**Conversion requirements:**
```fortran
! MUST preserve:
- All BC types: Dirichlet (type 1), Neumann (type 2), mixed (type 3)
- Inequality BC logic (surface ponding, seepage faces)
- Time interpolation of BC values
- BC sign conventions (vorz_u, vorz_o, vorz_r, vorz_l)

! BC modules:
use boundary_conditions_module
```

**Validation:**
- Test each BC type separately
- Verify inequality BC switching
- Check time interpolation accuracy
- **MUST: BC fluxes match original**

#### Step 5: Main Program Integration (CATFLOW.f)

**Location**: `/model/src/CATFLOW.f` → `/model_streamlined/catflow_main.f90`

**What it does:**
- Initializes all modules
- Reads input files
- Manages time loop
- Calls solver routines
- Writes output

**Conversion requirements:**
```fortran
program catflow_streamlined
    use constants_module
    use state_data_module
    use mesh_geometry_module
    use soil_hydraulics_module
    use boundary_conditions_module
    use time_module
    use koeff_module
    use steps_module
    ! etc.

    implicit none

    ! Initialize
    call init_constants()
    call allocate_all_modules()
    call read_input_files()

    ! Time loop
    do while (t_act < t_end)
        call steps(ih, dt)  ! Time stepping
        call write_output()
        t_act = t_act + dt
    end do

    ! Cleanup
    call deallocate_all_modules()

end program catflow_streamlined
```

**Critical integration points:**
- All modules initialized before use
- Input file reading (preserve format exactly)
- Time loop structure (preserve control flow)
- Output format (preserve for comparison)

**Validation:**
- Run simple infiltration test
- Compare output files with original
- Check mass balance closure
- **MUST: Identical results for test case**

---

### Phase 4b: Surface Hydrology

**Goal**: Add rainfall-runoff and ET
**Files**: OBERFLW.f, ETINTZ.f, CALBNA.f, RD_RB.f
**Timeline**: 2 weeks

#### Step 6: Surface Flow (OBERFLW.f)

**CRITICAL PHYSICS:**
- Kinematic wave equation for surface routing
- COURANT stability criterion (cour ≤ 0.67)
- Sub-time-stepping when unstable
- Ponding depth dynamics

**Must preserve:**
```fortran
! Kinematic wave:
∂h/∂t + ∂q/∂x = R - I
where q = v·h, v = k·h^m·S^n

! COURANT check:
cour = (5/3) * v * dt / dx
if (cour > 0.67) reduce dt and restart
```

#### Step 7: Evapotranspiration (ETINTZ.f)

**CRITICAL PHYSICS:**
- Full Penman-Monteith energy balance
- Solar radiation with topographic shading
- Canopy resistance (stomatal control)
- Soil resistance (Kolle model)
- Root water uptake distribution

**Must preserve:**
```fortran
! Penman-Monteith:
ET = (Δ·Rn + ρa·cp·VPD/ra) / (Δ + γ·(1 + rs/ra))

! Components preserved:
- Net radiation (Rn) with shortwave/longwave
- Aerodynamic resistance (ra)
- Surface resistance (rs)
- Horizon angle effects on radiation
```

---

### Phase 4c: Mass Balance & Output

**Goal**: Validation and diagnostics
**Files**: BALANC.f, CALGEO.f, rd_wr.f
**Timeline**: 1 week

#### Step 8: Mass Balance (BALANC.f)

**CRITICAL FOR VALIDATION:**
- Track every flux in and out
- Control volume framework
- Check closure at machine precision
- Report any imbalances

**Must track:**
- Rainfall input
- Runoff output
- ET losses
- Deep drainage
- Boundary fluxes
- Storage change
- **MUST: ΔStorage = Inputs - Outputs to ε < 1e-10**

---

## CONVERSION STANDARDS

### Code Structure Requirements

#### 1. Module Pattern (Follow koeff.f90 exactly)

```fortran
!===============================================================================
! MODULE: example_module
!
! PURPOSE: [Clear description]
!
! DESCRIPTION: [What physics/numerics this implements]
!
! ORIGINAL: EXAMPLE.f (Fortran 77)
! AUTHOR: CATFLOW Streamlined
! DATE: [Date]
!===============================================================================
module example_module
    ! Import only what's needed
    use state_data_module, only: specific_vars
    use mesh_geometry_module, only: specific_geom
    implicit none
    private

    ! Public interface
    public :: example_subroutine

contains

    subroutine example_subroutine(ih, dt)
        ! Type declarations
        integer(4), intent(in) :: ih
        real(8), intent(in) :: dt

        ! Local variables
        integer(4) :: iv, il
        real(8) :: temp_var

        ! Physics code (preserve exactly!)
        do iv = 1, iacnv(ih)
            do il = 1, iacnl(ih)
                ! Original algorithm preserved
            end do
        end do

    end subroutine example_subroutine

end module example_module
```

#### 2. Documentation Requirements

**Every subroutine must have:**
```fortran
!===========================================================================
! SUBROUTINE: name
!
! PURPOSE: [What it does]
!
! DESCRIPTION: [Physics/algorithm details]
!   Key equations preserved:
!   - [List critical equations]
!
! ARGUMENTS:
!   ih - Hillslope index
!   dt - Time step [s]
!
! PHYSICS NOTES:
!   [Any critical physical assumptions]
!   [Any numerical considerations]
!
! VALIDATION:
!   [How to verify correctness]
!===========================================================================
```

#### 3. Variable Naming

**Preserve original names when possible:**
```fortran
! Good (preserves scientific meaning):
theta     ! Water content
psi       ! Pressure head
durchl    ! Hydraulic conductivity (German: durchlässigkeit)
iacnv     ! Active nodes in vertical direction

! Avoid renaming unless truly confusing
```

#### 4. Type Safety

```fortran
! Always use:
implicit none
integer(4) :: i, iv, il, ih          ! Explicit sizing
real(8) :: psi, theta, k              ! Double precision
intent(in) :: readonly_params         ! Explicit intent
intent(inout) :: modified_variables
```

---

## VALIDATION PROTOCOL

### Level 1: Unit Test (Per Subroutine)

**After converting each file:**

1. **Compile test:**
   ```bash
   make clean && make
   # MUST compile with zero warnings
   ```

2. **Create unit test:**
   ```fortran
   program test_[subroutine]
       ! Set up identical inputs
       ! Call old version (if accessible)
       ! Call new version
       ! Compare outputs bit-for-bit
       ! Report any differences > 1e-15
   end program
   ```

3. **Verify physics:**
   - Check equation implementation line-by-line
   - Verify boundary conditions applied correctly
   - Test edge cases (saturated, dry, etc.)

### Level 2: Integration Test

**After completing Priority 1:**

1. **Simple infiltration:**
   ```bash
   # Run both old and new CATFLOW
   ./catflow_original infiltration.inp > old.out
   ./catflow_streamlined infiltration.inp > new.out

   # Compare results
   diff old.out new.out  # Should be identical
   ```

2. **Check metrics:**
   - Iteration counts identical
   - Time step sequence identical
   - Convergence rates identical
   - Final state identical (ψ, θ fields)

3. **Mass balance:**
   ```
   Total inflow  = [value]
   Total outflow = [value]
   Storage change = [value]
   Balance error = [value] < 1e-10 ✓
   ```

### Level 3: Physical Realism

**Test against known behavior:**

1. **Infiltration into dry soil:**
   - Sharp wetting front?
   - Correct infiltration rate?
   - Green-Ampt approximation reasonable?

2. **Drainage:**
   - Exponential decay of moisture?
   - Physically reasonable time scale?
   - No negative pressures in saturated zone?

3. **Rainfall-runoff:**
   - Runoff starts when infiltration capacity exceeded?
   - Hydrograph shape reasonable?
   - Peak timing correct?

---

## TESTING REQUIREMENTS

### Required Test Cases

**MUST pass before considering complete:**

1. **test_infiltration_simple.inp**
   - Homogeneous soil
   - Constant surface flux
   - 1D vertical
   - Duration: 24 hours
   - **PASS CRITERION**: ψ(z,t) identical to original

2. **test_drainage.inp**
   - Initially saturated
   - Free drainage bottom BC
   - No top flux
   - Duration: 7 days
   - **PASS CRITERION**: θ(z,t) identical to original

3. **test_rainfall_runoff.inp**
   - Rainfall event (50 mm/day for 6 hours)
   - Sloping domain
   - Surface routing active
   - **PASS CRITERION**: Runoff hydrograph identical

4. **test_et_cycle.inp**
   - Diurnal ET cycle
   - Root water uptake
   - 7-day simulation
   - **PASS CRITERION**: Water balance closes, ET matches

5. **test_heterogeneous.inp**
   - Layered soil
   - Multiple soil types
   - Test averaging methods
   - **PASS CRITERION**: Interface behavior correct

---

## COMMON PITFALLS - AVOID THESE

### ❌ DO NOT:

1. **Change array dimensions without checking:**
   ```fortran
   ! WRONG: Assuming dimensions
   real(8) :: array(100, 100)

   ! RIGHT: Use actual dimensions from modules
   use mesh_geometry_module, only: iacnv, iacnl
   real(8) :: array(iacnv(ih), iacnl(ih))
   ```

2. **Simplify "for clarity":**
   ```fortran
   ! WRONG: Simplifying physics
   k_avg = (k1 + k2) / 2  ! "Simpler"

   ! RIGHT: Preserve exact method
   k_avg = 2.0d0 * sqrt(k1 * k2) / dx  ! Original formula
   ```

3. **Ignore edge cases:**
   ```fortran
   ! WRONG: Assuming normal conditions
   flux = k * gradient

   ! RIGHT: Handle saturation/dryness
   if (theta < theta_r) then
       flux = 0.0d0
   else if (theta >= theta_s) then
       flux = k_sat * gradient
   else
       flux = k_unsat(theta) * gradient
   end if
   ```

4. **Skip validation:**
   ```fortran
   ! WRONG: "Looks good to me"
   ! RIGHT: Run bit-for-bit comparison
   ```

---

## FILE-BY-FILE CHECKLIST

**For each converted file, verify:**

- [ ] Compiles without warnings (`make`)
- [ ] All includes replaced with module imports
- [ ] All variables declared with explicit types
- [ ] `implicit none` at top of every subroutine
- [ ] Intent specified for all arguments
- [ ] Original algorithm preserved line-by-line
- [ ] Critical equations documented
- [ ] Edge cases handled identically
- [ ] Unit test created and passing
- [ ] Integrated into build system (Makefile)
- [ ] Memory properly managed (allocate/deallocate)
- [ ] No memory leaks (`valgrind` if possible)
- [ ] Physics validated against original
- [ ] Committed with clear description

---

## CURRENT DIRECTORY STRUCTURE

```
model_streamlined/
├── modules/                    ✅ COMPLETE
│   ├── constants_module.f90
│   ├── state_data_module.f90
│   ├── mesh_geometry_module.f90
│   ├── soil_hydraulics_module.f90
│   ├── boundary_conditions_module.f90
│   └── time_module.f90
│
├── physics/                    ⏳ 1 of 37 files
│   ├── koeff.f90               ✅ DONE (template!)
│   ├── steps.f90               ← START HERE
│   ├── hg.f90                  ← NEXT
│   ├── kinnen.f90              ← THEN
│   ├── koeffrb.f90             ← THEN
│   └── [33 more files...]
│
├── tests/                      ⏳ TO CREATE
│   ├── test_infiltration_simple.inp
│   ├── test_drainage.inp
│   ├── test_rainfall_runoff.inp
│   ├── test_et_cycle.inp
│   └── test_heterogeneous.inp
│
├── Makefile                    ✅ WORKING
├── catflow_main.f90            ← TO CREATE
│
├── ROADMAP_TO_100_PERCENT.md   ✅ COMPLETE
├── PHASE_2_COMPLETE.md         ✅ COMPLETE
└── CONTINUATION_PROMPT.md      ✅ (this file)
```

---

## QUALITY CHECKLIST - FINAL

**Before declaring "Phase 4 Complete":**

### Code Quality
- [ ] All 37 files converted to modules
- [ ] Zero compiler warnings
- [ ] All functions documented
- [ ] Build system fully automated
- [ ] Memory leaks checked

### Scientific Correctness
- [ ] All physics preserved exactly
- [ ] All equations match original
- [ ] Edge cases handled identically
- [ ] Numerical precision maintained

### Validation
- [ ] All 5 test cases pass
- [ ] Bit-identical results for simple cases
- [ ] Mass balance error < 1e-10
- [ ] Performance within 20% of original

### Completeness
- [ ] All original features working
- [ ] All BC types functional
- [ ] All solver options available
- [ ] All input formats supported
- [ ] All output formats working

---

## SUCCESS CRITERIA

### Minimal Success (Phase 4a)
```bash
$ ./catflow_streamlined test_infiltration_simple.inp

CATFLOW Streamlined v2.0
Initializing modules... OK
Reading input... OK
Allocating arrays... OK (0.5 MB vs 50 MB original)

Time stepping...
Step   1: dt=3600s, iter=5, converged ✓
Step   2: dt=3600s, iter=4, converged ✓
...
Step  24: dt=3600s, iter=4, converged ✓

Mass balance:
  Inflow:        240.000 mm
  Outflow:       238.523 mm
  Storage:         1.477 mm
  Balance error:   0.000 mm ✓

Simulation complete: 24 steps, 100% convergence
Results written to: test_infiltration_simple.out

VALIDATION: Comparing with original...
  ψ field: IDENTICAL (max diff = 1.2e-15)
  θ field: IDENTICAL (max diff = 3.4e-16)
  ✓ SUCCESS: Model validated!
```

### Full Success (Phase 4c)
- All test cases passing
- Performance benchmarked
- Documentation complete
- Ready for production use

---

## NEXT STEPS - IMMEDIATE ACTIONS

1. **Start with STEPS.f:**
   ```bash
   cd /Users/cojack/Documents/TUBAF/models/catflow/catflow_313
   cd model/src
   # Read STEPS.f carefully
   # Understand time stepping logic
   # Convert to steps.f90 following koeff.f90 pattern
   ```

2. **Follow this sequence:**
   - STEPS.f → steps.f90 (time stepping)
   - HG.f → hg.f90 (solver)
   - KINNEN.f → kinnen.f90 (fluxes)
   - KOEFFRB.f → koeffrb.f90 (BC)
   - CATFLOW.f → catflow_main.f90 (integration)

3. **Test after each file:**
   - Compile: `make`
   - Create unit test
   - Verify physics
   - Document any issues

4. **Milestone goal:**
   - First working simulation in 3-4 weeks
   - Validate against original
   - Celebrate! 🎉

---

## FINAL REMINDERS

### Scientific Integrity
**This is a 40-year-old, peer-reviewed, scientifically validated model.**
- Treat it with respect
- Preserve every detail
- When in doubt, ask - don't guess
- Validate, validate, validate

### The Goal
**Create a modern, maintainable version that:**
- ✅ Runs faster (less memory, better cache)
- ✅ Compiles faster (modular)
- ✅ Is easier to understand (explicit dependencies)
- ✅ Produces IDENTICAL results (physics preserved)

### You Are NOT:
- ❌ Improving the physics
- ❌ Fixing "problems" in algorithms
- ❌ Modernizing numerical methods
- ❌ Optimizing for speed first

### You ARE:
- ✅ Modernizing the software structure
- ✅ Preserving the proven science
- ✅ Making the code more maintainable
- ✅ Reducing memory overhead

---

## CONTACT / RESOURCES

**Reference Files:**
- Original code: `/model/src/*.f`
- Modules: `/model_streamlined/modules/*.f90`
- Template: `/model_streamlined/physics/koeff.f90` ← **STUDY THIS!**
- Roadmap: `ROADMAP_TO_100_PERCENT.md`
- Progress: `PHASE_2_COMPLETE.md`

**When Stuck:**
1. Read koeff.f90 - it shows the pattern
2. Check ROADMAP - it has file priorities
3. Review original .f file - preserve its logic
4. Test early and often
5. Document any uncertainties

---

## BEGIN HERE

**Your first task:**
```
Convert STEPS.f to steps.f90 following the koeff.f90 pattern.

Key physics to preserve:
- All solver options (irsol=1,2,3,4,5)
- Picard iteration
- Time step adaptation
- Convergence criteria

Validate by:
- Comparing iteration counts
- Checking convergence behavior
- Verifying time step sequence

Expected time: 2-3 days
```

**Good luck! The hard work is done - now execute the plan.** 🎯

---

**CATFLOW Streamlined Project**
*Modernizing 40 years of proven hydrology science*
*Where scientific rigor meets software engineering*
