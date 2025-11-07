% NAT2KOOR
% 
global max_xa min_xa
global max_xc min_xc
global max_xb min_xb
global max_xd min_xd
global ppya ppyc ppyd ppyb
global ppya1 ppyc1 ppyd1 ppyb1
global ppyd2 ppyb2
global lam_ab lam_bc lam_cd lam_da
global f_xsi_1 f_xsi_n f_eta_1 f_eta_m
global htyp ih
min_xa = min(pxa);
max_xa = max(pxa);
min_xc = min(pxc);
max_xc = max(pxc);
%min_xb = min(pxb);
%max_xb = max(pxb);
%min_xd = min(pxd);
%max_xd = max(pxd);
min_xb = max_xa;
max_xb = max_xc;
min_xd = min_xa;
max_xd = min_xc;

% Fallunterscheidungen nach Hangtyp
if (htyp(ih)==1),
%-----------------------------------------------------------------------
%  Polynomdarstellung fuer die Raender
%-----------------------------------------------------------------------
grad_b = gradient(pyb,pxb);
grad_d = gradient(pyd,pxd);
grad_ba = grad_b(1);
grad_da = grad_d(1);
grad_be = grad_b(length(grad_b));
grad_de = grad_d(length(grad_d));

%----------------------------------------------------------------------------------------
% splines der Ränder A,C,B,D (vgl. zB Press et al. 92, Numerical Recipes FORTRAN S.107ff)
%----------------------------------------------------------------------------------------
%CSAPE	Cubic spline interpolation with various end-conditions.
%
%        pp = csape(x,y[,conds[,valconds]])
%
% returns the cubic spline interpolant (in pp-form) to the given data  (x,y)
% using the specified end-conditions  conds(i)  with  values  valconds(i) ,
% with i=1 (i=2) referring to the left (right) endpoint. 
%   conds(i)=j  means that the j-th derivative is being specified to be
%   valconds(i) , j=1,2. 
%   conds(1)=0=conds(2)  means periodic end conditions.
%  If conds(i) is not specified or is different from 0, 1 or 2, then the 
%  default value for  conds(i)  is  1  and the default value of valconds(i) 
%  is taken.
%  If  valconds  is not specified, then the default value for valconds(i) is
%       deriv. of cubic interpolant to nearest four points, if  conds(i)=1;
%       0                                                   if  conds(i)=2.
%----------------------------------------------------------------------------------------
ppya =  csape(pxa, pya, [1 1], [-1/grad_da -1/grad_ba]);
ppyc =  csape(pxc, pyc, [1 1], [-1/grad_de -1/grad_be]);
ppyb =  csape(pxb, pyb, [1 1], [grad_ba grad_be]);
ppyd =  csape(pxd, pyd, [1 1], [grad_da grad_de]);
%                        | |       |       |
%                        | |       |    Wert der Bedingung für das rechte Ende (hier: Gradient des Randes D)
%                        | |    Wert der Bedingung für das linke Ende (hier: Gradient des Randes D)   
%                        | Randbedigung am rechten Ende: n-te Ableitung an der Stelle (hier 1. Ableitung)
%                        Randbedigung am linken Ende: n-te Ableitung an der Stelle (hier 1. Ableitung)  
%

elseif (htyp(ih)==2),

ppya = mkpp([pxa(1) pxa(length(pxa))],[0 pya(1)]);
ppyc = csape(pxc, pyc, [1 1], [0 0]);
ppyb = mkpp(pyb,[0 pxb(1)]);
ppyd = mkpp(pyd,[0 pxd(1)]);

end

% Ableitungen der o.g. Randkurven

ppya1 = fnder(ppya);
ppyc1 = fnder(ppyc);
ppyb1 = fnder(ppyb);
ppyd1 = fnder(ppyd);
ppyb2 = fnder(ppyb1);
ppyd2 = fnder(ppyd1);

%-----------------------------------------------------------------------
% Fallunterscheidungen, siehe Kiefer S.33  
%-----------------------------------------------------------------------
if abs(dybde(eta_1))>=abs(dxbde(eta_1)),
  lam_ab =  dxadt(xsi_n)/dybde(eta_1);
else
  lam_ab = -dyadt(xsi_n)/dxbde(eta_1);
end

if abs(dybde(eta_m))>=abs(dxbde(eta_m)),
  lam_bc =  dxcdt(xsi_n)/dybde(eta_m);
else
  lam_bc = -dycdt(xsi_n)/dxbde(eta_m);
end

if abs(dydde(eta_m))>=abs(dxdde(eta_m)),
  lam_cd =  dxcdt(xsi_1)/dydde(eta_m);
else
  lam_cd = -dycdt(xsi_1)/dxdde(eta_m);
end

if abs(dydde(eta_1))>=abs(dxdde(eta_1)),
  lam_da =  dxadt(xsi_1)/dydde(eta_1);
else
  lam_da = -dyadt(xsi_1)/dxdde(eta_1);
end

%-----------------------------------------------------------------------
% Festlegung der Koordinate TAU
%-----------------------------------------------------------------------
tau_anz = 51;
tau = [xsi_1:(xsi_n - xsi_1)/(tau_anz - 1):xsi_n]';

% Vorfaktoren zur Berechnung von hd und hd und hdb
f_xsi_n = (xsi_n - tau)./(xsi_n - xsi_1);
f_xsi_1 = (tau - xsi_1)./(xsi_n - xsi_1);
f_eta_m = (eta_m- eta )./(eta_m - eta_1);
f_eta_1 = (eta - eta_1)./(eta_m - eta_1);

%-----------------------------------------------------------------------
%  Berechnen der lateralen Kurvenschar
%-----------------------------------------------------------------------
[x_db, y_db, dx_db_dt, dx_db_de, dy_db_dt, dy_db_de] = koor_dbm(eta,tau);

%-----------------------------------------------------------------------
%  Plot der lateralen Kurvenschar
%-----------------------------------------------------------------------
%auch ausgelagert in zusatznat2koor.txt
plot(x_db,y_db,'y ');
orient landscape;
hh=line(x_db,y_db);
collines(hh,[1 1 0]);
xeck =[xa(tau') xa(tau') xc(tau') xc(tau') xb(eta) xb(eta) xd(eta) xd(eta)];
yeck =[ya(tau') ya(tau') yc(tau') yc(tau') yb(eta) yb(eta) yd(eta) yd(eta)];
max_x = max(xeck);
min_x = min(xeck);
max_y = max(yeck);
min_y = min(yeck);
dx = max_x - min_x;
dy = max_y - min_y;
xfak = 0.05;
xfak = 0.50;
yfak = xfak;
max_x = max_x+xfak*dx;
min_x = min_x-xfak*dx;
max_y = max_y+yfak*dy;
min_y = min_y-yfak*dy;
dx = max_x - min_x;
dy = (max_y - min_y) *10 ;
axis([min_x max_x min_y max_y]);
axes_ratio =  dx/(hfak*dy);
data_ratio =  1/hfak;
if dy > dx,
  hoch = 0.9;
  breit = 0.9*axes_ratio + 0.05;
else
  breit = 0.9;
  hoch = 0.9/axes_ratio + 0.05;
end
set(gca,...
             'position',[(1-breit)/2,(1-hoch)/2,breit,hoch],...
             'AspectRatio',[axes_ratio, data_ratio]...
            );
hold on
drawnow

%-----------------------------------------------------------------------
%  Berechnen der vertikalen Kurvenschar
%-----------------------------------------------------------------------
rho = xsi';
rho_s = xsi;
for i = 1:eta_anz-1,
  disp(sprintf('Berechne eta(i)=%6.3f bis eta(i+1)=%6.3f', eta(i),eta(i+1)));
  etah = [];
  rhoh = [];
% Aufruf des Runge-kutta-Verfahrens (ode23) 
  [etah, rhoh] = ode23('drhodeta',[eta(i),eta(i+1)],rho_s);
%  [etah, rhoh] = ode45('drhodeta',eta(i),eta(i+1),rho_s);
  callen = length(etah);
  rho_s = rhoh(callen,:)';
  rho = [rho; rhoh(callen,:)];
end
rho = rho';
%-----------------------------------------------------------------------
%  Berechnung der metrischen Koeffizienten und der Koordinatenneigung
%-----------------------------------------------------------------------
x = zeros(size(rho));
y = zeros(size(rho));
g_eta = zeros(size(rho));
g_xsi = zeros(size(rho));
dx_dxsi = zeros(size(rho));
dy_dxsi = zeros(size(rho));
[g_eta, drhodxsi] = gradient(rho,eta,xsi);
for i = 1:length(eta),
  [x(:,i), y(:,i), dx_db_dt, dx_db_de, dy_db_dt, dy_db_de] = koor_dbs(eta(i),rho(:,i));
  g_eta(:,i) = ((dx_db_dt.*dy_db_de - dx_db_de.*dy_db_dt).^2)./...
                (dx_db_dt.^2 + dy_db_dt.^2);
  g_xsi(:,i) = (dx_db_dt.^2 + dy_db_dt.^2).*(drhodxsi(:,i).^2);
% [dx_dxsi dy_dxsi] ist der Tangentialvektor fuer eta=const!!
  dx_dxsi(:,i) = dx_db_dt;
  dy_dxsi(:,i) = dy_db_dt;
end

[re,ho] = getreho(rec,hoc,pxc,x(:,length(eta))');
re=re';
ho=ho';
pxc(1)=pxc(1)-0.001;
pxc(length(pxc))=pxc(length(pxc))+0.001;
varbr = interp1(pxc,br,x(:,length(eta))');
varbr=varbr';
%-----------------------------------------------------------------------
%  Speichern der berechneten Daten
%-----------------------------------------------------------------------
save trans rho eta xsi
save koor x y g_eta g_xsi dx_dxsi dy_dxsi re ho varbr re_bez ho_bez z_bez flaech breite laenge

%-----------------------------------------------------------------------
%  Plot der vertikalen Kurvenschar
%-----------------------------------------------------------------------
hh=line(x',y');
collines(hh,[0 1 1]);
hold on
drawnow

%-----------------------------------------------------------------------
%  Plot der metrischen Koeffizienten ins Gitter
%-----------------------------------------------------------------------
%[n,m]=size(rho);
%for j = 1:1:m,
%  txtnum1 = zeros(n,5);
%  txtnum2 = zeros(n,5);
%  for i=1:1:n, txtnum1(i,:) = sprintf('%5.2f',g_eta(i,j)); end;
%  for i=1:1:n, txtnum2(i,:) = sprintf('%5.2f',g_xsi(i,j)); end;
%  th1 = text(x(:,j),y(:,j),txtnum1);
%  th2 = text(x(:,j),y(:,j),txtnum2);
%  set(th1,...
%    'HorizontalAlignment','left','VerticalAlignment','bottom','FontSize',8)
%  set(th2,...
%    'HorizontalAlignment','left','VerticalAlignment','top','FontSize',8)
%  hold on
%end
