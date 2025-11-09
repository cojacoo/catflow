!===============================================================================
! MODULE: addsteps_module
!
! PURPOSE:
!   Support subroutines for Richards equation solver in CATFLOW
!   Modernized version of ADDSTEPS.f using Fortran 90 modules
!
! DESCRIPTION:
!   Contains 9 critical support subroutines called by solver methods
!   in steps_module and other physics modules:
!
!   1. expcal    - Explicit calculation for explicit time stepping
!   2. ee_ix     - ADI half-step (explicit eta direction, implicit xsi direction)
!   3. ex_ie     - ADI half-step (explicit xsi direction, implicit eta direction)
!   4. tridig    - Tridiagonal matrix solver (Thomas algorithm)
!   5. pic_it    - Picard iteration setup (calculates residual)
!   6. rand_fl   - Boundary flux calculation and accumulation
!   7. chko_rb   - Check and switch boundary conditions (inequality BC logic)
!   8. savevz    - Save state variables for potential rollback
!   9. loadvz    - Load saved state variables (rollback on convergence failure)
!
! PHYSICS ALGORITHMS:
!
!   EXPLICIT CALCULATION (expcal):
!   - Implements forward Euler step: φ^(n+1) = φ^n + dt*F(φ^n)
!   - Assembles solution from coefficient matrix and old state
!   - Used by explicit time stepping solver (expstp)
!
!   ADI HALF-STEPS (ee_ix, ex_ie):
!   - Implement Alternating Direction Implicit method
!   - ee_ix: Explicit in eta (vertical), implicit in xsi (horizontal)
!   - ex_ie: Explicit in xsi (horizontal), implicit in eta (vertical)
!   - Each solves tridiagonal systems via tridig
!   - Relaxation parameters: expant (implicit weight), ome/omx (over-relaxation)
!   - Critical for unconditionally stable time stepping
!
!   THOMAS ALGORITHM (tridig):
!   - Solves tridiagonal linear system: A·u = r
!   - Matrix structure: | b  c  -  -  - |   |u|   |r|
!   -                   | a  b  c  -  - | × |u| = |r|
!   -                   | -  a  b  c  - |   |u|   |r|
!   - Forward elimination then back substitution
!   - O(n) complexity, numerically stable for diagonally dominant matrices
!   - CRITICAL: Must preserve exact implementation for numerical stability
!
!   PICARD ITERATION SETUP (pic_it):
!   - Transforms system into iterative form for Picard linearization
!   - Linearizes Richards equation: C(φ_old)·∂φ/∂t = ∇·[K(φ_old)·∇φ]
!   - Includes storage term: (θ - θ_old)/dt
!   - Builds residual vector RS for linear solver
!   - Called at each Picard iteration
!
!   BOUNDARY FLUX CALCULATION (rand_fl):
!   - Calculates actual fluxes at all boundaries from current solution
!   - Handles all 4 boundaries: bottom (unten), top (oben), right (rechts), left (links)
!   - Special treatment for corner points
!   - Calculates sink/source terms at interior points
!   - Computes flux violations (ueb_*) for BC switching logic
!   - Essential for mass balance and BC consistency
!
!   BOUNDARY CONDITION SWITCHING (chko_rb):
!   - Implements inequality boundary conditions (seepage faces, atmospheric BC)
!   - Checks if BC type should switch based on current state
!   - Switches between flux (Neumann) and potential (Dirichlet) BC
!   - Examples:
!     * Seepage face: flux=0 until saturation, then potential=0
!     * Atmospheric BC: infiltration flux until ponding, then potential=h_pond
!   - Returns rbchg flag if any BC changed (requires time step retry)
!   - Prevents oscillations and ensures physical consistency
!
!   STATE SAVE/LOAD (savevz, loadvz):
!   - Save/restore BC type flags (vorz_*) for time step retry
!   - Used when convergence fails or BC switching occurs
!   - Enables rollback to previous state
!   - Critical for adaptive time stepping
!
! NUMERICAL CONSIDERATIONS:
!
!   Thomas Algorithm Stability:
!   - Requires diagonally dominant matrix for stability
!   - No pivoting needed for Richards equation (property of FD scheme)
!   - Forward elimination must not divide by zero (check bet ≠ 0)
!   - Preserved EXACTLY from original code
!
!   ADI Splitting:
!   - Each half-step is unconditionally stable
!   - Full step has second-order accuracy in time
!   - Relaxation parameters affect convergence rate
!   - expant=1 gives Crank-Nicolson (most accurate)
!
!   Boundary Flux Accuracy:
!   - Uses finite difference approximation at boundaries
!   - Must be consistent with interior scheme
!   - Corner treatment ensures proper coupling
!   - Flux conservation critical for mass balance
!
!   BC Switching Logic:
!   - Must detect violation before solution diverges
!   - Hysteresis prevention (avoid rapid switching)
!   - Maximum 2 switches per time step (then reduce dt)
!   - Log string tracks which boundaries switched
!
! VALIDATION REQUIREMENTS:
!
!   1. Thomas algorithm:
!      - Test against known tridiagonal systems
!      - Verify O(n) complexity
!      - Check solution accuracy
!
!   2. ADI half-steps:
!      - Compare with full implicit solution
!      - Verify mass conservation
!      - Check convergence order
!
!   3. Picard setup:
!      - Verify residual calculation
!      - Check storage term accuracy
!      - Test convergence behavior
!
!   4. Boundary fluxes:
!      - Mass balance check (sum of boundary fluxes)
!      - Compare with analytical solutions
!      - Verify corner treatment
!
!   5. BC switching:
!      - Test seepage face behavior
!      - Check atmospheric BC transitions
!      - Verify no oscillations
!
!   6. State save/load:
!      - Verify perfect restoration
!      - Test rollback scenarios
!      - Check memory consistency
!
! ORIGINAL: ADDSTEPS.f (Fortran 77 with includes)
! AUTHOR: CATFLOW Streamlined
! DATE: 2025-11-09
!===============================================================================
module addsteps_module
    use constants_module, only: maxnv, maxnl
    implicit none
    private

    ! Make all 9 subroutines public
    public :: expcal
    public :: ee_ix
    public :: ex_ie
    public :: tridig
    public :: pic_it
    public :: rand_fl
    public :: chko_rb
    public :: savevz
    public :: loadvz

contains

    !===========================================================================
    ! SUBROUTINE: expcal
    !
    ! PURPOSE: Explicit calculation for explicit time stepping
    !
    ! DESCRIPTION:
    !   Implements one full explicit time step using forward Euler method:
    !   φ^(n+1) = φ^n + dt * F(φ^n)
    !
    !   The solution is assembled from the coefficient matrices and old state:
    !   φ_new = -RS + φ_old*(Fx_00 + Fe_00 + 1)
    !         + φ_xsi_plus*Fx_p1  + φ_xsi_minus*Fx_m1
    !         + φ_eta_plus*Fe_p1  + φ_eta_minus*Fe_m1
    !
    !   Algorithm:
    !   1. Loop over all nodes: combine diagonal terms
    !   2. Loop over xsi direction: add neighbor contributions
    !   3. Loop over eta direction: add neighbor contributions
    !
    !   The loop structure is optimized to avoid unnecessary array operations
    !   and follows the stencil pattern of the finite difference scheme.
    !
    ! STABILITY:
    !   Conditionally stable - requires dt < dt_exp where dt_exp depends on:
    !   - Mesh spacing (smaller cells → smaller dt)
    !   - Hydraulic conductivity (higher K → smaller dt)
    !   - Diffusivity (higher D → smaller dt)
    !
    ! ARGUMENTS:
    !   ih - Hillslope index [integer, input]
    !
    ! USES:
    !   state_data_module: coefficient matrices (Fx_*, Fe_*), RS, phineu, phialt
    !   mesh_geometry_module: iacnv, iacnl
    !===========================================================================
    subroutine expcal(ih)
        use state_data_module, only: Fx_00, Fx_p1, Fx_m1, Fe_00, Fe_p1, Fe_m1, &
                                      RS, phineu, phialt
        use mesh_geometry_module, only: iacnv, iacnl
        implicit none

        integer(4), intent(in) :: ih

        integer(4) :: iv, il

        ! Combine diagonal terms: φ_new = -RS + φ_old*(Fx_00 + Fe_00 + 1)
        do iv = 1, iacnv(ih)
            do il = 1, iacnl(ih)
                phineu(iv,il) = -RS(iv,il) + phialt(iv,il,ih) * &
                                (Fx_00(iv,il) + Fe_00(iv,il) + 1.0d0)
            end do
        end do

        ! Add xsi direction contributions
        do iv = 1, iacnv(ih)
            ! Forward neighbors (il+1)
            do il = 1, iacnl(ih) - 1
                phineu(iv,il) = phineu(iv,il) + phialt(iv,il+1,ih) * Fx_p1(iv,il)
            end do
            ! Backward neighbors (il-1)
            do il = 2, iacnl(ih)
                phineu(iv,il) = phineu(iv,il) + phialt(iv,il-1,ih) * Fx_m1(iv,il)
            end do
        end do

        ! Add eta direction contributions
        do il = 1, iacnl(ih)
            ! Forward neighbors (iv+1)
            do iv = 1, iacnv(ih) - 1
                phineu(iv,il) = phineu(iv,il) + phialt(iv+1,il,ih) * Fe_p1(iv,il)
            end do
            ! Backward neighbors (iv-1)
            do iv = 2, iacnv(ih)
                phineu(iv,il) = phineu(iv,il) + phialt(iv-1,il,ih) * Fe_m1(iv,il)
            end do
        end do

        return
    end subroutine expcal

    !===========================================================================
    ! SUBROUTINE: ee_ix
    !
    ! PURPOSE: ADI half-step with explicit eta, implicit xsi
    !
    ! DESCRIPTION:
    !   Performs one half-step of the Alternating Direction Implicit method.
    !   This half-step treats the eta (vertical) direction explicitly and
    !   the xsi (horizontal) direction implicitly.
    !
    !   Algorithm:
    !   1. Build RHS: RS -= φ_loc*(Fe_00 + expant) - explicit eta terms
    !   2. Add explicit eta neighbor contributions (Fe_p1, Fe_m1)
    !   3. For each eta level (constant iv):
    !      a) Set up tridiagonal system in xsi direction
    !      b) Solve using Thomas algorithm (tridig)
    !      c) Store solution in philoc
    !
    !   The implicit xsi direction creates tridiagonal systems:
    !   A(il)*φ(il-1) + B(il)*φ(il) + C(il)*φ(il+1) = R(il)
    !
    !   Relaxation parameters:
    !   - expant: implicit parameter (typically 1.0 for Crank-Nicolson)
    !   - omx: over-relaxation in xsi direction (typically 0.0)
    !
    ! ARGUMENTS:
    !   philoc  - Solution array [real*8(maxnv,maxnl), inout]
    !   ih      - Hillslope index [integer, input]
    !   expant  - Implicit parameter [real*8, input]
    !   omx     - Over-relaxation parameter xsi [real*8, input]
    !
    ! USES:
    !   state_data_module: coefficient matrices, RS
    !   mesh_geometry_module: iacnv, iacnl
    !===========================================================================
    subroutine ee_ix(philoc, ih, expant, omx)
        use state_data_module, only: Fx_00, Fx_p1, Fx_m1, Fe_00, Fe_p1, Fe_m1, RS
        use mesh_geometry_module, only: iacnv, iacnl
        implicit none

        real(8),    intent(inout) :: philoc(maxnv, maxnl)
        integer(4), intent(in)    :: ih
        real(8),    intent(in)    :: expant, omx

        integer(4) :: iv, il
        real(8) :: A(maxnl), B(maxnl), C(maxnl)
        real(8) :: R(maxnl), L(maxnl), H(maxnl)

        ! Build RHS: subtract explicit eta terms
        do iv = 1, iacnv(ih)
            do il = 1, iacnl(ih)
                RS(iv,il) = RS(iv,il) - philoc(iv,il) * (Fe_00(iv,il) + expant)
            end do
        end do

        ! Add explicit eta neighbor contributions
        do il = 1, iacnl(ih)
            ! Forward eta neighbors (iv+1)
            do iv = 1, iacnv(ih) - 1
                RS(iv,il) = RS(iv,il) - philoc(iv+1,il) * Fe_p1(iv,il)
            end do
            ! Backward eta neighbors (iv-1)
            do iv = 2, iacnv(ih)
                RS(iv,il) = RS(iv,il) - philoc(iv-1,il) * Fe_m1(iv,il)
            end do
        end do

        ! Solve implicit xsi direction for each eta level
        do iv = 1, iacnv(ih)
            ! Set up tridiagonal system
            do il = 1, iacnl(ih)
                A(il) = Fx_m1(iv,il)
                B(il) = Fx_00(iv,il) - 1.0d0 + omx
                C(il) = Fx_p1(iv,il)
                R(il) = RS(iv,il)
            end do

            ! Solve tridiagonal system
            call tridig(A, B, C, L, R, iacnl(ih), H)

            ! Store solution
            do il = 1, iacnl(ih)
                philoc(iv,il) = L(il)
            end do
        end do

        return
    end subroutine ee_ix

    !===========================================================================
    ! SUBROUTINE: ex_ie
    !
    ! PURPOSE: ADI half-step with explicit xsi, implicit eta
    !
    ! DESCRIPTION:
    !   Performs one half-step of the Alternating Direction Implicit method.
    !   This half-step treats the xsi (horizontal) direction explicitly and
    !   the eta (vertical) direction implicitly.
    !
    !   Algorithm:
    !   1. Build RHS: RS -= φ_loc*(Fx_00 + expant) - explicit xsi terms
    !   2. Add explicit xsi neighbor contributions (Fx_p1, Fx_m1)
    !   3. For each xsi position (constant il):
    !      a) Set up tridiagonal system in eta direction
    !      b) Solve using Thomas algorithm (tridig)
    !      c) Store solution in philoc
    !
    !   The implicit eta direction creates tridiagonal systems:
    !   A(iv)*φ(iv-1) + B(iv)*φ(iv) + C(iv)*φ(iv+1) = R(iv)
    !
    !   Relaxation parameters:
    !   - expant: implicit parameter (typically 1.0 for Crank-Nicolson)
    !   - ome: over-relaxation in eta direction (typically 0.0)
    !
    ! ARGUMENTS:
    !   philoc  - Solution array [real*8(maxnv,maxnl), inout]
    !   ih      - Hillslope index [integer, input]
    !   expant  - Implicit parameter [real*8, input]
    !   ome     - Over-relaxation parameter eta [real*8, input]
    !
    ! USES:
    !   state_data_module: coefficient matrices, RS
    !   mesh_geometry_module: iacnv, iacnl
    !===========================================================================
    subroutine ex_ie(philoc, ih, expant, ome)
        use state_data_module, only: Fx_00, Fx_p1, Fx_m1, Fe_00, Fe_p1, Fe_m1, RS
        use mesh_geometry_module, only: iacnv, iacnl
        implicit none

        real(8),    intent(inout) :: philoc(maxnv, maxnl)
        integer(4), intent(in)    :: ih
        real(8),    intent(in)    :: expant, ome

        integer(4) :: iv, il
        real(8) :: A(maxnv), B(maxnv), C(maxnv)
        real(8) :: R(maxnv), L(maxnv), H(maxnv)

        ! Build RHS: subtract explicit xsi terms
        do iv = 1, iacnv(ih)
            do il = 1, iacnl(ih)
                RS(iv,il) = RS(iv,il) - philoc(iv,il) * (Fx_00(iv,il) + expant)
            end do
        end do

        ! Add explicit xsi neighbor contributions
        do iv = 1, iacnv(ih)
            ! Forward xsi neighbors (il+1)
            do il = 1, iacnl(ih) - 1
                RS(iv,il) = RS(iv,il) - philoc(iv,il+1) * Fx_p1(iv,il)
            end do
            ! Backward xsi neighbors (il-1)
            do il = 2, iacnl(ih)
                RS(iv,il) = RS(iv,il) - philoc(iv,il-1) * Fx_m1(iv,il)
            end do
        end do

        ! Solve implicit eta direction for each xsi position
        do il = 1, iacnl(ih)
            ! Set up tridiagonal system
            do iv = 1, iacnv(ih)
                A(iv) = Fe_m1(iv,il)
                B(iv) = Fe_00(iv,il) - 1.0d0 + ome
                C(iv) = Fe_p1(iv,il)
                R(iv) = RS(iv,il)
            end do

            ! Solve tridiagonal system
            call tridig(A, B, C, L, R, iacnv(ih), H)

            ! Store solution
            do iv = 1, iacnv(ih)
                philoc(iv,il) = L(iv)
            end do
        end do

        return
    end subroutine ex_ie

    !===========================================================================
    ! SUBROUTINE: tridig
    !
    ! PURPOSE: Solve tridiagonal linear system using Thomas algorithm
    !
    ! DESCRIPTION:
    !   Solves the tridiagonal matrix equation A·u = r efficiently using
    !   the Thomas algorithm (a specialized form of Gaussian elimination).
    !
    !   Matrix structure:
    !   | b(1)  c(1)   0     0    ...   0   |   |u(1)|   |r(1)|
    !   | a(2)  b(2)  c(2)   0    ...   0   |   |u(2)|   |r(2)|
    !   |  0    a(3)  b(3)  c(3)  ...   0   | × |u(3)| = |r(3)|
    !   | ...   ...   ...   ...   ...  ...  |   | ... |   | ... |
    !   |  0     0     0    a(n) b(n) c(n-1)|   |u(n)|   |r(n)|
    !   |  0     0     0     0   a(n)  b(n) |   |u(n)|   |r(n)|
    !
    !   Thomas Algorithm (O(n) complexity):
    !   Forward elimination:
    !     gam(i) = c(i-1) / bet
    !     bet = b(i) - a(i) * gam(i)
    !     u(i) = (r(i) - a(i)*u(i-1)) / bet
    !
    !   Back substitution:
    !     u(i) = u(i) - gam(i+1) * u(i+1)
    !
    !   CRITICAL NUMERICAL STABILITY:
    !   - Requires diagonally dominant matrix (|b(i)| > |a(i)| + |c(i)|)
    !   - No pivoting needed for Richards equation (property of FD scheme)
    !   - Division by bet must not cause overflow/underflow
    !   - This implementation is EXACTLY preserved from original
    !
    ! ARGUMENTS:
    !   a   - Lower diagonal [real*8(*), input]
    !   b   - Main diagonal [real*8(*), input]
    !   c   - Upper diagonal [real*8(*), input]
    !   u   - Solution vector [real*8(*), output]
    !   r   - Right-hand side [real*8(*), input]
    !   n   - System size [integer, input]
    !   gam - Work array [real*8(*), workspace]
    !
    ! NOTES:
    !   - Arrays use assumed-size (*) for flexibility
    !   - Only indices 1:n are used
    !   - gam must be at least size n
    !   - This subroutine is called MANY times per time step
    !   - Performance critical - preserve exact algorithm
    !===========================================================================
    subroutine tridig(a, b, c, u, r, n, gam)
        implicit none

        integer(4), intent(in)    :: n
        real(8),    intent(in)    :: a(*), b(*), c(*), r(*)
        real(8),    intent(out)   :: u(*)
        real(8),    intent(inout) :: gam(*)

        integer(4) :: i
        real(8) :: bet

        ! Forward elimination
        bet = b(1)
        u(1) = r(1) / bet

        do i = 2, n
            gam(i) = c(i-1) / bet
            bet = b(i) - a(i) * gam(i)
            u(i) = (r(i) - a(i)*u(i-1)) / bet
        end do

        ! Back substitution
        do i = n-1, 1, -1
            u(i) = u(i) - gam(i+1) * u(i+1)
        end do

        return
    end subroutine tridig

    !===========================================================================
    ! SUBROUTINE: pic_it
    !
    ! PURPOSE: Set up linearized system for Picard iteration
    !
    ! DESCRIPTION:
    !   Transforms the Richards equation into a form suitable for Picard
    !   iteration. The Picard linearization uses the old solution to
    !   evaluate nonlinear coefficients:
    !
    !   C(φ_old)·∂φ/∂t = ∇·[K(φ_old)·∇φ] + sources
    !
    !   This creates a linear system for the correction Δφ = φ_new - φ_old:
    !   A·Δφ = RS
    !
    !   where RS (residual) includes:
    !   - Current solution contribution: -φ_new*(Fx_00 + Fe_00)
    !   - Neighbor contributions: -φ_new*Fx_p1, -φ_new*Fx_m1, etc.
    !   - Storage term: -(θ - θ_old) / dt
    !
    !   The storage term accounts for changes in water content and
    !   comes from the time derivative in Richards equation.
    !
    !   Algorithm:
    !   1. Subtract diagonal contributions from current solution
    !   2. Subtract storage term (θ change)
    !   3. Subtract xsi direction neighbor contributions
    !   4. Subtract eta direction neighbor contributions
    !
    !   After this, the linear solver (CG or ADI) solves A·Δφ = RS
    !   and the solution is updated: φ_new += Δφ
    !
    ! ARGUMENTS:
    !   ih - Hillslope index [integer, input]
    !
    ! USES:
    !   state_data_module: RS, phineu, Fx_*, Fe_*, theta, Th_alt, wasska
    !   mesh_geometry_module: iacnv, iacnl
    !
    ! NOTES:
    !   - wasska is the time step (dt) in the storage term
    !   - Storage term preserves mass: ∂θ/∂t = (θ - θ_old)/dt
    !===========================================================================
    subroutine pic_it(ih)
        use state_data_module, only: RS, phineu, Fx_00, Fx_p1, Fx_m1, &
                                      Fe_00, Fe_p1, Fe_m1, theta, Th_alt, wasska
        use mesh_geometry_module, only: iacnv, iacnl
        implicit none

        integer(4), intent(in) :: ih

        integer(4) :: iv, il

        ! Subtract diagonal terms and storage term
        do iv = 1, iacnv(ih)
            do il = 1, iacnl(ih)
                RS(iv,il) = RS(iv,il) - phineu(iv,il) * (Fx_00(iv,il) + Fe_00(iv,il)) &
                            - (theta(iv,il) - Th_alt(iv,il)) / wasska(iv,il)
            end do
        end do

        ! Subtract xsi direction neighbor contributions
        do iv = 1, iacnv(ih)
            ! Forward xsi neighbors (il+1)
            do il = 1, iacnl(ih) - 1
                RS(iv,il) = RS(iv,il) - phineu(iv,il+1) * Fx_p1(iv,il)
            end do
            ! Backward xsi neighbors (il-1)
            do il = 2, iacnl(ih)
                RS(iv,il) = RS(iv,il) - phineu(iv,il-1) * Fx_m1(iv,il)
            end do
        end do

        ! Subtract eta direction neighbor contributions
        do il = 1, iacnl(ih)
            ! Forward eta neighbors (iv+1)
            do iv = 1, iacnv(ih) - 1
                RS(iv,il) = RS(iv,il) - phineu(iv+1,il) * Fe_p1(iv,il)
            end do
            ! Backward eta neighbors (iv-1)
            do iv = 2, iacnv(ih)
                RS(iv,il) = RS(iv,il) - phineu(iv-1,il) * Fe_m1(iv,il)
            end do
        end do

        return
    end subroutine pic_it

    !===========================================================================
    ! SUBROUTINE: rand_fl
    !
    ! PURPOSE: Calculate boundary fluxes and check for violations
    !
    ! DESCRIPTION:
    !   Calculates the actual fluxes at all domain boundaries from the
    !   current solution. This is critical for:
    !   1. Mass balance verification
    !   2. Detecting BC violations (for inequality constraints)
    !   3. Output/reporting of boundary fluxes
    !
    !   For Dirichlet (potential) boundaries, the flux is back-calculated
    !   from the finite difference stencil. For Neumann (flux) boundaries,
    !   the prescribed flux is directly used.
    !
    !   The routine handles:
    !   - Inner boundary nodes (excluding corners)
    !   - Four corner points (special treatment)
    !   - Interior sinks/sources (vorz_s < 0)
    !
    !   Flux violation calculation:
    !   - For one-sided BC: ueb_* = q_pot - q_actual
    !   - If ueb > 0: prescribed flux violated, BC may switch
    !   - Used by chko_rb to trigger BC type changes
    !
    !   Corner point treatment:
    !   - If both boundaries are flux: shared calculation
    !   - If one is potential: that BC determines flux
    !   - If both are potential: cannot occur (physically inconsistent)
    !
    !   The flux calculation uses the finite difference stencil:
    !   q = (coefficients · φ_neighbors + φ_center - φ_old) / geometric_factor
    !
    ! ARGUMENTS:
    !   ih - Hillslope index [integer, input]
    !
    ! USES:
    !   state_data_module: coefficient matrices, phineu, phialt, vorfak
    !   mesh_geometry_module: geometric factors, fbrup, fbrlow
    !   boundary_conditions_module: vorz_*, lueb_*, qu_pot, etc.
    !
    ! NOTES:
    !   - Extremely complex routine with many special cases
    !   - Must preserve ALL logic exactly for physical consistency
    !   - Critical for BC switching and mass balance
    !===========================================================================
    subroutine rand_fl(ih)
        use state_data_module, only: Fx_00, Fx_p1, Fx_m1, Fe_00, Fe_p1, Fe_m1, &
                                      phineu, phialt, vorfak, A_x, A_e
        use mesh_geometry_module, only: iacnv, iacnl, f_xsi, f_eta, &
                                         x_p1m1, x_p1m0, e_p1m1, e_p1m0, &
                                         fbrup, fbrlow
        use boundary_conditions_module, only: vorz_u, vorz_o, vorz_r, vorz_l, vorz_s, &
                                               lueb_u, lueb_o, lueb_r, lueb_l, lueb_s, &
                                               rfl_u, rfl_o, rfl_r, rfl_l, &
                                               qu_pot, qo_pot, qr_pot, ql_pot, qs_pot, &
                                               ueb_u, ueb_o, ueb_r, ueb_l, sueb, senk
        implicit none

        integer(4), intent(in) :: ih

        integer(4) :: iv, il

        !-----------------------------------------------------------------------
        ! Bottom and top boundaries (inner nodes, excluding corners)
        !-----------------------------------------------------------------------
        do il = 2, iacnl(ih) - 1

            ! Bottom boundary (unten)
            iv = 1
            if (vorz_u(il,ih) .lt. 0) then
                ! Dirichlet BC: calculate flux from stencil
                Fx_p1(iv,il) = -A_x(iv,il) * vorfak(iv,il) / x_p1m1(il-1,ih) * fbrup(il,ih)
                Fx_00(iv,il) = (A_x(iv,il)*fbrup(il,ih) + A_x(iv,il-1)*fbrlow(il,ih)) &
                               * vorfak(iv,il) / x_p1m1(il-1,ih)
                Fx_m1(iv,il) = -A_x(iv,il-1) * vorfak(iv,il) / x_p1m1(il-1,ih) * fbrlow(il,ih)
                Fe_p1(iv,il) = -A_e(iv,il) * vorfak(iv,il) / e_p1m0(iv,ih)
                Fe_00(iv,il) = -Fe_p1(iv,il)

                rfl_u(il) = (Fx_p1(iv,il) * phineu(iv,il+1) &
                           + Fx_m1(iv,il) * phineu(iv,il-1) &
                           + Fe_p1(iv,il) * phineu(iv+1,il) &
                           + (Fx_00(iv,il) + Fe_00(iv,il) - 1.0d0) * phineu(iv,il) &
                           + phialt(iv,il,ih)) &
                           * e_p1m0(iv,ih) / (2.0d0 * f_xsi(iv,il,ih) * vorfak(iv,il))
            end if

            if (lueb_u(il)) then
                ueb_u(il) = qu_pot(il) - rfl_u(il)
            else
                ueb_u(il) = 0.0d0
            end if

            ! Top boundary (oben)
            iv = iacnv(ih)
            if (vorz_o(il,ih) .lt. 0) then
                ! Dirichlet BC: calculate flux from stencil
                Fx_p1(iv,il) = -A_x(iv,il) * vorfak(iv,il) / x_p1m1(il-1,ih) * fbrup(il,ih)
                Fx_00(iv,il) = (A_x(iv,il)*fbrup(il,ih) + A_x(iv,il-1)*fbrlow(il,ih)) &
                               * vorfak(iv,il) / x_p1m1(il-1,ih)
                Fx_m1(iv,il) = -A_x(iv,il-1) * vorfak(iv,il) / x_p1m1(il-1,ih) * fbrlow(il,ih)
                Fe_m1(iv,il) = -A_e(iv-1,il) * vorfak(iv,il) / e_p1m0(iv-1,ih)
                Fe_00(iv,il) = -Fe_m1(iv,il)

                rfl_o(il) = (Fx_p1(iv,il) * phineu(iv,il+1) &
                           + Fx_m1(iv,il) * phineu(iv,il-1) &
                           + Fe_m1(iv,il) * phineu(iv-1,il) &
                           + (Fx_00(iv,il) + Fe_00(iv,il) - 1.0d0) * phineu(iv,il) &
                           + phialt(iv,il,ih)) &
                           * e_p1m0(iv-1,ih) / (-2.0d0 * f_xsi(iv,il,ih) * vorfak(iv,il))
            end if

            if (lueb_o(il)) then
                ueb_o(il) = qo_pot(il) - rfl_o(il)
            else
                ueb_o(il) = 0.0d0
            end if

        end do

        !-----------------------------------------------------------------------
        ! Left and right boundaries (inner nodes, excluding corners)
        !-----------------------------------------------------------------------
        do iv = 2, iacnv(ih) - 1

            ! Left boundary (links)
            il = 1
            if (vorz_l(iv,ih) .lt. 0) then
                ! Dirichlet BC: calculate flux from stencil
                Fe_p1(iv,il) = -A_e(iv,il) * vorfak(iv,il) / e_p1m1(iv-1,ih)
                Fe_00(iv,il) = (A_e(iv,il) + A_e(iv-1,il)) * vorfak(iv,il) / e_p1m1(iv-1,ih)
                Fe_m1(iv,il) = -A_e(iv-1,il) * vorfak(iv,il) / e_p1m1(iv-1,ih)
                Fx_p1(iv,il) = -A_x(iv,il) * vorfak(iv,il) / x_p1m0(il,ih) * fbrup(il,ih)
                Fx_00(iv,il) = -Fx_p1(iv,il)

                rfl_l(iv) = (Fe_p1(iv,il) * phineu(iv+1,il) &
                           + Fe_m1(iv,il) * phineu(iv-1,il) &
                           + Fx_p1(iv,il) * phineu(iv,il+1) &
                           + (Fx_00(iv,il) + Fe_00(iv,il) - 1.0d0) * phineu(iv,il) &
                           + phialt(iv,il,ih)) &
                           * x_p1m0(il,ih) / (2.0d0 * f_eta(iv,il,ih) * vorfak(iv,il))
            end if

            if (lueb_l(iv)) then
                ueb_l(iv) = ql_pot(iv) - rfl_l(iv)
            else
                ueb_l(iv) = 0.0d0
            end if

            ! Right boundary (rechts)
            il = iacnl(ih)
            if (vorz_r(iv,ih) .lt. 0) then
                ! Dirichlet BC: calculate flux from stencil
                Fe_p1(iv,il) = -A_e(iv,il) * vorfak(iv,il) / e_p1m1(iv-1,ih)
                Fe_00(iv,il) = (A_e(iv,il) + A_e(iv-1,il)) * vorfak(iv,il) / e_p1m1(iv-1,ih)
                Fe_m1(iv,il) = -A_e(iv-1,il) * vorfak(iv,il) / e_p1m1(iv-1,ih)
                Fx_m1(iv,il) = -A_x(iv,il-1) * vorfak(iv,il) / x_p1m0(il-1,ih) * fbrlow(il,ih)
                Fx_00(iv,il) = -Fx_m1(iv,il)

                rfl_r(iv) = (Fe_p1(iv,il) * phineu(iv+1,il) &
                           + Fe_m1(iv,il) * phineu(iv-1,il) &
                           + Fx_m1(iv,il) * phineu(iv,il-1) &
                           + (Fx_00(iv,il) + Fe_00(iv,il) - 1.0d0) * phineu(iv,il) &
                           + phialt(iv,il,ih)) &
                           * x_p1m0(il-1,ih) / (-2.0d0 * f_eta(iv,il,ih) * vorfak(iv,il))
            end if

            if (lueb_r(iv)) then
                ueb_r(iv) = qr_pot(iv) - rfl_r(iv)
            else
                ueb_r(iv) = 0.0d0
            end if

        end do

        !-----------------------------------------------------------------------
        ! Corner: Bottom-Left
        !-----------------------------------------------------------------------
        il = 1
        iv = 1
        if ((vorz_u(il,ih) .lt. 0) .or. (vorz_l(iv,ih) .lt. 0)) then
            Fe_p1(iv,il) = -A_e(iv,il) * vorfak(iv,il) / e_p1m0(iv,ih)
            Fe_00(iv,il) = -Fe_p1(iv,il)
            Fx_p1(iv,il) = -A_x(iv,il) * vorfak(iv,il) / x_p1m0(il,ih) * fbrup(il,ih)
            Fx_00(iv,il) = -Fx_p1(iv,il)

            ! Different cases based on which boundaries are Dirichlet
            if (vorz_u(il,ih) * vorz_l(iv,ih) .lt. 0) then
                ! One Dirichlet, one Neumann
                if (vorz_l(iv,ih) .lt. 0) then
                    ! Left is Dirichlet
                    rfl_l(iv) = (Fe_p1(iv,il) * phineu(iv+1,il) &
                               - 2.0d0 * f_xsi(iv,il,ih) * rfl_u(il) * vorfak(iv,il) / e_p1m0(iv,ih) &
                               + Fx_p1(iv,il) * phineu(iv,il+1) &
                               + (Fx_00(iv,il) + Fe_00(iv,il) - 1.0d0) * phineu(iv,il) &
                               + phialt(iv,il,ih)) &
                               * x_p1m0(il,ih) / (2.0d0 * f_eta(iv,il,ih) * vorfak(iv,il))
                end if

                if (vorz_u(il,ih) .lt. 0) then
                    ! Bottom is Dirichlet
                    rfl_u(il) = (Fx_p1(iv,il) * phineu(iv,il+1) &
                               - 2.0d0 * f_eta(iv,il,ih) * rfl_l(iv) * vorfak(iv,il) / x_p1m0(il,ih) &
                               + Fe_p1(iv,il) * phineu(iv+1,il) &
                               + (Fx_00(iv,il) + Fe_00(iv,il) - 1.0d0) * phineu(iv,il) &
                               + phialt(iv,il,ih)) &
                               * e_p1m0(iv,ih) / (2.0d0 * f_xsi(iv,il,ih) * vorfak(iv,il))
                end if
            else
                ! Both same type (either both Neumann or both Dirichlet - shared calculation)
                rfl_u(il) = (Fx_p1(iv,il) * phineu(iv,il+1) &
                           + Fe_p1(iv,il) * phineu(iv+1,il) &
                           + (Fx_00(iv,il) + Fe_00(iv,il) - 1.0d0) * phineu(iv,il) &
                           + phialt(iv,il,ih)) &
                           * e_p1m0(iv,ih) / (4.0d0 * f_xsi(iv,il,ih) * vorfak(iv,il))
                rfl_l(iv) = rfl_u(il)
            end if
        end if

        if (lueb_u(il)) then
            ueb_u(il) = qu_pot(il) - rfl_u(il)
        else
            ueb_u(il) = 0.0d0
        end if
        if (lueb_l(iv)) then
            ueb_l(iv) = ql_pot(iv) - rfl_l(iv)
        else
            ueb_l(iv) = 0.0d0
        end if

        !-----------------------------------------------------------------------
        ! Corner: Bottom-Right
        !-----------------------------------------------------------------------
        il = iacnl(ih)
        iv = 1
        if ((vorz_u(il,ih) .lt. 0) .or. (vorz_r(iv,ih) .lt. 0)) then
            Fe_p1(iv,il) = -A_e(iv,il) * vorfak(iv,il) / e_p1m0(iv,ih)
            Fe_00(iv,il) = -Fe_p1(iv,il)
            Fx_m1(iv,il) = -A_x(iv,il-1) * vorfak(iv,il) / x_p1m0(il-1,ih) * fbrlow(il,ih)
            Fx_00(iv,il) = -Fx_m1(iv,il)

            if (vorz_u(il,ih) * vorz_r(iv,ih) .lt. 0) then
                if (vorz_r(iv,ih) .lt. 0) then
                    ! Right is Dirichlet
                    rfl_r(iv) = (Fe_p1(iv,il) * phineu(iv+1,il) &
                               - 2.0d0 * f_xsi(iv,il,ih) * rfl_u(il) * vorfak(iv,il) / e_p1m0(iv,ih) &
                               + Fx_m1(iv,il) * phineu(iv,il-1) &
                               + (Fx_00(iv,il) + Fe_00(iv,il) - 1.0d0) * phineu(iv,il) &
                               + phialt(iv,il,ih)) &
                               * x_p1m0(il-1,ih) / (-2.0d0 * f_eta(iv,il,ih) * vorfak(iv,il))
                end if

                if (vorz_u(il,ih) .lt. 0) then
                    ! Bottom is Dirichlet
                    rfl_u(il) = (2.0d0 * f_eta(iv,il,ih) * rfl_r(iv) * vorfak(iv,il) / x_p1m0(il-1,ih) &
                               + Fx_m1(iv,il) * phineu(iv,il-1) &
                               + Fe_p1(iv,il) * phineu(iv+1,il) &
                               + (Fx_00(iv,il) + Fe_00(iv,il) - 1.0d0) * phineu(iv,il) &
                               + phialt(iv,il,ih)) &
                               * e_p1m0(iv,ih) / (2.0d0 * f_xsi(iv,il,ih) * vorfak(iv,il))
                end if
            else
                rfl_u(il) = (Fx_m1(iv,il) * phineu(iv,il-1) &
                           + Fe_p1(iv,il) * phineu(iv+1,il) &
                           + (Fx_00(iv,il) + Fe_00(iv,il) - 1.0d0) * phineu(iv,il) &
                           + phialt(iv,il,ih)) &
                           * e_p1m0(iv,ih) / (4.0d0 * f_xsi(iv,il,ih) * vorfak(iv,il))
                rfl_r(iv) = -rfl_u(il)
            end if
        end if

        if (lueb_u(il)) then
            ueb_u(il) = qu_pot(il) - rfl_u(il)
        else
            ueb_u(il) = 0.0d0
        end if
        if (lueb_r(iv)) then
            ueb_r(iv) = qr_pot(iv) - rfl_r(iv)
        else
            ueb_r(iv) = 0.0d0
        end if

        !-----------------------------------------------------------------------
        ! Corner: Top-Left
        !-----------------------------------------------------------------------
        il = 1
        iv = iacnv(ih)
        if ((vorz_o(il,ih) .lt. 0) .or. (vorz_l(iv,ih) .lt. 0)) then
            Fe_m1(iv,il) = -A_e(iv-1,il) * vorfak(iv,il) / e_p1m0(iv-1,ih)
            Fe_00(iv,il) = -Fe_m1(iv,il)
            Fx_p1(iv,il) = -A_x(iv,il) * vorfak(iv,il) / x_p1m0(il,ih) * fbrup(il,ih)
            Fx_00(iv,il) = -Fx_p1(iv,il)

            if (vorz_o(il,ih) * vorz_l(iv,ih) .lt. 0) then
                if (vorz_l(iv,ih) .lt. 0) then
                    ! Left is Dirichlet
                    rfl_l(iv) = (2.0d0 * f_xsi(iv,il,ih) * rfl_o(il) * vorfak(iv,il) / e_p1m0(iv-1,ih) &
                               + Fe_m1(iv,il) * phineu(iv-1,il) &
                               + Fx_p1(iv,il) * phineu(iv,il+1) &
                               + (Fx_00(iv,il) + Fe_00(iv,il) - 1.0d0) * phineu(iv,il) &
                               + phialt(iv,il,ih)) &
                               * x_p1m0(il,ih) / (2.0d0 * f_eta(iv,il,ih) * vorfak(iv,il))
                end if

                if (vorz_o(il,ih) .lt. 0) then
                    ! Top is Dirichlet
                    rfl_o(il) = (Fx_p1(iv,il) * phineu(iv,il+1) &
                               + Fe_m1(iv,il) * phineu(iv-1,il) &
                               - 2.0d0 * f_eta(iv,il,ih) * rfl_l(iv) * vorfak(iv,il) / x_p1m0(il,ih) &
                               + (Fx_00(iv,il) + Fe_00(iv,il) - 1.0d0) * phineu(iv,il) &
                               + phialt(iv,il,ih)) &
                               * e_p1m0(iv-1,ih) / (-2.0d0 * f_xsi(iv,il,ih) * vorfak(iv,il))
                end if
            else
                rfl_o(il) = (Fx_p1(iv,il) * phineu(iv,il+1) &
                           + Fe_m1(iv,il) * phineu(iv-1,il) &
                           + (Fx_00(iv,il) + Fe_00(iv,il) - 1.0d0) * phineu(iv,il) &
                           + phialt(iv,il,ih)) &
                           * e_p1m0(iv-1,ih) / (-4.0d0 * f_xsi(iv,il,ih) * vorfak(iv,il))
                rfl_l(iv) = -rfl_o(il)
            end if
        end if

        if (lueb_o(il)) then
            ueb_o(il) = qo_pot(il) - rfl_o(il)
        else
            ueb_o(il) = 0.0d0
        end if
        if (lueb_l(iv)) then
            ueb_l(iv) = ql_pot(iv) - rfl_l(iv)
        else
            ueb_l(iv) = 0.0d0
        end if

        !-----------------------------------------------------------------------
        ! Corner: Top-Right
        !-----------------------------------------------------------------------
        il = iacnl(ih)
        iv = iacnv(ih)
        if ((vorz_o(il,ih) .lt. 0) .or. (vorz_r(iv,ih) .lt. 0)) then
            Fe_m1(iv,il) = -A_e(iv-1,il) * vorfak(iv,il) / e_p1m0(iv-1,ih)
            Fe_00(iv,il) = -Fe_m1(iv,il)
            Fx_m1(iv,il) = -A_x(iv,il-1) * vorfak(iv,il) / x_p1m0(il-1,ih) * fbrlow(il,ih)
            Fx_00(iv,il) = -Fx_m1(iv,il)

            if (vorz_o(il,ih) * vorz_r(iv,ih) .lt. 0) then
                if (vorz_r(iv,ih) .lt. 0) then
                    ! Right is Dirichlet
                    rfl_r(iv) = (2.0d0 * f_xsi(iv,il,ih) * rfl_o(il) * vorfak(iv,il) / e_p1m0(iv-1,ih) &
                               + Fe_m1(iv,il) * phineu(iv-1,il) &
                               + Fx_m1(iv,il) * phineu(iv,il-1) &
                               + (Fx_00(iv,il) + Fe_00(iv,il) - 1.0d0) * phineu(iv,il) &
                               + phialt(iv,il,ih)) &
                               * x_p1m0(il-1,ih) / (-2.0d0 * f_eta(iv,il,ih) * vorfak(iv,il))
                end if

                if (vorz_o(il,ih) .lt. 0) then
                    ! Top is Dirichlet
                    rfl_o(il) = (2.0d0 * f_eta(iv,il,ih) * rfl_r(iv) * vorfak(iv,il) / x_p1m0(il-1,ih) &
                               + Fx_m1(iv,il) * phineu(iv,il-1) &
                               + Fe_m1(iv,il) * phineu(iv-1,il) &
                               + (Fx_00(iv,il) + Fe_00(iv,il) - 1.0d0) * phineu(iv,il) &
                               + phialt(iv,il,ih)) &
                               * e_p1m0(iv-1,ih) / (-2.0d0 * f_xsi(iv,il,ih) * vorfak(iv,il))
                end if
            else
                rfl_o(il) = (Fx_m1(iv,il) * phineu(iv,il-1) &
                           + Fe_m1(iv,il) * phineu(iv-1,il) &
                           + (Fx_00(iv,il) + Fe_00(iv,il) - 1.0d0) * phineu(iv,il) &
                           + phialt(iv,il,ih)) &
                           * e_p1m0(iv-1,ih) / (-4.0d0 * f_xsi(iv,il,ih) * vorfak(iv,il))
                rfl_r(iv) = rfl_o(il)
            end if
        end if

        if (lueb_o(il)) then
            ueb_o(il) = qo_pot(il) - rfl_o(il)
        else
            ueb_o(il) = 0.0d0
        end if
        if (lueb_r(iv)) then
            ueb_r(iv) = qr_pot(iv) - rfl_r(iv)
        else
            ueb_r(iv) = 0.0d0
        end if

        !-----------------------------------------------------------------------
        ! Interior sinks/sources (only at inner points)
        !-----------------------------------------------------------------------
        do il = 2, iacnl(ih) - 1
            do iv = 2, iacnv(ih) - 1
                if (vorz_s(iv,il,ih) .lt. 0) then
                    ! Dirichlet sink/source BC: calculate flux
                    Fx_p1(iv,il) = -A_x(iv,il) * vorfak(iv,il) / x_p1m1(il-1,ih) * fbrup(il,ih)
                    Fx_00(iv,il) = (A_x(iv,il)*fbrup(il,ih) + A_x(iv,il-1)*fbrlow(il,ih)) &
                                   * vorfak(iv,il) / x_p1m1(il-1,ih)
                    Fx_m1(iv,il) = -A_x(iv,il-1) * vorfak(iv,il) / x_p1m1(il-1,ih) * fbrlow(il,ih)
                    Fe_p1(iv,il) = -A_e(iv,il) * vorfak(iv,il) / e_p1m1(iv-1,ih)
                    Fe_00(iv,il) = (A_e(iv,il) + A_e(iv-1,il)) * vorfak(iv,il) / e_p1m1(iv-1,ih)
                    Fe_m1(iv,il) = -A_e(iv-1,il) * vorfak(iv,il) / e_p1m1(iv-1,ih)

                    senk(iv,il) = -(Fe_p1(iv,il) * phineu(iv+1,il) &
                                  + Fe_m1(iv,il) * phineu(iv-1,il) &
                                  + Fx_p1(iv,il) * phineu(iv,il+1) &
                                  + Fx_m1(iv,il) * phineu(iv,il-1) &
                                  + (Fx_00(iv,il) + Fe_00(iv,il) - 1.0d0) * phineu(iv,il) &
                                  + phialt(iv,il,ih)) / vorfak(iv,il)
                end if

                if (lueb_s(iv,il)) then
                    sueb(iv,il) = qs_pot(iv,il) - senk(iv,il)
                else
                    sueb(iv,il) = 0.0d0
                end if
            end do
        end do

        return
    end subroutine rand_fl

    !===========================================================================
    ! SUBROUTINE: chko_rb
    !
    ! PURPOSE: Check and switch boundary conditions for inequality constraints
    !
    ! DESCRIPTION:
    !   Implements the critical logic for switching between Neumann (flux) and
    !   Dirichlet (potential) boundary conditions when inequality constraints
    !   are violated. This enables physically realistic behavior like:
    !
    !   - Seepage faces: water exits only when saturated (φ ≥ 0)
    !   - Atmospheric BC: infiltration until ponding (φ ≥ h_surface)
    !   - Stream coupling: flux until head reaches stream level
    !
    !   Inequality BC logic:
    !   If vorz = -1 (Dirichlet, potential prescribed):
    !     - Calculate actual flux from solution
    !     - If flux violates constraint (e.g., flow into dry soil)
    !     - Switch to vorz = +1 (Neumann, flux prescribed)
    !
    !   If vorz = +1 (Neumann, flux prescribed):
    !     - Check if potential violates constraint
    !     - If violation (e.g., ponding occurs)
    !     - Switch to vorz = -1 (Dirichlet, potential prescribed)
    !
    !   The switching is controlled by BC type (irbtyp):
    !   - Type 10:  Seepage face (one-sided BC)
    !   - Type 11:  General one-sided BC with specified thresholds
    !   - Type -99: Atmospheric BC (climate-driven)
    !
    !   When a BC switches:
    !   - Set rbchg = .true. (signals need for time step retry)
    !   - Update vorz flag to new BC type
    !   - Log which boundary switched (rblog string)
    !
    !   The log string format:
    !   - Lower case (r,l,o,u,s): switched from Dirichlet to Neumann
    !   - Upper case (R,L,O,U,S): switched from Neumann to Dirichlet
    !   - Number following letter: index of boundary node
    !
    !   Maximum 2 switches allowed per time step. If rbchg occurs twice,
    !   the solver must reduce the time step to avoid oscillations.
    !
    ! ARGUMENTS:
    !   ih     - Hillslope index [integer, input]
    !   rbchg  - BC change flag [logical, output]
    !   rblog  - Log string (80 chars) [character*80, output]
    !
    ! USES:
    !   state_data_module: phineu
    !   mesh_geometry_module: iacnv, iacnl, hko
    !   boundary_conditions_module: vorz_*, lueb_*, irb_*, irbtyp, q*_pot, p*_pot, rfl_*
    !   atmosphere_module: yoben (surface water depth)
    !
    ! NOTES:
    !   - This is one of the most complex subroutines in CATFLOW
    !   - Every detail must be preserved exactly
    !   - Critical for physical realism and numerical stability
    !   - Failure to handle BC switching causes solution oscillations
    !===========================================================================
    subroutine chko_rb(ih, rbchg, rblog)
        use state_data_module, only: phineu
        use mesh_geometry_module, only: iacnv, iacnl, hko
        use boundary_conditions_module, only: vorz_u, vorz_o, vorz_r, vorz_l, vorz_s, &
                                               lueb_u, lueb_o, lueb_r, lueb_l, lueb_s, &
                                               irb_u, irb_o, irb_r, irb_l, isnk, &
                                               irbtyp, isktyp, &
                                               qu_pot, qo_pot, qr_pot, ql_pot, qs_pot, &
                                               pu_pot, po_pot, pr_pot, pl_pot, ps_pot, &
                                               rfl_u, rfl_o, rfl_r, rfl_l, senk
        implicit none

        integer(4), intent(in)  :: ih
        logical,    intent(out) :: rbchg
        character(80), intent(out) :: rblog

        integer(4) :: iv, il, irblog
        logical :: ltest

        intrinsic :: abs

        rbchg = .false.
        write(rblog, 111)
111     format(80(' '))
        irblog = 1

        !-----------------------------------------------------------------------
        ! Check left and right boundaries
        !-----------------------------------------------------------------------
        do iv = 1, iacnv(ih)

            ! Right boundary (rechts)
            il = iacnl(ih)
            ltest = .false.

            ! Determine if this boundary has inequality constraints
            if (irb_r(iv,ih) .gt. 0) then
                if (abs(irbtyp(1,irb_r(iv,ih))) .eq. 11) ltest = .true.
                if (abs(irbtyp(1,irb_r(iv,ih))) .eq. 10) ltest = .true.
            elseif (irb_r(iv,ih) .eq. -10) then
                ltest = .true.
            elseif (irb_r(iv,ih) .eq. -99) then
                ltest = .true.
            end if

            if (ltest) then
                ! Currently Dirichlet (potential prescribed)
                if (vorz_r(iv,ih) .eq. -1) then
                    lueb_r(iv) = .true.
                    ! Check if flux constraint violated
                    if (rfl_r(iv) .lt. qr_pot(iv)) then
                        rbchg = .true.
                        if (irblog .le. 77) then
                            write(rblog(irblog+1:irblog+1), '(a)') 'r'
                            write(rblog(irblog+2:irblog+3), '(i2)') iv
                        end if
                        irblog = irblog + 3
                        vorz_r(iv,ih) = 1
                        lueb_r(iv) = .false.
                    end if
                ! Currently Neumann (flux prescribed)
                elseif (vorz_r(iv,ih) .eq. 1) then
                    lueb_r(iv) = .false.
                    ! Check if potential constraint violated
                    if (phineu(iv,il) .gt. pr_pot(iv)) then
                        rbchg = .true.
                        if (irblog .le. 77) then
                            write(rblog(irblog+1:irblog+1), '(a)') 'R'
                            write(rblog(irblog+2:irblog+3), '(i2)') iv
                        end if
                        irblog = irblog + 3
                        vorz_r(iv,ih) = -1
                        lueb_r(iv) = .true.
                    end if
                end if
            else
                lueb_r(iv) = .false.
            end if

            ! Left boundary (links)
            il = 1
            ltest = .false.

            if (irb_l(iv,ih) .gt. 0) then
                if (abs(irbtyp(1,irb_l(iv,ih))) .eq. 11) ltest = .true.
                if (abs(irbtyp(1,irb_l(iv,ih))) .eq. 10) ltest = .true.
            elseif (irb_l(iv,ih) .eq. -10) then
                ltest = .true.
            end if

            if (ltest) then
                if (vorz_l(iv,ih) .eq. -1) then
                    lueb_l(iv) = .true.
                    if (rfl_l(iv) .gt. ql_pot(iv)) then
                        rbchg = .true.
                        if (irblog .le. 77) then
                            write(rblog(irblog+1:irblog+1), '(a)') 'l'
                            write(rblog(irblog+2:irblog+3), '(i2)') iv
                        end if
                        irblog = irblog + 3
                        vorz_l(iv,ih) = 1
                        lueb_l(iv) = .false.
                    end if
                elseif (vorz_l(iv,ih) .eq. 1) then
                    lueb_l(iv) = .false.
                    if (phineu(iv,il) .gt. pl_pot(iv)) then
                        rbchg = .true.
                        if (irblog .le. 77) then
                            write(rblog(irblog+1:irblog+1), '(a)') 'L'
                            write(rblog(irblog+2:irblog+3), '(i2)') iv
                        end if
                        irblog = irblog + 3
                        vorz_l(iv,ih) = -1
                        lueb_l(iv) = .true.
                    end if
                end if
            else
                lueb_l(iv) = .false.
            end if

        end do

        !-----------------------------------------------------------------------
        ! Check top and bottom boundaries
        !-----------------------------------------------------------------------
        do il = 1, iacnl(ih)

            ! Top boundary (oben)
            iv = iacnv(ih)
            ltest = .false.

            if (irb_o(il,ih) .gt. 0) then
                if (abs(irbtyp(1,irb_o(il,ih))) .eq. 11) ltest = .true.
                if (abs(irbtyp(1,irb_o(il,ih))) .eq. 10) ltest = .true.
            elseif (irb_o(il,ih) .eq. -10) then
                ltest = .true.
            elseif (irb_o(il,ih) .eq. -99) then
                ltest = .true.
            end if

            if (ltest) then
                if (vorz_o(il,ih) .eq. -1) then
                    lueb_o(il) = .true.
                    if (rfl_o(il) .lt. qo_pot(il)) then
                        rbchg = .true.
                        if (irblog .le. 77) then
                            write(rblog(irblog+1:irblog+1), '(a)') 'o'
                            write(rblog(irblog+2:irblog+3), '(i2)') il
                        end if
                        irblog = irblog + 3
                        vorz_o(il,ih) = 1
                        lueb_o(il) = .false.
                    end if
                elseif (vorz_o(il,ih) .eq. 1) then
                    lueb_o(il) = .false.
                    ! Check for saturation (ponding)
                    if (phineu(iv,il) .ge. hko(iv,il,ih)) then
                        rbchg = .true.
                        if (irblog .le. 77) then
                            write(rblog(irblog+1:irblog+1), '(a)') 'O'
                            write(rblog(irblog+2:irblog+3), '(i2)') il
                        end if
                        irblog = irblog + 3
                        vorz_o(il,ih) = -1
                        lueb_o(il) = .true.
                    end if
                end if
            else
                lueb_o(il) = .false.
            end if

            ! Bottom boundary (unten)
            iv = 1
            ltest = .false.

            if (irb_u(il,ih) .gt. 0) then
                if (abs(irbtyp(1,irb_u(il,ih))) .eq. 11) ltest = .true.
                if (abs(irbtyp(1,irb_u(il,ih))) .eq. 10) ltest = .true.
            elseif (irb_u(il,ih) .eq. -10) then
                ltest = .true.
            end if

            if (ltest) then
                if (vorz_u(il,ih) .eq. -1) then
                    lueb_u(il) = .true.
                    if (rfl_u(il) .gt. qu_pot(il)) then
                        rbchg = .true.
                        if (irblog .le. 77) then
                            write(rblog(irblog+1:irblog+1), '(a)') 'u'
                            write(rblog(irblog+2:irblog+3), '(i2)') il
                        end if
                        irblog = irblog + 3
                        vorz_u(il,ih) = 1
                        lueb_u(il) = .false.
                    end if
                elseif (vorz_u(il,ih) .eq. 1) then
                    lueb_u(il) = .false.
                    if (phineu(iv,il) .gt. pu_pot(il)) then
                        rbchg = .true.
                        if (irblog .le. 77) then
                            write(rblog(irblog+1:irblog+1), '(a)') 'U'
                            write(rblog(irblog+2:irblog+3), '(i2)') il
                        end if
                        irblog = irblog + 3
                        vorz_u(il,ih) = -1
                        lueb_u(il) = .true.
                    end if
                end if
            else
                lueb_u(il) = .false.
            end if

        end do

        !-----------------------------------------------------------------------
        ! Check interior sinks/sources
        !-----------------------------------------------------------------------
        do iv = 2, iacnv(ih) - 1
            do il = 2, iacnl(ih) - 1
                ltest = .false.

                if (isnk(iv,il,ih) .gt. 0) then
                    if (abs(isktyp(1,isnk(iv,il,ih))) .eq. 11) ltest = .true.
                    if (abs(isktyp(1,isnk(iv,il,ih))) .eq. 10) ltest = .true.
                elseif (isnk(iv,il,ih) .eq. -10) then
                    ltest = .true.
                elseif (isnk(iv,il,ih) .eq. -99) then
                    ltest = .true.
                end if

                if (ltest) then
                    ! Sink (removal): qs_pot >= 0
                    if (qs_pot(iv,il) .ge. 0.0d0) then
                        if (vorz_s(iv,il,ih) .eq. -1) then
                            lueb_s(iv,il) = .true.
                            ! Cannot extract more than qs_pot
                            if (senk(iv,il) .gt. qs_pot(iv,il)) then
                                rbchg = .true.
                                if (irblog .le. 75) then
                                    write(rblog(irblog+1:irblog+1), '(a)') 's'
                                    write(rblog(irblog+2:irblog+5), '(2i2)') iv, il
                                end if
                                irblog = irblog + 5
                                vorz_s(iv,il,ih) = 1
                                lueb_s(iv,il) = .false.
                            end if
                        elseif (vorz_s(iv,il,ih) .eq. 1) then
                            lueb_s(iv,il) = .false.
                            ! Cannot get drier than ps_pot
                            if (phineu(iv,il) .lt. ps_pot(iv,il)) then
                                rbchg = .true.
                                if (irblog .le. 75) then
                                    write(rblog(irblog+1:irblog+1), '(a)') 'S'
                                    write(rblog(irblog+2:irblog+5), '(2i2)') iv, il
                                end if
                                irblog = irblog + 5
                                vorz_s(iv,il,ih) = -1
                                lueb_s(iv,il) = .true.
                            end if
                        end if
                    ! Source (addition): qs_pot < 0
                    elseif (qs_pot(iv,il) .lt. 0.0d0) then
                        if (vorz_s(iv,il,ih) .eq. -1) then
                            lueb_s(iv,il) = .true.
                            ! Cannot add more than |qs_pot|
                            if (senk(iv,il) .lt. qs_pot(iv,il)) then
                                rbchg = .true.
                                if (irblog .le. 75) then
                                    write(rblog(irblog+1:irblog+1), '(a)') 's'
                                    write(rblog(irblog+2:irblog+5), '(2i2)') iv, il
                                end if
                                irblog = irblog + 5
                                vorz_s(iv,il,ih) = 1
                                lueb_s(iv,il) = .false.
                            end if
                        elseif (vorz_s(iv,il,ih) .eq. 1) then
                            lueb_s(iv,il) = .false.
                            ! Cannot get wetter than ps_pot
                            if (phineu(iv,il) .gt. ps_pot(iv,il)) then
                                rbchg = .true.
                                if (irblog .le. 75) then
                                    write(rblog(irblog+1:irblog+1), '(a)') 'S'
                                    write(rblog(irblog+2:irblog+5), '(2i2)') iv, il
                                end if
                                irblog = irblog + 5
                                vorz_s(iv,il,ih) = -1
                                lueb_s(iv,il) = .true.
                            end if
                        end if
                    end if
                else
                    lueb_s(iv,il) = .false.
                end if

            end do
        end do

        return
    end subroutine chko_rb

    !===========================================================================
    ! SUBROUTINE: savevz
    !
    ! PURPOSE: Save boundary condition type flags for potential rollback
    !
    ! DESCRIPTION:
    !   Saves the current state of all BC type flags (vorz_*) to temporary
    !   storage arrays (vsav_*). This enables rollback if:
    !   - Convergence failure occurs
    !   - BC switching causes instability
    !   - Time step needs to be reduced and restarted
    !
    !   The vorz flags control which BC type is active:
    !   - vorz = +1: Neumann (flux) BC
    !   - vorz = -1: Dirichlet (potential) BC
    !
    !   These flags can change during time step execution via chko_rb.
    !   If the time step fails, loadvz restores the saved state.
    !
    !   Saved arrays:
    !   - vsav_u: bottom boundary (iacnl values)
    !   - vsav_o: top boundary (iacnl values)
    !   - vsav_r: right boundary (iacnv values)
    !   - vsav_l: left boundary (iacnv values)
    !   - vsav_s: interior sinks (iacnv × iacnl values)
    !
    ! ARGUMENTS:
    !   ih - Hillslope index [integer, input]
    !
    ! USES:
    !   boundary_conditions_module: vorz_*, vsav_*
    !   mesh_geometry_module: iacnv, iacnl
    !
    ! NOTES:
    !   - Must be called before attempting time step
    !   - Paired with loadvz for rollback
    !   - Essential for adaptive time stepping
    !===========================================================================
    subroutine savevz(ih)
        use boundary_conditions_module, only: vorz_u, vorz_o, vorz_r, vorz_l, vorz_s, &
                                               vsav_u, vsav_o, vsav_r, vsav_l, vsav_s
        use mesh_geometry_module, only: iacnv, iacnl
        implicit none

        integer(4), intent(in) :: ih

        integer(4) :: iv, il

        ! Save bottom and top boundary flags
        do il = 1, iacnl(ih)
            vsav_u(il) = vorz_u(il,ih)
            vsav_o(il) = vorz_o(il,ih)
        end do

        ! Save left and right boundary flags
        do iv = 1, iacnv(ih)
            vsav_r(iv) = vorz_r(iv,ih)
            vsav_l(iv) = vorz_l(iv,ih)
        end do

        ! Save interior sink/source flags
        do il = 1, iacnl(ih)
            do iv = 1, iacnv(ih)
                vsav_s(iv,il) = vorz_s(iv,il,ih)
            end do
        end do

        return
    end subroutine savevz

    !===========================================================================
    ! SUBROUTINE: loadvz
    !
    ! PURPOSE: Restore boundary condition type flags after failed attempt
    !
    ! DESCRIPTION:
    !   Restores BC type flags (vorz_*) from saved state (vsav_*). This is
    !   used when a time step attempt fails and must be retried with:
    !   - Smaller time step
    !   - Different solver parameters
    !   - Reset BC configuration
    !
    !   The restoration ensures that the BC state is consistent with the
    !   beginning of the time step, before any BC switching occurred.
    !
    !   Typical usage pattern:
    !   1. Call savevz before time step
    !   2. Attempt time step
    !   3. If failure: call loadvz to restore state
    !   4. Reduce time step and retry
    !
    !   Restored arrays:
    !   - vorz_u: bottom boundary (from vsav_u)
    !   - vorz_o: top boundary (from vsav_o)
    !   - vorz_r: right boundary (from vsav_r)
    !   - vorz_l: left boundary (from vsav_l)
    !   - vorz_s: interior sinks (from vsav_s)
    !
    ! ARGUMENTS:
    !   ih - Hillslope index [integer, input]
    !
    ! USES:
    !   boundary_conditions_module: vorz_*, vsav_*
    !   mesh_geometry_module: iacnv, iacnl
    !
    ! NOTES:
    !   - Must be paired with prior savevz call
    !   - Essential for robust time stepping
    !   - Prevents accumulation of BC state errors
    !===========================================================================
    subroutine loadvz(ih)
        use boundary_conditions_module, only: vorz_u, vorz_o, vorz_r, vorz_l, vorz_s, &
                                               vsav_u, vsav_o, vsav_r, vsav_l, vsav_s
        use mesh_geometry_module, only: iacnv, iacnl
        implicit none

        integer(4), intent(in) :: ih

        integer(4) :: iv, il

        ! Restore bottom and top boundary flags
        do il = 1, iacnl(ih)
            vorz_u(il,ih) = vsav_u(il)
            vorz_o(il,ih) = vsav_o(il)
        end do

        ! Restore left and right boundary flags
        do iv = 1, iacnv(ih)
            vorz_r(iv,ih) = vsav_r(iv)
            vorz_l(iv,ih) = vsav_l(iv)
        end do

        ! Restore interior sink/source flags
        do il = 1, iacnl(ih)
            do iv = 1, iacnv(ih)
                vorz_s(iv,il,ih) = vsav_s(iv,il)
            end do
        end do

        return
    end subroutine loadvz

end module addsteps_module
