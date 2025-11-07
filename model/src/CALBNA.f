      subroutine calbna(ih,ibna)
c-----------------------------------------------------------------------
c  Hang: Berechnung und Schreibe BNA (Polygon) Datei
c --- Vektoren der Polygonecken   
c     hloe	! upper left
c     hroe	! upper right
c     hrue	! lower right
c     hlue	! lower left   
c     sloe	! upper left
c     sroe	! upper right
c     srue	! lower right
c     slue	! lower left
c --- Berechnung der Polygonecken   
c     hmo   ! center top
c     hmr   ! center right
c     hmu   ! center bottom
c     hml   ! center left      
c     smo   ! center top
c     smr   ! center right
c     smu   ! center bottom
c     sml   ! center left      
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'

      real*8 sxz, hxz, sez, hez, sz, hz
      dimension  sxz(maxnv,maxnl-1)
      dimension  hxz(maxnv,maxnl-1)
      dimension  sez(maxnv-1,maxnl)
      dimension  hez(maxnv-1,maxnl)
      dimension  sz(maxnv-1,maxnl-1)
      dimension  hz(maxnv-1,maxnl-1)

      integer*4 iv,il,ih
      integer*4 ibna, ilfdnr, inr4, inr6, inr8

      external ggcross
            
      ilfdnr = 0
      inr4 = 5
      inr6 = 7
      inr8 = 9

      do 120 il = 1,iacnl(ih)-1
        do 125 iv = 1,iacnv(ih)
          sxz(iv,il) = 0.5*(sko(iv,il,ih)+sko(iv,il+1,ih))
          hxz(iv,il) = 0.5*(hko(iv,il,ih)+hko(iv,il+1,ih))
  125   continue
  120 continue
      do 220 iv = 1,iacnv(ih)-1
        do 225 il = 1,iacnl(ih)
          sez(iv,il) = 0.5*(sko(iv,il,ih)+sko(iv+1,il,ih))
          hez(iv,il) = 0.5*(hko(iv,il,ih)+hko(iv+1,il,ih))
  225   continue
  220 continue

      do 230 il = 1,iacnl(ih)-1
        do 240 iv = 1,iacnv(ih)-1
          call ggcross(sxz(iv,il),hxz(iv,il),sxz(iv+1,il),hxz(iv+1,il),
     &                 sez(iv,il),hez(iv,il),sez(iv,il+1),hez(iv,il+1),
     &                 sz(iv,il),hz(iv,il))
  240   continue
  230 continue

C     WRITE POLGYONS TO OUTPUT FILE AND ASSIGN POLYGON CORNER COORDINATES
c           here hko is still real elevation, therefore subtracting - hkomin(ih)
c     lower left node
        il=1
        iv=1
        ilfdnr = ilfdnr+1
        write(ibna,5000) ilfdnr, inr4, sko(iv,il,ih), hko(iv,il,ih)
        write(ibna,5001) sko(iv,il,ih), hko(iv,il,ih)
        write(ibna,5001) sez(iv,il), hez(iv,il)
        write(ibna,5001) sz(iv,il), hz(iv,il)
        write(ibna,5001) sxz(iv,il), hxz(iv,il)
        write(ibna,5001) sko(iv,il,ih), hko(iv,il,ih)
        sloe(iv,il,ih) = sez(iv,il)	! upper left
        hloe(iv,il,ih) = hez(iv, il)- hkomin(ih)	! upper left
        sroe(iv,il,ih) = sz(iv,il)     ! upper right
        hroe(iv,il,ih) = hz(iv,il)- hkomin(ih)     ! upper right
        srue(iv,il,ih) = sxz(iv,il)	! lower right
        hrue(iv,il,ih) = hxz(iv,il)- hkomin(ih)	! lower right
        slue(iv,il,ih) = sko(iv,il,ih)	! lower left        
        hlue(iv,il,ih) = hko(iv,il,ih)- hkomin(ih)	! lower left   
        smo(iv,il,ih) = 0.5*(sloe(iv,il,ih)+sroe(iv,il,ih))
        hmo(iv,il,ih) = 0.5*(hloe(iv,il,ih)+ hroe(iv,il,ih))  
        smr(iv,il,ih) = 0.5*(sroe(iv,il,ih)+srue(iv,il,ih))
        hmr(iv,il,ih) = 0.5*(hroe(iv,il,ih) + hrue(iv,il,ih)) 
        smu(iv,il,ih) = 0.5*(srue(iv,il,ih) + slue(iv,il,ih))
        hmu(iv,il,ih) = 0.5*(hrue(iv,il,ih) + hlue(iv,il,ih))
        sml(iv,il,ih) = 0.5*(slue(iv,il,ih) + sloe(iv,il,ih))
        hml(iv,il,ih) = 0.5*(hlue(iv,il,ih) + hloe(iv,il,ih))
          
c     leftmost column      
      do 300 iv = 2,iacnv(ih)-1
        ilfdnr = ilfdnr+1
        write(ibna,5000) ilfdnr, inr6, sko(iv,il,ih), hko(iv,il,ih)
        write(ibna,5001) sko(iv,il,ih), hko(iv,il,ih)
        write(ibna,5001) sez(iv,il), hez(iv,il)
        write(ibna,5001) sz(iv,il), hz(iv,il)
        write(ibna,5001) sxz(iv,il), hxz(iv,il)
        write(ibna,5001) sz(iv-1,il), hz(iv-1,il)
        write(ibna,5001) sez(iv-1,il), hez(iv-1,il)
        write(ibna,5001) sko(iv,il,ih), hko(iv,il,ih)
        sloe(iv,il,ih) = sez(iv,il)	! upper left
        hloe(iv,il,ih) = hez(iv, il)- hkomin(ih)	! upper left
        sroe(iv,il,ih) = sz(iv,il)! upper right
        hroe(iv,il,ih) = hz(iv,il)- hkomin(ih)      ! upper right
        srue(iv,il,ih) = sz(iv-1,il)	! lower right
        hrue(iv,il,ih) = hz(iv-1,il)- hkomin(ih)	! lower right
        slue(iv,il,ih) = sez(iv-1,il)	! lower left        
        hlue(iv,il,ih) = hez(iv-1,il)- hkomin(ih)	! lower left   
        smo(iv,il,ih) = 0.5*(sloe(iv,il,ih)+sroe(iv,il,ih))
        hmo(iv,il,ih) = 0.5*(hloe(iv,il,ih)+ hroe(iv,il,ih))  
        smr(iv,il,ih) = sxz(iv,il)
        hmr(iv,il,ih) = hxz(iv,il) - hkomin(ih) 
        smu(iv,il,ih) = 0.5*(srue(iv,il,ih) + slue(iv,il,ih))
        hmu(iv,il,ih) = 0.5*(hrue(iv,il,ih) + hlue(iv,il,ih))
        sml(iv,il,ih) = sko(iv,il,ih) 
        hml(iv,il,ih) = hko(iv,il,ih) - hkomin(ih)

  300 continue
c     upper left node
      iv=iacnv(ih)
      ilfdnr = ilfdnr+1
        write(ibna,5000) ilfdnr, inr4, sko(iv,il,ih), hko(iv,il,ih)
        write(ibna,5001) sko(iv,il,ih), hko(iv,il,ih)
        write(ibna,5001) sxz(iv,il), hxz(iv,il)
        write(ibna,5001) sz(iv-1,il), hz(iv-1,il)
        write(ibna,5001) sez(iv-1,il), hez(iv-1,il)
        write(ibna,5001) sko(iv,il,ih), hko(iv,il,ih)
        sloe(iv,il,ih) = sko(iv,il,ih)	! upper left
        hloe(iv,il,ih) = hko(iv,il,ih)- hkomin(ih)	! upper left
        sroe(iv,il,ih) = sxz(iv,il)    ! upper right
        hroe(iv,il,ih) = hxz(iv,il)- hkomin(ih)    ! upper right
        srue(iv,il,ih) = sz(iv-1,il)	! lower right
        hrue(iv,il,ih) = hz(iv-1,il)- hkomin(ih)	! lower right
        slue(iv,il,ih) = sez(iv-1,il)	! lower left        
        hlue(iv,il,ih) = hez(iv-1,il)- hkomin(ih)	! lower left   
        smo(iv,il,ih) = 0.5*(sloe(iv,il,ih)+sroe(iv,il,ih))
        hmo(iv,il,ih) = 0.5*(hloe(iv,il,ih)+ hroe(iv,il,ih))  
        smr(iv,il,ih) = 0.5*(sroe(iv,il,ih)+srue(iv,il,ih))
        hmr(iv,il,ih) = 0.5*(hroe(iv,il,ih) + hrue(iv,il,ih)) 
        smu(iv,il,ih) = 0.5*(srue(iv,il,ih) + slue(iv,il,ih))
        hmu(iv,il,ih) = 0.5*(hrue(iv,il,ih) + hlue(iv,il,ih))
        sml(iv,il,ih) = 0.5*(slue(iv,il,ih) + sloe(iv,il,ih))
        hml(iv,il,ih) = 0.5*(hlue(iv,il,ih) + hloe(iv,il,ih))

      do 310 il = 2,iacnl(ih)-1
c     lower (inner) row
        iv=1
        ilfdnr = ilfdnr+1
        write(ibna,5000) ilfdnr, inr6, sko(iv,il,ih), hko(iv,il,ih)
        write(ibna,5001) sko(iv,il,ih), hko(iv,il,ih)
        write(ibna,5001) sxz(iv,il-1), hxz(iv,il-1)
        write(ibna,5001) sz(iv,il-1), hz(iv,il-1)
        write(ibna,5001) sez(iv,il), hez(iv,il)
        write(ibna,5001) sz(iv,il), hz(iv,il)
        write(ibna,5001) sxz(iv,il), hxz(iv,il)
        write(ibna,5001) sko(iv,il,ih), hko(iv,il,ih)
        sloe(iv,il,ih) = sz(iv,il-1)	! upper left
        hloe(iv,il,ih) = hz(iv,il-1)- hkomin(ih)	! upper left
        sroe(iv,il,ih) = sz(iv,il)    ! upper right
        hroe(iv,il,ih) = hz(iv,il)- hkomin(ih)    ! upper right
        srue(iv,il,ih) = sxz(iv,il)	! lower right
        hrue(iv,il,ih) = hxz(iv,il)- hkomin(ih)	! lower right
        slue(iv,il,ih) = sxz(iv,il-1)	! lower left        
        hlue(iv,il,ih) = hxz(iv,il-1)- hkomin(ih)	! lower left   
        smo(iv,il,ih) = sez(iv,il)
        hmo(iv,il,ih) = hez(iv,il) - hkomin(ih) 
        smr(iv,il,ih) = 0.5*(sroe(iv,il,ih)+srue(iv,il,ih))
        hmr(iv,il,ih) = 0.5*(hroe(iv,il,ih) + hrue(iv,il,ih)) 
        smu(iv,il,ih) = sko(iv,il,ih)
        hmu(iv,il,ih) = hko(iv,il,ih) - hkomin(ih)
        sml(iv,il,ih) = 0.5*(slue(iv,il,ih) + sloe(iv,il,ih))
        hml(iv,il,ih) = 0.5*(hlue(iv,il,ih) + hloe(iv,il,ih))


c     inner nodes
        do 320 iv = 2,iacnv(ih)-1
            ilfdnr = ilfdnr+1
            write(ibna,5000) ilfdnr, inr8, sko(iv,il,ih), hko(iv,il,ih)
            write(ibna,5001) sxz(iv,il-1), hxz(iv,il-1)
            write(ibna,5001) sz(iv,il-1), hz(iv,il-1)
            write(ibna,5001) sez(iv,il), hez(iv,il)
            write(ibna,5001) sz(iv,il), hz(iv,il)
            write(ibna,5001) sxz(iv,il), hxz(iv,il)
            write(ibna,5001) sz(iv-1,il), hz(iv-1,il)
            write(ibna,5001) sez(iv-1,il), hez(iv-1,il)
            write(ibna,5001) sz(iv-1,il-1), hz(iv-1,il-1)
            write(ibna,5001) sxz(iv,il-1), hxz(iv,il-1)
            sloe(iv,il,ih) = sz(iv,il-1)	! upper left
            hloe(iv,il,ih) = hz(iv,il-1)- hkomin(ih)	! upper left
            sroe(iv,il,ih) = sz(iv,il)    ! upper right
            hroe(iv,il,ih) = hz(iv,il)- hkomin(ih)    ! upper right
            srue(iv,il,ih) = sz(iv-1,il)	! lower right
            hrue(iv,il,ih) = hz(iv-1,il)- hkomin(ih)	! lower right
            slue(iv,il,ih) = sz(iv-1,il-1)	! lower left        
            hlue(iv,il,ih) = hz(iv-1,il-1)- hkomin(ih)	! lower left   
            smo(iv,il,ih) = sez(iv,il)
            hmo(iv,il,ih) = hez(iv,il)- hkomin(ih)  
            smr(iv,il,ih) = sxz(iv,il)
            hmr(iv,il,ih) = hxz(iv,il) - hkomin(ih)
            smu(iv,il,ih) = sez(iv-1,il)
            hmu(iv,il,ih) = hez(iv-1,il)- hkomin(ih)
            sml(iv,il,ih) = sxz(iv,il-1)
            hml(iv,il,ih) = hxz(iv,il-1)- hkomin(ih)

  320   continue
c     top row (inner nodes)
        iv=iacnv(ih)
        ilfdnr = ilfdnr+1
        write(ibna,5000) ilfdnr, inr6, sko(iv,il,ih), hko(iv,il,ih)
        write(ibna,5001) sko(iv,il,ih), hko(iv,il,ih)
        write(ibna,5001) sxz(iv,il), hxz(iv,il)
        write(ibna,5001) sz(iv-1,il), hz(iv-1,il)! lower right
        write(ibna,5001) sez(iv-1,il), hez(iv-1,il)
        write(ibna,5001) sz(iv-1,il-1), hz(iv-1,il-1)! lower left
        write(ibna,5001) sxz(iv,il-1), hxz(iv,il-1)
        write(ibna,5001) sko(iv,il,ih), hko(iv,il,ih)
        sloe(iv,il,ih) = sxz(iv,il-1)	! upper left
        hloe(iv,il,ih) = hxz(iv,il-1)- hkomin(ih)	! upper left
        sroe(iv,il,ih) = sxz(iv,il)    ! upper right
        hroe(iv,il,ih) = hxz(iv,il)- hkomin(ih)    ! upper right
        srue(iv,il,ih) = sz(iv-1,il)	! lower right
        hrue(iv,il,ih) = hz(iv-1,il)- hkomin(ih)	! lower right
        slue(iv,il,ih) = sz(iv-1,il-1)	! lower left        
        hlue(iv,il,ih) = hz(iv-1,il-1)- hkomin(ih)	! lower left   
        smo(iv,il,ih) = sko(iv,il,ih)
        hmo(iv,il,ih) = hko(iv,il,ih) - hkomin(ih)
        smr(iv,il,ih) = 0.5*(sroe(iv,il,ih)+srue(iv,il,ih))
        hmr(iv,il,ih) = 0.5*(hroe(iv,il,ih) + hrue(iv,il,ih)) 
        smu(iv,il,ih) = sez(iv-1,il)
        hmu(iv,il,ih) = hez(iv-1,il)- hkomin(ih)
        sml(iv,il,ih) = 0.5*(slue(iv,il,ih) + sloe(iv,il,ih))
        hml(iv,il,ih) = 0.5*(hlue(iv,il,ih) + hloe(iv,il,ih))
        
  310 continue

        il=iacnl(ih)
c       lower right node
        iv=1
        ilfdnr = ilfdnr+1
        write(ibna,5000) ilfdnr, inr4, sko(iv,il,ih), hko(iv,il,ih)
        write(ibna,5001) sko(iv,il,ih), hko(iv,il,ih)
        write(ibna,5001) sxz(iv,il-1), hxz(iv,il-1)
        write(ibna,5001) sz(iv,il-1), hz(iv,il-1)
        write(ibna,5001) sez(iv,il), hez(iv,il)
        write(ibna,5001) sko(iv,il,ih), hko(iv,il,ih)
        sloe(iv,il,ih) = sz(iv,il-1)   ! upper left
        hloe(iv,il,ih) = hz(iv,il-1)- hkomin(ih)	! upper left
        sroe(iv,il,ih) = sez(iv,il)    ! upper right
        hroe(iv,il,ih) = hez(iv,il)- hkomin(ih)    ! upper right
        srue(iv,il,ih) = sko(iv,il,ih)	! lower right
        hrue(iv,il,ih) = hko(iv,il,ih)- hkomin(ih)	! lower right
        slue(iv,il,ih) = sxz(iv,il-1)	! lower left        
        hlue(iv,il,ih) = hxz(iv,il-1)- hkomin(ih)	! lower left   
        smo(iv,il,ih) = 0.5*(sloe(iv,il,ih)+sroe(iv,il,ih))
        hmo(iv,il,ih) = 0.5*(hloe(iv,il,ih)+ hroe(iv,il,ih))  
        smr(iv,il,ih) = 0.5*(sroe(iv,il,ih)+srue(iv,il,ih))
        hmr(iv,il,ih) = 0.5*(hroe(iv,il,ih) + hrue(iv,il,ih)) 
        smu(iv,il,ih) = 0.5*(srue(iv,il,ih) + slue(iv,il,ih))
        hmu(iv,il,ih) = 0.5*(hrue(iv,il,ih) + hlue(iv,il,ih))
        sml(iv,il,ih) = 0.5*(slue(iv,il,ih) + sloe(iv,il,ih))
        hml(iv,il,ih) = 0.5*(hlue(iv,il,ih) + hloe(iv,il,ih))


c       rightmost column
        do 330 iv = 2,iacnv(ih)-1
            ilfdnr = ilfdnr+1
            write(ibna,5000) ilfdnr, inr6, sko(iv,il,ih), hko(iv,il,ih)
            write(ibna,5001) sko(iv,il,ih), hko(iv,il,ih)
            write(ibna,5001) sez(iv-1,il), hez(iv-1,il)
            write(ibna,5001) sz(iv-1,il-1), hz(iv-1,il-1)
            write(ibna,5001) sxz(iv,il-1), hxz(iv,il-1)
            write(ibna,5001) sz(iv,il-1), hz(iv,il-1)
            write(ibna,5001) sez(iv,il), hez(iv,il)
            write(ibna,5001) sko(iv,il,ih), hko(iv,il,ih)
            sloe(iv,il,ih) = sz(iv,il-1)   ! upper left
            hloe(iv,il,ih) = hz(iv,il-1)- hkomin(ih)	! upper left
            sroe(iv,il,ih) = sez(iv,il)    ! upper right
            hroe(iv,il,ih) = hez(iv,il)- hkomin(ih)    ! upper right
            srue(iv,il,ih) = sez(iv-1,il)	! lower right
            hrue(iv,il,ih) = hez(iv-1,il)- hkomin(ih)	! lower right
            slue(iv,il,ih) = sz(iv-1,il-1)	! lower left        
            hlue(iv,il,ih) = hz(iv-1,il-1)- hkomin(ih)	! lower left   
            smo(iv,il,ih) = 0.5*(sloe(iv,il,ih)+sroe(iv,il,ih))
            hmo(iv,il,ih) = 0.5*(hloe(iv,il,ih)+ hroe(iv,il,ih))  
            smr(iv,il,ih) = sko(iv,il,ih)
            hmr(iv,il,ih) = hko(iv,il,ih) - hkomin(ih)
            smu(iv,il,ih) = 0.5*(srue(iv,il,ih) + slue(iv,il,ih))
            hmu(iv,il,ih) = 0.5*(hrue(iv,il,ih) + hlue(iv,il,ih))
            sml(iv,il,ih) = sxz(iv,il-1)
            hml(iv,il,ih) = hxz(iv,il-1) - hkomin(ih)

  330   continue
c       upper right node
        iv=iacnv(ih)
        ilfdnr = ilfdnr+1
        write(ibna,5000) ilfdnr, inr4, sko(iv,il,ih), hko(iv,il,ih)
        write(ibna,5001) sko(iv,il,ih), hko(iv,il,ih)
        write(ibna,5001) sez(iv-1,il), hez(iv-1,il)
        write(ibna,5001) sz(iv-1,il-1), hz(iv-1,il-1)
        write(ibna,5001) sxz(iv,il-1), hxz(iv,il-1)
        write(ibna,5001) sko(iv,il,ih), hko(iv,il,ih)
        sloe(iv,il,ih) = sxz(iv,il-1)   ! upper left
        hloe(iv,il,ih) = hxz(iv,il-1)- hkomin(ih)	! upper left
        sroe(iv,il,ih) = sko(iv,il,ih)    ! upper right
        hroe(iv,il,ih) = hko(iv,il,ih)- hkomin(ih)    ! upper right
        srue(iv,il,ih) = sez(iv-1,il)	! lower right
        hrue(iv,il,ih) = hez(iv-1,il)- hkomin(ih)	! lower right
        slue(iv,il,ih) = sz(iv-1,il-1)	! lower left        
        hlue(iv,il,ih) = hz(iv-1,il-1)- hkomin(ih)	! lower left   
        smo(iv,il,ih) = 0.5*(sloe(iv,il,ih) + sroe(iv,il,ih))
        hmo(iv,il,ih) = 0.5*(hloe(iv,il,ih) + hroe(iv,il,ih))  
        smr(iv,il,ih) = 0.5*(sroe(iv,il,ih) + srue(iv,il,ih))
        hmr(iv,il,ih) = 0.5*(hroe(iv,il,ih) + hrue(iv,il,ih)) 
        smu(iv,il,ih) = 0.5*(srue(iv,il,ih) + slue(iv,il,ih))
        hmu(iv,il,ih) = 0.5*(hrue(iv,il,ih) + hlue(iv,il,ih))
        sml(iv,il,ih) = 0.5*(slue(iv,il,ih) + sloe(iv,il,ih))
        hml(iv,il,ih) = 0.5*(hlue(iv,il,ih) + hloe(iv,il,ih))

c --- ---

!c TEST jw - alte Version pinpol (< 23.05.12)
!c ilfdnr, hier nicht mehr benötigt, als Integervariable für pinpol genutzt
!        do il = 1, iacnl(ih)
!          do iv = 1,iacnv(ih)
!             call pinpol(sko(iv,il,ih), hko(iv,il,ih)- hkomin(ih), 
!     &                  sloe(iv, il, ih),
!     &                  smo(iv, il, ih), 
!     &                  sroe(iv, il, ih), 
!     &                  smr(iv, il, ih), 
!     &                  srue(iv, il, ih), 
!     &                  smu(iv, il, ih), 
!     &                  slue(iv, il, ih), 
!     &                  sml(iv, il, ih), 
!     &                  hloe(iv, il, ih),
!     &                  hmo(iv, il, ih), 
!     &                  hroe(iv, il, ih), 
!     &                  hmr(iv, il, ih), 
!     &                  hrue(iv, il, ih), 
!     &                  hmu(iv, il, ih), 
!     &                  hlue(iv, il, ih), 
!     &                  hml(iv, il, ih), 
!     &                  ilfdnr)
!  
!                
!                if(ilfdnr .ne. 0.0) then
!                    write(*,*) 'Fehler in CALBNA.for'
!                endif
!                                                                                                                             
!            write(io(19),3000) 
!     &          sloe(iv,il,ih),hloe(iv,il,ih),
!     &          smo(iv, il, ih), hmo(iv, il, ih), 
!     &          sroe(iv,il,ih),hroe(iv,il,ih),
!     &          smr(iv, il, ih),hmr(iv, il, ih),
!     &          srue(iv,il,ih),hrue(iv,il,ih),
!     &          smu(iv, il, ih), hmu(iv, il, ih), 
!     &          slue(iv,il,ih), hlue(iv,il,ih),
!     &          sml(iv, il, ih), hml(iv, il, ih), 
!     &          sko(iv,il,ih), hko(iv,il,ih)- hkomin(ih),
!     &          ilfdnr
!          enddo
!        enddo 
 
 3000 format(18f12.6, i3)


 5000 format(2i5,2f12.4)
 5001 format(2f12.4)

      return
      end
