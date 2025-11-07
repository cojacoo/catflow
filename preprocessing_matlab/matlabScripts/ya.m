function ya = ya(tau)
global ppya pyd htyp ih
if (htyp(ih)==1),
[m,n] = size(tau);
ya = reshape(fnval(ppya,xa(tau)),m,n);
elseif (htyp(ih)==2),
ya = min(pyd)*ones(size(tau));
end
