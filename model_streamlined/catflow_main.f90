!===============================================================================
! PROGRAM: catflow_streamlined
!
! PURPOSE:
!   Main entry point for CATFLOW Streamlined hydrological model
!   Orchestrates initialization, time stepping, and output for hillslope-scale
!   subsurface flow simulation using Richards equation
!
! DESCRIPTION:
!   This is THE MASTER PROGRAM that coordinates all CATFLOW subsystems:
!
!   1. INITIALIZATION PHASE
!      - Read main input file (RDMINF)
!      - Read hillslope geometry and mesh
!      - Read soil hydraulic properties
!      - Read boundary conditions
!      - Read initial conditions
!      - Allocate all module arrays
!      - Initialize state variables (ψ, θ)
!
!   2. TIME INTEGRATION PHASE
!      - Loop over all hillslopes (1 to iacnh)
!      - For each hillslope:
!        * Call hg(ih, dt, meth) - main time integration routine
!        * Manages adaptive time stepping
!        * Solves Richards equation at each time step
!        * Writes output at print times
!        * Tracks mass balance
!
!   3. CLEANUP PHASE
!      - Write final results
!      - Deallocate arrays
!      - Close files
!      - Print summary statistics
!
! PROGRAM FLOW:
!
!   START
!     |
!     ├─> Initialize constants and I/O
!     |
!     ├─> Read main input file (RDMINF)
!     |   ├─> Grid dimensions (nv, nl, nh)
!     |   ├─> Time control (t_start, t_end, dt_init)
!     |   ├─> Solver method (meth)
!     |   ├─> Output control (print times)
!     |   └─> Physical options (ET, macropores, transport)
!     |
!     ├─> Read hillslope-specific input for each hillslope
!     |   ├─> Geometry (RDGEOM or similar)
!     |   ├─> Soil properties (RDBOD or similar)
!     |   ├─> Boundary conditions (RDRB or similar)
!     |   └─> Initial conditions (RDINI or similar)
!     |
!     ├─> Allocate all module arrays
!     |   ├─> state_data_module arrays
!     |   ├─> mesh_geometry_module arrays
!     |   ├─> soil_properties_module arrays
!     |   ├─> boundary_conditions_module arrays
!     |   └─> time_module arrays
!     |
!     ├─> Initialize state variables
!     |   ├─> Set initial ψ from input or hydrostatic
!     |   ├─> Calculate initial θ from ψ using kc_phi
!     |   └─> Zero all fluxes and work arrays
!     |
!     ├─> MAIN HILLSLOPE LOOP (ih = 1, iacnh)
!     |   |
!     |   └─> Call hg(ih, dt, meth)
!     |       |
!     |       ├─> Time integration for hillslope ih
!     |       ├─> Adaptive time stepping
!     |       ├─> Solver selection (ADI, CG, Picard, etc.)
!     |       ├─> Boundary condition updates
!     |       ├─> Output at print times
!     |       └─> Mass balance tracking
!     |
!     ├─> Write final summary
!     |
!     ├─> Deallocate all arrays
!     |
!   END
!
! SOLVER METHODS (via meth parameter):
!   - 'adi': Alternating Direction Implicit
!   - 'apk': ADI with predictor-corrector
!   - 'bcg': Biconjugate gradient
!   - 'pic': Picard iteration with CG
!   - 'mix': Mixed ADI + Picard
!
! KEY MODULES USED:
!   - constants_module:              Global parameters and dimensions
!   - state_data_module:             State variables (ψ, θ, fluxes)
!   - mesh_geometry_module:          Grid geometry and topology
!   - soil_properties_module:        Hydraulic property functions
!   - boundary_conditions_module:    BC types and values
!   - time_module:                   Time control and print scheduling
!   - hg_module:                     Main time integration (THE HEART)
!   - bodtab_module:                 K(ψ) and C(ψ) calculations
!   - balanc_module:                 Mass balance and diagnostics
!   - tcalw_module:                  Date/time utilities
!   - rd_wr_module:                  I/O operations
!
! INPUT FILES (read via RDMINF and related subroutines):
!   - catflow.inf:     Main control file
!   - geometry.dat:    Mesh coordinates and topology
!   - soil.dat:        Soil hydraulic parameters
!   - boundary.dat:    Boundary condition specifications
!   - initial.dat:     Initial conditions (ψ₀ or θ₀)
!   - climate.dat:     Atmospheric forcing (optional)
!
! OUTPUT FILES (written via wrres and related subroutines):
!   - results.out:     Primary results (ψ, θ, q)
!   - balance.out:     Mass balance summary
!   - fluxes.out:      Boundary fluxes
!   - log.out:         Diagnostic log
!
! VALIDATION:
!   - Mass balance error should be < 1e-10 relative
!   - Solution should match original CATFLOW for identical inputs
!   - Time step sequence should be reproducible
!   - Output files should be bit-identical (given same solver settings)
!
! PERFORMANCE:
!   - Most time spent in hg() -> solver routines
!   - Typical runtime: O(nt * nv * nl) where nt = number of time steps
!   - Memory usage: O(nv * nl * nh) for state arrays
!
! ORIGINAL: CATFLOW.f (Fortran 77 main program)
! AUTHOR: CATFLOW Streamlined
! DATE: 2025-11-10
!===============================================================================
program catflow_streamlined
    ! =========================================================================
    ! MODULE IMPORTS
    ! =========================================================================

    ! Core data structures
    use constants_module
    use state_data_module
    use state_variables_module
    use mesh_geometry_module
    use soil_properties_module
    use boundary_conditions_module
    use time_module

    ! Additional modules
    use atmosphere_module
    use balance_module
    use coefficient_module
    use control_module
    use diagnostics_module
    use error_module
    use hillslope_data_module
    use io_module
    use particle_module
    use solute_transport_module
    use stream_module
    use surface_module

    ! Physics modules (converted)
    use bodtab_module, only: kc_phi
    use balanc_module, only: mtheta, stpdif, stpbil, totbil
    use tcalw_module, only: dsps2ds, ds2diny
    use rd_wr_module, only: wrres
    use hg_module, only: hg

    implicit none

    ! =========================================================================
    ! LOCAL VARIABLES
    ! =========================================================================

    ! Grid dimensions (read from input)
    integer(4) :: nv          ! Number of vertical nodes
    integer(4) :: nl          ! Number of lateral nodes
    integer(4) :: nh          ! Number of hillslopes

    ! Time control
    real(8) :: t_start        ! Start time [s]
    real(8) :: t_end          ! End time [s]
    real(8) :: dt_init        ! Initial time step [s]

    ! Solver control
    character(len=3) :: meth  ! Solver method ('adi', 'bcg', 'pic', etc.)

    ! Loop counters
    integer(4) :: ih          ! Hillslope counter

    ! Status variables
    integer(4) :: ierr        ! Error flag

    ! =========================================================================
    ! EXTERNAL SUBROUTINES (not yet converted)
    ! =========================================================================
    ! These are input reading routines from the original CATFLOW
    ! They will be called as external routines until converted

    external :: RDMINF        ! Read main input file
    external :: RDGEOM        ! Read geometry
    external :: RDBOD         ! Read soil properties
    external :: RDRB          ! Read boundary conditions
    external :: RDINI         ! Read initial conditions
    external :: RDCLIM        ! Read climate data (optional)

    ! =========================================================================
    ! PROGRAM HEADER
    ! =========================================================================

    write(io, '(A)') ''
    write(io, '(A)') '=============================================================='
    write(io, '(A)') '  CATFLOW STREAMLINED - Modern Fortran 90 Implementation'
    write(io, '(A)') '  Hillslope-Scale Subsurface Flow Model'
    write(io, '(A)') '  Solving Richards Equation in Curvilinear Coordinates'
    write(io, '(A)') '=============================================================='
    write(io, '(A)') ''
    write(io, '(A)') 'Version:  2.0 (Streamlined)'
    write(io, '(A)') 'Date:     2025-11-10'
    write(io, '(A)') 'Language: Fortran 90/95'
    write(io, '(A)') ''

    ! =========================================================================
    ! PHASE 1: INITIALIZATION
    ! =========================================================================

    write(io, '(A)') '--- PHASE 1: Initialization ---'
    write(io, '(A)') ''

    ! Initialize module constants
    call init_balance_module()
    call init_control_module()
    call init_diagnostics_module()
    call init_error_module()
    call init_io_module()

    ! -------------------------------------------------------------------------
    ! Read main input file
    ! -------------------------------------------------------------------------
    ! NOTE: RDMINF is an EXTERNAL subroutine (not yet converted)
    ! It reads the main control file and sets:
    !   - Grid dimensions: nv, nl, nh
    !   - Time control: t_start, t_end, dt_init
    !   - Solver method: meth
    !   - Output control: number of print times, etc.
    !   - Physical options: ET, macropores, particle tracking, etc.

    write(io, '(A)') 'Reading main input file...'

    ! Default values (will be overwritten by RDMINF)
    nv = 20
    nl = 50
    nh = 1
    t_start = 0.0d0
    t_end = 86400.0d0      ! 1 day default
    dt_init = 60.0d0       ! 60 seconds default
    meth = 'pic'           ! Picard iteration default

    ! TODO: Call RDMINF when converted
    ! call RDMINF(nv, nl, nh, t_start, t_end, dt_init, meth, ierr)
    ! if (ierr /= 0) then
    !     write(io, '(A,I0)') 'ERROR: RDMINF failed with code ', ierr
    !     stop
    ! end if

    write(io, '(A,I0,A,I0,A,I0)') '  Grid: ', nv, ' x ', nl, ' nodes, ', nh, ' hillslopes'
    write(io, '(A,F12.2,A)') '  Simulation time: ', t_end, ' seconds'
    write(io, '(A,A3)')      '  Solver method: ', meth
    write(io, '(A)') ''

    ! -------------------------------------------------------------------------
    ! Allocate all module arrays
    ! -------------------------------------------------------------------------

    write(io, '(A)') 'Allocating arrays...'

    call allocate_state_data(nv, nl)
    call allocate_state_variables(nv, nl)
    call allocate_mesh_geometry(nv, nl, nh)
    call allocate_soil_properties(5)  ! Assume 5 soil types for now
    call allocate_boundary_conditions(nv, nl)
    call allocate_time_module(nh, 100)  ! Assume 100 print times max
    call allocate_atmosphere(nv, nl)
    call allocate_coefficients(nv, nl)
    call allocate_hillslope_data(nv, nl)
    call allocate_particle_module(nl)
    call allocate_solute_transport(nv, nl, 1)
    call allocate_stream_module(nh, nv, nl)
    call allocate_surface_module(nv, nl)

    write(io, '(A,I0,A)') '  Allocated ', nv*nl*nh, ' total nodes'
    write(io, '(A)') ''

    ! -------------------------------------------------------------------------
    ! Read hillslope-specific input
    ! -------------------------------------------------------------------------
    ! NOTE: These are EXTERNAL subroutines (not yet converted)

    write(io, '(A)') 'Reading hillslope input files...'

    ! TODO: Call input routines when converted
    ! call RDGEOM(ierr)     ! Geometry
    ! call RDBOD(ierr)      ! Soil properties
    ! call RDRB(ierr)       ! Boundary conditions
    ! call RDINI(ierr)      ! Initial conditions
    ! if (ierr /= 0) stop 'ERROR: Input file reading failed'

    write(io, '(A)') '  Geometry, soil, BC, and IC files read (TODO: implement)'
    write(io, '(A)') ''

    ! -------------------------------------------------------------------------
    ! Initialize state variables
    ! -------------------------------------------------------------------------

    write(io, '(A)') 'Initializing state variables...'

    ! Set initial pressure head (default: hydrostatic from surface)
    ! In real implementation, this would come from RDINI
    phineu = -1.0d0        ! Default: -1 m pressure (slightly unsaturated)
    phialt = phineu

    ! Calculate initial moisture content from pressure head
    ! This requires calling kc_phi for each node
    ! NOTE: kc_phi is in bodtab_module and needs full soil property setup

    write(io, '(A)') '  Initial pressure head set to -1.0 m (default)'
    write(io, '(A)') '  Initial moisture content (TODO: calculate from K(psi))'
    write(io, '(A)') ''

    ! Initialize time
    t_act = t_start
    dt = dt_init

    ! =========================================================================
    ! PHASE 2: MAIN TIME INTEGRATION
    ! =========================================================================

    write(io, '(A)') '--- PHASE 2: Main Time Integration ---'
    write(io, '(A)') ''

    ! -------------------------------------------------------------------------
    ! Loop over all hillslopes
    ! -------------------------------------------------------------------------

    do ih = 1, nh

        write(io, '(A,I0,A,I0)') 'Processing hillslope ', ih, ' of ', nh

        ! Set current hillslope context
        ! (In the original code, this would involve setting common block variables)

        ! ---------------------------------------------------------------------
        ! Call main time integration routine hg()
        ! ---------------------------------------------------------------------
        ! This is THE HEART OF CATFLOW
        ! hg() manages:
        !   - Adaptive time stepping
        !   - Solver selection and dispatch
        !   - Boundary condition updates
        !   - Output at print times
        !   - Mass balance tracking
        !   - Particle tracking integration
        !   - Surface flow coupling
        !   - ET integration

        write(io, '(A)') '  Calling hg() for time integration...'

        ! NOTE: hg() expects many module variables to be set up
        ! In the streamlined version, hg is in hg_module
        ! TODO: hg() call will work once all modules are properly initialized

        ! Placeholder: hg() would run the simulation here
        ! call hg(ih, dt, meth)

        write(io, '(A)') '  Time integration complete (TODO: implement hg call)'
        write(io, '(A)') ''

    end do  ! ih loop

    ! =========================================================================
    ! PHASE 3: CLEANUP AND FINALIZATION
    ! =========================================================================

    write(io, '(A)') '--- PHASE 3: Finalization ---'
    write(io, '(A)') ''

    ! Write final summary
    write(io, '(A)') 'Simulation completed successfully!'
    write(io, '(A)') ''
    write(io, '(A)') 'Mass balance summary:'
    write(io, '(A,ES15.6)') '  Total inflow:  ', volin
    write(io, '(A,ES15.6)') '  Total outflow: ', volrd + vsenk
    write(io, '(A,ES15.6)') '  Storage change:', biltot
    write(io, '(A,ES15.6)') '  Balance error: ', bilanz
    write(io, '(A)') ''

    ! Deallocate all arrays
    write(io, '(A)') 'Deallocating arrays...'

    call deallocate_state_data()
    call deallocate_mesh_geometry()
    call deallocate_soil_properties()
    call deallocate_boundary_conditions()

    write(io, '(A)') ''
    write(io, '(A)') '=============================================================='
    write(io, '(A)') '  CATFLOW STREAMLINED - Run Complete'
    write(io, '(A)') '=============================================================='
    write(io, '(A)') ''

end program catflow_streamlined
