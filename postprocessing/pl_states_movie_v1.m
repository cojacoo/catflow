%Version 1.2 vom 30.01.2006
% plots state variables and fluxes from catflow
% for a single hillslope
clear all;
clc;
close all
tic

% 3d matrizen berechnen und abspeichern für späteres selektives plotten

path(path,'F:\CATF\Quel_j1');

statefile='relsat.out'; %soilmoisture file
hkfile='hko.out';  %z coordinate file
skfile='sko.out'; %z coordinate file
f_etafile='fl_eta.out'; %fluxes in vertical direction 
f_xsifile='fl_xsi.out'; %fluxes in lateral direction
anglefile='angles.dat'; % angles between horizontal coordinate and lateral hillslope coordinate (pos. count clock)

 % calculate number of time steps and number of nodes(eta,xsi)
[numts, eta, xsi]=calnp(statefile);

%open model output
fid=fopen(statefile,'r');
fid2=fopen(skfile,'r');
fid3=fopen(hkfile,'r');
fid4=fopen(f_etafile,'r');
fid5=fopen(f_xsifile,'r');
angle=load(anglefile);

% get node coordinates
    fgets(fid2);
    fgets(fid3);
    sk=fscanf(fid2,'%f',[xsi,eta]);
    hk=fscanf(fid3,'%f',[xsi,eta]);
    hko=hk';
    sko=sk';
    fclose(fid2);
    fclose(fid3);

%  loop over timesteps
for j=1:numts
    sline = fgets(fid); %read first line
    nline=sscanf(sline,'%f');
    
    time = nline(1,:); 
    ttime1(j)=time;
        
    mat=fscanf(fid,'%f',[xsi,eta]); %read state variable into matrix
    mat2=mat';
    mat3(:,:,j)=mat2;   %store hillslope state in 3d-array
    
    fgets(fid4);
    fgets(fid5);
 
    f_etat=fscanf(fid4,'%f',[xsi,eta]);
    f_xsit=fscanf(fid5,'%f',[xsi,eta]);
        
    % rotate fluxes to cartesian coordinates
      f_eta=f_etat';
      f_xsi=f_xsit';
      f_x= f_xsi.*cos(angle)+f_eta.*sin(angle);
      f_z= -f_xsi.*sin(angle)+f_eta.*cos(angle);
      
      flux_x(:,:,j)=f_x;    %store hillslope flux states in 3d-array
      flux_z(:,:,j)=f_z;

                fgets(fid); %move to next entry
                fgets(fid4);
                fgets(fid5);

          subplot(2,1,1);
          pcolor(sko,hko,mat2);
          title(['timestep ',num2str(time/3600),' h']);
          colormap(cool);
          caxis([0.5 0.7]);
          shading('interp');
          xlabel('x [m]');
          ylabel('z [m]');
          colorbar;
          
          subplot(2,1,2);

          quiver(sko,hko,f_x,f_z);
          xlabel('x [m]');
          ylabel('z [m]');
          axis([0 90 1120 1180]);
       
           m(j)= getframe(gcf);
end

fclose all;
rechenzeit=toc
% figure;
% movie(m); 
  

