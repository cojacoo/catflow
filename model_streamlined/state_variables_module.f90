!===============================================================================
! MODULE: state_variables_module
!
! PURPOSE:
!   Additional state variables (alias/extension of state_data_module)
!   Some physics files use this name instead of state_data_module
!
! NOTE: This module provides additional state variables not in state_data_module
!       Eventually this should be merged with state_data_module
!
! AUTHOR: CATFLOW Streamlined
! DATE: 2025-11-10
!===============================================================================
module state_variables_module
    implicit none

    ! Hydraulic state
    real(8), allocatable :: psi(:,:)         ! Pressure head (alias for phineu)
    real(8), allocatable :: phineu(:,:)      ! Pressure head
    real(8), allocatable :: phialt(:,:)      ! Old pressure head
    real(8), allocatable :: theta(:,:)       ! Moisture content
    real(8), allocatable :: th_alt(:,:)      ! Old moisture
    real(8), allocatable :: th_mit(:,:)      ! Midpoint moisture

    ! Hydraulic properties
    real(8), allocatable :: durchl(:,:)      ! Conductivity K
    real(8), allocatable :: wasska(:,:)      ! Water capacity C
    integer(4), allocatable :: tabpos(:,:)   ! Table position hint

    ! Fluxes
    real(8), allocatable :: q_xsi(:,:)       ! Flux in ξ direction
    real(8), allocatable :: q_eta(:,:)       ! Flux in η direction
    real(8), allocatable :: senk(:,:)        ! Sink/source term

    ! Surface water
    real(8), allocatable :: yoben(:,:)       ! Surface water depth

    ! Macropore
    integer(4), allocatable :: mak_an(:,:)   ! Macropore active flag

contains

    subroutine allocate_state_variables(nv, nl)
        integer(4), intent(in) :: nv, nl

        allocate(psi(nv, nl))
        allocate(phineu(nv, nl))
        allocate(phialt(nv, nl))
        allocate(theta(nv, nl))
        allocate(th_alt(nv, nl))
        allocate(th_mit(nv, nl))
        allocate(durchl(nv, nl))
        allocate(wasska(nv, nl))
        allocate(tabpos(nv, nl))
        allocate(q_xsi(nv, nl))
        allocate(q_eta(nv, nl))
        allocate(senk(nv, nl))
        allocate(yoben(nv, nl))
        allocate(mak_an(nv, nl))

        ! Initialize
        psi = 0.0d0
        phineu = 0.0d0
        phialt = 0.0d0
        theta = 0.0d0
        th_alt = 0.0d0
        th_mit = 0.0d0
        durchl = 1.0d-6
        wasska = 0.01d0
        tabpos = 1
        q_xsi = 0.0d0
        q_eta = 0.0d0
        senk = 0.0d0
        yoben = 0.0d0
        mak_an = 0
    end subroutine allocate_state_variables

end module state_variables_module
