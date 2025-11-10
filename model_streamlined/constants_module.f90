!===============================================================================
! MODULE: constants_module
!
! PURPOSE:
!   Global constants and dimension parameters for CATFLOW Streamlined
!   Replaces the DIMENSN.inc and other parameter include files
!
! DESCRIPTION:
!   This module defines all compile-time constants used throughout CATFLOW:
!
!   1. ARRAY DIMENSIONS
!      - maxnv:  Maximum nodes in vertical (ξ) direction
!      - maxnl:  Maximum nodes in lateral (η) direction
!      - maxnh:  Maximum number of hillslopes
!      - maxcv:  Maximum control volumes
!      - maxtab: Maximum table size for soil hydraulics
!      - maxeig: Maximum soil types (eigensch = properties)
!      - maxtyp: Maximum boundary condition types
!      - maxpbm: Maximum particle batches for mass transport
!      - maxist: Maximum solute species
!
!   2. NUMERICAL PARAMETERS
!      - cgeps:  Conjugate gradient convergence criterion [dimensionless]
!      - piceps: Picard iteration convergence criterion [m]
!      - it_max: Maximum iterations for Picard/CG loops
!      - n_gr:   Iteration count threshold for time step control
!      - iacgr:  Grid resolution indicator
!
!   3. I/O CHANNELS
!      - io:     Main input/output unit
!      - io_log: Log file unit for diagnostics
!
! USAGE:
!   use constants_module, only: maxnv, maxnl, io
!
! ORIGINAL: DIMENSN.inc, IOINP.inc (Fortran 77 includes)
! AUTHOR: CATFLOW Streamlined
! DATE: 2025-11-10
!===============================================================================
module constants_module
    implicit none

    ! =========================================================================
    ! ARRAY DIMENSION PARAMETERS
    ! =========================================================================
    ! These define maximum sizes for all major arrays
    ! Actual problem size is typically smaller and set at runtime

    ! Grid dimensions
    integer(4), parameter :: maxnv = 100    ! Max nodes in vertical (ξ)
    integer(4), parameter :: maxnl = 100    ! Max nodes in lateral (η)
    integer(4), parameter :: maxnh = 10     ! Max hillslopes
    integer(4), parameter :: maxcv = maxnv * maxnl  ! Max control volumes

    ! Soil hydraulic properties
    integer(4), parameter :: maxtab = 2000  ! Max table entries for θ(ψ)
    integer(4), parameter :: maxeig = 20    ! Max soil types
    integer(4), parameter :: maxtyp = 10    ! Max BC types

    ! Particle tracking and transport
    integer(4), parameter :: maxpbm = 1000  ! Max particle batches
    integer(4), parameter :: maxist = 10    ! Max solute species

    ! =========================================================================
    ! NUMERICAL PARAMETERS
    ! =========================================================================

    ! Convergence criteria
    real(8), parameter :: cgeps  = 1.0d-6   ! CG residual tolerance
    real(8), parameter :: piceps = 1.0d-2   ! Picard tolerance [m]

    ! Iteration limits
    integer(4), parameter :: it_max = 30    ! Max Picard/CG iterations
    integer(4), parameter :: n_gr   = 8     ! Iteration threshold for dt control
    integer(4), parameter :: iacgr  = 0     ! Grid resolution indicator

    ! =========================================================================
    ! I/O UNIT NUMBERS
    ! =========================================================================

    integer(4), parameter :: io     = 6     ! Standard output
    integer(4), parameter :: io_log = 10    ! Log file unit

end module constants_module
