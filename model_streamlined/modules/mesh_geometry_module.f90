!===============================================================================
! MODULE: mesh_geometry_module
!
! PURPOSE:
!   Mesh geometry and coordinate transformation data for CATFLOW
!   Replaces hgfest.inc with modern Fortran 90 module
!
! DESCRIPTION:
!   Contains all mesh-related data including:
!   - Curvilinear coordinate system (xsi, eta)
!   - Metric coefficients for coordinate transformations
!   - Grid spacing and node positions
!   - Anisotropy tensors
!   - Slope angles and orientations
!   - Control volumes for mass balance
!   - Macropore distribution
!
! AUTHOR: CATFLOW Streamlined
! DATE: 2025-11-07
!
! REPLACES: hgfest.inc (259 lines with COMMON blocks)
!===============================================================================
module mesh_geometry_module
    use constants_module, only: maxnv, maxnl, maxnh, maxcv, maxnum
    implicit none
    private  ! Make everything private by default

    ! =========================================================================
    ! PUBLIC INTERFACE
    ! =========================================================================
    public :: allocate_mesh
    public :: deallocate_mesh
    public :: get_mesh_info

    ! Geographic location
    public :: rlongi, longi, lati

    ! Curvilinear coordinates
    public :: xsi, eta, x_p1m0, x_p1m1, e_p1m0, e_p1m1

    ! Cartesian coordinates
    public :: xko, yko, hko, sko
    public :: xkobez, ykobez, hkobez

    ! Metric coefficients
    public :: f_xsi, f_eta, fmf, fdf

    ! Grid spacing
    public :: dr_o, dr_u, dr_l, dr_r, drxsi, dreta
    public :: lrd_o, lrd_u, lrd_l, lrd_r

    ! Anisotropy tensors
    public :: kxx, kee, kxe, kxxf, keef, kxef
    public :: w_hohr, w_xshr, w_xsho, w_xshol
    public :: m_aniso

    ! Slopes and angles
    public :: slopeo, slopeu, sloper, slopel
    public :: gefall, azimut

    ! Areas and volumes
    public :: area, alla, vola, flaeche
    public :: hgobfl, hgbreit, hglang

    ! Variable width
    public :: varbr, fbrup, fbrlow

    ! Soil type indices
    public :: iboden

    ! Conductivity averaging methods
    public :: mm_xsi, mm_eta

    ! Averaging factors
    public :: av_fak, al_fak

    ! Depth below surface
    public :: depth

    ! Macropore data
    public :: lmak, macro, amak, b_mac, ivm

    ! Variability factors
    public :: rel_ks, rel_ths

    ! Polygon vertices
    public :: hloe, hroe, hrue, hlue
    public :: sloe, sroe, srue, slue
    public :: hmo, hmr, hmu, hml
    public :: smo, smr, smu, sml

    ! Control volumes
    public :: icvo, icvu, icvl, icvr, iaccv

    ! Hillslope identifiers
    public :: hangnr, hgih, ihgr
    public :: iacnh, iacnv, iacnl

    ! Channel parameters
    public :: lambda, igewkn

    ! Optimization parameters
    public :: d_Th_opt, d_Phi_opt

    ! Area factors
    public :: fcabf, fabf

    ! Visualization method
    public :: vimet

    ! Minimum elevation
    public :: hkomin

    ! =========================================================================
    ! GEOGRAPHIC LOCATION
    ! =========================================================================
    real(8) :: rlongi  ! Reference longitude of time zone (CET: 15° E)
    real(8) :: longi   ! Longitude of catchment
    real(8) :: lati    ! Latitude of catchment

    ! =========================================================================
    ! CURVILINEAR COORDINATES
    ! =========================================================================
    ! xsi-coordinate (longitudinal, along hillslope)
    real(8), allocatable :: xsi(:,:)            ! (maxnl, maxnh)
    real(8), allocatable :: x_p1m0(:,:)         ! xsi(il+1)-xsi(il)
    real(8), allocatable :: x_p1m1(:,:)         ! xsi(il+1)-xsi(il-1)

    ! eta-coordinate (vertical, depth)
    real(8), allocatable :: eta(:,:)            ! (maxnv, maxnh)
    real(8), allocatable :: e_p1m0(:,:)         ! eta(iv+1)-eta(iv)
    real(8), allocatable :: e_p1m1(:,:)         ! eta(iv+1)-eta(iv-1)

    ! =========================================================================
    ! CARTESIAN COORDINATES
    ! =========================================================================
    ! Global horizontal coordinates [m]
    real(8), allocatable :: xko(:)              ! (maxnl) "Rechtswert"
    real(8), allocatable :: yko(:)              ! (maxnl) "Hochwert"
    real(8), allocatable :: xkobez(:)           ! (maxnh) Reference x
    real(8), allocatable :: ykobez(:)           ! (maxnh) Reference y

    ! Hillslope coordinates [m]
    real(8), allocatable :: hko(:,:,:)          ! (maxnv,maxnl,maxnh) Elevation
    real(8), allocatable :: sko(:,:,:)          ! (maxnv,maxnl,maxnh) Lateral
    real(8), allocatable :: hkobez(:)           ! (maxnh) Reference elevation
    real(8), allocatable :: hkomin(:)           ! (maxnh) Minimum elevation

    ! =========================================================================
    ! METRIC COEFFICIENTS (coordinate transformation)
    ! =========================================================================
    real(8), allocatable :: f_xsi(:,:,:)        ! (maxnv,maxnl,maxnh)
    real(8), allocatable :: f_eta(:,:,:)        ! (maxnv,maxnl,maxnh)
    real(8) :: fmf                               ! Metric factor
    real(8) :: fdf                               ! Diffusion factor

    ! =========================================================================
    ! GRID SPACING [m]
    ! =========================================================================
    ! Spacing along boundaries
    real(8), allocatable :: dr_o(:,:)           ! (maxnl,maxnh) Top boundary
    real(8), allocatable :: dr_u(:,:)           ! (maxnl,maxnh) Bottom boundary
    real(8), allocatable :: dr_l(:,:)           ! (maxnv,maxnh) Left boundary
    real(8), allocatable :: dr_r(:,:)           ! (maxnv,maxnh) Right boundary

    ! Spacing within domain
    real(8), allocatable :: drxsi(:,:,:)        ! (maxnv,maxnl,maxnh) Longitudinal
    real(8), allocatable :: dreta(:,:,:)        ! (maxnv,maxnl,maxnh) Vertical

    ! Total boundary lengths [m]
    real(8), allocatable :: lrd_o(:)            ! (maxnh) Top
    real(8), allocatable :: lrd_u(:)            ! (maxnh) Bottom
    real(8), allocatable :: lrd_l(:)            ! (maxnh) Left
    real(8), allocatable :: lrd_r(:)            ! (maxnh) Right

    ! =========================================================================
    ! ANISOTROPY TENSORS (normalized with k_s)
    ! =========================================================================
    real(8), allocatable :: kxx(:,:,:)          ! (maxnv,maxnl,maxnh) xx-component
    real(8), allocatable :: kee(:,:,:)          ! (maxnv,maxnl,maxnh) ee-component
    real(8), allocatable :: kxe(:,:,:)          ! (maxnv,maxnl,maxnh) xe-component
    real(8), allocatable :: kxxf(:,:,:)         ! (maxnv,maxnl,maxnh) Flux variant
    real(8), allocatable :: keef(:,:,:)         ! (maxnv,maxnl,maxnh) Flux variant
    real(8), allocatable :: kxef(:,:,:)         ! (maxnv,maxnl,maxnh) Flux variant

    ! Angles [radians, positive counterclockwise]
    real(8), allocatable :: w_xshr(:,:)         ! (maxnv,maxnl) xsi to anisotropy
    real(8), allocatable :: w_xsho(:,:)         ! (maxnv,maxnl) xsi to horizontal
    real(8), allocatable :: w_xshol(:,:,:)      ! (maxnv,maxnl,maxnh) xsi to horizontal (hillslope)
    real(8), allocatable :: w_hohr(:,:)         ! (maxnv,maxnl) horizontal to anisotropy

    integer(4) :: m_aniso                        ! Anisotropy method flag

    ! =========================================================================
    ! SLOPES AND ORIENTATIONS
    ! =========================================================================
    ! Cosine of angle between surface and horizontal
    real(8), allocatable :: slopeo(:,:)         ! (maxnl,maxnh) Top
    real(8), allocatable :: slopeu(:,:)         ! (maxnl,maxnh) Bottom
    real(8), allocatable :: sloper(:,:)         ! (maxnv,maxnh) Right
    real(8), allocatable :: slopel(:,:)         ! (maxnv,maxnh) Left

    ! Tangent of angle between surface and horizontal
    real(8), allocatable :: gefall(:,:)         ! (maxnl,maxnh) Surface gradient

    ! Azimuth (orientation clockwise from north) [radians]
    real(8), allocatable :: azimut(:,:)         ! (maxnl,maxnh)

    ! =========================================================================
    ! AREAS AND VOLUMES
    ! =========================================================================
    real(8), allocatable :: area(:,:,:)         ! (maxnv,maxnl,maxnh) Element area [m²]
    real(8), allocatable :: flaeche(:,:,:)      ! (maxnv,maxnl,maxnh) Related area
    real(8), allocatable :: alla(:,:)           ! (maxcv,maxnh) CV longitudinal area [m²]
    real(8), allocatable :: vola(:,:)           ! (maxcv,maxnh) CV volume [m³]

    ! Hillslope dimensions
    real(8), allocatable :: hgobfl(:)           ! (maxnh) Total surface area [m²]
    real(8), allocatable :: hgbreit(:)          ! (maxnh) Mean width [m]
    real(8), allocatable :: hglang(:)           ! (maxnh) Length [m]

    ! =========================================================================
    ! VARIABLE WIDTH
    ! =========================================================================
    real(8), allocatable :: varbr(:,:)          ! (maxnl,maxnh) Variable width [m]
    real(8), allocatable :: fbrup(:,:)          ! (maxnl,maxnh) Width factor upper
    real(8), allocatable :: fbrlow(:,:)         ! (maxnl,maxnh) Width factor lower

    ! =========================================================================
    ! SOIL TYPE INDICES
    ! =========================================================================
    integer(4), allocatable :: iboden(:,:,:)    ! (maxnv,maxnl,maxnh) Soil type index

    ! =========================================================================
    ! CONDUCTIVITY AVERAGING METHODS
    ! =========================================================================
    integer(4), allocatable :: mm_xsi(:,:,:)    ! (maxnv,maxnl-1,maxnh) Longitudinal
    integer(4), allocatable :: mm_eta(:,:,:)    ! (maxnv-1,maxnl,maxnh) Vertical

    ! =========================================================================
    ! AVERAGING FACTORS
    ! =========================================================================
    real(8), allocatable :: av_fak(:,:,:)       ! (maxnv-1,maxnl,maxnh) Vertical
    real(8), allocatable :: al_fak(:,:,:)       ! (maxnv,maxnl-1,maxnh) Longitudinal

    ! =========================================================================
    ! DEPTH BELOW SURFACE
    ! =========================================================================
    real(8), allocatable :: depth(:,:,:)        ! (maxnv,maxnl,maxnh) [m]

    ! =========================================================================
    ! MACROPORE DATA
    ! =========================================================================
    logical, allocatable :: lmak(:)             ! (maxnh) Macropore info available?
    real(8), allocatable :: macro(:,:,:)        ! (maxnv,maxnl,maxnh) Macropore factor
    real(8), allocatable :: amak(:,:,:)         ! (maxnv,maxnl,maxnh) Macropore parameter
    real(8), allocatable :: b_mac(:,:,:)        ! (maxnv,maxnl,maxnh) Macropore exponent
    integer(4), allocatable :: ivm(:,:)         ! (maxnl,maxnh) Deepest macroporous element

    ! =========================================================================
    ! VARIABILITY FACTORS (statistical)
    ! =========================================================================
    real(8), allocatable :: rel_ks(:,:,:)       ! (maxnv,maxnl,maxnh) k_s variability
    real(8), allocatable :: rel_ths(:,:,:)      ! (maxnv,maxnl,maxnh) porosity variability

    ! =========================================================================
    ! POLYGON VERTICES [m]
    ! =========================================================================
    ! Lateral coordinates of polygon vertices
    real(8), allocatable :: sloe(:,:,:)         ! (maxnv,maxnl,maxnh) Upper left
    real(8), allocatable :: sroe(:,:,:)         ! (maxnv,maxnl,maxnh) Upper right
    real(8), allocatable :: srue(:,:,:)         ! (maxnv,maxnl,maxnh) Lower right
    real(8), allocatable :: slue(:,:,:)         ! (maxnv,maxnl,maxnh) Lower left
    real(8), allocatable :: smo(:,:,:)          ! (maxnv,maxnl,maxnh) Center top
    real(8), allocatable :: smr(:,:,:)          ! (maxnv,maxnl,maxnh) Center right
    real(8), allocatable :: smu(:,:,:)          ! (maxnv,maxnl,maxnh) Center bottom
    real(8), allocatable :: sml(:,:,:)          ! (maxnv,maxnl,maxnh) Center left

    ! Vertical coordinates of polygon vertices [m above reference]
    real(8), allocatable :: hloe(:,:,:)         ! (maxnv,maxnl,maxnh) Upper left
    real(8), allocatable :: hroe(:,:,:)         ! (maxnv,maxnl,maxnh) Upper right
    real(8), allocatable :: hrue(:,:,:)         ! (maxnv,maxnl,maxnh) Lower right
    real(8), allocatable :: hlue(:,:,:)         ! (maxnv,maxnl,maxnh) Lower left
    real(8), allocatable :: hmo(:,:,:)          ! (maxnv,maxnl,maxnh) Center top
    real(8), allocatable :: hmr(:,:,:)          ! (maxnv,maxnl,maxnh) Center right
    real(8), allocatable :: hmu(:,:,:)          ! (maxnv,maxnl,maxnh) Center bottom
    real(8), allocatable :: hml(:,:,:)          ! (maxnv,maxnl,maxnh) Center left

    ! =========================================================================
    ! CONTROL VOLUMES (for mass balance)
    ! =========================================================================
    integer(4), allocatable :: icvo(:,:)        ! (maxcv,maxnh) Top corner indices
    integer(4), allocatable :: icvu(:,:)        ! (maxcv,maxnh) Bottom corner indices
    integer(4), allocatable :: icvl(:,:)        ! (maxcv,maxnh) Left corner indices
    integer(4), allocatable :: icvr(:,:)        ! (maxcv,maxnh) Right corner indices
    integer(4), allocatable :: iaccv(:)         ! (maxnh) Active CV count

    ! =========================================================================
    ! HILLSLOPE IDENTIFIERS
    ! =========================================================================
    integer(4), allocatable :: hangnr(:)        ! (maxnh) Hillslope numbers (names)
    integer(4), allocatable :: hgih(:)          ! (maxnum) Position of hillslope numbers
    integer(4) :: ihgr                           ! Grid identifier
    integer(4) :: iacnh                          ! Active hillslopes count
    integer(4), allocatable :: iacnv(:)         ! (maxnh) Active nodes in eta direction
    integer(4), allocatable :: iacnl(:)         ! (maxnh) Active nodes in xsi direction

    ! =========================================================================
    ! CHANNEL PARAMETERS
    ! =========================================================================
    real(8), allocatable :: lambda(:)           ! (maxnh) Leakage parameter k'/d' [1/s]
    integer(4), allocatable :: igewkn(:,:)      ! (2,maxnh) Channel reach indices

    ! =========================================================================
    ! OPTIMIZATION PARAMETERS
    ! =========================================================================
    real(8) :: d_Th_opt                          ! Theta optimization step
    real(8) :: d_Phi_opt                         ! Phi optimization step

    ! =========================================================================
    ! AREA FACTORS
    ! =========================================================================
    real(8), allocatable :: fcabf(:)            ! (maxnh) Catchment area factor
    real(8), allocatable :: fabf(:)             ! (maxnh) Hillslope area factor

    ! =========================================================================
    ! VISUALIZATION METHOD
    ! =========================================================================
    character(3), allocatable :: vimet(:)       ! (maxnh) Visualization method

contains

    !===========================================================================
    ! SUBROUTINE: allocate_mesh
    !
    ! PURPOSE: Allocate all mesh geometry arrays
    !
    ! ARGUMENTS:
    !   nv - Number of nodes in eta (vertical) direction
    !   nl - Number of nodes in xsi (longitudinal) direction
    !   nh - Number of hillslopes
    !===========================================================================
    subroutine allocate_mesh(nv, nl, nh)
        implicit none
        integer, intent(in) :: nv, nl, nh
        integer :: stat

        ! Curvilinear coordinates
        allocate(xsi(nl,nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate xsi'

        allocate(x_p1m0(nl-1,nh), x_p1m1(nl-2,nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate x_p1m0/x_p1m1'

        allocate(eta(nv,nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate eta'

        allocate(e_p1m0(nv-1,nh), e_p1m1(nv-2,nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate e_p1m0/e_p1m1'

        ! Cartesian coordinates
        allocate(xko(nl), yko(nl), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate xko/yko'

        allocate(xkobez(nh), ykobez(nh), hkobez(nh), hkomin(nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate reference coordinates'

        allocate(hko(nv,nl,nh), sko(nv,nl,nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate hko/sko'

        ! Metric coefficients
        allocate(f_xsi(nv,nl,nh), f_eta(nv,nl,nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate metric coefficients'

        ! Grid spacing
        allocate(dr_o(nl,nh), dr_u(nl,nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate dr_o/dr_u'

        allocate(dr_l(nv,nh), dr_r(nv,nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate dr_l/dr_r'

        allocate(drxsi(nv,nl,nh), dreta(nv,nl,nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate drxsi/dreta'

        allocate(lrd_o(nh), lrd_u(nh), lrd_l(nh), lrd_r(nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate lrd arrays'

        ! Anisotropy tensors
        allocate(kxx(nv,nl,nh), kee(nv,nl,nh), kxe(nv,nl,nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate anisotropy tensors'

        allocate(kxxf(nv,nl,nh), keef(nv,nl,nh), kxef(nv,nl,nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate flux anisotropy tensors'

        allocate(w_xshr(nv,nl), w_xsho(nv,nl), w_xshol(nv,nl,nh), w_hohr(nv,nl), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate angle arrays'

        ! Slopes and orientations
        allocate(slopeo(nl,nh), slopeu(nl,nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate slopeo/slopeu'

        allocate(sloper(nv,nh), slopel(nv,nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate sloper/slopel'

        allocate(gefall(nl,nh), azimut(nl,nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate gefall/azimut'

        ! Areas and volumes
        allocate(area(nv,nl,nh), flaeche(nv,nl,nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate area/flaeche'

        allocate(alla(maxcv,nh), vola(maxcv,nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate alla/vola'

        allocate(hgobfl(nh), hgbreit(nh), hglang(nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate hillslope dimensions'

        ! Variable width
        allocate(varbr(nl,nh), fbrup(nl,nh), fbrlow(nl,nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate variable width arrays'

        ! Soil type indices
        allocate(iboden(nv,nl,nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate iboden'

        ! Conductivity averaging methods
        allocate(mm_xsi(nv,nl-1,nh), mm_eta(nv-1,nl,nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate mm_xsi/mm_eta'

        ! Averaging factors
        allocate(av_fak(nv-1,nl,nh), al_fak(nv,nl-1,nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate averaging factors'

        ! Depth
        allocate(depth(nv,nl,nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate depth'

        ! Macropore data
        allocate(lmak(nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate lmak'

        allocate(macro(nv,nl,nh), amak(nv,nl,nh), b_mac(nv,nl,nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate macropore arrays'

        allocate(ivm(nl,nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate ivm'

        ! Variability factors
        allocate(rel_ks(nv,nl,nh), rel_ths(nv,nl,nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate variability factors'

        ! Polygon vertices
        allocate(sloe(nv,nl,nh), sroe(nv,nl,nh), srue(nv,nl,nh), slue(nv,nl,nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate lateral polygon vertices'

        allocate(smo(nv,nl,nh), smr(nv,nl,nh), smu(nv,nl,nh), sml(nv,nl,nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate lateral center vertices'

        allocate(hloe(nv,nl,nh), hroe(nv,nl,nh), hrue(nv,nl,nh), hlue(nv,nl,nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate vertical polygon vertices'

        allocate(hmo(nv,nl,nh), hmr(nv,nl,nh), hmu(nv,nl,nh), hml(nv,nl,nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate vertical center vertices'

        ! Control volumes
        allocate(icvo(maxcv,nh), icvu(maxcv,nh), icvl(maxcv,nh), icvr(maxcv,nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate control volume indices'

        allocate(iaccv(nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate iaccv'

        ! Hillslope identifiers
        allocate(hangnr(nh), hgih(maxnum), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate hillslope identifiers'

        allocate(iacnv(nh), iacnl(nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate iacnv/iacnl'

        ! Channel parameters
        allocate(lambda(nh), igewkn(2,nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate channel parameters'

        ! Area factors
        allocate(fcabf(nh), fabf(nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate area factors'

        ! Visualization method
        allocate(vimet(nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate vimet'

        ! Initialize logical arrays
        lmak = .false.

    end subroutine allocate_mesh

    !===========================================================================
    ! SUBROUTINE: deallocate_mesh
    !
    ! PURPOSE: Deallocate all mesh geometry arrays
    !===========================================================================
    subroutine deallocate_mesh()
        implicit none

        ! Curvilinear coordinates
        if (allocated(xsi)) deallocate(xsi)
        if (allocated(x_p1m0)) deallocate(x_p1m0)
        if (allocated(x_p1m1)) deallocate(x_p1m1)
        if (allocated(eta)) deallocate(eta)
        if (allocated(e_p1m0)) deallocate(e_p1m0)
        if (allocated(e_p1m1)) deallocate(e_p1m1)

        ! Cartesian coordinates
        if (allocated(xko)) deallocate(xko)
        if (allocated(yko)) deallocate(yko)
        if (allocated(xkobez)) deallocate(xkobez)
        if (allocated(ykobez)) deallocate(ykobez)
        if (allocated(hko)) deallocate(hko)
        if (allocated(sko)) deallocate(sko)
        if (allocated(hkobez)) deallocate(hkobez)
        if (allocated(hkomin)) deallocate(hkomin)

        ! Metric coefficients
        if (allocated(f_xsi)) deallocate(f_xsi)
        if (allocated(f_eta)) deallocate(f_eta)

        ! Grid spacing
        if (allocated(dr_o)) deallocate(dr_o)
        if (allocated(dr_u)) deallocate(dr_u)
        if (allocated(dr_l)) deallocate(dr_l)
        if (allocated(dr_r)) deallocate(dr_r)
        if (allocated(drxsi)) deallocate(drxsi)
        if (allocated(dreta)) deallocate(dreta)
        if (allocated(lrd_o)) deallocate(lrd_o)
        if (allocated(lrd_u)) deallocate(lrd_u)
        if (allocated(lrd_l)) deallocate(lrd_l)
        if (allocated(lrd_r)) deallocate(lrd_r)

        ! Anisotropy tensors
        if (allocated(kxx)) deallocate(kxx)
        if (allocated(kee)) deallocate(kee)
        if (allocated(kxe)) deallocate(kxe)
        if (allocated(kxxf)) deallocate(kxxf)
        if (allocated(keef)) deallocate(keef)
        if (allocated(kxef)) deallocate(kxef)
        if (allocated(w_xshr)) deallocate(w_xshr)
        if (allocated(w_xsho)) deallocate(w_xsho)
        if (allocated(w_xshol)) deallocate(w_xshol)
        if (allocated(w_hohr)) deallocate(w_hohr)

        ! Slopes and orientations
        if (allocated(slopeo)) deallocate(slopeo)
        if (allocated(slopeu)) deallocate(slopeu)
        if (allocated(sloper)) deallocate(sloper)
        if (allocated(slopel)) deallocate(slopel)
        if (allocated(gefall)) deallocate(gefall)
        if (allocated(azimut)) deallocate(azimut)

        ! Areas and volumes
        if (allocated(area)) deallocate(area)
        if (allocated(flaeche)) deallocate(flaeche)
        if (allocated(alla)) deallocate(alla)
        if (allocated(vola)) deallocate(vola)
        if (allocated(hgobfl)) deallocate(hgobfl)
        if (allocated(hgbreit)) deallocate(hgbreit)
        if (allocated(hglang)) deallocate(hglang)

        ! Variable width
        if (allocated(varbr)) deallocate(varbr)
        if (allocated(fbrup)) deallocate(fbrup)
        if (allocated(fbrlow)) deallocate(fbrlow)

        ! Soil type indices
        if (allocated(iboden)) deallocate(iboden)

        ! Conductivity averaging methods
        if (allocated(mm_xsi)) deallocate(mm_xsi)
        if (allocated(mm_eta)) deallocate(mm_eta)

        ! Averaging factors
        if (allocated(av_fak)) deallocate(av_fak)
        if (allocated(al_fak)) deallocate(al_fak)

        ! Depth
        if (allocated(depth)) deallocate(depth)

        ! Macropore data
        if (allocated(lmak)) deallocate(lmak)
        if (allocated(macro)) deallocate(macro)
        if (allocated(amak)) deallocate(amak)
        if (allocated(b_mac)) deallocate(b_mac)
        if (allocated(ivm)) deallocate(ivm)

        ! Variability factors
        if (allocated(rel_ks)) deallocate(rel_ks)
        if (allocated(rel_ths)) deallocate(rel_ths)

        ! Polygon vertices
        if (allocated(sloe)) deallocate(sloe)
        if (allocated(sroe)) deallocate(sroe)
        if (allocated(srue)) deallocate(srue)
        if (allocated(slue)) deallocate(slue)
        if (allocated(smo)) deallocate(smo)
        if (allocated(smr)) deallocate(smr)
        if (allocated(smu)) deallocate(smu)
        if (allocated(sml)) deallocate(sml)
        if (allocated(hloe)) deallocate(hloe)
        if (allocated(hroe)) deallocate(hroe)
        if (allocated(hrue)) deallocate(hrue)
        if (allocated(hlue)) deallocate(hlue)
        if (allocated(hmo)) deallocate(hmo)
        if (allocated(hmr)) deallocate(hmr)
        if (allocated(hmu)) deallocate(hmu)
        if (allocated(hml)) deallocate(hml)

        ! Control volumes
        if (allocated(icvo)) deallocate(icvo)
        if (allocated(icvu)) deallocate(icvu)
        if (allocated(icvl)) deallocate(icvl)
        if (allocated(icvr)) deallocate(icvr)
        if (allocated(iaccv)) deallocate(iaccv)

        ! Hillslope identifiers
        if (allocated(hangnr)) deallocate(hangnr)
        if (allocated(hgih)) deallocate(hgih)
        if (allocated(iacnv)) deallocate(iacnv)
        if (allocated(iacnl)) deallocate(iacnl)

        ! Channel parameters
        if (allocated(lambda)) deallocate(lambda)
        if (allocated(igewkn)) deallocate(igewkn)

        ! Area factors
        if (allocated(fcabf)) deallocate(fcabf)
        if (allocated(fabf)) deallocate(fabf)

        ! Visualization method
        if (allocated(vimet)) deallocate(vimet)

    end subroutine deallocate_mesh

    !===========================================================================
    ! SUBROUTINE: get_mesh_info
    !
    ! PURPOSE: Print information about mesh geometry
    !===========================================================================
    subroutine get_mesh_info()
        implicit none

        print *, ''
        print *, '==================================================='
        print *, 'MESH GEOMETRY MODULE INFORMATION'
        print *, '==================================================='
        print *, ''

        if (allocated(xsi)) then
            print *, 'Mesh arrays are allocated:'
            print *, '  Grid dimensions:'
            print *, '    eta (vertical):   ', size(eta, 1), ' nodes'
            print *, '    xsi (longitudinal):', size(xsi, 1), ' nodes'
            print *, '    hillslopes:       ', size(xsi, 2)
            print *, ''
            print *, '  Total nodes:', size(eta, 1) * size(xsi, 1)
        else
            print *, 'Mesh arrays are NOT allocated'
        end if

        print *, ''
        print *, '==================================================='
        print *, ''

    end subroutine get_mesh_info

end module mesh_geometry_module
