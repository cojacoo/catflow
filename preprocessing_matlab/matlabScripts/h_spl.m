%-----------------------------------------------------------------------
%  Erzeugen eines rechtwinkligen Koordinatennetzes
%  auf Basis von Koordinatenvorgaben am Rand C und
%  einer Schichtdicke dyy
%-----------------------------------------------------------------------
%
%      e ^                                 Vorgabe von M-FILES:
%      t |
%      a      C                            XA(tau) XA'(tau)
%         ---------                        YA(tau) YA'(tau)
%        |         |                       XC(tau) XC'(tau)
%       D|         |B                      YC(tau) YC'(tau)
%        |         |                       XB(eta) XB'(eta) XB''(eta)
%   y ^   ---------   --> xsi, tau         YB(eta) YB'(eta) YB''(eta)
%     |       A                            XD(eta) XD'(eta) XD''(eta)
%      -->                                 YD(eta) YD'(eta) YD''(eta)
%       x
%
% Seite A und D bestimmen die Koordinaten
%-----------------------------------------------------------------------
% generelle Angaben, passend zu den vorgegebenen Funktionen!

clear
% Festlegung der Randwerte der natürlichen Koordinaten
global xsi_1 xsi_n eta_1 eta_m
global htyp ih pya pyb pyc pyd pxa pxb pxc pxd
dyyy = 1;
eta_1 = 0;
eta_m = 1;
xsi_1 = 0;
xsi_n = 1;

%-----------------------------------------------------------------------
%  Produziere:  oberer  Rand (C) pxc, pyc, rec, hoc
%               unterer Rand (A) pxa, pya
%                                eta, xsi
%-----------------------------------------------------------------------
%load hang2_xyz
fromArcGIS
%liest: htyp xh yh zh ho_bez re_bez z_bez numh flaech punkteh bh dyyy
%         |   |  |  |  |       |      |     |      |     |     |   |
%         |   |  |  |  |       |      |     |      |     |     |   Schichtdicken
%         |   |  |  |  |       |      |     |      |     |     Skalierungsfaktor 
%         |   |  |  |  |       |      |     |      |     Anzahl der Punkte in der Fallinie
%         |   |  |  |  |       |      |     |      Flaeche der Hänge
%         |   |  |  |  |       |      |     Nummern der Hänge 
%         |   |  |  |  |       |      Bezugsgröße der Z-Koordinate
%         |   |  |  |  |       Bezugsgröße der Rechtswerte
%         |   |  |  |  Bezugsgröße der Hochwerte
%         |   |  |  z-Werte der Fallinie
%         |   |  y-Werte der Fallinie
%         |   x-Werte der Fallinie
%         Hangtyp

% Anzahl der Hänge
hganz = length(numh);

%-----------------------------------------------------------------------
%  Schleife ueber alle Haenge:
%-----------------------------------------------------------------------
acthng=[1:1:length(numh)];
%acthng=1
for iact=1:length(acthng),
figure
  ih=acthng(iact);

% bearbeiten des ih. Hangs

% Zuweisen der Laufvariablen 
  disp(sprintf('Hang %5i',ih))
  br  = bh(1:punkteh(ih),ih)';
  rec = xh(1:punkteh(ih),ih)';
  hoc = yh(1:punkteh(ih),ih)';
  pyc = zh(1:punkteh(ih),ih)';
  mm = length(pyc);
  mm_org = mm;

%  Skalierungsfaktor (zur Darstellung)
hfak = 1;

% Berechnung der tatsächlichen Abstände dx zwischen 2 Punkten der Fallinie
% {Matlab: DIFF(X), for a vector X, is [X(2)-X(1)  X(3)-X(2) ... X(n)-X(n-1)]}
  dre = diff(rec);
  dho = diff(hoc);
  dx = sqrt(dre.^2+dho.^2);

% Festlegung der Schichtdicke dyy
  dyy = dyyy(ih);

%  gr: Steigung am Anfang; gre: Steigung am Ende
%  und testen der Tangentensteigung
gr = (pyc(1)-pyc(2))/dx(1);
gre= (pyc(length(pyc))-pyc(length(pyc)-1))/dx(length(dx));
if ((gr==0 | gre==0) & htyp(ih)==1),
  disp('Tangente horizontal, aber Hangtyp auf 1 gesetzt (siehe mktest.m).')
  break
elseif ((~(gr==0) | ~(gre==0)) & htyp(ih)==2),
  disp('Tangente nicht horizontal, aber Hangtyp auf 2 gesetzt (siehe mktest.m).')
  break
end

% Bei nicht horizontalen Tangenten (Hangtyp 1)
if (htyp(ih)==1),

% Extrapolation eines Hilfspunktes
%  y-Koordinate der C-Linie (oberer Rand) + neuem Punkt
pyc = [pyc(1)+gr*dx(1)/10 pyc];
mm = mm+1;

%  x-Koordinate der A-Linie (unterer Rand)
pxa = [0 dx(1)/10 dx(1)/10+cumsum(dx)];

br  = [br(1) br];
rec = [rec(1)-dre(1)/10 rec];
hoc = [hoc(1)-dho(1)/10 hoc];

%-------------------------------------------------------------------------------
% Festlegung des oberen und unteren Randes (x-Koordinaten)
% Verschiebung des oberen Randes entlang der Tangentensenkrechte des Randpunktes
dxx = -(pyc(2)-pyc(1))/(pxa(2)-pxa(1))*dyy;
pya = pyc-dyy;
if (dxx > 0),
  pxc = pxa+dxx;
else
  pxc = pxa;
  pxa = pxc-dxx;
end

elseif (htyp(ih)==2),
  pya = min(pyc)*ones(size(pyc))-dyy;
  pxc = [0 cumsum(dx)];
  pxa = pxc;

end

% Ermittlung der Laenge und Breite des Hanges
laenge=pxc(length(pxc))-pxc(1);
breite=flaech(ih)/laenge;

%-----------------------------------------------------------------------
% Laden der eta und xsi Werte
%eta = [0 0.1 0.3 0.6 0.8 0.9 0.95 1.0];
%load eta_xsi
eta_anz = length(eta);
xsi_anz = length(xsi);
%-----------------------------------------------------------------------

% Koordinaten des linken Randes D
pxd = [pxa(1) pxc(1)];
pyd = [pya(1) pyc(1)];

% Koordinaten des rechten Randes B
pxb = [pxa(mm) pxc(mm)];
pyb = [pya(mm) pyc(mm)];

%-----------------------------------------------------------------------
%  Berechnung der Koordinaten
%-----------------------------------------------------------------------
nat2koor;

%-----------------------------------------------------------------------
%  Formatwandlung fuer CATFLOW
%-----------------------------------------------------------------------
wandeln;

end;
