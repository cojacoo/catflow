      subroutine rel_sec(dr)
      real*8 dr
      character*22 dstre, dstrs,date2,time2
      integer*2 mm, dd, yy
      character*8 zeit

      external dsds2ds
c      intrinsic time, idate

      dstrs='01.01.1980 00:00:00.00'
      dstre='01.01.1980 00:00:00.00'
      call DATE_AND_TIME (date2,time2)
c      call time(zeit)
      zeit=time2(1:2)//":"//time2(3:4)//":"//time2(5:6)
      dstre(12:13)=zeit(1:2)
      dstre(15:16)=zeit(4:5)
      dstre(18:19)=zeit(7:8)

      write(dstre(1:2), '(a2)') date2(1:4)
      write(dstre(4:5), '(a2)')  date2(5:6)
      write(dstre(9:10),'(a2)') date2(3:4)


      call dsds2ds(dstre, dstrs, dr)


      return
      end
