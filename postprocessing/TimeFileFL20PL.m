%Matrix einlesen, Mittelwerte erstellen
% ACHTUNG! Skript muss zweimal angeschmissen werden. Beim ersten mal Fehlermeldung wegen nicht initialisierter eta und xsi.
% Direkt nochmal anschmeissen und es läuft.

figure;

%Größe des gesuchten Feldes, gezählt wird von links oben
%eta-Richtung
%for nia=1:16;
nia2=2;
nie2=2;%node
nia3=3;
nie3=3;%node
nia4=4;
nie4=4;%node
nia5=5;
nie5=5;%node
nia6=6;
nie6=6;%node
nia7=7;
nie7=7;%node
nia8=8;
nie8=8;%node
nia9=9;
nie9=9;%node
nia10=10;
nie10=10;%node
nia11=11;
nie11=11;%node
nia12=12;
nie12=12;%node
nia13=13;
nie13=13;%node
nia14=14;
nie14=14;%node
nia15=15;
nie15=15;%node
nia16=16;
nie16=16;%node
nia17=17;
nie17=17;%node
nia18=18;
nie18=18;%node
nia19=19;
nie19=19;%node
nia20=20;
nie20=20;%node
nia21=21;
nie21=21;%node

%Xsi-Richtung
nja=48;
nje=48;


%Gesuchter Hang
nhang=1;

%Zahl der Hänge in File
numh = 1;
%Zahl der Zeitschritte 
%numts = 259;
%mdos:
numts = 4320;

  %File oeffnen
  %Bei nur einer Datei
  fid=fopen('fl_xsiTeil2_m.out','r');
  %fid=fopen('fl_eta.out','r');

  %Zähler 
  j=1;
  z=1;
  i=1;
  mat3=zeros(eta,xsi,numts);
  %for z = 1:nhang
  for j=1:numh*numts
       %Daten aus erster Zeile
        stime = fscanf(fid,'%s4');
        time=sscanf(stime,'%f');
        shang = fscanf(fid,'%s4');
        thang = sscanf(shang,'%f');
        hang = -(thang)-1000;
        seta = fscanf(fid,'%s4');
        eta = sscanf(seta,'%f');
        sxsi = fscanf(fid,'%s4');
        xsi = sscanf(sxsi,'%f');
   
        %Matrix des Knotenzustandes
        mat=fscanf(fid, '%f' ,[xsi eta]);
        mat2=mat';
           if hang == nhang
              ttime1(i)=time;
              mat3(:,:,i)=mat2;
              i=i+1;
           end
   end
  
  for i=1:numts
      %Mittelwert bilden
      %vec1=mat3(nia:nie,nja:nje,i);
       %vec1(i)=mean(mean(mat3(nia:nie,nja:nje,i)));
      %Summe
       vec1(i)=sum(sum(mat3(nia2:nie2,nja:nje,i)));
       vec2(i)=sum(sum(mat3(nia3:nie3,nja:nje,i)));
       vec3(i)=sum(sum(mat3(nia4:nie4,nja:nje,i)));
       vec4(i)=sum(sum(mat3(nia5:nie5,nja:nje,i)));
       vec5(i)=sum(sum(mat3(nia6:nie6,nja:nje,i)));
       vec6(i)=sum(sum(mat3(nia7:nie7,nja:nje,i)));
       vec7(i)=sum(sum(mat3(nia8:nie8,nja:nje,i)));
       vec8(i)=sum(sum(mat3(nia9:nie9,nja:nje,i)));
       vec9(i)=sum(sum(mat3(nia10:nie10,nja:nje,i)));
       vec10(i)=sum(sum(mat3(nia11:nie11,nja:nje,i)));
       vec11(i)=sum(sum(mat3(nia12:nie12,nja:nje,i)));
       vec12(i)=sum(sum(mat3(nia13:nie13,nja:nje,i)));
       vec13(i)=sum(sum(mat3(nia14:nie14,nja:nje,i)));
       vec14(i)=sum(sum(mat3(nia15:nie15,nja:nje,i)));
       vec15(i)=sum(sum(mat3(nia16:nie16,nja:nje,i)));
       vec16(i)=sum(sum(mat3(nia17:nie17,nja:nje,i)));
       vec17(i)=sum(sum(mat3(nia18:nie18,nja:nje,i)));
       vec18(i)=sum(sum(mat3(nia19:nie19,nja:nje,i)));
       vec19(i)=sum(sum(mat3(nia20:nie20,nja:nje,i)));
       vec20(i)=sum(sum(mat3(nia21:nie21,nja:nje,i)));
  end
  
  %Zeitreihe plotten
 
  ttime1 = ttime1/86400;
  
  %T save timeser.txt ttime1 vec1;
  %fprintf(fid, '%6.2f %12.8f\n', ttime1, vec1);
  %subplot(2,2,1);
  plot(ttime1,vec1,'g-');
  %subplot(2,2,2);
  hold on;
  plot(ttime1,vec2,'r-');
  %subplot(2,2,3);
  plot(ttime1,vec3,'b-');
  %subplot(2,2,4);
  plot(ttime1,vec4,'y-');
  hold off;
  
  y = [ttime1; vec1; vec2; vec3; vec4; vec5; vec6; vec7; vec8; vec9; vec10; vec11; vec12; vec13; vec14; vec15; vec16; vec17; vec18; vec19; vec20];
  file = ['timeFL20.txt'];
  fid=fopen(file,'wt');
  fprintf(fid,'%6.6f %10.12f %10.12f %10.12f %10.12f %10.12f %10.12f %10.12f %10.12f %10.12f %10.12f %10.12f %10.12f %10.12f %10.12f %10.12f %10.12f %10.12f %10.12f %10.12f %10.12f\n', y);
  fclose(fid);
  hold  on;
  %titel=['fl_xsi'];
  %figure;

  
  %end

