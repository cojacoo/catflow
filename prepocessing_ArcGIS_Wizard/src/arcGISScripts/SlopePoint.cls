VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "SlopePoint"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'This class is part of the catflow wizard.
'See the help-file catflow.chm for more information

'Copyright (C) 2005  Dominik Reusser (domi_reusser@gmx.net)

'This program is free software; you can redistribute it and/or
'modify it under the terms of the GNU General Public License
'as published by the Free Software Foundation; either version 2
'of the License, or (at your option) any later version.

'This program is distributed in the hope that it will be useful,
'but WITHOUT ANY WARRANTY; without even the implied warranty of
'MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
'GNU General Public License for more details.

'You should have received a copy of the GNU General Public License
'along with this program; if not, write to the Free Software
'Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.



Option Explicit

Private mySlope As slope
Private p_xy As IPoint
Private thiessenWidth As Double
Private thiessenArea As Double
Private thiessenLength As Double



Public Property Set Point(xyz As IPoint)
    If (xyz Is Nothing) Then
        Err.Raise vbObjectError, "SlopePoint.setBasics", "xyz is Nothing"
    Else
        'Did not find better method to test whether Z was set
        On Error GoTo zNotSetErr
        If (xyz.Z = 1) Then
             
        End If
        On Error GoTo 0
        Set p_xy = xyz
        thiessenWidth = -1
    End If
    
    Exit Property
    
zNotSetErr:
   Err.Raise vbObjectError, "SlopePoint.setXY", "xy must include a value for z"
    
End Property

Public Property Set slope(s As slope)
    If (s Is Nothing) Then
        Err.Raise vbObjectError, "SlopePoint.Initialize", "Slope is Nothing"
    End If
    
    Set mySlope = s
    thiessenWidth = -1
End Property
Public Property Get slope() As slope
    Set slope = mySlope
End Property
Public Property Get Point() As IPoint
    Set Point = p_xy
    
End Property
Public Property Get Z() As Double
    If (Point Is Nothing) Then
           Err.Raise vbObjectError, "SlopePoint.getZ", "Coordinates have not been set"
    End If
    Z = p_xy.Z
End Property
Public Property Get X() As Double
    If (Point Is Nothing) Then
           Err.Raise vbObjectError, "SlopePoint.getX", "Coordinates have not been set"
    End If
    X = p_xy.X
End Property
Public Property Get Y() As Double
    If (Point Is Nothing) Then
           Err.Raise vbObjectError, "SlopePoint.getY", "Coordinates have not been set"
    End If
    Y = p_xy.Y
End Property
Public Property Get Width() As Double
    If (Point Is Nothing) Then
       Err.Raise vbObjectError, "SlopePoint.getWidth", "Coordinates have not been set"
    End If
    If mySlope Is Nothing Then
       Err.Raise vbObjectError, "SlopePoint.getWidth", "Slope has not been set"
    End If
    If thiessenWidth = -1 Then
       calculateWidth
    End If
    
    Width = thiessenWidth
    
End Property
Private Sub calculateWidth()
   Dim thiessenPoly As IPolygon
   
   Set thiessenPoly = mySlope.ThiessenPolygon(Me)
   
   Dim Area As IArea
   Set Area = thiessenPoly
   thiessenArea = Area.Area()
   
   Dim pTO As ITopologicalOperator
   Set pTO = thiessenPoly
   
   Dim fallLine As IPath
   Set fallLine = mySlope.SlopeFallLine()
   
   Dim pPolyline As IPolyline
   Set pPolyline = New polyline
   Dim pGeomColl As IGeometryCollection
   Set pGeomColl = pPolyline
   pGeomColl.AddGeometry fallLine
   
   Dim IG As IGeometry
   Set IG = pGeomColl
   
   
   
   Set IG = pTO.Intersect(IG, esriGeometry1Dimension)
   
   Dim path As IPath
   Set pGeomColl = IG
   Set path = pGeomColl.Geometry(0)
   
   
   thiessenLength = path.Length()
   thiessenWidth = thiessenArea / thiessenLength
  
 
End Sub

