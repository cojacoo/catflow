!===============================================================================
! MODULE: state_data_module
!
! PURPOSE: Manage all time-dependent state variables for CATFLOW
!          Replaces hgvari.inc from original Fortran 77 code
!          Uses ALLOCATABLE arrays for dynamic memory management
!
! AUTHOR: Streamlined from CATFLOW original (Zehe et al.)
! DATE: 2025-11-06
!===============================================================================
module state_data_module
    use constants_module, only: maxnv, maxnl, maxnh, maxcv
    implicit none

    private
    ! Make specific items public
    public :: allocate_state, deallocate_state, swap_state
    public :: Fx_p1, Fx_00, Fx_m1, Fe_p1, Fe_00, Fe_m1, RS, vorfak
    public :: A_x, A_e, A2x, A2e
    public :: psi_old, psi_new, psi, theta, theta_old
    public :: durchl, wasska, diffus, mak_an
    public :: senk, sueb
    public :: q_eta, q_xsi
    public :: yoben, yo_alt, hwsp, lrill, q, qomax, qosum, qssum
    public :: bilanz, th_mit, yo_mit
    public :: vrfl_u, vrfl_o, vrfl_r, vrfl_l, vsenk, vsueb
    public :: vueb_u, vueb_o, vueb_r, vueb_l
    public :: vnied, vnied2, vintz, vevapo, vtrans
    public :: brfl_u, brfl_o, brfl_r, brfl_l, bsenk, bsueb
    public :: bueb_u, bueb_o, bueb_r, bueb_l
    public :: bnied, bnied2, bintz, bevapo, btrans
    public :: volrd, bilrd, volin, bilin, biltot
    public :: rfl_u, rfl_o, rfl_r, rfl_l
    public :: ueb_u, ueb_o, ueb_r, ueb_l
    public :: tabpos, bm_l, bm_u, bm_r
    public :: lwriten, lwriteq, lwrites, lw1st, lw11st, ih1st

    !---------------------------------------------------------------------------
    ! NUMERICAL SCHEME COEFFICIENTS
    !---------------------------------------------------------------------------
    real(8), allocatable :: Fx_p1(:,:)      ! Coefficient xsi+1
    real(8), allocatable :: Fx_00(:,:)      ! Coefficient xsi
    real(8), allocatable :: Fx_m1(:,:)      ! Coefficient xsi-1
    real(8), allocatable :: Fe_p1(:,:)      ! Coefficient eta+1
    real(8), allocatable :: Fe_00(:,:)      ! Coefficient eta
    real(8), allocatable :: Fe_m1(:,:)      ! Coefficient eta-1
    real(8), allocatable :: RS(:,:)         ! Right-hand side
    real(8), allocatable :: vorfak(:,:)     ! Prefactor for time stepping

    ! Flux coefficients
    real(8), allocatable :: A_x(:,:)        ! xsi-direction conductivity
    real(8), allocatable :: A_e(:,:)        ! eta-direction conductivity
    real(8), allocatable :: A2x(:,:)        ! xsi-direction cross term
    real(8), allocatable :: A2e(:,:)        ! eta-direction cross term

    !---------------------------------------------------------------------------
    ! STATE VARIABLES - STREAMLINED APPROACH
    ! Use only two time levels instead of three (old, new)
    ! Swap pointers instead of copying arrays
    !---------------------------------------------------------------------------
    real(8), allocatable, target :: psi_old(:,:)        ! Previous timestep pressure head
    real(8), allocatable, target :: psi_new(:,:)        ! Current timestep pressure head
    real(8), pointer             :: psi(:,:)            ! Pointer to current state

    real(8), allocatable, target :: theta_target_old(:,:)   ! Old water content (target for swap)
    real(8), allocatable, target :: theta_target_new(:,:)   ! New water content (target for swap)
    real(8), pointer             :: theta(:,:)              ! Current water content pointer
    real(8), pointer             :: theta_old(:,:)          ! Old water content pointer

    ! Initial conditions (saved separately, deallocated after startup if not needed)
    real(8), allocatable :: psi_init(:,:)               ! Initial pressure head
    real(8), allocatable :: theta_init(:,:)             ! Initial water content

    ! Soil hydraulic properties (at current state)
    real(8), allocatable :: durchl(:,:)                 ! Hydraulic conductivity
    real(8), allocatable :: wasska(:,:)                 ! Water capacity C = dθ/dψ
    real(8), allocatable :: diffus(:,:)                 ! Diffusivity
    logical, allocatable :: mak_an(:,:)                 ! Macropore active flag

    ! Position in soil hydraulic lookup table
    integer, allocatable :: tabpos(:,:,:)               ! (maxnv, maxnl, maxnh)

    !---------------------------------------------------------------------------
    ! SINK/SOURCE TERMS
    !---------------------------------------------------------------------------
    real(8), allocatable :: senk(:,:)                   ! Sink term [1/s]
    real(8), allocatable :: sueb(:,:)                   ! Excess term [1/s]

    !---------------------------------------------------------------------------
    ! DARCY FLUXES
    !---------------------------------------------------------------------------
    real(8), allocatable :: q_eta(:,:)                  ! Flux in eta direction
    real(8), allocatable :: q_xsi(:,:)                  ! Flux in xsi direction

    !---------------------------------------------------------------------------
    ! SURFACE WATER
    !---------------------------------------------------------------------------
    real(8), allocatable :: yoben(:)                    ! Surface water depth (vertical) [m]
    real(8), allocatable :: yo_alt(:,:)                 ! Old surface water depth
    real(8), allocatable :: hwsp(:)                     ! Water level at hillfoot
    real(8), allocatable :: q(:,:)                      ! Runoff at each surface node
    real(8), allocatable :: qomax(:)                    ! Max runoff since start
    real(8), allocatable :: qosum(:), qssum(:)          ! Cumulative surface/subsurface runoff
    logical, allocatable :: lrill(:,:)                  ! Rill flow flag
    logical, allocatable :: lw1st(:)                    ! First output flag

    ! Surface output control flags
    logical :: lwriten, lwriteq, lwrites, lw11st
    integer :: ih1st

    !---------------------------------------------------------------------------
    ! BOUNDARY FLUXES (INSTANTANEOUS)
    !---------------------------------------------------------------------------
    real(8), allocatable :: rfl_u(:)                    ! Upper boundary flux
    real(8), allocatable :: rfl_o(:)                    ! Surface boundary flux
    real(8), allocatable :: rfl_r(:)                    ! Right boundary flux
    real(8), allocatable :: rfl_l(:)                    ! Left boundary flux

    real(8), allocatable :: ueb_u(:)                    ! Upper boundary excess
    real(8), allocatable :: ueb_o(:)                    ! Surface boundary excess
    real(8), allocatable :: ueb_r(:)                    ! Right boundary excess
    real(8), allocatable :: ueb_l(:)                    ! Left boundary excess

    !---------------------------------------------------------------------------
    ! WATER BALANCE - INCREMENTAL (PER TIMESTEP)
    !---------------------------------------------------------------------------
    real(8), allocatable :: bilanz(:)                   ! Total balance per timestep
    real(8), allocatable :: vrfl_u(:), vrfl_o(:)       ! Boundary fluxes [m³]
    real(8), allocatable :: vrfl_r(:), vrfl_l(:)
    real(8), allocatable :: vueb_u(:), vueb_o(:)       ! Excess fluxes [m³]
    real(8), allocatable :: vueb_r(:), vueb_l(:)
    real(8), allocatable :: vsenk(:), vsueb(:)         ! Sink/source [m³]
    real(8), allocatable :: vnied(:), vnied2(:)        ! Precipitation [m³]
    real(8), allocatable :: vintz(:)                    ! Interception [m³]
    real(8), allocatable :: vevapo(:), vtrans(:)       ! Evaporation, transpiration [m³]
    real(8), allocatable :: volrd(:)                    ! Boundary flux total
    real(8), allocatable :: volin(:)                    ! Storage change

    !---------------------------------------------------------------------------
    ! WATER BALANCE - CUMULATIVE (SINCE START)
    !---------------------------------------------------------------------------
    real(8), allocatable :: brfl_u(:,:), brfl_o(:,:)   ! (maxcv, maxnh)
    real(8), allocatable :: brfl_r(:,:), brfl_l(:,:)
    real(8), allocatable :: bueb_u(:), bueb_o(:)       ! (maxnh)
    real(8), allocatable :: bueb_r(:), bueb_l(:)
    real(8), allocatable :: bsenk(:,:), bsueb(:,:)     ! (maxcv, maxnh)
    real(8), allocatable :: bnied(:,:), bnied2(:,:)
    real(8), allocatable :: bintz(:,:)
    real(8), allocatable :: bevapo(:,:), btrans(:,:)
    real(8), allocatable :: bilrd(:,:)                  ! Cumulative boundary flux
    real(8), allocatable :: bilin(:,:)                  ! Cumulative storage change
    real(8), allocatable :: biltot(:,:)                 ! Total cumulative balance

    ! Particle mass loss across boundaries
    real(8), allocatable :: bm_l(:,:), bm_u(:,:), bm_r(:,:)  ! (maxstt, maxnh)

    ! Mean values for control volumes
    real(8), allocatable :: th_mit(:,:,:)               ! (maxcv, 2, maxnh)
    real(8), allocatable :: yo_mit(:,:)                 ! (2, maxnh)

contains

    !===========================================================================
    ! SUBROUTINE: allocate_state
    !
    ! PURPOSE: Allocate all state arrays based on actual grid dimensions
    !          This replaces static allocation at compile time
    !===========================================================================
    subroutine allocate_state(nv, nl, nh)
        implicit none
        integer, intent(in) :: nv, nl, nh
        integer :: stat

        print *, 'Allocating state arrays...'
        print *, '  Grid: ', nv, ' x ', nl, ' x ', nh

        ! Coefficients
        allocate(Fx_p1(nv,nl), Fx_00(nv,nl), Fx_m1(nv,nl), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate Fx arrays'

        allocate(Fe_p1(nv,nl), Fe_00(nv,nl), Fe_m1(nv,nl), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate Fe arrays'

        allocate(RS(nv,nl), vorfak(nv,nl), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate RS/vorfak'

        allocate(A_x(nv,nl-1), A_e(nv-1,nl), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate A arrays'

        allocate(A2x(nv,nl-1), A2e(nv-1,nl), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate A2 arrays'

        ! State variables
        allocate(psi_old(nv,nl), psi_new(nv,nl), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate psi arrays'

        allocate(theta_target_new(nv,nl), theta_target_old(nv,nl), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate theta arrays'

        ! Point theta pointers to targets
        theta => theta_target_new
        theta_old => theta_target_old

        allocate(psi_init(nv,nl), theta_init(nv,nl), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate init arrays'

        ! Point psi to psi_new initially
        psi => psi_new

        ! Soil properties
        allocate(durchl(nv,nl), wasska(nv,nl), diffus(nv,nl), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate soil property arrays'

        allocate(mak_an(nv,nl), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate mak_an'

        allocate(tabpos(nv,nl,nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate tabpos'

        ! Sinks
        allocate(senk(nv,nl), sueb(nv,nl), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate sink arrays'

        ! Fluxes
        allocate(q_eta(nv,nl), q_xsi(nv,nl), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate flux arrays'

        ! Surface water
        allocate(yoben(nl), yo_alt(nl,nh), hwsp(nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate surface arrays'

        allocate(q(nl,nh), qomax(nh), qosum(nh), qssum(nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate runoff arrays'

        allocate(lrill(nl,nh), lw1st(nh), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate logical arrays'

        ! Boundary fluxes
        allocate(rfl_u(nl), rfl_o(nl), rfl_r(nv), rfl_l(nv), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate rfl arrays'

        allocate(ueb_u(nl), ueb_o(nl), ueb_r(nv), ueb_l(nv), stat=stat)
        if (stat /= 0) stop 'ERROR: Failed to allocate ueb arrays'

        ! Balance - incremental
        allocate(bilanz(maxcv), stat=stat)
        allocate(vrfl_u(maxcv), vrfl_o(maxcv), vrfl_r(maxcv), vrfl_l(maxcv), stat=stat)
        allocate(vueb_u(maxcv), vueb_o(maxcv), vueb_r(maxcv), vueb_l(maxcv), stat=stat)
        allocate(vsenk(maxcv), vsueb(maxcv), stat=stat)
        allocate(vnied(maxcv), vnied2(maxcv), vintz(maxcv), stat=stat)
        allocate(vevapo(maxcv), vtrans(maxcv), stat=stat)
        allocate(volrd(maxcv), volin(maxcv), stat=stat)

        ! Balance - cumulative
        allocate(brfl_u(maxcv,nh), brfl_o(maxcv,nh), stat=stat)
        allocate(brfl_r(maxcv,nh), brfl_l(maxcv,nh), stat=stat)
        allocate(bueb_u(nh), bueb_o(nh), bueb_r(nh), bueb_l(nh), stat=stat)
        allocate(bsenk(maxcv,nh), bsueb(maxcv,nh), stat=stat)
        allocate(bnied(maxcv,nh), bnied2(maxcv,nh), bintz(maxcv,nh), stat=stat)
        allocate(bevapo(maxcv,nh), btrans(maxcv,nh), stat=stat)
        allocate(bilrd(maxcv,nh), bilin(maxcv,nh), biltot(maxcv,nh), stat=stat)

        ! Particle mass balance
        allocate(bm_l(3,nh), bm_u(3,nh), bm_r(3,nh), stat=stat)  ! maxstt = 3

        ! Mean values
        allocate(th_mit(maxcv,2,nh), yo_mit(2,nh), stat=stat)

        ! Initialize to zero
        call initialize_to_zero()

        print *, 'State arrays allocated successfully'
        print *, '  Memory estimate: ', (nv*nl*8*10)/1024/1024, ' MB'

    end subroutine allocate_state

    !===========================================================================
    ! SUBROUTINE: deallocate_state
    !
    ! PURPOSE: Deallocate all state arrays
    !===========================================================================
    subroutine deallocate_state()
        implicit none

        ! Nullify pointer before deallocation
        nullify(psi)

        if (allocated(Fx_p1))    deallocate(Fx_p1, Fx_00, Fx_m1)
        if (allocated(Fe_p1))    deallocate(Fe_p1, Fe_00, Fe_m1)
        if (allocated(RS))       deallocate(RS, vorfak)
        if (allocated(A_x))      deallocate(A_x, A_e, A2x, A2e)
        if (allocated(psi_old))  deallocate(psi_old, psi_new)
        if (allocated(theta_target_new))    deallocate(theta_target_new, theta_target_old)
        if (allocated(psi_init)) deallocate(psi_init, theta_init)
        if (allocated(durchl))   deallocate(durchl, wasska, diffus)
        if (allocated(mak_an))   deallocate(mak_an)
        if (allocated(tabpos))   deallocate(tabpos)
        if (allocated(senk))     deallocate(senk, sueb)
        if (allocated(q_eta))    deallocate(q_eta, q_xsi)
        if (allocated(yoben))    deallocate(yoben, yo_alt, hwsp)
        if (allocated(q))        deallocate(q, qomax, qosum, qssum)
        if (allocated(lrill))    deallocate(lrill, lw1st)
        if (allocated(rfl_u))    deallocate(rfl_u, rfl_o, rfl_r, rfl_l)
        if (allocated(ueb_u))    deallocate(ueb_u, ueb_o, ueb_r, ueb_l)

        print *, 'State arrays deallocated'

    end subroutine deallocate_state

    !===========================================================================
    ! SUBROUTINE: swap_state
    !
    ! PURPOSE: Swap old and new state using pointer reassignment (O(1) operation)
    !          This is MUCH faster than copying arrays
    !===========================================================================
    subroutine swap_state()
        implicit none
        real(8), pointer :: temp(:,:)

        ! Swap theta pointers (these are already pointers)
        temp => theta_old
        theta_old => theta
        theta => temp

        ! For psi, we do a simple copy for now (can be optimized to pointers later)
        psi_old = psi_new

        ! Update psi pointer to current state
        psi => psi_new

    end subroutine swap_state

    !===========================================================================
    ! SUBROUTINE: initialize_to_zero
    !
    ! PURPOSE: Initialize all arrays to zero
    !===========================================================================
    subroutine initialize_to_zero()
        implicit none

        Fx_p1 = 0.0d0; Fx_00 = 0.0d0; Fx_m1 = 0.0d0
        Fe_p1 = 0.0d0; Fe_00 = 0.0d0; Fe_m1 = 0.0d0
        RS = 0.0d0; vorfak = 0.0d0
        A_x = 0.0d0; A_e = 0.0d0; A2x = 0.0d0; A2e = 0.0d0

        psi_old = 0.0d0; psi_new = 0.0d0
        if (associated(theta)) theta = 0.0d0
        if (associated(theta_old)) theta_old = 0.0d0
        psi_init = 0.0d0; theta_init = 0.0d0

        durchl = 0.0d0; wasska = 0.0d0; diffus = 0.0d0
        mak_an = .false.
        tabpos = 1

        senk = 0.0d0; sueb = 0.0d0
        q_eta = 0.0d0; q_xsi = 0.0d0

        yoben = 0.0d0; yo_alt = 0.0d0; hwsp = 0.0d0
        q = 0.0d0; qomax = 0.0d0; qosum = 0.0d0; qssum = 0.0d0
        lrill = .false.; lw1st = .true.

        rfl_u = 0.0d0; rfl_o = 0.0d0; rfl_r = 0.0d0; rfl_l = 0.0d0
        ueb_u = 0.0d0; ueb_o = 0.0d0; ueb_r = 0.0d0; ueb_l = 0.0d0

        bilanz = 0.0d0
        vrfl_u = 0.0d0; vrfl_o = 0.0d0; vrfl_r = 0.0d0; vrfl_l = 0.0d0
        vueb_u = 0.0d0; vueb_o = 0.0d0; vueb_r = 0.0d0; vueb_l = 0.0d0
        vsenk = 0.0d0; vsueb = 0.0d0
        vnied = 0.0d0; vnied2 = 0.0d0; vintz = 0.0d0
        vevapo = 0.0d0; vtrans = 0.0d0
        volrd = 0.0d0; volin = 0.0d0

        brfl_u = 0.0d0; brfl_o = 0.0d0; brfl_r = 0.0d0; brfl_l = 0.0d0
        bueb_u = 0.0d0; bueb_o = 0.0d0; bueb_r = 0.0d0; bueb_l = 0.0d0
        bsenk = 0.0d0; bsueb = 0.0d0
        bnied = 0.0d0; bnied2 = 0.0d0; bintz = 0.0d0
        bevapo = 0.0d0; btrans = 0.0d0
        bilrd = 0.0d0; bilin = 0.0d0; biltot = 0.0d0

        bm_l = 0.0d0; bm_u = 0.0d0; bm_r = 0.0d0

        th_mit = 0.0d0; yo_mit = 0.0d0

        lwriten = .false.; lwriteq = .false.; lwrites = .false.
        lw11st = .true.; ih1st = 0

    end subroutine initialize_to_zero

end module state_data_module
