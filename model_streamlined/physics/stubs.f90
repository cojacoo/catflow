!===============================================================================
! MODULE: stubs_module
!
! PURPOSE:
!   Stub implementations for unconverted CATFLOW subsystems
!   Allows model to compile while these modules are being modernized
!
! DESCRIPTION:
!   Provides minimal working stubs for:
!   - strahl:   Time series interpolation (boundary conditions)
!   - updyo:    Surface water depth update (overland flow)
!   - etintz:   Evapotranspiration integration
!   - v_strb:   Velocity field interpolation (particle tracking)
!   - p_stepb:  Particle position update (streamline tracking)
!   - pmass:    Particle mass update (decay/reactions)
!   - ptkinj2:  Particle injection at boundary
!   - c_ipob:   Concentration calculation from particles
!   - gl_copy:  Copy velocity arrays
!
! STUB BEHAVIOR:
!   - strahl:   Returns constant value (no time interpolation)
!   - updyo:    Empty (no surface flow)
!   - etintz:   Empty (no ET)
!   - Particle tracking routines: Empty (no particle tracking)
!
! USAGE:
!   These stubs allow the model to compile and run for simple test cases
!   without surface flow, ET, or particle tracking.
!
!   TO IMPLEMENT FULL FUNCTIONALITY:
!   Replace these stubs with actual implementations from original CATFLOW
!
! AUTHOR: CATFLOW Streamlined
! DATE: 2025-11-10
!===============================================================================
module stubs_module
    implicit none
    private

    public :: strahl
    public :: updyo
    public :: etintz
    public :: v_strb
    public :: p_stepb
    public :: pmass
    public :: ptkinj2
    public :: c_ipob
    public :: gl_copy

contains

    !===========================================================================
    ! SUBROUTINE: strahl
    !
    ! PURPOSE: Interpolate time series data (STUB)
    !
    ! DESCRIPTION:
    !   Stub for time series interpolation. Returns constant value.
    !   Real implementation would interpolate between time series points.
    !
    ! ARGUMENTS:
    !   iz     - Time series index
    !   t      - Current time [s]
    !   value  - Interpolated value (output)
    !===========================================================================
    subroutine strahl(iz, t, value)
        implicit none
        integer(4), intent(in)  :: iz
        real(8),    intent(in)  :: t
        real(8),    intent(out) :: value

        ! Stub: return constant zero
        value = 0.0d0

        return
    end subroutine strahl

    !===========================================================================
    ! SUBROUTINE: updyo
    !
    ! PURPOSE: Update surface water depth (STUB)
    !
    ! DESCRIPTION:
    !   Stub for overland flow calculations. Does nothing.
    !   Real implementation would solve kinematic wave equation.
    !
    ! ARGUMENTS:
    !   ih   - Hillslope index
    !   dt   - Time step [s]
    !   itp  - Time point index
    !===========================================================================
    subroutine updyo(ih, dt, itp)
        implicit none
        integer(4), intent(in) :: ih
        real(8),    intent(in) :: dt
        integer(4), intent(in) :: itp

        ! Stub: no surface flow update

        return
    end subroutine updyo

    !===========================================================================
    ! SUBROUTINE: etintz
    !
    ! PURPOSE: Integrate evapotranspiration over time step (STUB)
    !
    ! DESCRIPTION:
    !   Stub for ET integration. Does nothing.
    !   Real implementation would calculate sink terms for ET.
    !
    ! ARGUMENTS:
    !   ih   - Hillslope index
    !   dt   - Time step [s]
    !===========================================================================
    subroutine etintz(ih, dt)
        implicit none
        integer(4), intent(in) :: ih
        real(8),    intent(in) :: dt

        ! Stub: no ET calculation

        return
    end subroutine etintz

    !===========================================================================
    ! SUBROUTINE: v_strb
    !
    ! PURPOSE: Interpolate velocity field to particle locations (STUB)
    !
    ! DESCRIPTION:
    !   Stub for velocity interpolation. Does nothing.
    !   Real implementation would interpolate velocity to particle positions.
    !
    ! ARGUMENTS:
    !   istp - Species index
    !   ih   - Hillslope index
    !   dt   - Time step [s]
    !===========================================================================
    subroutine v_strb(istp, ih, dt)
        implicit none
        integer(4), intent(in) :: istp
        integer(4), intent(in) :: ih
        real(8),    intent(in) :: dt

        ! Stub: no velocity interpolation

        return
    end subroutine v_strb

    !===========================================================================
    ! SUBROUTINE: p_stepb
    !
    ! PURPOSE: Advance particle positions (STUB)
    !
    ! DESCRIPTION:
    !   Stub for particle tracking. Does nothing.
    !   Real implementation would advance particles along streamlines.
    !
    ! ARGUMENTS:
    !   istp - Species index
    !   dt   - Time step [s]
    !   ih   - Hillslope index
    !===========================================================================
    subroutine p_stepb(istp, dt, ih)
        implicit none
        integer(4), intent(in) :: istp
        real(8),    intent(in) :: dt
        integer(4), intent(in) :: ih

        ! Stub: no particle movement

        return
    end subroutine p_stepb

    !===========================================================================
    ! SUBROUTINE: pmass
    !
    ! PURPOSE: Update particle masses (STUB)
    !
    ! DESCRIPTION:
    !   Stub for particle mass update. Does nothing.
    !   Real implementation would handle decay, reactions, etc.
    !
    ! ARGUMENTS:
    !   istp  - Species index
    !   t_act - Current time [s]
    !   ih    - Hillslope index
    !===========================================================================
    subroutine pmass(istp, t_act, ih)
        implicit none
        integer(4), intent(in) :: istp
        real(8),    intent(in) :: t_act
        integer(4), intent(in) :: ih

        ! Stub: no mass update

        return
    end subroutine pmass

    !===========================================================================
    ! SUBROUTINE: ptkinj2
    !
    ! PURPOSE: Inject particles at boundary (STUB)
    !
    ! DESCRIPTION:
    !   Stub for particle injection. Does nothing.
    !   Real implementation would inject particles at upper boundary.
    !
    ! ARGUMENTS:
    !   ih    - Hillslope index
    !   dt    - Time step [s]
    !   t_act - Current time [s]
    !===========================================================================
    subroutine ptkinj2(ih, dt, t_act)
        implicit none
        integer(4), intent(in) :: ih
        real(8),    intent(in) :: dt
        real(8),    intent(in) :: t_act

        ! Stub: no particle injection

        return
    end subroutine ptkinj2

    !===========================================================================
    ! SUBROUTINE: c_ipob
    !
    ! PURPOSE: Calculate concentrations from particle distribution (STUB)
    !
    ! DESCRIPTION:
    !   Stub for concentration calculation. Does nothing.
    !   Real implementation would compute concentrations from particle masses.
    !
    ! ARGUMENTS:
    !   istp - Species index
    !   ih   - Hillslope index
    !===========================================================================
    subroutine c_ipob(istp, ih)
        implicit none
        integer(4), intent(in) :: istp
        integer(4), intent(in) :: ih

        ! Stub: no concentration calculation

        return
    end subroutine c_ipob

    !===========================================================================
    ! SUBROUTINE: gl_copy
    !
    ! PURPOSE: Copy velocity arrays (STUB)
    !
    ! DESCRIPTION:
    !   Stub for velocity array copy. Does nothing.
    !   Real implementation would copy velocity field arrays.
    !
    ! ARGUMENTS:
    !   source - Source array
    !   dest   - Destination array
    !   ih     - Hillslope index
    !===========================================================================
    subroutine gl_copy(source, dest, ih)
        use constants_module, only: maxnv, maxnl
        implicit none
        real(8),    intent(in)  :: source(maxnv, maxnl)
        real(8),    intent(out) :: dest(maxnv, maxnl)
        integer(4), intent(in)  :: ih

        ! Stub: no copy operation (velocity tracking disabled)

        return
    end subroutine gl_copy

end module stubs_module
