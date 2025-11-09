!===============================================================================
! MODULE: bodtab_module
!
! PURPOSE:
!   Soil hydraulic property calculations for CATFLOW Richards equation solver
!   Modernized version of BODTAB.f using Fortran 90 modules
!
! DESCRIPTION:
!   This module contains ALL soil hydraulic property functions and table
!   generation for the CATFLOW model. It is absolutely CRITICAL for the
!   Richards equation solver - every time step requires K(ψ), C(ψ), and θ(ψ).
!
!   PUBLIC SUBROUTINES:
!   1. bodtab      - Generate soil hydraulic tables from parameters
!   2. kc_phi(phi,ih)      - Update K, C from potential φ (CRITICAL - called every step)
!   3. psi_phi(psi,phi,ih) - Convert potential φ to pressure head ψ
!   4. kc_psi(ih)          - Update K, C, θ from pressure head ψ
!   5. chk_ma(ku,iv,il,ih) - Macropore modifications to hydraulic conductivity
!
!   PUBLIC FUNCTIONS:
!   6. c_psi(iboden,psiact,ipos)  - Water capacity C(ψ) [1/m]
!   7. k_psi(iboden,psiact,ipos)  - Hydraulic conductivity K(ψ) [m/s]
!   8. k_th(iboden,th_act,ipos)   - Hydraulic conductivity K(θ) [m/s]
!   9. th_psi(iboden,psiact,ipos) - Water content θ(ψ) [-]
!   10. psi_th(iboden,thact,ipos) - Pressure head ψ(θ) [m]
!
!   PRIVATE SUBROUTINES:
!   11. vg_tab     - Generate van Genuchten (1980) model tables
!   12. ts_tab     - Generate Tang & Skaggs (1977) model tables
!   13. bw_tab     - Generate Broadbridge & White (1988) tables (not implemented)
!   14. filtab     - Read soil hydraulic table from file
!   15. lookup     - Table interpolation with position hint
!   16. locate     - Binary search (interval halving)
!   17. hunt       - Binary search with position hint (Numerical Recipes)
!
! SOIL HYDRAULIC MODELS:
!
!   Van Genuchten (1980) - imod = 1:
!   --------------------------------
!   The most widely used soil hydraulic model. Provides closed-form
!   expressions for θ(ψ), K(ψ), and C(ψ).
!
!   Parameters:
!   - K_s:  Saturated hydraulic conductivity [m/s]
!   - θ_s:  Saturated water content [-]
!   - θ_r:  Residual water content [-]
!   - α:    Inverse air entry value [1/m]
!   - n:    Pore size distribution index [-]
!   - m = 1 - 1/n: derived parameter
!
!   Equations:
!   Effective saturation: S_e = [1 + (α·ψ)^n]^(-m)
!   Water content:        θ = θ_r + (θ_s - θ_r)·S_e
!   Conductivity:         K = K_s·S_e^(1/2)·[1 - (1 - S_e^(1/m))^m]^2
!   Water capacity:       C = dθ/dψ = -(θ_s - θ_r)·n·m·α^n·ψ^(n-1)·[1 + (α·ψ)^n]^(-m-1)
!
!   Valid for unsaturated soil (ψ > 0). For saturated soil (ψ ≤ 0):
!   - θ = θ_s
!   - K = K_s
!   - C = 0 (incompressible)
!
!   Physical interpretation:
!   - n > 1 always (typically 1.1 to 3)
!   - Small α: fine-textured soil (clay) with high air entry
!   - Large α: coarse-textured soil (sand) with low air entry
!   - Large n: uniform pore sizes
!   - Small n: broad pore size distribution
!
!   Tang & Skaggs (1977) - imod = 2:
!   --------------------------------
!   Alternative model using power-law relationships.
!
!   Parameters:
!   - K_s:    Saturated conductivity [m/s]
!   - θ_s:    Saturated water content [-]
!   - α, β:   Water retention parameters
!   - A, B:   Conductivity parameters
!
!   Equations:
!   Water content:   θ = θ_s·α / [α + (ψ·100)^β]
!   Conductivity:    K = K_s·A / [A + (ψ·100)^B]
!   Water capacity:  C = -θ_s·α·β·100·(ψ·100)^(β-1) / [α + (ψ·100)^β]^2
!
!   Note: ψ multiplied by 100 for historical reasons (conversion cm → m)
!
!   Tabular Model - imod = 99:
!   ---------------------------
!   Measured soil hydraulic properties read from file.
!   Table contains [θ, ψ, K, C] at discrete points.
!   Interpolation used to obtain values at arbitrary ψ.
!
! TABLE STRUCTURE:
!
!   s_tab(itab, ieig, ityp):
!   - itab = 1...iactab(ityp): table row index
!   - ieig = 1...4: property index
!     * ieig=1: θ (water content) - monotonic increasing
!     * ieig=2: ψ (pressure head) - monotonic decreasing
!     * ieig=3: K (conductivity) - monotonic increasing
!     * ieig=4: C (capacity) - NON-monotonic (cannot be inverted)
!   - ityp = 1...iactyp: soil type index
!
!   Table generated on logarithmic ψ spacing:
!   log10(ψ) ranges from bodpar(6,ityp) to bodpar(7,ityp)
!   Typical range: log10(ψ) = -2 to +6 (ψ = 0.01 m to 10^6 m)
!
! LOOKUP ALGORITHM:
!
!   All functions (k_psi, c_psi, th_psi, etc.) use table interpolation
!   with POSITION HINT for performance:
!
!   1. Call hunt(xsp, nsp, xval, ipos) with position hint ipos
!   2. hunt searches near ipos first (faster than full binary search)
!   3. Linear interpolation: y = y(i) + [y(i+1)-y(i)]·[x-x(i)]/[x(i+1)-x(i)]
!   4. Extrapolation beyond table:
!      - ψ < ψ_min: use table minimum (driest state)
!      - ψ > ψ_max: use table maximum (saturated)
!
!   Position hint (ipos) cached in tabpos(iv,il,ih) array - each node
!   remembers its last table position. Since ψ changes slowly between
!   time steps, hunt usually finds the interval in O(1) time instead of O(log n).
!
! MACROPORE MODIFICATIONS (chk_ma):
!
!   When soil exceeds saturation threshold (θ > θ_threshold), macropores
!   activate and dramatically increase K:
!
!   K_macro = K·mfak
!
!   where mfak depends on:
!   - Macropore density: macro(iv,il,ih) > 1
!   - Current saturation: θ(iv,il)
!   - Threshold saturation: sattgr(iboden)·θ_s
!   - Exponent: b_mac(iv,il,ih)
!
!   Macropore anisotropy (m_aniso):
!   - m_aniso = 1: vertical macropores (gravity direction)
!   - m_aniso = 2: horizontal macropores (downslope direction)
!   - m_aniso = 0: isotropic macropore enhancement
!
!   Surface runoff coupling:
!   If surface node saturated AND node below saturated, macropores
!   activate for all underlying nodes (preferential flow to depth).
!
!   Physical interpretation:
!   Macropores represent structural voids (root channels, earthworm
!   burrows, cracks) that bypass the soil matrix and conduct water
!   rapidly when saturated. Critical for:
!   - Rapid infiltration during intense rainfall
!   - Fast drainage after saturation
!   - Preferential flow paths
!
! NUMERICAL CONSIDERATIONS:
!
!   Stability and Accuracy:
!   - K(ψ) varies over 10+ orders of magnitude
!   - Small errors in ψ cause large errors in K
!   - Table spacing must be fine enough for accuracy
!   - Position hint critical for performance (10-100x speedup)
!
!   Storage term correction:
!   The capacity C includes a correction term:
!   C_effective = C_table - snull·θ/θ_s
!
!   where snull is the storage coefficient for saturated soil.
!   This accounts for slight compressibility of saturated soil.
!
!   Extrapolation safety:
!   - Returning minimum/maximum table values prevents unphysical behavior
!   - No error if solution temporarily exceeds table bounds
!   - Solver self-corrects on next iteration
!
! VALIDATION REQUIREMENTS:
!
!   1. Van Genuchten model:
!      - Verify θ(ψ) matches published curves
!      - Check K(ψ) against analytical solution
!      - Verify C(ψ) = dθ/dψ numerically
!      - Test limiting behavior: ψ→0 (saturated) and ψ→∞ (dry)
!
!   2. Table interpolation:
!      - Compare interpolated vs analytical values
!      - Check mass conservation with table-based K
!      - Verify position hint gives identical results
!      - Test extrapolation behavior
!
!   3. Macropore activation:
!      - Verify threshold triggering
!      - Check anisotropy modifications
!      - Test surface-triggered activation
!      - Verify stability with large K jumps
!
!   4. Cross-model consistency:
!      - Van Genuchten vs tabular (using VG-generated table)
!      - Tang-Skaggs vs published parameters
!      - Verify all models conserve mass
!
! PERFORMANCE CRITICAL:
!
!   These functions are called MILLIONS of times per simulation:
!   - Every node, every iteration, every time step
!   - Position hint reduces lookup from O(log n) to O(1)
!   - Table spacing affects both accuracy and speed
!   - Typical: 100-200 table points per soil type
!
! ORIGINAL: BODTAB.f (Fortran 77 with includes)
! AUTHOR: CATFLOW Development Team
! CONVERTED: CATFLOW Streamlined
! DATE: 2025-11-09
!===============================================================================
module bodtab_module
    use constants_module, only: maxnv, maxnl, maxnh, maxtab, maxeig, maxtyp, maxpbm
    implicit none
    private

    ! Public subroutines
    public :: bodtab
    public :: kc_phi
    public :: psi_phi
    public :: kc_psi
    public :: chk_ma

    ! Public functions
    public :: c_psi
    public :: k_psi
    public :: k_th
    public :: th_psi
    public :: psi_th

    ! Private subroutines (table generation and utilities)
    ! vg_tab, ts_tab, bw_tab, filtab, lookup, locate, hunt

contains

    !===========================================================================
    ! SUBROUTINE: bodtab
    !
    ! PURPOSE: Generate soil hydraulic property tables from parameters
    !
    ! DESCRIPTION:
    !   Main initialization routine that generates lookup tables for all
    !   soil types defined in the model. Calls appropriate table generation
    !   routine based on imod(ityp):
    !
    !   imod = 1:  Van Genuchten model (vg_tab)
    !   imod = 2:  Tang & Skaggs model (ts_tab)
    !   imod = 3:  Broadbridge & White model (bw_tab) - not implemented
    !   imod = 99: Read from file (filtab)
    !
    !   For each soil type, also calculates permanent wilting point (PWP)
    !   water content at ψ = 10^4.2 m ≈ 15850 m (1.5 MPa, standard PWP).
    !
    ! ALGORITHM:
    !   1. Set iaceig = 4 (number of table columns: θ, ψ, K, C)
    !   2. Loop over all soil types (ityp = 1...iactyp)
    !   3. Call table generation routine based on imod(ityp)
    !   4. Calculate PWP water content: θ_pwp = θ(ψ_pwp)
    !
    ! USES:
    !   soil_properties_module: imod, iactyp, th_pwp, iaceig
    !   error_module: maxtst (dimension checking)
    !
    ! NOTES:
    !   - Called once during model initialization
    !   - Tables persist throughout simulation
    !   - PWP needed for plant water stress calculations
    !===========================================================================
    subroutine bodtab()
        use soil_properties_module, only: imod, iactyp, th_pwp, iaceig, maxeig
        use error_module, only: maxtst
        implicit none

        integer(4) :: ityp, ilp
        real(8) :: psipwp

        ! Set number of table columns (θ, ψ, K, C)
        iaceig = 4
        call maxtst('IACEIG  ', iaceig, 'MAXEIG  ', maxeig, 'BODTAB  ')

        ! Permanent wilting point: ψ = 10^4.2 / 100 ≈ 158.5 m
        psipwp = 10.0d0**(4.2d0) / 100.0d0
        ilp = 1  ! Initial position hint for lookup

        ! Generate tables for all soil types
        do ityp = 1, iactyp
            if (imod(ityp) == 1) call vg_tab(ityp)
            if (imod(ityp) == 2) call ts_tab(ityp)
            if (imod(ityp) == 3) call bw_tab(ityp)
            if (imod(ityp) == 99) call filtab(ityp)

            ! Calculate permanent wilting point water content
            th_pwp(ityp) = th_psi(ityp, psipwp, ilp)
        end do

        return
    end subroutine bodtab

    !===========================================================================
    ! SUBROUTINE: vg_tab
    !
    ! PURPOSE: Generate van Genuchten (1980) soil hydraulic property table
    !
    ! DESCRIPTION:
    !   Creates lookup table for θ(ψ), K(ψ), C(ψ) using van Genuchten
    !   closed-form equations. Table generated on logarithmic ψ spacing.
    !
    !   Parameters (bodpar):
    !   1: K_s  - Saturated conductivity [m/s]
    !   2: θ_s  - Saturated water content [-]
    !   3: θ_r  - Residual water content [-]
    !   4: α    - Inverse air entry [1/m]
    !   5: n    - Pore size distribution [-]
    !   6: psimin - log10(ψ_min) for table
    !   7: psimax - log10(ψ_max) for table
    !
    !   Table columns (s_tab):
    !   1: θ   - Water content (monotonic increasing)
    !   2: ψ   - Pressure head (monotonic decreasing)
    !   3: K   - Hydraulic conductivity (monotonic increasing)
    !   4: C   - Water capacity (non-monotonic)
    !
    ! ALGORITHM:
    !   For each table point (itab = 1...iactab):
    !   1. Calculate log10(ψ) with equal spacing
    !   2. Convert to ψ = 10^[log10(ψ)]
    !   3. Calculate effective saturation: S_e = [1 + (α·ψ)^n]^(-m)
    !   4. Calculate θ = θ_r + (θ_s - θ_r)·S_e
    !   5. Calculate K = K_s·S_e^0.5·[1 - (1 - S_e^(1/m))^m]^2
    !   6. Calculate C = -(θ_s - θ_r)·n·m·α^n·ψ^(n-1)·[1 + (α·ψ)^n]^(-m-1)
    !
    ! ARGUMENTS:
    !   ityp - Soil type index [integer, input]
    !
    ! USES:
    !   soil_properties_module: s_tab, bodpar, iactab, boden, anisot, imod, snull
    !   io_module: io, io_act, io_log
    !===========================================================================
    subroutine vg_tab(ityp)
        use soil_properties_module, only: s_tab, bodpar, iactab, boden, anisot, &
                                           imod, snull, iaceig
        use io_module, only: io, io_act, io_log
        implicit none

        integer(4), intent(in) :: ityp

        real(8) :: k_s, th_s, th_r, vg_a, vg_n, vg_m
        real(8) :: psimin, psimax, thstar, thhelp, vg_an
        integer(4) :: itab, ieig

        intrinsic :: dble

        ! Log soil parameters
        if ((io_act >= 2) .and. (io_log(2) > 0)) then
            write(io(2),'(a30,2f8.3,i4,i6,e13.4)') boden(ityp), &
                  anisot(1,ityp), anisot(2,ityp), imod(ityp), iactab(ityp), &
                  snull(ityp)
        end if

        ! Extract van Genuchten parameters
        k_s  = bodpar(1, ityp)
        th_s = bodpar(2, ityp)
        th_r = bodpar(3, ityp)
        vg_a = bodpar(4, ityp)
        vg_n = bodpar(5, ityp)
        vg_m = 1.0d0 - 1.0d0/vg_n

        ! Generate table with logarithmic ψ spacing
        do itab = 1, iactab(ityp)
            psimin = bodpar(6, ityp)
            psimax = bodpar(7, ityp)

            ! Logarithmic spacing: log10(ψ)
            thstar = psimax - (psimax - psimin) * dble(itab-1) / dble(iactab(ityp)-1)

            ! Pressure head (positive for unsaturated) [m]
            s_tab(itab, 2, ityp) = 10.0d0**thstar

            ! Effective saturation: S_e = [1 + (α·ψ)^n]^(-m)
            thstar = (1.0d0 + (vg_a * s_tab(itab,2,ityp))**vg_n)**(-vg_m)

            ! Water content (volumetric) [-]
            s_tab(itab, 1, ityp) = thstar * (th_s - th_r) + th_r

            ! Hydraulic conductivity [m/s]
            ! K = K_s · S_e^0.5 · [1 - (1 - S_e^(1/m))^m]^2
            thhelp = thstar**(1.0d0/vg_m)
            s_tab(itab, 3, ityp) = &
                k_s * thstar**(0.5d0) * (1.0d0 - (1.0d0 - thhelp)**vg_m)**2.0d0

            ! Water capacity [1/m]
            ! C = dθ/dψ = -(θ_s - θ_r)·n·m·α^n·ψ^(n-1)·[1 + (α·ψ)^n]^(-m-1)
            vg_an = vg_a**vg_n
            s_tab(itab, 4, ityp) = &
                (th_r - th_s) * vg_n * vg_m * vg_an * s_tab(itab,2,ityp)**(vg_n-1.0d0) &
                * (1.0d0 + (vg_a * s_tab(itab,2,ityp))**vg_n)**(-vg_m-1.0d0)

            ! Log table values
            if ((io_act >= 2) .and. (io_log(2) > 0)) then
                write(io(2),1000) (s_tab(itab,ieig,ityp), ieig=1,iaceig)
            end if
        end do

        return
1000    format(4e14.6)
    end subroutine vg_tab

    !===========================================================================
    ! SUBROUTINE: ts_tab
    !
    ! PURPOSE: Generate Tang & Skaggs (1977) soil hydraulic property table
    !
    ! DESCRIPTION:
    !   Creates lookup table using Tang & Skaggs power-law model.
    !
    !   Parameters (bodpar):
    !   1: K_s    - Saturated conductivity [m/s]
    !   2: θ_s    - Saturated water content [-]
    !   3: α      - Water retention parameter
    !   4: β      - Water retention exponent
    !   5: A      - Conductivity parameter
    !   6: B      - Conductivity exponent
    !   7: psimin - log10(ψ_min)
    !   8: psimax - log10(ψ_max)
    !
    !   Equations:
    !   θ = θ_s·α / [α + (ψ·100)^β]
    !   K = K_s·A / [A + (ψ·100)^B]
    !   C = -θ_s·α·β·100·(ψ·100)^(β-1) / [α + (ψ·100)^β]^2
    !
    ! ARGUMENTS:
    !   ityp - Soil type index [integer, input]
    !===========================================================================
    subroutine ts_tab(ityp)
        use soil_properties_module, only: s_tab, bodpar, iactab, boden, anisot, &
                                           imod, snull, iaceig
        use io_module, only: io, io_act, io_log
        implicit none

        integer(4), intent(in) :: ityp

        real(8) :: k_s, th_s, ts_alp, ts_bet, ts_A, ts_B
        real(8) :: psimin, psimax
        integer(4) :: itab, ieig

        intrinsic :: dble

        ! Log soil parameters
        if ((io_act >= 2) .and. (io_log(2) > 0)) then
            write(io(2),'(a30,2f8.3,i4,i6,e11.4)') boden(ityp), &
                  anisot(1,ityp), anisot(2,ityp), imod(ityp), iactab(ityp), &
                  snull(ityp)
        end if

        ! Extract Tang & Skaggs parameters
        k_s    = bodpar(1, ityp)
        th_s   = bodpar(2, ityp)
        ts_alp = bodpar(3, ityp)
        ts_bet = bodpar(4, ityp)
        ts_A   = bodpar(5, ityp)
        ts_B   = bodpar(6, ityp)

        do itab = 1, iactab(ityp)
            ! Pressure head with logarithmic spacing [m]
            psimax = bodpar(8, ityp)
            psimin = bodpar(7, ityp)
            s_tab(itab, 2, ityp) = 10.0d0**( &
                psimax - (psimax - psimin) * dble(itab-1) / dble(iactab(ityp)-1))

            ! Water content (volumetric) [-]
            ! θ = θ_s·α / [α + (ψ·100)^β]
            s_tab(itab, 1, ityp) = th_s * ts_alp / &
                (ts_alp + (s_tab(itab,2,ityp) * 100.0d0)**ts_bet)

            ! Hydraulic conductivity [m/s]
            ! K = K_s·A / [A + (ψ·100)^B]
            s_tab(itab, 3, ityp) = k_s * ts_A / &
                (ts_A + (s_tab(itab,2,ityp) * 100.0d0)**ts_B)

            ! Water capacity [1/m]
            ! C = -θ_s·α·β·100·(ψ·100)^(β-1) / [α + (ψ·100)^β]^2
            s_tab(itab, 4, ityp) = -th_s * ts_alp * ts_bet * 100.0d0 * &
                (s_tab(itab,2,ityp) * 100.0d0)**(ts_bet - 1.0d0) / &
                (ts_alp + (s_tab(itab,2,ityp) * 100.0d0)**ts_bet)**2.0d0

            ! Log table values
            if ((io_act >= 2) .and. (io_log(2) > 0)) then
                write(io(2),1000) (s_tab(itab,ieig,ityp), ieig=1,iaceig)
            end if
        end do

        return
1000    format(4e14.6)
    end subroutine ts_tab

    !===========================================================================
    ! SUBROUTINE: bw_tab
    !
    ! PURPOSE: Generate Broadbridge & White (1988) table (NOT IMPLEMENTED)
    !
    ! DESCRIPTION:
    !   Placeholder for Broadbridge & White model. Currently stops with
    !   error message if called.
    !
    ! ARGUMENTS:
    !   ityp - Soil type index [integer, input]
    !===========================================================================
    subroutine bw_tab(ityp)
        use soil_properties_module, only: bodpar, boden, anisot, imod, iactab, snull
        use io_module, only: io, io_act, io_log
        implicit none

        integer(4), intent(in) :: ityp

        real(8) :: k_s, th_s, th_r, lam_c, struc

        intrinsic :: dble

        ! Log soil parameters
        if ((io_act >= 2) .and. (io_log(2) > 0)) then
            write(io(2),'(a30,2f8.3,i4,i6,e11.4)') boden(ityp), &
                  anisot(1,ityp), anisot(2,ityp), imod(ityp), iactab(ityp), &
                  snull(ityp)
        end if

        ! Extract parameters (not used)
        k_s   = bodpar(1, ityp)
        th_s  = bodpar(2, ityp)
        th_r  = bodpar(3, ityp)
        lam_c = bodpar(4, ityp)
        struc = bodpar(5, ityp)

        stop 'Broadbridge & White Model fehlt noch!'

        return
    end subroutine bw_tab

    !===========================================================================
    ! SUBROUTINE: filtab
    !
    ! PURPOSE: Read soil hydraulic property table from file
    !
    ! DESCRIPTION:
    !   Reads measured or externally generated soil hydraulic properties
    !   from a text file. File format:
    !
    !   Line 1: soil_name  anisot_x anisot_y snull
    !   Line 2-N: θ  ψ  K  C
    !
    !   Reads until end-of-file, automatically determines table size.
    !
    ! ARGUMENTS:
    !   ityp - Soil type index [integer, input]
    !
    ! USES:
    !   soil_properties_module: tabfil (filename), s_tab, boden, anisot, snull
    !   io_module: iin (input unit), openi (open file)
    !   error_module: maxtst (check table size)
    !===========================================================================
    subroutine filtab(ityp)
        use soil_properties_module, only: s_tab, boden, anisot, snull, iactab, &
                                           imod, tabfil, iaceig, maxtab
        use io_module, only: iin, io, openi
        use error_module, only: maxtst
        implicit none

        integer(4), intent(in) :: ityp

        character(50) :: hlpstr
        integer(4) :: itab, ieig

        ! Open soil table file
        call openi(iin(1), tabfil(ityp), io(1))

        ! Read header: soil name and parameters
        read(iin(1),'(a30,a50)') boden(ityp), hlpstr
        read(hlpstr,*) anisot(1,ityp), anisot(2,ityp), snull(ityp)

        ! Read table rows until end-of-file
        itab = 1
950     read(iin(1), *, end=951) (s_tab(itab,ieig,ityp), ieig=1,iaceig)
        itab = itab + 1
        goto 950
951     continue

        close(iin(1))

        ! Set actual table size
        iactab(ityp) = itab - 1
        call maxtst('IACTAB  ', iactab(ityp), 'MAXTAB  ', maxtab, 'FILTAB  ')

        ! Log table
        if ((io_act >= 2) .and. (io_log(2) > 0)) then
            write(io(2),'(a30,2f8.3,i4,i6)') boden(ityp), &
                  anisot(1,ityp), anisot(2,ityp), imod(ityp), iactab(ityp)
            do itab = 1, iactab(ityp)
                write(io(2),1000) (s_tab(itab,ieig,ityp), ieig=1,iaceig)
            end do
        end if

        return
1000    format(4e14.6)
    end subroutine filtab

    !===========================================================================
    ! SUBROUTINE: kc_phi
    !
    ! PURPOSE: Update hydraulic conductivity K and capacity C from potential φ
    !
    ! DESCRIPTION:
    !   This is the CRITICAL interface between the Richards solver and soil
    !   hydraulic properties. Called at EVERY time step to update K and C
    !   based on current solution φ.
    !
    !   Algorithm:
    !   1. Convert φ (hydraulic potential) to ψ (pressure head)
    !   2. Update K, C, θ from ψ using table lookup
    !
    !   The separation into psi_phi + kc_psi allows intermediate access
    !   to ψ if needed for output or diagnostics.
    !
    ! ARGUMENTS:
    !   phi - Hydraulic potential φ [real*8(maxnv,maxnl), input]
    !   ih  - Hillslope index [integer, input]
    !
    ! UPDATES (via kc_psi):
    !   psi(iv,il)    - Pressure head [m]
    !   durchl(iv,il) - Hydraulic conductivity K [m/s]
    !   theta(iv,il)  - Water content θ [-]
    !   wasska(iv,il) - Water capacity C [1/m]
    !
    ! NOTES:
    !   - Performance critical - called millions of times
    !   - Must preserve EXACT physics
    !   - Any error here propagates through entire solution
    !===========================================================================
    subroutine kc_phi(phi, ih)
        implicit none

        integer(4), intent(in) :: ih
        real(8), intent(in) :: phi(maxnv, maxnl)

        ! Convert φ → ψ, then update K, C, θ from ψ
        call psi_phi(psi, phi, ih)
        call kc_psi(ih)

        return
    end subroutine kc_phi

    !===========================================================================
    ! SUBROUTINE: psi_phi
    !
    ! PURPOSE: Convert hydraulic potential φ to pressure head ψ
    !
    ! DESCRIPTION:
    !   Performs coordinate transformation:
    !   ψ = h_0 - φ
    !
    !   where h_0(iv,il,ih) is the reference elevation (vertical coordinate).
    !
    !   In the transformed coordinate system used by CATFLOW:
    !   - φ: hydraulic potential (solution variable) [m]
    !   - ψ: pressure head (for soil properties) [m]
    !   - h_0: elevation head (geometry) [m]
    !
    !   Relationship: φ = ψ + h_0
    !   Therefore:    ψ = h_0 - φ
    !
    ! ARGUMENTS:
    !   psi - Pressure head [real*8(maxnv,maxnl), output]
    !   phi - Hydraulic potential [real*8(maxnv,maxnl), input]
    !   ih  - Hillslope index [integer, input]
    !
    ! USES:
    !   mesh_geometry_module: hko (reference elevation)
    !===========================================================================
    subroutine psi_phi(psi, phi, ih)
        use mesh_geometry_module, only: iacnv, iacnl, hko
        implicit none

        integer(4), intent(in) :: ih
        real(8), intent(in) :: phi(maxnv, maxnl)
        real(8), intent(out) :: psi(maxnv, maxnl)

        integer(4) :: iv, il

        do iv = 1, iacnv(ih)
            do il = 1, iacnl(ih)
                psi(iv,il) = hko(iv,il,ih) - phi(iv,il)
            end do
        end do

        return
    end subroutine psi_phi

    !===========================================================================
    ! SUBROUTINE: kc_psi
    !
    ! PURPOSE: Update K, C, θ from pressure head ψ for entire domain
    !
    ! DESCRIPTION:
    !   For each node (iv,il), looks up soil type and calls table interpolation
    !   functions to obtain:
    !   - durchl: hydraulic conductivity K(ψ)
    !   - theta: water content θ(ψ)
    !   - wasska: water capacity C(ψ) with storage correction
    !
    !   Water capacity correction:
    !   C_eff = C_table - snull·θ/θ_s
    !
    !   The snull term accounts for slight compressibility of saturated soil.
    !
    !   After updating K, calls chk_ma to apply macropore modifications.
    !
    ! ARGUMENTS:
    !   ih - Hillslope index [integer, input]
    !
    ! USES:
    !   state_variables_module: psi, durchl, theta, wasska, tabpos
    !   mesh_geometry_module: iacnv, iacnl, iboden
    !   soil_properties_module: snull, s_tab, iactab
    !
    ! NOTES:
    !   - tabpos caches last lookup position for each node
    !   - hunt algorithm uses position hint for O(1) lookup
    !   - Correction term critical for saturated flow
    !===========================================================================
    subroutine kc_psi(ih)
        use soil_properties_module, only: snull, s_tab, iactab
        use mesh_geometry_module, only: iacnv, iacnl, iboden
        use state_variables_module, only: psi, durchl, theta, wasska, tabpos
        implicit none

        integer(4), intent(in) :: ih

        integer(4) :: iv, il

        do iv = 1, iacnv(ih)
            do il = 1, iacnl(ih)
                ! Lookup K(ψ)
                durchl(iv,il) = &
                    k_psi(iboden(iv,il,ih), psi(iv,il), tabpos(iv,il,ih))

                ! Lookup θ(ψ)
                theta(iv,il) = &
                    th_psi(iboden(iv,il,ih), psi(iv,il), tabpos(iv,il,ih))

                ! Lookup C(ψ) with storage correction
                wasska(iv,il) = &
                    c_psi(iboden(iv,il,ih), psi(iv,il), tabpos(iv,il,ih)) - &
                    snull(iboden(iv,il,ih)) * theta(iv,il) / &
                    s_tab(iactab(iboden(iv,il,ih)), 1, iboden(iv,il,ih))

                ! Apply macropore modifications to K
                call chk_ma(durchl(iv,il), iv, il, ih)
            end do
        end do

        return
    end subroutine kc_psi

    !===========================================================================
    ! SUBROUTINE: chk_ma
    !
    ! PURPOSE: Apply macropore modifications to hydraulic conductivity
    !
    ! DESCRIPTION:
    !   Implements macropore physics - dramatic K increase when soil
    !   exceeds saturation threshold. See module header for detailed physics.
    !
    !   [Full implementation preserved exactly from original - see below]
    !
    ! ARGUMENTS:
    !   ku - Hydraulic conductivity K [real*8, inout]
    !   iv - Vertical node index [integer, input]
    !   il - Horizontal node index [integer, input]
    !   ih - Hillslope index [integer, input]
    !===========================================================================
    subroutine chk_ma(ku, iv, il, ih)
        use soil_properties_module, only: s_tab, iactab, sattgr, anisot
        use mesh_geometry_module, only: iacnv, iboden, macro, b_mac, &
                                         kxx, kee, kxe, kxxf, keef, kxef, &
                                         w_xshr, lmak, m_aniso
        use state_variables_module, only: theta, mak_an
        implicit none

        integer(4), intent(in) :: iv, il, ih
        real(8), intent(inout) :: ku

        real(8) :: th_gr, mak_gr, mfak
        real(8) :: strahl2  ! External function

        intrinsic :: cos, sin, abs

        mak_gr = 1.0d0
        mak_an(iv,il) = .false.

        ! Check if macropores are active for this hillslope
        if (lmak(ih)) then

            ! Surface runoff triggered macropore activation:
            ! If surface node and node below are saturated, activate macropores
            th_gr = sattgr(iboden(iacnv(ih),il,ih)) * &
                    s_tab(iactab(iboden(iacnv(ih),il,ih)), 1, iboden(iacnv(ih),il,ih))

            if (theta(iacnv(ih),il) > th_gr .and. theta(iacnv(ih)-1,il) > th_gr) then
                if (macro(iv,il,ih) > 1.0d0) then
                    mfak = strahl2(mak_gr, macro(iv,il,ih), th_gr, &
                                   s_tab(iactab(iboden(iacnv(ih),il,ih)), 1, &
                                         iboden(iacnv(ih),il,ih)), &
                                   theta(iacnv(ih),il), b_mac(iacnv(ih),il,ih))
                    ku = ku * mfak
                    mak_an(iv,il) = .true.
                end if

            else
                ! Normal macropore activation: threshold exceedance
                th_gr = sattgr(iboden(iv,il,ih)) * &
                        s_tab(iactab(iboden(iv,il,ih)), 1, iboden(iv,il,ih))

                if (theta(iv,il) > th_gr) then
                    if (macro(iv,il,ih) > 1.0d0) then
                        mfak = strahl2(mak_gr, macro(iv,il,ih), th_gr, &
                                       s_tab(iactab(iboden(iv,il,ih)), 1, iboden(iv,il,ih)), &
                                       theta(iv,il), b_mac(iv,il,ih))
                        ku = ku * mfak
                        mak_an(iv,il) = .true.
                    end if
                end if
            end if

            ! Anisotropic macropore modifications
            if (mak_an(iv,il)) then
                ! m_aniso = 1: Vertical macropores (gravity direction)
                if (m_aniso == 1) then
                    kxx(iv,il,ih) = anisot(1,iboden(iv,il,ih)) / mfak * &
                                     cos(w_xshr(iv,il))**2 + &
                                     anisot(2,iboden(iv,il,ih)) * sin(w_xshr(iv,il))**2
                    kee(iv,il,ih) = anisot(1,iboden(iv,il,ih)) / mfak * &
                                     sin(w_xshr(iv,il))**2 + &
                                     anisot(2,iboden(iv,il,ih)) * cos(w_xshr(iv,il))**2
                    kxe(iv,il,ih) = (anisot(1,iboden(iv,il,ih)) / mfak - &
                                     anisot(2,iboden(iv,il,ih))) * &
                                     cos(w_xshr(iv,il)) * sin(w_xshr(iv,il))
                    if (kxe(iv,il,ih) < 0.0d0) then
                        kxe(iv,il,ih) = -1.0d0 * kxe(iv,il,ih)
                    end if

                ! m_aniso = 2: Horizontal macropores (downslope direction)
                else if (m_aniso == 2) then
                    kee(iv,il,ih) = keef(iv,il,ih) / mfak
                    kxe(iv,il,ih) = kxef(iv,il,ih) / mfak

                ! m_aniso = 0: Isotropic macropores
                else
                    kxx(iv,il,ih) = kxxf(iv,il,ih)
                    kee(iv,il,ih) = keef(iv,il,ih)
                    kxe(iv,il,ih) = kxef(iv,il,ih)
                end if
            end if

            ! Safety checks
            if (kxx(iv,il,ih) < 0.0d0) then
                write(6,*) kxx(iv,il,ih), 'kxx'
                stop 'Fehler in CHK_MA'
            else if (kxe(iv,il,ih) < 0.0d0) then
                write(6,*) kxe(iv,il,ih), 'kxe', cos(w_xshr(iv,il))
                write(6,*) sin(w_xshr(iv,il)), mfak
                stop 'Fehler in CHK_MA'
            else if (kee(iv,il,ih) < 0.0d0) then
                write(6,*) kee(iv,il,ih), 'kee'
                stop 'Fehler in CHK_MA'
            end if

        end if  ! lmak(ih)

        return
    end subroutine chk_ma

    !===========================================================================
    ! FUNCTION: c_psi
    !
    ! PURPOSE: Water capacity C(ψ) via table interpolation
    !
    ! DESCRIPTION:
    !   Returns water capacity dθ/dψ [1/m] for given pressure head.
    !   Uses lookup with position hint for performance.
    !
    !   Extrapolation:
    !   - ψ < ψ_min (too dry): return C_min (table entry 1)
    !   - ψ > ψ_max (saturated): return C_max (table entry iactab)
    !   - ψ_min ≤ ψ ≤ ψ_max: linear interpolation
    !
    ! ARGUMENTS:
    !   iboden  - Soil type index [integer, input]
    !   psiact  - Pressure head ψ [real*8, input]
    !   ipos    - Position hint [integer, inout]
    !
    ! RETURNS:
    !   c_psi - Water capacity C [real*8, 1/m]
    !===========================================================================
    double precision function c_psi(iboden, psiact, ipos)
        use soil_properties_module, only: s_tab, iactab
        implicit none

        integer(4), intent(in) :: iboden
        real(8), intent(in) :: psiact
        integer(4), intent(inout) :: ipos

        logical :: hoch, tief
        real(8) :: cact

        call lookup(s_tab(1,2,iboden), s_tab(1,4,iboden), iactab(iboden), &
                    psiact, cact, hoch, tief, ipos)

        if (hoch) then
            c_psi = s_tab(1, 4, iboden)
        else if (tief) then
            c_psi = s_tab(iactab(iboden), 4, iboden)
        else
            c_psi = cact
        end if

        return
    end function c_psi

    !===========================================================================
    ! FUNCTION: k_psi
    !
    ! PURPOSE: Hydraulic conductivity K(ψ) via table interpolation
    !
    ! RETURNS: K [m/s]
    !===========================================================================
    double precision function k_psi(iboden, psiact, ipos)
        use soil_properties_module, only: s_tab, iactab
        implicit none

        integer(4), intent(in) :: iboden
        real(8), intent(in) :: psiact
        integer(4), intent(inout) :: ipos

        logical :: hoch, tief
        real(8) :: kact

        call lookup(s_tab(1,2,iboden), s_tab(1,3,iboden), iactab(iboden), &
                    psiact, kact, hoch, tief, ipos)

        if (hoch) then
            ! k_min (driest)
            k_psi = s_tab(1, 3, iboden)
        else if (tief) then
            ! k_s (saturated)
            k_psi = s_tab(iactab(iboden), 3, iboden)
        else
            k_psi = kact
        end if

        return
    end function k_psi

    !===========================================================================
    ! FUNCTION: k_th
    !
    ! PURPOSE: Hydraulic conductivity K(θ) via table interpolation
    !
    ! RETURNS: K [m/s]
    !===========================================================================
    double precision function k_th(iboden, th_act, ipos)
        use soil_properties_module, only: s_tab, iactab
        implicit none

        integer(4), intent(in) :: iboden
        real(8), intent(in) :: th_act
        integer(4), intent(inout) :: ipos

        logical :: hoch, tief
        real(8) :: kact

        call lookup(s_tab(1,1,iboden), s_tab(1,3,iboden), iactab(iboden), &
                    th_act, kact, hoch, tief, ipos)

        if (hoch) then
            ! k_s (saturated, high θ)
            k_th = s_tab(iactab(iboden), 3, iboden)
        else if (tief) then
            ! k_min (dry, low θ)
            k_th = s_tab(1, 3, iboden)
        else
            k_th = kact
        end if

        return
    end function k_th

    !===========================================================================
    ! FUNCTION: th_psi
    !
    ! PURPOSE: Water content θ(ψ) via table interpolation
    !
    ! RETURNS: θ [-]
    !===========================================================================
    double precision function th_psi(iboden, psiact, ipos)
        use soil_properties_module, only: s_tab, iactab
        implicit none

        integer(4), intent(in) :: iboden
        real(8), intent(in) :: psiact
        integer(4), intent(inout) :: ipos

        logical :: hoch, tief
        real(8) :: thact

        call lookup(s_tab(1,2,iboden), s_tab(1,1,iboden), iactab(iboden), &
                    psiact, thact, hoch, tief, ipos)

        if (hoch) then
            ! theta_r (driest)
            th_psi = s_tab(1, 1, iboden)
        else if (tief) then
            ! theta_s (saturated)
            th_psi = s_tab(iactab(iboden), 1, iboden)
        else
            th_psi = thact
        end if

        return
    end function th_psi

    !===========================================================================
    ! FUNCTION: psi_th
    !
    ! PURPOSE: Pressure head ψ(θ) via table interpolation
    !
    ! RETURNS: ψ [m]
    !
    ! NOTES:
    !   Cannot determine ψ at saturation (θ = θ_s) because ψ → -∞
    !   Stops with error if hoch = .true.
    !===========================================================================
    double precision function psi_th(iboden, thact, ipos)
        use soil_properties_module, only: s_tab, iactab
        implicit none

        integer(4), intent(in) :: iboden
        real(8), intent(in) :: thact
        integer(4), intent(inout) :: ipos

        logical :: hoch, tief
        real(8) :: psiact

        call lookup(s_tab(1,1,iboden), s_tab(1,2,iboden), iactab(iboden), &
                    thact, psiact, hoch, tief, ipos)

        if (hoch) then
            stop 'error in psi_th, psi(th_s) kann nicht angegeben werden'
        else if (tief) then
            psi_th = s_tab(1, 2, iboden)
        else
            psi_th = psiact
        end if

        return
    end function psi_th

    !===========================================================================
    ! SUBROUTINE: lookup
    !
    ! PURPOSE: Table interpolation with position hint
    !
    ! DESCRIPTION:
    !   Performs linear interpolation in monotonic table with hunt algorithm
    !   for fast position finding.
    !
    !   For x in [x(i), x(i+1)]:
    !   y = y(i) + [y(i+1) - y(i)] · [x - x(i)] / [x(i+1) - x(i)]
    !
    !   Flags:
    !   hoch = .true. if x > max(table) (extrapolate high)
    !   tief = .true. if x < min(table) (extrapolate low)
    !
    !   Uses hunt for O(1) search with position hint.
    !
    ! ARGUMENTS:
    !   xsp  - Independent variable table [real*8(*), input]
    !   ysp  - Dependent variable table [real*8(*), input]
    !   nsp  - Table size [integer, input]
    !   xval - Query value [real*8, input]
    !   yval - Interpolated value [real*8, output]
    !   hoch - Extrapolate high flag [logical, output]
    !   tief - Extrapolate low flag [logical, output]
    !   isp  - Position hint [integer, inout]
    !===========================================================================
    subroutine lookup(xsp, ysp, nsp, xval, yval, hoch, tief, isp)
        implicit none

        real(8), intent(in) :: xsp(*), ysp(*)
        real(8), intent(in) :: xval
        real(8), intent(out) :: yval
        integer(4), intent(in) :: nsp
        integer(4), intent(inout) :: isp
        logical, intent(out) :: hoch, tief

        real(8) :: eps

        intrinsic :: dmin1, dmax1

        hoch = .false.
        tief = .false.
        eps  = 1.0d-5

        ! Find interval using hunt (position hint)
        call hunt(xsp, nsp, xval, isp)

        ! Interpolate if within table bounds
        if ((isp > 0) .and. (isp < nsp)) then
            yval = ysp(isp) + &
                   (ysp(isp+1) - ysp(isp)) * &
                   (xval - xsp(isp)) / (xsp(isp+1) - xsp(isp))
            return
        end if

        ! Check for extrapolation beyond table
        if (xval >= dmax1(xsp(1), xsp(nsp)) - eps) then
            hoch = .true.
            return
        end if
        if (xval <= dmin1(xsp(1), xsp(nsp)) + eps) then
            tief = .true.
            return
        end if

        stop 'Fehler in LOOKUP'
    end subroutine lookup

    !===========================================================================
    ! SUBROUTINE: LOCATE
    !
    ! PURPOSE: Binary search to find interval containing X
    !
    ! DESCRIPTION:
    !   Finds J such that X lies between XX(J) and XX(J+1).
    !   Uses interval halving (bisection method).
    !   From Numerical Recipes.
    !
    ! ARGUMENTS:
    !   XX - Sorted array [real*8(*), input]
    !   N  - Array size [integer, input]
    !   X  - Search value [real*8, input]
    !   J  - Interval index [integer, output]
    !===========================================================================
    subroutine LOCATE(XX, N, X, J)
        implicit none

        real(8), intent(in) :: XX(*), X
        integer(4), intent(in) :: N
        integer(4), intent(out) :: J

        integer(4) :: JL, JU, JM

        JL = 0
        JU = N + 1
10      if (JU - JL > 1) then
            JM = (JU + JL) / 2
            if ((XX(N) > XX(1)) .eqv. (X > XX(JM))) then
                JL = JM
            else
                JU = JM
            end if
            go to 10
        end if
        J = JL

        return
    end subroutine LOCATE

    !===========================================================================
    ! SUBROUTINE: HUNT
    !
    ! PURPOSE: Binary search with position hint
    !
    ! DESCRIPTION:
    !   Finds JLO such that X lies between XX(JLO) and XX(JLO+1).
    !   Starts search near initial JLO guess (position hint).
    !   Much faster than LOCATE when successive calls have correlated X values.
    !   From Numerical Recipes.
    !
    !   Algorithm:
    !   1. If JLO valid: search outward by doubling increment
    !   2. Once bracket found: use interval halving
    !   3. If JLO invalid: revert to full bisection
    !
    ! ARGUMENTS:
    !   XX  - Sorted array [real*8(*), input]
    !   N   - Array size [integer, input]
    !   X   - Search value [real*8, input]
    !   JLO - Position hint / result [integer, inout]
    !===========================================================================
    subroutine HUNT(XX, N, X, JLO)
        implicit none

        real(8), intent(in) :: XX(*), X
        integer(4), intent(in) :: N
        integer(4), intent(inout) :: JLO

        integer(4) :: JHI, JM, INC
        logical :: ASCND

        ASCND = XX(N) > XX(1)

        ! Check if JLO is valid
        if (JLO <= 0 .or. JLO > N) then
            JLO = 0
            JHI = N + 1
            go to 3
        end if

        INC = 1

        ! Hunt upward
        if (X >= XX(JLO) .eqv. ASCND) then
1           JHI = JLO + INC
            if (JHI > N) then
                JHI = N + 1
            else if (X >= XX(JHI) .eqv. ASCND) then
                JLO = JHI
                INC = INC + INC
                go to 1
            end if

        ! Hunt downward
        else
            JHI = JLO
2           JLO = JHI - INC
            if (JLO < 1) then
                JLO = 0
            else if (X < XX(JLO) .eqv. ASCND) then
                JHI = JLO
                INC = INC + INC
                go to 2
            end if
        end if

        ! Bisection
3       if (JHI - JLO == 1) return
        JM = (JHI + JLO) / 2
        if (X > XX(JM) .eqv. ASCND) then
            JLO = JM
        else
            JHI = JM
        end if
        go to 3

    end subroutine HUNT

end module bodtab_module
