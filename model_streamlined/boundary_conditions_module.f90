!===============================================================================
! MODULE: boundary_conditions_module
!
! PURPOSE:
!   Boundary condition arrays and parameters for CATFLOW Streamlined
!
! DESCRIPTION:
!   Contains BC type indicators, flux values, and control flags:
!   - irb_u, irb_o, irb_r, irb_l: BC types for each boundary
!   - rfl_u, rfl_o, rfl_r, rfl_l: BC flux/head values
!   - ueb_u, ueb_o, ueb_r, ueb_l: BC excess/overflow arrays
!   - vorz_u, vorz_o, vorz_r, vorz_l, vorz_s: BC sign indicators
!   - isnk: Sink/source type indicators
!   - isktyp: Sink type classification
!   - skpar: Sink parameters
!   - lland: Land surface flag
!   - lpob: Surface ponding flag
!
! ORIGINAL: RANDB.inc (Fortran 77 COMMON blocks)
! AUTHOR: CATFLOW Streamlined
! DATE: 2025-11-10
!===============================================================================
module boundary_conditions_module
    implicit none

    ! BC type arrays (nv or nl dimension)
    integer(4), allocatable :: irb_u(:)      ! Upper BC types
    integer(4), allocatable :: irb_o(:)      ! Lower BC types
    integer(4), allocatable :: irb_r(:)      ! Right BC types
    integer(4), allocatable :: irb_l(:)      ! Left BC types

    ! BC flux/head values
    real(8), allocatable :: rfl_u(:)         ! Upper BC values
    real(8), allocatable :: rfl_o(:)         ! Lower BC values
    real(8), allocatable :: rfl_r(:)         ! Right BC values
    real(8), allocatable :: rfl_l(:)         ! Left BC values

    ! BC excess arrays
    real(8), allocatable :: ueb_u(:)         ! Upper excess
    real(8), allocatable :: ueb_o(:)         ! Lower excess
    real(8), allocatable :: ueb_r(:)         ! Right excess
    real(8), allocatable :: ueb_l(:)         ! Left excess

    ! BC sign indicators
    real(8), allocatable :: vorz_u(:)        ! Upper sign
    real(8), allocatable :: vorz_o(:)        ! Lower sign
    real(8), allocatable :: vorz_r(:)        ! Right sign
    real(8), allocatable :: vorz_l(:)        ! Left sign
    real(8), allocatable :: vorz_s(:,:)      ! Sink sign (2D)

    ! Sink/source arrays
    integer(4), allocatable :: isnk(:,:)     ! Sink type (2D)
    integer(4), allocatable :: isktyp(:)     ! Sink type class
    real(8), allocatable :: skpar(:,:)       ! Sink parameters

    ! Control flags
    logical :: lland                         ! Land surface flag
    logical :: lpob                          ! Ponding flag

contains

    subroutine allocate_boundary_conditions(nv, nl)
        integer(4), intent(in) :: nv, nl

        ! Allocate boundary arrays
        allocate(irb_u(nl), irb_o(nl), irb_r(nv), irb_l(nv))
        allocate(rfl_u(nl), rfl_o(nl), rfl_r(nv), rfl_l(nv))
        allocate(ueb_u(nl), ueb_o(nl), ueb_r(nv), ueb_l(nv))
        allocate(vorz_u(nl), vorz_o(nl), vorz_r(nv), vorz_l(nv))
        allocate(vorz_s(nv, nl))
        allocate(isnk(nv, nl))
        allocate(isktyp(20))
        allocate(skpar(nv, nl))

        ! Initialize
        irb_u = 0; irb_o = 0; irb_r = 0; irb_l = 0
        rfl_u = 0.0d0; rfl_o = 0.0d0; rfl_r = 0.0d0; rfl_l = 0.0d0
        ueb_u = 0.0d0; ueb_o = 0.0d0; ueb_r = 0.0d0; ueb_l = 0.0d0
        vorz_u = 1.0d0; vorz_o = 1.0d0; vorz_r = 1.0d0; vorz_l = 1.0d0
        vorz_s = 1.0d0
        isnk = 0
        isktyp = 0
        skpar = 0.0d0
        lland = .false.
        lpob = .false.
    end subroutine allocate_boundary_conditions

    subroutine deallocate_boundary_conditions()
        if (allocated(irb_u))   deallocate(irb_u)
        if (allocated(irb_o))   deallocate(irb_o)
        if (allocated(irb_r))   deallocate(irb_r)
        if (allocated(irb_l))   deallocate(irb_l)
        if (allocated(rfl_u))   deallocate(rfl_u)
        if (allocated(rfl_o))   deallocate(rfl_o)
        if (allocated(rfl_r))   deallocate(rfl_r)
        if (allocated(rfl_l))   deallocate(rfl_l)
        if (allocated(ueb_u))   deallocate(ueb_u)
        if (allocated(ueb_o))   deallocate(ueb_o)
        if (allocated(ueb_r))   deallocate(ueb_r)
        if (allocated(ueb_l))   deallocate(ueb_l)
        if (allocated(vorz_u))  deallocate(vorz_u)
        if (allocated(vorz_o))  deallocate(vorz_o)
        if (allocated(vorz_r))  deallocate(vorz_r)
        if (allocated(vorz_l))  deallocate(vorz_l)
        if (allocated(vorz_s))  deallocate(vorz_s)
        if (allocated(isnk))    deallocate(isnk)
        if (allocated(isktyp))  deallocate(isktyp)
        if (allocated(skpar))   deallocate(skpar)
    end subroutine deallocate_boundary_conditions

end module boundary_conditions_module
