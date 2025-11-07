VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} frmProcessSlopes 
   Caption         =   "Process Slopes"
   ClientHeight    =   6645
   ClientLeft      =   45
   ClientTop       =   330
   ClientWidth     =   8850
   OleObjectBlob   =   "frmProcessSlopes.frx":0000
   StartUpPosition =   1  'CenterOwner
End
Attribute VB_Name = "frmProcessSlopes"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'This form is part of the catflow wizard.
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

'
' This is the document we are working with
Private m_pMxDoc As IMxDocument
'
' This is the focus map on the document
Private m_pMap As IMap
'
'
' This is the layer selected in the list box
Private m_pSelectedLineFeatureClass As IFeatureClass
Private m_pSelectedPolygonFeatureClass As IFeatureClass
Private m_pSelectedRasterLayer As IRasterLayer
Private m_pSelectedRivernetFeatureClass As IFeatureClass
Private m_pSelectedRainStationFeatureClass As IFeatureClass


'Containers for results
Private fc_point As IFeatureClass
Private fc_poly As IFeatureClass
Private fc_rivernet As IFeatureClass
Private riverTextStream As TextStream
Private slopeTextStream As TextStream
'
' This are the lists of layer indicies in the map and is accessed by the
' list control index on the form
Private m_LineLayerIndexLookup() As Long
Private m_PolygonLayerIndexLookup() As Long
Private m_RasterLayerIndexLookup() As Long
Private m_RivernetIndexLookup() As Long
Private m_RiverSplitFieldIndexLookup() As Long
Private m_RainStationLayerIndexLookup() As Long
Private m_RainStationAttributeLookup() As Long
Private m_CritRainLookup() As Long
Private m_ConnectedLookup() As Long
Private m_WtDLookup() As Long
Private m_StricklerLookup() As Long
Private m_BankSlopeLookup() As Long
Private m_SurfWidthLookup() As Long
Private m_ShapeFieldLookup() As Long
Private m_ThicknessFieldLookup() As Long
Private m_SlopeSplitFieldLookup() As Long
  
  


' This are the selected attribute field numbers
Private m_pSelectedLineIDFieldIndex As Long
Private m_pSelectedPolygonIDFieldIndex As Long
Private m_pSelectedRiverSplitLenghtFieldIndex As Long
Private m_pSelectedRainStationFieldIndex As Long
Private m_pCritRainIndex As Long
Private m_pConnectedIndex As Long
Private m_pWtDIndex As Long
Private m_pStricklerIndex As Long
Private m_pBankSlopeIndex As Long
Private m_pSurfWidthIndex As Long
Private m_pShapeFieldIndex As Long
Private m_pThicknessFieldIndex As Long
Private m_pSlopeSplitFieldIndex As Long

' Indicates the selected way of providing rain station id valuse
Private prevRainStationMode As String

' This is the selected Surface from the RasterLayer
Private m_pSelectedRasterSurface As IRasterSurface

' This are the list of field indicies in the line and polygon
' layer and are accessed by the
' list control index on the form
Private m_LineFieldIndexLookup() As Long
Private m_PolygonFieldIndexLookup() As Long


'For manipulating Subwaymap
Private curStep As String
Private Const stepIntro As Integer = 0
Private Const stepRiverNet As Integer = 1
Private Const stepRiverParam As Integer = 2
Private Const stepSlopeTheme As Integer = 3
Private Const stepSlopeParam As Integer = 4
Private Const stepSlopeCoord As Integer = 5
Private Const stepFinish As Integer = 6

'For calling help
Private helpPart(stepFinish) As String



'Arrays of Field Types
Private integerTypes(0 To 1) As esriFieldType
Private floatTypes(0 To 1) As esriFieldType

'Contain the preprocessing objects
Private myRiverNet As RiverNet
Private Slopes() As Slope

'Various values to be stored
Private x_reference As Double
Private y_reference As Double
Private z_reference As Double
Private theSlopeSplitLength As Double
Private Const defaultSlopeSplitDefault As Double = 20
Private theRiverSplitLength As Double
Private Const defaultRiverSplitLength As Double = 20
Private theSlopeThickness As Double
Private Const defaultSlopeThickness As Double = 5

'These contain lists for eta and xsi
Private EtaValues() As Double
Private XsiValues() As Double
Private NumberOfEtaValues As Integer
Private NumberOfXsiValues As Integer

'Values for StrahlerOrder dependend parameters
Private maxStrahlerOrder As Long
Private theCriticalRain() As Double
Private theWidthToDepthRatio() As Double
Private theStrickler() As Double
Private theBankSlope() As Double
Private theSurfaceWidth() As Double
Private theConnected() As Boolean

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


'Control Program flow (do not process data if this happened before)
Private slopesProcessed As Boolean
Private riverNetProcessed As Boolean

' Populates the provided list control with polygon layer names and
' updates the lookup array
Private Sub InitialiseWithShapeLayers(theControl As Variant, theArray() As Long, theShapeType As esriShapeType, Optional selectionRequired As Boolean = True)
Dim pLayer As ILayer
Dim layerIndex As Long

  ' Clear out any existing entries from the list
  theControl.Clear
  
  ' Exit staight away if there are no layers
  If m_pMap.LayerCount = 0 Then Exit Sub
  
  ' Make sure the layer lookup is big enough
  ReDim theArray(0 To m_pMap.LayerCount - 1)
  
  'Add no selection option
  If Not selectionRequired Then
      theControl.AddItem "***none***"
      theArray(theControl.ListCount - 1) = -1
  End If

  ' Look for the raster layers and add their names to the list box
  For layerIndex = 0 To m_pMap.LayerCount - 1
  
    ' get a pointer to the layer, it could be any type of layer
    Set pLayer = m_pMap.Layer(layerIndex)
      
    If TypeOf pLayer Is IGeoFeatureLayer Then
    
      Dim fl As IGeoFeatureLayer
      Set fl = pLayer
      Dim pFeatureClass As IFeatureClass
      Set pFeatureClass = fl.FeatureClass
      
      If Not (pFeatureClass Is Nothing) Then
        If pFeatureClass.ShapeType = theShapeType Then
          ' Add the layer name to the list
          theControl.AddItem pLayer.Name
        
          ' Update our lookup array which takes the index into the listbox and returns
          ' the layer number in the layer collection off the IMap
          theArray(theControl.ListCount - 1) = layerIndex
        End If
      End If
    End If
    
  Next layerIndex
  

End Sub

' Populates the provided list control with raster layer names and
' updates the lookup array
Private Sub InitialiseWithRasterLayers(theControl As Variant, theArray() As Long)
Dim pLayer As ILayer
Dim layerIndex As Long

  ' Clear out any existing entries from the list
  theControl.Clear
  
  ' Exit staight away if there are no layers
  If m_pMap.LayerCount = 0 Then Exit Sub
  
  ' Make sure the layer lookup is big enough
  ReDim theArray(0 To m_pMap.LayerCount - 1)

  ' Look for the raster layers and add their names to the list box
  For layerIndex = 0 To m_pMap.LayerCount - 1
  
    ' get a pointer to the layer, it could be any type of layer
    Set pLayer = m_pMap.Layer(layerIndex)
      
    If TypeOf pLayer Is IRasterLayer Then
      ' Add the layer name to the list
      theControl.AddItem pLayer.Name
      ' Update our lookup array which takes the index into the listbox and returns
      ' the layer number in the layer collection off the IMap
      theArray(theControl.ListCount - 1) = layerIndex
    End If
    
  Next layerIndex
  

End Sub

Private Sub initializeStrahlerParameters()

ReDim theStrickler(maxStrahlerOrder)
ReDim theBankSlope(maxStrahlerOrder)
ReDim theWidthToDepthRatio(maxStrahlerOrder)
ReDim theSurfaceWidth(maxStrahlerOrder)
ReDim theCriticalRain(maxStrahlerOrder)
ReDim theConnected(maxStrahlerOrder)

If maxStrahlerOrder >= 1 Then
   theStrickler(1) = defaultStricklerRoughnessOrder1
   theBankSlope(1) = defaultChannelBankSlopeOrder1
   theWidthToDepthRatio(1) = defaultWidthToDepthRatioOrder1
   theCriticalRain(1) = defaultCriticalRainFallOrder1
   theConnected(1) = False
End If

If maxStrahlerOrder >= 2 Then
   theStrickler(2) = defaultStricklerRoughnessOrder2
   theBankSlope(2) = defaultChannelBankSlopeOrder2
   theWidthToDepthRatio(2) = defaultWidthToDepthRatioOrder2
   theCriticalRain(2) = defaultCriticalRainFallOrder2
   theConnected(2) = False
End If
If maxStrahlerOrder >= 3 Then
   theStrickler(3) = defaultStricklerRoughnessOrder3
   theBankSlope(3) = defaultChannelBankSlopeOrder3
   theWidthToDepthRatio(3) = defaultWidthToDepthRatioOrder3
   theCriticalRain(3) = defaultCriticalRainFallOrder3
   theConnected(3) = False
End If
If maxStrahlerOrder >= 4 Then
   theStrickler(4) = defaultStricklerRoughnessOrder4
   theBankSlope(4) = defaultChannelBankSlopeOrder4
   theWidthToDepthRatio(4) = defaultWidthToDepthRatioOrder4
   theCriticalRain(4) = defaultCriticalRainFallOrder4
   theConnected(4) = False
End If
Dim i As Integer
i = 5
Do While i <= maxStrahlerOrder
   theStrickler(i) = defaultStricklerRoughnessOrder4
   theBankSlope(i) = defaultChannelBankSlopeOrder4
   theWidthToDepthRatio(i) = defaultWidthToDepthRatioOrder4
   theCriticalRain(i) = defaultCriticalRainFallOrder4
   theConnected(i) = False
   i = i + 1
Loop

cbxOrder.Clear
For i = 1 To maxStrahlerOrder
   cbxOrder.AddItem i
Next

cbxOrder.Value = 1

End Sub
Private Sub setupcbxDefaultGridShape()
   'theSlopeShapeTypeConstantThickness  = 1
   'theSlopeShapeTypeCakeShape = 2
   
   cbxDefaultGridShape.AddItem "ConstantThickness"
   cbxDefaultGridShape.AddItem "CakeShape"
   cbxDefaultGridShape.ListIndex = 0
End Sub
Private Sub setupcbxOrder()
  Dim order As Integer
  order = cbxOrder.ListIndex + 1
  If order = 0 Then
    Strickler.Enabled = False
    Connected.Enabled = False
    WtD.Enabled = False
    BankSlope.Enabled = False
    CritRain.Enabled = False
    Exit Sub
  End If
  
    Strickler.Enabled = True
    Connected.Enabled = True
    WtD.Enabled = True
    BankSlope.Enabled = True
    CritRain.Enabled = True
  
  Strickler = theStrickler(order)
  Connected = theConnected(order)
  BankSlope = theBankSlope(order)
  WtD = theWidthToDepthRatio(order)
  CritRain = theCriticalRain(order)
    
End Sub

Private Function ProcessSlopes() As Boolean
  
  
  ProcessSlopes = False
  Me.MousePointer = fmMousePointerHourGlass
  'How many Features are available?
  Dim numLines As Integer
  Dim numPolygons As Integer
  numLines = m_pSelectedLineFeatureClass.featureCount(Nothing)
  numPolygons = m_pSelectedPolygonFeatureClass.featureCount(Nothing)
  
  If numLines <> numPolygons Then
       MsgBox "Line and Polygon theme must contain same number of " & Chr(13) & _
              "Features. At the moment, the line theme contains " & Chr(13) & _
              numLines & " while the polygon theme contains " & _
              numPolygons & " features."
       Me.MousePointer = fmMousePointerDefault
       Exit Function
       
  End If
       
  
  'Genereate place to store features
  ReDim lines(1 To numLines) As IPath
  ReDim polygons(1 To numPolygons) As IPolygon
  
  'Sort Lines into Array according to ID
  Dim counter As Integer
  Dim feature As IFeature
  Dim ID As Integer
  
  For counter = 1 To numLines
      'Get the line and the ID
      Set feature = m_pSelectedLineFeatureClass.GetFeature(counter - 1)
      ID = feature.Value(m_pSelectedLineIDFieldIndex)
      
      'Is the ID outside the ArrayBoundary?
      If ID < LBound(lines) Then
          MsgBox "Line with ID " & ID & " has an Illegal ID. " & _
             "IDs must be greater than 0."
          Me.MousePointer = fmMousePointerDefault
          Exit Function
      End If
      If ID > UBound(lines) Then
          MsgBox "Line with ID " & ID & " has an Illegal ID. " & _
             "IDs must be in ascending order without gap, starting " & _
             "from 0. With " & numLines & " lines, the maximum possible" & _
             "ID is then " & numLines - 1
          Me.MousePointer = fmMousePointerDefault
          Exit Function
      End If
      'Does another feature exist with the same ID
      If Not (lines(ID) Is Nothing) Then
          MsgBox "Line with ID " & ID & " exists twice."
          Me.MousePointer = fmMousePointerDefault
          Exit Function
      End If
      'Is Polyline a path?
      Dim pGeometryCollection As IGeometryCollection
      Set pGeometryCollection = feature.ShapeCopy
      If Not pGeometryCollection.GeometryCount = 1 Then
          MsgBox "The line feature wit ID " & ID & " does not consist of a single, " & _
                 "connected path. Please check for missing connections " & _
                 "and points where the line splits."
          Me.MousePointer = fmMousePointerDefault
          Exit Function
       End If
       Set lines(ID) = pGeometryCollection.Geometry(0)
  Next
  
  'Sort polygons into Array according to ID
  For counter = 1 To numPolygons
      'Get the Polygon and the ID
      Set feature = m_pSelectedPolygonFeatureClass.GetFeature(counter - 1)
      ID = feature.Value(m_pSelectedPolygonIDFieldIndex)
      
      'Is the ID outside the ArrayBoundary?
      If ID < LBound(polygons) Then
          MsgBox "Polygon with ID " & ID & " has an Illegal ID. " & _
             "IDs must be greater than 0."
          Me.MousePointer = fmMousePointerDefault
          Exit Function
      End If
      If ID > UBound(polygons) Then
          MsgBox "Polygon with ID " & ID & " has an Illegal ID. " & _
             "IDs must be in ascending order without gap, starting " & _
             "from 0. With " & numPolygons & " Polygons, the maximum possible" & _
             "ID is then " & numPolygons - 1
          Me.MousePointer = fmMousePointerDefault
          Exit Function
      End If
      'Does another feature exist with the same ID
      If Not (polygons(ID) Is Nothing) Then
          MsgBox "Polygon with ID " & ID & " exists twice."
          Me.MousePointer = fmMousePointerDefault
          Exit Function
      End If
      
      Set polygons(ID) = feature.ShapeCopy
  Next
  
  'Now all places in Arrays are filled
  
  'Create shp for Results
  
  Dim idFieldName As String
  Dim widthFieldName As String
  Dim areaFieldName As String
  
  idFieldName = "SP_ID"
  widthFieldName = "Width"
  areaFieldName = "Area"
  
  Do While (fc_point Is Nothing)
         Set fc_point = CreateShapefile("Save Splitt Points as", _
                           esriGeometryPoint, _
                           idFieldName, _
                           esriFieldTypeInteger, _
                           widthFieldName, _
                           esriFieldTypeDouble)
         If fc_point Is Nothing Then
            If MsgBox("New file not created. Retry?", vbOKCancel) = vbCancel Then Exit Function
         End If
  Loop
  
  Do While (fc_poly Is Nothing)
          idFieldName = "T_ID"
          Set fc_poly = CreateShapefile("Save Thiessen Polygons as", _
                           esriGeometryPolygon, _
                           idFieldName, _
                           esriFieldTypeInteger, _
                           areaFieldName, _
                           esriFieldTypeDouble)
         If fc_point Is Nothing Then
            If MsgBox("New file not created. Retry?", vbOKCancel) = vbCancel Then Exit Function
         End If
  Loop
  
  'Loop through Array and create Slope Objects
  ReDim Slopes(1 To numLines) As Slope
  
  For counter = 1 To numLines
    
    Dim s As Slope
    Set s = New Slope
    
    On Error GoTo slopeErr
    s.ID = counter
    Set s.SlopePolygon = polygons(counter)
    Set s.SlopeFallLine = lines(counter)
    Set s.DEM = m_pSelectedRasterSurface
    Set s.SlopePointFeatureClass = fc_point
    Set s.ThiessenPolygonFeatureClass = fc_poly
         
    On Error GoTo 0
    
    On Error GoTo connectionErr:
      myRiverNet.connectSlope s
    On Error GoTo 0
    
    Set Slopes(counter) = s
nextSlope:
  Next
  Me.MousePointer = fmMousePointerDefault
  
  
  Do While (slopeTextStream Is Nothing)
          Set slopeTextStream = CreateTextStream("Save slope data for Matlab preprocessing")
          If slopeTextStream Is Nothing Then
            If MsgBox("New file not created. Retry?", vbYesNo) = vbNo Then Exit Function
          End If
  Loop
  
  'Success to be returned
  ProcessSlopes = True
  'State variable
  slopesProcessed = True
    
  Exit Function
slopeErr:
    If Err.Number = s.errThiessenShapeVisible Then
        MsgBox "It is likely that one of the files selected for saving " & _
         "is an active layer." & Chr(13) & _
         "Please remove the corresponding layer from the map." & Chr(13) & _
         "Otherwise try restarting ArcGis"
        Me.MousePointer = fmMousePointerDefault
        Exit Function
    End If
    MsgBox "Skiping Slope " & counter & ":" & Chr(13) & _
           Err.Description & " in " & Err.Source
    Err.Clear
    Resume nextSlope
    
connectionErr:
    MsgBox Err.Description, , Err.Source
    Resume Next
    
End Function

Private Sub BankSlope_AfterUpdate()
   Dim order As Integer
   order = cbxOrder.ListIndex + 1
   parseValue BankSlope, theBankSlope(order), positiveValue
   BankSlope.Value = theBankSlope(order)
End Sub

Private Sub cbCancel_Click()
  Unload Me
End Sub

Private Sub cbFinish_Click()
  lFinish_Click
  setDefaultsAndAttributeFields
  showResults
  connectSlopes
  createCatflowFiles
  Unload Me
End Sub
Private Sub setDefaultsAndAttributeFields()

 'Pass parameters to RiverNet object
 myRiverNet.DefaultParameterValue(myRiverNet.ParameterTypeSplitLength) = theRiverSplitLength
 If (m_pSelectedRiverSplitLenghtFieldIndex <> -1) Then
    myRiverNet.ParameterFieldIndex(myRiverNet.ParameterTypeSplitLength) = m_pSelectedRiverSplitLenghtFieldIndex
 End If
 
 Set myRiverNet.RainstationPolygons = m_pSelectedRainStationFeatureClass
 
 If (m_pSelectedRainStationFieldIndex <> -1) Then
    myRiverNet.ParameterFieldIndex(myRiverNet.ParameterTypeRainStationID) = _
                   m_pSelectedRainStationFieldIndex
 End If
 
 'm_pSelectedRainStationFieldIndex
 
 If (m_pCritRainIndex <> -1) Then
    myRiverNet.ParameterFieldIndex(myRiverNet.ParameterTypeCriticalRain) = m_pCritRainIndex
 End If
 If (m_pConnectedIndex <> -1) Then
    myRiverNet.ParameterFieldIndex(myRiverNet.ParameterTypeSealedAreasConnected) = m_pConnectedIndex
 End If
 If (m_pWtDIndex <> -1) Then
    myRiverNet.ParameterFieldIndex(myRiverNet.ParameterTypeWidthToDepthRatio) = m_pWtDIndex
 End If
 If (m_pStricklerIndex <> -1) Then
    myRiverNet.ParameterFieldIndex(myRiverNet.ParameterTypeStrickler) = m_pStricklerIndex
 End If
 If (m_pBankSlopeIndex <> -1) Then
    myRiverNet.ParameterFieldIndex(myRiverNet.ParameterTypeBankSlope) = m_pBankSlopeIndex
 End If
 If (m_pSurfWidthIndex <> -1) Then
    myRiverNet.ParameterFieldIndex(myRiverNet.ParameterTypeSurfaceWidth) = m_pSurfWidthIndex
 End If
 
 Dim order As Integer
 For order = 1 To maxStrahlerOrder
    myRiverNet.DefaultParameterValue(myRiverNet.ParameterTypeCriticalRain, order) = theCriticalRain(order)
    myRiverNet.DefaultParameterValue(myRiverNet.ParameterTypeWidthToDepthRatio, order) = theWidthToDepthRatio(order)
    myRiverNet.DefaultParameterValue(myRiverNet.ParameterTypeStrickler, order) = theStrickler(order)
    myRiverNet.DefaultParameterValue(myRiverNet.ParameterTypeBankSlope, order) = theBankSlope(order)
    myRiverNet.DefaultParameterValue(myRiverNet.ParameterTypeSurfaceWidth, order) = theSurfaceWidth(order)
    myRiverNet.DefaultParameterValue(myRiverNet.ParameterTypeSealedAreasConnected, order) = IIf(theConnected(order), 1, 0)
 Next
 
 'riverNetPointsIntoFeatureClass
 
 'Pass parameters to Slope Objects
 Dim Slope As Long
 Dim theValue As Double
 Dim theFeature As IFeature
 
 For Slope = LBound(Slopes) To UBound(Slopes)
   
   If Not (Slopes(Slope) Is Nothing) Then
      Set theFeature = searchFeature(m_pSelectedLineFeatureClass, m_pSelectedLineIDFieldIndex, Slopes(Slope).ID)
      'theSlopeShapeTypeConstantThickness  = 1 has index 0 in cbxDefaultGridShape
      'theSlopeShapeTypeCakeShape = 2 has index  1
      Slopes(Slope).SlopeShapeType = cbxDefaultGridShape.ListIndex + 1
      'Overwrite default if slope specific value is available
      If (m_pShapeFieldIndex <> -1) Then
        theValue = theFeature.Value(m_pShapeFieldIndex)
        If theValue > 0 And theValue < 3 Then
          Slopes(Slope).SlopeShapeType = theValue
        End If
      End If
      
      Slopes(Slope).Thickness = theSlopeThickness
      'Overwrite default if slope specific value is available
      If (m_pThicknessFieldIndex <> -1) Then
        theValue = theFeature.Value(m_pThicknessFieldIndex)
        If theValue > 0 Then
          Slopes(Slope).Thickness = theValue
        End If
      End If
      
      Slopes(Slope).SplitLength = theSlopeSplitLength
      'Overwrite default if slope specific value is available
      If (m_pSlopeSplitFieldIndex <> -1) Then
        theValue = theFeature.Value(m_pSlopeSplitFieldIndex)
        If theValue > 0 Then
          Slopes(Slope).SplitLength = theValue
        End If
      End If
      
    
      Slopes(Slope).XRef = x_reference
      Slopes(Slope).YRef = y_reference
      Slopes(Slope).ZRef = z_reference
      
      Slopes(Slope).updatePointFeatureClass
      Slopes(Slope).updateThiessenFeatureClass
   End If
 Next
 
End Sub
Private Sub showResults()
    
    Dim m_pApp As IApplication
    Set m_pApp = Application
 
    MiscUtil.AddFeatureLayer m_pApp, fc_poly
    MiscUtil.AddFeatureLayer m_pApp, fc_point
    MiscUtil.AddFeatureLayer m_pApp, fc_rivernet
    
    
    
End Sub
Private Sub createCatflowFiles()
    myRiverNet.toCatflow riverTextStream
  SlopeCatflowFile Slopes, slopeTextStream, x_reference, y_reference, z_reference, EtaValues, XsiValues
End Sub

Private Sub cbHelp_Click()
   helptopic helpPart(tabs.Value)
End Sub

Private Sub cbNext_Click()
   Select Case tabs.Value
     Case stepIntro
        MsgBox "Please make sure to save your project before proceding.", vbOKOnly, "Catflow Wizard"
     Case stepRiverNet 'rivernet
        If Not riverNetProcessed Then
           If processRivernet = False Then
              'Error occured
              Exit Sub
           End If
           
        End If
     Case stepSlopeTheme
        If Not slopesProcessed Then
          If ProcessSlopes = False Then
            Exit Sub
          End If
        End If
   End Select
   tabs.Value = tabs.Value + 1
End Sub

Private Sub cbPrevious_Click()
  tabs.Value = tabs.Value - 1
End Sub



Private Sub cbxBankSlope_Change()
  If cbxBankSlope.ListIndex < 0 Then Exit Sub
     
  m_pBankSlopeIndex = _
     m_BankSlopeLookup(cbxBankSlope.ListIndex)
End Sub

Private Sub cbxConnected_Change()
  ' Make sure the a valid layer has been selected
  If cbxConnected.ListIndex < 0 Then Exit Sub
     
  m_pConnectedIndex = _
     m_ConnectedLookup(cbxConnected.ListIndex)
     

End Sub

Private Sub cbxOrder_Change()
   UpdateUI
End Sub

Private Sub cbxRiverSplitLength_Change()
  ' Make sure the a valid layer has been selected
  
  If cbxRiverSplitLength.ListIndex < 0 Then Exit Sub
  
  ' Given the selected layer in the list find out which layer number
  ' this refers to from the m_pMap and set this to be the selected layer
  m_pSelectedRiverSplitLenghtFieldIndex = _
     m_RiverSplitFieldIndexLookup(cbxRiverSplitLength.ListIndex)
     
  'MsgBox "ListIndex " & lstLineLayerFields.ListIndex & _
  '       " evaluates to FieldNr " & m_pSelectedLineIDFieldIndex
  
  ' Now update the UI buttons to reflect the newly selected layer
  riverNetProcessed = False
  UpdateUI

End Sub

Private Sub cbxShapeField_Change()
  If cbxShapeField.ListIndex < 0 Then Exit Sub
     
  m_pShapeFieldIndex = _
     m_ShapeFieldLookup(cbxShapeField.ListIndex)
End Sub

Private Sub cbxSplitField_Change()
  If cbxSplitField.ListIndex < 0 Then Exit Sub
     
  m_pSlopeSplitFieldIndex = _
     m_SlopeSplitFieldLookup(cbxSplitField.ListIndex)
End Sub

Private Sub cbxStrickler_Change()
  If cbxStrickler.ListIndex < 0 Then Exit Sub
     
  m_pStricklerIndex = _
     m_StricklerLookup(cbxStrickler.ListIndex)
End Sub

Private Sub cbxSurfWidth_Change()
  If cbxSurfWidth.ListIndex < 0 Then Exit Sub
     
  m_pSurfWidthIndex = _
     m_SurfWidthLookup(cbxSurfWidth.ListIndex)
End Sub

Private Sub cbxThicknessField_Change()
  If cbxThicknessField.ListIndex < 0 Then Exit Sub
     
  m_pThicknessFieldIndex = _
     m_ThicknessFieldLookup(cbxThicknessField.ListIndex)
End Sub

Private Sub cbxWtD_Change()
  If cbxWtD.ListIndex < 0 Then Exit Sub
     
  m_pWtDIndex = _
     m_WtDLookup(cbxWtD.ListIndex)
End Sub

Private Sub cbxCritRain_Change()
  If cbxCritRain.ListIndex < 0 Then Exit Sub
     
  m_pCritRainIndex = _
     m_CritRainLookup(cbxCritRain.ListIndex)
End Sub



Private Sub cmdAbout_Click()
   MsgBox "Catflow Wizard version 0.81b, Copyright (C) 2006 Dominik Reusser " & Chr(13) & _
        "The Catflow Wizard comes with ABSOLUTELY NO WARRANTY; " & Chr(13) & _
        "This is free software, and you are welcome " & Chr(13) & _
        "to redistribute it under certain conditions." & Chr(13) & _
        "See help for more information.", vbOKOnly, "Catflow Wizard"
End Sub

Private Sub Connected_Click()
   Dim order As Integer
   order = cbxOrder.ListIndex + 1
   theConnected(order) = Connected
   
End Sub

Private Sub CritRain_AfterUpdate()
   Dim order As Integer
   order = cbxOrder.ListIndex + 1
   parseValue CritRain, theCriticalRain(order), positiveValue
   CritRain.Value = theCriticalRain(order)
End Sub




Private Sub DefaultThickness_AfterUpdate()
   parseValue DefaultThickness, theSlopeThickness, positiveValue
   DefaultThickness = theSlopeThickness
End Sub

Private Sub ImFinish_Click()
  lFinish_Click
End Sub

Private Sub ImIntro_Click()
  lIntro_Click
End Sub

Private Sub ImRivernet_Click()
  lRivernet_Click
End Sub

Private Sub ImRiverParam_Click()
  lRiverParam_Click
End Sub

Private Sub ImSlopeCoord_Click()
  lSlopeCoord_Click
End Sub

Private Sub ImSlopeParam_Click()
  lSlopeParam_Click
End Sub

Private Sub ImSlopes_Click()
  lSlopes_Click
End Sub



Private Sub InputEta_AfterUpdate()
   updateList EtaList, InputEta, EtaValues, NumberOfEtaValues
End Sub


Private Sub InputXsi_AfterUpdate()
   updateList XsiList, InputXsi, XsiValues, NumberOfXsiValues

End Sub
Private Sub updateList(theOutput As ListBox, theInput As TextBox, theValues() As Double, valueCount As Integer)

   Dim nextPos As Integer
   Dim prevPos As Integer
   
   
   theOutput.Clear
   
   theValues = parseList(theInput.Value)
   
   Dim counter As Integer
   
   For counter = LBound(theValues) To UBound(theValues) - 1
     theOutput.AddItem theValues(counter)
   Next
   
End Sub





Private Sub lFinish_Click()
  If Not riverNetProcessed Then
           If processRivernet = False Then
              'Error occured
              Exit Sub
           End If
  End If
  If Not slopesProcessed Then
          ProcessSlopes
  End If
  
   tabs.Value = stepFinish
End Sub
Private Sub connectSlopes()
  
  If Not (myRiverNet.SlopeConnected) Then
    Dim counter As Integer
    For counter = LBound(Slopes) To UBound(Slopes)
            
        On Error GoTo connectionErr:
            myRiverNet.connectSlope Slopes(counter)
        On Error GoTo 0
    Next
  End If
 
  Exit Sub
  
connectionErr:
    MsgBox Err.Description, , Err.Source
    Resume Next
    
End Sub

Private Sub lRiverParam_Click()
  If Not riverNetProcessed Then
           If processRivernet = False Then
              'Error occured
              Exit Sub
           End If
  End If
  tabs.Value = stepRiverParam
End Sub

Private Sub lSlopeCoord_Click()
  If Not riverNetProcessed Then
           If processRivernet = False Then
              'Error occured
              Exit Sub
           End If
  End If
  If Not slopesProcessed Then
          ProcessSlopes
  End If
  tabs.Value = stepSlopeTheme
End Sub
Private Sub lIntro_Click()
  tabs.Value = stepIntro
End Sub

Private Sub lRivernet_Click()
  tabs.Value = stepRiverNet
End Sub

Private Sub lSlopeParam_Click()
  If Not riverNetProcessed Then
           If processRivernet = False Then
              'Error occured
              Exit Sub
           End If
  End If
  tabs.Value = stepSlopeParam
End Sub

Private Sub lSlopes_Click()
  If Not riverNetProcessed Then
           If processRivernet = False Then
              'Error occured
              Exit Sub
           End If
  End If
  tabs.Value = stepSlopeTheme
End Sub

Private Sub setSubwayMap()
    Rem First restore the labels to default color and size
    If Not curStep = "" Then
      Controls("l" & curStep).ForeColor = vbWhite
      Controls("l" & curStep).Font.Size = 11
    End If
    
        Rem - depending on Tab value set curStep- current step
        Select Case tabs.Value
        Case stepIntro
        curStep = "Intro"
        Case stepRiverNet
        curStep = "Rivernet"
        Case stepRiverParam
        curStep = "RiverParam"
        Case stepSlopeTheme
        curStep = "Slopes"
        Case stepSlopeParam
        curStep = "SlopeParam"
        Case stepSlopeCoord
        curStep = "SlopeCoord"
        Case stepFinish
        curStep = "Finish"
        End Select
    
    Rem - Now with new value of curStep highlight active Subway Stop
    Rem - by making its label bigger and yellow in color
    Controls("l" & curStep).ForeColor = vbYellow
    Controls("l" & curStep).Font.Size = 12
    
    lRiverParam.Enabled = False
    lSlopes.Enabled = False
    lSlopeCoord.Enabled = False
    lSlopeParam.Enabled = False
    lFinish.Enabled = False
    ImRiverParam.Enabled = False
    ImSlopes.Enabled = False
    ImSlopeCoord.Enabled = False
    ImSlopeParam.Enabled = False
    ImFinish.Enabled = False
    
    If Not (m_pSelectedRivernetFeatureClass Is Nothing) _
         And Not (m_pSelectedRasterSurface Is Nothing) _
         Then
         lSlopes.Enabled = True
         ImSlopes.Enabled = True
         lRiverParam.Enabled = True
         ImRiverParam.Enabled = True
         If m_pSelectedPolygonIDFieldIndex > 0 _
            And m_pSelectedLineIDFieldIndex > 0 _
            Then
            lSlopeCoord.Enabled = True
            ImSlopeCoord.Enabled = True
            lSlopeParam.Enabled = True
            ImSlopeParam.Enabled = True
            lFinish.Enabled = True
            ImFinish.Enabled = True
         End If
    End If
End Sub

Private Sub lstLineLayerFields_Click()
  ' Make sure the a valid layer has been selected
  If lstLineLayerFields.ListIndex < 0 Then Exit Sub
     
  ' Given the selected layer in the list find out which layer number
  ' this refers to from the m_pMap and set this to be the selected layer
  m_pSelectedLineIDFieldIndex = _
     m_LineFieldIndexLookup(lstLineLayerFields.ListIndex)
     
  'MsgBox "ListIndex " & lstLineLayerFields.ListIndex & _
  '       " evaluates to FieldNr " & m_pSelectedLineIDFieldIndex
  
  ' Now update the UI buttons to reflect the newly selected layer
  slopesProcessed = False
  UpdateUI

End Sub

Private Sub lstLineLayers_Click()
  Dim layerIndex As Long


  ' Make sure the a valid layer has been selected
  If lstLineLayers.ListIndex < 0 Then Exit Sub
     
  ' Given the selected layer in the list find out which layer number
  ' this refers to from the m_pMap and set this to be the selected layer
  layerIndex = m_LineLayerIndexLookup(lstLineLayers.ListIndex)
  
  Dim fl As IGeoFeatureLayer
  Set fl = m_pMap.Layer(layerIndex)
  Set m_pSelectedLineFeatureClass = fl.FeatureClass
  
  ' Mark that lstLineLayerField need update
  
  m_pSelectedLineIDFieldIndex = -2
  m_pShapeFieldIndex = -2
  m_pThicknessFieldIndex = -2
  m_pSlopeSplitFieldIndex = -2
  

  ' Now update the UI buttons to reflect the newly selected layer
  UpdateUI

End Sub

Private Sub lstPolygonLayerFields_Click()
  ' Make sure the a valid layer has been selected
  If lstPolygonLayerFields.ListIndex < 0 Then Exit Sub
     
  ' Given the selected layer in the list find out which layer number
  ' this refers to from the m_pMap and set this to be the selected layer
  m_pSelectedPolygonIDFieldIndex = _
     m_PolygonFieldIndexLookup(lstPolygonLayerFields.ListIndex)
     
  'MsgBox "ListIndex " & lstPolygonLayerFields.ListIndex & _
  '       " evaluates to FieldNr " & m_pSelectedPolygonIDFieldIndex
  
  ' Now update the UI buttons to reflect the newly selected layer
    slopesProcessed = False
  UpdateUI


End Sub

Private Sub lstPolygonLayers_Click()
  Dim layerIndex As Long


  ' Make sure the a valid layer has been selected
  If lstPolygonLayers.ListIndex < 0 Then Exit Sub
     
  ' Given the selected layer in the list find out which layer number
  ' this refers to from the m_pMap and set this to be the selected layer
  layerIndex = m_PolygonLayerIndexLookup(lstPolygonLayers.ListIndex)
  
  Dim fl As IGeoFeatureLayer
  Set fl = m_pMap.Layer(layerIndex)
  Set m_pSelectedPolygonFeatureClass = fl.FeatureClass
  
  ' Mark that lstLineLayerField need update
  
  m_pSelectedPolygonIDFieldIndex = -2
  

  ' Now update the UI buttons to reflect the newly selected layer
  UpdateUI

End Sub

Private Sub lstRainStationAttribute_Click()
  ' Make sure the a valid layer has been selected
  If lstRainStationAttribute.ListIndex < 0 Then Exit Sub
     
  ' Given the selected layer in the list find out which layer number
  ' this refers to from the m_pMap and set this to be the selected layer
  m_pSelectedRainStationFieldIndex = _
     m_RainStationAttributeLookup(lstRainStationAttribute.ListIndex)
     
 
  UpdateUI

End Sub

Private Sub lstRainStationLayer_Click()
  Dim layerIndex As Long


  ' Make sure the a valid layer has been selected
  If lstRainStationLayer.ListIndex < 0 Then Exit Sub
     
  ' Given the selected layer in the list find out which layer number
  ' this refers to from the m_pMap and set this to be the selected layer
  layerIndex = m_RainStationLayerIndexLookup(lstRainStationLayer.ListIndex)
  
  If layerIndex = -1 Then
     Set m_pSelectedRainStationFeatureClass = Nothing
  Else
    Dim fl As IFeatureLayer
    Set fl = m_pMap.Layer(layerIndex)
    Set m_pSelectedRainStationFeatureClass = fl.FeatureClass
  End If
  
  ' Mark that lstLineLayerField need update
  
  m_pSelectedRainStationFieldIndex = -2
  
  ' Now update the UI buttons to reflect the newly selected layer
  UpdateUI

End Sub

Private Sub lstRasterBands_Click()

  ' Make sure the a valid layer has been selected
  If lstRasterBands.ListIndex < 0 Then Exit Sub
  
  'Create new RasterSurface
  Set m_pSelectedRasterSurface = New RasterSurface
  'Set the RasterSurface to use the selected RasterBand
  Dim pBands As IRasterBandCollection
  Set pBands = m_pSelectedRasterLayer.Raster
  m_pSelectedRasterSurface.RasterBand = pBands.Item(lstRasterBands.ListIndex)
  ' Now update the UI buttons to reflect the newly selected layer
  slopesProcessed = False
  riverNetProcessed = False
  UpdateUI
End Sub

Private Sub lstRasterLayers_Click()
  Dim layerIndex As Long


  ' Make sure the a valid layer has been selected
  If lstRasterLayers.ListIndex < 0 Then Exit Sub
     
  ' Given the selected layer in the list find out which layer number
  ' this refers to from the m_pMap and set this to be the selected layer
  layerIndex = m_RasterLayerIndexLookup(lstRasterLayers.ListIndex)
  Set m_pSelectedRasterLayer = m_pMap.Layer(layerIndex)
  
  ' Mark that lstRasterLayerBand need update
  Set m_pSelectedRasterSurface = Nothing
  
  ' Now update the UI buttons to reflect the newly selected layer
  UpdateUI

End Sub
Private Sub setupRasterBand()

  'Exit right away if no RasterLayer is selected
  If m_pSelectedRasterLayer Is Nothing Then Exit Sub
  'Exit right away if RasterSurface is selected
  If Not (m_pSelectedRasterSurface Is Nothing) Then Exit Sub
  
  lRasterBand.Caption = "Select appropriate raster band"
  lstRasterBands.Enabled = True
  
  
  lstRasterBands.Clear
  
  Dim p3DProp As I3DProperties
  Dim pLE As ILayerExtensions
  Set pLE = m_pSelectedRasterLayer
      
      ' look for 3D properties of layer:
  Dim i As Integer
  For i = 0 To pLE.ExtensionCount - 1
        If TypeOf pLE.Extension(i) Is I3DProperties Then
          Set p3DProp = pLE.Extension(i)
          Exit For
        End If
  Next
    
    
      ' We want the IRasterm_pSelectedRasterSurface of the layer;
      ' Look first for base m_pSelectedRasterSurface of layer itself:
  If Not p3DProp Is Nothing Then
    Set m_pSelectedRasterSurface = p3DProp.BaseSurface
    lRasterBand.Caption = "base surface selected"
    lstRasterBands.Enabled = False
  End If
    
    
      ' if base m_pSelectedRasterSurface of layer is not set, create the IRasterm_pSelectedRasterSurface from
      ' the first band of the raster:
  If m_pSelectedRasterSurface Is Nothing Then
        If Not m_pSelectedRasterLayer.Raster Is Nothing Then
          Dim pBands As IRasterBandCollection
          Set pBands = m_pSelectedRasterLayer.Raster
          If pBands.count > 1 Then
            Dim bandIndex As Long
            For bandIndex = 0 To pBands.count
              lstRasterBands.AddItem pBands.Item(bandIndex).Bandname
            Next
          ElseIf pBands.count = 1 Then
            'Create new RasterSurface
            Set m_pSelectedRasterSurface = New RasterSurface
            'Set the RasterSurface to use the selected RasterBand
            m_pSelectedRasterSurface.RasterBand = pBands.Item(0)
            lRasterBand.Caption = "Unique raster band selected"
            lstRasterBands.Enabled = False
          Else
            lRasterBand.Caption = "No raster band available"
            lstRasterBands.Enabled = False
          End If
        Else
          lRasterBand.Caption = "No raster band available"
          lstRasterBands.Enabled = False
        End If
 End If
  
End Sub

Private Sub lstRivernet_Click()
  Dim layerIndex As Long


  ' Make sure the a valid layer has been selected
  If lstRivernet.ListIndex < 0 Then Exit Sub
     
  ' Given the selected layer in the list find out which layer number
  ' this refers to from the m_pMap and set this to be the selected layer
  layerIndex = m_RivernetIndexLookup(lstRivernet.ListIndex)
  
  Dim fl As IGeoFeatureLayer
  Set fl = m_pMap.Layer(layerIndex)
  Set m_pSelectedRivernetFeatureClass = fl.FeatureClass
  
  riverNetProcessed = False
  m_pSelectedRiverSplitLenghtFieldIndex = -2
  m_pCritRainIndex = -2
  m_pConnectedIndex = -2
  m_pWtDIndex = -2
  m_pStricklerIndex = -2
  m_pBankSlopeIndex = -2
  m_pSurfWidthIndex = -2
  cbxRiverSplitLength.Enabled = True

  ' Now update the UI buttons to reflect the newly selected layer
  UpdateUI

End Sub

Private Sub rain_none_Click()
  UpdateUI
End Sub

Private Sub rain_polygon_Click()
  UpdateUI
End Sub

Private Sub rain_raster_Click()
  UpdateUI
End Sub

Private Sub riverSplitLength_AfterUpdate()
   Dim before As Integer
   before = theRiverSplitLength
   parseValue riverSplitLength, theRiverSplitLength, positiveValue
   riverSplitLength = theRiverSplitLength
   If (before <> theRiverSplitLength) Then
        riverNetProcessed = False
   End If
End Sub




Private Sub SlopeSplitDefault_AfterUpdate()
   parseValue SlopeSplitDefault, theSlopeSplitLength, positiveValue
   SlopeSplitDefault = theSlopeSplitLength

End Sub

Private Sub Strickler_AfterUpdate()
   Dim order As Integer
   order = cbxOrder.ListIndex + 1
   parseValue Strickler, theStrickler(order), positiveValue
   Strickler.Value = theStrickler(order)
End Sub

Private Sub SurfWidth_AfterUpdate()
   Dim order As Integer
   order = cbxOrder.ListIndex + 1
   parseValue SurfWidth, theSurfaceWidth(order), positiveValue
   SurfWidth.Value = theSurfaceWidth(order)
End Sub

Private Sub tabs_Change()
    
    setSubwayMap
    
    Select Case tabs.Value
    Case stepIntro 'Intro chosen
      cbNext.Enabled = True
      cbPrevious.Enabled = False
      cbFinish.Enabled = False
    Case stepRiverNet ' Rivernet
      cbNext.Enabled = False
      cbPrevious.Enabled = True
      cbFinish.Enabled = False
      If Not (m_pSelectedRivernetFeatureClass Is Nothing) _
         And Not (m_pSelectedRasterSurface Is Nothing) _
         Then
         cbNext.Enabled = True
      End If
    Case stepRiverParam ' River parameters
      cbNext.Enabled = True
      cbPrevious.Enabled = True
      cbFinish.Enabled = False
    Case stepSlopeTheme ' Slope Themes
      cbNext.Enabled = False
      cbPrevious.Enabled = True
      cbFinish.Enabled = False
      If m_pSelectedPolygonIDFieldIndex > 0 _
        And m_pSelectedLineIDFieldIndex > 0 _
        Then
        cbNext.Enabled = True
      End If
    Case stepSlopeParam 'Slope parameters
      cbNext.Enabled = True
      cbPrevious.Enabled = True
      cbFinish.Enabled = True
    Case stepSlopeCoord 'Slope Coordinates
      cbNext.Enabled = True
      cbPrevious.Enabled = True
      cbFinish.Enabled = True
    Case stepFinish 'Finish chosen
      cbNext.Enabled = False
      cbPrevious.Enabled = True
      cbFinish.Enabled = False
    
    End Select
    
  If Not (m_pSelectedRivernetFeatureClass Is Nothing) _
         And Not (m_pSelectedRasterSurface Is Nothing) _
         And m_pSelectedPolygonIDFieldIndex > 0 _
         And m_pSelectedLineIDFieldIndex > 0 _
         Then
         cbFinish.Enabled = True
         
  End If

End Sub



'
' Initialise the list of layers and buttons when the form is created
'
Private Sub UserForm_Initialize()

   If Not TestFor3DAnalyst() Then
       MsgBox "Please Activate 3D Analyst Extension"
       Unload Me
       Exit Sub
   End If

  
  ' Get a pointer to the IMxDocument interface from the application
  Set m_pMxDoc = Application.Document
  
  ' There can be more than one map per MxDoc,
  '   so QI to the focus Map and work with that
  Set m_pMap = m_pMxDoc.FocusMap
  
  tabs.Value = stepIntro
  tabs.Style = fmTabStyleNone
  
  ' get the layer list and update the UI to reflect this
  
  
  InitialiseWithShapeLayers lstLineLayers, m_LineLayerIndexLookup, esriGeometryPolyline
  InitialiseWithShapeLayers lstRivernet, m_RivernetIndexLookup, esriGeometryPolyline
  InitialiseWithShapeLayers lstPolygonLayers, m_PolygonLayerIndexLookup, esriGeometryPolygon
  InitialiseWithRasterLayers lstRasterLayers, m_RasterLayerIndexLookup
  InitialiseWithShapeLayers lstRainStationLayer, m_RainStationLayerIndexLookup, esriGeometryPolygon, False
  ' RainStationLayer may stay empty
  m_pSelectedRainStationFieldIndex = -1
  
  'Setup numeric fields
  riverSplitLength.Value = defaultRiverSplitLength
  SlopeSplitDefault.Value = defaultSlopeSplitDefault
  DefaultThickness.Value = defaultSlopeThickness
  theRiverSplitLength = defaultRiverSplitLength
  theSlopeSplitLength = defaultSlopeSplitDefault
  theSlopeThickness = defaultSlopeThickness
  
  setupcbxDefaultGridShape
  
  'Setup Eta and Xsi Variables
  InputEta_AfterUpdate
  InputXsi_AfterUpdate
  UpdateUI
  
  ' setup field types
  integerTypes(0) = esriFieldTypeSmallInteger
  integerTypes(1) = esriFieldTypeInteger
  floatTypes(0) = esriFieldTypeSingle
  floatTypes(1) = esriFieldTypeDouble
  
  'setup help relation
  helpPart(stepIntro) = "ch02.html#id4770764"
  helpPart(stepRiverNet) = "ch02.html#id4770833"
  helpPart(stepRiverParam) = "ch02.html#id4771052"
  helpPart(stepSlopeTheme) = "ch02.html#id4771322"
  helpPart(stepSlopeParam) = "ch02.html#id4771382"
  helpPart(stepSlopeCoord) = "ch02.html#id4771510"
  helpPart(stepFinish) = "ch02.html#id4771517"
  
End Sub
'
'Fill in Field names and keep them ready for processing
'
Private Sub setupLayerFields(theIndex As Long, theControl As Variant, theLookup() As Long, theClass As IObjectClass, typelist() As esriFieldType, Optional selectionRequired As Boolean = True)

  ' Check whether lstLineLayerField need update
  If (theIndex <> -2) Then Exit Sub

  ' Clear out any existing entries from the list
  theControl.Clear
  
  

  ' Only search ID fields if a LineLayer is selected
  If Not (theClass Is Nothing) Then
        Dim pFields As IFields
        Set pFields = theClass.Fields
          
        Dim fieldIndex As Long
        Dim pField As IField

        ' Make sure the layer lookup is big enough
        ReDim theLookup(0 To pFields.FieldCount - 1)
        
        'Add no selection option
        If Not selectionRequired Then
           theControl.AddItem "***none***"
           theLookup(theControl.ListCount - 1) = -1
        End If
  
        ' Look for the raster layers and add their names to the list box
        For fieldIndex = 0 To pFields.FieldCount - 1
  
          ' get a pointer to the Field, it could be any type of layer
          Set pField = pFields.Field(fieldIndex)
      
          ' If the layer supports the rasterLayer interface,
          ' then add it to our list of available layers
          Dim counter As Long
          Dim OK As Boolean
          OK = False
          For counter = LBound(typelist) To UBound(typelist)
             If pField.Type = typelist(counter) Then OK = True
          Next
          If OK Then
        
            ' Add the layer name to the list
            theControl.AddItem pField.Name
          
            ' Update our lookup array which takes the index into the listbox and returns
            ' the layer number in the layer collection off the IMap
            theLookup(theControl.ListCount - 1) = fieldIndex
          End If
    
        Next fieldIndex
  End If
  
  'Mark that lstLineLayerField is up to date
  If theControl.ListCount = 1 Then
     theControl.ListIndex = 0
     theControl.Enabled = False
  Else
     theIndex = -1
     theControl.Enabled = True
  End If
  
End Sub


'
'  All the buttons and controls get updated here to reflect the selected layer
'
Private Sub UpdateUI()
  
  'ID field for Slope Lines
  setupLayerFields m_pSelectedLineIDFieldIndex, lstLineLayerFields, m_LineFieldIndexLookup, m_pSelectedLineFeatureClass, integerTypes
  'ID field for slope polygons
  setupLayerFields m_pSelectedPolygonIDFieldIndex, lstPolygonLayerFields, m_PolygonFieldIndexLookup, m_pSelectedPolygonFeatureClass, integerTypes
  setupRasterBand
  'Splitt Length
  setupLayerFields m_pSelectedRiverSplitLenghtFieldIndex, cbxRiverSplitLength, m_RiverSplitFieldIndexLookup, m_pSelectedRivernetFeatureClass, floatTypes, False
  'RainStation ID
  setupLayerFields m_pSelectedRainStationFieldIndex, lstRainStationAttribute, m_RainStationAttributeLookup, m_pSelectedRainStationFeatureClass, integerTypes
  'Rivernet parameters
  setupLayerFields m_pConnectedIndex, cbxConnected, m_ConnectedLookup, m_pSelectedRivernetFeatureClass, integerTypes, False
  setupLayerFields m_pCritRainIndex, cbxCritRain, m_CritRainLookup, m_pSelectedRivernetFeatureClass, floatTypes, False
  setupLayerFields m_pWtDIndex, cbxWtD, m_WtDLookup, m_pSelectedRivernetFeatureClass, floatTypes, False
  setupLayerFields m_pBankSlopeIndex, cbxBankSlope, m_BankSlopeLookup, m_pSelectedRivernetFeatureClass, floatTypes, False
  setupLayerFields m_pStricklerIndex, cbxStrickler, m_StricklerLookup, m_pSelectedRivernetFeatureClass, floatTypes, False
  setupLayerFields m_pSurfWidthIndex, cbxSurfWidth, m_SurfWidthLookup, m_pSelectedRivernetFeatureClass, floatTypes, False
  'Slope parameters
  setupLayerFields m_pShapeFieldIndex, cbxShapeField, m_ShapeFieldLookup, m_pSelectedLineFeatureClass, integerTypes, False
  setupLayerFields m_pThicknessFieldIndex, cbxThicknessField, m_ThicknessFieldLookup, m_pSelectedLineFeatureClass, floatTypes, False
  setupLayerFields m_pSlopeSplitFieldIndex, cbxSplitField, m_SlopeSplitFieldLookup, m_pSelectedLineFeatureClass, floatTypes, False
  setupcbxOrder
  tabs_Change
  
End Sub




Private Function processRivernet() As Boolean


  
  Dim orderFieldName As String
  Dim idFieldName As String
  
  idFieldName = "SP_ID"
  orderFieldName = "Order"
  
  
  Do While (fc_rivernet Is Nothing)
         Set fc_rivernet = CreateShapefile("Save Rivernet Points as", _
                          esriGeometryPoint, _
                           idFieldName, _
                           esriFieldTypeInteger, _
                           orderFieldName, _
                           esriFieldTypeInteger)
         If fc_rivernet Is Nothing Then
            If MsgBox("New file not created. Retry?", vbOKCancel) = vbCancel Then Exit Function
         End If
  Loop
  
  Do While (riverTextStream Is Nothing)
          Set riverTextStream = CreateTextStream("Save Catflow rivernet data")
          If riverTextStream Is Nothing Then
            If MsgBox("New file not created. Retry?", vbYesNo) = vbNo Then Exit Function
          End If
  Loop
                           

                           
  
  Set myRiverNet = New RiverNet
  
  Set myRiverNet.DEM = m_pSelectedRasterSurface
  
  myRiverNet.DefaultParameterValue(myRiverNet.ParameterTypeSplitLength) = theRiverSplitLength
  If (m_pSelectedRiverSplitLenghtFieldIndex <> -1) Then
    myRiverNet.ParameterFieldIndex(myRiverNet.ParameterTypeSplitLength) = m_pSelectedRiverSplitLenghtFieldIndex
  End If
  'Set default vaule for Rainstation ID because this produced an error
  'The error occured because the rivernet was reinitialized on generating the
  'catflow file since this was the first read of the rainstationID and the
  'default value was reset
  myRiverNet.DefaultParameterValue(myRiverNet.ParameterTypeRainStationID) = 0
  
  On Error GoTo err_SetLines
calcTopology:
     Set myRiverNet.polylines = m_pSelectedRivernetFeatureClass
     maxStrahlerOrder = myRiverNet.MaximumStrahlerOrder()
  On Error GoTo 0
  initializeStrahlerParameters
  
  
  
  riverNetPointsIntoFeatureClass


  'success
  'return value
  processRivernet = True
  'state for subsequent programm execution
  riverNetProcessed = True
  UpdateUI
  Exit Function
err_SetLines:
  If Err.Number = myRiverNet.errorTooManyOutflows Then
     Dim newRadius As Double
     Dim answer As String
     answer = InputBox("More than 1 outflow found with a search radius of " & _
                         myRiverNet.topologySearchRadius & ". Do you want to " & _
                         "try again with a larger radius?", "Calculating Topology", _
                         "0,5")
     'cancel
     If answer = "" Then
         processRivernet = False
         Exit Function
     End If
     newRadius = CDbl(answer)
     If newRadius < myRiverNet.topologySearchRadius Then
        MsgBox "Your answer(" & newRadius & ") was smaller than the previous radius. Exiting..."
        processRivernet = False
        Exit Function
     End If
     myRiverNet.topologySearchRadius = newRadius
     Resume calcTopology
  End If
  MsgBox Err.Description, , Err.Source
  processRivernet = False
End Function

Private Sub riverNetPointsIntoFeatureClass()
  Dim orderFieldName As String
  Dim idFieldName As String
  
  idFieldName = "SP_ID"
  orderFieldName = "Order"
  
  
  Dim idField As Integer
  Dim orderField As Integer
  idField = fc_rivernet.FindField(idFieldName)
  orderField = fc_rivernet.FindField(orderFieldName)
  
  'Delete old points
  Dim fieldNames(0) As String
  Dim fieldIDs(0) As Integer
  
  fieldNames(0) = "Shape"
 
  Dim pFeatCur As IFeatureCursor
  Set pFeatCur = getFeatureCursor(fc_rivernet, _
                                 fieldNames, _
                                 fieldIDs)

  ' Process the features
  Dim pFeature As IFeature
  Set pFeature = pFeatCur.NextFeature
  Do Until pFeature Is Nothing
    pFeatCur.DeleteFeature
    Set pFeature = pFeatCur.NextFeature
  Loop
  
  Set pFeatCur = Nothing
  
  releaseLock fc_rivernet
  
  
  'Get points from myRiverNet
  
  Dim points As IGeometryCollection
  Set points = myRiverNet.RiverNetPoints()
  
  
   'Insert single Features using a cursor
   Set pFeatCur = fc_rivernet.Insert(True)
   
   
  'Create the point shape first
  Dim i As Integer
  For i = 0 To points.GeometryCount - 1
       Dim pFeatBuf As IFeatureBuffer
       Set pFeatBuf = fc_rivernet.CreateFeatureBuffer
       Dim Point As IPoint
       Set Point = points.Geometry(i)
       Set pFeatBuf.Shape = Point
       pFeatBuf.Value(idField) = Point.ID
       pFeatBuf.Value(orderField) = Point.M
       Dim v As Variant 'ID of the new Feature
       v = pFeatCur.InsertFeature(pFeatBuf)
       
  Next i
  
  Set pFeatCur = Nothing
End Sub
Private Sub WtD_AfterUpdate()
   Dim order As Integer
   order = cbxOrder.ListIndex + 1
   parseValue WtD, theWidthToDepthRatio(order), positiveValue
   WtD.Value = theWidthToDepthRatio(order)
End Sub

