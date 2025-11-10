!===============================================================================
! MODULE: time_module
!
! PURPOSE:
!   Time control and output scheduling for CATFLOW Streamlined
!
! AUTHOR: CATFLOW Streamlined
! DATE: 2025-11-10
!===============================================================================
module time_module
    use constants_module, only: maxnh, io
    implicit none

    ! Current time
    real(8) :: t_act                ! Current simulation time [s]
    real(8) :: t_neu                ! New time after step [s]

    ! Time stepping
    real(8) :: dt                   ! Time step [s]
    real(8) :: dt_min               ! Minimum time step [s]
    real(8) :: dt_max               ! Maximum time step [s]

    ! Print times
    real(8), allocatable :: t_p(:,:)    ! Print times array (it_p x nh)
    integer(4), allocatable :: ip(:)     ! Current print index per hillslope
    integer(4) :: it_p                   ! Total number of print times

    ! Date/time strings
    character(len=20) :: dstrs          ! Date string
    integer(4) :: itag                  ! Day of year
    integer(4) :: stunde                ! Hour of day

    ! Particle tracking time
    integer(4) :: istact                ! Active particle tracking flag

contains

    subroutine allocate_time_module(nh, nprint)
        integer(4), intent(in) :: nh, nprint

        it_p = nprint
        allocate(t_p(nprint, nh))
        allocate(ip(nh))

        t_p = 0.0d0
        ip = 1
        t_act = 0.0d0
        t_neu = 0.0d0
        dt = 1.0d0
        dt_min = 1.0d-6
        dt_max = 3600.0d0
        dstrs = ''
        itag = 1
        stunde = 0
        istact = 0
    end subroutine allocate_time_module

end module time_module
