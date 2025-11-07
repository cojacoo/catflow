      subroutine rel_sec(dr)
      real*8 dr
      character*22 dstre, dstrs
      integer*4 mm, dd, yy
      character*8 zeit

      external dsds2ds
      intrinsic time, idate

      dstrs='01.01.1980 00:00:00.00'
      dstre='01.01.1980 00:00:00.00'
      call idate(mm,dd,yy)
      call time(zeit)
      dstre(12:13)=zeit(1:2)
      dstre(15:16)=zeit(4:5)
      dstre(18:19)=zeit(7:8)
      write(dstre(1:2), '(i2)') dd
      write(dstre(4:5), '(i2)') mm
      write(dstre(9:10),'(i2)') yy


      call dsds2ds(dstre, dstrs, dr)


      return
      end
