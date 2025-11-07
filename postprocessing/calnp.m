function [npt, eta, xsi]= calnp(file)
% calculates printout times and number of nodes (vertical/horizontal)
% Usage: calnp('xxx.out')
fid=fopen(file,'r');
t=fscanf(fid,'%f');
h2=find(t(:)==-1001);
npt=length(h2);
eta = t(3);
xsi = t(4);
vec=['Zahl der Printzeitpunkte ', num2str(npt)];
disp(vec)
fclose(fid);

