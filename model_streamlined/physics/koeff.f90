!===============================================================================
! MODULE: koeff_module
!
! PURPOSE:
!   Coefficient calculation for CATFLOW (conductivity averaging, etc.)
!   Modernized version of KOEFF.f using Fortran 90 modules
!
! DESCRIPTION:
!   Calculates coefficients for the Richards equation solver:
!   - Hydraulic conductivity averaging between elements
!   - Transformation coefficients for curvilinear coordinates
!   - Temporal scaling factors
!
! ORIGINAL: KOEFF.f (Fortran 77 with includes)
! AUTHOR: CATFLOW Streamlined
! DATE: 2025-11-07
!===============================================================================
module koeff_module
    use constants_module, only: maxnv, maxnl
    implicit none
    private

    public :: koeff
    public :: calfak

contains

    !===========================================================================
    ! SUBROUTINE: koeff
    !
    ! PURPOSE: Main coefficient initialization routine
    !
    ! ARGUMENTS:
    !   ih - Hillslope index
    !   dt - Time step [s]
    !===========================================================================
    subroutine koeff(ih, dt)
        use state_data_module, only: Fx_m1, Fx_00, Fx_p1, Fe_m1, Fe_00, Fe_p1, &
                                      RS, vorfak, wasska
        use mesh_geometry_module, only: f_xsi, f_eta, iacnv, iacnl
        implicit none

        integer(4), intent(in) :: ih
        real(8), intent(in) :: dt

        integer(4) :: iv, il

        ! Initialize flux coefficients to zero
        do iv = 1, iacnv(ih)
            do il = 1, iacnl(ih)
                Fx_m1(iv,il) = 0.0d0
                Fx_00(iv,il) = 0.0d0
                Fx_p1(iv,il) = 0.0d0
                Fe_m1(iv,il) = 0.0d0
                Fe_00(iv,il) = 0.0d0
                Fe_p1(iv,il) = 0.0d0
                RS(iv,il) = 0.0d0

                ! Temporal and spatial scaling factor
                vorfak(iv,il) = dt / (f_xsi(iv,il,ih) * f_eta(iv,il,ih) * wasska(iv,il))
            end do
        end do

        ! Call subroutines to calculate various coefficients
        ! NOTE: These would need to be converted to modules as well
        ! call hgnull(senk, ih)
        call calfak(ih)
        ! call kinnen(ih)
        ! call koeffrb(ih, dt)
        ! call ksenken(ih, dt)

    end subroutine koeff

    !===========================================================================
    ! SUBROUTINE: calfak
    !
    ! PURPOSE: Calculate hydraulic conductivity averaging factors
    !
    ! DESCRIPTION:
    !   Implements three averaging methods (Zurmuehl, 1994):
    !   1. K(θ_mean) - Conductivity at mean water content
    !   2. Arithmetic mean
    !   3. Geometric mean
    !
    ! ARGUMENTS:
    !   ih - Hillslope index
    !===========================================================================
    subroutine calfak(ih)
        use state_data_module, only: theta, durchl, mak_an, tabpos, A_x, A2x, &
                                      A_e, A2e
        use mesh_geometry_module, only: iacnv, iacnl, f_eta, f_xsi, kxx, kxe, &
                                         kee, x_p1m0, e_p1m0, mm_xsi, mm_eta, &
                                         al_fak, av_fak, iboden
        use soil_hydraulics_module, only: vg_ngr
        implicit none

        integer(4), intent(in) :: ih

        integer(4) :: iv, il, poshlp
        real(8) :: th_hlp, k_hlp, k_hlp1, k_hlp2
        real(8) :: fdf0, fdf1
        real(8), external :: k_th

        ! =====================================================================
        ! HORIZONTAL (XSI) DIRECTION AVERAGING
        ! =====================================================================
        ! Calculate mean conductivity according to Zurmuehl (1994)

        do iv = 1, iacnv(ih)
            do il = 1, iacnl(ih) - 1

                ! Metric transformation factors
                fdf0 = f_eta(iv, il,   ih) / f_xsi(iv, il,   ih)
                fdf1 = f_eta(iv, il+1, ih) / f_xsi(iv, il+1, ih)

                ! Select averaging method
                select case (mm_xsi(iv, il, ih))

                case (2)
                    ! =========================================================
                    ! Method 2: ARITHMETIC MEAN
                    ! =========================================================
                    ! K_mean = (K1*w1 + K2*w2) / (w1 + w2)
                    ! where w = metric coefficient

                    A_x(iv,il) = (durchl(iv, il  ) * fdf0 * kxx(iv, il,   ih) + &
                                  durchl(iv, il+1) * fdf1 * kxx(iv, il+1, ih)) &
                                 / x_p1m0(il, ih)

                    A2x(iv,il) = (durchl(iv, il  ) * kxe(iv, il,   ih) + &
                                  durchl(iv, il+1) * kxe(iv, il+1, ih)) &
                                 / x_p1m0(il, ih)

                case (1)
                    ! =========================================================
                    ! Method 1: K(θ_MEAN) - Conductivity at mean water content
                    ! =========================================================
                    ! Only if no macropores active
                    ! Otherwise fallthrough to geometric mean

                    if (mak_an(iv, il) .or. mak_an(iv, il+1)) then
                        ! Macropores active -> use geometric mean
                        k_hlp1 = durchl(iv, il  )
                        k_hlp2 = durchl(iv, il+1)
                    else
                        ! Calculate K at weighted mean water content
                        th_hlp = theta(iv, il  ) * al_fak(iv, il, ih) + &
                                 theta(iv, il+1) * (1.0d0 - al_fak(iv, il, ih))

                        poshlp = tabpos(iv, il, ih)
                        k_hlp = k_th(iboden(iv, il, ih), th_hlp, poshlp)

                        k_hlp1 = k_hlp
                        k_hlp2 = k_hlp
                    end if

                    ! Apply geometric mean formula
                    A_x(iv,il) = 2.0d0 * sqrt(k_hlp1 * fdf0 * kxx(iv, il,   ih) * &
                                              k_hlp2 * fdf1 * kxx(iv, il+1, ih)) &
                                 / x_p1m0(il, ih)

                    A2x(iv,il) = (sqrt(k_hlp1) * kxe(iv, il,   ih) + &
                                  sqrt(k_hlp2) * kxe(iv, il+1, ih)) &
                                 / x_p1m0(il, ih)

                case (3)
                    ! =========================================================
                    ! Method 3: GEOMETRIC MEAN
                    ! =========================================================
                    ! K_mean = sqrt(K1 * K2)

                    k_hlp1 = durchl(iv, il  )
                    k_hlp2 = durchl(iv, il+1)

                    A_x(iv,il) = 2.0d0 * sqrt(k_hlp1 * fdf0 * kxx(iv, il,   ih) * &
                                              k_hlp2 * fdf1 * kxx(iv, il+1, ih)) &
                                 / x_p1m0(il, ih)

                    A2x(iv,il) = (sqrt(k_hlp1) * kxe(iv, il,   ih) + &
                                  sqrt(k_hlp2) * kxe(iv, il+1, ih)) &
                                 / x_p1m0(il, ih)

                case default
                    print *, 'ERROR: Invalid averaging method mm_xsi = ', mm_xsi(iv, il, ih)
                    stop

                end select

            end do  ! il loop
        end do  ! iv loop

        ! =====================================================================
        ! VERTICAL (ETA) DIRECTION AVERAGING
        ! =====================================================================
        ! Similar logic for vertical direction

        do iv = 1, iacnv(ih) - 1
            do il = 1, iacnl(ih)

                ! Metric transformation factors
                fdf0 = f_xsi(iv,   il, ih) / f_eta(iv,   il, ih)
                fdf1 = f_xsi(iv+1, il, ih) / f_eta(iv+1, il, ih)

                select case (mm_eta(iv, il, ih))

                case (2)
                    ! Arithmetic mean
                    A_e(iv,il) = (durchl(iv,   il) * fdf0 * kee(iv,   il, ih) + &
                                  durchl(iv+1, il) * fdf1 * kee(iv+1, il, ih)) &
                                 / e_p1m0(iv, ih)

                    A2e(iv,il) = (durchl(iv,   il) * kxe(iv,   il, ih) + &
                                  durchl(iv+1, il) * kxe(iv+1, il, ih)) &
                                 / e_p1m0(iv, ih)

                case (1)
                    ! K(θ_mean) or geometric mean
                    if (mak_an(iv, il) .or. mak_an(iv+1, il)) then
                        k_hlp1 = durchl(iv,   il)
                        k_hlp2 = durchl(iv+1, il)
                    else
                        th_hlp = theta(iv,   il) * av_fak(iv, il, ih) + &
                                 theta(iv+1, il) * (1.0d0 - av_fak(iv, il, ih))

                        poshlp = tabpos(iv, il, ih)
                        k_hlp = k_th(iboden(iv, il, ih), th_hlp, poshlp)

                        k_hlp1 = k_hlp
                        k_hlp2 = k_hlp
                    end if

                    A_e(iv,il) = 2.0d0 * sqrt(k_hlp1 * fdf0 * kee(iv,   il, ih) * &
                                              k_hlp2 * fdf1 * kee(iv+1, il, ih)) &
                                 / e_p1m0(iv, ih)

                    A2e(iv,il) = (sqrt(k_hlp1) * kxe(iv,   il, ih) + &
                                  sqrt(k_hlp2) * kxe(iv+1, il, ih)) &
                                 / e_p1m0(iv, ih)

                case (3)
                    ! Geometric mean
                    k_hlp1 = durchl(iv,   il)
                    k_hlp2 = durchl(iv+1, il)

                    A_e(iv,il) = 2.0d0 * sqrt(k_hlp1 * fdf0 * kee(iv,   il, ih) * &
                                              k_hlp2 * fdf1 * kee(iv+1, il, ih)) &
                                 / e_p1m0(iv, ih)

                    A2e(iv,il) = (sqrt(k_hlp1) * kxe(iv,   il, ih) + &
                                  sqrt(k_hlp2) * kxe(iv+1, il, ih)) &
                                 / e_p1m0(iv, ih)

                case default
                    print *, 'ERROR: Invalid averaging method mm_eta = ', mm_eta(iv, il, ih)
                    stop

                end select

            end do  ! il loop
        end do  ! iv loop

    end subroutine calfak

end module koeff_module
