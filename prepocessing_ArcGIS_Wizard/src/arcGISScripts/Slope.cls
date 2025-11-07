VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Slope"
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

'ID Values
Private slopeID As Integer
Private Const SLOPE_ID_MULTIPLIER As Integer = 1000

'Coordinates
Private myXRef As Double
Private myYRef As Double
Private myZRef As Double


'Length fields
Private dblSplitLength As Double
Private Const defaultSplitLength As Double = 20
Private theThickness As Double
Private Const DefaultThickness As Double = 5

'Shape of the Slope
'These constants are also used in Matlab scripts!
Private Const theSlopeShapeTypeConstantThickness As Integer = 1
Private Const theSlopeShapeTypeCakeShape As Integer = 2
Private theSlopeShapeType As Integer



'GIS objects
Private slopeCatchment As IPolygon
Private digitalElevationModel As IFunctionalSurface
Private mySlopeFallLine As IPath    'SplitDivideLength
Private slopePoints() As SlopePoint    'ISegment.fromPoint
Private thiessenPolygons() As IPolygon


'Featureclasses that will take results
Private slopePointFC As IFeatureClass
Private thiessenPolygonFC As IFeatureClass

'Important Fields in Feature Classes
Private pIDField As Long
Private pWidthField As Long
Private tIDField As Long
Private tAreaField As Long
Private tTagValueField As Long
Private tNodeIndexField As Long
Const pIDFieldName As String = "SP_ID"
Const pWidthFieldName As String = "Width"
Const tTagValueFieldName As String = "TagValue"
Const tNodeIndexFieldName As String = "NodeIndex"
Const tIDFieldName As String = "T_ID"
Const tAreaFieldName As String = "Area"



'Error handling related
Const constErrThiessenShapeVisible As Long = vbObjectError + 10
Const constAutomationError As Long = -2147467259

'States for the object
' line spliting
Private lineSplited As Boolean
' calculating the thiessen polygons
Private thiessenCalculated As Boolean
' calculating the point feature class with attributes
Private slopePointFCisUpToDate As Boolean


Public Property Get ID() As Integer
    ID = slopeID
End Property

Public Property Let ID(theID As Integer)
    slopeID = theID
    slopePointFCisUpToDate = False
End Property

Public Property Get OutLet() As IPoint
    If mySlopeFallLine Is Nothing Then
        Err.Raise vbObjectError, "Slope.getOutLet", _
            "Need to set slopeFallLine " & _
             Chr(13) & "ID of the Slope is " & slopeID
    End If
    
    Set OutLet = mySlopeFallLine.toPoint()
End Property
Public Property Get SplitLength() As Double

   If dblSplitLength = 0 Then
       dblSplitLength = defaultSplitLength
    End If
    
   SplitLength = dblSplitLength
End Property
Public Property Let SplitLength(theLength As Double)
  If theLength <= 0 Then
      Err.Raise vbObjectError, "Slope.setSplitLength", _
            "SplitLength must be > 0 "
  End If
  dblSplitLength = theLength
  reCalcSplit
End Property

Public Property Get numberOfSlopePoints() As Integer
   splitFallLine
   numberOfSlopePoints = UBound(slopePoints) - LBound(slopePoints)
End Property

Public Property Get SlopeShapeType() As Integer
   If theSlopeShapeType = 0 Then
      SlopeShapeType = SlopeShapeTypeConstantThickness
      Exit Property
   End If
   
   SlopeShapeType = theSlopeShapeType
   
End Property

Public Property Let SlopeShapeType(st As Integer)
  If st = SlopeShapeTypeConstantThickness Or _
     st = SlopeShapeTypeCakeShape Then
     theSlopeShapeType = st
  Else
     Err.Raise vbObjectError, "Slope.setSlopeShapeType", _
        "Type must be either ConstantThickness or CakeShape"
  End If
  
End Property

Public Property Get SlopeShapeTypeConstantThickness() As Integer
   SlopeShapeTypeConstantThickness = theSlopeShapeTypeConstantThickness
End Property

Public Property Get SlopeShapeTypeCakeShape() As Integer
   SlopeShapeTypeCakeShape = theSlopeShapeTypeCakeShape
End Property


Public Property Let Thickness(t As Double)
   If Thickness <= 0 Then
     Err.Raise vbObjectError, "Slope.setThickness", _
        "Thickness must be > 0"
   End If
   theThickness = Thickness
End Property
Public Property Get Thickness() As Double
   If theThickness = 0 Then
      Thickness = DefaultThickness
   Else
      Thickness = theThickness
   End If
   
End Property

Private Sub splitFallLine()
     If lineSplited Then
         Exit Sub
     End If
     
     If mySlopeFallLine Is Nothing Then
    
        Err.Raise vbObjectError, "Slope.splitFallLine", _
        "Need to set SlopeFallLine " & _
         Chr(13) & "ID of the Slope is " & slopeID
    End If
    
    If digitalElevationModel Is Nothing Then
        Err.Raise vbObjectError, "Slope.splitFallLine", _
        "Need to set Digital Elevation Model " & _
         Chr(13) & "ID of the Slope is " & slopeID

    End If
    
    If dblSplitLength = 0 Then
       dblSplitLength = defaultSplitLength
    End If
         
    
    Dim boolAsRatio As Boolean
    boolAsRatio = False
   
   
   
    '
    ' Specify the Offset.
    '
    Dim dblOffset As Double
    Dim numberOfPoints As Long
    Dim pointCount As Long
    
    dblOffset = 0
    
    'Make this larger, since estimate is wrong
    numberOfPoints = 2 + positiveRoundUp(mySlopeFallLine.Length / dblSplitLength)
    pointCount = 0
    
    Dim pts() As SlopePoint
    ReDim pts(numberOfPoints)
    
    Dim segmentCollection As ISegmentCollection
    Dim theSegments As IEnumSegment
    Set segmentCollection = mySlopeFallLine
    Set theSegments = segmentCollection.EnumSegments
    
    
    theSegments.Reset
    
    Dim currentSegment As ISegment
    Dim partIndex As Long
    Dim segmentIndex As Long
    theSegments.Next currentSegment, partIndex, segmentIndex
    If Not partIndex = 0 Then
       Err.Raise vbObjectError, "Slope.splitFallLine", "The slope fall line is " & _
              "not a single path as expected. Either, there are missing connections " & _
              "between parts of the line or the line splits at some point" & _
             Chr(13) & "ID of the Slope is " & slopeID
    End If
       
    Do While Not currentSegment Is Nothing
        
        '
        ' Work out the necessary size of the array.
        '
        Dim dblLength As Double
        dblLength = currentSegment.Length()
        If (pointCount = 0 And dblLength < dblSplitLength) Then
            dblOffset = dblSplitLength - dblLength
            Set pts(pointCount) = addPoint(currentSegment.fromPoint())
            pointCount = pointCount + 1
            GoTo nextSegment
        End If
        If (dblLength < dblOffset) Then
            dblOffset = dblOffset - dblLength
            GoTo nextSegment
        End If
        Dim dblArraySize As Double
        If boolAsRatio = True Then
          dblArraySize = (1 - dblOffset) / dblSplitLength
        Else
          dblArraySize = (dblLength - dblOffset) / dblSplitLength
        End If
        '
        ' Set the size of the array. This should be the calculated number of
        ' segments ROUNDED UP - because the array should contain a segment to
        ' hold the end segment, which is a fraction of the split length.
        '
        Dim pSegments() As ISegment
        ReDim pSegments(positiveRoundUp(dblArraySize))
        
        Dim lngNumSegs As Long
        currentSegment.SplitDivideLength dblOffset, dblSplitLength, boolAsRatio, lngNumSegs, pSegments(0)
        
        
        
        Dim i As Long
        
        For i = 0 To (lngNumSegs - 1)
          'Assign coordinates to Slopepoints
          If (pointCount > 0 And i = 0) Then
               'Do not use starting points of each segment
               i = 1
          End If
          
          Set pts(pointCount) = addPoint(pSegments(i).fromPoint)
          pointCount = pointCount + 1
        Next i
        dblOffset = (dblSplitLength - pSegments(lngNumSegs - 1).Length)
nextSegment:
        theSegments.Next currentSegment, partIndex, segmentIndex
        If Not partIndex = 0 Then
            Err.Raise vbObjectError, "Slope.splitFallLine", "The slope fall line is " & _
              "not a single path as expected. Either, there are missing connections " & _
              "between parts of the line or the line splits at some point" & _
             Chr(13) & "ID of the Slope is " & slopeID
        End If
    Loop
    
    ReDim slopePoints(pointCount - 1)
    ReDim thiessenPolygons(pointCount - 1)
    
    'Copy points into the final array
    
    For i = 0 To (pointCount - 1)
        Set slopePoints(i) = pts(i)
    Next i

    lineSplited = True
    thiessenCalculated = False
    slopePointFCisUpToDate = False
End Sub
Private Function addPoint(Point As IPoint) As SlopePoint
    Point.Z = digitalElevationModel.Z(Point.X, Point.Y)
    Dim spoint As SlopePoint
    Set spoint = New SlopePoint
    Set spoint.Point = Point
    Set spoint.Slope = Me
    Set addPoint = spoint
End Function
Public Sub updateThiessenFeatureClass()
         
     updatePointFeatureClass
     
     If thiessenPolygonFC Is Nothing Then
         Err.Raise vbObjectError, "Slope.updateThiessenFeatureClass", _
            "Please set ThiessenFeatureClass first"
     End If
     
     If slopeCatchment Is Nothing Then
            Err.Raise vbObjectError, "Slope.updateThiessenFeatureClass", _
            "Please set Slope Boundary first"
     End If
         
     
     If thiessenCalculated Then
        Exit Sub
     End If
     
     'Delete old thiessen polygons if existing
     deleteOld thiessenPolygonFC, tIDFieldName
 
     'If unable to compile here, try to activate
     'the Tin Reference using the menu
     'Tools:References
     Dim i As Integer
     Dim pFields As IFields2
     Dim idField As IField
     Dim pTinEdit As ITinEdit
     Dim pTin As ITin
     Dim pNodeCol As ITinNodeCollection
     'Dim pFeature As IFeature
     
     'ID Field to Identify Polygon (TagField)
     Set pFields = slopePointFC.Fields
     Set idField = pFields.Field(pIDField)
     'Create a Query to only use SlopePoints belonging to this slope
     Dim pQFilt As IQueryFilter
     Dim pFeatCur As IFeatureCursor

     Set pQFilt = New QueryFilter
     pQFilt.whereClause = "( " & pIDFieldName & " >= " & _
                       CLng(slopeID) * SLOPE_ID_MULTIPLIER & _
                       " ) and ( " & _
                       pIDFieldName & " < " & _
                       CLng(slopeID + 1) * SLOPE_ID_MULTIPLIER & _
                       " ) "
     'Create and initialize a new tin to hold slope points
     'Only a tin allows the ConvertToVoronoiRegions method
     Set pTinEdit = New Tin
     Set pTin = pTinEdit
     pTinEdit.InitNew slopeCatchment.Envelope
     'Add points to the TIN
     pTinEdit.AddFromFeatureClass slopePointFC, pQFilt, idField, idField, esriTinMassPoint
     'Calculate Thiessen Polygons using the ITinNodeCollection interface
     Set pNodeCol = pTinEdit
     On Error GoTo errConvert
     pNodeCol.ConvertToVoronoiRegions thiessenPolygonFC, Nothing, slopeCatchment, "", ""
     On Error GoTo 0
     'Save tin in temporary file and stop editing
     'pTinEdit.SaveAs getFreeFileName()
     pTinEdit.StopEditing False
     
  'Make Polygons available as single shapes
  pQFilt.whereClause = "( " & tTagValueFieldName & " >= " & _
                       CLng(slopeID) * SLOPE_ID_MULTIPLIER & _
                       " ) and ( " & _
                       tTagValueFieldName & " < " & _
                       CLng(slopeID + 1) * SLOPE_ID_MULTIPLIER & _
                       " ) "
  Set pFeatCur = thiessenPolygonFC.Search(pQFilt, True)
  Dim tagValueFieldID As Integer
  tagValueFieldID = pFeatCur.FindField(tTagValueFieldName)

  Dim pFeature As IFeature
  Set pFeature = pFeatCur.NextFeature()
  
  Do While Not (pFeature Is Nothing)
    Dim tID As Long
    tID = pFeature.Value(tagValueFieldID)
    Dim polygonID As Integer
    polygonID = tID - CLng(SLOPE_ID_MULTIPLIER) * slopeID
    
    Set thiessenPolygons(polygonID) = pFeature.ShapeCopy
    Set pFeature = pFeatCur.NextFeature()
  Loop
  
  'Will be used again
  Set pFeature = Nothing
  Set pFeatCur = Nothing
  
     
  Dim lIDField As Integer
  Dim lAreaField As Integer
  
  'Update Area-Field
  
  Dim fieldNames(2) As String
  Dim fieldIDs(2) As Integer
  Const cTagValueField As Integer = 0
  Const cIDField As Integer = 1
  Const cAreaField As Integer = 2
  
  fieldNames(cTagValueField) = tTagValueFieldName
  fieldNames(cIDField) = tIDFieldName
  fieldNames(cAreaField) = tAreaFieldName
  

  Set pFeatCur = getFeatureCursor(thiessenPolygonFC, _
                                 fieldNames, _
                                 fieldIDs)
    

  ' Add area field to features
  
  Set pFeature = pFeatCur.NextFeature
  Do Until pFeature Is Nothing
    tID = pFeature.Value(fieldIDs(cTagValueField))
    Dim sID As Integer
    sID = Int(tID / SLOPE_ID_MULTIPLIER)
    polygonID = tID - CLng(SLOPE_ID_MULTIPLIER) * sID
    If sID = slopeID Then
      Dim pArea As IArea
      Set pArea = thiessenPolygons(polygonID)
      pFeature.Value(fieldIDs(cAreaField)) = pArea.Area()
      pFeature.Value(fieldIDs(cIDField)) = tID
      pFeatCur.UpdateFeature pFeature
    End If
    Set pFeature = pFeatCur.NextFeature
  Loop
  
  Set pFeatCur = Nothing
  
  'Delete the TagValueField
  tTagValueField = thiessenPolygonFC.FindField(tTagValueFieldName)
  Dim pFieldTagValue As IField
  Set pFieldTagValue = thiessenPolygonFC.Fields.Field(tTagValueField)
  thiessenPolygonFC.DeleteField pFieldTagValue
  
  tNodeIndexField = thiessenPolygonFC.FindField(tNodeIndexFieldName)
  Dim pFieldNodeIndex As IField
  Set pFieldNodeIndex = thiessenPolygonFC.Fields.Field(tNodeIndexField)
  thiessenPolygonFC.DeleteField pFieldNodeIndex
  
  
  releaseLock thiessenPolygonFC
  
  thiessenCalculated = True
  
  Exit Sub
errConvert:
  If Err.Number = constAutomationError Then
     Err.Clear
     Err.Raise constErrThiessenShapeVisible, "Slope.calcThiessenPolygon", _
         "Automation error caught.  " & Chr(13) & _
         "It is likely that file selected for saving " & _
         "thiessen polygons is an active layer." & Chr(13) & _
         "Please remove the corresponding layer from the map."
  End If
End Sub




Public Sub toMatlab(w() As Double, _
                        X() As Double, _
                        Y() As Double, _
                        Z() As Double)
                        
        splitFallLine
        Dim counter As Integer
        For counter = LBound(slopePoints) To UBound(slopePoints)
            If LBound(w) > counter Or UBound(w) < counter Then
              Err.Raise vbObjectError, _
                      "Slope.toMatlab", _
                      "Width array does not have the right dimension." & _
                      "Current index is " & counter
            End If
            
            If LBound(X) > counter Or UBound(X) < counter Then
                    Err.Raise vbObjectError, _
                      "Slope.toMatlab", _
                      "X array does not have the right dimension." & _
                      "Current index is " & counter
            End If

            If LBound(Y) > counter Or UBound(Y) < counter Then
                    Err.Raise vbObjectError, _
                      "Slope.toMatlab", _
                      "Y array does not have the right dimension." & _
                      "Current index is " & counter
            End If

            If LBound(Z) > counter Or UBound(Z) < counter Then
                    Err.Raise vbObjectError, _
                      "Slope.toMatlab", _
                      "Z array does not have the right dimension." & _
                      "Current index is " & counter
            End If

            w(counter) = slopePoints(counter).Width
            X(counter) = slopePoints(counter).X
            Y(counter) = slopePoints(counter).Y
            Z(counter) = slopePoints(counter).Z
            
        Next
        
End Sub

Public Sub updatePointFeatureClass()
     
   splitFallLine
   
   If slopePointFCisUpToDate Then
      Exit Sub
   End If
  
   If slopePointFC Is Nothing Then
      Err.Raise vbObjectError, "Slope.updatePointFeatureClass", _
          "Please set slopePointFC first"
   End If
   
   deleteOld slopePointFC, pIDFieldName

   'Insert single Features using a cursor
   Dim pFeatCur As IFeatureCursor
   Set pFeatCur = slopePointFC.Insert(True)
   
   
  'Create the point shape first
  Dim i As Integer
  For i = LBound(slopePoints) To UBound(slopePoints)
       Dim pFeatBuf As IFeatureBuffer
       Set pFeatBuf = slopePointFC.CreateFeatureBuffer
       Set pFeatBuf.Shape = slopePoints(i).Point
       pFeatBuf.Value(pIDField) = CLng(slopeID) * SLOPE_ID_MULTIPLIER + i
       'pFeatBuf.Value(pWidthField) = 5
       Dim v As Variant 'ID of the new Feature
       v = pFeatCur.InsertFeature(pFeatBuf)
       
  Next i
  
  Set pFeatCur = Nothing
  
  'this is necessary because otherwise the method gets executed again
  'when a SlopePoint requests a ThiessenPolygon
  slopePointFCisUpToDate = True
        
    'Add width entries later because
    'this requires thiessen polygons
    'but thiessen polygons require
    'point shape file
    
  
  Dim fieldNames(1) As String
  Dim fieldIDs(1) As Integer
  Const cIDField As Integer = 0
  Const cWidthField As Integer = 1
  
  fieldNames(cIDField) = pIDFieldName
  fieldNames(cWidthField) = pWidthFieldName
  
  On Error GoTo errConvert
  Set pFeatCur = getFeatureCursor(slopePointFC, _
                                 fieldNames, _
                                 fieldIDs)
  On Error GoTo 0

  ' Process the features
  Dim pFeature As IFeature
  Set pFeature = pFeatCur.NextFeature
  Do Until pFeature Is Nothing
    Dim tID As Long
    tID = pFeature.Value(fieldIDs(cIDField))
    Dim sID As Integer
    Dim PointID As Integer
    sID = Int(tID / SLOPE_ID_MULTIPLIER)
    PointID = tID - CLng(SLOPE_ID_MULTIPLIER) * sID
    If (sID = slopeID) Then
      pFeature.Value(fieldIDs(cWidthField)) = slopePoints(PointID).Width
      pFeatCur.UpdateFeature pFeature
    End If
    Set pFeature = pFeatCur.NextFeature
  Loop
  
  Set pFeatCur = Nothing
  

  releaseLock slopePointFC
  
  
  Exit Sub
errConvert:
  If Err.Number = constAutomationError Then
     Err.Clear
     Err.Raise constErrThiessenShapeVisible, "Slope.calcThiessenPolygon", _
         "Automation error caught.  " & Chr(13) & _
         "It is likely that file selected for saving " & _
         "points is an active layer." & Chr(13) & _
         "Please remove the corresponding layer from the map."
  End If

End Sub

Private Sub deleteOld(theFeatureClass As IFeatureClass, theIDField As String)
   'Deleting previous Points
   Dim fieldNames(0) As String
   Dim fieldIDs(0) As Integer
   Dim whereClause As String

   whereClause = "( " & theIDField & " >= " & _
                       CLng(slopeID) * SLOPE_ID_MULTIPLIER & _
                       " ) and ( " & _
                       theIDField & " < " & _
                       CLng(slopeID + 1) * SLOPE_ID_MULTIPLIER & _
                       " ) "
  
   fieldNames(0) = "Shape"
 
   Dim pFeatCur As IFeatureCursor
   Set pFeatCur = getFeatureCursor(theFeatureClass, _
                                 fieldNames, _
                                 fieldIDs, _
                                 whereClause)

   ' Process the features
   Dim pFeature As IFeature
   Set pFeature = pFeatCur.NextFeature
   Do Until pFeature Is Nothing
     pFeatCur.DeleteFeature
     Set pFeature = pFeatCur.NextFeature
   Loop
  
   Set pFeatCur = Nothing
  
   releaseLock theFeatureClass
   

End Sub
Public Property Get ThiessenPolygon(Point As SlopePoint) As IPolygon
     updateThiessenFeatureClass
     
     Dim i As Integer
     For i = LBound(slopePoints) To UBound(slopePoints)
         If slopePoints(i) Is Point Then
              Set ThiessenPolygon = thiessenPolygons(i)
              Exit Property
         End If
     Next i
     
     Err.Raise vbObjectError, _
           "Slope.getThiessenPolygon", _
           "Passed point is not member of this Slope" & _
             Chr(13) & "ID of the Slope is " & slopeID

End Property
Public Property Get SlopeFallLine() As IPath
     Set SlopeFallLine = mySlopeFallLine
End Property

Public Property Set SlopeFallLine(theSlopeFallLine As IPath)
    If theSlopeFallLine Is Nothing Then
      Err.Raise vbObjectError, _
             "Slope.setInputFeatures", _
             "SlopetheSlopeFallLine was Nothing" & _
             Chr(13) & "ID of the Slope is " & slopeID
   End If
   
   If Not slopeCatchment Is Nothing Then
        testSlopeLineWithinCatchment theSlopeFallLine, slopeCatchment
   End If
   
   If Not DEM Is Nothing Then
        Set theSlopeFallLine = testSlopeLineToBeTurned(theSlopeFallLine)
   End If
   
   
   Set mySlopeFallLine = theSlopeFallLine
   
   reCalcSplit
   
End Property
Public Property Get SlopePolygon() As IPolygon
   Set SlopePolygon = slopeCatchment
End Property
Public Property Set SlopePolygon(theSlopePolygon As IPolygon)
   If theSlopePolygon Is Nothing Then
      Err.Raise vbObjectError, _
             "Slope.setInputFeatures", _
             "theSlopePolygon was Nothing" & _
             Chr(13) & "ID of the Slope is " & slopeID
   End If
   
   If Not mySlopeFallLine Is Nothing Then
      testSlopeLineWithinCatchment mySlopeFallLine, theSlopePolygon
   End If
   
   Set slopeCatchment = theSlopePolygon
   
   thiessenCalculated = False
   slopePointFCisUpToDate = False
   
End Property

Private Function testSlopeLineToBeTurned(theLine As IPath) As IPath
   Dim fromPoint As IPoint
   Dim toPoint As IPoint
   Set fromPoint = theLine.fromPoint()
   Set toPoint = theLine.toPoint()
   If DEM.Z(fromPoint.X, fromPoint.Y) < DEM.Z(toPoint.X, toPoint.Y) Then
      Dim pCurve As ICurve
      Set pCurve = theLine
    
      pCurve.ReverseOrientation
      Set theLine = pCurve
   End If
   Set testSlopeLineToBeTurned = theLine
End Function

Private Sub testSlopeLineWithinCatchment(line As IPath, poly As IPolygon)
   Dim pRelOp As IRelationalOperator
   Set pRelOp = poly
   
   Dim pPolyline As IPolyline
   Set pPolyline = New polyline
   Dim pGeomColl As IGeometryCollection
   Set pGeomColl = pPolyline
   pGeomColl.AddGeometry line
   
   If Not (pRelOp.Contains(pGeomColl)) Then
      Err.Raise vbObjectError, _
             "Slope.setInputFeatures", _
             "SlopeFallLine is not within SlopePolygon" & _
             Chr(13) & "ID of the Slope is " & slopeID
   End If
  
End Sub

Public Property Set DEM(theDigitalElevationModel As IFunctionalSurface)
   If theDigitalElevationModel Is Nothing Then
      Err.Raise vbObjectError, _
             "Slope.setInputFeatures", _
             "digitalElevationModel was Nothing" & _
             Chr(13) & "ID of the Slope is " & slopeID
   End If
   
   Set digitalElevationModel = theDigitalElevationModel
   
   If Not SlopeFallLine Is Nothing Then
        'Reassign to test direction
        Set Me.SlopeFallLine = Me.SlopeFallLine
   End If
   
   reCalcSplit
End Property

Public Property Get DEM() As IFunctionalSurface
   Set DEM = digitalElevationModel
End Property
Public Property Get SlopePointFeatureClass() As IFeatureClass
  Set SlopePointFeatureClass = slopePointFC
End Property
Public Property Set SlopePointFeatureClass(theSlopePointFeatureClass As IFeatureClass)
   If theSlopePointFeatureClass Is Nothing Then
      Err.Raise vbObjectError, _
             "Slope.setInputFeatures", _
             "Feature class for slope points was Nothing" & _
             Chr(13) & "ID of the Slope is " & slopeID
   End If
   'Are the fields as expected?
   pIDField = theSlopePointFeatureClass.FindField(pIDFieldName)
   If pIDField = -1 Then
     Err.Raise vbObjectError, _
           "Slope.setInputFeatures", _
           "ID field not found in slope point feature class." & _
             Chr(13) & "ID of the Slope is " & slopeID
   End If
   
   If Not theSlopePointFeatureClass.Fields.Field(pIDField).Type = esriFieldTypeInteger Then
     Err.Raise vbObjectError, _
           "Slope.setInputFeatures", _
           "ID field in slope point feature class is not an integer field." & _
             Chr(13) & "ID of the Slope is " & slopeID
   End If
  
   pWidthField = theSlopePointFeatureClass.FindField(pWidthFieldName)
   If pWidthField = -1 Then
      Err.Raise vbObjectError, _
           "Slope.setInputFeatures", _
           "Width field not found in slope point feature class." & _
             Chr(13) & "ID of the Slope is " & slopeID
   End If
   
   If Not theSlopePointFeatureClass.Fields.Field(pWidthField).Type = esriFieldTypeDouble Then
     Err.Raise vbObjectError, _
           "Slope.setInputFeatures", _
           "Width field in slope point feature class is not an double field." & _
             Chr(13) & "ID of the Slope is " & slopeID
   End If
   
   Set slopePointFC = theSlopePointFeatureClass
   
   reCalcSplit
   
End Property
Public Property Get ThiessenPolygonFeatureClass() As IFeatureClass
  Set ThiessenPolygonFeatureClass = thiessenPolygonFC
End Property
Public Property Set ThiessenPolygonFeatureClass(theThiessenPolygonFeatureClass As IFeatureClass)
                          
   If theThiessenPolygonFeatureClass Is Nothing Then
      Err.Raise vbObjectError, _
             "Slope.setInputFeatures", _
             "Feature class for thiessen theSlopePolygons was Nothing" & _
             Chr(13) & "ID of the Slope is " & slopeID
   End If
   
   'Check weather feature class has all the fields we need
   
    tIDField = theThiessenPolygonFeatureClass.FindField(tIDFieldName)
    If tIDField = -1 Then
       Err.Raise vbObjectError, _
         "ID field not found in thiessen theSlopePolygon feature class." & _
             Chr(13) & "ID of the Slope is " & slopeID
    End If
         
    If Not theThiessenPolygonFeatureClass.Fields.Field(tIDField).Type = esriFieldTypeInteger Then
       Err.Raise vbObjectError, _
         "Slope.setInputFeatures", _
         "ID field in thiessen theSlopePolygon feature class is not " & _
         "an integer field." & _
             Chr(13) & "ID of the Slope is " & slopeID
    End If
   
   
   tTagValueField = theThiessenPolygonFeatureClass.FindField(tTagValueFieldName)
   If Not (tTagValueField = -1) Then
     Err.Raise vbObjectError, _
           "Slope.setInputFeatures", _
           "TagValue field must not exist in thiessen polygon feature class." & _
             Chr(13) & "ID of the Slope is " & slopeID
   End If
   
   tNodeIndexField = theThiessenPolygonFeatureClass.FindField(tNodeIndexFieldName)
   If Not (tNodeIndexField = -1) Then
     Err.Raise vbObjectError, _
           "Slope.setInputFeatures", _
           "NodeIndex field must not exist in thiessen polygon feature class." & _
             Chr(13) & "ID of the Slope is " & slopeID
   End If
   
   tAreaField = theThiessenPolygonFeatureClass.FindField(tAreaFieldName)
   If tAreaField = -1 Then
      Err.Raise vbObjectError, _
           "Slope.setInputFeatures", _
           "Area field not found in thiessen polygon feature class." & _
             Chr(13) & "ID of the Slope is " & slopeID
   End If
   
   If Not theThiessenPolygonFeatureClass.Fields.Field(tAreaField).Type = esriFieldTypeDouble Then
     Err.Raise vbObjectError, _
           "Slope.setInputFeatures", _
           "Area field in thiessen polygon feature class is not an double field." & _
             Chr(13) & "ID of the Slope is " & slopeID
   End If
   
   Set thiessenPolygonFC = theThiessenPolygonFeatureClass
   
   reCalcSplit
   
End Property

Public Property Let XRef(X As Double)
      myXRef = X
End Property
Public Property Get XRef() As Double
      XRef = myXRef
End Property
Public Property Let YRef(Y As Double)
      myYRef = Y
End Property
Public Property Get YRef() As Double
      YRef = myYRef
End Property
Public Property Let ZRef(Z As Double)
      myZRef = Z
End Property
Public Property Get ZRef() As Double
      ZRef = myZRef
End Property
Public Property Get Area() As Double
  If slopeCatchment Is Nothing Then
     Err.Raise vbObjectError, "Slope.getArea", "Please set the CatchmentPolygon first"
  End If
  Dim pArea As IArea
  Set pArea = slopeCatchment
  Area = pArea.Area
End Property

Private Sub reCalcSplit()
    lineSplited = False
    thiessenCalculated = False
    slopePointFCisUpToDate = False
End Sub

Public Property Get errThiessenShapeVisible() As Long
   errThiessenShapeVisible = constErrThiessenShapeVisible
End Property
