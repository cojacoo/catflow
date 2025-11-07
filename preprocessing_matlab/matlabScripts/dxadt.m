function xa = dxadt(tau)
% linke untere Ecke A
global min_xa max_xa ih htyp
if (htyp(ih)==1),
xa = ones(size(tau))*(max_xa-min_xa);
elseif (htyp(ih)==2),
xa=ones(size(tau));
end
