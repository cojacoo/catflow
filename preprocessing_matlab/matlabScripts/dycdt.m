function yc = dycdt(tau)
global ppyc1
[m,n] = size(tau);
yc = reshape(fnval(ppyc1,xc(tau)),m,n).*dxcdt(tau);
