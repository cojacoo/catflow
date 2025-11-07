function yd = dydde(eta)
global ppyd1 ih htyp
if (htyp(ih)==1),
[m,n] = size(eta);
yd = reshape(fnval(ppyd1,xd(eta)),m,n).*dxdde(eta);
elseif (htyp(ih)==2),
yd=ones(size(eta));
end
