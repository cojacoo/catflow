!===============================================================================
! MODULE: hg_opera_module
!
! PURPOSE:
!   Array operations for hillslope grids in CATFLOW
!   Essential utility routines for solution vector manipulation
!   Modernized version of HG_OPERA.f using Fortran 90 modules
!
! DESCRIPTION:
!   Provides fundamental array operations on 2D hillslope grids. These
!   operations are used extensively throughout CATFLOW solvers for:
!
!   - State variable copying (save/restore during time stepping)
!   - Work array initialization (zero out before use)
!   - Solution updates (add corrections to current state)
!   - Intermediate calculations (temporary storage)
!
!   All operations work on the active portion of hillslope arrays,
!   respecting the actual grid dimensions iacnv(ih) × iacnl(ih).
!
!   ARRAY STRUCTURE:
!   ===============
!
!   Hillslope arrays in CATFLOW use fixed allocation with variable extent:
!
!   Declared size: (maxnv, maxnl, maxnh)
!   - maxnv: Maximum nodes in eta (vertical) direction
!   - maxnl: Maximum nodes in xsi (horizontal) direction
!   - maxnh: Maximum number of hillslopes
!
!   Active size for hillslope ih: (iacnv(ih), iacnl(ih))
!   - iacnv(ih): Actual nodes in eta direction for hillslope ih
!   - iacnl(ih): Actual nodes in xsi direction for hillslope ih
!
!   Operations only touch the active portion to:
!   - Avoid unnecessary computation
!   - Maintain locality of reference (cache efficiency)
!   - Prevent contamination of unused array space
!
!   MEMORY LAYOUT:
!   =============
!
!   Fortran uses column-major ordering:
!   A(i,j,k) is stored contiguously in i first, then j, then k
!
!   For hillslope arrays:
!   - Inner loop over il (xsi) for cache efficiency
!   - Outer loop over iv (eta)
!   - Hillslope dimension ih usually fixed in calling context
!
!   Access pattern for optimal cache performance:
!   do iv = 1, iacnv(ih)
!       do il = 1, iacnl(ih)
!           A(iv,il) = ...
!       end do
!   end do
!
!   NUMERICAL PRECISION:
!   ===================
!
!   All operations use real(8) (double precision):
!   - 64-bit IEEE 754 floating point
!   - ~16 decimal digits of precision
!   - Essential for iterative solver convergence
!
!   No round-off mitigation needed for these operations since:
!   - Copy: exact reproduction
!   - Zero: no arithmetic involved
!   - Add: single operation (no accumulation error)
!
!   PERFORMANCE CONSIDERATIONS:
!   ==========================
!
!   These are called MANY times per time step:
!   - hgcopy: ~10-20 calls per step (state management)
!   - hgnull: ~5-10 calls per step (work array init)
!   - hgadd: ~5-10 calls per Picard iteration
!
!   Optimization strategies:
!   - Explicit loop bounds (no function calls in loops)
!   - Contiguous memory access (column-major)
!   - No branching inside loops
!   - Compiler-friendly patterns (vectorizable)
!
!   Typical array sizes:
!   - Small: 20×50 = 1,000 nodes
!   - Medium: 50×100 = 5,000 nodes
!   - Large: 100×200 = 20,000 nodes
!
!   Operation counts per call:
!   - hgcopy: n_nodes assignments (~8 bytes/node)
!   - hgnull: n_nodes assignments
!   - hgadd: 2*n_nodes operations (read + add + write)
!
! PUBLIC SUBROUTINES:
!   hgcopy - Copy 2D array (source → destination)
!   hgnull - Zero out 2D array
!   hgadd  - Add two 2D arrays element-wise
!
! EXTERNAL DEPENDENCIES:
!   mesh_geometry_module: iacnv, iacnl (active grid dimensions)
!   constants_module: maxnv, maxnl (array dimensions)
!
! USAGE PATTERNS:
!
!   State save/restore:
!   call hgcopy(phineu, phialt(1,1,ih), ih)  ! Save new to old
!   call hgcopy(phialt(1,1,ih), phineu, ih)  ! Restore old to new
!
!   Work array initialization:
!   call hgnull(dPhi, ih)  ! Zero correction before CG solve
!
!   Solution update:
!   call hgadd(phineu, dPhi, ih)  ! phineu += dPhi (Picard update)
!
! VALIDATION REQUIREMENTS:
!
!   1. Correctness:
!      - hgcopy: Verify A_out(i,j) = A_in(i,j) for all active (i,j)
!      - hgnull: Verify A(i,j) = 0.0 for all active (i,j)
!      - hgadd: Verify C(i,j) = A(i,j) + B(i,j) for all active (i,j)
!
!   2. Bounds respect:
!      - Verify operations only touch 1:iacnv(ih), 1:iacnl(ih)
!      - Check no out-of-bounds access for edge cases
!
!   3. Precision preservation:
!      - hgcopy: Check bit-exact reproduction
!      - hgadd: Verify no unexpected round-off
!
!   4. Performance:
!      - Profile memory bandwidth utilization
!      - Check vectorization (compiler reports)
!      - Benchmark against hand-coded alternatives
!
!   5. Integration:
!      - Run full simulation and verify correct state evolution
!      - Check solution reproducibility across runs
!
! PHYSICS PRESERVATION:
!   ALL operations preserved EXACTLY from original HG_OPERA.f:
!   - Loop ordering (iv outer, il inner)
!   - Array indexing conventions
!   - Active region determination
!   - No algorithmic changes whatsoever
!
! ORIGINAL: HG_OPERA.f (Fortran 77 with includes)
! AUTHOR: CATFLOW Streamlined
! DATE: 2025-11-09
!===============================================================================
module hg_opera_module
    use constants_module, only: maxnv, maxnl
    implicit none
    private

    ! Make all array operation subroutines public
    public :: hgcopy
    public :: hgnull
    public :: hgadd

contains

    !===========================================================================
    ! SUBROUTINE: hgcopy
    !
    ! PURPOSE: Copy 2D hillslope array (source → destination)
    !
    ! DESCRIPTION:
    !   Copies the active portion of a 2D array from source (A_in) to
    !   destination (A_out). Used extensively for:
    !
    !   - Saving current state before time step
    !   - Restoring previous state after convergence failure
    !   - Creating working copies for solvers
    !   - Intermediate storage in iterative methods
    !
    !   The copy is performed element-by-element:
    !   A_out(iv,il) = A_in(iv,il)
    !   for all iv ∈ [1,iacnv(ih)], il ∈ [1,iacnl(ih)]
    !
    !   Only the active grid region is copied. The rest of the allocated
    !   array (from maxnv×maxnl) remains unchanged.
    !
    !   CRITICAL: This operation must be bit-exact. No transformations,
    !   no approximations. Essential for:
    !   - Time step rollback (exact state restoration)
    !   - Iterative solver convergence (precise residual calculation)
    !   - Mass balance preservation (no round-off accumulation)
    !
    !   Loop ordering (iv outer, il inner) follows Fortran column-major
    !   storage for cache efficiency, though both orderings would give
    !   identical results for this simple operation.
    !
    ! ARGUMENTS:
    !   A_in  - Source array [real(8)(maxnv,maxnl), input]
    !   A_out - Destination array [real(8)(maxnv,maxnl), output]
    !   ih    - Hillslope index [integer(4), input]
    !
    ! USES:
    !   mesh_geometry_module: iacnv, iacnl
    !
    ! NOTES:
    !   - Arrays can overlap in memory (same variable) - this is valid
    !   - No temporary storage needed
    !   - Compiler may optimize to memcpy() for contiguous sections
    !   - Preserves ALL bits (exact copy, not numerical approximation)
    !===========================================================================
    subroutine hgcopy(A_in, A_out, ih)
        use mesh_geometry_module, only: iacnv, iacnl
        implicit none

        real(8),    intent(in)  :: A_in(maxnv, maxnl)
        real(8),    intent(out) :: A_out(maxnv, maxnl)
        integer(4), intent(in)  :: ih

        integer(4) :: iv, il

        ! Copy active region of array
        do iv = 1, iacnv(ih)
            do il = 1, iacnl(ih)
                A_out(iv,il) = A_in(iv,il)
            end do
        end do

        return
    end subroutine hgcopy

    !===========================================================================
    ! SUBROUTINE: hgnull
    !
    ! PURPOSE: Zero out 2D hillslope array
    !
    ! DESCRIPTION:
    !   Sets all elements in the active portion of a 2D array to zero:
    !   A(iv,il) = 0.0
    !   for all iv ∈ [1,iacnv(ih)], il ∈ [1,iacnl(ih)]
    !
    !   Used for:
    !   - Initializing work arrays before solver iterations
    !   - Clearing correction vectors (dPhi) before CG solve
    !   - Resetting accumulator arrays
    !   - Preparing temporary storage
    !
    !   Why explicit zero assignment (not implicit initialization):
    !   - Arrays are reused across time steps
    !   - Automatic arrays may contain garbage
    !   - Explicit zeroing ensures clean state
    !   - Helps catch bugs (uninitialized variable use)
    !
    !   The zero constant 0.0d0 is:
    !   - Exact representation in floating point
    !   - No round-off error
    !   - Bit pattern: all zeros in IEEE 754
    !
    !   Performance note:
    !   Modern compilers may optimize this to:
    !   - SIMD vector instructions (set multiple elements)
    !   - memset() call for contiguous regions
    !   - Zero-page copy on some architectures
    !
    ! ARGUMENTS:
    !   A  - Array to zero [real(8)(maxnv,maxnl), output]
    !   ih - Hillslope index [integer(4), input]
    !
    ! USES:
    !   mesh_geometry_module: iacnv, iacnl
    !
    ! NOTES:
    !   - Only active region is zeroed
    !   - Rest of allocated array unchanged
    !   - Safe to call multiple times (idempotent)
    !   - No dependencies on previous array contents
    !===========================================================================
    subroutine hgnull(A, ih)
        use mesh_geometry_module, only: iacnv, iacnl
        implicit none

        real(8),    intent(out) :: A(maxnv, maxnl)
        integer(4), intent(in)  :: ih

        integer(4) :: iv, il

        ! Zero active region of array
        do iv = 1, iacnv(ih)
            do il = 1, iacnl(ih)
                A(iv,il) = 0.0d0
            end do
        end do

        return
    end subroutine hgnull

    !===========================================================================
    ! SUBROUTINE: hgadd
    !
    ! PURPOSE: Add two 2D hillslope arrays element-wise
    !
    ! DESCRIPTION:
    !   Adds array B to array A element by element:
    !   A(iv,il) = A(iv,il) + B(iv,il)
    !   for all iv ∈ [1,iacnv(ih)], il ∈ [1,iacnl(ih)]
    !
    !   This is the in-place accumulation operation. The first argument
    !   (A) is both input and output - it is modified by adding B to it.
    !
    !   Used primarily for:
    !   - Picard iteration updates: φ_new = φ_old + Δφ
    !   - Incremental solution corrections
    !   - Accumulating contributions from multiple sources
    !   - Conjugate gradient solution updates
    !
    !   Mathematical operation:
    !   A ← A + B  (in-place addition)
    !
    !   Equivalent to:
    !   for each element: A[i] = A[i] + B[i]
    !
    !   Round-off considerations:
    !   - Single addition per element (minimal error)
    !   - No catastrophic cancellation (adding same-sign terms)
    !   - Order of operations fixed (deterministic)
    !   - Double precision ensures adequate accuracy
    !
    !   For large correction sequences (many Picard iterations), small
    !   errors can accumulate. However, the Picard convergence criterion
    !   (‖Δφ‖ < ε) ensures corrections become negligible before error
    !   accumulation becomes significant.
    !
    !   Cache efficiency:
    !   - Two array reads + one write per element
    !   - Sequential access pattern (good spatial locality)
    !   - Compiler may fuse loads/stores
    !   - Potential for SIMD vectorization
    !
    ! ARGUMENTS:
    !   A  - Accumulator array [real(8)(maxnv,maxnl), inout]
    !        Input: current values
    !        Output: current + B
    !   B  - Array to add [real(8)(maxnv,maxnl), input]
    !   ih - Hillslope index [integer(4), input]
    !
    ! USES:
    !   mesh_geometry_module: iacnv, iacnl
    !
    ! NOTES:
    !   - First argument is modified (in-place operation)
    !   - Second argument is unchanged
    !   - Arrays must have same logical dimensions
    !   - No check for overflow (assumed physical values)
    !   - Commutative: A+B = B+A, but order matters for round-off
    !===========================================================================
    subroutine hgadd(A, B, ih)
        use mesh_geometry_module, only: iacnv, iacnl
        implicit none

        real(8),    intent(inout) :: A(maxnv, maxnl)
        real(8),    intent(in)    :: B(maxnv, maxnl)
        integer(4), intent(in)    :: ih

        integer(4) :: iv, il

        ! Add B to A element-wise over active region
        do iv = 1, iacnv(ih)
            do il = 1, iacnl(ih)
                A(iv,il) = A(iv,il) + B(iv,il)
            end do
        end do

        return
    end subroutine hgadd

end module hg_opera_module
