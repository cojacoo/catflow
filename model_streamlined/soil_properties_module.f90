!===============================================================================
! MODULE: soil_properties_module
!
! PURPOSE:
!   Soil hydraulic properties and retention curves for CATFLOW Streamlined
!
! DESCRIPTION:
!   Contains soil parameter arrays and hydraulic property tables:
!   - bodpar:  Soil parameters (van Genuchten, etc.) [varies]
!   - boden:   Soil type names [character]
!   - s_tab:   Tabulated soil hydraulic properties [varies]
!   - anisot:  Anisotropy ratios Kh/Kv [dimensionless]
!   - snull:   Residual moisture content [m³/m³]
!   - imod:    Soil model type (1=VG, 2=tabular, etc.)
!   - iactab:  Actual number of table entries
!   - iactyp:  Actual number of soil types
!   - iaceig:  Actual soil properties count
!   - th_pwp:  Permanent wilting point moisture [m³/m³]
!   - sattgr:  Saturation threshold [m³/m³]
!
! ORIGINAL: BODEN.inc, BDPAR.inc (Fortran 77 COMMON blocks)
! AUTHOR: CATFLOW Streamlined
! DATE: 2025-11-10
!===============================================================================
module soil_properties_module
    use constants_module, only: maxtab, maxeig, maxtyp
    implicit none

    ! Soil parameters (maxeig soil types, various parameters per type)
    real(8), allocatable :: bodpar(:,:)      ! Soil parameters
    character(len=20), allocatable :: boden(:)  ! Soil type names

    ! Tabulated properties
    real(8), allocatable :: s_tab(:,:,:)     ! Hydraulic property tables
    integer(4) :: iactab                     ! Actual table entries

    ! Soil characteristics
    real(8), allocatable :: anisot(:)        ! Anisotropy ratio Kh/Kv
    real(8), allocatable :: snull(:)         ! Residual moisture content
    real(8), allocatable :: th_pwp(:)        ! Permanent wilting point
    real(8), allocatable :: sattgr(:)        ! Saturation threshold

    ! Model type indicators
    integer(4), allocatable :: imod(:)       ! Soil model type
    integer(4) :: iactyp                     ! Actual number of types
    integer(4) :: iaceig                     ! Actual properties count
    integer(4) :: maxeig_loc                 ! Local copy for allocation

contains

    subroutine allocate_soil_properties(neig)
        integer(4), intent(in) :: neig
        integer(4) :: ntab

        iactyp = neig
        iaceig = neig
        maxeig_loc = neig
        ntab = maxtab
        iactab = 100  ! Default, will be set during input

        allocate(bodpar(neig, 20))
        allocate(boden(neig))
        allocate(s_tab(ntab, 5, neig))
        allocate(anisot(neig))
        allocate(snull(neig))
        allocate(th_pwp(neig))
        allocate(sattgr(neig))
        allocate(imod(neig))

        ! Initialize
        bodpar = 0.0d0
        boden = ''
        s_tab = 0.0d0
        anisot = 1.0d0
        snull = 0.0d0
        th_pwp = 0.0d0
        sattgr = 1.0d0
        imod = 1
    end subroutine allocate_soil_properties

    subroutine deallocate_soil_properties()
        if (allocated(bodpar))  deallocate(bodpar)
        if (allocated(boden))   deallocate(boden)
        if (allocated(s_tab))   deallocate(s_tab)
        if (allocated(anisot))  deallocate(anisot)
        if (allocated(snull))   deallocate(snull)
        if (allocated(th_pwp))  deallocate(th_pwp)
        if (allocated(sattgr))  deallocate(sattgr)
        if (allocated(imod))    deallocate(imod)
    end subroutine deallocate_soil_properties

end module soil_properties_module
