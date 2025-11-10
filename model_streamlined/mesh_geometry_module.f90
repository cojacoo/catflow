!===============================================================================
! MODULE: mesh_geometry_module
!
! PURPOSE:
!   Grid geometry and mesh topology for CATFLOW Streamlined
!   Replaces COMMON blocks for coordinate transformations and mesh data
!
! DESCRIPTION:
!   This module contains all geometric information for the curvilinear mesh:
!
!   1. GRID DIMENSIONS
!      - iacnv:  Actual number of nodes in vertical (ξ) direction
!      - iacnl:  Actual number of nodes in lateral (η) direction
!      - iacnh:  Actual number of hillslopes
!      - iaccv:  Actual number of control volumes
!
!   2. COORDINATE TRANSFORMATION FACTORS
!      - f_xsi:  Metric coefficients for ξ coordinate [varies]
!      - f_eta:  Metric coefficients for η coordinate [varies]
!      - x_p1m1: Geometric factor for ξ stencil [m]
!      - e_p1m1: Geometric factor for η stencil [m]
!
!   3. GEOMETRIC PROPERTIES
!      - area:   Control volume area [m²]
!      - hko:    Surface elevation [m]
!
!   4. SOIL TYPE MAPPING
!      - iboden: Soil type index for each node [integer]
!      - hangnr: Hillslope number [integer]
!
!   5. MACROPORE PARAMETERS
!      - macro:  Macropore indicator [logical or integer]
!      - b_mac:  Macropore conductivity parameter [varies]
!
!   6. CONTROL VOLUME INDICES
!      - icvu, icvo, icvl, icvr: CV indices for boundaries
!      - ihgr:   Hillslope group indicator
!      - hgobfl: Hillslope surface area [m²]
!
! USAGE:
!   use mesh_geometry_module, only: iacnv, iacnl, area
!
!   ! In main program: allocate after reading grid dimensions
!   call allocate_mesh_geometry(nv, nl)
!
! NOTE: Arrays are ALLOCATABLE - must be allocated before use!
!
! ORIGINAL: GEOMET.inc, GITTER.inc (Fortran 77 COMMON blocks)
! AUTHOR: CATFLOW Streamlined
! DATE: 2025-11-10
!===============================================================================
module mesh_geometry_module
    implicit none

    ! =========================================================================
    ! GRID DIMENSIONS (scalars set at runtime)
    ! =========================================================================

    integer(4) :: iacnv          ! Actual number of vertical nodes
    integer(4) :: iacnl          ! Actual number of lateral nodes
    integer(4) :: iacnh          ! Actual number of hillslopes
    integer(4) :: iaccv          ! Actual number of control volumes

    ! =========================================================================
    ! COORDINATE TRANSFORMATION (2D arrays nv x nl)
    ! =========================================================================

    real(8), allocatable :: f_xsi(:,:)   ! Metric coefficient for ξ
    real(8), allocatable :: f_eta(:,:)   ! Metric coefficient for η
    real(8), allocatable :: x_p1m1(:,:)  ! ξ geometric factor [m]
    real(8), allocatable :: e_p1m1(:,:)  ! η geometric factor [m]

    ! =========================================================================
    ! GEOMETRIC PROPERTIES (2D arrays nv x nl)
    ! =========================================================================

    real(8), allocatable :: area(:,:)    ! Control volume area [m²]
    real(8), allocatable :: hko(:,:)     ! Surface elevation [m]

    ! =========================================================================
    ! SOIL TYPE AND HILLSLOPE MAPPING (2D integer arrays nv x nl)
    ! =========================================================================

    integer(4), allocatable :: iboden(:,:)  ! Soil type index
    integer(4), allocatable :: hangnr(:,:)  ! Hillslope number

    ! =========================================================================
    ! MACROPORE PARAMETERS (2D arrays nv x nl)
    ! =========================================================================

    integer(4), allocatable :: macro(:,:)   ! Macropore indicator
    real(8), allocatable :: b_mac(:,:)      ! Macropore conductivity

    ! =========================================================================
    ! BOUNDARY INDICES (1D arrays)
    ! =========================================================================

    integer(4), allocatable :: icvu(:)   ! Upper boundary CV indices
    integer(4), allocatable :: icvo(:)   ! Lower boundary CV indices
    integer(4), allocatable :: icvl(:)   ! Left boundary CV indices
    integer(4), allocatable :: icvr(:)   ! Right boundary CV indices

    ! =========================================================================
    ! HILLSLOPE INFORMATION
    ! =========================================================================

    integer(4) :: ihgr               ! Hillslope group indicator
    real(8), allocatable :: hgobfl(:)    ! Hillslope surface area [m²]

contains

    !===========================================================================
    ! SUBROUTINE: allocate_mesh_geometry
    !
    ! PURPOSE: Allocate all mesh geometry arrays
    !
    ! ARGUMENTS:
    !   nv - Number of nodes in vertical direction
    !   nl - Number of nodes in lateral direction
    !   nh - Number of hillslopes (optional, default 1)
    !===========================================================================
    subroutine allocate_mesh_geometry(nv, nl, nh)
        implicit none
        integer(4), intent(in) :: nv, nl
        integer(4), intent(in), optional :: nh
        integer(4) :: num_hills

        ! Set actual dimensions
        iacnv = nv
        iacnl = nl
        iacnh = 1
        if (present(nh)) iacnh = nh
        iaccv = nv * nl

        num_hills = iacnh

        ! Allocate 2D arrays
        allocate(f_xsi(nv, nl))
        allocate(f_eta(nv, nl))
        allocate(x_p1m1(nv, nl))
        allocate(e_p1m1(nv, nl))
        allocate(area(nv, nl))
        allocate(hko(nv, nl))
        allocate(iboden(nv, nl))
        allocate(hangnr(nv, nl))
        allocate(macro(nv, nl))
        allocate(b_mac(nv, nl))

        ! Allocate boundary index arrays
        allocate(icvu(nl))
        allocate(icvo(nl))
        allocate(icvl(nv))
        allocate(icvr(nv))

        ! Allocate hillslope arrays
        allocate(hgobfl(num_hills))

        ! Initialize to zero/default
        f_xsi  = 0.0d0
        f_eta  = 0.0d0
        x_p1m1 = 0.0d0
        e_p1m1 = 0.0d0
        area   = 0.0d0
        hko    = 0.0d0
        iboden = 1
        hangnr = 1
        macro  = 0
        b_mac  = 0.0d0
        icvu   = 0
        icvo   = 0
        icvl   = 0
        icvr   = 0
        ihgr   = 0
        hgobfl = 0.0d0

    end subroutine allocate_mesh_geometry

    !===========================================================================
    ! SUBROUTINE: deallocate_mesh_geometry
    !
    ! PURPOSE: Deallocate all mesh geometry arrays
    !===========================================================================
    subroutine deallocate_mesh_geometry()
        implicit none

        if (allocated(f_xsi))   deallocate(f_xsi)
        if (allocated(f_eta))   deallocate(f_eta)
        if (allocated(x_p1m1))  deallocate(x_p1m1)
        if (allocated(e_p1m1))  deallocate(e_p1m1)
        if (allocated(area))    deallocate(area)
        if (allocated(hko))     deallocate(hko)
        if (allocated(iboden))  deallocate(iboden)
        if (allocated(hangnr))  deallocate(hangnr)
        if (allocated(macro))   deallocate(macro)
        if (allocated(b_mac))   deallocate(b_mac)
        if (allocated(icvu))    deallocate(icvu)
        if (allocated(icvo))    deallocate(icvo)
        if (allocated(icvl))    deallocate(icvl)
        if (allocated(icvr))    deallocate(icvr)
        if (allocated(hgobfl))  deallocate(hgobfl)

    end subroutine deallocate_mesh_geometry

end module mesh_geometry_module
