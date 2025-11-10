!===============================================================================
! MODULE: steps_module
!
! PURPOSE:
!   Time stepping solvers for Richards equation in CATFLOW
!   Modernized version of STEPS.f using Fortran 90 modules
!
! DESCRIPTION:
!   Contains 6 solver subroutines for the nonlinear Richards equation:
!
!   1. expstp  - Explicit time stepping
!      - Simplest method, conditionally stable
!      - Uses forward Euler discretization
!      - Requires small time steps (dt < dt_exp)
!      - Best for: rapid transients, initial testing
!
!   2. bcgstp  - Biconjugate gradient solver (implicit)
!      - Iterative linear solver for implicit discretization
!      - Preconditioned for faster convergence
!      - Handles stiff problems better than explicit
!      - Best for: general purpose, moderate nonlinearity
!
!   3. adistp  - ADI (Alternating Direction Implicit)
!      - Splits 2D problem into 1D sweeps
!      - Implicit in each direction alternately
!      - Unconditionally stable
!      - Best for: strongly anisotropic problems
!
!   4. apkstp  - ADI with predictor-corrector
!      - Enhanced ADI with corrector steps
!      - Updates hydraulic properties mid-step
!      - Better handles strong nonlinearity
!      - Best for: highly nonlinear problems (infiltration fronts)
!
!   5. piccg   - Picard iteration with conjugate gradient
!      - Outer Picard loop for nonlinearity
!      - Inner CG solver for linear system
!      - Iterates until convergence (rsq < piceps)
!      - Best for: general unsaturated flow problems
!
!   6. picadi  - Picard iteration with ADI
!      - Outer Picard loop for nonlinearity
!      - Inner ADI solver for linear system
!      - Alternative to piccg for anisotropic problems
!      - Best for: layered soils, anisotropic conductivity
!
! CONVERGENCE CRITERIA:
!   - Picard iterations: |Δφ|_∞ < piceps (typically 1e-2 m)
!   - Conjugate gradient: residual < cgeps (typically 1e-6)
!   - Maximum iterations: it_max (typically 20)
!
! TIME STEP ADAPTATION:
!   All solvers monitor boundary condition (BC) changes via chko_rb:
!   - If BC changes during solve: repeat with updated BC
!   - If BC changes twice (n_chg >= 2): abort, reduce time step
!   - Ensures consistency between BC and solution state
!
! BOUNDARY CONDITION SWITCHING:
!   Critical feature for unsaturated flow:
!   - Surface nodes switch between flux and head BC
!   - Switching detected by chko_rb (rbchg flag)
!   - Time step repeats with new BC type
!   - Prevents oscillations at surface
!
! ITERATION CONTROL:
!   - it_max: Maximum Picard iterations (from constants_module)
!   - piceps: Picard convergence tolerance [m] (from constants_module)
!   - cgeps:  CG convergence tolerance (from constants_module)
!   - abbruch: Abort flag (returned to caller for time step reduction)
!
! EXTERNAL FUNCTION CALLS:
!   Coefficient calculation:
!   - koeff:   Calculate finite difference coefficients
!   - kc_phi:  Update K(θ) and C(θ) from φ
!
!   Explicit solver:
!   - expcal:  Explicit calculation (forward Euler)
!
!   ADI solvers:
!   - ex_ie:   Explicit xsi, implicit eta half-step
!   - ee_ix:   Explicit eta, implicit xsi half-step
!
!   Picard iteration:
!   - pic_it:  Set up Picard linearization (RS = f(φ_old))
!
!   Linear solvers:
!   - cg_solv: Conjugate gradient solver
!
!   Boundary conditions:
!   - rand_fl: Apply boundary fluxes
!   - chko_rb: Check for BC type changes
!
!   Array operations:
!   - hgcopy:  Copy 2D arrays
!   - hgnull:  Zero out 2D arrays
!   - hgadd:   Add 2D arrays
!
! PHYSICS PRESERVATION:
!   ALL numerical algorithms preserved EXACTLY from original:
!   - Picard linearization structure
!   - ADI splitting scheme
!   - CG preconditioning approach
!   - Time step retry logic
!   - Convergence checking
!   - BC switching detection
!
! VALIDATION REQUIREMENTS:
!   1. Mass balance: Check bilanz ≈ 0 after each step
!   2. Convergence: Monitor n_it, rsq for each case
!   3. BC consistency: Verify rbchg handling
!   4. Time step stability: Confirm dt adaptation works
!   5. Compare with original: Identical results for test cases
!
! ORIGINAL: STEPS.f (Fortran 77 with includes)
! AUTHOR: CATFLOW Streamlined
! DATE: 2025-11-07
!===============================================================================
module steps_module
    use constants_module, only: maxnv, maxnl
    use bodtab_module, only: kc_phi
    use hg_opera_module, only: hgcopy, hgnull, hgadd
    use dcg_module, only: cg_solv
    use addsteps_module, only: chko_rb, rand_fl, ex_ie, ee_ix, pic_it, expcal
    use koeffrb_module, only: koeffrb
    implicit none
    private

    ! Make all 6 solver subroutines public
    public :: expstp
    public :: bcgstp
    public :: adistp
    public :: apkstp
    public :: piccg
    public :: picadi

contains

    !===========================================================================
    ! SUBROUTINE: expstp
    !
    ! PURPOSE: Explicit time stepping (forward Euler)
    !
    ! DESCRIPTION:
    !   Simplest solver: φ^(n+1) = φ^n + dt * F(φ^n)
    !   Conditionally stable: requires dt < dt_exp
    !
    !   Algorithm:
    !   1. Calculate coefficients at current state
    !   2. Perform explicit calculation
    !   3. Apply boundary fluxes
    !   4. Check for BC changes
    !   5. If BC changed: repeat (max 2 times)
    !
    !   Boundary condition adaptation:
    !   - n_chg counts BC changes in this step
    !   - If n_chg >= 2: return with abbruch=.true.
    !   - Caller must reduce time step and retry
    !
    ! ARGUMENTS:
    !   ih       - Hillslope index
    !   dt       - Time step [s]
    !   abbruch  - Abort flag (output)
    !
    ! EXTERNAL CALLS:
    !   koeff   - Calculate FD coefficients
    !   expcal  - Explicit calculation step
    !   rand_fl - Apply boundary fluxes
    !   chko_rb - Check BC changes
    !===========================================================================
    subroutine expstp(ih, dt, abbruch)
        use constants_module, only: io, io_log
        use mesh_geometry_module, only: iacnh
        implicit none

        integer(4), intent(in)  :: ih
        real(8),    intent(in)  :: dt
        logical,    intent(out) :: abbruch

        integer(4) :: n_chg
        logical :: rbchg
        character(80) :: rblog

        n_chg = 0
        rbchg = .false.
        abbruch = .false.

 1000   continue
            call koeffrb(ih, dt)
            call expcal(ih)

            call rand_fl(ih)
            call chko_rb(ih, rbchg, rblog)

            if (rbchg) then
                n_chg = n_chg + 1
!               write(io(1),*) 'RB-Wechsel: ', n_chg, dt
                if (io_log(1) .gt. 0) then
                    if (iacnh .gt. 1) write(io(1),'(a)') rblog
                endif
                if (n_chg .ge. 2) then
!                   abbruch = .true.
                    goto 999
                endif
                goto 1000
            endif

  999   continue
        return
    end subroutine expstp

    !===========================================================================
    ! SUBROUTINE: bcgstp
    !
    ! PURPOSE: Biconjugate gradient solver step
    !
    ! DESCRIPTION:
    !   Implicit solver using preconditioned biconjugate gradient method.
    !
    !   Algorithm:
    !   1. Calculate coefficients for implicit discretization
    !   2. Set up RHS: RS = RS - φ_old (for implicit formulation)
    !   3. Solve linear system: A·Δφ = RS using CG
    !   4. Update: φ_new = φ_old + Δφ
    !   5. Apply boundary fluxes
    !   6. Check BC changes, retry if needed
    !
    !   The CG solver uses:
    !   - Tolerance: cgeps/100 (tighter than Picard)
    !   - Preconditioning: diagonal or incomplete factorization
    !   - Convergence metric: L2 norm of residual
    !
    !   BC switching:
    !   - If BC changes: reset φ = φ_old and retry
    !   - If changes twice: abort with abbruch=.true.
    !
    ! ARGUMENTS:
    !   ih       - Hillslope index
    !   dt       - Time step [s]
    !   n_cg     - Number of CG iterations (output)
    !   abbruch  - Abort flag (output)
    !
    ! EXTERNAL CALLS:
    !   koeff   - Calculate FD coefficients
    !   cg_solv - Conjugate gradient solver
    !   hgcopy  - Copy arrays
    !   hgnull  - Zero array
    !   kc_phi  - Update K and C from φ
    !   rand_fl - Apply boundary fluxes
    !   chko_rb - Check BC changes
    !===========================================================================
    subroutine bcgstp(ih, dt, n_cg, abbruch)
        use constants_module, only: io, io_log, cgeps
        use state_data_module, only: RS, phineu, phialt
        use mesh_geometry_module, only: iacnv, iacnl, iacnh
        implicit none

        integer(4), intent(in)  :: ih
        real(8),    intent(in)  :: dt
        integer(4), intent(out) :: n_cg
        logical,    intent(out) :: abbruch

        integer(4) :: il, iv
        integer(4) :: n_chg
        real(8) :: rsq
        real(8) :: Phi(maxnv, maxnl)
        logical :: rbchg
        character(80) :: rblog

        n_chg = 0
        rbchg = .false.
        abbruch = .false.

 1000   continue
            call koeffrb(ih, dt)

            ! Adjust RHS for implicit scheme
            do iv = 1, iacnv(ih)
                do il = 1, iacnl(ih)
                    RS(iv,il) = RS(iv,il) - phialt(iv,il,ih)
                end do
            end do

            ! Solve for correction: A·Δφ = RS
            call hgcopy(phineu, Phi, ih)
            call hgnull(phineu, ih)
            call cg_solv(ih, Phi, rsq, n_cg, cgeps/100.0d0)
            call hgcopy(Phi, phineu, ih)

            call rand_fl(ih)
            call chko_rb(ih, rbchg, rblog)

            if (rbchg) then
                n_chg = n_chg + 1
!               write(io(1),*) 'RB-Wechsel: ', n_cg, n_chg, dt
                if (io_log(1) .gt. 0) then
                    if (iacnh .gt. 1) write(io(1),'(a)') rblog
                endif
                if (n_chg .ge. 2) then
                    abbruch = .true.
                    goto 999
                endif
                call kc_phi(phialt(1,1,ih), ih)
                call hgcopy(phialt(1,1,ih), phineu, ih)
                goto 1000
            endif

  999   continue
        return
    end subroutine bcgstp

    !===========================================================================
    ! SUBROUTINE: adistp
    !
    ! PURPOSE: ADI (Alternating Direction Implicit) time step
    !
    ! DESCRIPTION:
    !   Splits 2D problem into two 1D implicit solves:
    !   - First half-step: implicit in eta, explicit in xsi
    !   - Second half-step: implicit in xsi, explicit in eta
    !
    !   Algorithm:
    !   1. First half-step (dt/2):
    !      - Calculate coefficients
    !      - Solve implicit in eta direction (ex_ie)
    !      - Update K and C from new φ
    !   2. Second half-step (dt/2):
    !      - Calculate coefficients again
    !      - Solve implicit in xsi direction (ee_ix)
    !   3. Apply boundary fluxes
    !   4. Check BC changes
    !
    !   Relaxation parameters:
    !   - expant=1.0: Full implicit (Crank-Nicolson)
    !   - ome=0.0:    No over-relaxation in eta
    !   - omx=0.0:    No over-relaxation in xsi
    !
    !   Advantages:
    !   - Unconditionally stable
    !   - Efficient for anisotropic problems
    !   - Tridiagonal systems (fast to solve)
    !
    ! ARGUMENTS:
    !   ih       - Hillslope index
    !   dt       - Time step [s]
    !   abbruch  - Abort flag (output)
    !
    ! EXTERNAL CALLS:
    !   koeff   - Calculate FD coefficients
    !   ex_ie   - Explicit xsi, implicit eta step
    !   ee_ix   - Explicit eta, implicit xsi step
    !   kc_phi  - Update K and C from φ
    !   hgcopy  - Copy arrays
    !   rand_fl - Apply boundary fluxes
    !   chko_rb - Check BC changes
    !===========================================================================
    subroutine adistp(ih, dt, abbruch)
        use constants_module, only: io, io_log
        use state_data_module, only: phineu, phialt
        use mesh_geometry_module, only: iacnh
        implicit none

        integer(4), intent(in)  :: ih
        real(8),    intent(in)  :: dt
        logical,    intent(out) :: abbruch

        integer(4) :: n_chg
        real(8) :: expant, ome, omx
        logical :: rbchg
        character(80) :: rblog

        expant = 1.0d0
        ome = 0.0d0
        omx = 0.0d0

        n_chg = 0
        rbchg = .false.
        abbruch = .false.

 1000   continue
            ! First half-step: implicit in eta
            call koeffrb(ih, dt/2.0d0)
            call ex_ie(phineu, ih, expant, ome)

            ! Update K and C at mid-step
            call kc_phi(phineu, ih)

            ! Second half-step: implicit in xsi
            call koeffrb(ih, dt/2.0d0)
            call ee_ix(phineu, ih, expant, omx)

            call rand_fl(ih)
            call chko_rb(ih, rbchg, rblog)

            if (rbchg) then
                n_chg = n_chg + 1
!               write(io(1),*) 'RB-Wechsel: ', n_chg, dt
                if (io_log(1) .gt. 0) then
                    if (iacnh .gt. 1) write(io(1),'(a)') rblog
                endif
                if (n_chg .ge. 2) then
                    abbruch = .true.
                    goto 999
                endif
                call kc_phi(phialt(1,1,ih), ih)
                call hgcopy(phialt(1,1,ih), phineu, ih)
                goto 1000
            endif

  999   continue
        return
    end subroutine adistp

    !===========================================================================
    ! SUBROUTINE: apkstp
    !
    ! PURPOSE: ADI with predictor-corrector scheme
    !
    ! DESCRIPTION:
    !   Enhanced ADI that updates hydraulic properties mid-step for better
    !   handling of strong nonlinearity (e.g., infiltration fronts).
    !
    !   Algorithm:
    !   ETA DIRECTION:
    !   1. Predictor (dt/4): implicit eta step with old K,C
    !   2. Corrector: update K,C from predictor
    !   3. Full step (dt/2): implicit eta with corrected K,C
    !   4. Update K,C again
    !
    !   XSI DIRECTION:
    !   5. Predictor (dt/4): implicit xsi step
    !   6. Corrector: update K,C
    !   7. Full step (dt/2): implicit xsi with corrected K,C
    !
    !   This approach:
    !   - Better captures moving fronts
    !   - More expensive (4 solves instead of 2)
    !   - Recommended for infiltration events
    !
    ! ARGUMENTS:
    !   ih       - Hillslope index
    !   dt       - Time step [s]
    !   abbruch  - Abort flag (output)
    !
    ! EXTERNAL CALLS:
    !   koeff   - Calculate FD coefficients
    !   ex_ie   - Implicit eta step
    !   ee_ix   - Implicit xsi step
    !   kc_phi  - Update K and C
    !   hgcopy  - Copy arrays
    !   rand_fl - Apply boundary fluxes
    !   chko_rb - Check BC changes
    !===========================================================================
    subroutine apkstp(ih, dt, abbruch)
        use constants_module, only: io, io_log
        use state_data_module, only: phineu, phialt
        use mesh_geometry_module, only: iacnh
        implicit none

        integer(4), intent(in)  :: ih
        real(8),    intent(in)  :: dt
        logical,    intent(out) :: abbruch

        integer(4) :: n_chg
        real(8) :: philoc(maxnv, maxnl)
        real(8) :: expant, ome, omx
        logical :: rbchg
        character(80) :: rblog

        expant = 1.0d0
        ome = 0.0d0
        omx = 0.0d0

        n_chg = 0
        rbchg = .false.
        abbruch = .false.

 1000   continue
            ! Predictor step (eta direction, dt/4)
            call hgcopy(phineu, philoc, ih)
            call koeffrb(ih, dt/4.0d0)
            call ex_ie(phineu, ih, expant, ome)

            ! Corrector: update K and C
            call kc_phi(phineu, ih)

            ! Full first half-step (eta, dt/2 with corrected K,C)
            call hgcopy(philoc, phineu, ih)
            call koeffrb(ih, dt/2.0d0)
            call ex_ie(phineu, ih, expant, ome)

            ! Update K and C after first half-step
            call kc_phi(phineu, ih)

            ! Predictor step (xsi direction, dt/4)
            call hgcopy(phineu, philoc, ih)
            call koeffrb(ih, dt/4.0d0)
            call ee_ix(phineu, ih, expant, omx)

            ! Corrector: update K and C
            call kc_phi(phineu, ih)

            ! Full second half-step (xsi, dt/2 with corrected K,C)
            call hgcopy(philoc, phineu, ih)
            call koeffrb(ih, dt/2.0d0)
            call ee_ix(phineu, ih, expant, omx)

            call rand_fl(ih)
            call chko_rb(ih, rbchg, rblog)

            if (rbchg) then
                n_chg = n_chg + 1
!               write(io(1),*) 'RB-Wechsel: ', n_chg, dt
                if (io_log(1) .gt. 0) then
                    if (iacnh .gt. 1) write(io(1),'(a)') rblog
                endif
                if (n_chg .ge. 2) then
                    abbruch = .true.
                    goto 999
                endif
                call kc_phi(phialt(1,1,ih), ih)
                call hgcopy(phialt(1,1,ih), phineu, ih)
                goto 1000
            endif

  999   continue
        return
    end subroutine apkstp

    !===========================================================================
    ! SUBROUTINE: piccg
    !
    ! PURPOSE: Picard iteration with conjugate gradient linear solver
    !
    ! DESCRIPTION:
    !   Most robust solver for general unsaturated flow problems.
    !   Uses outer Picard iteration to handle nonlinearity.
    !
    !   Picard linearization:
    !   C(φ_old)·∂φ/∂t = ∇·[K(φ_old)·∇φ] + sources
    !
    !   Algorithm:
    !   Loop until convergence or max iterations:
    !   1. Calculate K(φ_n) and C(φ_n)
    !   2. Calculate FD coefficients
    !   3. Set up linearized system (pic_it)
    !   4. Solve A·Δφ = RS using CG
    !   5. Update: φ_(n+1) = φ_n + Δφ
    !   6. Apply boundary fluxes
    !   7. Check BC changes
    !   8. Check convergence: |Δφ|_∞ < piceps
    !   9. If not converged and n_it < it_max: iterate
    !
    !   Convergence criteria:
    !   - rsq < piceps: converged successfully
    !   - n_it >= it_max: abort, reduce time step
    !   - BC changes twice: abort, reduce time step
    !
    !   Time step adaptation:
    !   - If dt > dt_min and BC changes: allow retry
    !   - Otherwise: caller must reduce time step
    !
    ! ARGUMENTS:
    !   ih       - Hillslope index
    !   dt       - Time step [s]
    !   dt_min   - Minimum allowable time step [s]
    !   abbruch  - Abort flag (output)
    !   n_it     - Number of Picard iterations (output)
    !   n_cg     - Total CG iterations (output)
    !   rsq      - Final convergence metric (output)
    !
    ! EXTERNAL CALLS:
    !   koeff   - Calculate FD coefficients
    !   pic_it  - Set up Picard linearization
    !   cg_solv - CG linear solver
    !   hgnull  - Zero array
    !   hgadd   - Add arrays
    !   hgcopy  - Copy arrays
    !   kc_phi  - Update K and C
    !   rand_fl - Apply boundary fluxes
    !   chko_rb - Check BC changes
    !===========================================================================
    subroutine piccg(ih, dt, dt_min, abbruch, n_it, n_cg, rsq)
        use constants_module, only: io, io_log, it_max, piceps, cgeps
        use state_data_module, only: phineu, phialt
        use mesh_geometry_module, only: iacnh
        implicit none

        integer(4), intent(in)  :: ih
        real(8),    intent(in)  :: dt, dt_min
        logical,    intent(out) :: abbruch
        integer(4), intent(out) :: n_it, n_cg
        real(8),    intent(out) :: rsq

        integer(4) :: it_act, n_chg
        real(8) :: dPhi(maxnv, maxnl)
        logical :: rbchg
        character(80) :: rblog

        n_it = 0
        abbruch = .false.
        n_cg = 0
        n_chg = 0
        rbchg = .false.

 1000   continue
            ! Picard iteration
            call hgnull(dPhi, ih)
            call koeffrb(ih, dt)
            call pic_it(ih)
            call cg_solv(ih, dPhi, rsq, it_act, cgeps)
            call hgadd(phineu, dPhi, ih)
            call rand_fl(ih)
            call chko_rb(ih, rbchg, rblog)

            n_it = n_it + 1
            n_cg = n_cg + it_act

            ! Check for BC changes (only retry if dt > dt_min)
            if (rbchg .and. (dt .gt. dt_min)) then
                n_chg = n_chg + 1
!               write(io(1),*) 'RB-Wechsel: ',n_it, n_cg, n_chg, dt
                if (io_log(1) .gt. 0) then
                    if (iacnh .gt. 1) write(io(1),'(a)') rblog
                endif
                if (n_chg .ge. 2) then
                    abbruch = .true.
                    goto 999
                endif
                call kc_phi(phialt(1,1,ih), ih)
                call hgcopy(phialt(1,1,ih), phineu, ih)
                n_it = 0
                goto 1000
            endif

            ! Check convergence
            if (rsq .lt. piceps) goto 999

            ! Check iteration limit
            if (n_it .ge. it_max) then
                abbruch = .true.
                if (io_log(1) .gt. 0) then
                    write(io(1),2000) n_it, it_max, rsq
                endif
                write(*,2000) n_it, it_max, rsq
                goto 999
            endif

            ! Update K and C for next iteration
            call kc_phi(phineu, ih)
        goto 1000

  999   continue
        return

 2000   format('PICCG: Iterationsanzahl: ',i2,' (',i2,')  RSQ: ',e9.3, &
                ' -> starke Zeitschrittreduktion')
    end subroutine piccg

    !===========================================================================
    ! SUBROUTINE: picadi
    !
    ! PURPOSE: Picard iteration with ADI linear solver
    !
    ! DESCRIPTION:
    !   Alternative to piccg using ADI instead of CG for linear solves.
    !   Better for strongly anisotropic problems or layered soils.
    !
    !   Algorithm:
    !   Loop until convergence:
    !   1. Calculate K(φ_n) and C(φ_n)
    !   2. Calculate FD coefficients (full dt)
    !   3. Set up Picard linearization (pic_it)
    !   4. Split ADI solve:
    !      a) Implicit eta, explicit xsi (ex_ie)
    !      b) Update K,C at midpoint
    !      c) Implicit xsi, explicit eta (ee_ix)
    !   5. Update: φ_(n+1) = φ_n + Δφ
    !   6. Calculate convergence: rsq = max|Δφ|
    !   7. Apply boundary fluxes
    !   8. Check BC changes
    !   9. Check convergence and iterate
    !
    !   Two implementation variants (see commented code):
    !   - Variant 1: No K,C update after first half-step (faster)
    !   - Variant 2: Update K,C mid-ADI (more accurate) - ACTIVE
    !
    !   Convergence:
    !   - Uses L∞ norm: rsq = max|Δφ|
    !   - Threshold: piceps (typically 1e-2 m)
    !
    ! ARGUMENTS:
    !   ih       - Hillslope index
    !   dt       - Time step [s]
    !   abbruch  - Abort flag (output)
    !   n_it     - Number of iterations (output)
    !   rsq      - Final convergence metric (output)
    !
    ! EXTERNAL CALLS:
    !   koeff   - Calculate FD coefficients
    !   pic_it  - Set up Picard linearization
    !   ex_ie   - Implicit eta step
    !   ee_ix   - Implicit xsi step
    !   hgnull  - Zero array
    !   hgadd   - Add arrays
    !   hgcopy  - Copy arrays
    !   kc_phi  - Update K and C
    !   rand_fl - Apply boundary fluxes
    !   chko_rb - Check BC changes
    !===========================================================================
    subroutine picadi(ih, dt, abbruch, n_it, rsq)
        use constants_module, only: io, io_log, it_max, piceps
        use state_data_module, only: phineu, phialt
        use mesh_geometry_module, only: iacnv, iacnl
        implicit none

        integer(4), intent(in)  :: ih
        real(8),    intent(in)  :: dt
        logical,    intent(out) :: abbruch
        integer(4), intent(out) :: n_it
        real(8),    intent(out) :: rsq

        integer(4) :: il, iv, n_chg
        real(8) :: dPhi(maxnv, maxnl)
        real(8) :: philoc(maxnv, maxnl)
        real(8) :: omx, ome, expant
        logical :: rbchg
        character(80) :: rblog

        intrinsic :: abs

        n_it = 0
        abbruch = .false.

        ! Relaxation parameters
        omx = 0.0d0
        ome = 0.0d0
        expant = 0.0d0
        n_chg = 0

 1000   continue
            call hgnull(dPhi, ih)

!-----------------------------------------------------------
! Case 1: Without update of coefficients after first half-step
!         (converges slower, but computes slightly faster)
!
!           call koeff(ih, dt)
!           call pic_it(ih)
!           call hgcopy(RS, philoc, ih)
!           call ex_ie(dPhi, ih, expant, ome)
!           call hgcopy(philoc, RS, ih)
!           call ee_ix(dPhi, ih, expant, omx)
!
!
!
!
!
!
!
!-----------------------------------------------------------
! Case 2: With update of coefficients after first half-step
!         (converges faster, but computes slower)

            call hgcopy(phineu, philoc, ih)

            ! First half-step: implicit eta
            call koeffrb(ih, dt)
            call pic_it(ih)
            call ex_ie(dPhi, ih, expant, ome)
            call hgadd(phineu, dPhi, ih)

            ! Update K and C at midpoint
            call kc_phi(phineu, ih)
            call koeffrb(ih, dt)
            call pic_it(ih)

            ! Second half-step: implicit xsi
            call ee_ix(dPhi, ih, expant, omx)

            call hgcopy(philoc, phineu, ih)
!-----------------------------------------------------------

            call hgadd(phineu, dPhi, ih)

            ! Calculate L∞ convergence metric
            rsq = 0.0d0
            do iv = 1, iacnv(ih)
                do il = 1, iacnl(ih)
                    if (abs(dPhi(iv,il)) .gt. rsq) rsq = abs(dPhi(iv,il))
                end do
            end do

            call rand_fl(ih)
            call chko_rb(ih, rbchg, rblog)

            n_it = n_it + 1

            ! Check for BC changes
            if (rbchg) then
                n_chg = n_chg + 1
                write(io(3),*) 'RB-Wechsel: ', n_it, n_chg, dt
                if (n_chg .ge. 2) then
                    abbruch = .true.
                    goto 999
                endif
                call kc_phi(phialt(1,1,ih), ih)
                call hgcopy(phialt(1,1,ih), phineu, ih)
                n_it = 0
                goto 1000
            endif

            ! Check convergence
            if (rsq .lt. piceps) goto 999

            ! Check iteration limit
            if (n_it .ge. it_max) then
                abbruch = .true.
                if (io_log(1) .gt. 0) then
                    write(io(1),2000) n_it, it_max, rsq
                endif
                goto 999
            endif

            ! Update K and C for next iteration
            call kc_phi(phineu, ih)
        goto 1000

  999   continue
        return

 2000   format('PICADI: Iterationsanzahl: ',i2,' (',i2,')  RSQ:',e10.4)
    end subroutine picadi

end module steps_module
