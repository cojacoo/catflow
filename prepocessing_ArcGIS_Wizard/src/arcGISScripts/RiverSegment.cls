VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "RiverSegment"
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

Private strahlerOrdn As Integer
Private pPath As IPath
Private pointCollection() As RiverPoint
Private myDEM As IFunctionalSurface
Private dblSplitLength As Double
Private theNet As RiverNet

Private Const defaultSplitLength As Double = 20
'Default values from Weiherbach
'Thomas Maurer, Physikalisch begründete zeitkontinuierliche Modellierung des Wassertransports in kleinen ländlichen
'               Einzugsgebieten, Institut für Hydrologie und Wasserwirtschaft, Heft 61, Karlsruhe 1997, p121
Private Const defaultStricklerRoughnessOrder1 As Double = 10
Private Const defaultStricklerRoughnessOrder2 As Double = 15
Private Const defaultStricklerRoughnessOrder3 As Double = 20
Private Const defaultStricklerRoughnessOrder4 As Double = 20
Private Const defaultChannelBankSlopeOrder1 As Double = 8
Private Const defaultChannelBankSlopeOrder2 As Double = 2
Private Const defaultChannelBankSlopeOrder3 As Double = 1.5
Private Const defaultChannelBankSlopeOrder4 As Double = 1
Private Const defaultWidthToDepthRatioOrder1 As Double = 0.1
Private Const defaultWidthToDepthRatioOrder2 As Double = 0.4
Private Const defaultWidthToDepthRatioOrder3 As Double = 0.6
Private Const defaultWidthToDepthRatioOrder4 As Double = 0.8
Private Const defaultCriticalRainFallOrder1 As Double = 25
Private Const defaultCriticalRainFallOrder2 As Double = 20
Private Const defaultCriticalRainFallOrder3 As Double = 15
Private Const defaultCriticalRainFallOrder4 As Double = 10


'Indicates whether DEM is available
Private useDEM As Boolean

'for output
Private myXRef As Double
Private myYRef As Double
Private sealed As Integer
Private rough As Double
Private cbs As Integer
Private wdr As Double
Private crf As Double
Private SurfaceWidth As Double

Public Property Get SealedAreasConnected() As Boolean
  If sealed = 1 Then SealedAreasConnected = True
End Property

Public Property Let SealedAreasConnected(b As Boolean)
  sealed = 0
  If b Then sealed = 1
End Property


Public Sub connectSlope(s As slope, PointID As Integer)

   testPointAvailability

  If (PointID < firstPointID) _
    Or (PointID > lastPointID) _
    Then
    Err.Raise vbObjectError, "RiverSegment.connectSlope", _
     "Invalid pointID is outside ID range for this RiverSegment"
  End If
  
  
  
  If pointCollection(PointID).slope Is Nothing Then
     Set pointCollection(PointID).slope = s
  Else
    Err.Raise vbObjectError, "RiverSegment.connectSlope", _
        "River net point with ID " & PointID & " is allready connected " & _
        "to slope " & pointCollection(PointID).slope.ID & _
        "Can not connect slope number " & s.ID & _
        ". Probably, two slopes are reaching the river at the " & _
        "same point. Either move one slope line or set the split " & _
        "length for the corresponding river stretch smaller."
  End If
     
End Sub

Public Sub toCatflow(outStream As TextStream)
  Dim counter As Integer
  For counter = LBound(pointCollection) To UBound(pointCollection) - 1
     pointCollection(counter).CatflowParameterOutput outStream
  Next
End Sub
'Returns the end number
Public Function assignNumbers(start As Integer, lastRiverPoint() As RiverPoint) As Integer
    If pPath Is Nothing Then
       Err.Raise vbObjectError, "RiverSegment.assignNumbers", _
            "Set valid path first"
    End If
    
    If myDEM Is Nothing Then
       useDEM = False
    End If
    
    If strahlerOrdn = 0 Then
       strahlerOrdn = 1
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
    
    numberOfPoints = positiveRoundUp(pPath.Length / SplitLength)
    ReDim pointCollection(start To start + numberOfPoints)
    pointCount = 0
    
    Dim segmentCollection As ISegmentCollection
    Dim theSegments As IEnumSegment
    Set segmentCollection = pPath
    Set theSegments = segmentCollection.EnumSegments
    
    
    theSegments.Reset
    
    Dim currentSegment As ISegment
    Dim partIndex As Long
    Dim segmentIndex As Long
    theSegments.Next currentSegment, partIndex, segmentIndex
    If Not partIndex = 0 Then
       Err.Raise vbObjectError, "RiverSegment.assignNumbers", "The line is " & _
              "not a single path as expected. Either, there are missing connections " & _
              "between parts of the line or the line splits at some point"
    End If
       
    Do While Not currentSegment Is Nothing
        
        '
        ' Work out the necessary size of the array.
        '
        Dim dblLength As Double
        dblLength = currentSegment.Length()
        If (pointCount = 0 And dblLength < SplitLength) Then
            dblOffset = SplitLength - dblLength
            addPoint currentSegment.fromPoint(), pointCount + start, lastRiverPoint(), pointCollection()
            pointCount = pointCount + 1
            GoTo nextSegment
        End If
        If (dblLength < dblOffset) Then
            dblOffset = dblOffset - dblLength
            GoTo nextSegment
        End If
        Dim dblArraySize As Double
        If boolAsRatio = True Then
          dblArraySize = (1 - dblOffset) / SplitLength
        Else
          dblArraySize = (dblLength - dblOffset) / SplitLength
        End If
        '
        ' Set the size of the array. This should be the calculated number of
        ' segments ROUNDED UP - because the array should contain a segment to
        ' hold the end segment, which is a fraction of the split length.
        '
        Dim pSegments() As ISegment
        ReDim pSegments(positiveRoundUp(dblArraySize))
        
        Dim lngNumSegs As Long
        currentSegment.SplitDivideLength dblOffset, SplitLength, boolAsRatio, lngNumSegs, pSegments(0)
        
        
        
        Dim i As Long
        
        For i = 0 To (lngNumSegs - 1)
          'Assign coordinates to Slopepoints
          If (pointCount > 0 And i = 0) Then
               'Do not use starting points of each segment
               i = 1
          End If
          'If just one point in the segment, this is the
          'starting point from above and should therefore
          'not be used
          If i <= lngNumSegs - 1 Then
             addPoint pSegments(i).fromPoint, pointCount + start, lastRiverPoint(), pointCollection()
             pointCount = pointCount + 1
          End If
        Next i
        dblOffset = (SplitLength - pSegments(lngNumSegs - 1).Length)
nextSegment:
        theSegments.Next currentSegment, partIndex, segmentIndex
        If Not partIndex = 0 Then
            Err.Raise vbObjectError, "Slope.splitFallLine", "The slope fall line is " & _
              "not a single path as expected. Either, there are missing connections " & _
              "between parts of the line or the line splits at some point"
        End If
    Loop
    
    'gColl.RemoveGeometries gColl.GeometryCount - 1, 1
       
    
    assignNumbers = pointCount + start
    
    'Make sure that no nothing-entries occur, if UBound is called
    
    'It seems that ReDim shouldn't use LBound to UBount-1
    '(error on April 11th with riverpoint below outflow)
    
    ReDim Preserve pointCollection(start To assignNumbers)
    
    ReDim slopes(start To assignNumbers)
    
End Function
Private Sub addPoint(Point As IPoint, ID As Integer, previous() As RiverPoint, gColl() As RiverPoint)

    Dim rPoint As RiverPoint
    Set rPoint = New RiverPoint
    rPoint.X = Point.X
    rPoint.Y = Point.Y
    If useDEM Then
       rPoint.Z = myDEM.Z(Point.X, Point.Y)
    End If
    rPoint.ID = ID
    rPoint.order = strahlerOrdn
    Set rPoint.RiverSegment = Me
    Set rPoint.RiverNet = Me.RiverNet
    Dim counter As Integer
    For counter = LBound(previous) To UBound(previous) - 1
      If Not previous(counter) Is Nothing Then
        rPoint.AddUpstreamRiverPoint previous(counter)
        Set previous(counter).DownstreamRiverPoint = rPoint
        Set previous(counter) = Nothing
      End If
    Next
    Set gColl(ID) = rPoint
    Set previous(LBound(previous)) = rPoint
End Sub
Public Property Get SplitLength() As Double
   If dblSplitLength = 0 Then
       dblSplitLength = defaultSplitLength
   End If
   SplitLength = dblSplitLength
End Property
Public Property Let SplitLength(s As Double)
   If s <= 0 Then
     Err.Raise vbObjectError, "RiverSegment.setSplitLength", _
            "Splitlength must be greater than 0"
   End If
   dblSplitLength = s
End Property
Public Property Get DEM() As IFunctionalSurface
   Set DEM = myDEM
End Property
Public Property Set DEM(d As IFunctionalSurface)
   If d Is Nothing Then
       Err.Raise vbObjectError, "RiverSegment.setDEM", _
            "DEM must not be nothing"
    End If
   Set myDEM = d
   useDEM = True
End Property
Public Property Get allPoints() As Multipoint
    testPointAvailability
    
    Set allPoints = New Multipoint
    Dim pGeometryCollection As IGeometryCollection
    Set pGeometryCollection = allPoints
    
    Dim counter As Integer
    For counter = LBound(pointCollection) To UBound(pointCollection) - 1
      Dim nextPoint As IPoint
      Set nextPoint = pointCollection(counter).IPoint()
      pGeometryCollection.AddGeometry nextPoint
    Next
    
    
End Property
Public Property Get firstPointID() As Integer
   testPointAvailability
    firstPointID = LBound(pointCollection)
End Property
Private Sub testPointAvailability()

    If pPath Is Nothing Then
       Err.Raise vbObjectError, "RiverSegment.getAllPoints", _
            "Set valid path first"
    End If
    If UBound(pointCollection) = 0 Then
       ReDim a(1) As RiverPoint
       assignNumbers 0, a
    End If
    
End Sub
Public Property Get lastPointID() As Integer
    testPointAvailability
    lastPointID = UBound(pointCollection) - 1
End Property
Public Property Get lastRiverPoint() As RiverPoint
    testPointAvailability
    Set lastRiverPoint = pointCollection(lastPointID)
End Property
Public Property Get fromPoint() As IPoint
    If pPath Is Nothing Then
       Err.Raise vbObjectError, "RiverSegment.getFromPoint", _
            "Set valid path first"
    End If
    Set fromPoint = pPath.fromPoint
End Property
Public Property Get toPoint() As IPoint
    If pPath Is Nothing Then
       Err.Raise vbObjectError, "RiverSegment.getToPoint", _
            "Set valid path first"
    End If
    Set toPoint = pPath.toPoint
End Property

Public Property Get path() As IPath
    Set path = pPath
End Property
Public Property Set path(path As IPath)
  If path Is Nothing Then
    Err.Raise vbObjectError, "RiverSegment Property Set path", _
               "Path must not be nothing"
  End If
  Set pPath = path
  ReDim pointCollection(0 To 0)
End Property
Public Property Get StrahlerOrdnung() As Integer
   StrahlerOrdnung = strahlerOrdn
End Property

Public Property Let StrahlerOrdnung(Ordnung As Integer)
  If Ordnung < 1 Then
     Err.Raise vbObjectError, "RiverSegment Property Let StrahlerOrder", _
               "Strahler order must be greater than 0"
     
  End If
  strahlerOrdn = Ordnung
End Property


Public Property Let SealedSurfaceWidthParallelToChannel(s As Double)
  If s < 0 Then
    Err.Raise vbObjectError, "RiverSegment.setSealedSurfaceWidth", "Width must be >=0"
  End If
  SurfaceWidth = s
End Property
Public Property Get SealedSurfaceWidthParallelToChannel() As Double
  SealedSurfaceWidthParallelToChannel = SurfaceWidth
End Property
Public Property Get CriticalRainFall() As Double
  If crf = 0 Then
     Select Case StrahlerOrdnung
     Case 1
       crf = defaultCriticalRainFallOrder1
     Case 2
       crf = defaultCriticalRainFallOrder2
     Case 3
       crf = defaultCriticalRainFallOrder3
     Case 4
       crf = defaultCriticalRainFallOrder4
     Case Else
       Err.Raise vbObjectError, "RiverSegment.getCriticalRainFall", "Critical rain fall not set and no default value available"
     End Select
   End If
  CriticalRainFall = crf
End Property
Public Property Let CriticalRainFall(r As Double)
  If r <= 0 Then
    Err.Raise vbObjectError, "RiverSegment.setCriticalRainFall", "Critical Rainfall must be > 0"
  End If
  crf = r
End Property
Public Property Get WidthToDepthRatio() As Double
   If wdr = 0 Then
     Select Case StrahlerOrdnung
     Case 1
       wdr = defaultWidthToDepthRatioOrder1
     Case 2
       wdr = defaultWidthToDepthRatioOrder2
     Case 3
       wdr = defaultWidthToDepthRatioOrder3
     Case 4
       wdr = defaultWidthToDepthRatioOrder4
     Case Else
       Err.Raise vbObjectError, "RiverSegment.getWidthToDepthRatio", "Ratio not set and no default value available"
     End Select
   End If
   WidthToDepthRatio = wdr
End Property
Public Property Let WidthToDepthRatio(r As Double)
  If r <= 0 Then
    Err.Raise vbObjectError, "RiverSegment.setWidthToDepthRatio", "Ratio must be > 0"
  End If
  wdr = r
End Property
Public Property Let ChannelBankSlope(s As Integer)
  If s <= 0 Then
    Err.Raise vbObjectError, "RiverSegment.setChannelBankSlope", "Slope must be > 0"
  End If
  cbs = s
End Property
Public Property Get ChannelBankSlope() As Integer
   If cbs = 0 Then
     Select Case StrahlerOrdnung
     Case 1
       cbs = defaultChannelBankSlopeOrder1
     Case 2
       cbs = defaultChannelBankSlopeOrder2
     Case 3
       cbs = defaultChannelBankSlopeOrder3
     Case 4
       cbs = defaultChannelBankSlopeOrder4
     Case Else
       Err.Raise vbObjectError, "RiverSegment.getChannelBankSlope", "Slope not set and no default value available"
     End Select
   End If
   ChannelBankSlope = cbs
End Property
Public Property Let StricklerRoughness(s As Double)
  If s < 0 Then
     Err.Raise vbObjectError, "RiverSegment.setStricklerRoughness", "Roughness must be > 0"
  End If
  
  rough = s

End Property
Public Property Get StricklerRoughness() As Double
   If rough = 0 Then
     Select Case StrahlerOrdnung
     Case 1
       rough = defaultStricklerRoughnessOrder1
     Case 2
       rough = defaultStricklerRoughnessOrder2
     Case 3
       rough = defaultStricklerRoughnessOrder3
     Case 4
       rough = defaultStricklerRoughnessOrder4
     Case Else
       Err.Raise vbObjectError, "RiverSegment.getStricklerRoughness", "Roughness not set and no default value available"
     End Select
   End If
   StricklerRoughness = rough
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
Public Property Set RiverNet(r As RiverNet)
  If r Is Nothing Then
    Err.Raise vbObjectError, "RiverPoint.setRiverNet", "RiverNet must not be nothing"
  End If
  Set theNet = r
End Property
Public Property Get RiverNet() As RiverNet
  Set RiverNet = theNet
End Property
