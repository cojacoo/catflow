!===============================================================================
! MODULE: hg_module
!
! PURPOSE:
!   Main time integration loop for CATFLOW - the heart of the model
!   Controls adaptive time stepping, solver selection, and subsystem integration
!   Modernized version of HG.f using Fortran 90 modules
!
! DESCRIPTION:
!   This is THE MOST CRITICAL SUBROUTINE in CATFLOW. It orchestrates:
!
!   1. ADAPTIVE TIME STEPPING
!      - Dynamic dt adjustment based on convergence (rel_ab)
!      - Picard iteration count monitoring (n_it vs n_gr)
!      - Time step histogramming for analysis
!      - Minimum time step enforcement (dt_min)
!      - Maximum time step limitation (dt_mak for macropore CFL)
!
!   2. SOLVER METHOD SELECTION
!      Via meth parameter (character*3):
!      - 'adi': ADI (Alternating Direction Implicit)
!      - 'apk': ADI with predictor-corrector
!      - 'bcg': Biconjugate gradient solver
!      - 'pic': Picard iteration with CG
!      - 'mix': Mixed ADI + Picard
!
!   3. CONVERGENCE CHECKING
!      - rel_ab: Relative-absolute change metric
!      - Threshold: rel_ab < 0.5 triggers retry
!      - abbruch flag: Signals solver failure
!      - Adaptive retry: divide dt by 5 (first) or 10 (subsequent)
!
!   4. PRINT TIME SYNCHRONIZATION
!      - Monitors t_p(ip(ih),ih) array of output times
!      - Adjusts dt to hit print times exactly
!      - Writes results via wrres at print times
!      - Increments print counter ip(ih)
!
!   5. MASS BALANCE TRACKING
!      - stpbil: Step mass balance
!      - totbil: Total cumulative balance
!      - stpdif: Solution difference metric
!      - Balance components: biltot, bilrd, brfl_*, qosum, etc.
!
!   6. PARTICLE TRACKING INTEGRATION
!      Loop over istact species:
!      - v_strb: Interpolate velocity field to particle locations
!      - p_stepb: Advance particles via streamline tracking
!      - pmass: Update particle masses (decay, reactions)
!      - c_ipob: Calculate concentrations from particle distribution
!      - ptkinj2: Inject particles at upper boundary
!
!   7. SURFACE FLOW COUPLING
!      - updyo: Update surface water depth yo
!      - Handles runoff generation and routing
!      - Only if lland .and. lpob(ih) flags set
!
!   8. EVAPOTRANSPIRATION
!      - etintz: Integrate ET over time step
!      - Updates sink terms for transpiration
!      - Coupled with surface processes
!
!   9. DATE/TIME MANAGEMENT
!      - dsps2ds: Date string plus seconds conversion
!      - ds2diny: Date string to day-in-year
!      - itag, stunde: Day and hour for diurnal cycles
!
!  10. STATE MANAGEMENT
!      - Save old state: phialt, yo_alt, iz_alt, th_alt
!      - Advance new state: phineu, yoben, interz, theta
!      - Velocity history: vx_sta, ve_sta, qxalt, qealt
!      - Midpoint values: th_mit, yo_mit
!
! ALGORITHM FLOW:
!
!   INITIALIZATION (before label 500):
!   - Copy current state to old state arrays
!   - Update K(φ) and C(φ) from pressure heads
!   - Calculate mean water contents
!   - Save midpoint values from previous step
!   - Check if approaching print time
!   - Calculate date/time for interval midpoint
!
!   LOCAL TIME LOOP (label 500):
!   1. Initialize iteration counters (n_it, n_cg, rsq)
!   2. Integrate ET sinks if land surface (etintz)
!   3. SOLVER DISPATCH:
!      - Select method via meth string
!      - Call appropriate solver (adistp, apk, bcg, pic, mix)
!      - Solver updates phineu (pressure head)
!      - Returns convergence info (n_it, n_cg, rsq, rbchg)
!   4. Update K(φ) and C(φ) from new phineu
!   5. Calculate solution change metric (stpdif -> rel_ab)
!
!   CONVERGENCE DECISION:
!   6a. IF rel_ab < 0.5 OR abbruch:
!       - Solution failed convergence criteria
!       - Restore old state: phialt -> phineu
!       - Restore boundary state: yo_alt -> yoben
!       - Reload velocity field (loadvz)
!       - Reduce time step:
!         * First failure: dt = max(dt/5, dt_min)
!         * Subsequent: dt = max(dt/10, dt_min)
!       - Reset lerst flag
!       - GOTO 500 (retry with smaller dt)
!
!   6b. ELSE (success):
!       - PARTICLE TRACKING:
!         * Inject particles at boundary (ptkinj2)
!         * Save old fluxes: qxalt, qealt
!         * Calculate new fluxes: cal_q
!         * Save old gradients: gtxalt, gtealt
!         * Save old velocities: vx_sta, ve_sta
!         * Loop over species (istp = 1, istact):
!           + Interpolate velocity (v_strb)
!           + Advance particles (p_stepb)
!           + Update masses (pmass)
!           + Calculate concentrations (c_ipob)
!
!       - MASS BALANCE:
!         * Calculate step balance (stpbil)
!         * Save state for next step: phineu -> phialt
!         * Save boundary state: yoben -> yo_alt
!         * Save velocity field (savevz)
!         * Save water contents: theta -> th_alt
!         * Update midpoint arrays: th_mit, yo_mit
!
!       - SURFACE FLOW:
!         * Update surface water (updyo) if land surface
!
!       - TIME INCREMENT:
!         * Advance time: t_act = t_act + dt
!         * Increment step counter: izaehl(ih)
!         * Calculate total balance (totbil)
!
!       - OUTPUT:
!         * Print step summary (if iacnh <= ihgr)
!         * Check for print time: |t_act - t_p| < 0.001
!         * If print time:
!           + Calculate runoff coefficient
!           + Write balance file (io(3))
!           + Write results (wrres)
!           + Increment print counter: ip(ih)
!
!       - TIME STEP STATISTICS:
!         * Update histogram arrays (class, cltim)
!         * Bin dt into size classes (clgr array)
!
!       - NEXT TIME STEP CALCULATION:
!         * IF rel_ab < 1:
!           + Reduce: dt = max(rel_ab^2 * dt, 0.5*dt, dt_min)
!           + Further reduce if n_it > n_gr
!         * ELSE:
!           + IF n_it > n_gr: reduce based on iterations
!           + ELSE: increase: dt = min((1+rel_ab)/2 * dt, 1.5*dt, dt_mak)
!
!   7. Check for print time approach: adjust dt if needed
!   8. Check for section end: if t_act >= t_neu, GOTO 900
!   9. Check for section boundary: adjust dt if crossing t_neu
!  10. Sanity check: dt > 0
!  11. Calculate date/time for next interval midpoint
!  12. GOTO 500 (next time step)
!
!   EXIT (label 900):
!   - Final sanity check: dt > 0
!   - Return to caller
!
! CRITICAL FEATURES:
!
!   TIME STEP RETRY MECHANISM:
!   - First failure (lerst=.true.): dt/5
!   - Subsequent failures: dt/10
!   - Enforces dt >= dt_min
!   - State rollback: restore phialt, yo_alt, iz_alt
!   - Velocity rollback: loadvz
!
!   PRINT TIME SYNCHRONIZATION:
!   - Before solve: if t_act+dt >= t_p: dt = t_p - t_act
!   - After success: if |t_act - t_p| < 0.001: output and increment ip
!   - After time step calc: recheck t_act+dt >= t_p
!   - Ensures output at EXACT requested times
!
!   SECTION BOUNDARY HANDLING:
!   - If t_act >= t_neu - 1e-10: end section
!   - If t_act+dt > t_neu: save dt to dts, set dt = t_neu - t_act
!   - Ensures smooth transitions between input sections
!
!   DATE/TIME CONVERSIONS:
!   - dstrs: Reference date string
!   - t_act: Elapsed seconds since reference
!   - datstr: Current date string (interval midpoint)
!   - itag: Day of year (integer)
!   - stunde: Hour of day (real)
!   - Used for diurnal cycles in boundary conditions
!
! PHYSICS PRESERVATION:
!   ALL numerical logic preserved EXACTLY from original:
!   - Time step adaptation formulae
!   - Convergence thresholds (0.5 for rel_ab)
!   - Retry strategy (dt/5 vs dt/10)
!   - Balance calculations
!   - Particle tracking sequence
!   - Output synchronization
!   - Histogram binning
!
! VALIDATION REQUIREMENTS:
!   1. Time step sequence: Identical to original for same inputs
!   2. Mass balance: Check biltot ≈ 0 for conservative problems
!   3. Print times: Verify output at exact requested times
!   4. Convergence: Monitor rel_ab, n_it, rsq distributions
!   5. Histogram: Compare class counts with original
!   6. Particle tracking: Verify concentration fields match
!   7. Surface flow: Check qosum, yo evolution
!   8. ET: Verify bintz, bevapo, btrans
!
! ERROR HANDLING:
!   - Stop if meth not recognized
!   - Stop if dt <= 0 (two checks: during loop, at exit)
!   - Warning if rel_ab < 0.5 or abbruch
!   - Convergence messages include ih, t_act, rsq, rel_ab
!
! OUTPUT:
!   - Log file io(1): Step summary, convergence warnings
!   - Screen (*): Same as log (if iacnh <= ihgr)
!   - Balance file io(3): At print times, detailed mass balance
!   - Result files: Via wrres at print times
!
! PERFORMANCE CONSIDERATIONS:
!   - Most time spent in solver calls (adistp, bcg, pic, etc.)
!   - Particle tracking can be expensive for many particles
!   - Balance calculations are relatively cheap
!   - Time step adaptation is critical for efficiency
!
! SUBROUTINE HIERARCHY:
!   hg (this routine)
!   ├── Solver selection (one of):
!   │   ├── adistp: ADI method
!   │   ├── apkstp: ADI predictor-corrector
!   │   ├── bcgstp: Biconjugate gradient
!   │   └── piccg:  Picard iteration with CG
!   ├── State management:
!   │   ├── hgcopy: Copy 2D arrays
!   │   ├── obcopy: Copy 1D boundary arrays
!   │   ├── kc_phi: Update K(φ) and C(φ)
!   │   ├── mtheta: Mean water content
!   │   ├── loadvz: Load velocity field
!   │   └── savevz: Save velocity field
!   ├── Particle tracking:
!   │   ├── ptkinj2: Inject particles
!   │   ├── v_strb:  Interpolate velocity
!   │   ├── p_stepb: Advance particles
!   │   ├── pmass:   Update masses
!   │   └── c_ipob:  Calculate concentrations
!   ├── Flux calculations:
!   │   └── cal_q:   Calculate fluxes from heads
!   ├── Mass balance:
!   │   ├── stpbil:  Step balance
!   │   ├── totbil:  Total balance
!   │   └── stpdif:  Solution difference
!   ├── Surface flow:
!   │   └── updyo:   Update surface water depth
!   ├── Evapotranspiration:
!   │   └── etintz:  Integrate ET over dt
!   ├── Date/time:
!   │   ├── dsps2ds: Date string + seconds
!   │   └── ds2diny: Date string to day-in-year
!   └── Output:
!       └── wrres:   Write results
!
! ORIGINAL: HG.f (Fortran 77 with includes)
! AUTHOR: CATFLOW Streamlined
! DATE: 2025-11-07
!===============================================================================
module hg_module
    use constants_module, only: maxnv, maxnl, maxnh
    implicit none
    private

    public :: hg

contains

    !===========================================================================
    ! SUBROUTINE: hg
    !
    ! PURPOSE: Main time integration subroutine for hillslope hydrology
    !
    ! DESCRIPTION:
    !   Controls the time stepping loop for one hillslope over one input section.
    !   Integrates from t_act to t_neu using adaptive time stepping.
    !
    ! ARGUMENTS:
    !   ih   - Hillslope index [1..iacnh]
    !   dt   - Initial/suggested time step [s] (modified during execution)
    !   meth - Solution method: 'adi', 'apk', 'bcg', 'pic', 'mix'
    !
    ! EXTERNAL STATE (via modules):
    !   INPUT:
    !   - t_act:      Current simulation time [s]
    !   - t_neu:      End time of current section [s]
    !   - t_p:        Array of print times [s]
    !   - ip:         Print time index
    !   - phialt:     Pressure head at start of step [m]
    !   - yo_alt:     Surface water depth at start [m]
    !   - iz_alt:     Interface depths at start [m]
    !   - dt_min:     Minimum allowed time step [s]
    !   - dt_mak:     Maximum time step (CFL for macropores) [s]
    !   - n_gr:       Picard iteration threshold
    !   - it_max:     Maximum Picard iterations
    !   - piceps:     Picard convergence tolerance [m]
    !   - istact:     Number of solute species
    !   - lland:      Land surface flag
    !   - lpob:       Surface water flag for hillslope
    !
    !   OUTPUT:
    !   - phineu:     Updated pressure head [m]
    !   - yoben:      Updated surface water depth [m]
    !   - interz:     Updated interface depths [m]
    !   - theta:      Updated water content [-]
    !   - t_act:      Advanced simulation time [s]
    !   - ip:         Incremented print counter
    !   - izaehl:     Incremented step counter
    !   - biltot:     Total mass balance [m³]
    !   - class:      Time step histogram bins
    !   - cltim:      Time in each histogram bin
    !
    ! EXTERNAL CALLS:
    !   State management:
    !   - hgcopy:   Copy 2D hillslope arrays
    !   - obcopy:   Copy 1D boundary arrays
    !   - kc_phi:   Update K and C from phi
    !   - mtheta:   Calculate mean theta
    !   - loadvz:   Load velocity field
    !   - savevz:   Save velocity field
    !   - gl_copy:  Copy velocity arrays
    !
    !   Solvers (from steps_module):
    !   - adistp:   ADI solver
    !   - apkstp:   ADI predictor-corrector
    !   - bcgstp:   Biconjugate gradient
    !   - piccg:    Picard + CG
    !
    !   Mass balance:
    !   - stpbil:   Step mass balance
    !   - totbil:   Total mass balance
    !   - stpdif:   Calculate rel_ab metric
    !
    !   Particle tracking:
    !   - ptkinj2:  Inject particles at boundary
    !   - v_strb:   Interpolate velocity field
    !   - p_stepb:  Step particles
    !   - pmass:    Update particle masses
    !   - c_ipob:   Calculate concentrations
    !
    !   Flux and surface:
    !   - cal_q:    Calculate fluxes
    !   - updyo:    Update surface water depth
    !   - etintz:   Integrate evapotranspiration
    !
    !   Time and output:
    !   - dsps2ds:  Date string plus seconds
    !   - ds2diny:  Date string to day-in-year
    !   - wrres:    Write results
    !
    ! ALGORITHM:
    !   1. Initialize: copy old state, update K and C
    !   2. Time loop (label 500):
    !      a. Call solver (method-dependent)
    !      b. Check convergence (rel_ab, abbruch)
    !      c. If failed: restore state, reduce dt, retry
    !      d. If success: particle tracking, balance, advance time
    !      e. Adapt dt based on convergence quality
    !      f. Check for print time or section end
    !      g. Loop to next step
    !   3. Exit (label 900)
    !
    ! NOTES:
    !   - This routine modifies dt dynamically
    !   - Uses goto for time loop control (labels 500, 900)
    !   - All format statements preserved from original
    !   - Comment "jw" indicates Jan Wienhöfer notes
    !===========================================================================
    subroutine hg(ih, dt, meth)
        use constants_module, only: io, io_log, it_max, piceps, n_gr, iacgr
        use state_data_module, only: phineu, phialt, theta, th_alt, th_mit, &
                                      yo_mit, interz, iz_alt, yoben, yo_alt, &
                                      q_xsi, q_eta, qxalt, qealt, &
                                      gtxact, gtxalt, gteact, gtealt, &
                                      vx_st, vx_sta, ve_st, ve_sta
        use mesh_geometry_module, only: iaccv, iacnh, ihgr
        use time_module, only: t_act, t_neu, t_p, ip, it_p, dstrs, itag, stunde, &
                                dt_min, dt_mak, izaehl, class, cltim, clgr
        use boundary_conditions_module, only: lland, lpob
        use particle_module, only: istact
        use balance_module, only: biltot, bilanz, bilin, bsenk, bilrd, &
                                   brfl_o, brfl_r, brfl_u, brfl_l, &
                                   qosum, bnied, bnied2, bintz, bevapo, btrans, &
                                   bm_l, bm_u, bm_r
        use hillslope_data_module, only: hangnr
        use steps_module, only: adistp, apkstp, bcgstp, piccg
        implicit none

        ! Arguments
        integer(4), intent(in)    :: ih
        real(8),    intent(inout) :: dt
        character(*), intent(in)  :: meth

        ! Local variables
        integer(4) :: i, icv, istp
        integer(4) :: n_it, n_cg
        real(8) :: rel_ab
        real(8) :: dts
        real(8) :: rsq, rcoeff
        logical :: abbruch, rbchg, lerst
        character(22) :: datstr
        real :: tagnr, tagstd

        ! External subroutines not yet modularized
        external :: stpbil, totbil, stpdif, hgcopy, obcopy
        external :: kc_phi
        external :: wrres
        external :: dsps2ds
        external :: ds2diny
        external :: mtheta
        external :: cal_q
        external :: loadvz, savevz
        external :: updyo, etintz
        external :: v_strb, ptkinj2
        external :: p_stepb, pmass
        external :: c_ipob, gl_copy

        ! Intrinsic functions
        intrinsic :: abs, max, min, dble

        ! ===================================================================
        ! INITIALIZATION - Prepare for time integration
        ! ===================================================================

        abbruch = .false.
        lerst = .true.

        ! Copy current state to old state arrays
        call hgcopy(phialt(1,1,ih), phineu, ih)
        call obcopy(yo_alt(1,ih), yoben, ih)
        ! ### hier wird yoben auf yo_alt(1,ih) gesetzt
        call obcopy(iz_alt(1,ih), interz, ih)

        ! Update hydraulic properties from pressure head
        call kc_phi(phialt(1,1,ih), ih)

        ! Save water content
        call hgcopy(theta, th_alt, ih)
        call mtheta(ih)

        ! Update midpoint arrays from previous step
        do icv = 1, iaccv(ih)
            th_mit(icv,1,ih) = th_mit(icv,2,ih)
        end do
        yo_mit(1,ih) = yo_mit(2,ih)

        dts = 0.0d0

        ! Test for print times - adjust dt if approaching output time
        if (t_act + dt .ge. t_p(ip(ih),ih)) then
            dt = (t_p(ip(ih),ih) - t_act)
        endif

        ! Date string plus seconds to date string (interval midpoint)
        call dsps2ds(dstrs, t_act + dt/2.0d0, datstr)
        ! Date string to day in year
        call ds2diny(datstr, tagnr, tagstd)
        itag = dble(tagnr)
        stunde = dble(tagstd)

        ! ===================================================================
        ! LOCAL TIME LOOP - Adaptive time stepping
        ! ===================================================================
  500   continue

            n_it = 0
            n_cg = 0
            rsq = 0.0d0

            ! Integrate ET sinks if land surface
            if (lland .and. lpob(ih)) call etintz(ih, dt)

            ! ===============================================================
            ! SOLVER DISPATCH - Select and call appropriate solver
            ! ===============================================================
            if (meth .eq. 'adi') then
                call adistp(ih, dt, rbchg)
            elseif (meth .eq. 'apk') then
                call apkstp(ih, dt, rbchg)
            elseif (meth .eq. 'bcg') then
                call bcgstp(ih, dt, n_cg, rbchg)
            elseif (meth .eq. 'pic') then
                call piccg(ih, dt, dt_min, abbruch, n_it, n_cg, rsq)
            elseif (meth .eq. 'mix') then
                call adistp(ih, dt, rbchg)
                call piccg(ih, dt, dt_min, abbruch, n_it, n_cg, rsq)
            else
                stop 'Hangberechnungsmethode unbekannt (HG)'
            endif

            ! Update hydraulic properties from new solution
            call kc_phi(phineu, ih)

            ! Calculate solution change metric
            call stpdif(ih, rel_ab)

            ! ===============================================================
            ! TIME STEP CONTROL - Check convergence and decide next action
            ! ===============================================================

            ! Minimum time step reached but still not converged
            if ((dt .le. dt_min) .and. (.not. lerst)) then
                write(io(1),313) ih, t_act/86400.0d0, rsq
                write(*,313) ih, t_act/86400.0d0, rsq
  313           format('Genauigkeit nicht erreicht: Hang ',i3, &
                        ', Zeit ',f6.2,' Tage, rsq ',e12.4)
                rel_ab = 1.0d0
                abbruch = .false.
            endif

            ! ===============================================================
            ! CONVERGENCE CHECK
            ! ===============================================================
            if (rel_ab .lt. 0.5d0 .or. abbruch) then
                ! -----------------------------------------------------------
                ! CONVERGENCE FAILED - Retry with smaller time step
                ! -----------------------------------------------------------
                write(io(1),314) ih, t_act/86400.0d0, rsq, rel_ab
  314           format('Genauigkeit nicht erreicht: Hang ',i3, &
                        ', Zeit ',f6.2,' Tage, rsq, rel_ab ',2e12.4)
                write(io(1),*) 'abbruch=', abbruch

                ! Restore old state
                call kc_phi(phialt(1,1,ih), ih)
                call hgcopy(phialt(1,1,ih), phineu, ih)
                call obcopy(yo_alt(1,ih), yoben, ih)
                ! ### hier wird yoben auf yo_alt gesetzt
                call obcopy(iz_alt(1,ih), interz, ih)
                call loadvz(ih)

                ! Reduce time step adaptively
                if (lerst) then
                    dt = max(dt/5.0d0, dt_min)
                    lerst = .false.
                else
                    dt = max(dt/10.0d0, dt_min)
                endif
                abbruch = .false.

            else
                ! -----------------------------------------------------------
                ! CONVERGENCE SUCCESS - Proceed with next time step
                ! -----------------------------------------------------------
                ! Preparation for next time step
                lerst = .true.

                ! ===========================================================
                ! PARTICLE TRACKING - Input with mathematical boundary flux
                ! ===========================================================

                ! Inject particles at upper boundary
                call ptkinj2(ih, dt, t_act)

                ! Save old fluxes and calculate new fluxes
                call hgcopy(q_xsi, qxalt, ih)
                call hgcopy(q_eta, qealt, ih)
                call cal_q(ih)

                ! Save old gradients
                call hgcopy(gtxact, gtxalt, ih)
                call hgcopy(gteact, gtealt, ih)

                ! Save old velocities
                call gl_copy(vx_st, vx_sta, ih)
                call gl_copy(ve_st, ve_sta, ih)

                ! Loop over solute species
                do istp = 1, istact
                    ! Interpolate velocity field
                    call v_strb(istp, ih, dt)
                    ! Particle step
                    call p_stepb(istp, dt, ih)
                    ! Particle mass
                    call pmass(istp, t_act, ih)
                    ! Calculate concentrations
                    call c_ipob(istp, ih)
                end do

                ! ===========================================================
                ! MASS BALANCE AND STATE UPDATE
                ! ===========================================================

                call stpbil(ih, dt)

                ! Save new state as old state for next step
                call hgcopy(phineu, phialt(1,1,ih), ih)
                call obcopy(yoben, yo_alt(1,ih), ih)
                ! ... hier wird yo_alt auf yoben gesetzt
                call obcopy(interz, iz_alt(1,ih), ih)
                call savevz(ih)
                call hgcopy(theta, th_alt, ih)

                ! Update midpoint arrays
                do icv = 1, iaccv(ih)
                    th_mit(icv,1,ih) = th_mit(icv,2,ih)
                end do

                ! ===========================================================
                ! SURFACE FLOW UPDATE
                ! ===========================================================
                if (lland .and. lpob(ih)) call updyo(ih, dt, it_p(ip(ih),ih))
                yo_mit(1,ih) = yo_mit(2,ih)

                ! ===========================================================
                ! TIME INCREMENT
                ! ===========================================================
                t_act = t_act + dt

                izaehl(ih) = izaehl(ih) + 1
                call totbil(ih, istact)

                ! ===========================================================
                ! OUTPUT - Step summary
                ! ===========================================================
                if (iacnh .le. ihgr) then
                    if (io_log(1) .gt. 0) then
                        write(io(1),1500) hangnr(ih), izaehl(ih), t_act/86400.0d0, dt, &
                                          biltot(1,ih), bilanz(1), rel_ab, n_cg, n_it, rsq
                    endif
                    write(*,1500) hangnr(ih), izaehl(ih), t_act/86400.0d0, dt, &
                                  biltot(1,ih), bilanz(1), rel_ab, n_cg, n_it, rsq
                endif
 1500           format(i3,i6,f10.5,f8.1,e11.3,e11.3,f7.2,i4,i3,1x,e9.3)

                ! ===========================================================
                ! PRINT TIME OUTPUT - Write results if at output time
                ! ===========================================================
                if (abs(t_act - t_p(ip(ih),ih)) .lt. 0.001d0) then
                    ! Calculate runoff coefficient
                    if (qosum(ih) .gt. 0.0d0 .and. bnied(1,ih) .gt. 0.0d0) then
                        rcoeff = qosum(ih) / bnied(1,ih)
                    else
                        rcoeff = 0.0d0
                    endif

                    ! Write to balance file
                    write(io(3),1600) hangnr(ih),';', izaehl(ih),';', t_act,';', &
                        biltot(1,ih),';', bilin(1,ih),';', -bsenk(1,ih),';', &
                        bilrd(1,ih),';', -brfl_o(1,ih),';', -brfl_r(1,ih), ';', &
                        brfl_u(1,ih), ';', brfl_l(1,ih),';', qosum(ih),';', rcoeff, &
                        ';', bnied(1,ih),';', bnied2(1,ih),';', bintz(1,ih), ';', &
                        bevapo(1,ih),';', btrans(1,ih),';', (bm_l(istp,ih),';', &
                        bm_u(istp,ih),';', bm_r(istp,ih),';', istp=1,istact)

1600                format(i3,a1,i6,a1,f18.6,a1,8(f18.6,a1),f18.6,a1,f12.4, &
                            a1,14(f18.6,a1))

                    call wrres(t_p(ip(ih),ih), it_p(ip(ih),ih), ih)
                    ip(ih) = ip(ih) + 1
                endif

                ! ===========================================================
                ! TIME STEP STATISTICS - Histogram for analysis
                ! ===========================================================
                if (dt .le. clgr(1)) then
                    class(1) = class(1) + 1
                    cltim(1) = cltim(1) + dt
                endif
                do i = 2, iacgr
                    if ((dt .gt. clgr(i-1)) .and. (dt .le. clgr(i))) then
                        class(i) = class(i) + 1
                        cltim(i) = cltim(i) + dt
                    endif
                end do
                if (dt .gt. clgr(iacgr)) then
                    class(iacgr+1) = class(iacgr+1) + 1
                    cltim(iacgr+1) = cltim(iacgr+1) + dt
                endif
                if (izaehl(ih) .eq. 15) then
                    rel_ab = rel_ab
                    ! jw - WOZU?
                endif

                ! ===========================================================
                ! NEXT TIME STEP CALCULATION - Adaptive sizing
                ! ===========================================================
                if (rel_ab .lt. 1.0d0) then
                    ! Reduction based on REL_AB
                    dt = max(rel_ab*rel_ab*dt, 0.5d0*dt, dt_min)
                    if (n_it .gt. n_gr) then
                        ! Further reduction based on Picard iterations
                        dt = dt * (1.0d0 - dble(n_it - n_gr) / dble(it_max))
                    endif
                else
                    if (n_it .gt. n_gr) then
                        ! Reduction based on Picard iterations
                        dt = dt * (1.0d0 - dble(n_it - n_gr) / dble(it_max))
                    else
                        ! Increase based on REL_AB,
                        ! CFL criterion in case of macropore flow
                        dt = min((1.0d0 + rel_ab)/2.0d0 * dt, 1.5d0*dt, dt_mak)
                    endif
                endif
            endif
            ! End of convergence check

        ! ===================================================================
        ! TIME LOOP CONTINUATION CHECKS
        ! ===================================================================

        ! Test for print times - adjust dt if approaching output time
        if (t_act + dt .ge. t_p(ip(ih),ih)) then
            dt = (t_p(ip(ih),ih) - t_act)
        endif

        ! Section end?
        if (t_act .ge. t_neu - 1.0d-10) then
            t_act = t_neu
            dt = max(dts, dt)
            goto 900
        endif

        ! New time step beyond section end?
        if (t_act + dt .gt. t_neu) then
            dts = dt
            dt = t_neu - t_act
        endif

        ! Sanity check
        if (dt .le. 0.0d0) then
            stop 'dt < 0 in HG 1'
        endif

        ! Date string plus seconds to date string (interval midpoint)
        call dsps2ds(dstrs, t_act + dt/2.0d0, datstr)
        ! Date string to day in year
        call ds2diny(datstr, tagnr, tagstd)
        itag = dble(tagnr)
        stunde = dble(tagstd)

        goto 500
        ! ^------------- Loop back to label 500

        ! ===================================================================
        ! EXIT POINT
        ! ===================================================================
  900   continue

        ! Final sanity check
        if (dt .le. 0.0d0) then
            stop 'dt < 0 in HG 2'
        endif

        return
    end subroutine hg

end module hg_module
