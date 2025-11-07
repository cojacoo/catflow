%Version 0.8 vom 18.12.2006
% plots state variables and fluxes from catflow
clear all; close all

path(path,'D:\uniP-backup\CATFLOW\modell_test');
path(path,'D:\uniP-backup\CATFLOW\modell_test\outm');

statefile='relsat_m.out'; %soilmoisture file
hkfile='hko_m.out';  %z coordinate file
skfile='sko_m.out'; %z coordinate file
f_etafile='fl_eta_m.out'; %fluxes in vertical direction 
f_xsifile='fl_xsi_m.out'; %fluxes in lateral direction
anglefile='angles.dat'; % angles between horizontal coordinate and lateral hillslope coordinate (pos. count clock)

% hillslopes to be plotted
nhang=-1001;
numh = length(nhang);

fid=fopen(statefile,'r');
t=fscanf(fid,'%f');
numts=length(find(t(:)==-1001));    % calculate number of time steps
fclose(fid);

fid=fopen(statefile,'r');
fid2=fopen(skfile,'r');
fid3=fopen(hkfile,'r');
fid4=fopen(f_etafile,'r');
fid5=fopen(f_xsifile,'r');
angle=load(anglefile);

i=1; it=0;

while it==0
   stime=fscanf(fid,'%s5') ;
   stime=fscanf(fid4,'%s5'); 
   stime=fscanf(fid5,'%s5'); 

   nhs=fscanf(fid,'%s5'); 
   nhs=fscanf(fid2,'%s5'); 
   nhs=fscanf(fid3,'%s5'); 
   nhs=fscanf(fid4,'%s5'); 
   nhs=fscanf(fid5,'%s5'); 
   nh=sscanf(nhs, '%f');

   etas=fscanf(fid,'%s5');
   xsis=fscanf(fid,'%s5');
   eta=sscanf(etas, '%f');
   xsi=sscanf(xsis, '%f');
   mat=fscanf(fid,'%f',[xsi,eta]);
   etas=fscanf(fid4,'%s5');
   xsis=fscanf(fid4,'%s5');
   etas=fscanf(fid5,'%s5');
   xsis=fscanf(fid5,'%s5');
   seta = fscanf(fid2,'%s4');
   eta = sscanf(seta,'%f');
   sxsi = fscanf(fid2,'%s4');
   xsi = sscanf(sxsi,'%f');
   seta = fscanf(fid3,'%s4');
   eta = sscanf(seta,'%f');
   sxsi = fscanf(fid3,'%s4');
   xsi = sscanf(sxsi,'%f');
   f_e=fscanf(fid4,'%f',[xsi,eta]);
   f_x=fscanf(fid5,'%f',[xsi,eta]);
  
   sk=fscanf(fid2,'%f',[xsi,eta]);
   hk=fscanf(fid3,'%f',[xsi,eta]);

   if nh == nhang
      hko=hk';
      sko=sk';
      fclose(fid2);
      fclose(fid3);
      it=1;
   end 
end

mov = avifile('example.avi');
mov.fps = 0.5;
mov.quality = 100;

for j=2:numh*numts
        
        stime = fscanf(fid,'%s4');
        time=sscanf(stime,'%f');
        stime = fscanf(fid4,'%s4');
        stime = fscanf(fid5,'%s4');
        shang = fscanf(fid,'%s4');
        hang = sscanf(shang,'%f');
        shang = fscanf(fid4,'%s4');
        shang = fscanf(fid5,'%s4');
        seta = fscanf(fid,'%s4');
        eta = sscanf(seta,'%f');
        sxsi = fscanf(fid,'%s4');
        xsi = sscanf(sxsi,'%f');
        mat=fscanf(fid,'%f',[xsi,eta]);
        mat2=mat';
        etas=fscanf(fid4,'%s5');
        xsis=fscanf(fid4,'%s5');
        etas=fscanf(fid5,'%s5');
        xsis=fscanf(fid5,'%s5');
        f_etat=fscanf(fid4,'%f',[xsi,eta]);
        f_xsit=fscanf(fid5,'%f',[xsi,eta]);
         
        if hang == nhang
         
        
            % rotate fluxes to cartesian coordinates
         
          f_eta=f_etat';
          f_xsi=f_xsit';
          f_x= f_xsi.*cos(angle)+f_eta.*sin(angle);
          f_z= -f_xsi.*sin(angle)+f_eta.*cos(angle);
  
%         ttime1(i)=time;
%         mat3(:,:,i)=mat2;


%bild=figure;
hold all;
axis tight

        subplot(2,1,1);
        set(gca,'nextplot','replacechildren');
          pcolor(sko,hko,mat2);
          title(time);
          colormap(cool);
          caxis([0.5 0.7]);
          shading('interp');
          xlabel('x [m]');
          ylabel('z [m]');
          colorbar;
          
          %mat3(:,:,i)=mat2;
 
          subplot(2,1,2);
          set(gca,'nextplot','replacechildren');
          quiver(sko(1:20,:),hko(1:20,:),f_x(1:20,:),f_z(1:20,:));
          xlabel('x [m]');
          ylabel('z [m]');
          axis([40 50 15 30]);
       
           m(i)= getframe(gcf);
            
           mov = addframe(mov,m);

           i=i+1;
       end
end
mov = close(mov);
fclose all;
% movie(m); 
  

