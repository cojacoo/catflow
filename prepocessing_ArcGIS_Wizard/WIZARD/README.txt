
 Catflow Wizard
 
 September 2004 by Dominik Reusser

The Catflow Wizard helps to prepare the input files for Catflow from GIS data. 

CATFLOW is a physically based, distributed model for simulating the dynamics 
of water and solutes in small rural catchments on the event and season time 
scale. 
The catchment is modeled as
a) a river network with a topology and river stretch specific river geometry
b) hillslopes represented by a two dimensional y/z raster which is based on
    a curvelinear, orthogonal coordinate system

Information about installation and usage in the help file (catflow.chm)

# 2010-09-22 ## J. Wienhöfer
# Different to the stepwise instruction in the help file, the IDs of Slope lines and Slope polygons 
# need to start from 1, not from zero. While generating the shapes, the ID field can be calculated as
# ID = FID + 1
#
   

Current state of the catflow wizard project:

1) Catflow template with the wizard
   Files created:
   - river net geometry
   - slope data for matlab preprocessing
   - shape files for split points and thiessen polygons 
     (allows to check process)
   
2) Parameters that can be set as default and as
   river stretch-specific values from shape file attributes
   - split length
   - strickler roughness
   - critical rainfall
   - width to depth ratio
   - river bank slope
   - width of sealed surfaces
   - surfaces connected?
   - missing/planned: rain stations as polygon theme
   
3) Parameters that can be set as default and as
   slope-specific vaules from shape file attributes
   - slope thickness
   - slope shape (cake or constant thickness)
   - split length
   - eta and xsi node coordinates
   
4) Matlab script adjusted to read output file
   from catflow wizard. (FromArcGIS.M)
   
5) Help file which is hopefully sufficient to
   create catflow geometry input files if you have a DEM
   only.
   
6) VBA-Code for catflow wizard and helpfile sources (DocBook)
   available in a CVS-Repository. This allows to track changes.
   
7) Installation: Put template (catflow.mxt) and helpfile
   (catflow.chm) into your ArcGIS template directory
   (C:\arcgis\arcexe83\bin\Templates). If the directory differs,
   you'll need to adjust the path (public const helpfile)
   in the module CatflowUtil.
   Copy the matlabScript folder to where you would like to
   run the matlab routines.
   
8) In case the helpfile will not open, check if it is blocked by your operating system (Windows). You might also find this link helpful:
	http://www.west-wind.com/weblog/posts/2012/Jan/11/Problems-with-opening-CHM-Help-files-from-Network-or-Internet

   
