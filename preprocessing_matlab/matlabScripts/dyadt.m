function ya = dyadt(tau)
global ppya1 htyp ih
if (htyp(ih)==1),
[m,n] = size(tau);
ya = reshape(fnval(ppya1,xa(tau)),m,n).*dxadt(tau);
elseif(htyp(ih)==2),
ya = zeros(size(tau));
end
