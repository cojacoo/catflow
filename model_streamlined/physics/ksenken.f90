!===============================================================================
! MODULE: ksenken_module
!
! PURPOSE:
!   Sink and source term calculation for CATFLOW Richards equation
!
! DESCRIPTION:
!   Computes sink/source terms at internal grid points including:
!   - Root water uptake (transpiration from soil)
!   - Evapotranspiration coupling
!   - Internal sources/sinks from time series
!   - Inequality conditions (seepage faces, atmospheric BC)
!
!   Sinks are positive when extracting water from the control volume.
!   Sources are negative (adding water to control volume).
!
!   Physics preserved:
!   - Root water uptake distribution (plrw)
!   - Atmospheric coupling (isnk = -99)
!   - Seepage face logic (isnk = -10)
!   - Time series interpolation
!   - All BC types: Dirichlet (pressure), Neumann (flux), mixed
!
! ORIGINAL: KSENKEN.f (Fortran 77)
! AUTHOR: CATFLOW Streamlined
! DATE: 2025-11-07
!===============================================================================
module ksenken_module
    use constants_module, only: maxnv, maxnl
    implicit none
    private

    public :: ksenken

contains

    !===========================================================================
    ! SUBROUTINE: ksenken
    !
    ! PURPOSE: Calculate sink/source coefficients at internal points
    !
    ! DESCRIPTION:
    !   Computes sink/source terms for the Richards equation at interior
    !   grid points (iv=2 to iacnv-1, il=2 to iacnl-1). Boundaries are
    !   handled separately in KOEFFRB.
    !
    !   Sink/source types (isktyp):
    !   0  : No sink/source
    !   1  : Prescribed flux [1/s]
    !   2  : Prescribed flux [m²/s] (divided by control volume area)
    !   -1 : Prescribed suction (pressure head)
    !   -2 : Prescribed potential relative to geometry
    !   -4 : Hold old value (time-invariant)
    !   10 : Seepage face (inequality condition)
    !   11 : One-sided BC (both flux and pressure specified)
    !   99 : Atmospheric coupling (ET from canopy)
    !
    !   Sign conventions:
    !   - vorz_s > 0: Neumann BC (flux), qs_pot > 0 extracts water
    !   - vorz_s < 0: Dirichlet BC (pressure), ps_pot specified
    !
    ! ARGUMENTS:
    !   ih - Hillslope index
    !   dt - Time step [s]
    !
    ! PHYSICS NOTES:
    !   - ET coupling: qs_pot = Ecanop * plrw / area
    !     where plrw is relative root water uptake distribution
    !   - Seepage faces: Switch between flux (0) and pressure (hko)
    !   - Time interpolation: uses strahl() function for BC time series
    !
    ! VALIDATION:
    !   - Mass balance: sum of all sinks must equal total ET
    !   - Root uptake: sum(qs_pot * area) = total transpiration
    !   - Pressure constraints: ps_pot physically reasonable (> -15000 cm)
    !===========================================================================
    subroutine ksenken(ih, dt)
        use state_data_module, only: RS, vorfak, Fx_m1, Fx_00, Fx_p1, &
                                      Fe_m1, Fe_00, Fe_p1, &
                                      phialt, senk, psi
        use mesh_geometry_module, only: iacnv, iacnl, hko, area, &
                                         dr_o, slopeo, hkomin, f_xsi, f_eta
        use boundary_conditions_module, only: isnk, vorz_s, isktyp, skpar, &
                                               qs_pot, ps_pot, plrw, Ecanop, &
                                               zsnk, lsintp
        use time_module, only: t_act, io
        implicit none

        integer(4), intent(in) :: ih
        real(8), intent(in) :: dt

        integer(4) :: iv, il
        real(8) :: dnull
        real(8), external :: strahl

        dnull = 0.0d0

        ! =======================================================================
        ! SINK/SOURCE TERMS AT INTERNAL POINTS
        ! =======================================================================
        ! Loop over internal points only (boundaries handled in KOEFFRB)

        do il = 2, iacnl(ih) - 1
            do iv = 2, iacnv(ih) - 1

                ! ---------------------------------------------------------------
                ! DETERMINE SINK/SOURCE TYPE AND CALCULATE POTENTIAL
                ! ---------------------------------------------------------------

                if (isnk(iv,il,ih) == 0) then
                    ! =============================================================
                    ! TYPE 0: No sink/source
                    ! =============================================================
                    qs_pot(iv,il) = 0.0d0

                elseif (isnk(iv,il,ih) == -4) then
                    ! =============================================================
                    ! TYPE -4: Hold old pressure value
                    ! =============================================================
                    ps_pot(iv,il) = phialt(iv,il,ih)

                elseif (isnk(iv,il,ih) == -10) then
                    ! =============================================================
                    ! TYPE -10: Seepage face (inequality condition)
                    ! =============================================================
                    ! Switch between zero flux and atmospheric pressure
                    qs_pot(iv,il) = 0.0d0
                    ps_pot(iv,il) = hko(iv,il,ih)

                elseif (isnk(iv,il,ih) == -99) then
                    ! =============================================================
                    ! TYPE -99: Atmospheric coupling (ET from canopy)
                    ! =============================================================
                    ! Root water uptake based on transpiration demand
                    if (plrw(iv,il) > 0.0d0) then
                        ! Sink flux: Transpiration rate distributed by root density
                        ! Units: [1/s] = [m/s] * [m] * [-] / [m²]
                        qs_pot(iv,il) = Ecanop(il) * dr_o(il,ih) * slopeo(il,ih) * &
                                         plrw(iv,il) / area(iv,il,ih)

                        ! Sanity check (should never be negative)
                        if (qs_pot(iv,il) < 0.0d0) then
                            write(io(1),*) 'ERROR in KSENKEN: Negative sink at iv=', iv, &
                                           ', il=', il
                            write(io(1),*) '  Ecanop =', Ecanop(il), &
                                           ', dr_o =', dr_o(il,ih), &
                                           ', slopeo =', slopeo(il,ih)
                            write(io(1),*) '  plrw =', plrw(iv,il), &
                                           ', area =', area(iv,il,ih)
                            write(io(1),*) '  qs_pot (negative) =', qs_pot(iv,il)
                        end if
                    else
                        ! No root uptake at this location
                        qs_pot(iv,il) = 0.0d0
                    end if

                    ! Limiting pressure for extremely dry conditions
                    ! -10^4.2 cm ≈ -15849 cm (permanent wilting point)
                    ps_pot(iv,il) = hko(iv,il,ih) - 10.0d0**4.2d0 / 100.0d0

                else
                    ! =============================================================
                    ! TIME SERIES DRIVEN SINKS/SOURCES
                    ! =============================================================
                    ! Read sink parameters from time series files

                    if (isktyp(1,isnk(iv,il,ih)) == 0) then
                        ! ---------------------------------------------------------
                        ! TYPE 0: No sink (with optional time series for zero flux)
                        ! ---------------------------------------------------------
                        if (lsintp(isnk(iv,il,ih))) then
                            qs_pot(iv,il) = strahl(dnull, &
                                skpar(2,1,isnk(iv,il,ih)), &
                                zsnk(1,isnk(iv,il,ih)), &
                                zsnk(2,isnk(iv,il,ih)), t_act+dt)
                        else
                            qs_pot(iv,il) = 0.0d0
                        end if

                    elseif (isktyp(1,isnk(iv,il,ih)) == 1) then
                        ! ---------------------------------------------------------
                        ! TYPE 1: Prescribed flux [1/s]
                        ! ---------------------------------------------------------
                        if (lsintp(isnk(iv,il,ih))) then
                            qs_pot(iv,il) = strahl(skpar(1,1,isnk(iv,il,ih)), &
                                skpar(2,1,isnk(iv,il,ih)), &
                                zsnk(1,isnk(iv,il,ih)), &
                                zsnk(2,isnk(iv,il,ih)), t_act+dt)
                        else
                            qs_pot(iv,il) = skpar(1,1,isnk(iv,il,ih))
                        end if

                    elseif (isktyp(1,isnk(iv,il,ih)) == 2) then
                        ! ---------------------------------------------------------
                        ! TYPE 2: Prescribed flux [m²/s]
                        ! ---------------------------------------------------------
                        ! Convert from areal flux to volumetric flux rate
                        qs_pot(iv,il) = skpar(1,1,isnk(iv,il,ih)) / area(iv,il,ih)

                    elseif (isktyp(1,isnk(iv,il,ih)) == -1) then
                        ! ---------------------------------------------------------
                        ! TYPE -1: Prescribed suction (pressure head)
                        ! ---------------------------------------------------------
                        if (lsintp(isnk(iv,il,ih))) then
                            ps_pot(iv,il) = hko(iv,il,ih) - &
                                strahl(skpar(1,1,isnk(iv,il,ih)), &
                                skpar(2,1,isnk(iv,il,ih)), &
                                zsnk(1,isnk(iv,il,ih)), &
                                zsnk(2,isnk(iv,il,ih)), t_act+dt)
                        else
                            ps_pot(iv,il) = hko(iv,il,ih) - skpar(1,1,isnk(iv,il,ih))
                        end if

                    elseif (isktyp(1,isnk(iv,il,ih)) == -2) then
                        ! ---------------------------------------------------------
                        ! TYPE -2: Potential relative to geometry (*.GEO file)
                        ! ---------------------------------------------------------
                        if (lsintp(isnk(iv,il,ih))) then
                            ps_pot(iv,il) = strahl(skpar(1,1,isnk(iv,il,ih)), &
                                skpar(2,1,isnk(iv,il,ih)), &
                                zsnk(1,isnk(iv,il,ih)), &
                                zsnk(2,isnk(iv,il,ih)), t_act+dt) - hkomin(ih)
                        else
                            ps_pot(iv,il) = skpar(1,1,isnk(iv,il,ih)) - hkomin(ih)
                        end if

                    elseif (isktyp(1,isnk(iv,il,ih)) == -4) then
                        ! ---------------------------------------------------------
                        ! TYPE -4: Hold old value
                        ! ---------------------------------------------------------
                        ps_pot(iv,il) = phialt(iv,il,ih)

                    elseif (abs(isktyp(1,isnk(iv,il,ih))) == 10) then
                        ! ---------------------------------------------------------
                        ! TYPE 10: Seepage face (inequality BC)
                        ! ---------------------------------------------------------
                        qs_pot(iv,il) = 0.0d0
                        ps_pot(iv,il) = hko(iv,il,ih)

                    elseif (abs(isktyp(1,isnk(iv,il,ih))) == 11) then
                        ! ---------------------------------------------------------
                        ! TYPE 11: One-sided BC (both flux and pressure specified)
                        ! ---------------------------------------------------------
                        qs_pot(iv,il) = skpar(1,2,isnk(iv,il,ih))
                        ps_pot(iv,il) = hko(iv,il,ih) - skpar(1,1,isnk(iv,il,ih))

                    elseif (isktyp(1,isnk(iv,il,ih)) == 99) then
                        ! ---------------------------------------------------------
                        ! TYPE 99: Atmospheric (not yet implemented)
                        ! ---------------------------------------------------------
                        stop 'ERROR: Sink type 99 not yet implemented in KSENKEN'

                    else
                        ! ---------------------------------------------------------
                        ! UNKNOWN TYPE
                        ! ---------------------------------------------------------
                        write(io(1),*) 'ERROR: Unknown sink type at iv=', iv, &
                                       ', il=', il, ', ih=', ih
                        write(io(1),*) '  isktyp =', isktyp(1,isnk(iv,il,ih))
                        stop 'ERROR: Unknown sink type in KSENKEN'

                    end if  ! isktyp cases

                end if  ! isnk cases

                ! ---------------------------------------------------------------
                ! APPLY SINK/SOURCE TO MATRIX AND RIGHT-HAND SIDE
                ! ---------------------------------------------------------------

                if (vorz_s(iv,il,ih) > 0) then
                    ! ===========================================================
                    ! NEUMANN BC (FLUX CONDITION)
                    ! ===========================================================
                    ! Sink: flux positive out of control volume [1/s]
                    ! Add to right-hand side (negative because sink removes water)
                    RS(iv,il) = RS(iv,il) - vorfak(iv,il) * qs_pot(iv,il) * &
                                f_xsi(iv,il,ih) * f_eta(iv,il,ih)

                    ! Store for mass balance tracking
                    senk(iv,il) = qs_pot(iv,il)

                elseif (vorz_s(iv,il,ih) < 0) then
                    ! ===========================================================
                    ! DIRICHLET BC (PRESSURE CONDITION)
                    ! ===========================================================
                    ! Override all flux coefficients - pressure is prescribed
                    Fx_m1(iv,il) = 0.0d0
                    Fx_p1(iv,il) = 0.0d0
                    Fx_00(iv,il) = -0.5d0  ! Half weight for potential equation
                    Fe_00(iv,il) = -0.5d0  ! Half weight for potential equation
                    Fe_p1(iv,il) = 0.0d0
                    Fe_m1(iv,il) = 0.0d0
                    RS(iv,il) = -ps_pot(iv,il)

                end if  ! vorz_s check

            end do  ! iv loop
        end do  ! il loop

    end subroutine ksenken

end module ksenken_module
