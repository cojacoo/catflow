!===============================================================================
! MODULE: dcg_module
!
! PURPOSE:
!   Conjugate Gradient solver for Richards equation in CATFLOW
!   Diagonal preconditioned CG for sparse linear systems
!   Modernized version of DCG.f using Fortran 90 modules
!
! DESCRIPTION:
!   Implements preconditioned conjugate gradient (PCG) solver for the
!   linearized Richards equation. The system arises from finite difference
!   discretization and has the structure:
!
!   A·φ = RS
!
!   where:
!   - A is the sparse coefficient matrix (5-point stencil in 2D)
!   - φ is the unknown pressure head field
!   - RS is the right-hand side (residual from Picard iteration)
!
!   The matrix A is stored in coefficient form (not assembled):
!   A·φ = Fx_00·φ(i,j) + Fx_p1·φ(i,j+1) + Fx_m1·φ(i,j-1)
!       + Fe_00·φ(i,j) + Fe_p1·φ(i+1,j) + Fe_m1·φ(i-1,j)
!
!   CONJUGATE GRADIENT ALGORITHM:
!   ============================
!
!   Given: A·x = b, initial guess x₀, tolerance ε
!
!   1. Initialization:
!      r₀ = b - A·x₀         (initial residual)
!      z₀ = M⁻¹·r₀           (apply preconditioner)
!      p₀ = z₀               (initial search direction)
!      ρ₀ = ⟨r₀,z₀⟩          (initial inner product)
!
!   2. Iteration loop (k = 0, 1, 2, ...):
!      a. Compute matrix-vector product:
!         q = A·pₖ
!
!      b. Calculate step length:
!         α = ρₖ / ⟨pₖ,q⟩
!
!      c. Update solution and residual:
!         xₖ₊₁ = xₖ + α·pₖ
!         rₖ₊₁ = rₖ - α·q
!
!      d. Check convergence:
!         if ‖rₖ₊₁‖ < ε: STOP
!
!      e. Apply preconditioner:
!         zₖ₊₁ = M⁻¹·rₖ₊₁
!
!      f. Calculate new inner product:
!         ρₖ₊₁ = ⟨rₖ₊₁,zₖ₊₁⟩
!
!      g. Calculate conjugacy parameter:
!         β = ρₖ₊₁ / ρₖ
!
!      h. Update search direction:
!         pₖ₊₁ = zₖ₊₁ + β·pₖ
!
!   PRECONDITIONING:
!   ===============
!
!   Diagonal (Jacobi) preconditioner:
!   M⁻¹ = diag(A)⁻¹
!
!   For Richards equation, the diagonal is:
!   A_ii = Fx_00(i,j) + Fe_00(i,j) - 1
!
!   Preconditioning transformation:
!   z = M⁻¹·r  ⟺  z(i,j) = r(i,j) / A_ii
!
!   This significantly improves convergence for ill-conditioned systems
!   (e.g., layered soils, large conductivity contrasts).
!
!   CONVERGENCE CRITERION:
!   =====================
!
!   The solver monitors the L² norm of the residual:
!   ‖r‖₂ = √(Σᵢⱼ rᵢⱼ²)
!
!   Convergence is achieved when:
!   ‖rₖ‖₂ / ‖r₀‖₂ < ε  (relative residual)
!
!   or equivalently:
!   ‖rₖ‖₂² < ε²·‖r₀‖₂²
!
!   Typical tolerance: ε = 10⁻⁶ to 10⁻⁸
!
!   NUMERICAL STABILITY:
!   ===================
!
!   Critical considerations:
!
!   1. Orthogonality maintenance:
!      - Conjugate directions pₖ must remain A-orthogonal
!      - Finite precision arithmetic causes loss of orthogonality
!      - Maximum iterations typically limited to n_nodes/2
!
!   2. Breakdown conditions:
!      - ⟨pₖ,q⟩ ≈ 0: Search direction orthogonal to gradient (rare for SPD)
!      - ρₖ < 0: Preconditioner not positive definite (should not occur)
!      - Division by zero protection essential
!
!   3. Preconditioning effectiveness:
!      - Diagonal must be positive (ensured by Richards FD scheme)
!      - Condition number reduction: κ(M⁻¹A) < κ(A)
!      - Convergence rate: O(√κ) iterations
!
!   4. Residual accumulation:
!      - Computed residual rₖ₊₁ = rₖ - α·q can drift from true residual
!      - Consider periodic recalculation: r = b - A·x
!
!   PERFORMANCE CHARACTERISTICS:
!   ===========================
!
!   Complexity per iteration:
!   - Matrix-vector product: O(5·n_nodes) (5-point stencil)
!   - Inner products: O(n_nodes)
!   - Vector updates: O(n_nodes)
!   - Total: O(n_nodes) per iteration
!
!   Typical iteration counts:
!   - Well-conditioned: 10-50 iterations
!   - Ill-conditioned: 100-500 iterations
!   - Strong nonlinearity: 500+ iterations (reduce dt)
!
!   Memory requirements:
!   - Work arrays: 5 × n_nodes × 8 bytes (p, q, r, z, diagonal)
!   - Coefficient storage: already allocated in state_data_module
!
! PUBLIC SUBROUTINES:
!   cg_solv - Main conjugate gradient solver
!
! EXTERNAL DEPENDENCIES:
!   state_data_module: Fx_*, Fe_*, RS (coefficient matrices)
!   mesh_geometry_module: iacnv, iacnl (grid dimensions)
!   constants_module: maxnv, maxnl (array dimensions)
!
! VALIDATION REQUIREMENTS:
!
!   1. Convergence test:
!      - Run on known problems with analytical solutions
!      - Verify ‖x_cg - x_exact‖ < tolerance
!      - Test various mesh sizes and anisotropies
!
!   2. Preconditioning effectiveness:
!      - Compare iteration counts with/without preconditioner
!      - Expect 2-10× reduction in iterations
!      - Monitor condition number estimates
!
!   3. Stability test:
!      - Run to high iteration counts (>1000)
!      - Check orthogonality loss: ⟨pᵢ,A·pⱼ⟩ for i≠j
!      - Verify residual monotonicity
!
!   4. Performance benchmark:
!      - Time matrix-vector products separately
!      - Profile inner products and vector ops
!      - Compare with direct solvers for small problems
!
!   5. Integration test:
!      - Run full Richards simulation
!      - Verify mass balance closure
!      - Check solution smoothness
!      - Compare with ADI solver results
!
! PHYSICS PRESERVATION:
!   ALL numerical algorithms preserved EXACTLY from original DCG.f:
!   - CG iteration structure
!   - Inner product calculations
!   - Search direction updates
!   - Convergence checking
!   - Preconditioning application
!   - Matrix-vector product implementation
!
! ORIGINAL: DCG.f (Fortran 77 with includes)
! AUTHOR: CATFLOW Streamlined
! DATE: 2025-11-09
!===============================================================================
module dcg_module
    use constants_module, only: maxnv, maxnl
    implicit none
    private

    ! Make CG solver public
    public :: cg_solv

contains

    !===========================================================================
    ! SUBROUTINE: cg_solv
    !
    ! PURPOSE: Preconditioned conjugate gradient solver for linear systems
    !
    ! DESCRIPTION:
    !   Solves the linear system A·φ = RS arising from linearized Richards
    !   equation using the preconditioned conjugate gradient method.
    !
    !   The coefficient matrix A is stored in stencil form:
    !   - Fx_00, Fx_p1, Fx_m1: xsi direction coefficients
    !   - Fe_00, Fe_p1, Fe_m1: eta direction coefficients
    !
    !   Matrix-vector product (A·p):
    !   (A·p)(i,j) = p(i,j)·(Fx_00(i,j) + Fe_00(i,j) - 1)
    !              + p(i,j+1)·Fx_p1(i,j)
    !              + p(i,j-1)·Fx_m1(i,j)
    !              + p(i+1,j)·Fe_p1(i,j)
    !              + p(i-1,j)·Fe_m1(i,j)
    !
    !   Diagonal preconditioner:
    !   diag(i,j) = Fx_00(i,j) + Fe_00(i,j) - 1
    !   z = M⁻¹·r  means  z(i,j) = r(i,j) / diag(i,j)
    !
    !   Algorithm:
    !   1. Calculate initial residual: r = RS - A·φ
    !   2. Precondition: z = M⁻¹·r
    !   3. Initialize search direction: p = z
    !   4. Loop until convergence:
    !      a) q = A·p  (matrix-vector product)
    !      b) α = ⟨r,z⟩ / ⟨p,q⟩  (step length)
    !      c) φ += α·p  (update solution)
    !      d) r -= α·q  (update residual)
    !      e) Check ‖r‖² < ε²  (convergence)
    !      f) z = M⁻¹·r  (precondition new residual)
    !      g) β = ⟨r_new,z_new⟩ / ⟨r_old,z_old⟩  (conjugacy)
    !      h) p = z + β·p  (update search direction)
    !
    !   Convergence is based on L² norm of residual:
    !   ‖r‖² = Σᵢⱼ r(i,j)²
    !
    !   The solver returns when ‖r‖² < eps² or n_cg >= maxcg.
    !
    ! ARGUMENTS:
    !   ih      - Hillslope index [integer(4), input]
    !   Phi     - Solution vector (φ) [real(8)(maxnv,maxnl), inout]
    !             Input: initial guess (typically 0)
    !             Output: converged solution
    !   rsq     - Residual squared norm [real(8), output]
    !   n_cg    - Number of CG iterations performed [integer(4), output]
    !   eps     - Convergence tolerance [real(8), input]
    !
    ! USES:
    !   state_data_module: Fx_00, Fx_p1, Fx_m1, Fe_00, Fe_p1, Fe_m1, RS
    !   mesh_geometry_module: iacnv, iacnl
    !
    ! NOTES:
    !   - Maximum iterations: 200 (hardcoded, can be made parameter)
    !   - Diagonal must be non-zero (always true for Richards equation)
    !   - Work arrays p, q, r, z are local (automatic storage)
    !   - Preserves EXACT algorithm from original DCG.f
    !===========================================================================
    subroutine cg_solv(ih, Phi, rsq, n_cg, eps)
        use state_data_module, only: Fx_00, Fx_p1, Fx_m1, Fe_00, Fe_p1, Fe_m1, RS
        use mesh_geometry_module, only: iacnv, iacnl
        implicit none

        integer(4), intent(in)    :: ih
        real(8),    intent(inout) :: Phi(maxnv, maxnl)
        real(8),    intent(out)   :: rsq
        integer(4), intent(out)   :: n_cg
        real(8),    intent(in)    :: eps

        ! Work arrays
        real(8) :: p(maxnv, maxnl)    ! Search direction
        real(8) :: q(maxnv, maxnl)    ! A·p (matrix-vector product)
        real(8) :: r(maxnv, maxnl)    ! Residual
        real(8) :: z(maxnv, maxnl)    ! Preconditioned residual
        real(8) :: diag(maxnv, maxnl) ! Diagonal preconditioner

        ! Scalars
        real(8) :: rho, rho_old, alpha, beta, pq
        real(8) :: eps2, rsq0
        integer(4) :: iv, il
        integer(4), parameter :: maxcg = 200

        intrinsic :: abs

        ! Initialize iteration counter
        n_cg = 0

        ! Calculate diagonal preconditioner
        ! diag = Fx_00 + Fe_00 - 1 (diagonal of A)
        do iv = 1, iacnv(ih)
            do il = 1, iacnl(ih)
                diag(iv,il) = Fx_00(iv,il) + Fe_00(iv,il) - 1.0d0
                ! Protect against zero diagonal (should not occur for Richards)
                if (abs(diag(iv,il)) .lt. 1.0d-20) diag(iv,il) = 1.0d0
            end do
        end do

        ! Calculate initial residual: r = RS - A·Phi
        ! First: r = RS
        do iv = 1, iacnv(ih)
            do il = 1, iacnl(ih)
                r(iv,il) = RS(iv,il)
            end do
        end do

        ! Subtract A·Phi from r
        ! Diagonal contribution
        do iv = 1, iacnv(ih)
            do il = 1, iacnl(ih)
                r(iv,il) = r(iv,il) - Phi(iv,il) * diag(iv,il)
            end do
        end do

        ! Xsi direction off-diagonal contributions
        do iv = 1, iacnv(ih)
            ! Forward xsi (il+1)
            do il = 1, iacnl(ih) - 1
                r(iv,il) = r(iv,il) - Phi(iv,il+1) * Fx_p1(iv,il)
            end do
            ! Backward xsi (il-1)
            do il = 2, iacnl(ih)
                r(iv,il) = r(iv,il) - Phi(iv,il-1) * Fx_m1(iv,il)
            end do
        end do

        ! Eta direction off-diagonal contributions
        do il = 1, iacnl(ih)
            ! Forward eta (iv+1)
            do iv = 1, iacnv(ih) - 1
                r(iv,il) = r(iv,il) - Phi(iv+1,il) * Fe_p1(iv,il)
            end do
            ! Backward eta (iv-1)
            do iv = 2, iacnv(ih)
                r(iv,il) = r(iv,il) - Phi(iv-1,il) * Fe_m1(iv,il)
            end do
        end do

        ! Calculate initial residual norm squared
        rsq0 = 0.0d0
        do iv = 1, iacnv(ih)
            do il = 1, iacnl(ih)
                rsq0 = rsq0 + r(iv,il) * r(iv,il)
            end do
        end do

        ! Convergence threshold
        eps2 = eps * eps * rsq0
        rsq = rsq0

        ! Check if already converged
        if (rsq .lt. eps2) then
            n_cg = 0
            return
        end if

        ! Apply preconditioner: z = M⁻¹·r
        do iv = 1, iacnv(ih)
            do il = 1, iacnl(ih)
                z(iv,il) = r(iv,il) / diag(iv,il)
            end do
        end do

        ! Initialize search direction: p = z
        do iv = 1, iacnv(ih)
            do il = 1, iacnl(ih)
                p(iv,il) = z(iv,il)
            end do
        end do

        ! Calculate initial inner product: rho = ⟨r,z⟩
        rho = 0.0d0
        do iv = 1, iacnv(ih)
            do il = 1, iacnl(ih)
                rho = rho + r(iv,il) * z(iv,il)
            end do
        end do

        !-----------------------------------------------------------------------
        ! Main CG iteration loop
        !-----------------------------------------------------------------------
        do n_cg = 1, maxcg

            !-------------------------------------------------------------------
            ! Matrix-vector product: q = A·p
            !-------------------------------------------------------------------

            ! Diagonal contribution
            do iv = 1, iacnv(ih)
                do il = 1, iacnl(ih)
                    q(iv,il) = p(iv,il) * diag(iv,il)
                end do
            end do

            ! Xsi direction off-diagonal contributions
            do iv = 1, iacnv(ih)
                ! Forward xsi (il+1)
                do il = 1, iacnl(ih) - 1
                    q(iv,il) = q(iv,il) + p(iv,il+1) * Fx_p1(iv,il)
                end do
                ! Backward xsi (il-1)
                do il = 2, iacnl(ih)
                    q(iv,il) = q(iv,il) + p(iv,il-1) * Fx_m1(iv,il)
                end do
            end do

            ! Eta direction off-diagonal contributions
            do il = 1, iacnl(ih)
                ! Forward eta (iv+1)
                do iv = 1, iacnv(ih) - 1
                    q(iv,il) = q(iv,il) + p(iv+1,il) * Fe_p1(iv,il)
                end do
                ! Backward eta (iv-1)
                do iv = 2, iacnv(ih)
                    q(iv,il) = q(iv,il) + p(iv-1,il) * Fe_m1(iv,il)
                end do
            end do

            !-------------------------------------------------------------------
            ! Calculate step length: alpha = rho / ⟨p,q⟩
            !-------------------------------------------------------------------
            pq = 0.0d0
            do iv = 1, iacnv(ih)
                do il = 1, iacnl(ih)
                    pq = pq + p(iv,il) * q(iv,il)
                end do
            end do

            ! Protect against division by zero (should not occur for SPD matrix)
            if (abs(pq) .lt. 1.0d-30) then
                ! CG breakdown - return with current solution
                return
            end if

            alpha = rho / pq

            !-------------------------------------------------------------------
            ! Update solution and residual
            !-------------------------------------------------------------------
            do iv = 1, iacnv(ih)
                do il = 1, iacnl(ih)
                    Phi(iv,il) = Phi(iv,il) + alpha * p(iv,il)
                    r(iv,il) = r(iv,il) - alpha * q(iv,il)
                end do
            end do

            !-------------------------------------------------------------------
            ! Check convergence: ‖r‖² < eps²
            !-------------------------------------------------------------------
            rsq = 0.0d0
            do iv = 1, iacnv(ih)
                do il = 1, iacnl(ih)
                    rsq = rsq + r(iv,il) * r(iv,il)
                end do
            end do

            if (rsq .lt. eps2) then
                ! Converged!
                return
            end if

            !-------------------------------------------------------------------
            ! Apply preconditioner to new residual: z = M⁻¹·r
            !-------------------------------------------------------------------
            do iv = 1, iacnv(ih)
                do il = 1, iacnl(ih)
                    z(iv,il) = r(iv,il) / diag(iv,il)
                end do
            end do

            !-------------------------------------------------------------------
            ! Calculate new inner product and conjugacy parameter
            !-------------------------------------------------------------------
            rho_old = rho
            rho = 0.0d0
            do iv = 1, iacnv(ih)
                do il = 1, iacnl(ih)
                    rho = rho + r(iv,il) * z(iv,il)
                end do
            end do

            beta = rho / rho_old

            !-------------------------------------------------------------------
            ! Update search direction: p = z + beta·p
            !-------------------------------------------------------------------
            do iv = 1, iacnv(ih)
                do il = 1, iacnl(ih)
                    p(iv,il) = z(iv,il) + beta * p(iv,il)
                end do
            end do

        end do
        !-----------------------------------------------------------------------
        ! End of CG iteration loop
        !-----------------------------------------------------------------------

        ! Maximum iterations reached - return with current solution
        return

    end subroutine cg_solv

end module dcg_module
