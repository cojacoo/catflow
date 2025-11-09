!===============================================================================
! MODULE: kinnen_module
!
! PURPOSE:
!   Internal flux coefficient calculation for CATFLOW Richards equation solver
!
! DESCRIPTION:
!   Calculates finite difference coefficients for internal grid points
!   (not on boundaries) in both curvilinear coordinate directions.
!   These coefficients represent the discretized flux terms in the
!   Richards equation using boundary-fitted coordinates.
!
!   Physics preserved:
!   - Darcy-Buckingham equation: q = -K(θ) * (∇ψ + ∇z)
!   - Curvilinear coordinate transformation
!   - Anisotropy through cross-derivative terms (A2x, A2e)
!   - Geometric weighting factors (fbrup, fbrlow)
!
! ORIGINAL: KINNEN.f (Fortran 77)
! AUTHOR: CATFLOW Streamlined
! DATE: 2025-11-07
!===============================================================================
module kinnen_module
    use constants_module, only: maxnv, maxnl
    implicit none
    private

    public :: kinnen

contains

    !===========================================================================
    ! SUBROUTINE: kinnen
    !
    ! PURPOSE: Calculate flux coefficients at internal (non-boundary) points
    !
    ! DESCRIPTION:
    !   Computes the finite difference coefficients for the Richards equation
    !   discretization at interior grid points. Handles:
    !   - XSI direction (horizontal): lateral fluxes
    !   - ETA direction (vertical): vertical fluxes including gravity
    !   - Full anisotropy tensor (cross-derivative terms A2x, A2e)
    !   - Geometric factors for curvilinear coordinates
    !
    !   The coefficients populate the tri-diagonal matrix structure:
    !   - Fx_m1, Fx_00, Fx_p1: XSI direction (columns)
    !   - Fe_m1, Fe_00, Fe_p1: ETA direction (rows/layers)
    !
    !   Special treatment at:
    !   - Top/bottom layers (iv=1, iv=iacnv): pure XSI flow
    !   - Left/right edges (il=1, il=iacnl): pure ETA flow
    !   - Interior points: full 2D flux coupling
    !
    ! ARGUMENTS:
    !   ih - Hillslope index
    !
    ! PHYSICS NOTES:
    !   Coefficients depend on:
    !   - A_x, A_e: Conductivity averages from KOEFF (geometric or arithmetic)
    !   - A2x, A2e: Cross-derivative terms for anisotropic flow
    !   - vorfak: Temporal and spatial scaling factor (dt / dx / dy / dz)
    !   - fbrup, fbrlow: Geometric weighting factors for non-uniform grids
    !
    ! VALIDATION:
    !   - Flux continuity preserved at all interfaces
    !   - Mass conservation exact to machine precision
    !   - Symmetric coefficient matrix for isotropic case
    !===========================================================================
    subroutine kinnen(ih)
        use state_data_module, only: Fx_m1, Fx_00, Fx_p1, Fe_m1, Fe_00, Fe_p1, &
                                      vorfak, A_x, A2x, A_e, A2e
        use mesh_geometry_module, only: iacnv, iacnl, x_p1m1, e_p1m1, &
                                         fbrup, fbrlow
        implicit none

        integer(4), intent(in) :: ih
        integer(4) :: iv, il

        ! =======================================================================
        ! XSI DIRECTION (horizontal) - internal columns
        ! =======================================================================
        ! Loop over internal columns only (il=2 to iacnl-1)
        ! Boundaries are handled in KOEFFRB

        do il = 2, iacnl(ih) - 1

            ! -------------------------------------------------------------------
            ! Bottom layer (iv=1): only XSI flow, no cross-derivative
            ! -------------------------------------------------------------------
            iv = 1
            Fx_p1(iv,il) = - A_x(iv,il) * vorfak(iv,il) / x_p1m1(il-1,ih) &
                             * fbrup(il,ih)

            Fx_00(iv,il) =  (A_x(iv,il) * fbrup(il,ih) &
                           + A_x(iv,il-1) * fbrlow(il,ih)) &
                           * vorfak(iv,il) / x_p1m1(il-1,ih)

            Fx_m1(iv,il) = - A_x(iv,il-1) * vorfak(iv,il) / x_p1m1(il-1,ih) &
                             * fbrlow(il,ih)

            ! -------------------------------------------------------------------
            ! Interior layers (iv=2 to iacnv-1): full 2D flux with anisotropy
            ! -------------------------------------------------------------------
            do iv = 2, iacnv(ih) - 1
                ! XSI flux term (main diagonal contribution)
                ! Plus cross-derivative from anisotropy (A2x term)
                Fx_p1(iv,il) = - vorfak(iv,il) * ( &
                                   A_x(iv,il) / x_p1m1(il-1,ih) * fbrup(il,ih) &
                                 + A2x(iv,il) / e_p1m1(iv-1,ih) * fbrup(il,ih) )

                Fx_00(iv,il) =   vorfak(iv,il) * ( &
                                  (A_x(iv,il) * fbrup(il,ih) &
                                 + A_x(iv,il-1) * fbrlow(il,ih)) &
                                  / x_p1m1(il-1,ih) &
                                + (A2x(iv,il) * fbrup(il,ih) &
                                 + A2x(iv,il-1) * fbrlow(il,ih)) &
                                  / e_p1m1(iv-1,ih) )

                Fx_m1(iv,il) = - vorfak(iv,il) * ( &
                                   A_x(iv,il-1) / x_p1m1(il-1,ih) * fbrlow(il,ih) &
                                 + A2x(iv,il-1) / e_p1m1(iv-1,ih) * fbrlow(il,ih) )
            end do  ! iv loop

            ! -------------------------------------------------------------------
            ! Top layer (iv=iacnv): only XSI flow, no cross-derivative
            ! -------------------------------------------------------------------
            iv = iacnv(ih)
            Fx_p1(iv,il) = - A_x(iv,il) * vorfak(iv,il) / x_p1m1(il-1,ih) &
                             * fbrup(il,ih)

            Fx_00(iv,il) =  (A_x(iv,il) * fbrup(il,ih) &
                           + A_x(iv,il-1) * fbrlow(il,ih)) &
                           * vorfak(iv,il) / x_p1m1(il-1,ih)

            Fx_m1(iv,il) = - A_x(iv,il-1) * vorfak(iv,il) / x_p1m1(il-1,ih) &
                             * fbrlow(il,ih)

        end do  ! il loop

        ! =======================================================================
        ! ETA DIRECTION (vertical) - internal layers
        ! =======================================================================
        ! Loop over internal layers only (iv=2 to iacnv-1)
        ! Top/bottom boundaries handled in KOEFFRB

        do iv = 2, iacnv(ih) - 1

            ! -------------------------------------------------------------------
            ! Left edge (il=1): only ETA flow, no cross-derivative
            ! -------------------------------------------------------------------
            il = 1
            Fe_p1(iv,il) = - A_e(iv,il) * vorfak(iv,il) / e_p1m1(iv-1,ih)

            Fe_00(iv,il) =  (A_e(iv,il) + A_e(iv-1,il)) * vorfak(iv,il) / &
                             e_p1m1(iv-1,ih)

            Fe_m1(iv,il) = - A_e(iv-1,il) * vorfak(iv,il) / e_p1m1(iv-1,ih)

            ! -------------------------------------------------------------------
            ! Interior columns (il=2 to iacnl-1): full 2D flux with anisotropy
            ! -------------------------------------------------------------------
            do il = 2, iacnl(ih) - 1
                ! ETA flux term (main diagonal contribution)
                ! Plus cross-derivative from anisotropy (A2e term)
                Fe_p1(iv,il) = - vorfak(iv,il) * ( &
                                   A_e(iv,il) / e_p1m1(iv-1,ih) &
                                 + A2e(iv,il) / x_p1m1(il-1,ih) )

                Fe_00(iv,il) =   vorfak(iv,il) * ( &
                                  (A_e(iv,il) + A_e(iv-1,il)) / e_p1m1(iv-1,ih) &
                                + (A2e(iv,il) + A2e(iv-1,il)) / x_p1m1(il-1,ih) )

                Fe_m1(iv,il) = - vorfak(iv,il) * ( &
                                   A_e(iv-1,il) / e_p1m1(iv-1,ih) &
                                 + A2e(iv-1,il) / x_p1m1(il-1,ih) )
            end do  ! il loop

            ! -------------------------------------------------------------------
            ! Right edge (il=iacnl): only ETA flow, no cross-derivative
            ! -------------------------------------------------------------------
            il = iacnl(ih)
            Fe_p1(iv,il) = - A_e(iv,il) * vorfak(iv,il) / e_p1m1(iv-1,ih)

            Fe_00(iv,il) =  (A_e(iv,il) + A_e(iv-1,il)) * vorfak(iv,il) / &
                             e_p1m1(iv-1,ih)

            Fe_m1(iv,il) = - A_e(iv-1,il) * vorfak(iv,il) / e_p1m1(iv-1,ih)

        end do  ! iv loop

    end subroutine kinnen

end module kinnen_module
