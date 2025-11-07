!===============================================================================
! MODULE: constants_module
!
! PURPOSE: Define all global constants and parameters for CATFLOW
!          Replaces dim.inc from original Fortran 77 code
!
! AUTHOR: Streamlined from CATFLOW original (Zehe et al.)
! DATE: 2025-11-06
!===============================================================================
module constants_module
    implicit none

    ! Make all constants public by default (can be made private selectively)
    public

    !---------------------------------------------------------------------------
    ! I/O AND FILE MANAGEMENT
    !---------------------------------------------------------------------------
    integer, parameter :: maxfil = 220      ! Max. number of control files
    integer, parameter :: maxin  = 8        ! Max. number of input files
    integer, parameter :: maxout = 20       ! Max. number of output files
    integer, parameter :: maxprt = 100000   ! Max. number of print-out times

    !---------------------------------------------------------------------------
    ! GRID DIMENSIONS
    !---------------------------------------------------------------------------
    integer, parameter :: maxnv  = 120      ! Max. number of soil layers (eta)
    integer, parameter :: maxnl  = 750      ! Max. number of soil columns (xsi)
    integer, parameter :: maxnh  = 1        ! Max. number of hillslopes
    integer, parameter :: maxnum = 1        ! Highest hillslope number (used as name)

    !---------------------------------------------------------------------------
    ! SOIL PROPERTIES
    !---------------------------------------------------------------------------
    integer, parameter :: maxtyp = 35       ! Max. number of soil types
    integer, parameter :: maxeig = 5        ! Max. number of soil properties (columns)
    integer, parameter :: maxero = 3        ! Max. number of erosion parameters
    integer, parameter :: maxpbm = 9        ! Max. number of soil hydraulic parameters
    integer, parameter :: maxtab = 1000     ! Max. length of soil table (rows)

    !---------------------------------------------------------------------------
    ! SURFACE AND VEGETATION
    !---------------------------------------------------------------------------
    integer, parameter :: maxfix = 3        ! Max. number of fixed integers per surface node
    integer, parameter :: maxwrf = 5        ! Max. number of wind direction factors
    integer, parameter :: maxhor = 36       ! Max. number of horizon angles
    integer, parameter :: maxuse = 20       ! Max. number of land uses
    integer, parameter :: maxpft = 25       ! Max. length of land-use time series
    integer, parameter :: maxpfp = 15       ! Max. number of land-use parameters

    !---------------------------------------------------------------------------
    ! CLIMATE AND FORCING
    !---------------------------------------------------------------------------
    integer, parameter :: maxnie = 6        ! Max. number of rainfall time series
    integer, parameter :: maxkli = 4        ! Max. number of climate time series
    integer, parameter :: maxkld = 6        ! Max. number of climate data columns

    !---------------------------------------------------------------------------
    ! BOUNDARY CONDITIONS AND SINKS/SOURCES
    !---------------------------------------------------------------------------
    integer, parameter :: maxrbf = 5        ! Max. number of BC time series
    integer, parameter :: maxsnk = 2        ! Max. number of sink/source time series
    integer, parameter :: maxrbp = 5        ! Max. number of BC parameters
    integer, parameter :: maxskp = 2        ! Max. number of sink/source parameters

    !---------------------------------------------------------------------------
    ! SIMULATION CONTROL
    !---------------------------------------------------------------------------
    integer, parameter :: maxgr  = 15       ! Max. number of time step classes
    integer, parameter :: maxcv  = 3        ! Max. number of control volumes

    !---------------------------------------------------------------------------
    ! DRAINAGE NETWORK
    !---------------------------------------------------------------------------
    integer, parameter :: maxnb  = 1        ! Max. number of drainage reaches
    integer, parameter :: maxit  = 1        ! Max. number of inflows (confluences)
    integer, parameter :: maxgng = 1        ! Max. number of output hydrographs
    integer, parameter :: maxbrf = 3        ! Max. number of boundary files for network

    !---------------------------------------------------------------------------
    ! OUTPUT
    !---------------------------------------------------------------------------
    integer, parameter :: maxpkt = 70       ! Max. number of soil moisture time series

    !---------------------------------------------------------------------------
    ! PARTICLE TRACKING
    !---------------------------------------------------------------------------
    integer, parameter :: npmax  = 25000    ! Max. number of particles (global)
    integer, parameter :: maxstt = 3        ! Max. number of solute types
    integer, parameter :: maxmif = 5        ! Max. number of mass inputs

    !---------------------------------------------------------------------------
    ! GLOBAL VARIABLES (replacements for COMMON blocks)
    !---------------------------------------------------------------------------

    ! Project-wide surface roughness (can be overridden)
    real(8), dimension(maxfil) :: kstall
    integer :: icf

    ! Iteration criteria
    integer :: it_max    ! Max. number of Picard iterations
    integer :: n_gr      ! Number of iteration classes
    real(8) :: piceps    ! Picard convergence tolerance
    real(8) :: cgeps     ! Conjugate gradient tolerance

    ! Switches for input reading
    logical, dimension(maxnh) :: lpob    ! True when surface attributes are read
    logical :: lland                      ! True when land use is considered

    ! I/O unit numbers
    integer :: ilok, ipar, inutz
    integer, dimension(maxout) :: io, io_log
    integer, dimension(maxin)  :: iin
    integer, dimension(maxkli) :: iikli
    integer, dimension(maxnie) :: iinie
    integer, dimension(maxsnk) :: iisnk
    integer, dimension(maxrbf) :: iirbf
    integer :: io_act, iin_act

    ! Min/max tracking for each hillslope
    real(8), dimension(maxnh) :: th_max, th_min      ! Soil moisture
    real(8), dimension(maxnh) :: psi_max, psi_min    ! Suction head
    real(8), dimension(maxnh) :: phi_max, phi_min    ! Total potential
    real(8), dimension(maxnh) :: fl_max, sk_max      ! Flux and sink/source

contains

    !===========================================================================
    ! SUBROUTINE: init_constants
    !
    ! PURPOSE: Initialize global variables (replaces initialization code
    !          scattered throughout original CATFLOW.f)
    !===========================================================================
    subroutine init_constants()
        implicit none

        ! Initialize counters
        icf = 0

        ! Initialize iteration parameters (will be overridden from input)
        it_max = 20
        n_gr = 10
        piceps = 1.0d-2
        cgeps = 1.0d-6

        ! Initialize switches
        lpob = .false.
        lland = .false.

        ! Initialize I/O units (will be assigned properly later)
        io = 0
        iin = 0
        iikli = 0
        iinie = 0
        iisnk = 0
        iirbf = 0
        io_log = 0
        io_act = 0
        iin_act = 0

        ! Initialize min/max trackers
        th_max = -huge(1.0d0)
        th_min = huge(1.0d0)
        psi_max = -huge(1.0d0)
        psi_min = huge(1.0d0)
        phi_max = -huge(1.0d0)
        phi_min = huge(1.0d0)
        fl_max = -huge(1.0d0)
        sk_max = -huge(1.0d0)

    end subroutine init_constants

    !===========================================================================
    ! FUNCTION: get_parameter_info
    !
    ! PURPOSE: Return information about dimensioning parameters (for debugging)
    !===========================================================================
    subroutine get_parameter_info()
        implicit none

        print *, '========================================='
        print *, 'CATFLOW STREAMLINED - DIMENSION PARAMETERS'
        print *, '========================================='
        print *, 'Grid dimensions:'
        print *, '  maxnv  (soil layers)      =', maxnv
        print *, '  maxnl  (soil columns)     =', maxnl
        print *, '  maxnh  (hillslopes)       =', maxnh
        print *, ''
        print *, 'Memory allocation estimate:'
        print *, '  State arrays (~nodes):    ', maxnv * maxnl * maxnh
        print *, '  Memory per real(8) array: ', maxnv * maxnl * 8 / 1024, 'KB'
        print *, ''
        print *, 'Particle tracking:'
        print *, '  npmax  (max particles)    =', npmax
        print *, '  maxstt (solute types)     =', maxstt
        print *, '========================================='

    end subroutine get_parameter_info

end module constants_module
