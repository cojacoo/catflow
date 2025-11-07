function xb = dxbde(eta)
global min_xb max_xb htyp ih
if (htyp(ih)==1),
xb = ones(size(eta))*(max_xb-min_xb);
elseif (htyp(ih)==2),
xb= zeros(size(eta));
end
