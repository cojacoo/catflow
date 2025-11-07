!===============================================================================
! MODULE: boundary_conditions_module
!
! PURPOSE:
!   Boundary conditions and forcing data for CATFLOW
!   Replaces hgbdry.inc with modern Fortran 90 module
!
! DESCRIPTION:
!   Contains all boundary condition data including:
!   - Mathematical BC types (Dirichlet, Neumann, mixed)
!   - Climate forcing data (temperature, radiation, wind, etc.)
!   - Rainfall/precipitation data
!   - Land use and vegetation parameters
!   - ET components (soil, interception, canopy)
!   - Time series management for all forcings
!   - Wind reduction and horizon shading factors
!
! AUTHOR: CATFLOW Streamlined
! DATE: 2025-11-07
!
! REPLACES: hgbdry.inc (201 lines with COMMON blocks)
!===============================================================================
module boundary_conditions_module
    use constants_module, only: maxnv, maxnl, maxnh, maxrbf, maxsnk, maxrbp, &
                                 maxskp, maxkli, maxkld, maxnie, maxtyp, &
                                 maxuse, maxpft, maxpfp, maxwrf, maxfix, maxhor, maxero
    implicit none
    private

    ! =========================================================================
    ! PUBLIC INTERFACE
    ! =========================================================================
    public :: allocate_boundary_conditions
    public :: deallocate_boundary_conditions
    public :: get_bc_info

    ! Boundary condition types and indices
    public :: irbtyp, isktyp, ktyp
    public :: irb_u, irb_o, irb_r, irb_l, isnk
    public :: vorz_u, vorz_o, vorz_r, vorz_l, vorz_s
    public :: vsav_u, vsav_o, vsav_r, vsav_l, vsav_s

    ! Boundary condition parameters
    public :: rbpar, skpar

    ! Climate data
    public :: klima, klimas, zref, iackld, klfehlt
    public :: sw0, sw1, sw2, trueb, truebf
    public :: rBilart

    ! Rainfall data
    public :: nied

    ! Potential fluxes and potentials
    public :: qu_pot, qo_pot, qr_pot, ql_pot, qs_pot
    public :: pu_pot, po_pot, pr_pot, pl_pot, ps_pot
    public :: lueb_u, lueb_o, lueb_r, lueb_l, lueb_s

    ! ET components
    public :: neff, interz, iz_alt, sattgr
    public :: Esoil, Eintz, Ecanop
    public :: plrw, ivroot

    ! Land use
    public :: iusenr, luseid, cluse, pflpar
    public :: iacuse, iacpft, iacpfp
    public :: t_ln, lnfile

    ! Wind and radiation
    public :: wrf, wru, wro, bezfak
    public :: iacwrf, hor, iachor, iacfix
    public :: ifixob

    ! File management
    public :: rbfil, snkfil, n_fil, k_fil
    public :: iacrbf, iacsnk, iacnie, iackli

    ! Interpolation flags
    public :: lrintp, lsintp, lnintp, lklima, lnied, etilog

    ! Time series
    public :: zrbf, z2srbf, szrbf
    public :: zsnk, z2ssnk, szsnk
    public :: zkli, z2skli, szkli, klifak
    public :: znie, z2snie, sznie, niefak

    ! =========================================================================
    ! BOUNDARY CONDITION TYPES AND INDICES
    ! =========================================================================
    ! BC type: (time_index, bc_file_index)
    ! Values: 1=Dirichlet (pressure), 2=Neumann (flux), 3=mixed
    integer(4), allocatable :: irbtyp(:,:)      ! (2, maxrbf)
    integer(4), allocatable :: isktyp(:,:)      ! (2, maxsnk) Sink/source type

    ! BC file indices for each boundary
    integer(4), allocatable :: irb_u(:,:)       ! (maxnl, maxnh) Bottom
    integer(4), allocatable :: irb_o(:,:)       ! (maxnl, maxnh) Top/surface
    integer(4), allocatable :: irb_r(:,:)       ! (maxnv, maxnh) Right
    integer(4), allocatable :: irb_l(:,:)       ! (maxnv, maxnh) Left
    integer(4), allocatable :: isnk(:,:,:)      ! (maxnv,maxnl,maxnh) Internal sink/source

    ! Sign of BC (-1: potential/Dirichlet, 1: flux/Neumann)
    integer(4), allocatable :: vorz_u(:,:)      ! (maxnl, maxnh)
    integer(4), allocatable :: vorz_o(:,:)      ! (maxnl, maxnh)
    integer(4), allocatable :: vorz_r(:,:)      ! (maxnv, maxnh)
    integer(4), allocatable :: vorz_l(:,:)      ! (maxnv, maxnh)
    integer(4), allocatable :: vorz_s(:,:,:)    ! (maxnv,maxnl,maxnh)

    ! Saved BC signs
    integer(4), allocatable :: vsav_u(:)        ! (maxnl)
    integer(4), allocatable :: vsav_o(:)        ! (maxnl)
    integer(4), allocatable :: vsav_r(:)        ! (maxnv)
    integer(4), allocatable :: vsav_l(:)        ! (maxnv)
    integer(4), allocatable :: vsav_s(:,:)      ! (maxnv, maxnl)

    ! =========================================================================
    ! BOUNDARY CONDITION PARAMETERS
    ! =========================================================================
    real(8), allocatable :: rbpar(:,:,:)        ! (2,maxrbp,maxrbf) BC parameters
    real(8), allocatable :: skpar(:,:,:)        ! (2,maxskp,maxsnk) Sink parameters

    ! =========================================================================
    ! CLIMATE DATA
    ! =========================================================================
    ! Climate data interval: (time_index, data_column, climate_file)
    real(8), allocatable :: klima(:,:,:)        ! (2, maxkld, maxkli)
    real(8), allocatable :: klimas(:,:)         ! (maxkld, maxkli) Saved values
    real(8), allocatable :: zref(:)             ! (maxkli) Reference height [m]
    integer(4), allocatable :: ktyp(:)          ! (maxkli) Climate data type (1 or 2)
    integer(4), allocatable :: iackld(:)        ! (maxkli) Active columns per file
    logical, allocatable :: klfehlt(:)          ! (maxkli) Missing data flag

    ! Radiation parameters (for Kolle model)
    real(8), allocatable :: sw0(:)              ! (maxkli) SW radiation regression
    real(8), allocatable :: sw1(:)              ! (maxkli) SW radiation regression
    real(8), allocatable :: sw2(:)              ! (maxkli) SW radiation regression
    real(8), allocatable :: trueb(:)            ! (maxkli) Atmospheric dimming
    real(8), allocatable :: truebf(:)           ! (maxkli) Atmospheric dimming factor
    integer(4), allocatable :: rBilart(:)       ! (maxkli) Net radiation method (1 or 2)

    ! =========================================================================
    ! RAINFALL DATA
    ! =========================================================================
    real(8), allocatable :: nied(:,:)           ! (2, maxnie) Rainfall time series

    ! =========================================================================
    ! INEQUALITY BOUNDARY CONDITIONS
    ! =========================================================================
    ! Flags for boundary flux overflow (inequality BC)
    logical, allocatable :: lueb_u(:)           ! (maxnl)
    logical, allocatable :: lueb_o(:)           ! (maxnl)
    logical, allocatable :: lueb_r(:)           ! (maxnv)
    logical, allocatable :: lueb_l(:)           ! (maxnv)
    logical, allocatable :: lueb_s(:,:)         ! (maxnv, maxnl)

    ! Potential fluxes [m/s]
    real(8), allocatable :: qu_pot(:)           ! (maxnl) Bottom
    real(8), allocatable :: qo_pot(:)           ! (maxnl) Top
    real(8), allocatable :: qr_pot(:)           ! (maxnv) Right
    real(8), allocatable :: ql_pot(:)           ! (maxnv) Left
    real(8), allocatable :: qs_pot(:,:)         ! (maxnv, maxnl) Internal

    ! Potential pressures [m]
    real(8), allocatable :: pu_pot(:)           ! (maxnl)
    real(8), allocatable :: po_pot(:)           ! (maxnl)
    real(8), allocatable :: pr_pot(:)           ! (maxnv)
    real(8), allocatable :: pl_pot(:)           ! (maxnv)
    real(8), allocatable :: ps_pot(:,:)         ! (maxnv, maxnl)

    ! =========================================================================
    ! EVAPOTRANSPIRATION COMPONENTS
    ! =========================================================================
    real(8), allocatable :: neff(:)             ! (maxnl) Effective rainfall [m/s]
    real(8), allocatable :: interz(:)           ! (maxnl) Interception storage [m]
    real(8), allocatable :: iz_alt(:,:)         ! (maxnl,maxnh) Old interception [m]
    real(8), allocatable :: sattgr(:)           ! (maxtyp) Saturation threshold

    real(8), allocatable :: Esoil(:)            ! (maxnl) Soil evaporation [m/s]
    real(8), allocatable :: Eintz(:)            ! (maxnl) Interception evap [m/s]
    real(8), allocatable :: Ecanop(:)           ! (maxnl) Transpiration [m/s]

    real(8), allocatable :: plrw(:,:)           ! (maxnv,maxnl) Plant-available water fraction
    integer(4), allocatable :: ivroot(:)        ! (maxnl) Rooting depth element index

    ! =========================================================================
    ! LAND USE / VEGETATION
    ! =========================================================================
    integer(4), allocatable :: iusenr(:,:)      ! (maxnl,maxnh) Land use number
    integer(4), allocatable :: luseid(:)        ! (maxuse) Land use IDs
    character(30), allocatable :: cluse(:)      ! (maxuse) Land use descriptions

    ! Plant functional type parameters
    ! (time_step, parameter_index, land_use_type)
    real(8), allocatable :: pflpar(:,:,:)       ! (maxpft, maxpfp+1, maxuse)

    integer(4) :: iacuse                         ! Active land uses
    integer(4), allocatable :: iacpft(:)        ! (maxuse) Active PFT time steps
    integer(4) :: iacpfp                         ! Active PFT parameters

    ! Land use time series
    real(8) :: t_ln(2)                           ! Time bounds for land use
    character(30) :: lnfile                      ! Land use filename

    ! =========================================================================
    ! WIND AND RADIATION FACTORS
    ! =========================================================================
    ! Wind reduction factors
    real(8), allocatable :: wrf(:,:,:)          ! (maxnl,maxwrf,maxnh)
    real(8), allocatable :: wru(:)              ! (maxwrf) Wind direction lower bound
    real(8), allocatable :: wro(:)              ! (maxwrf) Wind direction upper bound
    real(8), allocatable :: bezfak(:,:)         ! (maxwrf,maxkli) Reference factors
    integer(4) :: iacwrf                         ! Active wind reduction factors

    ! Horizon angles for shading
    integer(4), allocatable :: hor(:,:,:)       ! (maxnl,maxhor,maxnh)
    integer(4) :: iachor                         ! Active horizon angles

    ! Surface indices
    integer(4), allocatable :: ifixob(:,:,:)    ! (maxnl,maxfix,maxnh)
    integer(4) :: iacfix                         ! Active surface indices

    ! =========================================================================
    ! FILE MANAGEMENT
    ! =========================================================================
    character(30), allocatable :: rbfil(:)      ! (maxrbf) BC filenames
    character(30), allocatable :: snkfil(:)     ! (maxsnk) Sink filenames
    character(30), allocatable :: n_fil(:)      ! (maxnie) Rainfall filenames
    character(30), allocatable :: k_fil(:)      ! (maxkli) Climate filenames

    integer(4) :: iacrbf                         ! Active BC files
    integer(4) :: iacsnk                         ! Active sink files
    integer(4) :: iacnie                         ! Active rainfall files
    integer(4) :: iackli                         ! Active climate files

    ! =========================================================================
    ! INTERPOLATION FLAGS
    ! =========================================================================
    logical, allocatable :: lrintp(:)           ! (maxrbf) Interpolate BC?
    logical, allocatable :: lsintp(:)           ! (maxsnk) Interpolate sink?
    logical, allocatable :: lnintp(:)           ! (maxnie) Interpolate rainfall?
    logical, allocatable :: lklima(:)           ! (maxkli) Climate available?
    logical, allocatable :: lnied(:)            ! (maxnie) Rainfall available?
    logical :: etilog                            ! ET logging flag

    ! =========================================================================
    ! TIME SERIES DATA
    ! =========================================================================
    ! Boundary condition time series
    real(8), allocatable :: zrbf(:,:)           ! (2,maxrbf) Time [s]
    real(8), allocatable :: z2srbf(:)           ! (maxrbf) File time -> seconds
    real(8), allocatable :: szrbf(:)            ! (maxrbf) Time offset

    ! Sink time series
    real(8), allocatable :: zsnk(:,:)           ! (2,maxsnk)
    real(8), allocatable :: z2ssnk(:)           ! (maxsnk)
    real(8), allocatable :: szsnk(:)            ! (maxsnk)

    ! Climate time series
    real(8), allocatable :: zkli(:,:)           ! (2,maxkli)
    real(8), allocatable :: z2skli(:)           ! (maxkli)
    real(8), allocatable :: szkli(:)            ! (maxkli)
    real(8), allocatable :: klifak(:)           ! (maxkli) Climate factor

    ! Rainfall time series
    real(8), allocatable :: znie(:,:)           ! (2,maxnie)
    real(8), allocatable :: z2snie(:)           ! (maxnie)
    real(8), allocatable :: sznie(:)            ! (maxnie)
    real(8), allocatable :: niefak(:)           ! (maxnie) Rainfall factor

contains

    !===========================================================================
    ! SUBROUTINE: allocate_boundary_conditions
    !
    ! PURPOSE: Allocate all boundary condition arrays
    !===========================================================================
    subroutine allocate_boundary_conditions()
        implicit none
        integer :: stat

        ! BC types and indices
        allocate(irbtyp(2,maxrbf), isktyp(2,maxsnk), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate BC types'

        allocate(irb_u(maxnl,maxnh), irb_o(maxnl,maxnh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate irb_u/irb_o'

        allocate(irb_r(maxnv,maxnh), irb_l(maxnv,maxnh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate irb_r/irb_l'

        allocate(isnk(maxnv,maxnl,maxnh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate isnk'

        ! BC signs
        allocate(vorz_u(maxnl,maxnh), vorz_o(maxnl,maxnh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate vorz_u/vorz_o'

        allocate(vorz_r(maxnv,maxnh), vorz_l(maxnv,maxnh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate vorz_r/vorz_l'

        allocate(vorz_s(maxnv,maxnl,maxnh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate vorz_s'

        allocate(vsav_u(maxnl), vsav_o(maxnl), vsav_r(maxnv), vsav_l(maxnv), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate vsav arrays'

        allocate(vsav_s(maxnv,maxnl), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate vsav_s'

        ! BC parameters
        allocate(rbpar(2,maxrbp,maxrbf), skpar(2,maxskp,maxsnk), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate BC parameters'

        ! Climate data
        allocate(klima(2,maxkld,maxkli), klimas(maxkld,maxkli), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate klima'

        allocate(zref(maxkli), ktyp(maxkli), iackld(maxkli), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate climate metadata'

        allocate(klfehlt(maxkli), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate klfehlt'

        allocate(sw0(maxkli), sw1(maxkli), sw2(maxkli), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate SW parameters'

        allocate(trueb(maxkli), truebf(maxkli), rBilart(maxkli), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate radiation parameters'

        ! Rainfall
        allocate(nied(2,maxnie), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate nied'

        ! Inequality BC
        allocate(lueb_u(maxnl), lueb_o(maxnl), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate lueb_u/lueb_o'

        allocate(lueb_r(maxnv), lueb_l(maxnv), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate lueb_r/lueb_l'

        allocate(lueb_s(maxnv,maxnl), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate lueb_s'

        allocate(qu_pot(maxnl), qo_pot(maxnl), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate q_pot arrays'

        allocate(qr_pot(maxnv), ql_pot(maxnv), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate qr/ql_pot'

        allocate(qs_pot(maxnv,maxnl), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate qs_pot'

        allocate(pu_pot(maxnl), po_pot(maxnl), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate p_pot arrays'

        allocate(pr_pot(maxnv), pl_pot(maxnv), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate pr/pl_pot'

        allocate(ps_pot(maxnv,maxnl), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate ps_pot'

        ! ET components
        allocate(neff(maxnl), interz(maxnl), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate neff/interz'

        allocate(iz_alt(maxnl,maxnh), sattgr(maxtyp), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate iz_alt/sattgr'

        allocate(Esoil(maxnl), Eintz(maxnl), Ecanop(maxnl), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate ET components'

        allocate(plrw(maxnv,maxnl), ivroot(maxnl), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate plrw/ivroot'

        ! Land use
        allocate(iusenr(maxnl,maxnh), luseid(maxuse), cluse(maxuse), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate land use arrays'

        allocate(pflpar(maxpft,maxpfp+1,maxuse), iacpft(maxuse), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate pflpar'

        ! Wind and radiation
        allocate(wrf(maxnl,maxwrf,maxnh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate wrf'

        allocate(wru(maxwrf), wro(maxwrf), bezfak(maxwrf,maxkli), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate wind parameters'

        allocate(hor(maxnl,maxhor,maxnh), ifixob(maxnl,maxfix,maxnh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate horizon/surface indices'

        ! Filenames
        allocate(rbfil(maxrbf), snkfil(maxsnk), n_fil(maxnie), k_fil(maxkli), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate filename arrays'

        ! Interpolation flags
        allocate(lrintp(maxrbf), lsintp(maxsnk), lnintp(maxnie), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate interpolation flags'

        allocate(lklima(maxkli), lnied(maxnie), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate data availability flags'

        ! Time series
        allocate(zrbf(2,maxrbf), z2srbf(maxrbf), szrbf(maxrbf), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate BC time series'

        allocate(zsnk(2,maxsnk), z2ssnk(maxsnk), szsnk(maxsnk), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate sink time series'

        allocate(zkli(2,maxkli), z2skli(maxkli), szkli(maxkli), klifak(maxkli), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate climate time series'

        allocate(znie(2,maxnie), z2snie(maxnie), sznie(maxnie), niefak(maxnie), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate rainfall time series'

        ! Initialize counters
        iacrbf = 0
        iacsnk = 0
        iacnie = 0
        iackli = 0
        iacuse = 0
        iacpfp = 0
        iacwrf = 0
        iachor = 0
        iacfix = 0

        ! Initialize flags
        etilog = .false.
        lueb_u = .false.
        lueb_o = .false.
        lueb_r = .false.
        lueb_l = .false.
        lueb_s = .false.
        lrintp = .false.
        lsintp = .false.
        lnintp = .false.
        lklima = .false.
        lnied = .false.
        klfehlt = .false.

        ! Initialize strings
        rbfil = ''
        snkfil = ''
        n_fil = ''
        k_fil = ''
        cluse = ''
        lnfile = ''

    end subroutine allocate_boundary_conditions

    !===========================================================================
    ! SUBROUTINE: deallocate_boundary_conditions
    !
    ! PURPOSE: Deallocate all boundary condition arrays
    !===========================================================================
    subroutine deallocate_boundary_conditions()
        implicit none

        if (allocated(irbtyp)) deallocate(irbtyp)
        if (allocated(isktyp)) deallocate(isktyp)
        if (allocated(irb_u)) deallocate(irb_u)
        if (allocated(irb_o)) deallocate(irb_o)
        if (allocated(irb_r)) deallocate(irb_r)
        if (allocated(irb_l)) deallocate(irb_l)
        if (allocated(isnk)) deallocate(isnk)
        if (allocated(vorz_u)) deallocate(vorz_u)
        if (allocated(vorz_o)) deallocate(vorz_o)
        if (allocated(vorz_r)) deallocate(vorz_r)
        if (allocated(vorz_l)) deallocate(vorz_l)
        if (allocated(vorz_s)) deallocate(vorz_s)
        if (allocated(vsav_u)) deallocate(vsav_u)
        if (allocated(vsav_o)) deallocate(vsav_o)
        if (allocated(vsav_r)) deallocate(vsav_r)
        if (allocated(vsav_l)) deallocate(vsav_l)
        if (allocated(vsav_s)) deallocate(vsav_s)
        if (allocated(rbpar)) deallocate(rbpar)
        if (allocated(skpar)) deallocate(skpar)
        if (allocated(klima)) deallocate(klima)
        if (allocated(klimas)) deallocate(klimas)
        if (allocated(zref)) deallocate(zref)
        if (allocated(ktyp)) deallocate(ktyp)
        if (allocated(iackld)) deallocate(iackld)
        if (allocated(klfehlt)) deallocate(klfehlt)
        if (allocated(sw0)) deallocate(sw0)
        if (allocated(sw1)) deallocate(sw1)
        if (allocated(sw2)) deallocate(sw2)
        if (allocated(trueb)) deallocate(trueb)
        if (allocated(truebf)) deallocate(truebf)
        if (allocated(rBilart)) deallocate(rBilart)
        if (allocated(nied)) deallocate(nied)
        if (allocated(lueb_u)) deallocate(lueb_u)
        if (allocated(lueb_o)) deallocate(lueb_o)
        if (allocated(lueb_r)) deallocate(lueb_r)
        if (allocated(lueb_l)) deallocate(lueb_l)
        if (allocated(lueb_s)) deallocate(lueb_s)
        if (allocated(qu_pot)) deallocate(qu_pot)
        if (allocated(qo_pot)) deallocate(qo_pot)
        if (allocated(qr_pot)) deallocate(qr_pot)
        if (allocated(ql_pot)) deallocate(ql_pot)
        if (allocated(qs_pot)) deallocate(qs_pot)
        if (allocated(pu_pot)) deallocate(pu_pot)
        if (allocated(po_pot)) deallocate(po_pot)
        if (allocated(pr_pot)) deallocate(pr_pot)
        if (allocated(pl_pot)) deallocate(pl_pot)
        if (allocated(ps_pot)) deallocate(ps_pot)
        if (allocated(neff)) deallocate(neff)
        if (allocated(interz)) deallocate(interz)
        if (allocated(iz_alt)) deallocate(iz_alt)
        if (allocated(sattgr)) deallocate(sattgr)
        if (allocated(Esoil)) deallocate(Esoil)
        if (allocated(Eintz)) deallocate(Eintz)
        if (allocated(Ecanop)) deallocate(Ecanop)
        if (allocated(plrw)) deallocate(plrw)
        if (allocated(ivroot)) deallocate(ivroot)
        if (allocated(iusenr)) deallocate(iusenr)
        if (allocated(luseid)) deallocate(luseid)
        if (allocated(cluse)) deallocate(cluse)
        if (allocated(pflpar)) deallocate(pflpar)
        if (allocated(iacpft)) deallocate(iacpft)
        if (allocated(wrf)) deallocate(wrf)
        if (allocated(wru)) deallocate(wru)
        if (allocated(wro)) deallocate(wro)
        if (allocated(bezfak)) deallocate(bezfak)
        if (allocated(hor)) deallocate(hor)
        if (allocated(ifixob)) deallocate(ifixob)
        if (allocated(rbfil)) deallocate(rbfil)
        if (allocated(snkfil)) deallocate(snkfil)
        if (allocated(n_fil)) deallocate(n_fil)
        if (allocated(k_fil)) deallocate(k_fil)
        if (allocated(lrintp)) deallocate(lrintp)
        if (allocated(lsintp)) deallocate(lsintp)
        if (allocated(lnintp)) deallocate(lnintp)
        if (allocated(lklima)) deallocate(lklima)
        if (allocated(lnied)) deallocate(lnied)
        if (allocated(zrbf)) deallocate(zrbf)
        if (allocated(z2srbf)) deallocate(z2srbf)
        if (allocated(szrbf)) deallocate(szrbf)
        if (allocated(zsnk)) deallocate(zsnk)
        if (allocated(z2ssnk)) deallocate(z2ssnk)
        if (allocated(szsnk)) deallocate(szsnk)
        if (allocated(zkli)) deallocate(zkli)
        if (allocated(z2skli)) deallocate(z2skli)
        if (allocated(szkli)) deallocate(szkli)
        if (allocated(klifak)) deallocate(klifak)
        if (allocated(znie)) deallocate(znie)
        if (allocated(z2snie)) deallocate(z2snie)
        if (allocated(sznie)) deallocate(sznie)
        if (allocated(niefak)) deallocate(niefak)

    end subroutine deallocate_boundary_conditions

    !===========================================================================
    ! SUBROUTINE: get_bc_info
    !
    ! PURPOSE: Print information about boundary conditions
    !===========================================================================
    subroutine get_bc_info()
        implicit none

        print *, ''
        print *, '==================================================='
        print *, 'BOUNDARY CONDITIONS MODULE INFORMATION'
        print *, '==================================================='
        print *, ''

        if (allocated(irbtyp)) then
            print *, 'Boundary condition arrays are allocated'
            print *, ''
            print *, 'Active data files:'
            print *, '  BC files:      ', iacrbf
            print *, '  Sink files:    ', iacsnk
            print *, '  Climate files: ', iackli
            print *, '  Rainfall files:', iacnie
            print *, ''
            print *, 'Land use:'
            print *, '  Active uses:   ', iacuse
            print *, '  PFT parameters:', iacpfp
            print *, ''
            print *, 'Wind/radiation:'
            print *, '  Wind sectors:  ', iacwrf
            print *, '  Horizon angles:', iachor
        else
            print *, 'Boundary condition arrays are NOT allocated'
        end if

        print *, ''
        print *, '==================================================='
        print *, ''

    end subroutine get_bc_info

end module boundary_conditions_module
