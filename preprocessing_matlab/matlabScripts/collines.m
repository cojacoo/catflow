function collines(h,c)
%  collines(h,c)
%    setzt die Farbe der Objekte mit den HANDLES h auf c
for jj = 1:length(h),
  set(h(jj), 'Color', [c],'linewidth', [0.01]);
end;
