load trans
load koor
file = ['hang', num2str(ih) '.geo'];
fid=fopen(file,'w');
[nx,ne]=size(g_xsi);
w_fix=0;
newl = '\r\n';  % PC
newl = '\n';    % WS
fprintf(fid,['%6i %6i %7.4f %5i  (%3i Punkte)'  newl],ne, nx, w_fix, ih, mm_org);
fprintf(fid,['%12.2f %12.2f %8.2f'  newl],re_bez, ho_bez, z_bez);
fprintf(fid,['%12.2f %10.4f %10.4f'  newl],flaech(ih), breite, laenge);
fprintf(fid,['%10.8f' newl],eta');
zz1=[xsi';re';ho';varbr'];
%zz1=[xsi';re;ho;varbr];
fprintf(fid,['%10.8f %12.4f %12.4f %12.4f' newl],zz1);
yy = y;
xx = x;
fe = sqrt(g_eta);
fx = sqrt(g_xsi);
% ws = Winkel von xsi nach x, positiv im Gegenuhrzeigersinn
ws = -atan2(dy_dxsi,dx_dxsi);
% wh = Winkel der Hauptachse der Anisotropie, positiv im Gegenuhrzeigersinn
wh = zeros(size(ws));
yy = yy';
xx = xx';
fe = fe';
fx = fx';
ws = ws';
wh = wh';
zz = [yy(:)';xx(:)';fe(:)';fx(:)';ws(:)';wh(:)';ones(1,ne*nx)];
fprintf(fid,['%10.4f %10.4f %14.8f %14.8f %12.8f %8.4f %3i' newl],zz);

fclose(fid);
