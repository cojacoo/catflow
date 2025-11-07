function yb = dyb2de2(eta)
global ppyb2
[m,n] = size(eta);
yb = reshape(fnval(ppyb2,xb(eta)),m,n).*dxbde(eta);
