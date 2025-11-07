function [x,y] = getreho(xp,yp,sp,s)
% [x,y] = getreho(xp,yp,s,s0)
%
%  Gegeben:  xp yp gerichteter Polygonzug
%            s  natuerliche Wegkoordinate
%            sp natuerliche Wegkoordinate an den Punkten
%               d,h.  xp(1),yp(1) ==  sp(1)
%
%  Gesucht:  x,y and den Stellen s

s(1) = s(1)+10000*eps;
s(length(s)) = s(length(s))-10000*eps;
x = interp1(sp,xp,s);
y = interp1(sp,yp,s);
