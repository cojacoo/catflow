!===============================================================================
! MODULE: rd_wr_module
!
! PURPOSE:
!   Results output generation for CATFLOW simulations
!   Modernized version of rd_wr.f using Fortran 90 modules
!
! DESCRIPTION:
!   This module handles writing simulation results to output files at
!   specified timesteps. It is CRITICAL for:
!
!   - Generating time series of state variables
!   - Saving spatial distributions for visualization
!   - Recording mass balances and fluxes
!   - Enabling post-processing and analysis
!
!   The wrres (write results) subroutine is called at each print time
!   specified in the simulation control file. It writes multiple output
!   files containing different aspects of the simulation state:
!
!   OUTPUT FILES (by io unit number):
!   =================================
!
!   io(4)  - Theta.out: Water content θ(x,z,t) [dimensionless]
!            Volumetric water content at each node
!            Range: θ_r to θ_s (residual to saturated)
!
!   io(5)  - Psi.out: Pressure head ψ(x,z,t) [m]
!            Soil water potential (negative = suction)
!            Range: 0 (saturated) to ~10^6 m (air dry)
!
!   io(7)  - q_xsi.out: Horizontal flux q_x(x,z,t) [m/s]
!            Darcy flux in xsi (downslope) direction
!
!   io(8)  - q_eta.out: Vertical flux q_z(x,z,t) [m/s]
!            Darcy flux in eta (depth) direction
!
!   io(9)  - Senk.out: Sink/source term S(x,z,t) [m³/s]
!            Water extraction (roots) or addition (injection)
!
!   io(13) - ve_st.out: Solute flux vertical [kg/m²/s]
!            Vertical transport of dissolved substances
!
!   io(14) - vx_st.out: Solute flux horizontal [kg/m²/s]
!            Horizontal transport of dissolved substances
!
!   io(15) - Konz.out: Concentration C(x,z,t) [mg/L or similar]
!            Dissolved solute concentration by species
!            Includes mass balance mp_bil for each species
!
!   io(18) - Sat.out: Relative saturation S_e(x,z,t) [dimensionless]
!            Effective saturation: (θ - θ_r)/(θ_s - θ_r)
!            Range: 0.0 (residual) to 1.0 (saturated)
!
!   FILE FORMAT:
!   ===========
!
!   Each output file follows the same structure:
!
!   Header line (written each time):
!   t_p   hangnr   iacnv   iacnl   [istact for concentration]
!
!   where:
!   - t_p: simulation time [seconds since start]
!   - hangnr: negative hillslope ID (-(1000 + hangnr))
!   - iacnv: number of nodes in vertical (eta) direction
!   - iacnl: number of nodes in horizontal (xsi) direction
!   - istact: number of solute species (concentration files only)
!
!   Data lines (2D array, written top to bottom):
!   Row 1 (iv=iacnv): values for all horizontal positions
!   Row 2 (iv=iacnv-1): ...
!   ...
!   Row iacnv (iv=1): values for all horizontal positions (bottom)
!
!   This ordering (top to bottom) matches:
!   - Visualization convention (surface at top)
!   - Physical intuition (gravity downward)
!   - Cross-section plotting
!
!   SELECTIVE OUTPUT:
!   ================
!
!   Not all files written every time. Control via io_log array:
!
!   io_log(n) = 0: Never write file n
!   io_log(n) = 1: Write file n at each print time
!
!   Exception: First output (it_p = 1) ALWAYS writes all files
!   to establish initial conditions.
!
!   This allows:
!   - Minimizing disk usage for large simulations
!   - Focusing on relevant variables
!   - Different output frequencies for different variables
!
!   RELATIVE SATURATION:
!   ===================
!
!   t_star = (θ - θ_r) / (θ_s - θ_r)
!
!   More intuitive than absolute θ because:
!   - Independent of soil type (normalized 0-1)
!   - Shows "fullness" of soil pore space
!   - Easier to interpret across heterogeneous domains
!   - Related to plant available water
!
!   SURFACE PONDING:
!   ===============
!
!   When surface is saturated (θ = θ_s at surface node) AND
!   infiltration capacity exceeded, water ponds on surface.
!
!   Surface pressure head adjusted:
!   psi(iacnv, il) = -yoben(il)
!
!   where yoben(il) is ponding depth [m] at horizontal position il.
!
!   Negative sign because:
!   - ψ = 0 at water table
!   - ψ < 0 in saturated zone below water table
!   - Surface ponding creates temporary "perched water table"
!
!   FLUX CLEANING:
!   =============
!
!   Very small fluxes (|q| < 10^-30) set to exactly zero.
!
!   Prevents:
!   - Numerical artifacts in output
!   - Misleading visualization (spurious tiny fluxes)
!   - Unnecessary precision in output files
!
!   Physical justification:
!   - 10^-30 m/s is ~10^-22 mm/year (utterly negligible)
!   - Well below any measurement precision
!   - Below roundoff significance
!
!   SOLUTE TRANSPORT OUTPUT:
!   =======================
!
!   For each species (istp = 1...istact):
!   1. Mass balance mp_bil(istp, ih) [kg total in domain]
!   2. Concentration field c_tact(istp, iv, il, ih) [mg/L]
!   3. Vertical flux ve_st(iv, il, ih) [kg/m²/s]
!   4. Horizontal flux vx_st(iv, il, ih) [kg/m²/s]
!
!   Mass balance tracks:
!   - Initial mass
!   - Inputs (boundaries, sources)
!   - Outputs (boundaries, sinks)
!   - Current mass in domain
!   - Conservation check (closure)
!
!   PERFORMANCE CONSIDERATIONS:
!   ==========================
!
!   Output generation is I/O intensive:
!   - Multiple large files written
!   - Hundreds to thousands of timesteps
!   - Potentially GB of data for long simulations
!
!   Optimization strategies:
!   - Selective output (io_log control)
!   - Binary format for large files (future)
!   - Compressed output (future)
!   - Parallel I/O for multi-hillslope (future)
!
!   Typical output sizes:
!   - Small hillslope (50×100): ~5 KB per file per timestep
!   - Large hillslope (200×500): ~200 KB per file per timestep
!   - Full simulation (1000 steps, 5 files): ~1-200 MB
!
! PUBLIC SUBROUTINES:
!   wrres - Write results at specified timestep
!
! EXTERNAL DEPENDENCIES:
!   constants_module: maxnv, maxnl
!   mesh_geometry_module: iacnv, iacnl, hangnr, iboden, area
!   state_variables_module: theta, psi, q_xsi, q_eta, senk, yoben
!   solute_transport_module: c_tact, ve_st, vx_st, mp_bil, istact
!   soil_properties_module: bodpar (θ_r, θ_s)
!   io_module: io, io_log (file units and control)
!
! VALIDATION REQUIREMENTS:
!
!   1. Mass balance closure:
!      - Verify total water mass conserved
!      - Check solute mass balance
!      - Confirm flux divergence = storage change
!
!   2. Output format consistency:
!      - Check header format (parsable by post-processing)
!      - Verify grid dimensions match geometry
!      - Ensure no NaN or Inf values
!
!   3. Physical bounds:
!      - θ_r ≤ θ ≤ θ_s for all nodes
!      - ψ ≥ 0 for unsaturated
!      - 0 ≤ S_e ≤ 1 (relative saturation)
!
!   4. File I/O correctness:
!      - Readable by visualization tools
!      - Time series continuity
!      - No corrupted writes
!
! USAGE PATTERNS:
!
!   Called from main time loop at each print time:
!   if (t_current >= t_p(ip, ih)) then
!       call wrres(t_p(ip, ih), ip, ih)
!       ip = ip + 1
!   end if
!
! PHYSICS PRESERVATION:
!   ALL operations preserved EXACTLY from original rd_wr.f:
!   - Output file formats
!   - Variable ordering (top to bottom)
!   - Header structure
!   - Flux cleaning threshold
!   - No algorithmic changes whatsoever
!
! ORIGINAL: rd_wr.f (Fortran 77 with includes)
! AUTHOR: CATFLOW Development Team
! CONVERTED: CATFLOW Streamlined
! DATE: 2025-11-09
!===============================================================================
module rd_wr_module
    use constants_module, only: maxnv, maxnl
    implicit none
    private

    ! Public subroutines
    public :: wrres

contains

    !===========================================================================
    ! SUBROUTINE: wrres
    !
    ! PURPOSE: Write simulation results to output files
    !
    ! DESCRIPTION:
    !   Main results output routine. Called at each specified print time to
    !   write current state variables, fluxes, and mass balances to formatted
    !   output files.
    !
    !   For each active output file (io_log(n) = 1), writes:
    !   1. Header line with timestamp and grid dimensions
    !   2. 2D field values (top to bottom, left to right)
    !
    !   Special handling:
    !   - First output (it_p = 1) always writes all files
    !   - Surface ponding adjusted in pressure head
    !   - Very small fluxes cleaned to zero
    !   - Relative saturation computed from θ, θ_r, θ_s
    !
    !   Output files managed by io_module:
    !   - io(n): file unit numbers
    !   - io_log(n): output control flags
    !
    ! ALGORITHM:
    !   1. Compute relative saturation t_star from theta
    !   2. Write headers for all active output files
    !   3. Adjust surface pressure head for ponding
    !   4. Clean very small fluxes to zero
    !   5. Write solute concentrations and mass balances (if active)
    !   6. Write 2D fields for all active variables
    !
    ! ARGUMENTS:
    !   t_p  - Print time [real(8), input]
    !          Time in seconds since simulation start
    !   it_p - Print index [integer(4), input]
    !          Sequential output number (1, 2, 3, ...)
    !   ih   - Hillslope index [integer(4), input]
    !          Which hillslope to output
    !
    ! USES:
    !   mesh_geometry_module: iacnv, iacnl, hangnr, iboden, area
    !   state_variables_module: theta, psi, q_xsi, q_eta, senk, yoben
    !   solute_transport_module: c_tact, ve_st, vx_st, mp_bil, istact
    !   soil_properties_module: bodpar
    !   io_module: io, io_log
    !
    ! NOTES:
    !   - hangnr written as -(1000 + hangnr(ih)) for identification
    !   - Arrays written in Fortran order (column-major)
    !   - Format codes allow up to 2000 nodes in horizontal direction
    !   - All files use formatted (ASCII) output for portability
    !
    ! PERFORMANCE:
    !   - I/O bound operation
    !   - Time scales with number of active files and grid size
    !   - Typical: milliseconds for small grids, seconds for large grids
    !   - Called O(100-1000) times per simulation
    !
    ! VALIDATION:
    !   - Check output files for correct dimensions
    !   - Verify time values monotonically increasing
    !   - Ensure physical bounds (θ, ψ, S_e) respected
    !   - Confirm mass balance closure for solutes
    !===========================================================================
    subroutine wrres(t_p, it_p, ih)
        use mesh_geometry_module, only: iacnv, iacnl, hangnr, iboden, area
        use state_variables_module, only: theta, psi, q_xsi, q_eta, senk, yoben
        use solute_transport_module, only: c_tact, ve_st, vx_st, mp_bil, istact
        use soil_properties_module, only: bodpar
        use io_module, only: io, io_log
        implicit none

        integer(4), intent(in) :: it_p, ih
        real(8),    intent(in) :: t_p

        integer(4) :: iv, il, istp, is
        real(8)    :: t_star(maxnv, maxnl)

        intrinsic :: abs

        ! Compute relative saturation: t_star = (θ - θ_r) / (θ_s - θ_r)
        do iv = iacnv(ih), 1, -1
            do il = 1, iacnl(ih)
                t_star(iv,il) = (theta(iv,il) - bodpar(3, iboden(iv,il,ih))) / &
                                (bodpar(2, iboden(iv,il,ih)) - bodpar(3, iboden(iv,il,ih)))
            end do
        end do

        ! Write headers for active output files
        ! Always write on first output (it_p = 1), otherwise check io_log

        ! Water content (theta)
        if ((io_log(4) == 1) .or. (it_p == 1)) then
            is = 1
            write(io(4), 504) t_p, -(1000 + hangnr(ih)), iacnv(ih), iacnl(ih)
        else
            is = 0
        end if

        ! Pressure head (psi)
        if ((io_log(5) == 1) .or. (it_p == 1)) then
            is = 1
            write(io(5), 505) t_p, -(1000 + hangnr(ih)), iacnv(ih), iacnl(ih)
        else
            is = 0
        end if

        ! Horizontal flux (q_xsi)
        if ((io_log(7) == 1) .or. (it_p == 1)) then
            is = 1
            write(io(7), 507) t_p, -(1000 + hangnr(ih)), iacnv(ih), iacnl(ih)
        else
            is = 0
        end if

        ! Vertical flux (q_eta)
        if ((io_log(8) == 1) .or. (it_p == 1)) then
            is = 1
            write(io(8), 508) t_p, -(1000 + hangnr(ih)), iacnv(ih), iacnl(ih)
        else
            is = 0
        end if

        ! Sink/source term
        if ((io_log(9) == 1) .or. (it_p == 1)) then
            is = 1
            write(io(9), 509) t_p, -(1000 + hangnr(ih)), iacnv(ih), iacnl(ih)
        else
            is = 0
        end if

        ! Vertical solute flux
        if ((io_log(13) == 1) .or. (it_p == 1)) then
            is = 1
            write(io(13), 513) t_p, -(1000 + hangnr(ih)), iacnv(ih), iacnl(ih)
        else
            is = 0
        end if

        ! Horizontal solute flux
        if ((io_log(14) == 1) .or. (it_p == 1)) then
            is = 1
            write(io(14), 514) t_p, -(1000 + hangnr(ih)), iacnv(ih), iacnl(ih)
        else
            is = 0
        end if

        ! Concentration (with number of species)
        if ((io_log(15) == 1) .or. (it_p == 1)) then
            is = 1
            write(io(15), 515) t_p, -(1000 + hangnr(ih)), &
                              iacnv(ih), iacnl(ih), istact
        else
            is = 0
        end if

        ! Relative saturation
        if ((io_log(18) == 1) .or. (it_p == 1)) then
            is = 1
            write(io(18), 514) t_p, -(1000 + hangnr(ih)), iacnv(ih), iacnl(ih)
        else
            is = 0
        end if

        ! Adjust surface pressure head for ponding
        ! Clean very small fluxes
        do il = 1, iacnl(ih)
            if (yoben(il) > 0.0d0) psi(iacnv(ih), il) = -yoben(il)

            do iv = 1, iacnv(ih)
                if (abs(q_xsi(iv,il)) < 1.0d-30) q_xsi(iv,il) = 0.0d0
                if (abs(q_eta(iv,il)) < 1.0d-30) q_eta(iv,il) = 0.0d0
            end do
        end do

        ! Write solute concentrations and mass balances (if solute transport active)
        if (istact > 0) then
            if ((io_log(15) == 1) .or. (it_p == 1)) then
                do istp = 1, istact
                    ! Mass balance for this species
                    write(io(15), *) mp_bil(istp, ih)

                    ! Concentration field (top to bottom)
                    do iv = iacnv(ih), 1, -1
                        write(io(15), 3000) (c_tact(istp,iv,il,ih), il=1, iacnl(ih))
                    end do
                end do
            end if
        end if

        ! Write 2D fields for all active variables (top to bottom)
        do iv = iacnv(ih), 1, -1
            ! Water content
            if ((io_log(4) == 1) .or. (it_p == 1)) &
                write(io(4), 1000) (theta(iv,il), il=1, iacnl(ih))

            ! Pressure head
            if ((io_log(5) == 1) .or. (it_p == 1)) &
                write(io(5), 2000) (psi(iv,il), il=1, iacnl(ih))

            ! Horizontal flux
            if ((io_log(7) == 1) .or. (it_p == 1)) &
                write(io(7), 3000) (q_xsi(iv,il), il=1, iacnl(ih))

            ! Vertical flux
            if ((io_log(8) == 1) .or. (it_p == 1)) &
                write(io(8), 3000) (q_eta(iv,il), il=1, iacnl(ih))

            ! Sink/source
            if ((io_log(9) == 1) .or. (it_p == 1)) &
                write(io(9), 3000) (senk(iv,il), il=1, iacnl(ih))

            ! Solute fluxes (if active)
            if (istact > 0) then
                if ((io_log(13) == 1) .or. (it_p == 1)) &
                    write(io(13), 3000) (ve_st(iv,il,ih), il=1, iacnl(ih))

                if ((io_log(14) == 1) .or. (it_p == 1)) &
                    write(io(14), 3000) (vx_st(iv,il,ih), il=1, iacnl(ih))
            end if

            ! Relative saturation
            if ((io_log(18) == 1) .or. (it_p == 1)) &
                write(io(18), 1000) (t_star(iv,il), il=1, iacnl(ih))
        end do

        return

        ! Format statements
504     format(f12.1, i6, 3i5)
505     format(f12.1, i6, 3i5)
507     format(f12.1, i6, 3i5)
508     format(f12.1, i6, 3i5)
509     format(f12.1, i6, 3i5)
513     format(f12.1, i6, 3i5)
514     format(f12.1, i6, 3i5)
515     format(f12.1, i6, 3i5)
1000    format(2000f8.3)
2000    format(2000e14.3E3)
3000    format(2000e12.3)

    end subroutine wrres

end module rd_wr_module
