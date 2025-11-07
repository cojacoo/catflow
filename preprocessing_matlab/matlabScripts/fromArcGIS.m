% FromArcGIS.M
% Programm zum Einlesen der Daten aus ArcGIS
% This class is part of the catflow wizard.
% See the help-file catflow.chm for more information

% Copyright (C) 2005  Dominik Reusser (domi_reusser@gmx.net)

% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.

% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
% 
% Input:  Wird abgefragt. ASCII-File aus GIS erzeugt
%

%clear 
global htyp

    
    [filename, pathname] = uigetfile('*.txt', 'Pick the file produced by ArcGIS');
    if isequal(filename,0)
       disp('User selected Cancel')
       exit
   end
    fid = fopen(fullfile(pathname, filename));
  %Dataformat from ArcGis preprocessing:
  %First line: numberOfSlopes (n), maxNumberOfSlopePoints, x_bez, y_bez, z_bez, number of Xsi, number of Eta
    slopeCount = fscanf(fid, '%i',[1 1]) 
    slopePointCount = fscanf(fid, '%i',[1,1])
    re_bez = fscanf(fid, '%g',[1,1])
    ho_bez = fscanf(fid, '%g',[1,1])
    z_bez = fscanf(fid, '%g',[1,1])
    xsiCount = fscanf(fid, '%i',[1,1])
    etaCount = fscanf(fid, '%i',[1,1])
    %line 2 SlopeID
    numh = fscanf(fid, '%i',[1,slopeCount])
  %line 3 SlopeType (Constant Thickness or 'Cake shape')
    htyp = fscanf(fid, '%i',[1,slopeCount])
  %line 4 Area
    flaech = fscanf(fid, '%g',[1,slopeCount])
    flaech = flaech'
  %line 5 Number of points
    punkteh = fscanf(fid, '%i',[1,slopeCount])
  %line 6 Thickness of slope
    dyyy = fscanf(fid, '%g',[1,slopeCount])
    
  %line 7 Eta Values
    eta = fscanf(fid, '%g',[1,etaCount])
  %line 8 Xsi Values
    xsi = fscanf(fid, '%g',[1,xsiCount])
    xsi = xsi'
    if(not(issorted(eta)))
        error('eta is not sorted ascending')
    end
    if(not(issorted(xsi)))
        error('xsi is not sorted ascending')
    end
  %line 9...8+n x of slopepoints
    xh = fscanf(fid, '%g',[slopePointCount,slopeCount])
  %line 9+n...8+2n y of slopepoints
    yh = fscanf(fid, '%g',[slopePointCount,slopeCount])
    
  %line 9+2n...8+3n z of slopepoints
    zh = fscanf(fid, '%g',[slopePointCount,slopeCount])
  %line 9+3n...8+4n width of slopepoints
    bh = fscanf(fid, '%g',[slopePointCount,slopeCount])
    
     fclose(fid)