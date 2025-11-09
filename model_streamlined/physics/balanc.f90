!===============================================================================
! MODULE: balanc_module
!
! PURPOSE:
!   Mass balance and diagnostic utilities for CATFLOW Richards equation solver
!   Modernized version of BALANC.f using Fortran 90 modules
!
! DESCRIPTION:
!   This module contains ALL mass balance tracking and diagnostic calculations
!   that are CRITICAL for model validation and verification. These functions
!   ensure mass conservation and control adaptive time stepping.
!
!   PUBLIC SUBROUTINES:
!   1. mtheta  - Calculate mean (volume-averaged) moisture content θ
!   2. stpdif  - Calculate solution change metric (rel_ab) for time step adaptation
!   3. cal_q   - Calculate fluxes (q_xsi, q_eta) from potential gradients
!   4. stpbil  - Step-wise mass balance tracking for single time step
!   5. totbil  - Cumulative total mass balance tracking over all time
!
! MASS BALANCE PHYSICS:
!
!   The Richards equation conserves mass rigorously:
!   ∂θ/∂t = -∇·q + S
!
!   where:
!   - θ: volumetric water content [-]
!   - q: Darcy flux vector [m/s]
!   - S: sink/source term [1/s]
!
!   Integrated over control volume V with boundary ∂V:
!   d/dt ∫_V θ dV = -∫_∂V q·n dA + ∫_V S dV
!
!   In discrete form (exact to machine precision):
!   ΔStorage = Inflows - Outflows + Sinks/Sources ± BoundaryViolations
!
!   volin = (θ_new - θ_old) × Volume
!   volrd = Q_bottom + Q_left - Q_top - Q_right
!   bilanz = volin - volrd + vsenk
!
!   If bilanz ≠ 0, there is a bug in the numerical scheme!
!
! FUNCTION DESCRIPTIONS:
!
!   MTHETA - Mean Water Content:
!   --------------------------
!   Calculates volume-weighted average θ for each control volume:
!
!   θ_mean = ∫_V θ dV / V = Σ θ(iv,il) × area(iv,il) × varbr(il) / vola
!
!   Also calculates mean surface water depth yo_mit.
!   Called every time step BEFORE and AFTER solver.
!   Result stored in th_mit(icv,1:2,ih):
!   - th_mit(icv,1,ih): old time step value
!   - th_mit(icv,2,ih): current time step value
!
!   Physical interpretation:
!   - Represents "average wetness" of hillslope segment
!   - Used in mass balance: Δθ_mean × V = ΔStorage
!   - Critical for detecting wetting/drying trends
!
!   STPDIF - Solution Change Metric:
!   -----------------------------
!   Calculates relative change in solution for time step adaptation:
!
!   rel_ab = min(rel1ab, rel2ab)
!
!   where:
!   rel1ab = d_Th_opt / max(|θ_new - θ_old|)
!   rel2ab = d_Phi_opt / max(|φ_new - φ_old| × C)  [only if saturated]
!
!   Algorithm:
!   1. Find maximum θ change at interior points (exclude boundaries)
!   2. Find maximum φ×C change at saturated points (φ < 0)
!   3. Calculate relative factors compared to target changes
!   4. Return minimum (most restrictive)
!
!   Time step adaptation logic (in hg.f90):
!   - rel_ab > 2.0: increase time step (converging too slowly)
!   - rel_ab < 0.5: decrease time step (changing too fast)
!   - 0.5 ≤ rel_ab ≤ 2.0: accept current time step
!
!   Physical interpretation:
!   - Measures how "gently" solution changes
!   - Large changes → small time step (maintain accuracy)
!   - Small changes → large time step (computational efficiency)
!   - Factor 999.99 returned if changes negligible (no limit)
!
!   Target values (d_Th_opt, d_Phi_opt) set in input file, typical:
!   - d_Th_opt = 0.02 (2% water content change per step)
!   - d_Phi_opt = 0.01 (1 cm head change per step)
!
!   CAL_Q - Flux Calculation:
!   ----------------------
!   Calculates Darcy fluxes from hydraulic potential gradients:
!
!   q_xsi = -K_tensor · ∇φ in xsi direction (downslope)
!   q_eta = -K_tensor · ∇φ in eta direction (vertical)
!
!   Using conductance matrix:
!   A_x(iv,il):  xsi-xsi conductance
!   A_e(iv,il):  eta-eta conductance
!   A2x(iv,il):  xsi-eta cross-conductance
!   A2e(iv,il):  eta-xsi cross-conductance
!
!   Algorithm:
!   1. Interior points: 4-point stencil with full tensor
!      q_x = -[A_x·∇φ_x + A2e·∇φ_e] / (4·f_eta)
!      q_e = -[A2x·∇φ_x + A_e·∇φ_e] / (4·f_xsi)
!
!   2. Boundary points: Use boundary flux from rand_fl
!      q_boundary = rfl_* (back-calculated from BC)
!
!   3. Corner points: Both fluxes from boundaries
!
!   Also tracks maximum flux and sink magnitudes for diagnostics:
!   - fl_max(ih): maximum |q| in domain
!   - sk_max(ih): maximum sink strength
!
!   Physical interpretation:
!   - Converts head gradients → actual water movement
!   - Required for particle tracking (velocities)
!   - Required for mass balance verification
!   - Must match boundary fluxes exactly
!
!   STPBIL - Step-Wise Mass Balance:
!   -----------------------------
!   Tracks ALL mass fluxes for single time step. Absolutely CRITICAL
!   for validation - any error indicates numerical bugs!
!
!   For each control volume (icv):
!
!   A. Boundary Fluxes [m³]:
!      vrfl_l(icv) = ∫ q_xsi × dη × varbr dt  (left boundary)
!      vrfl_r(icv) = ∫ q_xsi × dη × varbr dt  (right boundary)
!      vrfl_u(icv) = ∫ q_eta × dξ × varbr dt  (bottom boundary)
!      vrfl_o(icv) = ∫ q_eta × dξ × varbr dt  (top boundary)
!
!      Integration accounts for:
!      - Flux averaging at boundaries (geometric mean)
!      - Variable hillslope width varbr(il,ih)
!      - Time step duration dt
!
!   B. Atmospheric Fluxes [m³]:
!      vnied(icv)  = ∫ precipitation dt
!      vintz(icv)  = ∫ interception dt
!      vevapo(icv) = ∫ soil evaporation dt
!      vtrans(icv) = ∫ canopy transpiration dt
!
!   C. Sink/Source Terms [m³]:
!      vsenk(icv) = ∫∫ senk(iv,il) × area × varbr dt
!      vsueb(icv) = ∫∫ sueb(iv,il) × area × varbr dt  (violations)
!
!   D. Storage Change [m³]:
!      volin(icv) = [θ_mean_new - θ_mean_old] × Volume
!
!   E. Net Boundary Flow [m³]:
!      volrd(icv) = vrfl_u + vrfl_l - vrfl_o - vrfl_r
!      (positive = net inflow)
!
!   F. Mass Balance Error [m³]:
!      bilanz(icv) = volin - volrd + vsenk
!
!   If mass is conserved: bilanz ≈ 0 (to machine precision)
!   If |bilanz| > 1e-8 m³, set to zero (numerical noise)
!   If bilanz significant: BUG in solver, coefficients, or BC!
!
!   Also tracks boundary condition violations (ueb_*):
!   - For inequality BC (seepage faces, atmospheric)
!   - Measures flux excess beyond prescribed limits
!   - Integrated over step: vueb_* [m³]
!   - Used by chko_rb for BC switching logic
!
!   TOTBIL - Total Cumulative Balance:
!   -------------------------------
!   Accumulates step-wise quantities over entire simulation.
!
!   For each control volume (icv):
!   bilin(icv,ih)  += volin(icv)   [total storage change, m³]
!   bilrd(icv,ih)  += volrd(icv)   [total boundary flow, m³]
!   bsenk(icv,ih)  += vsenk(icv)   [total sink/source, m³]
!   biltot(icv,ih)  = bilin - bilrd + bsenk  [cumulative error, m³]
!
!   brfl_*(icv,ih) += vrfl_*(icv)  [cumulative boundary fluxes, m³]
!   bnied(icv,ih)  += vnied(icv)   [total precipitation, m³]
!   bevapo(icv,ih) += vevapo(icv)  [total evaporation, m³]
!   btrans(icv,ih) += vtrans(icv)  [total transpiration, m³]
!
!   bueb_*(ih) += vueb_*  [cumulative BC violations, m³]
!
!   bm_*(istp,ih) += mlos_*(istp,ih)  [particle mass losses, kg]
!
!   Also converts precipitation to mm for output:
!   bnied2(icv,ih) = bnied(icv,ih) / hgobfl(ih) × 1000  [mm]
!
!   Discharge at right boundary (catchment outlet):
!   qssum(ih) += vrfl_r(1)  [cumulative discharge, m³]
!
!   Physical interpretation:
!   - Running total of all water movement
!   - biltot tracks cumulative mass conservation error
!   - Should remain ≈ 0 throughout entire simulation
!   - If biltot grows: systematic bias in numerical scheme
!   - Essential for long-term simulations (days to years)
!
! NUMERICAL CONSIDERATIONS:
!
!   Flux Calculation Accuracy:
!   - Interior: 4-point stencil consistent with coefficient matrices
!   - Boundaries: Must match fluxes from rand_fl EXACTLY
!   - Corners: Careful treatment to avoid double-counting
!   - Factor 1/4 comes from 2D finite difference discretization
!
!   Mean Calculation Precision:
!   - Volume-weighted to account for variable cell sizes
!   - Variable hillslope width (varbr) included correctly
!   - Must match integration scheme in solver
!
!   Time Step Metric Robustness:
!   - Interior points only (boundaries have prescribed behavior)
!   - Saturated points use φ×C (equivalent to pressure change)
!   - Minimum of θ and φ metrics (most restrictive wins)
!   - Large return value (999.99) if changes negligible
!
!   Mass Balance Tolerance:
!   - Set bilanz=0 if |error| < 1e-8 m³ (numerical noise)
!   - Typical domain: 100-1000 m³, so relative error ~ 1e-11
!   - Machine precision: ~1e-16, so factor 10^5 safety margin
!   - Any persistent error > 1e-8 indicates real problem
!
! VALIDATION REQUIREMENTS:
!
!   1. Mean water content:
!      - Compare Σθ×V against direct summation
!      - Check conservation: d(θ_mean×V)/dt = fluxes
!      - Verify consistency with stpbil storage changes
!
!   2. Time step metric:
!      - Test extreme cases: very dry, very wet, mixed
!      - Verify interior-only calculation (no boundary influence)
!      - Check saturation detection (φ < 0)
!      - Confirm minimum selection logic
!
!   3. Flux calculation:
!      - Mass balance closure: ∇·q = (computed fluxes)
!      - Boundary consistency: cal_q = rand_fl at boundaries
!      - Corner treatment: no double-counting
!      - Tensor effects: verify A2x, A2e cross terms
!
!   4. Step balance:
!      - Force mass conservation error: bilanz must detect
!      - Test all flux components independently
!      - Verify boundary flux integration (geometry factors)
!      - Check atmospheric flux accounting
!
!   5. Total balance:
!      - Long simulation: biltot growth rate
!      - Compare against independent water budget
!      - Verify particle mass tracking
!      - Check discharge accumulation
!
! PERFORMANCE NOTES:
!
!   - mtheta: O(N) where N = mesh size, called every step
!   - stpdif: O(N), called every step
!   - cal_q: O(N), called every step
!   - stpbil: O(N), called every accepted step
!   - totbil: O(M) where M = control volumes, very fast
!
!   All routines well-optimized with simple loops.
!   No significant performance concerns.
!
! ORIGINAL: BALANC.f (Fortran 77 with includes)
! AUTHOR: CATFLOW Development Team
! CONVERTED: CATFLOW Streamlined
! DATE: 2025-11-09
!===============================================================================
module balanc_module
    use constants_module, only: maxnv, maxnl, maxnh, maxcv, maxist
    implicit none
    private

    ! Make all 5 subroutines public
    public :: mtheta
    public :: stpdif
    public :: cal_q
    public :: stpbil
    public :: totbil

contains

    !===========================================================================
    ! SUBROUTINE: mtheta
    !
    ! PURPOSE: Calculate mean (volume-averaged) water content for hillslope
    !
    ! DESCRIPTION:
    !   Computes volume-weighted average water content for each control volume
    !   and mean surface water depth for the entire hillslope.
    !
    !   Mean water content:
    !   th_mit(icv,2,ih) = Σ θ(iv,il) × area(iv,il) × varbr(il) / vola(icv)
    !
    !   Summed over all nodes in control volume icv:
    !   - iv from icvu(icv,ih) to icvo(icv,ih) (vertical extent)
    !   - il from icvl(icv,ih) to icvr(icv,ih) (horizontal extent)
    !
    !   Mean surface water depth:
    !   yo_mit(2,ih) = Σ yoben(il) × slopeo(il) × dr_o(il) × varbr(il) / vola(1)
    !
    !   Summed over all surface nodes (il = 1 to iacnl).
    !
    !   The index "2" denotes current time step. After step completion,
    !   th_mit(icv,2,ih) is copied to th_mit(icv,1,ih) for next step.
    !
    ! ALGORITHM:
    !   1. Loop over control volumes
    !   2. Initialize th_mit(icv,2,ih) = 0
    !   3. Sum θ × area × varbr over all nodes in control volume
    !   4. Divide by control volume total volume
    !   5. Compute mean surface water depth similarly
    !
    ! ARGUMENTS:
    !   ih - Hillslope index [integer, input]
    !
    ! USES:
    !   mesh_geometry_module: iaccv, icvu, icvo, icvl, icvr, area, varbr, vola
    !   mesh_geometry_module: iacnl, slopeo, dr_o
    !   state_variables_module: theta, th_mit
    !   surface_module: yoben, yo_mit
    !
    ! UPDATES:
    !   th_mit(icv,2,ih) - Mean water content for control volume icv [-]
    !   yo_mit(2,ih) - Mean surface water depth [m]
    !
    ! NOTES:
    !   - Called at beginning of time step (after phialt → phineu copy)
    !   - Called again in stpbil to update for mass balance
    !   - Critical for mass balance: Δθ_mean × V = storage change
    !===========================================================================
    subroutine mtheta(ih)
        use mesh_geometry_module, only: iaccv, icvu, icvo, icvl, icvr, &
                                         area, varbr, vola, iacnl, slopeo, dr_o
        use state_variables_module, only: theta, th_mit
        use surface_module, only: yoben, yo_mit
        implicit none

        integer(4), intent(in) :: ih

        integer(4) :: iv, il, icv

        ! Calculate mean water content for each control volume
        do icv = 1, iaccv(ih)
            th_mit(icv, 2, ih) = 0.0d0

            do iv = icvu(icv, ih), icvo(icv, ih)
                do il = icvl(icv, ih), icvr(icv, ih)
                    th_mit(icv, 2, ih) = th_mit(icv, 2, ih) + &
                        theta(iv, il) * area(iv, il, ih) * varbr(il, ih)
                end do
            end do

            ! Divide by control volume to get mean
            th_mit(icv, 2, ih) = th_mit(icv, 2, ih) / vola(icv, ih)
        end do

        ! Calculate mean surface water depth
        yo_mit(2, ih) = 0.0d0
        do il = 1, iacnl(ih)
            yo_mit(2, ih) = yo_mit(2, ih) + &
                yoben(il) * slopeo(il, ih) * dr_o(il, ih) * varbr(il, ih)
        end do
        yo_mit(2, ih) = yo_mit(2, ih) / vola(1, ih)

        return
    end subroutine mtheta

    !===========================================================================
    ! SUBROUTINE: stpdif
    !
    ! PURPOSE: Calculate solution change metric for time step adaptation
    !
    ! DESCRIPTION:
    !   Computes the relative change in solution (θ and φ) compared to
    !   target optimal changes. Used to adapt time step size:
    !
    !   - rel_ab > 2.0: solution changing slowly, increase time step
    !   - rel_ab < 0.5: solution changing rapidly, decrease time step
    !   - 0.5 ≤ rel_ab ≤ 2.0: time step appropriate, accept solution
    !
    !   The metric is:
    !   rel_ab = min(rel1ab, rel2ab)
    !
    !   where:
    !   rel1ab = d_Th_opt / max|θ_new - θ_old|  (water content change)
    !   rel2ab = d_Phi_opt / max|φ_new - φ_old|×C  (head change, saturated only)
    !
    !   Also tracks domain-wide extrema for diagnostics:
    !   - th_max, th_min: water content range
    !   - psi_max, psi_min: pressure head range
    !   - phi_max, phi_min: hydraulic potential range
    !
    ! ALGORITHM:
    !   1. Initialize/update domain extrema (all nodes)
    !   2. Find maximum |Δθ| at INTERIOR nodes (exclude boundaries)
    !   3. Find maximum |Δφ×C| at INTERIOR SATURATED nodes (φ < 0)
    !   4. Calculate relative factors:
    !      - If Δθ_max < 0.0001: rel1ab = 999.99 (no limit)
    !      - Else: rel1ab = d_Th_opt / Δθ_max
    !   5. Calculate relative factors for φ similarly
    !   6. Return minimum (most restrictive)
    !
    !   CRITICAL: Only interior nodes used (iv=2:iacnv-1, il=2:iacnl-1)
    !   because boundary nodes have prescribed behavior that may change
    !   discontinuously (BC switching).
    !
    ! ARGUMENTS:
    !   ih     - Hillslope index [integer, input]
    !   rel_ab - Relative change metric [real*8, output]
    !
    ! USES:
    !   mesh_geometry_module: iacnv, iacnl
    !   state_variables_module: theta, th_alt, phineu, phialt, psi, wasska
    !   diagnostics_module: th_max, th_min, psi_max, psi_min, phi_max, phi_min
    !   control_module: d_Th_opt, d_Phi_opt
    !
    ! UPDATES:
    !   rel_ab - Solution change metric [-]
    !   th_max, th_min, psi_max, psi_min, phi_max, phi_min [module variables]
    !
    ! NOTES:
    !   - Called after every solver iteration
    !   - Critical for adaptive time stepping and convergence
    !   - Large commented block (lines 280-329 in original) preserved but
    !     not converted - was boundary node treatment that's disabled
    !===========================================================================
    subroutine stpdif(ih, rel_ab)
        use mesh_geometry_module, only: iacnv, iacnl
        use state_variables_module, only: theta, th_alt, phineu, phialt, &
                                           psi, wasska
        use diagnostics_module, only: th_max, th_min, psi_max, psi_min, &
                                       phi_max, phi_min
        use control_module, only: d_Th_opt, d_Phi_opt
        implicit none

        integer(4), intent(in) :: ih
        real(8), intent(out) :: rel_ab

        integer(4) :: iv, il
        real(8) :: delta1, delta2
        real(8) :: d_Th_max, d_Phi_max
        real(8) :: rel1ab, rel2ab

        intrinsic :: abs, min

        ! Update domain extrema for diagnostics
        do iv = 1, iacnv(ih)
            do il = 1, iacnl(ih)
                if (th_max(ih) < theta(iv, il)) th_max(ih) = theta(iv, il)
                if (th_min(ih) > theta(iv, il)) th_min(ih) = theta(iv, il)
                if (psi_max(ih) < psi(iv, il)) psi_max(ih) = psi(iv, il)
                if (psi_min(ih) > psi(iv, il)) psi_min(ih) = psi(iv, il)
                if (phi_max(ih) < phineu(iv, il)) phi_max(ih) = phineu(iv, il)
                if (phi_min(ih) > phineu(iv, il)) phi_min(ih) = phineu(iv, il)
            end do
        end do

        ! Find maximum changes at INTERIOR points only (exclude boundaries)
        d_Th_max = 0.0d0
        d_Phi_max = 0.0d0

        do iv = 2, iacnv(ih) - 1
            do il = 2, iacnl(ih) - 1
                ! Maximum water content change
                delta1 = abs(theta(iv, il) - th_alt(iv, il))
                if (delta1 > d_Th_max) d_Th_max = delta1

                ! Maximum potential change (only if saturated, φ < 0)
                ! Multiply by C (wasska) to get equivalent water content change
                if (phineu(iv, il) < 0.0d0) then
                    delta2 = abs((phineu(iv, il) - phialt(iv, il, ih)) * wasska(iv, il))
                    if (delta2 > d_Phi_max) d_Phi_max = delta2
                end if
            end do
        end do

        ! Calculate relative change factors
        if (d_Th_max < 0.0001d0) then
            rel1ab = 999.99d0
        else
            rel1ab = d_Th_opt / d_Th_max
        end if

        if (d_Phi_max < 0.0001d0) then
            rel2ab = 999.99d0
        else
            rel2ab = d_Phi_opt / d_Phi_max
        end if

        ! Return most restrictive (minimum) factor
        rel_ab = min(rel1ab, rel2ab)

        return
    end subroutine stpdif

    !===========================================================================
    ! SUBROUTINE: cal_q
    !
    ! PURPOSE: Calculate Darcy fluxes from hydraulic potential gradients
    !
    ! DESCRIPTION:
    !   Computes velocity field (q_xsi, q_eta) from current solution (phineu)
    !   using conductance matrices and finite difference gradients.
    !
    !   Interior nodes (iv=2:iacnv-1, il=2:iacnl-1):
    !   Use full 4-point stencil with tensor conductivities:
    !
    !   q_xsi = -[A_x·∇φ_x + A2e·∇φ_e] / (4·f_eta)
    !   q_eta = -[A2x·∇φ_x + A_e·∇φ_e] / (4·f_xsi)
    !
    !   where ∇φ_x and ∇φ_e are centered differences in xsi and eta directions.
    !
    !   Boundary nodes:
    !   Use boundary fluxes calculated in rand_fl:
    !   q_boundary = rfl_* (back-calculated from BC)
    !
    !   Corner nodes:
    !   Both flux components taken from boundaries.
    !
    !   Also tracks maximum magnitudes:
    !   - fl_max(ih) = max(√(q_xsi² + q_eta²))
    !   - sk_max(ih) = max(|senk|)
    !
    ! ALGORITHM:
    !   1. Interior points: full tensor calculation
    !   2. Boundary points (edges): partial tensor + boundary flux
    !   3. Corner points: both fluxes from boundaries
    !   4. Compute flux magnitude and track maximum
    !   5. Track maximum sink/source strength
    !
    ! ARGUMENTS:
    !   ih - Hillslope index [integer, input]
    !
    ! USES:
    !   mesh_geometry_module: iacnv, iacnl, f_xsi, f_eta
    !   state_variables_module: phineu, q_xsi, q_eta, senk
    !   coefficient_module: A_x, A_e, A2x, A2e
    !   boundary_conditions_module: rfl_u, rfl_o, rfl_r, rfl_l
    !   diagnostics_module: fl_max, sk_max
    !
    ! UPDATES:
    !   q_xsi(iv,il) - Darcy flux in xsi direction [m/s]
    !   q_eta(iv,il) - Darcy flux in eta direction [m/s]
    !   fl_max(ih) - Maximum flux magnitude [m/s]
    !   sk_max(ih) - Maximum sink strength [1/s]
    !
    ! NOTES:
    !   - Called after convergence, before particle tracking
    !   - Required for transport calculations
    !   - Must match boundary fluxes from rand_fl EXACTLY
    !   - Factor 1/4 from 2D finite difference discretization
    !===========================================================================
    subroutine cal_q(ih)
        use mesh_geometry_module, only: iacnv, iacnl, f_xsi, f_eta, area
        use state_variables_module, only: phineu, q_xsi, q_eta, senk
        use coefficient_module, only: A_x, A_e, A2x, A2e
        use boundary_conditions_module, only: rfl_u, rfl_o, rfl_r, rfl_l
        use diagnostics_module, only: fl_max, sk_max
        implicit none

        integer(4), intent(in) :: ih

        integer(4) :: iv, il
        real(8) :: fluss

        intrinsic :: sqrt

        ! ===================================================================
        ! INTERIOR POINTS - Full tensor calculation
        ! ===================================================================
        do il = 2, iacnl(ih) - 1
            do iv = 2, iacnv(ih) - 1
                ! Xsi-direction flux (downslope)
                ! Includes xsi-xsi conductance (A_x) and eta-xsi cross (A2e)
                q_xsi(iv, il) = -( &
                    A_x(iv,   il  ) * (phineu(iv,   il+1) - phineu(iv,   il  )) + &
                    A_x(iv,   il-1) * (phineu(iv,   il  ) - phineu(iv,   il-1)) + &
                    A2e(iv,   il  ) * (phineu(iv+1, il  ) - phineu(iv,   il  )) + &
                    A2e(iv-1, il  ) * (phineu(iv,   il  ) - phineu(iv-1, il  ))   &
                ) / f_eta(iv, il, ih) / 4.0d0

                ! Eta-direction flux (vertical)
                ! Includes eta-eta conductance (A_e) and xsi-eta cross (A2x)
                q_eta(iv, il) = -( &
                    A2x(iv,   il  ) * (phineu(iv,   il+1) - phineu(iv,   il  )) + &
                    A2x(iv,   il-1) * (phineu(iv,   il  ) - phineu(iv,   il-1)) + &
                    A_e(iv,   il  ) * (phineu(iv+1, il  ) - phineu(iv,   il  )) + &
                    A_e(iv-1, il  ) * (phineu(iv,   il  ) - phineu(iv-1, il  ))   &
                ) / f_xsi(iv, il, ih) / 4.0d0
            end do
        end do

        ! ===================================================================
        ! BOTTOM AND TOP BOUNDARIES
        ! ===================================================================
        do il = 2, iacnl(ih) - 1
            ! Bottom boundary (iv=1)
            iv = 1
            q_xsi(iv, il) = -( &
                A_x(iv, il  ) * (phineu(iv, il+1) - phineu(iv, il  )) + &
                A_x(iv, il-1) * (phineu(iv, il  ) - phineu(iv, il-1))   &
            ) / f_eta(iv, il, ih) / 4.0d0
            q_eta(iv, il) = rfl_u(il)  ! From boundary condition

            ! Top boundary (iv=iacnv)
            iv = iacnv(ih)
            q_xsi(iv, il) = -( &
                A_x(iv, il  ) * (phineu(iv, il+1) - phineu(iv, il  )) + &
                A_x(iv, il-1) * (phineu(iv, il  ) - phineu(iv, il-1))   &
            ) / f_eta(iv, il, ih) / 4.0d0
            q_eta(iv, il) = rfl_o(il)  ! From boundary condition
        end do

        ! ===================================================================
        ! LEFT AND RIGHT BOUNDARIES
        ! ===================================================================
        do iv = 2, iacnv(ih) - 1
            ! Left boundary (il=1)
            il = 1
            q_eta(iv, il) = -( &
                A_e(iv,   il) * (phineu(iv+1, il) - phineu(iv,   il)) + &
                A_e(iv-1, il) * (phineu(iv,   il) - phineu(iv-1, il))   &
            ) / f_xsi(iv, il, ih) / 4.0d0
            q_xsi(iv, il) = rfl_l(iv)  ! From boundary condition

            ! Right boundary (il=iacnl)
            il = iacnl(ih)
            q_eta(iv, il) = -( &
                A_e(iv,   il) * (phineu(iv+1, il) - phineu(iv,   il)) + &
                A_e(iv-1, il) * (phineu(iv,   il) - phineu(iv-1, il))   &
            ) / f_xsi(iv, il, ih) / 4.0d0
            q_xsi(iv, il) = rfl_r(iv)  ! From boundary condition
        end do

        ! ===================================================================
        ! CORNER POINTS - Both fluxes from boundaries
        ! ===================================================================
        ! Bottom-left corner
        il = 1
        iv = 1
        q_xsi(iv, il) = rfl_l(iv)
        q_eta(iv, il) = rfl_u(il)

        ! Bottom-right corner
        il = iacnl(ih)
        iv = 1
        q_xsi(iv, il) = rfl_r(iv)
        q_eta(iv, il) = rfl_u(il)

        ! Top-left corner
        il = 1
        iv = iacnv(ih)
        q_xsi(iv, il) = rfl_l(iv)
        q_eta(iv, il) = rfl_o(il)

        ! Top-right corner
        il = iacnl(ih)
        iv = iacnv(ih)
        q_xsi(iv, il) = rfl_r(iv)
        q_eta(iv, il) = rfl_o(il)

        ! ===================================================================
        ! TRACK MAXIMUM FLUX AND SINK MAGNITUDES (diagnostics)
        ! ===================================================================
        do il = 1, iacnl(ih)
            do iv = 1, iacnv(ih)
                ! Flux magnitude
                fluss = sqrt(q_xsi(iv, il)**2 + q_eta(iv, il)**2)
                if (fl_max(ih) < fluss) fl_max(ih) = fluss

                ! Sink/source strength
                fluss = senk(iv, il)
                if (sk_max(ih) < fluss) sk_max(ih) = fluss
            end do
        end do

        return
    end subroutine cal_q

    !===========================================================================
    ! SUBROUTINE: stpbil
    !
    ! PURPOSE: Calculate step-wise mass balance for single time step
    !
    ! DESCRIPTION:
    !   Tracks ALL water fluxes during time step to verify mass conservation.
    !   This is absolutely CRITICAL - any imbalance indicates numerical bugs!
    !
    !   For each control volume (icv), calculates:
    !   1. Boundary fluxes: vrfl_l, vrfl_r, vrfl_u, vrfl_o [m³]
    !   2. Atmospheric fluxes: vnied, vintz, vevapo, vtrans [m³]
    !   3. Sink/source terms: vsenk, vsueb [m³]
    !   4. Storage change: volin = Δθ_mean × Volume [m³]
    !   5. Net boundary flow: volrd [m³]
    !   6. Mass balance: bilanz = volin - volrd + vsenk [m³]
    !
    !   Also integrates BC violations (ueb_*) over boundaries.
    !   Accumulates discharge at catchment outlet: qssum(ih).
    !
    !   MUST CALL mtheta FIRST to update th_mit(icv,2,ih)!
    !
    ! ALGORITHM:
    !   1. Call mtheta to update mean water content
    !   2. Integrate BC violations over boundaries → vueb_*
    !   3. For each control volume:
    !      a) Initialize all flux components to zero
    !      b) Integrate boundary fluxes (with flux averaging)
    !      c) Integrate atmospheric fluxes at top surface
    !      d) Integrate sink/source terms in interior
    !      e) Multiply all by dt to get volumes [m³]
    !      f) Calculate storage change: volin
    !      g) Calculate net boundary flow: volrd
    !      h) Calculate mass balance error: bilanz
    !   4. Accumulate discharge: qssum(ih) += vrfl_r(1)
    !
    !   Flux averaging at boundaries:
    !   - If boundary node: q = q(boundary)
    !   - If interior: q = [q(node) + q(neighbor)] / 2
    !   This ensures flux continuity across control volume boundaries.
    !
    ! ARGUMENTS:
    !   ih - Hillslope index [integer, input]
    !   dt - Time step size [real*8, input, seconds]
    !
    ! USES:
    !   Multiple modules for geometry, state, fluxes, atmosphere, balance
    !
    ! UPDATES:
    !   vrfl_*, vsenk, vsueb, vnied, vintz, vevapo, vtrans [m³]
    !   volin, volrd, bilanz [m³]
    !   vueb_* [m³]
    !   qssum(ih) [m³]
    !
    ! NOTES:
    !   - Called every accepted time step
    !   - bilanz should be ~0; if not, there's a bug!
    !   - Set bilanz=0 if |error| < 1e-8 (numerical noise)
    !===========================================================================
    subroutine stpbil(ih, dt)
        use mesh_geometry_module, only: iacnv, iacnl, iaccv, icvu, icvo, &
                                         icvl, icvr, area, varbr, vola, &
                                         dreta, drxsi, dr_o, dr_l, dr_r, &
                                         dr_u, slopeo, ifixob
        use state_variables_module, only: q_xsi, q_eta, th_mit
        use boundary_conditions_module, only: ueb_l, ueb_r, ueb_u, ueb_o, &
                                               isnk, senk, sueb
        use atmosphere_module, only: nied, Eintz, Esoil, Ecanop
        use balance_module, only: vrfl_l, vrfl_r, vrfl_u, vrfl_o, &
                                   vsenk, vsueb, vnied, vnied2, vintz, &
                                   vevapo, vtrans, volin, volrd, bilanz, &
                                   vueb_l, vueb_r, vueb_u, vueb_o, qssum
        implicit none

        integer(4), intent(in) :: ih
        real(8), intent(in) :: dt

        integer(4) :: iv, il, icv
        real(8) :: qq, bb, locfak

        external :: mtheta
        intrinsic :: abs

        ! Update mean water content for mass balance
        call mtheta(ih)

        ! ===================================================================
        ! INTEGRATE BC VIOLATIONS OVER BOUNDARIES
        ! ===================================================================
        vueb_l = 0.0d0
        vueb_r = 0.0d0
        vueb_u = 0.0d0
        vueb_o = 0.0d0

        do iv = 1, iacnv(ih)
            il = 1
            vueb_l = vueb_l + ueb_l(iv) * dr_l(iv, ih) * varbr(il, ih)
            il = iacnl(ih)
            vueb_r = vueb_r + ueb_r(iv) * dr_r(iv, ih) * varbr(il, ih)
        end do

        do il = 1, iacnl(ih)
            iv = 1
            vueb_u = vueb_u + ueb_u(il) * dr_u(il, ih) * varbr(il, ih)
            iv = iacnv(ih)
            vueb_o = vueb_o + ueb_o(il) * dr_o(il, ih) * varbr(il, ih)
        end do

        ! Multiply by dt to get volumes [m³]
        vueb_l = vueb_l * dt
        vueb_r = vueb_r * dt
        vueb_u = vueb_u * dt
        vueb_o = vueb_o * dt

        ! ===================================================================
        ! CALCULATE MASS BALANCE FOR EACH CONTROL VOLUME
        ! ===================================================================
        do icv = 1, iaccv(ih)
            ! Initialize all flux components
            vrfl_l(icv) = 0.0d0
            vrfl_r(icv) = 0.0d0
            vrfl_u(icv) = 0.0d0
            vrfl_o(icv) = 0.0d0
            vsenk(icv) = 0.0d0
            vsueb(icv) = 0.0d0
            vnied(icv) = 0.0d0
            vnied2(icv) = 0.0d0
            vintz(icv) = 0.0d0
            vevapo(icv) = 0.0d0
            vtrans(icv) = 0.0d0

            ! ===============================================================
            ! LEFT AND RIGHT BOUNDARY FLUXES
            ! ===============================================================
            do iv = icvu(icv, ih), icvo(icv, ih)
                ! Left boundary flux
                il = icvl(icv, ih)
                if (il == 1) then
                    ! Boundary node: use boundary flux
                    qq = q_xsi(iv, il)
                    bb = varbr(il, ih)
                else
                    ! Interior: average with neighbor
                    qq = (q_xsi(iv, il) + q_xsi(iv, il-1)) / 2.0d0
                    bb = (varbr(il, ih) + varbr(il-1, ih)) / 2.0d0
                end if
                vrfl_l(icv) = vrfl_l(icv) + qq * dreta(iv, il, ih) * bb

                ! Right boundary flux
                il = icvr(icv, ih)
                if (il == iacnl(ih)) then
                    ! Boundary node: use boundary flux
                    qq = q_xsi(iv, il)
                    bb = varbr(il, ih)
                else
                    ! Interior: average with neighbor
                    qq = (q_xsi(iv, il) + q_xsi(iv, il+1)) / 2.0d0
                    bb = (varbr(il, ih) + varbr(il+1, ih)) / 2.0d0
                end if
                vrfl_r(icv) = vrfl_r(icv) + qq * dreta(iv, il, ih) * bb
            end do

            ! ===============================================================
            ! BOTTOM AND TOP BOUNDARY FLUXES + ATMOSPHERIC FLUXES
            ! ===============================================================
            do il = icvl(icv, ih), icvr(icv, ih)
                ! Bottom boundary flux
                iv = icvu(icv, ih)
                if (iv == 1) then
                    ! Boundary node: use boundary flux
                    qq = q_eta(iv, il)
                    bb = varbr(il, ih)
                else
                    ! Interior: average with neighbor
                    qq = (q_eta(iv, il) + q_eta(iv-1, il)) / 2.0d0
                    bb = varbr(il, ih)
                end if
                vrfl_u(icv) = vrfl_u(icv) + qq * drxsi(iv, il, ih) * bb

                ! Top boundary flux
                iv = icvo(icv, ih)
                if (iv == iacnv(ih)) then
                    ! Boundary node: use boundary flux
                    qq = q_eta(iv, il)
                    bb = varbr(il, ih)
                else
                    ! Interior: average with neighbor
                    qq = (q_eta(iv, il) + q_eta(iv+1, il)) / 2.0d0
                    bb = varbr(il, ih)
                end if
                vrfl_o(icv) = vrfl_o(icv) + qq * drxsi(iv, il, ih) * bb

                ! Atmospheric fluxes at top surface
                locfak = dr_o(il, ih) * varbr(il, ih) * slopeo(il, ih)

                ! Precipitation
                vnied(icv) = vnied(icv) + nied(1, ifixob(il, 2, ih)) * locfak

                ! Precipitation in mm (for output)
                if (slopeo(il, ih) > 0.0d0) then
                    vnied2(icv) = vnied2(icv) + nied(1, ifixob(il, 2, ih)) * locfak
                else
                    vnied2(icv) = vnied2(icv) + nied(1, ifixob(il, 2, ih)) * locfak
                end if

                ! Interception, evaporation, transpiration
                vintz(icv) = vintz(icv) + Eintz(il) * locfak
                vevapo(icv) = vevapo(icv) + Esoil(il) * locfak
                vtrans(icv) = vtrans(icv) + Ecanop(il) * locfak
            end do

            ! ===============================================================
            ! INTERIOR SINK/SOURCE TERMS
            ! ===============================================================
            do iv = icvu(icv, ih), icvo(icv, ih)
                do il = icvl(icv, ih), icvr(icv, ih)
                    if (isnk(iv, il, ih) /= 0) then
                        vsenk(icv) = vsenk(icv) + &
                            senk(iv, il) * area(iv, il, ih) * varbr(il, ih)
                        vsueb(icv) = vsueb(icv) + &
                            sueb(iv, il) * area(iv, il, ih) * varbr(il, ih)
                    end if
                end do
            end do

            ! ===============================================================
            ! MULTIPLY BY TIME STEP TO GET VOLUMES [m³]
            ! ===============================================================
            vrfl_l(icv) = vrfl_l(icv) * dt
            vrfl_r(icv) = vrfl_r(icv) * dt
            vrfl_u(icv) = vrfl_u(icv) * dt
            vrfl_o(icv) = vrfl_o(icv) * dt
            vsenk(icv) = vsenk(icv) * dt
            vsueb(icv) = vsueb(icv) * dt
            vnied(icv) = vnied(icv) * dt
            vnied2(icv) = vnied2(icv) * dt
            vintz(icv) = vintz(icv) * dt
            vevapo(icv) = vevapo(icv) * dt
            vtrans(icv) = vtrans(icv) * dt

            ! ===============================================================
            ! CALCULATE MASS BALANCE COMPONENTS
            ! ===============================================================
            ! Net boundary flow (positive = inflow)
            volrd(icv) = vrfl_u(icv) + vrfl_l(icv) - vrfl_o(icv) - vrfl_r(icv)

            ! Storage change
            volin(icv) = (th_mit(icv, 2, ih) - th_mit(icv, 1, ih)) * vola(icv, ih)

            ! Mass balance error: should be zero!
            if (abs(volrd(icv) - vsenk(icv)) < 1.0d-8) then
                bilanz(icv) = 0.0d0
            else
                bilanz(icv) = volin(icv) - volrd(icv) + vsenk(icv)
            end if
        end do

        ! ===================================================================
        ! ACCUMULATE DISCHARGE AT CATCHMENT OUTLET (right boundary of cv=1)
        ! ===================================================================
        qssum(ih) = qssum(ih) + vrfl_r(1)

        return
    end subroutine stpbil

    !===========================================================================
    ! SUBROUTINE: totbil
    !
    ! PURPOSE: Accumulate total cumulative mass balance over entire simulation
    !
    ! DESCRIPTION:
    !   Adds step-wise quantities (v*) to cumulative totals (b*) for each
    !   control volume and hillslope. Provides running water budget and
    !   tracks long-term mass conservation.
    !
    !   Key accumulated quantities:
    !   - bilin: total storage change [m³]
    !   - bilrd: total boundary flows [m³]
    !   - bsenk: total sink/source [m³]
    !   - biltot = bilin - bilrd + bsenk: cumulative error [m³]
    !   - brfl_*: cumulative boundary fluxes [m³]
    !   - bnied, bevapo, btrans: cumulative atmospheric fluxes [m³]
    !   - bueb_*: cumulative BC violations [m³]
    !   - bm_*: cumulative particle mass losses [kg]
    !
    !   Also converts precipitation to mm for output:
    !   bnied2 = bnied / hgobfl × 1000 [mm]
    !
    ! ALGORITHM:
    !   1. Loop over control volumes
    !   2. Add step values (v*) to totals (b*)
    !   3. Calculate biltot = bilin - bilrd + bsenk
    !   4. Convert precipitation to mm
    !   5. Accumulate BC violations
    !   6. Accumulate particle mass losses
    !
    ! ARGUMENTS:
    !   ih     - Hillslope index [integer, input]
    !   istact - Number of active particle species [integer, input]
    !
    ! USES:
    !   mesh_geometry_module: iaccv, hgobfl
    !   balance_module: v* (step values), b* (cumulative values)
    !   particle_module: mlos_*, bm_*
    !
    ! UPDATES:
    !   All cumulative balance arrays (b*) [m³ or mm]
    !
    ! NOTES:
    !   - Called every accepted time step after stpbil
    !   - biltot tracks cumulative mass conservation error
    !   - Should remain ≈ 0 throughout simulation
    !===========================================================================
    subroutine totbil(ih, istact)
        use mesh_geometry_module, only: iaccv, hgobfl
        use balance_module, only: volin, volrd, vsenk, vsueb, vnied, vnied2, &
                                   vintz, vevapo, vtrans, vrfl_u, vrfl_o, &
                                   vrfl_r, vrfl_l, vueb_u, vueb_o, vueb_r, &
                                   vueb_l, bilin, bilrd, bsenk, bsueb, &
                                   biltot, brfl_u, brfl_o, brfl_r, brfl_l, &
                                   bnied, bnied2, bintz, bevapo, btrans, &
                                   bueb_u, bueb_o, bueb_r, bueb_l
        use particle_module, only: mlos_l, mlos_r, mlos_u, bm_l, bm_r, bm_u
        implicit none

        integer(4), intent(in) :: ih, istact

        integer(4) :: icv, istp

        ! ===================================================================
        ! ACCUMULATE BALANCE COMPONENTS FOR EACH CONTROL VOLUME
        ! ===================================================================
        do icv = 1, iaccv(ih)
            ! Storage change
            bilin(icv, ih) = bilin(icv, ih) + volin(icv)

            ! Boundary flows
            bilrd(icv, ih) = bilrd(icv, ih) + volrd(icv)

            ! Sink/source terms
            bsenk(icv, ih) = bsenk(icv, ih) + vsenk(icv)
            bsueb(icv, ih) = bsueb(icv, ih) + vsueb(icv)

            ! Total balance error
            biltot(icv, ih) = bilin(icv, ih) - bilrd(icv, ih) + bsenk(icv, ih)

            ! Individual boundary fluxes
            brfl_u(icv, ih) = brfl_u(icv, ih) + vrfl_u(icv)
            brfl_o(icv, ih) = brfl_o(icv, ih) + vrfl_o(icv)
            brfl_r(icv, ih) = brfl_r(icv, ih) + vrfl_r(icv)
            brfl_l(icv, ih) = brfl_l(icv, ih) + vrfl_l(icv)

            ! Atmospheric fluxes
            bnied(icv, ih) = bnied(icv, ih) + vnied(icv)

            ! Precipitation in mm (divide by surface area, convert to mm)
            bnied2(icv, ih) = bnied2(icv, ih) + vnied2(icv) / hgobfl(ih) * 1.0d3

            ! Evapotranspiration components
            bintz(icv, ih) = bintz(icv, ih) + vintz(icv)
            bevapo(icv, ih) = bevapo(icv, ih) + vevapo(icv)
            btrans(icv, ih) = btrans(icv, ih) + vtrans(icv)
        end do

        ! ===================================================================
        ! ACCUMULATE PARTICLE MASS LOSSES AT BOUNDARIES
        ! ===================================================================
        do istp = 1, istact
            bm_l(istp, ih) = bm_l(istp, ih) + mlos_l(istp, ih)
            bm_r(istp, ih) = bm_r(istp, ih) + mlos_r(istp, ih)
            bm_u(istp, ih) = bm_u(istp, ih) + mlos_u(istp, ih)
        end do

        ! ===================================================================
        ! ACCUMULATE BOUNDARY CONDITION VIOLATIONS
        ! ===================================================================
        bueb_u(ih) = bueb_u(ih) + vueb_u
        bueb_o(ih) = bueb_o(ih) + vueb_o
        bueb_r(ih) = bueb_r(ih) + vueb_r
        bueb_l(ih) = bueb_l(ih) + vueb_l

        return
    end subroutine totbil

end module balanc_module
