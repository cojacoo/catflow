function yc = yc(tau)
global ppyc
[m,n] = size(tau);
yc = reshape(fnval(ppyc,xc(tau)),m,n);
