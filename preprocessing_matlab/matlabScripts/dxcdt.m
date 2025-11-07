function xc = dxcdt(tau)
global min_xc max_xc
xc = ones(size(tau))*(max_xc-min_xc);
