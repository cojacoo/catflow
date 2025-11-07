!===============================================================================
! MODULE: soil_hydraulics_module
!
! PURPOSE:
!   Soil hydraulic properties and parameters for CATFLOW
!   Replaces soil.inc with modern Fortran 90 module
!
! DESCRIPTION:
!   Contains all soil-related data including:
!   - Van Genuchten parameters
!   - Soil hydraulic tables
!   - Soil type properties
!   - Anisotropy factors
!   - Albedo parameters
!   - Soil resistance parameters
!   - Erosion parameters
!
! AUTHOR: CATFLOW Streamlined
! DATE: 2025-11-07
!
! REPLACES: soil.inc (51 lines with COMMON blocks)
!===============================================================================
module soil_hydraulics_module
    use constants_module, only: maxtyp, maxtab, maxeig, maxpbm, maxero
    implicit none
    private  ! Make everything private by default

    ! =========================================================================
    ! PUBLIC INTERFACE
    ! =========================================================================
    public :: allocate_soil
    public :: deallocate_soil
    public :: get_soil_info

    ! Van Genuchten parameters
    public :: vg_ngr

    ! Soil hydraulic table
    public :: s_tab

    ! Soil parameters
    public :: bodpar

    ! Anisotropy
    public :: anisot

    ! Permanent wilting point
    public :: th_pwp

    ! Storage coefficient
    public :: snull

    ! Albedo parameters
    public :: satkni, balmax, balmin

    ! Soil resistance parameters
    public :: f_rs, wp_rs, zd_max

    ! Erosion parameters
    public :: eross

    ! Conversion method
    public :: imod

    ! Soil descriptions
    public :: boden, tabfil

    ! Actual dimensions
    public :: iactyp, iactab, iaceig

    ! =========================================================================
    ! VAN GENUCHTEN PARAMETERS
    ! =========================================================================
    ! Boundary between arithmetic and geometric averaging for Van Genuchten's n
    ! (after Zurmuehl)
    real(8), parameter :: vg_ngr = 2.0d0

    ! =========================================================================
    ! SOIL HYDRAULIC TABLE
    ! =========================================================================
    ! Soil hydraulic table: (table_rows, eigenvalues, soil_types)
    ! Contains precalculated hydraulic properties
    real(8), allocatable :: s_tab(:,:,:)    ! (maxtab, maxeig, maxtyp)

    ! =========================================================================
    ! SOIL PARAMETERS
    ! =========================================================================
    ! Soil parameters: (parameters, soil_types)
    ! Contains Van Genuchten parameters, saturated hydraulic conductivity, etc.
    real(8), allocatable :: bodpar(:,:)     ! (maxpbm, maxtyp)

    ! =========================================================================
    ! ANISOTROPY
    ! =========================================================================
    ! Soil anisotropy factors: (2, soil_types)
    ! anisot(1,:): horizontal/vertical anisotropy ratio
    ! anisot(2,:): angle of anisotropy
    real(8), allocatable :: anisot(:,:)     ! (2, maxtyp)

    ! =========================================================================
    ! WATER RETENTION
    ! =========================================================================
    ! Permanent wilting point [Vol.-%] for each soil type
    real(8), allocatable :: th_pwp(:)       ! (maxtyp)

    ! Storage coefficient for saturated soil for each soil type
    real(8), allocatable :: snull(:)        ! (maxtyp)

    ! =========================================================================
    ! ALBEDO PARAMETERS
    ! =========================================================================
    ! Soil albedo parameters:
    ! satkni: Saturation influence coefficient
    ! balmax: Albedo under dry conditions
    ! balmin: Albedo at satkni * saturation
    real(8), allocatable :: satkni(:)       ! (maxtyp)
    real(8), allocatable :: balmax(:)       ! (maxtyp)
    real(8), allocatable :: balmin(:)       ! (maxtyp)

    ! =========================================================================
    ! SOIL RESISTANCE PARAMETERS (Kolle model)
    ! =========================================================================
    ! f_rs:   Soil resistance factor
    ! wp_rs:  Wilting point for resistance
    ! zd_max: Maximum dry layer thickness [m]
    real(8), allocatable :: f_rs(:)         ! (maxtyp)
    real(8), allocatable :: wp_rs(:)        ! (maxtyp)
    real(8), allocatable :: zd_max(:)       ! (maxtyp)

    ! =========================================================================
    ! EROSION PARAMETERS (Schramm model)
    ! =========================================================================
    real(8), allocatable :: eross(:,:)      ! (maxero, maxtyp)

    ! =========================================================================
    ! CONVERSION METHOD
    ! =========================================================================
    ! Method to convert soil parameters to soil hydraulic table
    ! Different models: Van Genuchten, Brooks-Corey, etc.
    integer(4), allocatable :: imod(:)      ! (maxtyp)

    ! =========================================================================
    ! SOIL DESCRIPTIONS
    ! =========================================================================
    ! Soil type names/descriptions
    character(30), allocatable :: boden(:)  ! (maxtyp)

    ! Names of input files holding tables of soil hydraulic properties
    character(30), allocatable :: tabfil(:) ! (maxtyp)

    ! =========================================================================
    ! ACTUAL DIMENSIONS
    ! =========================================================================
    ! Actual number of soil types in use
    integer(4) :: iactyp

    ! Actual number of table rows for each soil type
    integer(4), allocatable :: iactab(:)    ! (maxtyp)

    ! Actual number of eigenvalues (properties) in table
    integer(4) :: iaceig

contains

    !===========================================================================
    ! SUBROUTINE: allocate_soil
    !
    ! PURPOSE: Allocate all soil hydraulic arrays
    !===========================================================================
    subroutine allocate_soil()
        implicit none
        integer :: stat

        ! Soil hydraulic table
        allocate(s_tab(maxtab, maxeig, maxtyp), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate s_tab'

        ! Soil parameters
        allocate(bodpar(maxpbm, maxtyp), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate bodpar'

        ! Anisotropy
        allocate(anisot(2, maxtyp), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate anisot'

        ! Water retention
        allocate(th_pwp(maxtyp), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate th_pwp'

        allocate(snull(maxtyp), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate snull'

        ! Albedo parameters
        allocate(satkni(maxtyp), balmax(maxtyp), balmin(maxtyp), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate albedo parameters'

        ! Soil resistance parameters
        allocate(f_rs(maxtyp), wp_rs(maxtyp), zd_max(maxtyp), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate soil resistance parameters'

        ! Erosion parameters
        allocate(eross(maxero, maxtyp), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate eross'

        ! Conversion method
        allocate(imod(maxtyp), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate imod'

        ! Soil descriptions
        allocate(boden(maxtyp), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate boden'

        allocate(tabfil(maxtyp), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate tabfil'

        ! Table dimensions
        allocate(iactab(maxtyp), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate iactab'

        ! Initialize dimensions
        iactyp = 0
        iaceig = 0
        iactab = 0

        ! Initialize strings
        boden = ''
        tabfil = ''

        ! Initialize numeric arrays to zero
        s_tab = 0.0d0
        bodpar = 0.0d0
        anisot = 0.0d0
        th_pwp = 0.0d0
        snull = 0.0d0
        satkni = 0.0d0
        balmax = 0.0d0
        balmin = 0.0d0
        f_rs = 0.0d0
        wp_rs = 0.0d0
        zd_max = 0.0d0
        eross = 0.0d0
        imod = 0

    end subroutine allocate_soil

    !===========================================================================
    ! SUBROUTINE: deallocate_soil
    !
    ! PURPOSE: Deallocate all soil hydraulic arrays
    !===========================================================================
    subroutine deallocate_soil()
        implicit none

        ! Soil hydraulic table
        if (allocated(s_tab)) deallocate(s_tab)

        ! Soil parameters
        if (allocated(bodpar)) deallocate(bodpar)

        ! Anisotropy
        if (allocated(anisot)) deallocate(anisot)

        ! Water retention
        if (allocated(th_pwp)) deallocate(th_pwp)
        if (allocated(snull)) deallocate(snull)

        ! Albedo parameters
        if (allocated(satkni)) deallocate(satkni)
        if (allocated(balmax)) deallocate(balmax)
        if (allocated(balmin)) deallocate(balmin)

        ! Soil resistance parameters
        if (allocated(f_rs)) deallocate(f_rs)
        if (allocated(wp_rs)) deallocate(wp_rs)
        if (allocated(zd_max)) deallocate(zd_max)

        ! Erosion parameters
        if (allocated(eross)) deallocate(eross)

        ! Conversion method
        if (allocated(imod)) deallocate(imod)

        ! Soil descriptions
        if (allocated(boden)) deallocate(boden)
        if (allocated(tabfil)) deallocate(tabfil)

        ! Table dimensions
        if (allocated(iactab)) deallocate(iactab)

    end subroutine deallocate_soil

    !===========================================================================
    ! SUBROUTINE: get_soil_info
    !
    ! PURPOSE: Print information about soil hydraulic module
    !===========================================================================
    subroutine get_soil_info()
        implicit none

        print *, ''
        print *, '==================================================='
        print *, 'SOIL HYDRAULICS MODULE INFORMATION'
        print *, '==================================================='
        print *, ''

        print *, 'Van Genuchten parameter:'
        print *, '  vg_ngr (n boundary) = ', vg_ngr
        print *, ''

        if (allocated(s_tab)) then
            print *, 'Soil arrays are allocated:'
            print *, '  Maximum soil types:    ', maxtyp
            print *, '  Maximum table rows:    ', maxtab
            print *, '  Maximum properties:    ', maxeig
            print *, '  Maximum parameters:    ', maxpbm
            print *, ''
            print *, 'Active dimensions:'
            print *, '  Active soil types:     ', iactyp
            print *, '  Active properties:     ', iaceig
        else
            print *, 'Soil arrays are NOT allocated'
        end if

        print *, ''
        print *, '==================================================='
        print *, ''

    end subroutine get_soil_info

end module soil_hydraulics_module
