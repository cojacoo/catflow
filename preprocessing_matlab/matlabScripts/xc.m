function xc = xc(tau)
global max_xc min_xc
xc = tau*(max_xc-min_xc)+min_xc;
