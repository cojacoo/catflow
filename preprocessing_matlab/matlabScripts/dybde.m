function yb = dybde(eta)
global ppyb1 ih htyp
 
if (htyp(ih)==1),
  [m,n] = size(eta);
  yb = reshape(fnval(ppyb1,xb(eta)),m,n).*dxbde(eta);
elseif (htyp(ih)==2),
  yb = ones(size(eta));
end
