function xd = dxdde(eta)
global min_xd max_xd htyp ih
if (htyp(ih)==1),
xd = ones(size(eta))*(max_xd-min_xd);
elseif (htyp(ih)==2),
xd = zeros(size(eta));
end
