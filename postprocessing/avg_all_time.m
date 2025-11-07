%Version 1.0 vom 30.01.07
%zum Matrix einlesen, Mittelwerte erstellen von cATFLOW-output
% J.Wienhöfer, Uni Potsdam

%path(path,'f:');
close all; 

%Größe des gesuchten Feldes falls nicht alles gewünscht
%eta-Richtung nia=5; nie=8 ;     
%Xsi-Richtung nja=3; nje=5;

%Gesuchter Hang
nhang=-1001;

var={'relsat';'senken';'fl_xsi';'fl_eta'}    ;% 'theta';'evapo''psi'; 'relsat';'senken';'fl_xsi';'fl_eta'
ext='.out';

for v=1:length(var)
vac=char(var(v));
infile=[vac,ext];
    if v==1
    numts = calnp(infile); %calculate number of time steps
    end
    %File oeffnen
    fid=fopen(infile,'r');
    %Zahl der Hänge in File
    numh = length(nhang);
    %Zähler 
    i=1;
    
  for j=1:numh*numts
       %Daten aus erster Zeile
        stime = fscanf(fid,'%s4');
        time=sscanf(stime,'%f');
        shang = fscanf(fid,'%s4');
        thang = sscanf(shang,'%f');
   %     hang = -(thang)-1000;
        seta = fscanf(fid,'%s4');
        eta = sscanf(seta,'%f');
        sxsi = fscanf(fid,'%s4');
        xsi = sscanf(sxsi,'%f');
   
        %Matrix des Knotenzustandes
        mat=fscanf(fid, '%f' ,[xsi eta]);
        mat2=mat';
           if thang == nhang
              ttime1(i)=time;
              mat3(:,:,i)=mat2;
              i=i+1;
           end
   end
  
    for k=1:numts
        vec1(k)=max(mean(mat3(1:eta,1:xsi,k))); %create vector of mean values for all nodes
%                                                   or use nia,nie,nja,nje
%                                                   (see above): mat3(nia:nie,nja:nje,k)
    end

  %Zeitreihe plotten
 
  ttime1 = ttime1/3600;
  figure; 
  plot(ttime1,vec1,'g-');
    title(vac)
  saveas(gcf,['mean_',vac,'.jpg']);

%   save timeseries to file
 y = [ttime1; vec1];
  file = ['mean_',vac,'.txt'];
  fid=fopen(file,'wt');
  fprintf(fid,'%6.6f %12.8f\n', y);
  fclose(fid);
  
end
