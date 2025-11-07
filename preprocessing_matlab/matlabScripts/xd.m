function xd = xd(eta)
global max_xd min_xd htyp ih
if (htyp(ih)==1),
xd = eta*(max_xd-min_xd)+min_xd;
elseif (htyp(ih)==2),
xd = min_xd*ones(size(eta));
end
