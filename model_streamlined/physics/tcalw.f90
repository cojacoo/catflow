!===============================================================================
! MODULE: tcalw_module
!
! PURPOSE:
!   Date and time calculation utilities for CATFLOW
!   Modernized version of TCALW.f using Fortran 90 modules
!
! DESCRIPTION:
!   This module provides essential date/time manipulation functions for
!   CATFLOW's temporal integration and output generation. It handles:
!
!   - Date string parsing and formatting
!   - Time arithmetic (adding seconds to dates)
!   - Day-of-year calculations (Julian day number)
!   - Calendar conversions (Gregorian calendar)
!
!   These utilities are critical for:
!   - Driving data time interpolation (meteorological forcing)
!   - Output timestamping (results files)
!   - Time step management (synchronization with observations)
!   - Event timing (precipitation onset, irrigation scheduling)
!
!   DATE STRING FORMAT:
!   ==================
!
!   CATFLOW uses a fixed 22-character date string format:
!   "DD.MM.CCYY HH:MM:SS.FF"
!
!   Where:
!   - DD: Day (01-31)
!   - MM: Month (01-12)
!   - CC: Century (19, 20, 21, etc.)
!   - YY: Year within century (00-99)
!   - HH: Hour (00-23)
!   - MM: Minute (00-59)
!   - SS: Second (00-59)
!   - FF: Hundredths of second (00-99)
!
!   Example: "15.06.1998 14:30:00.00" = June 15, 1998, 2:30 PM
!
!   This format provides:
!   - Human readability
!   - Fixed width for file I/O
!   - Subsecond precision (0.01 s)
!   - Unambiguous date ordering (day.month.year)
!
!   JULIAN DAY NUMBERING:
!   ====================
!
!   The module uses Julian day numbers for date arithmetic:
!   - Continuous day count since November 24, 4714 BC (proleptic Gregorian)
!   - Handles leap years correctly
!   - Simplifies date difference calculations
!   - Standard astronomical/scientific convention
!
!   Day-of-year (1-366) calculated from Julian day:
!   - January 1 = day 1
!   - December 31 = day 365 (or 366 in leap years)
!
!   GREGORIAN CALENDAR:
!   ==================
!
!   Leap year rules:
!   1. Year divisible by 4: leap year
!   2. EXCEPT year divisible by 100: not leap year
!   3. EXCEPT year divisible by 400: leap year
!
!   Examples:
!   - 1996: leap (rule 1)
!   - 1900: not leap (rule 2)
!   - 2000: leap (rule 3)
!
!   Transition from Julian to Gregorian calendar:
!   October 15, 1582 (Gregorian reform)
!
! PUBLIC SUBROUTINES:
!   dsps2ds - Date string plus seconds → date string
!   ds2diny - Date string → day in year
!
! PRIVATE SUBROUTINES (support functions):
!   dat2str - Date components → string
!   str2dat - String → date components
!   plsec   - Date + seconds → new date
!   julian  - Date → Julian calendar info
!   uhrsec  - Time → seconds
!   secuhr  - Seconds → time
!   addtag  - Add days to date
!   julday  - Date → Julian day number (function)
!   caldat  - Julian day number → date
!   JUL     - Day-of-year conversions
!
! USAGE PATTERNS:
!
!   Time stepping:
!   call dsps2ds(date_start, dt_seconds, date_next)
!
!   Day of year for phenology:
!   call ds2diny(date_string, day_number, hour_fraction)
!
!   Output timestamping:
!   call dat2str(jh, ja, mo, ta, st, mi, se, hd, outstring)
!
! TIME PRECISION:
!
!   All time calculations use real(8) (double precision) for seconds:
!   - ~16 decimal digits precision
!   - Adequate for century-scale simulations
!   - Roundoff error << 1 second for typical use
!
!   Subsecond resolution (0.01 s):
!   - Sufficient for hydrological processes
!   - Typical timesteps: seconds to hours
!   - Observation data usually 1-min to 1-hour resolution
!
! VALIDATION REQUIREMENTS:
!
!   1. Date arithmetic:
!      - Verify dsps2ds across month/year boundaries
!      - Test leap year transitions (Feb 28/29)
!      - Check century boundaries (1999→2000)
!
!   2. Julian day calculations:
!      - Compare with published tables
!      - Verify leap year handling
!      - Test Gregorian calendar transition
!
!   3. Day-of-year:
!      - Check Jan 1 = 1, Dec 31 = 365/366
!      - Verify leap year day counts
!
!   4. String formatting:
!      - Ensure fixed 22-character width
!      - Check zero-padding (01, 02, etc.)
!      - Verify all date components
!
! PHYSICS PRESERVATION:
!   ALL operations preserved EXACTLY from original TCALW.f:
!   - Date string format (22 characters)
!   - Julian day algorithm (Numerical Recipes)
!   - Calendar rules (Gregorian)
!   - No algorithmic changes whatsoever
!
! ORIGINAL: TCALW.f (Fortran 77)
! AUTHOR: CATFLOW Development Team
! CONVERTED: CATFLOW Streamlined
! DATE: 2025-11-09
!===============================================================================
module tcalw_module
    implicit none
    private

    ! Public subroutines - date/time utilities
    public :: dsps2ds
    public :: ds2diny

    ! Private subroutines - internal support functions
    ! (dat2str, str2dat, plsec, julian, uhrsec, secuhr, addtag, caldat, JUL)

contains

    !===========================================================================
    ! SUBROUTINE: dsps2ds
    !
    ! PURPOSE: Date string plus seconds → date string
    !
    ! DESCRIPTION:
    !   Adds a specified number of seconds to a date string and returns the
    !   resulting date as a new string. This is the fundamental time-stepping
    !   operation for CATFLOW.
    !
    !   Algorithm:
    !   1. Parse input date string → date components
    !   2. Add seconds to date/time → new date components
    !   3. Format new date components → output string
    !
    !   Handles:
    !   - Hour/day/month/year rollovers
    !   - Leap years
    !   - Negative time increments (backward in time)
    !   - Large time steps (days/months/years)
    !
    !   Used for:
    !   - Advancing simulation time
    !   - Interpolating driving data
    !   - Computing output timestamps
    !
    ! ARGUMENTS:
    !   dstrs  - Input date string [character*(*), input]
    !            Must be at least 22 characters
    !   addsec - Seconds to add [real(8), input]
    !            Can be negative for backward time
    !   dstra  - Output date string [character*(*), output]
    !            Should be at least 22 characters
    !
    ! NOTES:
    !   - Preserves subsecond precision (hundredths of second)
    !   - Thread-safe (no internal state)
    !   - Can handle arbitrarily large time increments
    !===========================================================================
    subroutine dsps2ds(dstrs, addsec, dstra)
        implicit none

        character(*), intent(in)  :: dstrs
        real(8),      intent(in)  :: addsec
        character(*), intent(out) :: dstra

        integer(4) :: jhds, jahs, mons, tags, stds, mins, secs, hdss
        integer(4) :: jhda, jaha, mona, taga, stda, mina, seca, hdsa

        ! Parse input date string
        call str2dat(jhds, jahs, mons, tags, stds, mins, secs, hdss, dstrs)

        ! Add seconds to date
        call plsec(jhds, jahs, mons, tags, stds, mins, secs, hdss, &
                   addsec, &
                   jhda, jaha, mona, taga, stda, mina, seca, hdsa)

        ! Format output date string
        call dat2str(jhda, jaha, mona, taga, stda, mina, seca, hdsa, dstra)

        return
    end subroutine dsps2ds

    !===========================================================================
    ! SUBROUTINE: ds2diny
    !
    ! PURPOSE: Date string → day in year
    !
    ! DESCRIPTION:
    !   Converts a date string to day-of-year (1-366) and fractional hour.
    !   Essential for phenology, solar calculations, and seasonal forcing.
    !
    !   Day numbering:
    !   - January 1 = 1.0
    !   - February 1 = 32.0 (or 32.0 in leap year)
    !   - December 31 = 365.0 (or 366.0 in leap year)
    !
    !   Hour fraction:
    !   - 00:00:00 = 0.0
    !   - 12:00:00 = 12.0
    !   - 23:59:59 = 23.9997...
    !
    !   Used for:
    !   - Growing degree days (GDD)
    !   - Solar declination/radiation
    !   - Phenological stage determination
    !   - Seasonal parameter variations
    !
    ! ARGUMENTS:
    !   datstr - Input date string [character*(*), input]
    !            Must be at least 22 characters
    !   tagnr  - Day of year [real, output]
    !            Range: 1.0 to 365.0 (or 366.0 in leap year)
    !   tagstd - Hour of day [real, output]
    !            Range: 0.0 to 23.9997...
    !
    ! NOTES:
    !   - tagnr is REAL (single precision) for historical compatibility
    !   - Accounts for leap years automatically
    !   - Minutes and seconds converted to fractional hours
    !===========================================================================
    subroutine ds2diny(datstr, tagnr, tagstd)
        implicit none

        character(*), intent(in)  :: datstr
        real,         intent(out) :: tagnr
        real,         intent(out) :: tagstd

        integer(4) :: jhda, jaha, mona, taga, stda, mina, seca, hdsa
        integer(4) :: wochtag
        real :: jultag, wochnr
        character(2) :: tagnam

        intrinsic :: real

        ! Parse date string
        call str2dat(jhda, jaha, mona, taga, stda, mina, seca, hdsa, datstr)

        ! Convert time to fractional hours
        tagstd = real(stda) + real(mina)/60.0 + real(seca)/3600.0

        ! Get Julian calendar information (day of year)
        call julian(taga, mona, jhda, jaha, &
                    jultag, wochtag, tagnam, wochnr, tagnr)

        return
    end subroutine ds2diny

    !===========================================================================
    ! SUBROUTINE: dat2str
    !
    ! PURPOSE: Convert date components to formatted string
    !
    ! DESCRIPTION:
    !   Formats individual date/time components into CATFLOW's standard
    !   22-character date string format: "DD.MM.CCYY HH:MM:SS.FF"
    !
    !   Zero-pads all fields to maintain fixed width.
    !
    ! ARGUMENTS:
    !   jhd1, jah1, mon1, tag1 - Date components [integer(4), input]
    !   std1, min1, sec1, hds1 - Time components [integer(4), input]
    !   outstr - Formatted date string [character*(*), output]
    !===========================================================================
    subroutine dat2str(jhd1, jah1, mon1, tag1, std1, min1, sec1, hds1, outstr)
        implicit none

        integer(4),   intent(in)  :: jhd1, jah1, mon1, tag1
        integer(4),   intent(in)  :: std1, min1, sec1, hds1
        character(*), intent(out) :: outstr

        ! Initialize template
        write(outstr(1:22), 100)
100     format('  .  .       :  :  .  ')

        ! Format date/time components with zero-padding
        if (tag1 < 10) then
            write(outstr(1:2), 101) tag1
        else
            write(outstr(1:2), 102) tag1
        end if

        if (mon1 < 10) then
            write(outstr(4:5), 101) mon1
        else
            write(outstr(4:5), 102) mon1
        end if

        if (jhd1 < 10) then
            write(outstr(7:8), 101) jhd1
        else
            write(outstr(7:8), 102) jhd1
        end if

        if (jah1 < 10) then
            write(outstr(9:10), 101) jah1
        else
            write(outstr(9:10), 102) jah1
        end if

        if (std1 < 10) then
            write(outstr(12:13), 101) std1
        else
            write(outstr(12:13), 102) std1
        end if

        if (min1 < 10) then
            write(outstr(15:16), 101) min1
        else
            write(outstr(15:16), 102) min1
        end if

        if (sec1 < 10) then
            write(outstr(18:19), 101) sec1
        else
            write(outstr(18:19), 102) sec1
        end if

        if (hds1 < 10) then
            write(outstr(21:22), 101) hds1
        else
            write(outstr(21:22), 102) hds1
        end if

        return
101     format('0', i1)
102     format(i2)
    end subroutine dat2str

    !===========================================================================
    ! SUBROUTINE: str2dat
    !
    ! PURPOSE: Parse date string to components
    !
    ! DESCRIPTION:
    !   Parses CATFLOW's 22-character date string into individual integer
    !   components for date arithmetic.
    !
    ! ARGUMENTS:
    !   jhd1, jah1, mon1, tag1 - Date components [integer(4), output]
    !   std1, min1, sec1, hds1 - Time components [integer(4), output]
    !   outstr - Formatted date string [character*(*), input]
    !===========================================================================
    subroutine str2dat(jhd1, jah1, mon1, tag1, std1, min1, sec1, hds1, outstr)
        implicit none

        integer(4),   intent(out) :: jhd1, jah1, mon1, tag1
        integer(4),   intent(out) :: std1, min1, sec1, hds1
        character(*), intent(in)  :: outstr

        read(outstr(1:22), 100) tag1, mon1, jhd1, jah1, std1, min1, sec1, hds1
100     format(i2, 1x, i2, 1x, i2, i2, 1x, i2, 1x, i2, 1x, i2, 1x, i2)

        return
    end subroutine str2dat

    !===========================================================================
    ! SUBROUTINE: plsec
    !
    ! PURPOSE: Add seconds to date
    !
    ! DESCRIPTION:
    !   Adds (or subtracts) seconds to a date/time, properly handling
    !   day/month/year rollovers.
    !
    !   Algorithm:
    !   1. Convert time-of-day to seconds
    !   2. Add increment (may be negative)
    !   3. Extract day rollover count
    !   4. Update calendar date by days
    !   5. Convert remaining seconds back to time
    !
    ! ARGUMENTS:
    !   jhd1, jah1, mon1, tag1 - Input date [integer(4), input]
    !   std1, min1, sec1, hds1 - Input time [integer(4), input]
    !   asec - Seconds to add [real(8), input]
    !   jhd2, jah2, mon2, tag2 - Output date [integer(4), output]
    !   std2, min2, sec2, hds2 - Output time [integer(4), output]
    !===========================================================================
    subroutine plsec(jhd1, jah1, mon1, tag1, std1, min1, sec1, hds1, &
                     asec, &
                     jhd2, jah2, mon2, tag2, std2, min2, sec2, hds2)
        implicit none

        integer(4), intent(in)  :: jhd1, jah1, mon1, tag1
        integer(4), intent(in)  :: std1, min1, sec1, hds1
        real(8),    intent(in)  :: asec
        integer(4), intent(out) :: jhd2, jah2, mon2, tag2
        integer(4), intent(out) :: std2, min2, sec2, hds2

        real(8) :: addsec, dsec1, hlp, tagsec
        integer(4) :: idtag

        intrinsic :: nint, dmod

        addsec = asec
        jhd2 = jhd1
        tagsec = 24.0d0 * 3600.0d0

        ! Extract full days from seconds
        addsec = dmod(addsec, tagsec)
        idtag = nint((asec - addsec) / tagsec)

        ! Convert current time to seconds
        call uhrsec(std1, min1, sec1, hds1, dsec1)

        ! Add remaining seconds
        hlp = dsec1 + addsec

        ! Handle day boundaries
        if (hlp > tagsec) then
            addsec = hlp - tagsec
            idtag = idtag + 1
        else if (hlp < 0.0d0) then
            addsec = hlp + tagsec
            idtag = idtag - 1
        else
            addsec = hlp
        end if

        ! Update calendar date by days
        call addtag(jhd1, jah1, mon1, tag1, idtag, jhd2, jah2, mon2, tag2)

        ! Convert seconds back to time
        call secuhr(std2, min2, sec2, hds2, addsec)

        return
    end subroutine plsec

    !===========================================================================
    ! SUBROUTINE: uhrsec
    !
    ! PURPOSE: Convert time to seconds (double precision)
    !
    ! DESCRIPTION:
    !   Converts hours:minutes:seconds.hundredths to total seconds as
    !   real(8) for precise time arithmetic.
    !
    ! ARGUMENTS:
    !   std, min, sec, hds - Time components [integer(4), input]
    !   tagsec - Total seconds [real(8), output]
    !===========================================================================
    subroutine uhrsec(std, min, sec, hds, tagsec)
        implicit none

        integer(4), intent(in)  :: std, min, sec, hds
        real(8),    intent(out) :: tagsec

        intrinsic :: dble

        tagsec = dble(std) * 3600.0d0
        tagsec = tagsec + dble(min * 60)
        tagsec = tagsec + dble(sec)
        tagsec = tagsec + dble(hds) / 100.0d0

        return
    end subroutine uhrsec

    !===========================================================================
    ! SUBROUTINE: secuhr
    !
    ! PURPOSE: Convert seconds to time components
    !
    ! DESCRIPTION:
    !   Converts total seconds (real*8) to hours:minutes:seconds.hundredths.
    !   Inverse of uhrsec.
    !
    ! ARGUMENTS:
    !   std, min, sec, hds - Time components [integer(4), output]
    !   tagsec - Total seconds [real(8), input]
    !===========================================================================
    subroutine secuhr(std, min, sec, hds, tagsec)
        implicit none

        integer(4), intent(out) :: std, min, sec, hds
        real(8),    intent(in)  :: tagsec

        real(8) :: hlp, tagsec_work

        intrinsic :: aint, dble

        tagsec_work = tagsec

        ! Extract hours
        hlp = tagsec_work / 3600.0d0
        std = int(aint(hlp))

        ! Extract minutes
        tagsec_work = tagsec_work - dble(std) * 3600.0d0
        hlp = tagsec_work / 60.0d0
        min = int(aint(hlp))

        ! Extract seconds
        tagsec_work = tagsec_work - dble(min) * 60.0d0
        hlp = tagsec_work
        sec = int(aint(hlp))

        ! Extract hundredths
        tagsec_work = tagsec_work - dble(sec)
        hds = int(aint(tagsec_work * 100.0d0))

        return
    end subroutine secuhr

    !===========================================================================
    ! SUBROUTINE: addtag
    !
    ! PURPOSE: Add days to date
    !
    ! DESCRIPTION:
    !   Adds (or subtracts) integer days to a calendar date using Julian
    !   day number arithmetic.
    !
    !   Algorithm:
    !   1. Convert date to Julian day number
    !   2. Add day increment
    !   3. Convert back to calendar date
    !
    ! ARGUMENTS:
    !   ih1, ij1, im1, it1 - Input date [integer(4), input]
    !   idtag - Days to add [integer(4), input]
    !   ih2, ij2, im2, it2 - Output date [integer(4), output]
    !===========================================================================
    subroutine addtag(ih1, ij1, im1, it1, idtag, ih2, ij2, im2, it2)
        implicit none

        integer(4), intent(in)  :: ih1, ij1, im1, it1
        integer(4), intent(in)  :: idtag
        integer(4), intent(out) :: ih2, ij2, im2, it2

        integer(4) :: jh2, jj2, jm2, jt2
        integer(4) :: jd

        intrinsic :: int

        ! Convert to Julian day number
        jd = julday(ih1, ij1, im1, it1) + int(idtag)

        ! Convert back to calendar date
        call caldat(jd, jh2, jj2, jm2, jt2)

        ih2 = int(jh2)
        ij2 = int(jj2)
        im2 = int(jm2)
        it2 = int(jt2)

        return
    end subroutine addtag

    !===========================================================================
    ! FUNCTION: julday
    !
    ! PURPOSE: Convert calendar date to Julian day number
    !
    ! DESCRIPTION:
    !   Implements Gregorian calendar to Julian day number conversion.
    !   From Numerical Recipes.
    !
    !   Julian day number is continuous day count since November 24, 4714 BC.
    !   Accounts for Gregorian calendar reform (October 15, 1582).
    !
    ! ARGUMENTS:
    !   jh, yy - Century and year within century [integer(4), input]
    !   mm, id - Month and day [integer(4), input]
    !
    ! RETURNS:
    !   Julian day number [integer(4)]
    !===========================================================================
    integer(4) function julday(jh, yy, mm, id)
        implicit none

        integer(4), intent(in) :: jh, yy, mm, id
        integer(4), parameter :: IGREG = 588829
        integer(4) :: iyyy, ja, jm, jy

        intrinsic :: int

        ! Construct full year from century + year
        iyyy = int(jh * 100 + yy)
        jy = iyyy

        if (jy == 0) then
            write(*, *) 'julday: there is no year zero'
            stop
        end if

        if (jy < 0) jy = jy + 1

        if (mm > 2) then
            jm = mm + 1
        else
            jy = jy - 1
            jm = mm + 13
        end if

        julday = int(365.25d0 * jy) + int(30.6001d0 * jm) + id + 1720995

        ! Gregorian calendar correction
        if (id + 31 * (mm + 12 * iyyy) >= IGREG) then
            ja = int(0.01d0 * jy)
            julday = julday + 2 - ja + int(0.25d0 * ja)
        end if

        return
    end function julday

    !===========================================================================
    ! SUBROUTINE: caldat
    !
    ! PURPOSE: Convert Julian day number to calendar date
    !
    ! DESCRIPTION:
    !   Inverse of julday. Converts Julian day number to Gregorian calendar
    !   date. From Numerical Recipes.
    !
    ! ARGUMENTS:
    !   julian - Julian day number [integer(4), input]
    !   jh, yy - Century and year within century [integer(4), output]
    !   mm, id - Month and day [integer(4), output]
    !===========================================================================
    subroutine caldat(julian, jh, yy, mm, id)
        implicit none

        integer(4), intent(in)  :: julian
        integer(4), intent(out) :: jh, yy, mm, id

        integer(4), parameter :: IGREG = 2299161
        integer(4) :: iyyy, ja, jalpha, jb, jc, jd, je

        intrinsic :: int

        if (julian >= IGREG) then
            jalpha = int(((julian - 1867216) - 0.25d0) / 36524.25d0)
            ja = julian + 1 + jalpha - int(0.25d0 * jalpha)
        else
            ja = julian
        end if

        jb = ja + 1524
        jc = int(6680.0d0 + ((jb - 2439870) - 122.1d0) / 365.25d0)
        jd = 365 * jc + int(0.25d0 * jc)
        je = int((jb - jd) / 30.6001d0)

        id = jb - jd - int(30.6001d0 * je)
        mm = je - 1
        if (mm > 12) mm = mm - 12

        iyyy = jc - 4715
        if (mm > 2) iyyy = iyyy - 1
        if (iyyy <= 0) iyyy = iyyy - 1

        jh = int(iyyy * 0.01d0 + 0.01d0)
        yy = int(iyyy) - jh * 100

        return
    end subroutine caldat

    !===========================================================================
    ! SUBROUTINE: julian
    !
    ! PURPOSE: Calculate Julian calendar information
    !
    ! DESCRIPTION:
    !   Comprehensive Julian calendar calculations including:
    !   - Day of year (1-366)
    !   - Week number
    !   - Day of week
    !
    !   Used for phenology and astronomical calculations.
    !
    ! ARGUMENTS:
    !   TT, MM, HH, JJ - Day, month, century, year [integer(4), input]
    !   RNDTT - Total days since reference [real, output]
    !   ITAG - Day of week (0-7) [integer(4), output]
    !   CTAA - Day name abbreviation [character(2), output]
    !   WOJ - Week number in year [real, output]
    !   TAJ - Day number in year (1-366) [real, output]
    !===========================================================================
    subroutine julian(TT, MM, HH, JJ, RNDTT, ITAG, CTAA, WOJ, TAJ)
        implicit none

        integer(4), intent(in)  :: TT, MM, HH, JJ
        real,       intent(out) :: RNDTT, TAJ, WOJ
        integer(4), intent(out) :: ITAG
        character(2), intent(out) :: CTAA

        integer(4) :: AJ, LVJ, KSJ, LSJ, NSJ, LM, ML(0:12)
        integer(4) :: L, IWH
        real :: RNDLVJ, RNDLM, HILF, WH, RH

        character(2) :: CTAG(0:7)

        intrinsic :: int, nint, real, amod

        data ML /0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31/
        data CTAG /'SA', 'SO', 'MO', 'DI', 'MI', 'DO', 'FR', 'SA'/

        ! Determine if leap year
        AJ = HH * 100 + JJ
        LVJ = AJ - 1
        KSJ = int(LVJ / 4)
        LSJ = KSJ * 4
        NSJ = LSJ + 4

        if (AJ == NSJ) then
            ML(2) = 29
        else
            ML(2) = 28
            if (MM == 2 .and. TT == 29) then
                stop 'UP JULIAN: 29. Februar existiert nicht !'
            end if
        end if

        ! Days in previous years
        RNDLVJ = real(LSJ) * 365.25 + real(LVJ - LSJ) * 365.0

        ! Day of year calculation
        LM = MM - 1
        TAJ = 0.0
        do L = 0, LM
            TAJ = TAJ + real(ML(L))
        end do

        RNDLM = RNDLVJ + TAJ
        TAJ = TAJ + real(TT)
        WOJ = int(TAJ / 7.0) + 1.0

        ! Total days for day-of-week calculation
        RNDTT = RNDLM + real(TT)
        HILF = amod(RNDTT, 35000.0)
        WH = HILF / 7.0
        IWH = int(WH)
        RH = WH - real(IWH)
        ITAG = nint(RH * 7.0)
        CTAA = CTAG(ITAG)

        return
    end subroutine julian

end module tcalw_module
