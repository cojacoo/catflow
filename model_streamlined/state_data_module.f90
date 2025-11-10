!===============================================================================
! MODULE: state_data_module
!
! PURPOSE:
!   Global state variables for CATFLOW Streamlined
!   Replaces COMMON blocks for pressure, moisture, fluxes, and coefficients
!
! DESCRIPTION:
!   This module contains all primary state variables and their derivatives:
!
!   1. PRESSURE HEAD STATE
!      - phineu:  New (current) pressure head ψ [m]
!      - phialt:  Old (previous) pressure head [m]
!
!   2. MOISTURE CONTENT STATE
!      - theta:   Current volumetric moisture content θ [m³/m³]
!      - th_alt:  Old moisture content [m³/m³]
!      - th_mit:  Midpoint moisture content [m³/m³]
!
!   3. FLUX ARRAYS
!      - Fx_00:   Flux coefficient at center node (ξ direction) [varies]
!      - Fx_p1:   Flux coefficient at ξ+1 neighbor [varies]
!      - Fx_m1:   Flux coefficient at ξ-1 neighbor [varies]
!      - Fe_00:   Flux coefficient at center node (η direction) [varies]
!      - Fe_p1:   Flux coefficient at η+1 neighbor [varies]
!      - Fe_m1:   Flux coefficient at η-1 neighbor [varies]
!
!   4. RIGHT-HAND SIDE
!      - RS:      Right-hand side vector for linear system [m/s]
!
!   5. FACTORS
!      - vorfak:  Precomputed factors for efficiency [varies]
!
! USAGE:
!   use state_data_module, only: phineu, theta
!
!   ! In main program: allocate after reading grid dimensions
!   call allocate_state_data(nv, nl)
!
! NOTE: Arrays are ALLOCATABLE - must be allocated before use!
!
! ORIGINAL: ZUST.inc, KOEFF.inc, PHI.inc (Fortran 77 COMMON blocks)
! AUTHOR: CATFLOW Streamlined
! DATE: 2025-11-10
!===============================================================================
module state_data_module
    implicit none

    ! =========================================================================
    ! STATE VARIABLES (2D arrays dimensioned nv x nl)
    ! =========================================================================

    ! Pressure head [m]
    real(8), allocatable :: phineu(:,:)  ! Current pressure head ψ
    real(8), allocatable :: phialt(:,:)  ! Old pressure head

    ! Moisture content [m³/m³]
    real(8), allocatable :: theta(:,:)   ! Current moisture content θ
    real(8), allocatable :: th_alt(:,:)  ! Old moisture content
    real(8), allocatable :: th_mit(:,:)  ! Midpoint moisture content

    ! =========================================================================
    ! FLUX COEFFICIENTS (2D arrays dimensioned nv x nl)
    ! =========================================================================
    ! These are the discretized flux terms in the finite difference equations
    ! Format: F{x,e}_{position} where position is m1(-1), 00(0), p1(+1)

    ! ξ (vertical) direction fluxes
    real(8), allocatable :: Fx_00(:,:)   ! Center node ξ flux
    real(8), allocatable :: Fx_p1(:,:)   ! ξ+1 neighbor flux
    real(8), allocatable :: Fx_m1(:,:)   ! ξ-1 neighbor flux

    ! η (lateral) direction fluxes
    real(8), allocatable :: Fe_00(:,:)   ! Center node η flux
    real(8), allocatable :: Fe_p1(:,:)   ! η+1 neighbor flux
    real(8), allocatable :: Fe_m1(:,:)   ! η-1 neighbor flux

    ! =========================================================================
    ! LINEAR SYSTEM ARRAYS
    ! =========================================================================

    real(8), allocatable :: RS(:,:)      ! Right-hand side [m/s]
    real(8), allocatable :: vorfak(:,:)  ! Precomputed factors

contains

    !===========================================================================
    ! SUBROUTINE: allocate_state_data
    !
    ! PURPOSE: Allocate all state variable arrays
    !
    ! ARGUMENTS:
    !   nv - Number of nodes in vertical direction
    !   nl - Number of nodes in lateral direction
    !===========================================================================
    subroutine allocate_state_data(nv, nl)
        implicit none
        integer(4), intent(in) :: nv, nl

        ! Allocate pressure and moisture
        allocate(phineu(nv, nl))
        allocate(phialt(nv, nl))
        allocate(theta(nv, nl))
        allocate(th_alt(nv, nl))
        allocate(th_mit(nv, nl))

        ! Allocate flux coefficients
        allocate(Fx_00(nv, nl))
        allocate(Fx_p1(nv, nl))
        allocate(Fx_m1(nv, nl))
        allocate(Fe_00(nv, nl))
        allocate(Fe_p1(nv, nl))
        allocate(Fe_m1(nv, nl))

        ! Allocate system arrays
        allocate(RS(nv, nl))
        allocate(vorfak(nv, nl))

        ! Initialize to zero
        phineu = 0.0d0
        phialt = 0.0d0
        theta  = 0.0d0
        th_alt = 0.0d0
        th_mit = 0.0d0
        Fx_00  = 0.0d0
        Fx_p1  = 0.0d0
        Fx_m1  = 0.0d0
        Fe_00  = 0.0d0
        Fe_p1  = 0.0d0
        Fe_m1  = 0.0d0
        RS     = 0.0d0
        vorfak = 0.0d0

    end subroutine allocate_state_data

    !===========================================================================
    ! SUBROUTINE: deallocate_state_data
    !
    ! PURPOSE: Deallocate all state variable arrays
    !===========================================================================
    subroutine deallocate_state_data()
        implicit none

        if (allocated(phineu)) deallocate(phineu)
        if (allocated(phialt)) deallocate(phialt)
        if (allocated(theta))  deallocate(theta)
        if (allocated(th_alt)) deallocate(th_alt)
        if (allocated(th_mit)) deallocate(th_mit)
        if (allocated(Fx_00))  deallocate(Fx_00)
        if (allocated(Fx_p1))  deallocate(Fx_p1)
        if (allocated(Fx_m1))  deallocate(Fx_m1)
        if (allocated(Fe_00))  deallocate(Fe_00)
        if (allocated(Fe_p1))  deallocate(Fe_p1)
        if (allocated(Fe_m1))  deallocate(Fe_m1)
        if (allocated(RS))     deallocate(RS)
        if (allocated(vorfak)) deallocate(vorfak)

    end subroutine deallocate_state_data

end module state_data_module
