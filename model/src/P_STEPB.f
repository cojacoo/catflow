c Interpolation Geschwindigkeiten ist raus
c Teilchenreflektion ist raus
c 
c     Verlust oberer Rand einbauen?

      subroutine p_stepb(istp,dt,ih)

c----------------------------------------------------------------------
c  Routinte zur Berechnung des Teilchenstep
c     iplos, zeigt ob Teilchen in der Domaene ist 1, oder nicht 0
c     nur bei iplos=1 wird die schleife gerechnet, bei verlust wird iplos =0 gesetzt
c     Anzahl der Teilchen die pro zeitschritt über rechten, linken, und unteren Rand verschwinden
c     nplosu, nplosl, nplosr, wird übergeben in bilanzfile
c----------------------------------------------------------------------

      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgbdry.inc'
      include 'hgvari.inc'
      include 'pbdry.inc'
      include 'pfest.inc'
      include 'pvari.inc'
      include 'zeit.inc'


      real*8 spvir, hpvir, dt, ran1, ran2
      real*8 sk_rand, hk_rand, sk_zwi, hk_zwi
      real*8 laenge, nenner 	
      real*8 zxsi, zeta, yh, xh, vzx, vze, rs_z, rh_z
      integer*4 i, ih, istp, npt, seite
      integer*4 ievir, ixvir, schritt, checker

      dimension spvir(maxstt, npmax), hpvir(maxstt,npmax)
      dimension sk_rand(100), hk_rand(100), ievir(100), ixvir(100)     
c           maximal 100 Schritte   
      intrinsic abs, int, sign, sqrt

      external ran1, ran2
      external pinpol, llcross
      logical bloed

c      write(6,*)'npact, istact',npact(1,ih), istact, ih
      xh=1.
      zxsi=0.
      zeta=0.

	nplosl(istp,ih)=0
	nplosu(istp,ih)=0
	nplosr(istp,ih)=0
      mlos_l(istp,ih)=0.       
      mlos_u(istp,ih)=0.       
      mlos_r(istp,ih)=0.       

	do 65 npt = 1, npact(istp,ih)

c	 Teilchenschleife läuft nur wenn iplos =1, teilchen in der domaine
      if (iplos(istp,npt,ih) .eq. 1) then                           ! i1

c---- Virtueller Schritt auf Zwischenposition --------------------------
c         1.7= sqrt (3) als Faktor um Zufallszahlen mit
c         Varianz 1 zu nutzen (var = 1/3 U^2, u ist Breite des Intervalls
c------------------------------------------------------------------------
         yh= 0.5 - ran1(iseed)
         vzx =sign(xh,yh)
         rs_z= ran2(iseed)
         zxsi= vzx * rs_z*1.7
         yh = 0.5 -ran1(iseed)
         vze = sign(xh,yh)
         rh_z = ran2(iseed)
         zeta = vze * rh_z*1.7

c  --- vom alten Ort mit alter Geschwindigkeit
         spvir(istp,npt) = skpalt(istp,npt,ih)   
     &       + vx_sta(iealt(istp,npt,ih),ixalt(istp,npt,ih),ih) *dt 
     &          /r_ret(istp,iealt(istp,npt,ih),ixalt(istp,npt,ih))
     &       + zxsi*sqrt(6.*d_koef(istp,iboden(iealt(istp,npt,ih),  
     &          ixalt(istp,npt,ih),ih)) *dt)        
         hpvir(istp,npt) = hkpalt(istp,npt,ih)     
     &       + ve_sta(iealt(istp,npt,ih),ixalt(istp,npt,ih),ih) *dt 
     &          /r_ret(istp,iealt(istp,npt,ih),ixalt(istp,npt,ih))
     &       + zeta*sqrt(6.* d_koef(istp,iboden(iealt(istp,npt,ih),
     &          ixalt(istp,npt,ih),ih))*dt)       


c -------- Bestimmung der Knotennummern (virtueller Schritt) --------------
       schritt = 1
       ievir(2:100) = 0
       ixvir(2:100) = 0
       ievir(schritt) = iealt(istp,npt,ih)
       ixvir(schritt) = ixalt(istp,npt,ih)
       sk_rand(1:100) = 0.0
       hk_rand(1:100) = 0.0
       bloed = .false.
       checker = 1                                                      ! testtesttest

c     Zwischenspeicher für Position (wird zur Verfolgung des Teilchens aktualisiert)       
       sk_zwi = skpalt(istp,npt,ih)
       hk_zwi = hkpalt(istp,npt,ih)


c---  Test, ob Teilchen noch in Polygon, oder über welche Seite es gegangen ist       
121    call pinpol(spvir(istp,npt),hpvir(istp,npt), 
     &             sk_zwi, hk_zwi,
     &             ievir(schritt), ixvir(schritt), ih,
     &             sk_rand(schritt), hk_rand(schritt), 
     &             seite)

c---Teilchenstep, wenn außerhalb alter Zelle
       if( seite .eq. 0) then                                   ! i 101 
          goto 123
       else                                                     ! e101
!c  --Prüfung auf Teilchenverlust, sonst Suche nach Partikel in Nachbarpolygonen (Schritt + 1)

       schritt = schritt + 1

       if(schritt .gt. 10) then
        write(*,*) 'Problem in PSTEPB'                                   ! jw testtest   
       endif

                 
c       Teilchenstep nach rechts        
            if(seite .eq. 4) then
                if (ixvir(schritt-1) .eq. iacnl(ih)) then
c           Verlust: Position setzen auf alte Position, Schritt -1 
                    schritt = schritt-1
                    spvir(istp,npt) = sk_zwi                          
                    hpvir(istp,npt) = hk_zwi
                    goto 123
                else
c           ixvir(schritt) verändern und Teilchen suchen     
                   ixvir(schritt) = ixvir(schritt-1)+1            
                   ievir(schritt) = ievir(schritt-1)
                endif    


c      Teilchenstep nach unten
            else if(seite .eq. 1) then
                if (ievir(schritt-1) .eq. 1) then
c           Verlust: Position setzen auf alte Position 
                    schritt = schritt-1
                    spvir(istp,npt) = sk_zwi                            
                    hpvir(istp,npt) = hk_zwi
                    goto 123
                else
c           ievir(schritt) verändern und Teilchen suchen   
                   ievir(schritt) = ievir(schritt-1)-1      
                   ixvir(schritt) = ixvir(schritt-1)  
                endif    
        
c      Teilchenstep nach links
            else if(seite .eq. 2) then
                if (ixvir(schritt-1) .eq. 1) then
c           Verlust: Position setzen auf alte Position 
                    schritt = schritt-1
                    spvir(istp,npt) = sk_zwi                            
                    hpvir(istp,npt) = hk_zwi
                    goto 123
                else
c           ixvir(schritt) verändern und Teilchen suchen       
                   ixvir(schritt) = ixvir(schritt-1)-1 
                   ievir(schritt) = ievir(schritt-1)      
                endif    

c      Teilchenstep nach oben
            else if(seite .eq. 3) then
                if (ievir(schritt-1) .eq. iacnv(ih)) then
c           Verlust: Position setzen auf alte Position 
                    schritt = schritt-1
                    spvir(istp,npt) = sk_zwi                           
                    hpvir(istp,npt) = hk_zwi
                    goto 123
                else
c           ievir(schritt) verändern und Teilchen suchen       
                   ievir(schritt) = ievir(schritt-1) + 1
                   ixvir(schritt) = ixvir(schritt-1)       
                endif
 
            else 
                 schritt = schritt -1  
                 bloed = .true.
                 checker = checker + 1
                 if(checker .gt. 123) stop 'Error in PSTEP_B' 
c               write(*,*) 'Problem: Undefined side in P_stepb.'        ! jw testtesttest
                write(io(1),313) 
     &         ih,t_act/86400.,npt,istp,ievir(schritt),ixvir(schritt)
  313           format('Info: Undefined side in P_stepb: Hang ',i3
     &            ,', Zeit ',f6.2,' Tage, Partikel ',i8, ' Stoff ', i3,
     &            ' Knoten Reihe ', i5,', Spalte ', i5)

            endif
       
        if(schritt .gt. 5) then
            if(ievir(schritt) .eq. ievir(schritt-2) .and. 
     &          ixvir(schritt) .eq. ixvir(schritt-2)) then
                write(*,*) 'Problem in PSTEPB'                          ! jw testtesttest
	          write(io(1),314) 
     &       ih,t_act/86400.,npt,istp,ievir(schritt),ievir(schritt-1),ixvir(schritt),ixvir(schritt-1)
  314           format('Problem in PSTEPB (virtual step): Hang ',i3
     &            ,', Zeit ',f6.2,' Tage, Partikel ',i8, ' Stoff ', i3,
     &            ' Knoten Reihen ', 2i5,', Spalten ', 2i5)
                 checker = checker + 1
                 if(checker .gt. 123) stop 'Error in PSTEP_B' 

            endif
        endif

        if(bloed .or. sk_zwi .eq. 0.0 .or. hk_zwi .eq. 0.0) then
           sk_zwi = 0.5*(smu(ievir(schritt), ixvir(schritt), ih) 
     &                + smo(ievir(schritt), ixvir(schritt), ih))
            hk_zwi = 0.5*(hmu(ievir(schritt), ixvir(schritt), ih) 
     &                + hmo(ievir(schritt), ixvir(schritt), ih))
            bloed = .false.
        else
c  Zwischenposition: Schnittpunkt zwischen Mittelpunkten unterer/oberer Rand - liegt in Polygon (nicht immer, wenn auch linker/rechter Rand mitgenommen wird!)           
        sk_zwi = sk_rand(schritt-1)
        hk_zwi = hk_rand(schritt-1)
        endif

       goto 121
       endif                                                    !ei 101

123   continue

c    aktualisiere Teilchenpositionen (Knotennummern)   
c        ieact(istp,npt,ih) = ievir(schritt)
c        ixact(istp,npt,ih) = ixvir(schritt)


c-----Mitteln von v'act linear über Teilchenweg, wenn mehrere Polygone durchschritten wurden

          laenge= sqrt((spvir(istp,npt) - skpalt(istp,npt,ih))**2 
     &             + abs(hpvir(istp,npt) - hkpalt(istp,npt,ih))**2)


      if(schritt .eq. 1) then
        vxipo = vx_st(iealt(istp,npt,ih),ixalt(istp,npt,ih),ih)
        veipo = ve_st(iealt(istp,npt,ih),ixalt(istp,npt,ih),ih)
      else if( schritt .eq. 2) then      
c               Länge Schritt / ( Länge1/v1 + Länge2/v2 )
c               Gewichten mit (gesamter) Länge
c               oder nur jeweils xsi/eta Anteil?                            ! jw

c     --- xsi direction
        vxipo = laenge
     &          /(sqrt((sk_rand(schritt-1) - skpalt(istp,npt,ih))**2
     &                  +(hk_rand(schritt-1) - hkpalt(istp,npt,ih))**2)
     &            / vx_st(iealt(istp,npt,ih),ixalt(istp,npt,ih),ih)  
     &            + sqrt((sk_rand(schritt-1)- spvir(istp,npt))**2
     &                   +(hk_rand(schritt-1) - hpvir(istp,npt))**2)
     &            /vx_st(ieact(istp,npt,ih),ixact(istp,npt,ih),ih) )  
c       old velocity not zero (else not stepping out of node)
c       if velocity in new node is zero: keep old velocity 
        if(vx_st(ieact(istp,npt,ih),ixact(istp,npt,ih),ih) .eq. 0) then
            vxipo = vx_st(iealt(istp,npt,ih),ixalt(istp,npt,ih),ih)
        endif
       
c     --- eta direction
        veipo = laenge
     &          /(sqrt((sk_rand(schritt-1) - skpalt(istp,npt,ih))**2
     &                +(hk_rand(schritt-1) - hkpalt(istp,npt,ih))**2)
     &            / ve_st(iealt(istp,npt,ih),ixalt(istp,npt,ih),ih)  
     &            + sqrt((sk_rand(schritt-1)- spvir(istp,npt))**2
     &                  +(hk_rand(schritt-1) - hpvir(istp,npt))**2)
     &            /ve_st(ieact(istp,npt,ih),ixact(istp,npt,ih),ih) )  
      
        if(ve_st(ieact(istp,npt,ih),ixact(istp,npt,ih),ih) .eq. 0) then
            veipo = ve_st(iealt(istp,npt,ih),ixalt(istp,npt,ih),ih)
        endif

      else
c     harmonisches Mittel beteiligte Polygone 

c     xsi-direction
          if(vx_st(ievir(1),ixvir(1),ih) .eq. 0) then
            nenner = 0
          else  
            nenner = sqrt((sk_rand(1) - skpalt(istp,npt,ih))**2
     &              + (hk_rand(1) - hkpalt(istp,npt,ih))**2) / 
     &                vx_st(ievir(1),ixvir(1),ih)
          endif

          do 77 i = 2, schritt-1
             if(vx_st(ievir(i),ixvir(i),ih) .eq. 0) then   
                nenner = nenner
             else
                nenner= nenner +          
     &               sqrt((sk_rand(i) - sk_rand(i-1))**2
     &                + abs(hk_rand(i) - hk_rand(i-1))**2) / 
     &                  vx_st(ievir(i),ixvir(i),ih)
             endif
77        continue

          if(vx_st(ievir(schritt),ixvir(schritt),ih) .eq. 0) then
            nenner = nenner
          else  
          nenner= nenner + 
     &               sqrt((spvir(istp,npt) - sk_rand(schritt-1))**2
     &                + (hpvir(istp,npt) - hk_rand(schritt-1))**2) / 
     &                  vx_st(ievir(schritt),ixvir(schritt),ih)
          endif

          if(nenner .eq. 0) then
            vxipo = 0
          else  
            vxipo = laenge / nenner
          endif

c     eta-direction
          if(ve_st(ievir(1),ixvir(1),ih) .eq. 0) then
            nenner = 0
          else  
            nenner = sqrt((sk_rand(1) - skpalt(istp,npt,ih))**2
     &              + (hk_rand(1) - hkpalt(istp,npt,ih))**2) / 
     &                ve_st(ievir(1),ixvir(1),ih)
          endif
          
          do 88 i = 2, schritt-1
             if(ve_st(ievir(i),ixvir(i),ih) .eq. 0) then   
                nenner = nenner
             else
                nenner= nenner +          
     &               sqrt((sk_rand(i) - sk_rand(i-1))**2
     &                + abs(hk_rand(i) - hk_rand(i-1))**2) / 
     &                  ve_st(ievir(i),ixvir(i),ih)
             endif
88        continue

          if(ve_st(ievir(schritt),ixvir(schritt),ih) .eq. 0) then
            nenner = nenner
          else  
          nenner= nenner + 
     &               sqrt((spvir(istp,npt) - sk_rand(schritt-1))**2
     &                + (hpvir(istp,npt) - hk_rand(schritt-1))**2) / 
     &                  ve_st(ievir(schritt),ixvir(schritt),ih)
          endif
          
          if(nenner .eq. 0) then
            veipo = 0
          else  
            veipo = laenge / nenner
          endif

      endif    

      if(isnan(vxipo)) then
        vxipo = 0
      endif
      if(isnan(veipo)) then
        veipo = 0
      endif


c       Geschwindigkeit merken? vxipa

c       vxipa=vxipo
c       veipa=veipo

c-----------------------------------------------------------
C--Teilchenstep


c-----Teilchenstep nach Runge Kutta
c     vxipo mitteln mit vxipa ???                                       ! jw
c     r_ret, d_koef mitteln entlang Weg?
         skpact(istp,npt,ih) = skpalt(istp,npt,ih) + 
     &    vxipo/r_ret(istp,iealt(istp,npt,ih),ixalt(istp,npt,ih))*dt
     &    +zxsi*sqrt(6.*d_koef(istp,iboden(iealt(istp,npt,ih),
     &     ixalt(istp,npt,ih),ih)) * dt)
         
         hkpact(istp,npt,ih) = hkpalt(istp,npt,ih) + 
     &    veipo/r_ret(istp,iealt(istp,npt,ih),ixalt(istp,npt,ih))*dt
     &    +zeta*sqrt(6.* d_koef(istp,iboden(iealt(istp,npt,ih),
     &     ixalt(istp,npt,ih),ih)) * dt)


c -------- Bestimmung der Knotennummern --------------
c     Teilchenstep
       schritt = 1
       ievir(schritt) = iealt(istp,npt,ih)
       ixvir(schritt) = ixalt(istp,npt,ih)
       ievir(2:100) = 0
       ixvir(2:100) = 0       
       sk_rand(1:100) = 0.0
       hk_rand(1:100) = 0.0
       bloed = .false. 
       checker = 1                                                     ! testtesttest

c     Zwischenspeicher für Position (wird zur Verfolgung des Teilchens aktualisiert)       
       sk_zwi = skpalt(istp,npt,ih)
       hk_zwi = hkpalt(istp,npt,ih)

c---  Test, ob Teilchen noch in Polygon, oder über welche Seite es gegangen ist       
221   call pinpol(skpact(istp,npt,ih),hkpact(istp,npt,ih), 
     &             sk_zwi, hk_zwi,
     &             ievir(schritt), ixvir(schritt), ih,
     &             sk_rand(schritt), hk_rand(schritt), 
     &             seite)
        
c---Teilchenstep, wenn außerhalb alter Zelle
       if( seite .eq. 0) then                                   ! i 101 
          goto 223
       else                                                     ! e101  
!c  --Prüfung auf Teilchenverlust
c    --- rechts   
        if((ixvir(schritt) .eq. iacnl(ih)) .and. seite .eq. 4) then 
c--------       Nullfluss, Teilchenreflektion
                if (irb_r(ievir(schritt),ih) .eq. 0) then
                   skpact(istp,npt,ih) = sk_zwi
                   hkpact(istp,npt,ih) = hk_zwi
c----------     Sonst Teilchenverlust: Position setzen auf alte Position
                else
                   skpact(istp,npt,ih) = sk_zwi
                   hkpact(istp,npt,ih) = hk_zwi
                   nplosr(istp,ih)=nplosr(istp,ih)+1
                   mlos_r(istp,ih)=mlos_r(istp,ih)+mpact(istp,npt,ih)
                   iplos(istp,npt,ih)=0
                end if
                goto 223
c     --- unten                 
        else if(ievir(schritt) .eq. 1 .and. seite .eq. 1) then
c----------Nullfluss, Teilchenreflektion
                if (irb_u(ixvir(schritt),ih) .eq. 0) then
                   skpact(istp,npt,ih) = sk_zwi
                   hkpact(istp,npt,ih) = hk_zwi
c----------     Sonst Teilchenverlust
                else
                   skpact(istp,npt,ih) = sk_zwi
                   hkpact(istp,npt,ih) = hk_zwi
                   nplosu(istp,ih)=nplosu(istp,ih)+1
                   mlos_u(istp,ih)=mlos_u(istp,ih)
     &                                  +mpact(istp,npt,ih)
                   iplos(istp,npt,ih)=0
                endif
                goto 223                
c     --- links
        else if(ixvir(schritt) .eq. 1 .and. seite .eq. 2) then
c--------       Nullfluss, Teilchenreflektion
                if (irb_l(ievir(schritt),ih) .eq. 0) then
                   skpact(istp,npt,ih) = sk_zwi
                   hkpact(istp,npt,ih) = hk_zwi
c----------     Sonst Teilchenverlust
                else
                   skpact(istp,npt,ih) = sk_zwi
                   hkpact(istp,npt,ih) = hk_zwi
                   nplosl(istp,ih)=nplosl(istp,ih)+1
                   mlos_l(istp,ih)=mlos_l(istp,ih)+mpact(istp,npt,ih)
                   iplos(istp,npt,ih)=0
                end if
                goto 223 
c     --- oben: kein Verlust erlaubt    
        else if(ievir(schritt) .eq. iacnv(ih) .and. seite .eq. 3) then
                   skpact(istp,npt,ih) = sk_zwi
                   hkpact(istp,npt,ih) = hk_zwi
                   goto 223
        endif

c  ----
c     sonst Suche nach Partikel in Nachbarpolygonen (Schritt + 1)
        schritt = schritt + 1
 
        if(schritt .gt. 10) then
        write(*,*) 'Problem in PSTEPB'                                   ! jw testtest   
       endif
            
c       Teilchenstep nach rechts        
        if(seite .eq. 4) then
            ixvir(schritt) = ixvir(schritt-1)+1            
            ievir(schritt) = ievir(schritt-1)

c      Teilchenstep nach unten
        else if(seite .eq. 1) then
            ievir(schritt) = ievir(schritt-1)-1      
            ixvir(schritt) = ixvir(schritt-1)        

c      Teilchenstep nach links
        else if(seite .eq. 2) then
             ixvir(schritt) = ixvir(schritt-1)-1 
             ievir(schritt) = ievir(schritt-1)           

c-------Teilchenstep nach oben
        else if(seite .eq. 3) then
            ievir(schritt) = ievir(schritt-1) + 1
            ixvir(schritt) = ixvir(schritt-1)       
c ----      Abfangen, wenn 'seite' anders
        else 
            schritt = schritt -1
            bloed = .true.  
                 checker = checker + 1
                 if(checker .gt. 123) stop 'Error in PSTEP_B' 

	          write(io(1),315) 
     &       ih,t_act/86400.,npt,istp,ievir(schritt),ixvir(schritt)
  315       format('Info: Undefined side in P_stepb: Hang ',i3
     &            ,', Zeit ',f6.2,' Tage, Partikel ',i8, ' Stoff ', i3,
     &            ' Knoten Reihe ', i5,', Spalte ', i5)
        endif

        if(schritt .gt. 5) then
            if(ievir(schritt) .eq. ievir(schritt-2) .and. 
     &          ixvir(schritt) .eq. ixvir(schritt-2)) then
                write(*,*) 'Problem in PSTEPB'                          ! jw testtesttest
 	          write(io(1),316) 
     &       ih,t_act/86400.,npt,istp,ievir(schritt),ievir(schritt-1),ixvir(schritt),ixvir(schritt-1)
  316           format('Problem in PSTEPB (particle step): Hang ',i3
     &            ,', Zeit ',f6.2,' Tage, Partikel ',i8, ' Stoff ', i3,
     &            ' Knoten Reihen ', 2i5,', Spalten ', 2i5)
                 checker = checker + 1
                 if(checker .gt. 123) stop 'Error in PSTEP_B' 

           endif
        endif

c  Zwischenposition: Randpunkt    
        if(bloed .or. sk_zwi .eq. 0.0 .or. hk_zwi .eq. 0.0) then
           sk_zwi = 0.5*(smu(ievir(schritt), ixvir(schritt), ih) 
     &                + smo(ievir(schritt), ixvir(schritt), ih))
            hk_zwi = 0.5*(hmu(ievir(schritt), ixvir(schritt), ih) 
     &                + hmo(ievir(schritt), ixvir(schritt), ih))
            bloed = .false.
        else
c  Zwischenposition: Schnittpunkt zwischen Mittelpunkten unterer/oberer Rand - liegt in Polygon (nicht immer, wenn auch linker/rechter Rand mitgenommen wird!)           
        sk_zwi = sk_rand(schritt-1)
        hk_zwi = hk_rand(schritt-1)
        endif


       goto 221
       endif                                                    !ei 101

223   continue

c       aktualisiere Teilchenpositionen (Knotennummern)   
        ieact(istp,npt,ih) = ievir(schritt)
        ixact(istp,npt,ih) = ixvir(schritt)

c       aktualisiere alte Teilchen position
         iealt(istp,npt,ih)=ieact(istp,npt,ih)
         ixalt(istp,npt,ih)=ixact(istp,npt,ih)
         skpalt(istp,npt,ih)=skpact(istp,npt,ih)
         hkpalt(istp,npt,ih)=hkpact(istp,npt,ih)

      end if    !if block 1, teilchenschritt/ teilchen in Domaene -  ei1
65    continue ! ende schleife Teilchenzahl

!       if (nplosu(istp,ih) .gt. 0) write(6,*) 'mlos_u=',mlos_u(istp,ih) 
!       if (nplosr(istp,ih) .gt. 0) write(6,*) 'mlos_r=',mlos_r(istp,ih) 
!       if (nplosl(istp,ih) .gt. 0) write(6,*) 'mlos_l=',mlos_l(istp,ih) 
     
	return
      end

c--------
c	jw 12.12.07		Auskommentierte Teile (alter Elementschritt) rausgenommen
c
c     jw 10.05.12       Änderung der Zuordnung zu Gridzellen: Abfrage, ob Teilchen im Knoten (pinpol)
c     jw 05.06.12           Teilchenverfolgung über Randsegmente

