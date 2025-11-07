function yd = yd(eta)
global ppyd htyp ih pyd
if (htyp(ih)==1),
[m,n] = size(eta);
yd = reshape(fnval(ppyd,xd(eta)),m,n);
elseif (htyp(ih)==2),
yd = eta*(max(pyd)-min(pyd))+min(pyd);
end

