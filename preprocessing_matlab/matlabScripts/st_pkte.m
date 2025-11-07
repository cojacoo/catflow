function [xs, ys]=st_pkte(xo, yo, xu, yu);
% [xs, ys]=st_pkte(xo, yo, xu, yu)
%
%  xo,yo:  Punkte des oberen  Endes von Teilstrecken ohne Verzweigungen
%  xu,yu:  Punkte des unteren Endes von Teilstrecken ohne Verzweigungen
%  xs,ys:  Startpunkte (channelhead) eines dentritischen Gewaessernetzes
%
global myeps
[n]=length(xo);

j=0;
for i=1:n,
  is=find( (abs(xo(i)-xu)<myeps) & (abs(yo(i)-yu)<myeps) );
  if isempty(is),
    j=j+1;
    ipos(j) = i;
  end;
end;
xs=xo(ipos(1:j));
ys=yo(ipos(1:j));
