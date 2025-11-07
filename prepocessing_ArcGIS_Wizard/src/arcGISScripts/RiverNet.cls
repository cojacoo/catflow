VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "RiverNet"
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

Private Const numberOfPossibleUpstreams As Integer = 6
Private Const allowableStrahlerOrder As Integer = 20
Private Const defaultRainStationID As Integer = 0
Private nextDownstream() As Integer
Private nextUpstream() As Integer
Private unprocessed() As RiverSegment
Private processed() As RiverSegment
Private orderIncreasingID() As Integer
Private theSegments As IFeatureClass
Private theRainPolygons As IFeatureClass
Private queue As queue
Private currentPointCounter As Integer
Private currentSegmentCounter As Integer
Private myDEM As IFunctionalSurface
Private numberOfPaths As Integer

'parameter field
Private Const CriticalRain As Long = 0
Private Const WidthToDepthRatio As Long = 1
Private Const Strickler As Long = 2
Private Const BankSlope As Long = 3
Private Const SurfaceWidth As Long = 4
Private Const Connected As Long = 5
Private Const SplitLength As Long = 6
Private Const RainStationID As Long = 7

Private Const NumberOfParameterFields = 8
Private Const NumberOfPolylineParameterFields = 7
Private Const OrderDependentValuesBelow = 6
Private theParameterFieldIndex(NumberOfParameterFields) As Long
Private DefaultValue(NumberOfParameterFields, allowableStrahlerOrder) As Double


'length fields
Private currentSearchRadius As Double

'state handling
Private riverNetInitialized As Boolean
Private riverNetCalculated As Boolean
'Throw an error if we want to
'output to catflow without any slopes
'being connected. Otherwise, if
'the rivernet is recreated, output is
'created without slope ID and the problem
'is hidden.
Private isSlopeConnected As Boolean
'we need strahler order to assign correct parameters
'however, parameters are assigned before calculating the order
'because attributes from the shape are not available later on,
'therefore we need to run the whole calculation at least twice.
'This flag is only set during the first calculation.
Private reRunCalcExecutionSequence As Boolean

'Error handling
Private Const errTooManyOutflows = vbObjectError + 20

Public Property Get SlopeConnected() As Boolean
    SlopeConnected = isSlopeConnected
End Property

Public Property Get RiverNetPoints() As Multipoint
     If Not riverNetCalculated Then
       calcExecutionSequence
     End If
     
     Dim collection As IGeometryCollection
     Set collection = New Multipoint
     Dim counter As Integer
     For counter = 0 To numberOfPaths - 1
        collection.AddGeometryCollection processed(counter).allPoints()
     Next
     
     Set RiverNetPoints = collection
End Property

Public Property Get MaximumStrahlerOrder() As Long
  If Not riverNetCalculated Then
    calcExecutionSequence
  End If
  
  
  If numOfOutflows() <> 1 Then
    Err.Raise vbObjectError, "RiverNet.GetMaximumStrahlerOrder", _
        "More than one (or no) outflow detetcted. Can not determine Maximum Order."
  End If
  
  Dim counter As Long
  
  For counter = 0 To numberOfPaths - 1
     If nextDownstream(counter) = -1 Then
        MaximumStrahlerOrder = processed(counter).StrahlerOrdnung
     End If
  Next

End Property
Public Sub connectSlope(s As slope)

    'Dim riverNet As IProximityOperator
    'Set riverNet = RiverNetPoints
    
    Dim theConnection As IPoint
    'riverNet.QueryNearestPoint theConnection, esriNoExtension, s.OutLet()
    Set theConnection = findNearest(s.OutLet, RiverNetPoints)
    
    If theConnection Is Nothing Then
       Err.Raise vbObjectError, "RiverNet.ConnectSlope", _
                 "No nearest point found for slope " & _
                 s.ID
    End If

    Dim counter As Integer
    For counter = 0 To numberOfPaths - 1
        If (theConnection.ID >= processed(counter).firstPointID) _
           And (theConnection.ID <= processed(counter).lastPointID) _
           Then
           processed(counter).connectSlope s, theConnection.ID
           isSlopeConnected = True
           Exit Sub
        End If
    Next
        
    Err.Raise vbObjectError, "RiverNet.connectSlope", "Slope was not connected to any river point."
        
    
End Sub
Public Sub toCatflow(outStream As TextStream)
  If Not riverNetCalculated Then
    'Quickfix since Rainstation is not implemented in Wizard yet
    
    'Otherwise, this will be set (by the get-Method) with the first calculation
    'of the rivernet parameters in the toCatflow routines of
    'riverpoints. And changing the DefaultValue causes the
    'rivernet to be reinitialized
    DefaultParameterValue(ParameterTypeRainStationID) = defaultRainStationID
    
    calcExecutionSequence
  End If
  
  If Not isSlopeConnected Then
     Err.Raise vbObjectError, "RiverNet.toCatflow", _
                 "RiverNet.toCatflow: No slopes are connected "
  End If
  
  Dim counter As Integer
  For counter = 0 To numberOfPaths - 1
     processed(orderIncreasingID(counter)).toCatflow outStream
  Next
End Sub

Private Sub calcExecutionSequence()
  
  If Not riverNetInitialized Then
    extractPathpolylines
  End If
  
  'Remember order of segments with increasing ID
  ReDim orderIncreasingID(numberOfPaths)
  currentSegmentCounter = 0
  'Reset ID for River Points
  currentPointCounter = 1
  
  Set queue = New queue
  
  allSpringsToQueue

  Do While Not (queue.IsEmpty)
     'Get ID of the next Segment
     Dim toProcess As Integer
     toProcess = queue.Pop
     'Remember order of segments with increasing ID
     orderIncreasingID(currentSegmentCounter) = toProcess
     currentSegmentCounter = currentSegmentCounter + 1
     
     processNextSegment toProcess
  Loop
  'Mark outflow riverpoint as such
  
  
  processed(orderIncreasingID(numberOfPaths - 1)).lastRiverPoint.IsTheOutlet = True
  
  
  
  'Because we need to know strahler order to assign correct parameters
  'This should be changed when implementing again
  If reRunCalcExecutionSequence Then
     reRunCalcExecutionSequence = False
     reinitializeRiverNet
     calcExecutionSequence
     Exit Sub
  End If
  
  riverNetCalculated = True
  ' Because unprocessed are now nothing
  riverNetInitialized = False
  
  If MaximumStrahlerOrder >= allowableStrahlerOrder Then
    Err.Raise vbObjectError, "RiverNet.calcExecutionSequence", _
           "Allowale Strahler order exceeded. Please increase " & _
           "constant (allowableStrahlerOrder) in the RiverNet code " & _
           "to at least " & MaximumStrahlerOrder + 1 & _
           ". Required to store order sensitive" & _
           "parameter values."
  End If

End Sub


Private Sub processNextSegment(segmentNr As Integer)

    'Find all directly upstream RiverPoints
    Dim upStreamCount As Integer
    upStreamCount = numberOfUpStreams(segmentNr)
    
    ReDim upstreamRiverPoints(IIf(upStreamCount = 0, 1, upStreamCount)) As RiverPoint
    Dim counter As Integer
    
    For counter = 1 To upStreamCount
       Set upstreamRiverPoints(counter - 1) = processed(nextUpstream(segmentNr, counter)).lastRiverPoint
    Next

    'Tell the segment to Number its river net points
    'And remember the new state of the counter
    On Error GoTo err_assign
    currentPointCounter = unprocessed(segmentNr).assignNumbers(currentPointCounter, upstreamRiverPoints())
    On Error GoTo 0
    
    'Remove it from unprocessed
    Set processed(segmentNr) = unprocessed(segmentNr)
    Set unprocessed(segmentNr) = Nothing
    
    setStrahlerOrderNextDownstream segmentNr

    'Has nextDownstream any unprocessed nextUpstream?
    'If not, add it to the queue
    
    Dim downStrS As Integer
    downStrS = nextDownstream(segmentNr)
    
    If downStrS = -1 Then
        Exit Sub
    End If
    
    Dim thereIsOne As Boolean
    thereIsOne = False
    For counter = 1 To numberOfUpStreams(downStrS)
       If Not unprocessed(nextUpstream(downStrS, counter)) _
           Is Nothing Then
           thereIsOne = True
           Exit Sub
       End If
    Next
    
    If Not thereIsOne Then
      queue.Push (downStrS)
    End If

    Exit Sub

err_assign:
    showPath unprocessed(segmentNr).path
    Err.Raise Err.Number, Err.Source, Err.Description
End Sub

Private Function numberOfUpStreams(segmentNr As Integer) As Integer
    Dim counter As Integer
    For counter = 1 To numberOfPossibleUpstreams
          If nextUpstream(segmentNr, counter) = -1 Then
             numberOfUpStreams = counter - 1
             Exit Function
          End If
    Next
    numberOfUpStreams = numberOfPossibleUpstreams
End Function

Private Sub setStrahlerOrderNextDownstream(segmentNr As Integer)
    Dim downStrS As Integer
    downStrS = nextDownstream(segmentNr)
    
    If downStrS = -1 Then
      Exit Sub
    End If
    
    If numberOfUpStreams(downStrS) = 1 Then
       unprocessed(downStrS).StrahlerOrdnung = _
            processed(segmentNr).StrahlerOrdnung
    Else
      If unprocessed(downStrS).StrahlerOrdnung < _
              processed(segmentNr).StrahlerOrdnung + 1 Then
           unprocessed(downStrS).StrahlerOrdnung = _
              processed(segmentNr).StrahlerOrdnung + 1
      End If
    End If
End Sub
Public Property Set DEM(d As IFunctionalSurface)
  Set myDEM = d
  reinitializeRiverNet True
End Property
Public Property Get RainstationPolygons() As IFeatureClass
  Set RainstationPolygons = theRainPolygons
End Property
Public Property Set RainstationPolygons(polygons As IFeatureClass)
  If polygons Is Nothing Then Exit Property
  If Not polygons.ShapeType = esriGeometryPolygon Then
     Err.Raise vbObjectError, "RiverNet.setRainstationPolygons", _
          "RainstationPolygons needs to be of type esriGeometryPolygon"
  End If
  
  
  Set theRainPolygons = polygons
  
  ParameterFieldName(ParameterTypeRainStationID) = ""
End Property
Public Function getRainstationID(Point As IPoint) As Integer
  'Any Polygons available and attribute field set?
  Dim fc As IFeatureClass
  Set fc = RainstationPolygons
  If Not (fc Is Nothing Or _
          ParameterFieldIndex(ParameterTypeRainStationID) = -1) _
    Then
    
    
    'to test Geographic relationship
    Dim operator As IRelationalOperator
    Set operator = Point
    
    'container for polygons
    Dim feature As IFeature
    Dim theFeature As IFeature
    Dim numPolygons As Long
    
    
    'Polygon containing point available?
    numPolygons = fc.featureCount(Nothing)
    
    Dim counter As Integer
    
    For counter = 0 To numPolygons - 1
      'Get the Polygon
      Set feature = fc.GetFeature(counter)
      'Is point within the polygon
      Dim Geometry As IGeometry
      Set Geometry = feature.Shape
      If operator.Within(Geometry) Then
         
         If theFeature Is Nothing Then
            Set theFeature = feature
         Else
         'More than one Polygon?
            Err.Raise vbObjectError, "RiverNet.getRainstationID", _
            "Overlapping Polygons for Rainstation IDs not allowed"
         End If
      End If
    Next
    
    'Assign Attribute from Polygon
    If Not (theFeature Is Nothing) Then
      getRainstationID = theFeature.Value(ParameterFieldIndex(ParameterTypeRainStationID))
      Exit Function
    End If
  End If
  
  'Default value if no Polygon
  If DefaultParameterValue(ParameterTypeRainStationID) = -1 Then
     DefaultParameterValue(ParameterTypeRainStationID) = defaultRainStationID
  End If
  
  getRainstationID = DefaultParameterValue(ParameterTypeRainStationID)
End Function
Public Property Set polylines(segments As IFeatureClass)
  If segments Is Nothing Then Exit Property
  If Not segments.ShapeType = esriGeometryPolyline Then
     Err.Raise vbObjectError, "RiverNet.setPolyline", _
          "polylines needs to be of type esriGeometryPolyline"
  End If
  If myDEM Is Nothing Then
     Err.Raise vbObjectError, "RiverNet.setPolyline", _
          "Please set digital elevation model first"
          
  End If
  
  Set theSegments = segments
  
  Dim counter As Long
  For counter = 0 To NumberOfPolylineParameterFields - 1
     ParameterFieldName(counter) = ""
  Next
  reinitializeRiverNet True
  
End Property

Public Property Get polylines() As IFeatureClass
  Set polylines = theSegments
End Property

Private Sub extractPathpolylines()
  
  'Count paths in all features
  
  numberOfPaths = 0
  Dim featureCount As Integer
  featureCount = polylines.featureCount(Nothing)
  ReDim pPoly(featureCount) As IPolyline
  
  Dim counter As Integer
  For counter = 0 To featureCount - 1
    Dim pFeature As IFeature
    Dim pGeomCol As IGeometryCollection
    Set pFeature = polylines.GetFeature(counter)
    
    Set pPoly(counter) = pFeature.ShapeCopy()
    Set pGeomCol = pPoly(counter)
    numberOfPaths = numberOfPaths + pGeomCol.GeometryCount
    
  Next
  
 
  
  initializeArrays
  
  
  'Store Paths as unprocessed
  Dim pathCounter As Integer
  Dim parameterType As Integer
  Dim order As Integer
  pathCounter = 0
  
  For counter = 0 To featureCount - 1
    Set pGeomCol = pPoly(counter)
    
    Dim counter2 As Integer
    For counter2 = 0 To pGeomCol.GeometryCount - 1
      Set unprocessed(pathCounter) = New RiverSegment
      Set unprocessed(pathCounter).path = pGeomCol.Geometry(counter2)
      Set unprocessed(pathCounter).DEM = myDEM
      Set unprocessed(pathCounter).RiverNet = Me
      For parameterType = 0 To NumberOfPolylineParameterFields - 1
        If parameterType >= OrderDependentValuesBelow Then
           order = 1
        Else
           If processed(pathCounter) Is Nothing Then
              reRunCalcExecutionSequence = True
              order = 1
           Else
              order = processed(pathCounter).StrahlerOrdnung
           End If
        End If
        Dim parameterValue As Double
        parameterValue = -1
        If theParameterFieldIndex(parameterType) > -1 Then
           parameterValue = polylines.GetFeature(counter). _
                                     Value(theParameterFieldIndex(parameterType))
        End If
        If parameterValue = -1 And DefaultValue(parameterType, order) <> -1 Then
           parameterValue = DefaultValue(parameterType, order)
        End If
        If parameterValue <> -1 Then
           Select Case parameterType
           Case CriticalRain
               unprocessed(pathCounter).CriticalRainFall = parameterValue
           Case WidthToDepthRatio
               unprocessed(pathCounter).WidthToDepthRatio = parameterValue
           Case Strickler
               unprocessed(pathCounter).StricklerRoughness = parameterValue
           Case BankSlope
               unprocessed(pathCounter).ChannelBankSlope = parameterValue
           Case SurfaceWidth
               unprocessed(pathCounter).SealedSurfaceWidthParallelToChannel = parameterValue
           Case Connected
              If parameterValue = 0 Then
                 unprocessed(pathCounter).SealedAreasConnected = False
              Else
                 unprocessed(pathCounter).SealedAreasConnected = True
              End If
           
           Case SplitLength
              unprocessed(pathCounter).SplitLength = parameterValue
           End Select
        End If
      Next
      pathCounter = pathCounter + 1
    Next
  Next
  
  findReversedPolylines
  
  calcTopology currentSearchRadius

  If numOfOutflows() <> 1 Then
     showOutflows
     Err.Raise errTooManyOutflows, "RiverNet.initialize", _
         "more than one Outflow detected"
  End If

  riverNetInitialized = True
  riverNetCalculated = False
  
End Sub
Public Property Get topologySearchRadius() As Double
     topologySearchRadius = currentSearchRadius
End Property
Public Property Let topologySearchRadius(d As Double)
    If d < 0 Then
       Err.Raise vbObjectError, "RiverNet.setTopologySearchRadius", _
           "The radius must be > 0"
    End If
    currentSearchRadius = d
End Property
Public Static Property Get errorTooManyOutflows() As Long
     errorTooManyOutflows = errTooManyOutflows
End Property
Private Sub initializeArrays()
  ReDim nextUpstream(numberOfPaths - 1, 1 To numberOfPossibleUpstreams)
  ReDim nextDownstream(numberOfPaths - 1)
  ReDim unprocessed(numberOfPaths - 1)
  ReDim Preserve processed(numberOfPaths - 1)
  Dim counter1 As Integer
  Dim counter2 As Integer
  For counter1 = LBound(nextDownstream) To numberOfPaths - 1
      nextDownstream(counter1) = -1
      For counter2 = 1 To numberOfPossibleUpstreams
         nextUpstream(counter1, counter2) = -1
      Next
  Next
End Sub
Private Sub findReversedPolylines()
    
    
    
    Dim counter As Integer
    For counter = 0 To numberOfPaths - 1
         'Extract next path from Polyline
         Dim pPath As IPath
         Set pPath = unprocessed(counter).path
         'Extract Start and Ending point
         Dim fromPoint As IPoint
         Dim toPoint As IPoint
         Set fromPoint = pPath.fromPoint
         Set toPoint = pPath.toPoint
         'Extract height
         Dim startZ As Double
         Dim endZ As Double
         startZ = myDEM.Z(fromPoint.X, fromPoint.Y)
         endZ = myDEM.Z(toPoint.X, toPoint.Y)
         If startZ < endZ Then
            pathIsReversed pPath, counter
         End If
    Next
End Sub
Private Sub pathIsReversed(ByRef path As IPath, Number As Integer)
    Dim pCurve As ICurve
    Set pCurve = path
    
    pCurve.ReverseOrientation
    Set unprocessed(Number).path = pCurve
End Sub
Private Sub calcTopology(Optional tolerance As Double = 0)
    Dim counter As Integer
    Dim toCompare As Integer
    'Work through all Paths
    
    For counter = 0 To numberOfPaths - 1
      Dim fromPoint As IProximityOperator
      Set fromPoint = unprocessed(counter).fromPoint
      'Compare to every other Path
      For toCompare = 0 To numberOfPaths - 1
        If Not counter = toCompare Then
          Dim toPoint As IPoint
          Set toPoint = unprocessed(toCompare).toPoint
          'within tolerance
          If fromPoint.ReturnDistance(toPoint) <= tolerance Then
             'Bifurkations are not allowed
             If nextDownstream(toCompare) > 0 Then
                showPath unprocessed(toCompare).path
                Err.Raise vbObjectError, "RiverNet.calcTopology", _
                   "Two downstream segments found within a " & _
                   "distance of " & tolerance
             End If
             nextDownstream(toCompare) = counter
             If numberOfUpStreams(counter) = _
                numberOfPossibleUpstreams Then
                showPath unprocessed(counter).path
                Err.Raise vbObjectError, "RiverNet.calcTopology", _
                   "More than " & numberOfPossibleUpstreams & _
                   " upstream segments found within a " & _
                   "distance of " & tolerance
             End If
             nextUpstream(counter, _
                           numberOfUpStreams(counter) + 1) _
                           = toCompare
          End If
        End If
      Next
    Next
End Sub


Private Sub showPath(path As IPath)
  'aus HydrologicalModelling, HDButtonR.cls

  Dim pMxDoc As IMxDocument
  Dim pActView As IActiveView
  Set pMxDoc = Application.Document
  Set pActView = pMxDoc.ActiveView
    
  Dim m_Disp As IScreenDisplay
  Set m_Disp = pActView.ScreenDisplay
  
  Dim m_GraphCon As IGraphicsContainer
  Set m_GraphCon = pActView.GraphicsContainer
  
  ' define a color for both selected point and rain drop path
  Dim pColor1 As IRgbColor
  Set pColor1 = New RgbColor
  pColor1.Blue = 70
  pColor1.Red = 20
  pColor1.Green = 255
        
  
  'Define line symbol
  Dim pSymL As ISimpleLineSymbol
  Set pSymL = New SimpleLineSymbol
  With pSymL
    .Color = pColor1
    .Style = esriSLSSolid
    .Width = 2
  End With
  
  'Convert Path to Polyline
  Dim pPolyline As IPolyline
  Set pPolyline = New polyline
  Dim pGeomColl As IGeometryCollection
  Set pGeomColl = pPolyline
  pGeomColl.AddGeometry path
        
  'Create graphics and add it into map
  Dim pLineElem As IElement
  Set pLineElem = Util.CreateLineElement(pPolyline, esriSLSSolid, pColor1, 2)
  m_GraphCon.AddElement pLineElem, 0
  With m_Disp
    .ActiveCache = 0
    .StartDrawing m_Disp.hDC, 0
    .SetSymbol pSymL
     pLineElem.Draw m_Disp, Nothing
    .FinishDrawing
  End With

  Set pMxDoc = Nothing
  Set pActView = Nothing
  Set m_Disp = Nothing
  Set m_GraphCon = Nothing
  Set pSymL = Nothing
  Set pLineElem = Nothing

End Sub
Private Sub showOutflows()
  
  Dim pMxDoc As IMxDocument
  Dim pActView As IActiveView
  Set pMxDoc = Application.Document
  Set pActView = pMxDoc.ActiveView
    
  Dim m_Disp As IScreenDisplay
  Set m_Disp = pActView.ScreenDisplay
  
  Dim m_GraphCon As IGraphicsContainer
  Set m_GraphCon = pActView.GraphicsContainer
   
  ' define a color for both selected point and rain drop path
  Dim pColor1 As IRgbColor
  Set pColor1 = New RgbColor
  pColor1.Blue = 70
  pColor1.Red = 20
  pColor1.Green = 255
      
  
  'Define a maker symbol for the selected location
  Dim pSym As ISimpleMarkerSymbol
  Set pSym = New SimpleMarkerSymbol
  With pSym
   .Style = esriSMSCircle
   .Color = pColor1
   .Size = 1
  End With

  Dim counter As Integer
  For counter = 0 To numberOfPaths - 1
     If nextDownstream(counter) = -1 Then
        'Add a Marker to the map
        Dim pMarkerElement As IElement
        Set pMarkerElement = Util.CreateMarkerElement(unprocessed(counter).toPoint, pColor1, 6, esriSMSCircle)
        m_GraphCon.AddElement pMarkerElement, 0
        With m_Disp
          .ActiveCache = 0
          .StartDrawing m_Disp.hDC, 0
          .SetSymbol pSym
          pMarkerElement.Draw m_Disp, Nothing
          .FinishDrawing
        End With
     End If
  Next
   
  

  Set pMxDoc = Nothing
  Set pActView = Nothing
  Set m_Disp = Nothing
  Set m_GraphCon = Nothing
  Set pSym = Nothing
  Set pMarkerElement = Nothing

End Sub
Private Function numOfOutflows() As Integer
   Dim counter As Integer
   For counter = 0 To numberOfPaths - 1
     If nextDownstream(counter) = -1 Then
        numOfOutflows = numOfOutflows + 1
     End If
   Next
   
End Function

Private Sub allSpringsToQueue()

   Dim counter As Integer
   For counter = 0 To numberOfPaths - 1
     'Find a spring
     If nextUpstream(counter, 1) = -1 Then
        'Assign it order 1
        unprocessed(counter).StrahlerOrdnung = 1
        'Add to queue
        queue.Push (counter)
     End If
   Next
   
   
End Sub
Public Property Get ParameterTypeRainStationID() As Long
  ParameterTypeRainStationID = RainStationID

End Property

Public Property Get ParameterTypeSealedAreasConnected() As Long
  ParameterTypeSealedAreasConnected = Connected

End Property


Public Property Get ParameterTypeCriticalRain() As Long
  ParameterTypeCriticalRain = CriticalRain
  
End Property

Public Property Get ParameterTypeWidthToDepthRatio() As Long
  ParameterTypeWidthToDepthRatio = WidthToDepthRatio
 
End Property

Public Property Get ParameterTypeStrickler() As Long

  ParameterTypeStrickler = Strickler
 
End Property

Public Property Get ParameterTypeBankSlope() As Long
  ParameterTypeBankSlope = BankSlope

End Property

Public Property Get ParameterTypeSurfaceWidth() As Long
  
  ParameterTypeSurfaceWidth = SurfaceWidth
  
End Property
Public Property Get ParameterTypeSplitLength() As Long
  ParameterTypeSplitLength = SplitLength
End Property
Public Property Get ParameterFieldIndex(parameterType As Long) As Integer
  
  If parameterType < 0 Or parameterType >= NumberOfParameterFields Then
      Err.Raise vbObjectError, "RiverNet.getParameterFieldName", _
        "Invalid ParameterType"
  End If
  
  ParameterFieldIndex = theParameterFieldIndex(parameterType)
End Property
Public Property Let ParameterFieldIndex(parameterType As Long, index As Integer)
  
  If parameterType < 0 Or parameterType >= NumberOfParameterFields Then
      Err.Raise vbObjectError, "RiverNet.setParameterFieldName", _
        "Invalid ParameterType"
  End If
  
  Dim oldID As Long
  
  oldID = theParameterFieldIndex(parameterType)
  
  Dim FeatureClass As IFeatureClass
  Set FeatureClass = getFeatureClass(parameterType)
  
  If FeatureClass Is Nothing Then
     Err.Raise vbObjectError, "RiverNet.setParameterFieldName", _
        "featureClass needs to be set before assining FieldNames for parameters"
  End If
  
  
  If index >= FeatureClass.Fields.FieldCount Then
     Err.Raise vbObjectError, "RiverNet.setParameterFieldIndex", _
        "featureClass has only " & FeatureClass.Fields.FieldCount & _
        " attributes. Unable to set ParameterFieldIndex to " & _
        index
  End If

  theParameterFieldIndex(parameterType) = index
  
  If oldID <> theParameterFieldIndex(parameterType) And FeatureClass Is polylines Then
     reinitializeRiverNet True
  End If

End Property
Private Function getFeatureClass(parameterType As Long) As IFeatureClass

  If parameterType < 0 Or parameterType >= NumberOfParameterFields Then
      Err.Raise vbObjectError, "RiverNet.getFeatureClass", _
        "Invalid ParameterType"
  End If
  
  Select Case parameterType
  Case ParameterTypeSealedAreasConnected, _
       ParameterTypeCriticalRain, _
       ParameterTypeWidthToDepthRatio, _
       ParameterTypeStrickler, _
       ParameterTypeBankSlope, _
       ParameterTypeSurfaceWidth, _
       ParameterTypeSplitLength
       
       Set getFeatureClass = polylines
  Case ParameterTypeRainStationID
    
       Set getFeatureClass = RainstationPolygons
  Case Else
        Err.Raise vbObjectError, "RiverNet.getFeatureClass", _
        "Invalid ParameterType"
  End Select
  
End Function
Public Property Let ParameterFieldName(parameterType As Long, Name As String)
  
  Dim FeatureClass As IFeatureClass
  Set FeatureClass = getFeatureClass(parameterType)
  
  
  If FeatureClass Is Nothing Then
     Err.Raise vbObjectError, "RiverNet.setParameterFieldName", _
        "featureClass needs to be set before assining FieldNames for parameters"
  End If
  
  'FindField returns -1 if the Name was not found == consistent
  ParameterFieldIndex(parameterType) = FeatureClass.FindField(Name)

End Property

Public Property Get ParameterFieldName(parameterType As Long) As String
  If parameterType < 0 Or parameterType >= NumberOfParameterFields Then
      Err.Raise vbObjectError, "RiverNet.getParameterFieldName", _
        "Invalid ParameterType"
  End If
  
  Dim FeatureClass As IFeatureClass
  Set FeatureClass = getFeatureClass(parameterType)
  
  If FeatureClass Is Nothing Then
     Err.Raise vbObjectError, "RiverNet.getParameterFieldName", _
        "featureClass needs to be set before retrieving FieldNames for parameters"
  End If
  If theParameterFieldIndex(parameterType) > -1 Then
    ParameterFieldName = FeatureClass.Fields.Field(theParameterFieldIndex(parameterType)).Name
  End If
  
End Property

Public Property Get DefaultParameterValue(parameterType As Long, Optional StrahlerOrder As Integer = -1) As Double
  
  If parameterType < 0 Or parameterType >= NumberOfParameterFields Then
      Err.Raise vbObjectError, "RiverNet.getParameterFieldName", _
        "Invalid ParameterType"
  End If
  If OrderDependentValuesBelow <= parameterType And StrahlerOrder <> -1 Then
    Err.Raise vbObjectError, "RiverNet.getDefaultParameterValue", _
        "Parameter is not dependend on StrahlerOrder. " & _
        "Do not provide Strahler Order when calling method"
  End If
  If OrderDependentValuesBelow > parameterType And StrahlerOrder = -1 Then
    Err.Raise vbObjectError, "RiverNet.getDefaultParameterValue", _
        "Parameter is dependend on StrahlerOrder. " & _
        "Please provide Strahler Order when calling method"
  End If
  
  Dim order As Long
  If StrahlerOrder = -1 Then
     order = 1
  Else
     order = StrahlerOrder
  End If
  
  DefaultParameterValue = DefaultValue(parameterType, order)
End Property
Public Property Let DefaultParameterValue(parameterType As Long, Optional StrahlerOrder As Integer = -1, Value As Double)
  If parameterType < 0 Or parameterType >= NumberOfParameterFields Then
      Err.Raise vbObjectError, "RiverNet.getParameterFieldName", _
        "Invalid ParameterType"
  End If
    If OrderDependentValuesBelow <= parameterType And StrahlerOrder <> -1 Then
    Err.Raise vbObjectError, "RiverNet.getDefaultParameterValue", _
        "Parameter is not dependend on StrahlerOrder. " & _
        "Do not provide Strahler Order when calling method"
  End If
  If OrderDependentValuesBelow > parameterType And StrahlerOrder = -1 Then
    Err.Raise vbObjectError, "RiverNet.getDefaultParameterValue", _
        "Parameter is dependend on StrahlerOrder. " & _
        "Please provide Strahler Order when calling method"
  End If
  
  Select Case parameterType
     Case CriticalRain
          testValue Value, positiveValue
     Case WidthToDepthRatio
          testValue Value, positiveValue
     Case Strickler
          testValue Value, positiveValue
     Case BankSlope
          testValue Value, positiveValue
     Case SurfaceWidth
          testValue Value, positiveOrZeroValue
     Case Connected
          testValue Value, booleanValue
     Case SplitLength
          testValue Value, positiveValue
     Case ParameterTypeRainStationID
          Value = Int(Value)
  End Select
  
  Dim order As Long
  If StrahlerOrder = -1 Then
     order = 1
  Else
     order = StrahlerOrder
  End If

  If (DefaultValue(parameterType, order) <> Value) Then
    DefaultValue(parameterType, order) = Value
    reinitializeRiverNet True
  End If
  
End Property

Private Sub Class_Initialize()
  Dim counter As Long
  Dim counter2 As Long
  For counter = 0 To NumberOfParameterFields - 1
     For counter2 = 1 To allowableStrahlerOrder - 1
        DefaultValue(counter, counter2) = -1
     Next
  Next
End Sub

Private Sub reinitializeRiverNet(Optional deleteProcessed = False)
  riverNetInitialized = False
  riverNetCalculated = False
  isSlopeConnected = False
  If deleteProcessed Then
      ReDim processed(1)
  End If

End Sub
