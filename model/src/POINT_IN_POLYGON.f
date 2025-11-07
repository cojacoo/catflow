
      subroutine pinpol(px, py, oldx, oldy, ind_e, ind_x, ih, 
     &                      sk_edge, hk_edge, side) 
c-----------------------------------------------------------------------
c  Testen, ob Punkt innerhalb Polygon liegt (tt= 1) oder nicht (tt=-1),
c  wenn auf Kante: tt=0                                                                    
c  Rückgabe, welche Seite das Teilchen passiert hat 
c     side = 0 : innerhalb / auf Kante
c     'side': 
c            3      
c     2     0    4
c            1      
c

c basierend auf Pseudocode, Quelle http://de.wikipedia.org/wiki/Punkt-in-Polygon-Test_nach_Jordan
c     (zuletzt gecheckt am 19. Mai 2012)
c       erweitert um Abfrage, ob Punktepaare identisch sind
c       erweitert um Bestimmung der überschrittenen Seite
     
c     uses function 'rightcross'   
c-----------------------------------------------------------------------
      implicit none

      include 'dim.inc'
      include 'hgfest.inc'
      
      integer*4 tt, ih, ind_e, ind_x
      integer*4 side
      integer*4 rightcross
      real*8  px,py
      real*8  pollox, polrox, polrux, pollux
      real*8  polloy, polroy, polruy, polluy
      real*8  polmlx, polmly, polmox, polmoy
      real*8  polmrx, polmry, polmux, polmuy
      real*8  sk_edge, hk_edge, oldx, oldy
      real*8  eps  
      real*8  sk_edge_o, hk_edge_o, sk_edge_r, hk_edge_r 
      real*8  sk_edge_u, hk_edge_u, sk_edge_l, hk_edge_l   
      real*8  sk_edge_o1, hk_edge_o1, sk_edge_r1, hk_edge_r1 
      real*8  sk_edge_u1, hk_edge_u1, sk_edge_l1, hk_edge_l1   

      external llcross
      intrinsic min, max
        
       eps = 1e-13
       
       tt = -1
       side = 0

        pollox = sloe(ind_e, ind_x, ih)
        polrox = sroe(ind_e, ind_x, ih)
        polrux = srue(ind_e, ind_x, ih) 
        pollux = slue(ind_e, ind_x, ih)
        polloy = hloe(ind_e, ind_x, ih)
        polroy = hroe(ind_e, ind_x, ih)
        polruy = hrue(ind_e, ind_x, ih)
        polluy = hlue(ind_e, ind_x, ih)
        polmlx = sml(ind_e, ind_x, ih)
        polmly = hml(ind_e, ind_x, ih) 
        polmox = smo(ind_e, ind_x, ih)
        polmoy = hmo(ind_e, ind_x, ih)
        polmrx = smr(ind_e, ind_x, ih)
        polmry = hmr(ind_e, ind_x, ih)
        polmux = smu(ind_e, ind_x, ih)
        polmuy = hmu(ind_e, ind_x, ih) 


        tt = tt *rightcross(px, py, polmlx, polmly, pollox, polloy, eps)
        if(tt .eq. 0) goto 111
        tt = tt *rightcross(px, py, pollox, polloy, polmox, polmoy, eps)
        if(tt .eq. 0) goto 111
        tt = tt *rightcross(px, py, polmox, polmoy, polrox, polroy, eps)
        if(tt .eq. 0) goto 111
        tt = tt *rightcross(px, py, polrox, polroy, polmrx, polmry, eps)
        if(tt .eq. 0) goto 111
        tt = tt *rightcross(px, py, polmrx, polmry, polrux, polruy, eps)
        if(tt .eq. 0) goto 111
        tt = tt *rightcross(px, py, polrux, polruy, polmux, polmuy, eps)
        if(tt .eq. 0) goto 111
        tt = tt *rightcross(px, py, polmux, polmuy, pollux, polluy, eps)
        if(tt .eq. 0) goto 111
        tt = tt *rightcross(px, py, pollux, polluy, polmlx, polmly, eps)
       
c        wenn außerhalb ...
        if(tt .lt. 0) then
             
c         Bestimmung der Schnittpunkte mit den Rändern und damit die Seite

c           # oben: links
c            Schnittpunkt Trajektorie mit Rand
               call llcross(oldx,oldy,px,py,
     &                   pollox, polloy,
     &                   polmox, polmoy,
     &                   sk_edge_o1, hk_edge_o1,eps)
               sk_edge_o = sk_edge_o1
               hk_edge_o = hk_edge_o1

c              wenn Schnittpunkt sowohl auf Trajektorie als auch auf Rand liegt, 
c               ist der Schnittpunkt der Punkt, wo das Polygon verlassen wurde 
               if((abs(sk_edge_o - px) + abs(hk_edge_o - py)) .le. eps) 
     &          then
                    side = 0
                    goto 111
               endif
                      
               if(min(px, oldx)-eps .le. sk_edge_o .and.  
     &            sk_edge_o .le. max(px,oldx)+eps .and.
     &            min(py, oldy)-eps .le. hk_edge_o .and.
     &            hk_edge_o .le. max(py,oldy)+eps  .and.
     &            min(polmox, pollox)-eps .le. sk_edge_o .and. 
     &            sk_edge_o .le. max(polmox, pollox)+eps .and.
     &            min(polmoy, polloy)-eps .le. hk_edge_o .and. 
     &            hk_edge_o .le. max(polmoy, polloy)+eps ) then
                  side = 3
                  goto 111
               endif

c           # oben: rechts
               call llcross(oldx,oldy,px,py,
     &                   polmox, polmoy,
     &                   polrox, polroy,
     &                   sk_edge_o, hk_edge_o,eps)
               if((abs(sk_edge_o - px) + abs(hk_edge_o - py)) .le. eps) 
     &           then
                    side = 0
                    goto 111
               endif
     
               if(min(px, oldx)-eps .le. sk_edge_o .and.  
     &            sk_edge_o .le. max(px,oldx)+eps .and.
     &            min(py, oldy)-eps .le. hk_edge_o .and.
     &            hk_edge_o .le. max(py,oldy)+eps  .and.
     &            min(polrox, polmox)-eps .le. sk_edge_o .and. 
     &            sk_edge_o .le. max(polrox, polmox)+eps .and.
     &            min(polmoy, polroy)-eps .le. hk_edge_o .and. 
     &            hk_edge_o .le. max(polmoy, polroy)+eps ) then
                  side = 3
                  goto 111
               endif

c           # rechts: oben
c            Schnittpunkt Trajektorie mit Rand
34             call llcross(oldx,oldy,px,py,
     &                   polrox, polroy,
     &                   polmrx, polmry,
     &                   sk_edge_r1, hk_edge_r1,eps)
               sk_edge_r = sk_edge_r1
               hk_edge_r = hk_edge_r1

               if((abs(sk_edge_r - px) + abs(hk_edge_r - py)) .le. eps) 
     &          then
                    side = 0
                    goto 111
               endif

c              wenn Schnittpunkt sowohl auf Trajektorie als auch auf Rand liegt, 
c               ist der Schnittpunkt der Punkt, wo das Polygon verlassen wurde 
               if(min(px, oldx)-eps .le. sk_edge_r .and.  
     &            sk_edge_r .le. max(px,oldx)+eps .and.
     &            min(py, oldy)-eps .le. hk_edge_r .and.
     &            hk_edge_r .le. max(py,oldy)+eps  .and.
     &            min(polmrx, polrox)-eps .le. sk_edge_r .and. 
     &            sk_edge_r .le. max(polmrx, polrox)+eps .and.
     &            min(polmry, polroy)-eps .le. hk_edge_r .and. 
     &            hk_edge_r .le. max(polmry, polroy)+eps ) then
                  side = 4
                  goto 111
               endif

c           # rechts: unten
               call llcross(oldx,oldy,px,py,
     &                   polmrx, polmry,
     &                   polrux, polruy,
     &                   sk_edge_r, hk_edge_r,eps)
               if((abs(sk_edge_r - px) + abs(hk_edge_r - py)) .le. eps) 
     &          then
                    side = 0
                    goto 111
               endif

               if(min(px, oldx)-eps .le. sk_edge_r .and.  
     &            sk_edge_r .le. max(px,oldx)+eps .and.
     &            min(py, oldy)-eps .le. hk_edge_r .and.
     &            hk_edge_r .le. max(py,oldy)+eps  .and.
     &            min(polmrx, polrux)-eps .le. sk_edge_r .and. 
     &            sk_edge_r .le. max(polmrx, polrux)+eps .and.
     &            min(polmry, polruy)-eps .le. hk_edge_r .and. 
     &            hk_edge_r .le. max(polmry, polruy)+eps ) then
                    side =  4
                    goto 111
               endif

c           # unten: rechts
41             call llcross(oldx,oldy,px,py,
     &                   polrux, polruy,
     &                   polmux, polmuy,
     &                   sk_edge_u1, hk_edge_u1,eps)
               sk_edge_u = sk_edge_u1
               hk_edge_u = hk_edge_u1

               if((abs(sk_edge_u - px) + abs(hk_edge_u - py)) .le. eps) 
     &          then
                    side = 0
                    goto 111
               endif

               if(min(px, oldx)-eps .le. sk_edge_u .and.  
     &            sk_edge_u .le. max(px,oldx)+eps .and.
     &            min(py, oldy)-eps .le. hk_edge_u .and.
     &            hk_edge_u .le. max(py,oldy)+eps  .and.
     &            min(polmux, polrux)-eps .le. sk_edge_u .and. 
     &            sk_edge_u .le. max(polmux, polrux)+eps .and.
     &            min(polmuy, polruy)-eps .le. hk_edge_u .and. 
     &            hk_edge_u .le. max(polmuy, polruy)+eps ) then
                  	side = 1
                    goto 111
               endif

c           # unten: links
               call llcross(oldx,oldy,px,py,
     &                   polmux, polmuy,
     &                   pollux, polluy,
     &                   sk_edge_u, hk_edge_u,eps)
               if((abs(sk_edge_u - px) + abs(hk_edge_u - py)) .le. eps) 
     &          then
                    side = 0
                    goto 111
               endif

               if(min(px, oldx)-eps .le. sk_edge_u .and.  
     &            sk_edge_u .le. max(px,oldx)+eps .and.
     &            min(py, oldy)-eps .le. hk_edge_u .and.
     &            hk_edge_u .le. max(py,oldy)+eps  .and.
     &            min(polmux, pollux)-eps .le. sk_edge_u .and. 
     &            sk_edge_u .le. max(polmux, pollux)+eps .and.
     &            min(polmuy, polluy)-eps .le. hk_edge_u .and. 
     &            hk_edge_u .le. max(polmuy, polluy)+eps ) then
                  	side = 1
                    goto 111
              endif

c           # links: unten 
120            call llcross(oldx,oldy,px,py,
     &                   polmlx, polmly,
     &                   pollux, polluy,
     &                   sk_edge_l1, hk_edge_l1,eps)
               sk_edge_l = sk_edge_l1
               hk_edge_l = hk_edge_l1

               if((abs(sk_edge_l - px) + abs(hk_edge_l - py)) .le. eps)
     &          then
                    side = 0
                    goto 111
               endif

               if(min(px, oldx)-eps .le. sk_edge_l .and.  
     &            sk_edge_l .le. max(px,oldx)+eps .and.
     &            min(py, oldy)-eps .le. hk_edge_l .and.
     &            hk_edge_l .le. max(py,oldy)+eps  .and.
     &            min(polmlx, pollux)-eps .le. sk_edge_l .and. 
     &            sk_edge_l .le. max(polmlx, pollux)+eps .and.
     &            min(polmly, polluy)-eps .le. hk_edge_l .and. 
     &            hk_edge_l .le. max(polmly, polluy)+eps) then
                  	side = 2
                    goto 111
               endif

c           # links: oben 
               call llcross(oldx,oldy,px,py,
     &                   pollox, polloy,
     &                   polmlx, polmly,
     &                   sk_edge_l, hk_edge_l,eps)
               if((abs(sk_edge_l - px) + abs(hk_edge_l - py)) .le. eps) 
     &          then
                    side = 0
                    goto 111
               endif

               if(min(px, oldx)-eps .le. sk_edge_l .and.  
     &            sk_edge_l .le. max(px,oldx)+eps .and.
     &            min(py, oldy)-eps .le. hk_edge_l .and.
     &            hk_edge_l .le. max(py,oldy)+eps  .and.
     &            min(polmlx, pollox)-eps .le. sk_edge_l .and. 
     &            sk_edge_l .le. max(polmlx, pollox)+eps .and.
     &            min(polmly, polloy)-eps .le. hk_edge_l .and. 
     &            hk_edge_l .le. max(polmly, polloy)+eps) then
                  	side = 2
                    goto 111
              endif
         
c      --- wenn keine Seite gequert wurde und nicht zu 111 gesprungen:
          side = -1
        
        endif

111   continue

c      SChnittpunkte setzen und leicht verschieben, damit nicht mehr auf Rand
        if (side .eq. 3) then
            sk_edge = sk_edge_o
            hk_edge = hk_edge_o + 10*eps
        else if (side .eq. 4) then
            sk_edge = sk_edge_r + 10*eps
            hk_edge = hk_edge_r
        else if (side .eq. 1) then
            sk_edge = sk_edge_u
            hk_edge = hk_edge_u - 10*eps
        else if (side .eq. 2) then
            sk_edge = sk_edge_l - 10*eps
            hk_edge = hk_edge_l
        else if(side .ne. 0) then
            sk_edge = 0.0
            hk_edge = 0.0
c            write(*,*) 'Error in pinpol'                                                  ! jw test error message
        endif                                        


      end subroutine pinpol


c-----------------------------------------------------------------------
c   #  auxiliary functions

      integer*4 function rightcross(xa, ya, xb, yb, xc, yc, eps) 
c-----------------------------------------------------------------------
c  Hilfsroutine für pinpol
c-----------------------------------------------------------------------
        
      implicit none

      integer*4 idelta
      real*8 delta, xcc, ycc, xbb, ybb
      real*8 xa, ya, xb, yb, xc, yc
      real*8 eps,one
      intrinsic abs
      
      one=1.
       
        if(ya .eq. yb .and. xa .eq. xb) then
           rightcross = 0
        else if(ya .eq. yc .and. xa .eq. xc) then
           rightcross = 0    
        else if(ya .eq. yb .and. ya .eq. yc) then 
           if(xb .le. xa .and. xa .le. xc ) then
            rightcross = 0
           else if(xc .le. xa .and. xa .le. xb ) then
            rightcross = 0
           else 
            rightcross = 1
           endif

        else
            if (yb .gt. yc) then            ! tauschen B <-> C
                xcc = xb                    ! dummies
                ycc = yb
                xbb = xc
                ybb = yc
            else
                xcc = xc
                ycc = yc
                xbb = xb
                ybb=  yb
            endif

            if (ya .le. ybb .or. ya .gt. ycc) then
                rightcross = 1
            else 
                delta = (xbb - xa)*(ycc - ya) - (ybb - ya)*(xcc - xa)
                if (abs(delta) .le. eps) then
                 rightcross = 0                                                     ! Koordinaten neu setzen wenn kurz über Rand?
                else
                 delta = SIGN(one, delta)
                 idelta = NINT(delta)
                 rightcross = ISIGN(1, idelta)      ! -1 oder 1 
                endif
            endif
        endif
 
      end function rightcross

c     
      subroutine llcross(x0,y0,x1,y1,x2,y2,x3,y3,x,y, eps)
c-----------------------------------------------------------------------
c  Hilfsroutine für pinpol
c-----------------------------------------------------------------------
c    x,y ist der Schnittpunkt zweier Geraden P0-P1 und P2-P3
c    (die nicht parallel/identisch sein duerfen!!)
c    basiert auf subroutine ggcross, erweitert um Abfrage, ob P0 identisch mit P2/P3 bzw. P1 mit P2/P3 (somit auch Schnittpunkt identisch mit Randpunkt)     
    
      real*8 x0,y0,x1,y1,x2,y2,x3,y3,x,y,eps

      intrinsic abs

      if((abs(x0-x2) .lt. eps) .and. (abs(y0-y2) .lt. eps) ) then
           x = x2
           y= y2
      else if((abs(x0-x3) .lt. eps) .and. (abs(y0-y3) .lt. eps)) then 
           x = x3
           y= y3
      else if((abs(x1-x2) .lt. eps) .and. (abs(y1-y2) .lt. eps)) then 
           x = x2
           y= y2
      else if((abs(x1-x3) .lt. eps) .and. (abs(y1-y3) .lt. eps)) then 
           x = x3
           y= y3
      else     
        if ((abs(x0-x1).le. eps) .or. (abs(x2-x3).le. eps) .or.
     &          (abs(y0-y1).le. eps) .or. (abs(y2-y3).le. eps)) then
             if (abs(x0-x1).le. eps) then
              x = x0
              if (abs(y2-y3).le. eps) then
                y = y2
              else
                y = (x-x2)*(y2-y3)/(x2-x3)+y2
              endif
             endif
             if (abs(y0-y1).le. eps) then
              y = y0
              if (abs(x2-x3).le. eps) then
                x = x2
              else
                x = (y-y2)*(x2-x3)/(y2-y3)+x2
              endif
             endif
             if (abs(x2-x3).le. eps) then
              x = x2
              if (abs(y0-y1).le. eps) then
                y = y1
              else
                y = (x-x0)*(y0-y1)/(x0-x1)+y0
              endif
             endif
             if (abs(y2-y3).le. eps) then
              y = y2
              if (abs(x0-x1).le. eps) then
                x = x0
              else
                x = (y-y0)*(x0-x1)/(y0-y1)+x0
              endif
             endif
        else
          y = ( y0+ (x2-x0-y2*(x2-x3)/(y2-y3)) *(y0-y1)/(x0-x1) )/
     &      (1-(x2-x3)/(y2-y3)*(y0-y1)/(x0-x1))
          x = ( x0+ (y2-y0-x2*(y2-y3)/(x2-x3)) *(x0-x1)/(y0-y1) )/
     &      (1-(y2-y3)/(x2-x3)*(x0-x1)/(y0-y1))
        endif
      endif

      return
      end