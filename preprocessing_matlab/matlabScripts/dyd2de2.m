function yd = dyd2de2(eta)
global ppyd2
[m,n] = size(eta);
yd = reshape(fnval(ppyd2,xd(eta)),m,n).*dxdde(eta);
