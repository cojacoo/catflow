!===============================================================================
! MODULE: time_module
!
! PURPOSE:
!   Time management and time stepping for CATFLOW
!   Replaces zeit.inc with modern Fortran 90 module
!
! DESCRIPTION:
!   Contains all time-related variables including:
!   - Simulation time bounds and current time
!   - Time step controls (min, max, actual)
!   - Output time management
!   - Time step statistics and histograms
!   - Date/time string representations
!
! AUTHOR: CATFLOW Streamlined
! DATE: 2025-11-07
!
! REPLACES: zeit.inc (54 lines with COMMON blocks)
!===============================================================================
module time_module
    use constants_module, only: maxnh, maxprt, maxgr
    implicit none
    private

    ! =========================================================================
    ! PUBLIC INTERFACE
    ! =========================================================================
    public :: allocate_time
    public :: deallocate_time
    public :: get_time_info

    ! Time bounds and current time
    public :: t_start, t_end, t_alt, t_neu, t_act

    ! Time step control
    public :: dt_exp, dt_min, dt_max, dtbach, dt_mak

    ! Date/time
    public :: itag, stunde
    public :: dstrs, dstre, dstrs2

    ! Output control
    public :: t_p, ip, it_p

    ! Time step counter
    public :: izaehl

    ! Time step statistics
    public :: clgr, cltim, class, iacgr

    ! =========================================================================
    ! TIME BOUNDS AND CURRENT TIME
    ! =========================================================================
    real(8) :: t_start   ! Global starting point in time [s]
    real(8) :: t_end     ! Global end point in time [s]
    real(8) :: t_alt     ! Local starting point in time [s]
    real(8) :: t_neu     ! Local end point in time [s]
    real(8) :: t_act     ! Actual simulation point in time [s]

    ! =========================================================================
    ! TIME STEP CONTROL
    ! =========================================================================
    real(8) :: dt_exp    ! Maximum explicit time step [s]
    real(8) :: dt_min    ! Global minimum time step [s]
    real(8) :: dt_max    ! Global maximum time step [s]
    real(8) :: dtbach    ! Maximum timestep for active drainage network [s]
    real(8) :: dt_mak    ! Maximum timestep for active macropore flow [s]

    ! =========================================================================
    ! DATE AND TIME OF DAY
    ! =========================================================================
    real(8) :: itag      ! Day number in year (1-365/366)
    real(8) :: stunde    ! Hour of day (0-24)

    ! =========================================================================
    ! DATE STRINGS
    ! =========================================================================
    character(22) :: dstrs   ! Start time string
    character(22) :: dstre   ! End time string
    character(22) :: dstrs2  ! Alternative start time string

    ! =========================================================================
    ! OUTPUT CONTROL
    ! =========================================================================
    ! Output times for each hillslope and print event
    real(8), allocatable :: t_p(:,:)        ! (maxprt, maxnh)

    ! Counter for print events
    integer(4), allocatable :: ip(:)        ! (maxnh)

    ! Switch for output control
    integer(4), allocatable :: it_p(:,:)    ! (maxprt, maxnh)

    ! =========================================================================
    ! TIME STEP COUNTER
    ! =========================================================================
    integer(4), allocatable :: izaehl(:)    ! (maxnh) Time step counter

    ! =========================================================================
    ! TIME STEP STATISTICS
    ! =========================================================================
    ! Boundaries between classes of time step length [s]
    real(8), allocatable :: clgr(:)         ! (maxgr)

    ! Cumulative time within each time step class [s]
    real(8), allocatable :: cltim(:)        ! (maxgr+1)

    ! Cumulative number of timesteps within each class
    integer(4), allocatable :: class(:)     ! (maxgr+1)

    ! Actual number of time step class boundaries
    integer(4) :: iacgr

contains

    !===========================================================================
    ! SUBROUTINE: allocate_time
    !
    ! PURPOSE: Allocate time management arrays
    !===========================================================================
    subroutine allocate_time()
        implicit none
        integer :: stat

        ! Output control
        allocate(t_p(maxprt,maxnh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate t_p'

        allocate(ip(maxnh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate ip'

        allocate(it_p(maxprt,maxnh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate it_p'

        ! Time step counter
        allocate(izaehl(maxnh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate izaehl'

        ! Time step statistics
        allocate(clgr(maxgr), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate clgr'

        allocate(cltim(maxgr+1), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate cltim'

        allocate(class(maxgr+1), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate class'

        ! Initialize scalar variables
        t_start = 0.0d0
        t_end = 0.0d0
        t_alt = 0.0d0
        t_neu = 0.0d0
        t_act = 0.0d0

        dt_exp = 0.0d0
        dt_min = 0.0d0
        dt_max = 0.0d0
        dtbach = 0.0d0
        dt_mak = 0.0d0

        itag = 1.0d0
        stunde = 0.0d0

        dstrs = ''
        dstre = ''
        dstrs2 = ''

        ! Initialize arrays
        t_p = 0.0d0
        ip = 0
        it_p = 0
        izaehl = 0

        clgr = 0.0d0
        cltim = 0.0d0
        class = 0
        iacgr = 0

    end subroutine allocate_time

    !===========================================================================
    ! SUBROUTINE: deallocate_time
    !
    ! PURPOSE: Deallocate time management arrays
    !===========================================================================
    subroutine deallocate_time()
        implicit none

        if (allocated(t_p)) deallocate(t_p)
        if (allocated(ip)) deallocate(ip)
        if (allocated(it_p)) deallocate(it_p)
        if (allocated(izaehl)) deallocate(izaehl)
        if (allocated(clgr)) deallocate(clgr)
        if (allocated(cltim)) deallocate(cltim)
        if (allocated(class)) deallocate(class)

    end subroutine deallocate_time

    !===========================================================================
    ! SUBROUTINE: get_time_info
    !
    ! PURPOSE: Print current time information
    !===========================================================================
    subroutine get_time_info()
        implicit none
        real(8) :: elapsed, remaining, progress

        print *, ''
        print *, '==================================================='
        print *, 'TIME MODULE INFORMATION'
        print *, '==================================================='
        print *, ''

        print *, 'Simulation time bounds:'
        print *, '  Start time: ', t_start, ' s'
        print *, '  End time:   ', t_end, ' s'
        print *, '  Duration:   ', t_end - t_start, ' s'
        print *, ''

        if (t_act > 0.0d0) then
            elapsed = t_act - t_start
            remaining = t_end - t_act
            if ((t_end - t_start) > 0.0d0) then
                progress = 100.0d0 * elapsed / (t_end - t_start)
            else
                progress = 0.0d0
            end if

            print *, 'Current simulation time:'
            print *, '  Current:  ', t_act, ' s'
            print *, '  Elapsed:  ', elapsed, ' s'
            print *, '  Remaining:', remaining, ' s'
            print *, '  Progress: ', progress, ' %'
            print *, ''
        end if

        print *, 'Time step controls:'
        print *, '  dt_min: ', dt_min, ' s'
        print *, '  dt_max: ', dt_max, ' s'
        if (dt_exp > 0.0d0) print *, '  dt_exp: ', dt_exp, ' s'
        if (dtbach > 0.0d0) print *, '  dt_bach:', dtbach, ' s (drainage)'
        if (dt_mak > 0.0d0) print *, '  dt_mak: ', dt_mak, ' s (macropore)'
        print *, ''

        if (allocated(izaehl)) then
            print *, 'Time step counters:'
            print *, '  Hillslope 1: ', izaehl(1), ' steps'
        end if

        if (iacgr > 0) then
            print *, ''
            print *, 'Time step statistics:'
            print *, '  Number of classes: ', iacgr
        end if

        print *, ''
        print *, '==================================================='
        print *, ''

    end subroutine get_time_info

end module time_module
