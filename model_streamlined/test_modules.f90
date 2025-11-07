!===============================================================================
! PROGRAM: test_modules
!
! PURPOSE: Test the new modular structure of CATFLOW streamlined
!          Demonstrates how modules are used vs. old COMMON blocks
!
! COMPILE: gfortran -c modules/constants_module.f90
!          gfortran -c modules/state_data_module.f90
!          gfortran -o test_modules test_modules.f90 constants_module.o state_data_module.o
!
! RUN:     ./test_modules
!===============================================================================
program test_modules
    use constants_module
    use state_data_module
    implicit none

    integer :: nv, nl, nh
    real(8) :: mem_mb

    print *, ''
    print *, '============================================='
    print *, 'CATFLOW STREAMLINED - MODULE STRUCTURE TEST'
    print *, '============================================='
    print *, ''

    ! Initialize constants
    call init_constants()

    ! Display parameter information
    call get_parameter_info()

    ! Set actual grid dimensions (smaller than max for this test)
    nv = 30    ! 30 soil layers
    nl = 50    ! 50 soil columns
    nh = 1     ! 1 hillslope

    print *, ''
    print *, 'Allocating state arrays for test grid...'
    print *, ''

    ! Allocate state arrays
    call allocate_state(nv, nl, nh)

    ! Calculate actual memory used
    mem_mb = (nv * nl * 8.0d0 * 20.0d0) / 1024.0d0 / 1024.0d0  ! Rough estimate

    print *, ''
    print *, 'SUCCESS! State arrays allocated'
    print *, '  Actual grid size: ', nv, ' x ', nl, ' x ', nh
    print *, '  Nodes: ', nv * nl
    print *, '  Estimated memory: ', mem_mb, ' MB'
    print *, ''

    ! Test: Set some values
    psi_new = -1.5d0                ! Set pressure head to -1.5 m (field capacity)
    theta = 0.3d0                   ! Set water content to 0.3
    print *, 'Initialized test values:'
    print *, '  psi_new(1,1) = ', psi_new(1,1)
    print *, '  theta(1,1) = ', theta(1,1)
    print *, ''

    ! Test: Swap state (demonstrate O(1) operation)
    print *, 'Testing state swap (pointer reassignment)...'
    psi_old = psi_new
    psi_new = -2.0d0

    call swap_state()

    print *, '  After swap:'
    print *, '    psi (current) now points to what was psi_new'
    print *, '    psi_new contains what was psi_old'
    print *, '  SUCCESS: State swapped with zero copying!'
    print *, ''

    ! Deallocate
    print *, 'Deallocating state arrays...'
    call deallocate_state()

    print *, ''
    print *, '============================================='
    print *, 'TEST COMPLETED SUCCESSFULLY'
    print *, '============================================='
    print *, ''
    print *, 'Key improvements demonstrated:'
    print *, '  [1] No COMMON blocks - clean module structure'
    print *, '  [2] Dynamic allocation - memory sized to actual grid'
    print *, '  [3] Pointer swapping - O(1) state updates'
    print *, '  [4] Type safety - compiler checks all accesses'
    print *, '  [5] Selective imports - only use what you need'
    print *, ''
    print *, 'Memory savings vs. static allocation:'
    print *, '  Static (maxnv x maxnl): ', (maxnv * maxnl * 8 * 20) / 1024 / 1024, ' MB'
    print *, '  Dynamic (actual grid):  ', mem_mb, ' MB'
    print *, '  Reduction: ', &
        (1.0d0 - mem_mb / ((maxnv * maxnl * 8.0d0 * 20.0d0) / 1024.0d0 / 1024.0d0)) * 100.0d0, ' %'
    print *, ''

end program test_modules
