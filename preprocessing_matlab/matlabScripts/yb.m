function yb = yb(eta)
global ppyb htyp ih pyb
if (htyp(ih)==1),
[m,n] = size(eta);
yb = reshape(fnval(ppyb,xb(eta)),m,n);
elseif (htyp(ih)==2),
yb = eta*(max(pyb)-min(pyb))+min(pyb);
end
