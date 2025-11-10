!===============================================================================
! FILE: additional_modules.f90
!
! PURPOSE:
!   Collection of small stub modules for dependencies
!   These are minimal implementations to satisfy module imports
!
! AUTHOR: CATFLOW Streamlined
! DATE: 2025-11-10
!===============================================================================

!===============================================================================
! MODULE: atmosphere_module
!===============================================================================
module atmosphere_module
    implicit none
    integer(4) :: neff                   ! Effective rainfall indicator
    real(8), allocatable :: Esoil(:,:)   ! Soil evaporation
    real(8), allocatable :: yoben(:,:)   ! Surface water depth
    real(8), allocatable :: nied(:,:)    ! Precipitation
    real(8), allocatable :: Eintz(:,:)   ! Interception evaporation
    real(8), allocatable :: Ecanop(:,:)  ! Canopy evaporation
contains
    subroutine allocate_atmosphere(nv, nl)
        integer(4), intent(in) :: nv, nl
        allocate(Esoil(nv, nl), yoben(nv, nl))
        allocate(nied(nv, nl), Eintz(nv, nl), Ecanop(nv, nl))
        Esoil = 0.0d0; yoben = 0.0d0; nied = 0.0d0
        Eintz = 0.0d0; Ecanop = 0.0d0; neff = 0
    end subroutine allocate_atmosphere
end module atmosphere_module

!===============================================================================
! MODULE: balance_module
!===============================================================================
module balance_module
    implicit none
    real(8) :: biltot, bilanz, bilin, bsenk, bilrd
    real(8) :: volin, volrd, vsenk, vsueb, vnied, vnied2
    real(8) :: vrfl_l, vrfl_r, vrfl_u, vrfl_o
    real(8) :: brfl_u, brfl_o, brfl_l, brfl_r
    real(8) :: qosum
contains
    subroutine init_balance_module()
        biltot = 0.0d0; bilanz = 0.0d0; bilin = 0.0d0
        bsenk = 0.0d0; bilrd = 0.0d0
        volin = 0.0d0; volrd = 0.0d0; vsenk = 0.0d0
        vsueb = 0.0d0; vnied = 0.0d0; vnied2 = 0.0d0
        vrfl_l = 0.0d0; vrfl_r = 0.0d0; vrfl_u = 0.0d0; vrfl_o = 0.0d0
        brfl_u = 0.0d0; brfl_o = 0.0d0; brfl_l = 0.0d0; brfl_r = 0.0d0
        qosum = 0.0d0
    end subroutine init_balance_module
end module balance_module

!===============================================================================
! MODULE: coefficient_module
!===============================================================================
module coefficient_module
    implicit none
    real(8), allocatable :: A_x(:,:), A_e(:,:)
    real(8), allocatable :: A2x(:,:), A2e(:,:)
contains
    subroutine allocate_coefficients(nv, nl)
        integer(4), intent(in) :: nv, nl
        allocate(A_x(nv, nl), A_e(nv, nl))
        allocate(A2x(nv, nl), A2e(nv, nl))
        A_x = 0.0d0; A_e = 0.0d0; A2x = 0.0d0; A2e = 0.0d0
    end subroutine allocate_coefficients
end module coefficient_module

!===============================================================================
! MODULE: control_module
!===============================================================================
module control_module
    implicit none
    real(8) :: d_Th_opt      ! Optimal theta change
    real(8) :: d_Phi_opt     ! Optimal phi change
contains
    subroutine init_control_module()
        d_Th_opt = 0.01d0
        d_Phi_opt = 0.1d0
    end subroutine init_control_module
end module control_module

!===============================================================================
! MODULE: diagnostics_module
!===============================================================================
module diagnostics_module
    implicit none
    real(8) :: fl_max, sk_max
    real(8) :: th_max, th_min, psi_max, psi_min
contains
    subroutine init_diagnostics_module()
        fl_max = 0.0d0; sk_max = 0.0d0
        th_max = 0.0d0; th_min = 1.0d0
        psi_max = 0.0d0; psi_min = -100.0d0
    end subroutine init_diagnostics_module
end module diagnostics_module

!===============================================================================
! MODULE: error_module
!===============================================================================
module error_module
    implicit none
    integer(4) :: maxtst         ! Maximum test counter
contains
    subroutine init_error_module()
        maxtst = 0
    end subroutine init_error_module
end module error_module

!===============================================================================
! MODULE: hillslope_data_module
!===============================================================================
module hillslope_data_module
    implicit none
    integer(4), allocatable :: hangnr(:,:)   ! Hillslope number
contains
    subroutine allocate_hillslope_data(nv, nl)
        integer(4), intent(in) :: nv, nl
        allocate(hangnr(nv, nl))
        hangnr = 1
    end subroutine allocate_hillslope_data
end module hillslope_data_module

!===============================================================================
! MODULE: io_module
!===============================================================================
module io_module
    use constants_module, only: io, io_log
    implicit none
    integer(4) :: iin        ! Input unit
    integer(4) :: io_act     ! Active I/O flag
contains
    subroutine init_io_module()
        iin = 5
        io_act = 1
    end subroutine init_io_module
    subroutine openi(unit, filename, status)
        integer(4), intent(in) :: unit
        character(len=*), intent(in) :: filename, status
        open(unit=unit, file=filename, status=status, action='read')
    end subroutine openi
end module io_module

!===============================================================================
! MODULE: particle_module
!===============================================================================
module particle_module
    implicit none
    integer(4) :: istact                     ! Active particles flag
    real(8), allocatable :: mlos_l(:), mlos_r(:), mlos_u(:)
    real(8), allocatable :: bm_l(:), bm_r(:), bm_u(:)
contains
    subroutine allocate_particle_module(n)
        integer(4), intent(in) :: n
        allocate(mlos_l(n), mlos_r(n), mlos_u(n))
        allocate(bm_l(n), bm_r(n), bm_u(n))
        mlos_l = 0.0d0; mlos_r = 0.0d0; mlos_u = 0.0d0
        bm_l = 0.0d0; bm_r = 0.0d0; bm_u = 0.0d0
        istact = 0
    end subroutine allocate_particle_module
end module particle_module

!===============================================================================
! MODULE: solute_transport_module
!===============================================================================
module solute_transport_module
    implicit none
    real(8), allocatable :: c_tact(:,:,:)    ! Concentration
    real(8), allocatable :: ve_st(:,:)       ! Velocity eta
    real(8), allocatable :: vx_st(:,:)       ! Velocity xsi
    real(8) :: mp_bil                        ! Mass balance
    integer(4) :: istact                     ! Active flag
contains
    subroutine allocate_solute_transport(nv, nl, nspec)
        integer(4), intent(in) :: nv, nl, nspec
        allocate(c_tact(nv, nl, nspec))
        allocate(ve_st(nv, nl), vx_st(nv, nl))
        c_tact = 0.0d0; ve_st = 0.0d0; vx_st = 0.0d0
        mp_bil = 0.0d0; istact = 0
    end subroutine allocate_solute_transport
end module solute_transport_module

!===============================================================================
! MODULE: stream_module
!===============================================================================
module stream_module
    implicit none
    real(8), allocatable :: y_bach(:), y_vorl(:)
    real(8) :: auint, inter
    integer(4), allocatable :: ihgb(:), hangnr(:,:)
contains
    subroutine allocate_stream_module(nh, nv, nl)
        integer(4), intent(in) :: nh, nv, nl
        allocate(y_bach(nh), y_vorl(nh), ihgb(nh))
        allocate(hangnr(nv, nl))
        y_bach = 0.0d0; y_vorl = 0.0d0
        auint = 0.0d0; inter = 0.0d0
        ihgb = 0; hangnr = 1
    end subroutine allocate_stream_module
end module stream_module

!===============================================================================
! MODULE: surface_module
!===============================================================================
module surface_module
    implicit none
    real(8), allocatable :: yoben(:,:)       ! Surface water depth
    real(8), allocatable :: yo_mit(:,:)      ! Midpoint surface water
contains
    subroutine allocate_surface_module(nv, nl)
        integer(4), intent(in) :: nv, nl
        allocate(yoben(nv, nl), yo_mit(nv, nl))
        yoben = 0.0d0; yo_mit = 0.0d0
    end subroutine allocate_surface_module
end module surface_module
