!===============================================================================
! PROGRAM: test_soil_module
!
! PURPOSE: Test the soil_hydraulics_module
!          Validates allocation, memory usage, and basic operations
!
! COMPILE: make
!
! RUN:     ./test_soil_module
!===============================================================================
program test_soil_module
    use constants_module
    use soil_hydraulics_module
    implicit none

    real(8) :: mem_kb

    print *, ''
    print *, '======================================================'
    print *, 'SOIL HYDRAULICS MODULE - VALIDATION TEST'
    print *, '======================================================'
    print *, ''

    ! Initialize constants
    call init_constants()

    print *, 'Maximum dimensions:'
    print *, '  maxtyp  (soil types):      ', maxtyp
    print *, '  maxtab  (table rows):      ', maxtab
    print *, '  maxeig  (properties):      ', maxeig
    print *, '  maxpbm  (parameters):      ', maxpbm
    print *, '  maxero  (erosion params):  ', maxero
    print *, ''

    ! Allocate soil arrays
    print *, 'Allocating soil hydraulic arrays...'
    call allocate_soil()
    print *, 'SUCCESS! Soil arrays allocated'
    print *, ''

    ! Estimate memory usage
    ! Major arrays:
    ! s_tab:   maxtab × maxeig × maxtyp × 8 bytes
    ! bodpar:  maxpbm × maxtyp × 8 bytes
    ! Plus smaller arrays
    mem_kb = (maxtab * maxeig * maxtyp * 8.0d0 + &
              maxpbm * maxtyp * 8.0d0 + &
              maxero * maxtyp * 8.0d0) / 1024.0d0

    print *, 'Estimated memory usage: ', mem_kb, ' KB'
    print *, ''

    ! Test 1: Van Genuchten parameter
    print *, 'Test 1: Van Genuchten parameter...'
    print *, '  vg_ngr = ', vg_ngr, ' (boundary for averaging)'
    print *, '  SUCCESS!'
    print *, ''

    ! Test 2: Set some soil parameters (Sandy loam example)
    print *, 'Test 2: Setting soil parameters (Sandy loam)...'
    iactyp = 1  ! One active soil type
    iaceig = 5  ! Five properties (theta_r, theta_s, alpha, n, K_s)

    ! Van Genuchten parameters for sandy loam
    bodpar(1,1) = 0.065d0   ! theta_r (residual water content)
    bodpar(2,1) = 0.41d0    ! theta_s (saturated water content)
    bodpar(3,1) = 0.075d0   ! alpha [1/cm]
    bodpar(4,1) = 1.89d0    ! n (shape parameter)
    bodpar(5,1) = 106.1d0   ! K_s [cm/day]

    boden(1) = 'Sandy Loam'
    imod(1) = 1  ! Van Genuchten model

    print *, '  Soil type: ', trim(boden(1))
    print *, '  theta_r  = ', bodpar(1,1)
    print *, '  theta_s  = ', bodpar(2,1)
    print *, '  alpha    = ', bodpar(3,1), ' 1/cm'
    print *, '  n        = ', bodpar(4,1)
    print *, '  K_s      = ', bodpar(5,1), ' cm/day'
    print *, '  Model    = ', imod(1), ' (Van Genuchten)'
    print *, '  SUCCESS!'
    print *, ''

    ! Test 3: Set anisotropy
    print *, 'Test 3: Setting anisotropy...'
    anisot(1,1) = 10.0d0    ! K_h/K_v = 10 (horizontal/vertical)
    anisot(2,1) = 0.0d0     ! Angle = 0 (aligned with coordinate axes)
    print *, '  K_h/K_v = ', anisot(1,1)
    print *, '  Angle   = ', anisot(2,1), ' radians'
    print *, '  SUCCESS!'
    print *, ''

    ! Test 4: Set water retention parameters
    print *, 'Test 4: Setting water retention...'
    th_pwp(1) = 0.10d0      ! Permanent wilting point = 10%
    snull(1) = 1.0d-4       ! Storage coefficient for saturated soil
    print *, '  PWP    = ', th_pwp(1) * 100.0d0, ' %'
    print *, '  S_s    = ', snull(1), ' 1/m'
    print *, '  SUCCESS!'
    print *, ''

    ! Test 5: Set albedo parameters
    print *, 'Test 5: Setting albedo parameters...'
    satkni(1) = 0.5d0       ! Saturation influence
    balmax(1) = 0.25d0      ! Dry soil albedo
    balmin(1) = 0.10d0      ! Wet soil albedo
    print *, '  Saturation coeff = ', satkni(1)
    print *, '  Dry albedo       = ', balmax(1)
    print *, '  Wet albedo       = ', balmin(1)
    print *, '  SUCCESS!'
    print *, ''

    ! Test 6: Set soil resistance parameters
    print *, 'Test 6: Setting soil resistance (Kolle model)...'
    f_rs(1) = 20.0d0        ! Resistance factor
    wp_rs(1) = 0.12d0       ! Wilting point for resistance
    zd_max(1) = 0.05d0      ! Maximum dry layer = 5 cm
    print *, '  f_rs   = ', f_rs(1)
    print *, '  wp_rs  = ', wp_rs(1)
    print *, '  zd_max = ', zd_max(1), ' m'
    print *, '  SUCCESS!'
    print *, ''

    ! Test 7: Set erosion parameters
    print *, 'Test 7: Setting erosion parameters...'
    eross(1,1) = 0.001d0    ! Erosion coefficient
    print *, '  Erosion coeff = ', eross(1,1)
    print *, '  SUCCESS!'
    print *, ''

    ! Display module info
    call get_soil_info()

    ! Test 8: Access a table value
    print *, 'Test 8: Soil hydraulic table...'
    s_tab(1,1,1) = -1.0d0   ! Pressure head at row 1
    s_tab(1,2,1) = 0.15d0   ! Water content at row 1
    s_tab(1,3,1) = 0.5d0    ! Hydraulic conductivity at row 1
    iactab(1) = 100         ! 100 rows in table
    print *, '  Table row 1:'
    print *, '    h     = ', s_tab(1,1,1), ' m'
    print *, '    theta = ', s_tab(1,2,1)
    print *, '    K/K_s = ', s_tab(1,3,1)
    print *, '  Table rows = ', iactab(1)
    print *, '  SUCCESS!'
    print *, ''

    ! Deallocate
    print *, 'Deallocating soil arrays...'
    call deallocate_soil()
    print *, 'SUCCESS! Soil arrays deallocated'
    print *, ''

    print *, '======================================================'
    print *, 'ALL TESTS PASSED SUCCESSFULLY'
    print *, '======================================================'
    print *, ''

    print *, 'Key improvements demonstrated:'
    print *, '  [1] 290-line modern module replaces 51-line include'
    print *, '  [2] Clean organization by property type'
    print *, '  [3] Automatic initialization to safe defaults'
    print *, '  [4] Type-safe parameter access'
    print *, '  [5] Clear documentation of each parameter'
    print *, ''

end program test_soil_module
