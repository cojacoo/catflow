function xa = xa(tau)
global min_xa max_xa ih htyp
if (htyp(ih)==1),
xa = tau*(max_xa-min_xa)+min_xa;
elseif (htyp(ih)==2),
xa=tau;
end