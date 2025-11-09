!===============================================================================
! MODULE: koeffrb_module
!
! PURPOSE:
!   Boundary coefficient calculation for CATFLOW Richards equation solver
!
! DESCRIPTION:
!   Calculates finite difference coefficients at domain boundaries for the
!   Richards equation in curvilinear coordinates. Implements various boundary
!   condition types for all four boundaries: bottom (unten), top (oben),
!   right (rechts), and left (links).
!
!   IMPORTANT NOTES:
!   - At corner points, either one potential and one flux OR two fluxes must
!     be specified
!   - All physics and numerical methods are preserved exactly from KOEFFRB.f
!   - This is a syntactic modernization only
!
! BOUNDARY CONDITION TYPES (irbtyp or direct irb_*):
!
!   FLUX BOUNDARIES (Neumann, Type 2):
!   ==================================
!   0    : Zero flux (no-flow boundary)
!   1    : Prescribed flux [L/T] (can be time series)
!   3    : Gravity flux (unit gradient)
!   5    : Leakage boundary (mixed BC): q = K_leak * (h_ext - h)
!   -3   : Gravity flux (pauschal/direct specification)
!   -5   : Free outflow/zero divergence
!
!   POTENTIAL BOUNDARIES (Dirichlet, Type 1):
!   ==========================================
!   -1   : Suction head [L] (matric potential)
!   -2   : Potential relative to *.GEO file datum [L]
!   -4   : Hold old value (keep previous timestep potential)
!
!   SPECIAL BOUNDARIES:
!   ===================
!   10   : Seepage face (one-sided BC): flux=0 OR potential=h_seepage
!   11   : One-sided BC with specified flux and potential thresholds
!   -10  : Seepage face (pauschal specification)
!   -99  : Atmospheric boundary (climate-driven):
!          - Top: precipitation/evaporation
!          - Bottom: gravity flux
!          - Sides: zero flux or stream coupling
!   99   : Atmospheric BC (time series - not yet implemented)
!
! COORDINATE SYSTEM:
!   - XSI (ξ): horizontal coordinate (along slope)
!   - ETA (η): vertical coordinate (perpendicular to slope)
!   - IL: column index (1=left/top, iacnl=right/bottom)
!   - IV: layer index (1=bottom, iacnv=top)
!
! BOUNDARY LAYOUT:
!   Top (oben) - iv=iacnv
!   |‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾|
!   |                  |
! L |                  | R
! e |                  | i
! f |                  | g
! t |                  | h
!   |                  | t
!   |__________________|
!   Bottom (unten) - iv=1
!
! ORIGINAL: KOEFFRB.f (Fortran 77)
! AUTHOR: CATFLOW Streamlined
! DATE: 2025-11-07
!===============================================================================
module koeffrb_module
    use constants_module, only: maxnv, maxnl
    implicit none
    private

    public :: koeffrb

contains

    !===========================================================================
    ! SUBROUTINE: koeffrb
    !
    ! PURPOSE: Calculate boundary coefficients for Richards equation
    !
    ! ARGUMENTS:
    !   ih - Hillslope index
    !   dt - Time step [s]
    !===========================================================================
    subroutine koeffrb(ih, dt)
        use state_data_module, only: Fx_m1, Fx_00, Fx_p1, Fe_m1, Fe_00, Fe_p1, &
                                      RS, vorfak, durchl, phialt, q_eta, q_xsi, &
                                      theta, psi, mak_an, tabpos, A_x, A2x, &
                                      A_e, A2e
        use mesh_geometry_module, only: iacnv, iacnl, f_xsi, f_eta, &
                                         slopeu, slopeo, sloper, slopel, &
                                         hko, hkomin, e_p1m0, x_p1m0, &
                                         fbrup, fbrlow, iboden, imod
        use boundary_conditions_module, only: irb_u, irb_o, irb_r, irb_l, &
                                               irbtyp, rbpar, lrintp, zrbf, &
                                               vorz_u, vorz_o, vorz_r, vorz_l, &
                                               qu_pot, pu_pot, qo_pot, po_pot, &
                                               qr_pot, pr_pot, ql_pot, pl_pot, &
                                               rfl_u, rfl_o, rfl_r, rfl_l, &
                                               cil_o
        use time_module, only: t_act, istact
        use atmosphere_module, only: neff, Esoil, yoben
        use stream_module, only: auint, inter, ihgb, hangnr, y_bach, y_vorl
        implicit none

        integer(4), intent(in) :: ih
        real(8), intent(in) :: dt

        integer(4) :: iv, il, istp, ib
        real(8) :: dnull
        real(8), external :: strahl

        intrinsic abs, cos

        dnull = 0.0d0
        ib = 0

        ! =====================================================================
        ! BOTTOM BOUNDARY (unten)
        ! =====================================================================
        iv = 1
        do il = 1, iacnl(ih)

            ! =================================================================
            ! PAUSCHAL (direct specification without time series)
            ! =================================================================

            ! -----------------------------------------------------------------
            ! Zero flux
            ! -----------------------------------------------------------------
            if (irb_u(il,ih) .eq. 0) then
                qu_pot(il) = 0.0d0

            ! -----------------------------------------------------------------
            ! Gravity flux
            ! -----------------------------------------------------------------
            elseif (irb_u(il,ih) .eq. -3) then
                qu_pot(il) = -durchl(iv,il) / slopeu(il,ih)

            ! -----------------------------------------------------------------
            ! Hold old value
            ! -----------------------------------------------------------------
            elseif (irb_u(il,ih) .eq. -4) then
                pu_pot(il) = phialt(iv,il,ih)

            ! -----------------------------------------------------------------
            ! Zero divergence / free outflow
            ! -----------------------------------------------------------------
            elseif (irb_u(iv,ih) .eq. -5) then
                if (q_eta(iv+1, il) .lt. 0.0d0) then
                    qu_pot(il) = q_eta(iv+1, il)
                elseif (q_eta(iv+1, il) .ge. 0.0d0) then
                    qu_pot(il) = 0.0d0
                end if

            ! -----------------------------------------------------------------
            ! Seepage face (one-sided BC)
            ! -----------------------------------------------------------------
            elseif (irb_u(il,ih) .eq. -10) then
                qu_pot(il) = 0.0d0
                pu_pot(il) = hko(iv,il,ih)

            ! -----------------------------------------------------------------
            ! Atmospheric (bottom: gravity flux)
            ! -----------------------------------------------------------------
            elseif (irb_u(il,ih) .eq. -99) then
                qu_pot(il) = -durchl(iv,il) / slopeu(il,ih)
                pu_pot(il) = hko(iv,il,ih) + 999999.0d0

            ! =================================================================
            ! TIME SERIES (Zeitreihe)
            ! =================================================================
            else

                ! -------------------------------------------------------------
                ! Zero flux with optional time series
                ! -------------------------------------------------------------
                if (irbtyp(1,irb_u(il,ih)) .eq. 0) then
                    if (lrintp(irb_u(il,ih))) then
                        qu_pot(il) = strahl(dnull, rbpar(2,1,irb_u(il,ih)), &
                                            zrbf(1,irb_u(il,ih)), zrbf(2,irb_u(il,ih)), &
                                            t_act+dt)
                    else
                        qu_pot(il) = 0.0d0
                    endif

                ! -------------------------------------------------------------
                ! Prescribed flux
                ! -------------------------------------------------------------
                elseif (irbtyp(1,irb_u(il,ih)) .eq. 1) then
                    if (lrintp(irb_u(il,ih))) then
                        qu_pot(il) = strahl(rbpar(1,1,irb_u(il,ih)), &
                                            rbpar(2,1,irb_u(il,ih)), &
                                            zrbf(1,irb_u(il,ih)), zrbf(2,irb_u(il,ih)), &
                                            t_act+dt)
                    else
                        qu_pot(il) = rbpar(1,1,irb_u(il,ih))
                    endif

                ! -------------------------------------------------------------
                ! Gravity flux
                ! -------------------------------------------------------------
                elseif (irbtyp(1,irb_u(il,ih)) .eq. 3) then
                    qu_pot(il) = -durchl(iv,il) / slopeu(il,ih)

                ! -------------------------------------------------------------
                ! Leakage boundary (mixed BC)
                ! -------------------------------------------------------------
                elseif (irbtyp(1,irb_u(il,ih)) .eq. 5) then
                    qu_pot(il) = rbpar(1,1,irb_u(il,ih)) * &
                                 ( rbpar(1,2,irb_u(il,ih)) &
                                   - ( hko(iv,il,ih) + hkomin(ih) - psi(iv,il) ) )

                ! -------------------------------------------------------------
                ! Suction head
                ! -------------------------------------------------------------
                elseif (irbtyp(1,irb_u(il,ih)) .eq. -1) then
                    if (lrintp(irb_u(il,ih))) then
                        pu_pot(il) = hko(iv,il,ih) - strahl(rbpar(1,1,irb_u(il,ih)), &
                                                             rbpar(2,1,irb_u(il,ih)), &
                                                             zrbf(1,irb_u(il,ih)), &
                                                             zrbf(2,irb_u(il,ih)), &
                                                             t_act+dt)
                    else
                        pu_pot(il) = hko(iv,il,ih) - rbpar(1,1,irb_u(il,ih))
                    endif

                ! -------------------------------------------------------------
                ! Potential relative to *.GEO file
                ! -------------------------------------------------------------
                elseif (irbtyp(1,irb_u(il,ih)) .eq. -2) then
                    if (lrintp(irb_u(il,ih))) then
                        pu_pot(il) = strahl(rbpar(1,1,irb_u(il,ih)), &
                                            rbpar(2,1,irb_u(il,ih)), &
                                            zrbf(1,irb_u(il,ih)), zrbf(2,irb_u(il,ih)), &
                                            t_act+dt) - hkomin(ih)
                    else
                        pu_pot(il) = rbpar(1,1,irb_u(il,ih)) - hkomin(ih)
                    endif

                ! -------------------------------------------------------------
                ! Hold old value
                ! -------------------------------------------------------------
                elseif (irbtyp(1,irb_u(il,ih)) .eq. -4) then
                    pu_pot(il) = phialt(iv,il,ih)

                ! -------------------------------------------------------------
                ! Seepage face (one-sided BC)
                ! -------------------------------------------------------------
                elseif (abs(irbtyp(1,irb_u(il,ih))) .eq. 10) then
                    qu_pot(il) = 0.0d0
                    pu_pot(il) = hko(iv,il,ih)

                ! -------------------------------------------------------------
                ! One-sided BC
                ! -------------------------------------------------------------
                elseif (abs(irbtyp(1,irb_u(il,ih))) .eq. 11) then
                    qu_pot(il) = rbpar(1,2,irb_u(il,ih))
                    pu_pot(il) = hko(iv,il,ih) - rbpar(1,1,irb_u(il,ih))

                ! -------------------------------------------------------------
                ! Atmospheric (bottom: gravity flux)
                ! -------------------------------------------------------------
                elseif (abs(irbtyp(1,irb_u(il,ih))) .eq. 99) then
                    qu_pot(il) = -durchl(iv,il) / slopeu(il,ih)
                    pu_pot(il) = hko(iv,il,ih) + 999999.0d0

                else
                    stop 'Fehler am unteren Rand'
                endif
            endif

            ! =================================================================
            ! Apply boundary condition to coefficient matrix
            ! =================================================================

            if (vorz_u(il,ih) .gt. 0) then
                ! RB 2.Art, Neumann, Fluss (Flux BC)
                ! Skip corner points where perpendicular BC is Dirichlet
                if ( (il.eq.1)         .and. (vorz_l(iv,ih) .lt. 0)) goto 10
                if ( (il.eq.iacnl(ih)) .and. (vorz_r(iv,ih) .lt. 0)) goto 10

                Fe_p1(iv,il) = - A_e(iv,il) * vorfak(iv,il) / e_p1m0(iv,ih)
                Fe_00(iv,il) = - Fe_p1(iv,il)
                RS(iv,il)    = RS(iv,il) &
                               + 2.0d0 * f_xsi(iv,il,ih) * qu_pot(il) * &
                                 vorfak(iv,il) / e_p1m0(iv,ih)
10              continue
                rfl_u(il) = qu_pot(il)

            elseif (vorz_u(il,ih) .lt. 0) then
                ! RB 1.Art, Dirichlet, Potential (Potential BC)
                Fe_p1(iv,il) = 0.0d0
                Fe_00(iv,il) = -0.5d0
                Fx_00(iv,il) = -0.5d0
                Fx_p1(iv,il) = 0.0d0
                Fx_m1(iv,il) = 0.0d0
                RS(iv,il)    = -pu_pot(il)
            endif

        end do  ! il loop

        ! =====================================================================
        ! TOP BOUNDARY (oben, i.e., Atmosphere)
        ! =====================================================================
        iv = iacnv(ih)
        do il = 1, iacnl(ih)

            ! =================================================================
            ! PAUSCHAL (direct specification without time series)
            ! =================================================================

            ! -----------------------------------------------------------------
            ! Zero flux
            ! -----------------------------------------------------------------
            if (irb_o(il,ih) .eq. 0) then
                qo_pot(il) = 0.0d0

            ! -----------------------------------------------------------------
            ! Gravity flux
            ! -----------------------------------------------------------------
            elseif (irb_o(il,ih) .eq. -3) then
                qo_pot(il) = -durchl(iv,il) / slopeo(il,ih)

            ! -----------------------------------------------------------------
            ! Hold old value
            ! -----------------------------------------------------------------
            elseif (irb_o(il,ih) .eq. -4) then
                po_pot(il) = phialt(iv,il,ih)

            ! -----------------------------------------------------------------
            ! Seepage face (one-sided BC)
            ! -----------------------------------------------------------------
            elseif (irb_o(il,ih) .eq. -10) then
                qo_pot(il) = 0.0d0
                po_pot(il) = hko(iv,il,ih)

            ! -----------------------------------------------------------------
            ! Atmospheric (top: climate)
            ! -----------------------------------------------------------------
            elseif (irb_o(il,ih) .eq. -99) then
                ! Ulli's version, modified slopeo jw
                qo_pot(il) = (-neff(il) + Esoil(il)) * slopeo(il,ih) &
                             - yoben(il) / slopeo(il,ih) / dt
                ! jw: Limit with infiltration capacity? - min(durchl(iacnv(ih), il) * (grad_z - 1))
                po_pot(il) = hko(iv,il,ih) + yoben(il) + (neff(il)) * dt

            ! =================================================================
            ! TIME SERIES (Zeitreihe)
            ! =================================================================
            else

                ! -------------------------------------------------------------
                ! Zero flux with optional time series
                ! -------------------------------------------------------------
                if (irbtyp(1,irb_o(il,ih)) .eq. 0) then
                    if (lrintp(irb_o(il,ih))) then
                        qo_pot(il) = strahl(dnull, rbpar(2,1,irb_o(il,ih)), &
                                            zrbf(1,irb_o(il,ih)), zrbf(2,irb_o(il,ih)), &
                                            t_act+dt)
                        do istp = 1, istact
                            cil_o(istp,il,ih) = strahl(rbpar(1,istp+1,irb_o(il,ih)), &
                                                       rbpar(2,istp+1,irb_o(il,ih)), &
                                                       zrbf(1,irb_o(il,ih)), &
                                                       zrbf(2,irb_o(il,ih)), &
                                                       t_act+dt)
                        end do
                    else
                        qo_pot(il) = 0.0d0
                        do istp = 1, istact
                            cil_o(istp,il,ih) = 0.0d0
                        end do
                    endif

                ! -------------------------------------------------------------
                ! Prescribed flux
                ! -------------------------------------------------------------
                elseif (irbtyp(1,irb_o(il,ih)) .eq. 1) then
                    if (lrintp(irb_o(il,ih))) then
                        qo_pot(il) = strahl(rbpar(1,1,irb_o(il,ih)), &
                                            rbpar(2,1,irb_o(il,ih)), &
                                            zrbf(1,irb_o(il,ih)), zrbf(2,irb_o(il,ih)), &
                                            t_act+dt)
                        do istp = 1, istact
                            cil_o(istp,il,ih) = strahl(rbpar(1,istp+1,irb_o(il,ih)), &
                                                       rbpar(2,istp+1,irb_o(il,ih)), &
                                                       zrbf(1,irb_o(il,ih)), &
                                                       zrbf(2,irb_o(il,ih)), &
                                                       t_act+dt)
                        end do
                    else
                        qo_pot(il) = rbpar(1,1,irb_o(il,ih))
                        do istp = 1, istact
                            cil_o(istp,il,ih) = rbpar(1,istp+1,irb_o(il,ih))
                        end do
                    endif

                ! -------------------------------------------------------------
                ! Gravity flux
                ! -------------------------------------------------------------
                elseif (irbtyp(1,irb_o(il,ih)) .eq. 3) then
                    qo_pot(il) = -durchl(iv,il) / slopeo(il,ih)

                ! -------------------------------------------------------------
                ! Leakage boundary (mixed BC)
                ! -------------------------------------------------------------
                elseif (irbtyp(1,irb_o(il,ih)) .eq. 5) then
                    qo_pot(il) = rbpar(1,1,irb_o(il,ih)) * &
                                 ( rbpar(1,2,irb_o(il,ih)) &
                                   - ( hko(iv,il,ih) + hkomin(ih) - psi(iv,il) ) )

                ! -------------------------------------------------------------
                ! Suction head
                ! -------------------------------------------------------------
                elseif (irbtyp(1,irb_o(il,ih)) .eq. -1) then
                    if (lrintp(irb_o(il,ih))) then
                        po_pot(il) = hko(iv,il,ih) - strahl(rbpar(1,1,irb_o(il,ih)), &
                                                             rbpar(2,1,irb_o(il,ih)), &
                                                             zrbf(1,irb_o(il,ih)), &
                                                             zrbf(2,irb_o(il,ih)), &
                                                             t_act+dt)
                    else
                        po_pot(il) = hko(iv,il,ih) - rbpar(1,1,irb_o(il,ih))
                    endif

                ! -------------------------------------------------------------
                ! Potential relative to *.GEO file
                ! -------------------------------------------------------------
                elseif (irbtyp(1,irb_o(il,ih)) .eq. -2) then
                    if (lrintp(irb_o(il,ih))) then
                        po_pot(il) = strahl(rbpar(1,1,irb_o(il,ih)), &
                                            rbpar(2,1,irb_o(il,ih)), &
                                            zrbf(1,irb_o(il,ih)), zrbf(2,irb_o(il,ih)), &
                                            t_act+dt) - hkomin(ih)
                    else
                        po_pot(il) = rbpar(1,1,irb_o(il,ih)) - hkomin(ih)
                    endif

                ! -------------------------------------------------------------
                ! Hold old value
                ! -------------------------------------------------------------
                elseif (irbtyp(1,irb_o(il,ih)) .eq. -4) then
                    po_pot(il) = phialt(iv,il,ih)

                ! -------------------------------------------------------------
                ! Seepage face (one-sided BC)
                ! -------------------------------------------------------------
                elseif (abs(irbtyp(1,irb_o(il,ih))) .eq. 10) then
                    qo_pot(il) = 0.0d0
                    po_pot(il) = hko(iv,il,ih)

                ! -------------------------------------------------------------
                ! One-sided BC
                ! -------------------------------------------------------------
                elseif (abs(irbtyp(1,irb_o(il,ih))) .eq. 11) then
                    qo_pot(il) = rbpar(1,2,irb_o(il,ih))
                    po_pot(il) = hko(iv,il,ih) - rbpar(1,1,irb_o(il,ih))
                    do istp = 1, istact
                        cil_o(istp,il,ih) = rbpar(1,istp+2,irb_o(il,ih))
                    end do

                ! -------------------------------------------------------------
                ! Atmospheric (top: climate)
                ! -------------------------------------------------------------
                elseif (abs(irbtyp(1,irb_o(il,ih))) .eq. 99) then
                    stop '99 noch nicht implementiert'

                else
                    stop 'Fehler am oberen Rand'
                endif
            endif

            ! =================================================================
            ! Apply boundary condition to coefficient matrix
            ! =================================================================

            if (vorz_o(il,ih) .gt. 0) then
                ! RB 2.Art, Neumann, Fluss (Flux BC)
                ! Skip corner points where perpendicular BC is Dirichlet
                if ( (il.eq.1)         .and. (vorz_l(iv,ih) .lt. 0)) goto 20
                if ( (il.eq.iacnl(ih)) .and. (vorz_r(iv,ih) .lt. 0)) goto 20

                Fe_m1(iv,il) = - A_e(iv-1,il) * vorfak(iv,il) / e_p1m0(iv-1,ih)
                Fe_00(iv,il) = - Fe_m1(iv,il)
                RS(iv,il)    = RS(iv,il) &
                               - 2.0d0 * f_xsi(iv,il,ih) * qo_pot(il) * &
                                 vorfak(iv,il) / e_p1m0(iv-1,ih)
20              continue
                rfl_o(il) = qo_pot(il)

            elseif (vorz_o(il,ih) .lt. 0) then
                ! RB 1.Art, Dirichlet, Potential (Potential BC)
                Fe_m1(iv,il) = 0.0d0
                Fe_00(iv,il) = -0.5d0
                Fx_00(iv,il) = -0.5d0
                Fx_p1(iv,il) = 0.0d0
                Fx_m1(iv,il) = 0.0d0
                RS(iv,il)    = -po_pot(il)
            endif

        end do  ! il loop

        ! =====================================================================
        ! RIGHT BOUNDARY (rechts, i.e., Hangfuss/hillslope toe)
        ! =====================================================================
        il = iacnl(ih)
        do iv = 1, iacnv(ih)

            ! =================================================================
            ! PAUSCHAL (direct specification without time series)
            ! =================================================================

            ! -----------------------------------------------------------------
            ! Zero flux
            ! -----------------------------------------------------------------
            if (irb_r(iv,ih) .eq. 0) then
                qr_pot(iv) = 0.0d0

            ! -----------------------------------------------------------------
            ! Gravity flux
            ! -----------------------------------------------------------------
            elseif (irb_r(iv,ih) .eq. -3) then
                qr_pot(iv) = durchl(iv,il) / sloper(iv,ih)

            ! -----------------------------------------------------------------
            ! Free outflow
            ! -----------------------------------------------------------------
            elseif (irb_r(iv,ih) .eq. -5) then
                if (q_xsi(iv, il-1) .gt. 0.0d0) then
                    qr_pot(iv) = q_xsi(iv, il-1)
                elseif (q_xsi(iv, il-1) .le. 0.0d0) then
                    qr_pot(iv) = 0.0d0
                end if

            ! -----------------------------------------------------------------
            ! Hold old value
            ! -----------------------------------------------------------------
            elseif (irb_r(iv,ih) .eq. -4) then
                pr_pot(iv) = phialt(iv,il,ih)

            ! -----------------------------------------------------------------
            ! Seepage face (one-sided BC)
            ! -----------------------------------------------------------------
            elseif (irb_r(iv,ih) .eq. -10) then
                qr_pot(iv) = 0.0d0
                if (imod(iboden(iv,il,ih)) .eq. 1) then
                    ! Modified by Theresa and Thomas 28.03.2008
                    pr_pot(iv) = -0.63d0 + hko(iv,il,ih)
                else
                    write(6,*) ' Seepage boundary condition only defined for'
                    write(6,*) ' VanGenuchten soil hydraulic model!'
                    stop
                end if

            ! -----------------------------------------------------------------
            ! Atmospheric (right: Vorfluter/stream)
            ! -----------------------------------------------------------------
            elseif (irb_r(iv,ih) .eq. -99) then
                qr_pot(iv) = 0.0d0
                pr_pot(iv) = 9999999.0d0

            ! =================================================================
            ! TIME SERIES (Zeitreihe)
            ! =================================================================
            else

                ! -------------------------------------------------------------
                ! Zero flux with optional time series
                ! -------------------------------------------------------------
                if (irbtyp(1,irb_r(iv,ih)) .eq. 0) then
                    if (lrintp(irb_r(iv,ih))) then
                        qr_pot(iv) = strahl(dnull, rbpar(2,1,irb_r(iv,ih)), &
                                            zrbf(1,irb_r(iv,ih)), zrbf(2,irb_r(iv,ih)), &
                                            t_act+dt)
                    else
                        qr_pot(iv) = 0.0d0
                    endif

                ! -------------------------------------------------------------
                ! Prescribed flux
                ! -------------------------------------------------------------
                elseif (irbtyp(1,irb_r(iv,ih)) .eq. 1) then
                    if (lrintp(irb_r(iv,ih))) then
                        qr_pot(iv) = strahl(rbpar(1,1,irb_r(iv,ih)), &
                                            rbpar(2,1,irb_r(iv,ih)), &
                                            zrbf(1,irb_r(iv,ih)), zrbf(2,irb_r(iv,ih)), &
                                            t_act+dt)
                    else
                        qr_pot(iv) = rbpar(1,1,irb_r(iv,ih))
                    endif

                ! -------------------------------------------------------------
                ! Gravity flux
                ! -------------------------------------------------------------
                elseif (irbtyp(1,irb_r(iv,ih)) .eq. 3) then
                    qr_pot(iv) = durchl(iv,il) / sloper(iv,ih)

                ! -------------------------------------------------------------
                ! Leakage boundary (mixed BC)
                ! -------------------------------------------------------------
                elseif (irbtyp(1,irb_r(iv,ih)) .eq. 5) then
                    qr_pot(iv) = rbpar(1,1,irb_r(iv,ih)) * &
                                 ( rbpar(1,2,irb_r(iv,ih)) &
                                   - ( hko(iv,il,ih) + hkomin(ih) - psi(iv,il) ) )

                ! -------------------------------------------------------------
                ! Suction head
                ! -------------------------------------------------------------
                elseif (irbtyp(1,irb_r(iv,ih)) .eq. -1) then
                    ! Special handling for stream interaction
                    if (auint .and. inter(ihgb(hangnr(ih)))) then
                        pr_pot(iv) = hko(iacnv(ih),il,ih) + y_bach(ihgb(hangnr(ih))) - &
                                     y_vorl(ihgb(hangnr(ih))) - hko(iv,il,ih)
                    end if
                    if (lrintp(irb_r(iv,ih))) then
                        pr_pot(iv) = hko(iv,il,ih) - strahl(rbpar(1,1,irb_r(iv,ih)), &
                                                             rbpar(2,1,irb_r(iv,ih)), &
                                                             zrbf(1,irb_r(iv,ih)), &
                                                             zrbf(2,irb_r(iv,ih)), &
                                                             t_act+dt)
                    else
                        pr_pot(iv) = hko(iv,il,ih) - rbpar(1,1,irb_r(iv,ih))
                    endif

                ! -------------------------------------------------------------
                ! Potential relative to *.GEO file
                ! -------------------------------------------------------------
                elseif (irbtyp(1,irb_r(iv,ih)) .eq. -2) then
                    if (lrintp(irb_r(iv,ih))) then
                        pr_pot(iv) = strahl(rbpar(1,1,irb_r(iv,ih)), &
                                            rbpar(2,1,irb_r(iv,ih)), &
                                            zrbf(1,irb_r(iv,ih)), zrbf(2,irb_r(iv,ih)), &
                                            t_act+dt) - hkomin(ih)
                    else
                        pr_pot(iv) = rbpar(1,1,irb_r(iv,ih)) - hkomin(ih)
                    endif

                ! -------------------------------------------------------------
                ! Hold old value
                ! -------------------------------------------------------------
                elseif (irbtyp(1,irb_r(iv,ih)) .eq. -4) then
                    pr_pot(iv) = phialt(iv,il,ih)

                ! -------------------------------------------------------------
                ! Seepage face (one-sided BC)
                ! -------------------------------------------------------------
                elseif (abs(irbtyp(1,irb_r(iv,ih))) .eq. 10) then
                    qr_pot(iv) = 0.0d0
                    pr_pot(iv) = hko(iv,il,ih)

                ! -------------------------------------------------------------
                ! One-sided BC
                ! -------------------------------------------------------------
                elseif (abs(irbtyp(1,irb_r(iv,ih))) .eq. 11) then
                    qr_pot(iv) = rbpar(1,2,irb_r(iv,ih))
                    pr_pot(iv) = hko(iv,il,ih) - rbpar(1,1,irb_r(iv,ih))

                ! -------------------------------------------------------------
                ! Atmospheric (right: Vorfluter/stream)
                ! -------------------------------------------------------------
                elseif (abs(irbtyp(1,irb_r(iv,ih))) .eq. 99) then
                    stop '99 noch nicht implementiert'

                else
                    stop 'Fehler am rechten Rand'
                endif
            endif  ! end if right boundary

            ! =================================================================
            ! Apply boundary condition to coefficient matrix
            ! =================================================================

            if (vorz_r(iv,ih) .gt. 0) then
                ! RB 2.Art, Neumann, Fluss (Flux BC)
                ! Skip corner points where perpendicular BC is Dirichlet
                if ( (iv.eq.1)         .and. (vorz_u(il,ih) .lt. 0)) goto 30
                if ( (iv.eq.iacnv(ih)) .and. (vorz_o(il,ih) .lt. 0)) goto 30

                Fx_m1(iv,il) = - A_x(iv,il-1) * vorfak(iv,il) / x_p1m0(il-1,ih) &
                                 * fbrlow(il,ih)
                Fx_00(iv,il) = - Fx_m1(iv,il)
                RS(iv,il)    = RS(iv,il) &
                               - 2.0d0 * f_eta(iv,il,ih) * qr_pot(iv) * &
                                 vorfak(iv,il) / x_p1m0(il-1,ih)
30              continue
                rfl_r(iv) = qr_pot(iv)

            elseif (vorz_r(iv,ih) .lt. 0) then
                ! RB 1.Art, Dirichlet, Potential (Potential BC)
                Fx_m1(iv,il) = 0.0d0
                Fx_00(iv,il) = -0.5d0
                Fe_00(iv,il) = -0.5d0
                Fe_p1(iv,il) = 0.0d0
                Fe_m1(iv,il) = 0.0d0
                RS(iv,il)    = -pr_pot(iv)
            endif

        end do  ! iv loop

        ! =====================================================================
        ! LEFT BOUNDARY (links, i.e., Hangtop/hilltop)
        ! =====================================================================
        il = 1
        do iv = 1, iacnv(ih)

            ! =================================================================
            ! PAUSCHAL (direct specification without time series)
            ! =================================================================

            ! -----------------------------------------------------------------
            ! Zero flux
            ! -----------------------------------------------------------------
            if (irb_l(iv,ih) .eq. 0) then
                ql_pot(iv) = 0.0d0

            ! -----------------------------------------------------------------
            ! Gravity flux
            ! -----------------------------------------------------------------
            elseif (irb_l(iv,ih) .eq. -3) then
                ql_pot(iv) = durchl(iv,il) / slopel(iv,ih)

            ! -----------------------------------------------------------------
            ! Hold old value
            ! -----------------------------------------------------------------
            elseif (irb_l(iv,ih) .eq. -4) then
                pl_pot(iv) = phialt(iv,il,ih)

            ! -----------------------------------------------------------------
            ! Seepage face (one-sided BC)
            ! -----------------------------------------------------------------
            elseif (irb_l(iv,ih) .eq. -10) then
                ql_pot(iv) = 0.0d0
                pl_pot(iv) = hko(iv,il,ih)

            ! -----------------------------------------------------------------
            ! Atmospheric (left: zero flux)
            ! -----------------------------------------------------------------
            elseif (irb_l(iv,ih) .eq. -99) then
                ql_pot(iv) = 0.0d0
                pl_pot(iv) = 9999999.0d0

            ! =================================================================
            ! TIME SERIES (Zeitreihe)
            ! =================================================================
            else

                ! -------------------------------------------------------------
                ! Zero flux with optional time series
                ! -------------------------------------------------------------
                if (irbtyp(1,irb_l(iv,ih)) .eq. 0) then
                    if (lrintp(irb_l(iv,ih))) then
                        ql_pot(iv) = strahl(dnull, rbpar(2,1,irb_l(iv,ih)), &
                                            zrbf(1,irb_l(iv,ih)), zrbf(2,irb_l(iv,ih)), &
                                            t_act+dt)
                    else
                        ql_pot(iv) = 0.0d0
                    endif

                ! -------------------------------------------------------------
                ! Prescribed flux
                ! -------------------------------------------------------------
                elseif (irbtyp(1,irb_l(iv,ih)) .eq. 1) then
                    if (lrintp(irb_l(iv,ih))) then
                        ql_pot(iv) = strahl(rbpar(1,1,irb_l(iv,ih)), &
                                            rbpar(2,1,irb_l(iv,ih)), &
                                            zrbf(1,irb_l(iv,ih)), zrbf(2,irb_l(iv,ih)), &
                                            t_act+dt)
                    else
                        ql_pot(iv) = rbpar(1,1,irb_l(iv,ih))
                    endif

                ! -------------------------------------------------------------
                ! Gravity flux
                ! -------------------------------------------------------------
                elseif (irbtyp(1,irb_l(iv,ih)) .eq. 3) then
                    ql_pot(iv) = durchl(iv,il) / slopel(iv,ih)

                ! -------------------------------------------------------------
                ! Leakage boundary (mixed BC)
                ! -------------------------------------------------------------
                elseif (irbtyp(1,irb_l(iv,ih)) .eq. 5) then
                    ql_pot(iv) = rbpar(1,1,irb_l(iv,ih)) * &
                                 ( rbpar(1,2,irb_l(iv,ih)) &
                                   - ( hko(iv,il,ih) + hkomin(ih) - psi(iv,il) ) )

                ! -------------------------------------------------------------
                ! Suction head
                ! -------------------------------------------------------------
                elseif (irbtyp(1,irb_l(iv,ih)) .eq. -1) then
                    if (lrintp(irb_l(iv,ih))) then
                        pl_pot(iv) = hko(iv,il,ih) - strahl(rbpar(1,1,irb_l(iv,ih)), &
                                                             rbpar(2,1,irb_l(iv,ih)), &
                                                             zrbf(1,irb_l(iv,ih)), &
                                                             zrbf(2,irb_l(iv,ih)), &
                                                             t_act+dt)
                    else
                        pl_pot(iv) = hko(iv,il,ih) - rbpar(1,1,irb_l(iv,ih))
                    endif

                ! -------------------------------------------------------------
                ! Potential relative to *.GEO file
                ! -------------------------------------------------------------
                elseif (irbtyp(1,irb_l(iv,ih)) .eq. -2) then
                    if (lrintp(irb_l(iv,ih))) then
                        pl_pot(iv) = strahl(rbpar(1,1,irb_l(iv,ih)), &
                                            rbpar(2,1,irb_l(iv,ih)), &
                                            zrbf(1,irb_l(iv,ih)), zrbf(2,irb_l(iv,ih)), &
                                            t_act+dt) - hkomin(ih)
                    else
                        pl_pot(iv) = rbpar(1,1,irb_l(iv,ih)) - hkomin(ih)
                    endif

                ! -------------------------------------------------------------
                ! Hold old value
                ! -------------------------------------------------------------
                elseif (irbtyp(1,irb_l(iv,ih)) .eq. -4) then
                    pl_pot(iv) = phialt(iv,il,ih)

                ! -------------------------------------------------------------
                ! Seepage face (one-sided BC)
                ! -------------------------------------------------------------
                elseif (abs(irbtyp(1,irb_l(iv,ih))) .eq. 10) then
                    ql_pot(iv) = 0.0d0
                    pl_pot(iv) = hko(iv,il,ih)

                ! -------------------------------------------------------------
                ! One-sided BC
                ! -------------------------------------------------------------
                elseif (abs(irbtyp(1,irb_l(iv,ih))) .eq. 11) then
                    ql_pot(iv) = rbpar(1,2,irb_l(iv,ih))
                    pl_pot(iv) = hko(iv,il,ih) - rbpar(1,1,irb_l(iv,ih))

                ! -------------------------------------------------------------
                ! Atmospheric (left: zero flux)
                ! -------------------------------------------------------------
                elseif (abs(irbtyp(1,irb_l(iv,ih))) .eq. 99) then
                    stop '99 noch nicht implementiert'

                else
                    stop 'Fehler am linken Rand'
                endif
            endif

            ! =================================================================
            ! Apply boundary condition to coefficient matrix
            ! =================================================================

            if (vorz_l(iv,ih) .gt. 0) then
                ! RB 2.Art, Neumann, Fluss (Flux BC)
                ! Skip corner points where perpendicular BC is Dirichlet
                if ( (iv.eq.1)         .and. (vorz_u(il,ih) .lt. 0)) goto 40
                if ( (iv.eq.iacnv(ih)) .and. (vorz_o(il,ih) .lt. 0)) goto 40

                Fx_p1(iv,il) = - A_x(iv,il) * vorfak(iv,il) / x_p1m0(il,ih) &
                                 * fbrup(il,ih)
                Fx_00(iv,il) = - Fx_p1(iv,il)
                RS(iv,il)    = RS(iv,il) &
                               + 2.0d0 * f_eta(iv,il,ih) * ql_pot(iv) * &
                                 vorfak(iv,il) / x_p1m0(il,ih)
40              continue
                rfl_l(iv) = ql_pot(iv)

            elseif (vorz_l(iv,ih) .lt. 0) then
                ! RB 1.Art, Dirichlet, Potential (Potential BC)
                Fx_p1(iv,il) = 0.0d0
                Fx_00(iv,il) = -0.5d0
                Fe_00(iv,il) = -0.5d0
                Fe_p1(iv,il) = 0.0d0
                Fe_m1(iv,il) = 0.0d0
                RS(iv,il)    = -pl_pot(iv)
            endif

        end do  ! iv loop

    end subroutine koeffrb

end module koeffrb_module
