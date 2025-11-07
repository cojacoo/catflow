function xb = xb(eta)
global max_xb min_xb htyp ih
if (htyp(ih)==1),
xb = eta*(max_xb-min_xb)+min_xb;
elseif (htyp(ih)==2),
xb = max_xb*ones(size(eta));
end
