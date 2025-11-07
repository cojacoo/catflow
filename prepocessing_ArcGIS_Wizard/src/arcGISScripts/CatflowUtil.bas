Attribute VB_Name = "CatflowUtil"
Option Explicit

Public Const positiveValue As Integer = 0
Public Const positiveOrZeroValue As Integer = 1
Public Const negativeValue As Integer = 2
Public Const negativeOrZeroValue As Integer = 3
Public Const booleanValue As Integer = 4
Public Const everyValue As Integer = 5
   
Public Const HH_DISPLAY_TOPIC = &H0&   ' WinHelp equivalent.
Public Const HH_DISPLAY_TOC = &H1&     ' WinHelp equivalent.
Public Const HH_DISPLAY_INDEX = &H2&   ' WinHelp equivalent.
Public Const HH_DISPLAY_SEARCH = &H3&  ' WinHelp equivalent.

Public Const HH_HELP_CONTEXT = &HF&    ' Display mapped numeric.
Public Const HH_CLOSE_ALL = &H12&      ' WinHelp equivalent.

Public Declare Function HTMLHelp Lib "hhctrl.ocx" Alias "HtmlHelpA" ( _
    ByVal hWnd As Long, _
    ByVal szFilename As String, _
    ByVal dwCommand As Long, _
    ByRef dwData As Any _
) As Long

Public Const helpfile As String = "C:\arcgis\arcexe83\bin\Templates\catflow.chm"

Public Sub singleSlope()
  Dim pMxDoc As IMxDocument
  Dim pEnumLayer As IEnumLayer
  Dim pFeature As IFeature
  Dim myLine As IFeature
  Dim myPolygon As IFeature
  Dim m_pSelectedRasterLayer As IRasterLayer
  Dim pFeatureCursor As IFeatureCursor
  Dim pFeatureLayer As IFeatureLayer
  Dim pFeatureClass As IFeatureClass
  Dim pFeatureSelection As IFeatureSelection
  Dim pMap As IMap
  Dim pSelectionSet As ISelectionSet
  Dim pUID As IUID

'the UID specifies the interface identifier (GUID)
'that represents the type of layer you want returned.
'in this case we want an EnumLayer containing all the FeatureLayer objects
  Set pUID = New UID
  pUID = "{E156D7E5-22AF-11D3-9F99-00C04F6BC78E}" ' Identifies FeatureLayer objects
  Set pMxDoc = Application.Document
  Set pMap = pMxDoc.FocusMap
  
  'Loop through all feature layers in the map
  Set pEnumLayer = pMap.Layers(pUID, True)
  pEnumLayer.Reset
  Set pFeatureLayer = pEnumLayer.Next
  Do While Not pFeatureLayer Is Nothing
    
    'Loop through the selected features per layer
    Set pFeatureSelection = pFeatureLayer 'QI
    Set pSelectionSet = pFeatureSelection.SelectionSet
    'Can use Nothing keyword if you don't want to draw them,
    'otherwise, the spatial reference might not match the Map's
    pSelectionSet.Search Nothing, False, pFeatureCursor
    Set pFeature = pFeatureCursor.NextFeature
    Do While Not pFeature Is Nothing
        Set pFeatureClass = pFeatureLayer.FeatureClass
        If (pFeatureClass.ShapeType = esriGeometryPolyline) Then
            If (myLine Is Nothing) Then
                Set myLine = pFeature
            Else
                MsgBox "More than one line selected", vbCritical, "Catflow Preprocessing"
                Exit Sub
            End If
        ElseIf (pFeatureClass.ShapeType = esriGeometryPolygon) Then
            If (myPolygon Is Nothing) Then
                Set myPolygon = pFeature
            Else
                MsgBox "More than one polygon selected", vbCritical, "Catflow Preprocessing"
                Exit Sub
            End If
        End If
        
      
      Set pFeature = pFeatureCursor.NextFeature
    Loop
    Set pFeatureLayer = pEnumLayer.Next
  Loop
  
  'Do something with the feature
   If (myLine Is Nothing Or myPolygon Is Nothing) Then
        MsgBox "Please select one polygon and one line", vbCritical, "Catflow Preprocessing"
        Exit Sub
   End If
   
   Dim layerIndex As Integer
   Dim pLayer As ILayer
   
   For layerIndex = 0 To pMap.LayerCount - 1
  
    ' get a pointer to the layer, it could be any type of layer
    Set pLayer = pMap.Layer(layerIndex)
    Debug.Print "Looking at " & pLayer.Name
   
      
    If TypeOf pLayer Is IRasterLayer Then
        If m_pSelectedRasterLayer Is Nothing Then
            Set m_pSelectedRasterLayer = pLayer
            Debug.Print "Raster selected"
        End If
    End If
  Next
    
   
  If (m_pSelectedRasterLayer Is Nothing) Then
        MsgBox "No digital elevation model found", vbCritical, "Catflow Preprocessing"
        Exit Sub
   End If
    
  Dim idFieldName As String
  Dim widthFieldName As String
  Dim areaFieldName As String
  Dim fc_point  As IFeatureClass, fc_poly As IFeatureClass
  Set fc_point = Nothing
  Set fc_poly = Nothing
  
  
  
  idFieldName = "SP_ID"
  widthFieldName = "Width"
  areaFieldName = "Area"
  
  
    'Get the actual slope
    
    Dim pGeometryCollection As IGeometryCollection
    Set pGeometryCollection = myLine.ShapeCopy
    If Not pGeometryCollection.GeometryCount = 1 Then
        MsgBox "The line myLine wit ID does not consist of a single, " & _
               "connected path. Please check for missing connections " & _
               "and points where the line splits."
        Exit Sub
     End If
     Dim line As IPath
     Set line = pGeometryCollection.Geometry(0)
     
     
   
     'Parametrice Slope
     Dim Slope As Slope
     Set Slope = New Slope
     
     Dim polygonFeature As IPolygon
     Set polygonFeature = myPolygon.ShapeCopy
     Set Slope.SlopeFallLine = line
     Set Slope.SlopePolygon = polygonFeature
     
     
        'theSlopeShapeTypeConstantThickness  = 1 has index 0 in cbxDefaultGridShape
      'theSlopeShapeTypeCakeShape = 2 has index  1
      Slope.SlopeShapeType = 1
      'Overwrite default if slope specific value is available
      Dim fieldIndex As Integer
      Dim theValue As Integer
      
      fieldIndex = myPolygon.Fields.FindField("c_SlopeType")
      If (fieldIndex <> -1) Then
        theValue = myPolygon.Value(fieldIndex)
        If theValue > 0 And theValue < 3 Then
          Slope.SlopeShapeType = theValue
        End If
      End If
      
      
      Slope.Thickness = 20
      'Overwrite default if slope specific value is available
      fieldIndex = myPolygon.Fields.FindField("c_SlopeThickness")
      If (fieldIndex <> -1) Then
        theValue = myPolygon.Value(fieldIndex)
        If theValue > 0 Then
          Slope.Thickness = theValue
        End If
      End If
      
      Slope.SplitLength = 10
      'Overwrite default if slope specific value is available
      fieldIndex = myPolygon.Fields.FindField("c_SplitLength")
      If (fieldIndex <> -1) Then
        theValue = myPolygon.Value(fieldIndex)
        If theValue > 0 Then
          Slope.SplitLength = theValue
        End If
      End If
      
  Dim m_pSelectedRasterSurface As IRasterSurface
  
  Set m_pSelectedRasterSurface = New RasterSurface
  'Shortcut from setupRasterBand. Maybe needs to be changed
  Dim pBands As IRasterBandCollection
  Set pBands = m_pSelectedRasterLayer.Raster
  m_pSelectedRasterSurface.RasterBand = pBands.Item(0)
  
  Do While (fc_point Is Nothing)
         Set fc_point = CreateShapefile("Save Splitt Points as", _
                           esriGeometryPoint, _
                           idFieldName, _
                           esriFieldTypeInteger, _
                           widthFieldName, _
                           esriFieldTypeDouble)
         If fc_point Is Nothing Then
            If MsgBox("New file not created. Retry?", vbOKCancel) = vbCancel Then Exit Sub
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
            If MsgBox("New file not created. Retry?", vbOKCancel) = vbCancel Then Exit Sub
         End If
  Loop

  Dim slopeTextStream As TextStream
  Do While (slopeTextStream Is Nothing)
          Set slopeTextStream = CreateTextStream("Save slope data for Matlab preprocessing")
          If slopeTextStream Is Nothing Then
            If MsgBox("New file not created. Retry?", vbYesNo) = vbNo Then Exit Sub
          End If
  Loop
  
  Dim EtaIn As String
  Dim EtaValues() As Double
  EtaIn = InputBox("Please Enter Values for Eta", "Catflow Wizard", "0.0; 0.10; 0.20; 0.30; 0.40; 0.50; 0.60; 0.70; 0.80; 0.90; 0.92; 0.94; 0.96; 0.98; 1.0")
  EtaValues = parseList(EtaIn)
  
  Dim XsiIn As String
  Dim XsiValues() As Double
  XsiIn = InputBox("Please Enter Values for Xsi", "Catflow Wizard", "0.0; 0.10; 0.20; 0.30; 0.40; 0.50; 0.60; 0.70; 0.80; 0.90; 0.92; 0.94; 0.96; 0.98; 1.0")
  XsiValues = parseList(XsiIn)
  
    Set Slope.DEM = m_pSelectedRasterSurface
    Set Slope.SlopePointFeatureClass = fc_point
    Set Slope.ThiessenPolygonFeatureClass = fc_poly
      
    Slope.updatePointFeatureClass
    Slope.updateThiessenFeatureClass
    
    Dim Slopes(1 To 1) As Slope
    Set Slopes(1) = Slope
    
    SlopeCatflowFile Slopes, slopeTextStream, 0, 0, 0, EtaValues, XsiValues
    
    Dim m_pApp As IApplication
    Set m_pApp = Application
 
    MiscUtil.AddFeatureLayer m_pApp, fc_poly
    MiscUtil.AddFeatureLayer m_pApp, fc_point

End Sub
Public Function CreateTextStream(title As String) As TextStream
    ' +++ Set up browser
    Dim pBrowser As IGxDialog
    Set pBrowser = New GxDialog
    Dim pEnumGX As IEnumGxObject

    ' +++ Open browser
    Dim blnFlag As Boolean
    pBrowser.title = title
    pBrowser.ButtonCaption = "Save"
    pBrowser.AllowMultiSelect = False
    pBrowser.RememberLocation = True
    Set pBrowser.ObjectFilter = New GxFilterTextFiles
  
 
    ' +++ Open browser
    blnFlag = pBrowser.DoModalSave(0)
    If blnFlag = False Then Exit Function
    
    Dim folder As IGxObject
    Set folder = pBrowser.FinalLocation
    
  
   Dim strFolder As String
   Dim strName As String
   strFolder = folder.FullName
   strName = pBrowser.Name
 
  
   'Test for existing File
   If fileExists(strFolder, strName) Then Exit Function
  
   Dim fs As FileSystemObject
   Set fs = New FileSystemObject
   
   Dim FileName As String
   FileName = strFolder & "\" & strName
   Set CreateTextStream = fs.CreateTextFile(FileName)
       
  
End Function

Public Function parseList(text As String) As Double()
   Dim nextPos, prevPos As Integer
   Dim valueCount As Integer
   nextPos = 1
   ReDim theValues(50) As Double
   valueCount = 0
   nextPos = InStr(prevPos + 1, text, ";", vbTextCompare)
   
   Do
      theValues(valueCount) = Val(Replace(Mid(text, prevPos + 1, nextPos - prevPos - 1), ",", "."))
      valueCount = valueCount + 1
      prevPos = nextPos
      nextPos = InStr(prevPos + 1, text, ";", vbTextCompare)
   Loop Until nextPos = 0
   
   theValues(valueCount) = Val(Replace(Right(text, Len(text) - prevPos), ",", "."))
   If theValues(valueCount) = 0 Then
      'terminated by ;
      valueCount = valueCount - 1
   End If
   
   'Sort the list
   Quick_sort theValues, 0, valueCount
   
   'Test for dublicates
   Dim counter As Integer
   Dim counter2 As Integer
   
   Dim previousValue As Double
   previousValue = theValues(0)
   counter = 1
   Do While (counter < valueCount)
      Do While (theValues(counter) = previousValue)
         'Remove a dublicate
         For counter2 = counter + 1 To valueCount
           theValues(counter2 - 1) = theValues(counter2)
         Next
         valueCount = valueCount - 1
      Loop
      previousValue = theValues(counter)
      counter = counter + 1
   Loop
   
   ReDim Preserve theValues(valueCount + 1)
   
   parseList = theValues
   
End Function

Public Sub SlopeCatflowFile(Slopes() As Slope, _
                            slopeTextStream As TextStream, _
                            x_reference As Double, _
                            y_reference As Double, _
                            z_reference As Double, _
                            EtaValues() As Double, _
                            XsiValues() As Double)
  
    Dim maxNumSlopePoints As Integer
    maxNumSlopePoints = 0
    Dim numOfSlopes As Integer
    numOfSlopes = UBound(Slopes) - LBound(Slopes)
    
    Dim NumberOfEtaValues As Integer
    Dim NumberOfXsiValues As Integer
     NumberOfEtaValues = UBound(EtaValues) - LBound(EtaValues)
     NumberOfEtaValues = UBound(EtaValues) - LBound(EtaValues)
    
    Dim counter As Integer
    Dim counter2 As Integer
    
    For counter = LBound(Slopes) To UBound(Slopes)
        If Slopes(counter).numberOfSlopePoints > maxNumSlopePoints Then
           maxNumSlopePoints = Slopes(counter).numberOfSlopePoints
        End If
    Next
    
    'Dataformat for Matlab preprocessing:
    'First line: numberOfSlopes (n), maxNumberOfSlopePoints, x_bez, y_bez, z_bez, number of Xsi, number of Eta
    slopeTextStream.WriteLine numOfSlopes + 1 & " " & _
            maxNumSlopePoints + 1 & _
            numberFormat(x_reference) & _
            numberFormat(y_reference) & _
            numberFormat(z_reference) & _
            " " & NumberOfXsiValues + 1 & " " & NumberOfEtaValues + 1
            
    'line 2 SlopeID
    For counter = LBound(Slopes) To UBound(Slopes)
        slopeTextStream.Write Slopes(counter).ID & " "
    Next
    slopeTextStream.WriteLine
    
    'line 3 SlopeType (Constant Thickness or 'Cake shape')
    For counter = LBound(Slopes) To UBound(Slopes)
        slopeTextStream.Write Slopes(counter).SlopeShapeType & " "
    Next
    slopeTextStream.WriteLine
    
    'line 4 Area
    For counter = LBound(Slopes) To UBound(Slopes)
        slopeTextStream.Write numberFormat(Slopes(counter).Area)
    Next
    slopeTextStream.WriteLine
    
    'line 5 Number of points
    For counter = LBound(Slopes) To UBound(Slopes)
        slopeTextStream.Write Slopes(counter).numberOfSlopePoints & " "
    Next
    slopeTextStream.WriteLine
    
    'line 6 Thickness of slope
    For counter = LBound(Slopes) To UBound(Slopes)
        slopeTextStream.Write numberFormat(Slopes(counter).Thickness)
    Next
    slopeTextStream.WriteLine
    
    'line 7 Eta Values
    For counter = 0 To NumberOfEtaValues
       slopeTextStream.Write numberFormat(EtaValues(counter))
    Next
    slopeTextStream.WriteLine
    
    'line 8 Xsi Values
    For counter = 0 To NumberOfXsiValues
       slopeTextStream.Write numberFormat(XsiValues(counter))
    Next
    slopeTextStream.WriteLine
    
    'Collect information about slopepoints
    ReDim breite(maxNumSlopePoints, LBound(Slopes) To UBound(Slopes)) As Double
    ReDim X(maxNumSlopePoints, LBound(Slopes) To UBound(Slopes)) As Double
    ReDim Y(maxNumSlopePoints, LBound(Slopes) To UBound(Slopes)) As Double
    ReDim Z(maxNumSlopePoints, LBound(Slopes) To UBound(Slopes)) As Double
    ReDim tempBreite(maxNumSlopePoints) As Double
    ReDim tempX(maxNumSlopePoints) As Double
    ReDim tempY(maxNumSlopePoints) As Double
    ReDim tempZ(maxNumSlopePoints) As Double
    
    For counter = LBound(Slopes) To UBound(Slopes)
        Slopes(counter).toMatlab tempBreite, tempX, tempY, tempZ
        For counter2 = 0 To maxNumSlopePoints
           breite(counter2, counter) = tempBreite(counter2)
           X(counter2, counter) = tempX(counter2)
           Y(counter2, counter) = tempY(counter2)
           Z(counter2, counter) = tempZ(counter2)
           tempBreite(counter2) = 0
           tempX(counter2) = 0
           tempY(counter2) = 0
           tempZ(counter2) = 0
        Next
    Next
    
    'line 9...8+n x of slopepoints
    For counter = LBound(Slopes) To UBound(Slopes)
        For counter2 = 0 To maxNumSlopePoints
          slopeTextStream.Write numberFormat(X(counter2, counter))
        Next
        slopeTextStream.WriteLine
    Next
    
    'line 9+n...8+2n y of slopepoints
    For counter = LBound(Slopes) To UBound(Slopes)
        For counter2 = 0 To maxNumSlopePoints
          slopeTextStream.Write numberFormat(Y(counter2, counter))
        Next
        slopeTextStream.WriteLine
    Next
    
    'line 9+2n...8+3n z of slopepoints
    For counter = LBound(Slopes) To UBound(Slopes)
        For counter2 = 0 To maxNumSlopePoints
          slopeTextStream.Write numberFormat(Z(counter2, counter))
        Next
        slopeTextStream.WriteLine
    Next
    
    'line 9+3n...8+4n width of slopepoints
    For counter = LBound(Slopes) To UBound(Slopes)
        For counter2 = 0 To maxNumSlopePoints
          slopeTextStream.Write numberFormat(breite(counter2, counter))
        Next
        slopeTextStream.WriteLine
    Next
    
End Sub


Public Function searchFeature(FeatureClass As IFeatureClass, fieldIndex As Long, Value As Integer) As IFeature

'loop through all features
Dim FID As Integer
Dim toReturn, currentFeature As IFeature

Set toReturn = Nothing

For FID = 0 To FeatureClass.featureCount(Nothing) - 1
    Set currentFeature = FeatureClass.GetFeature(FID)
    If (currentFeature.Value(fieldIndex) = Value) Then
        If Not (toReturn Is Nothing) Then
            Err.Raise vbObjectError, "CatflowUtil", "Multiple Features with same value " & Value & _
                " in field with index " & fieldIndex
        End If
        Set toReturn = currentFeature
    End If
Next

If (toReturn Is Nothing) Then
            Err.Raise vbObjectError, "CatflowUtil", "No Features with value " & Value & _
                " in field with index " & fieldIndex
End If

Set searchFeature = toReturn

End Function

Public Sub helptopic(part As String)
    Dim hWndHTMLHelp As Long
    hWndHTMLHelp = HTMLHelp(0&, helpfile & "::/" & part, HH_DISPLAY_TOPIC, Null)
    If Err.Number <> 0 Then
        Call MsgBox(Err.Description)
        Call Err.Clear
    End If

End Sub

Public Sub testRivernet()
       If Not TestFor3DAnalyst() Then
       MsgBox "Please Activate 3D Analyst Extension"
       Exit Sub
    End If
     
    Dim pMxDoc As IMxDocument
    'Dim pEnumFeature As IEnumFeature
    
    'Dim pRWS As IRasterWorkspace
    Dim pLayer As ILayer
    Dim m_pMap As IMap
    
    Dim d As IFunctionalSurface
    Dim polyline As IFeatureClass
 
    Set pMxDoc = Application.Document
    Set m_pMap = pMxDoc.FocusMap
    
    If m_pMap.LayerCount = 0 Then Exit Sub
    
    Dim layerIndex As Long
    
    For layerIndex = 0 To m_pMap.LayerCount - 1
       Set pLayer = m_pMap.Layer(layerIndex)
       If TypeOf pLayer Is IRasterLayer Then
          'Create IFunctionalSurface(TIN) or IRasterSurface from IRasterLayer
          Dim rasterLayer As IRasterLayer
          Dim surface As IRasterSurface
          
          Set rasterLayer = pLayer
          ' From ArcObjects Component Help (3DExt) IRasterSurface Example


          Dim p3DProp As I3DProperties
          Dim pLE As ILayerExtensions
          Set pLE = pLayer
          
          ' look for 3D properties of layer:
          Dim i As Integer
          For i = 0 To pLE.ExtensionCount - 1
            If TypeOf pLE.Extension(i) Is I3DProperties Then
              Set p3DProp = pLE.Extension(i)
              Exit For
            End If
          Next
        
        
          ' We want the IRasterSurface of the layer;
          ' Look first for base surface of layer itself:
          If Not p3DProp Is Nothing Then
            Set surface = p3DProp.BaseSurface
          End If
        
        
          ' if base surface of layer is not set, create the IRasterSurface from
          ' the first band of the raster:
          If surface Is Nothing Then
            If Not rasterLayer.Raster Is Nothing Then
              Set surface = New RasterSurface
              Dim pBands As IRasterBandCollection
              Set pBands = rasterLayer.Raster
              surface.RasterBand = pBands.Item(0)
            End If
          End If
        
        ' End From ArcObjects Component Help (3DExt) IRasterSurface Example
        
          
          'Set surface = New RasterSurface
          'surface.PutRaster rasterLayer.Raster, 1
          Set d = surface
       ElseIf TypeOf pLayer Is FeatureLayer Then
           Dim fl As IGeoFeatureLayer
           Set fl = pLayer
           Dim pFeatureClass As IFeatureClass
           Set pFeatureClass = fl.FeatureClass
           Dim pFeature As IFeature
           Dim pGeometryCollection As IGeometryCollection
           If pFeatureClass.ShapeType = esriGeometryPolyline Then
              Set polyline = pFeatureClass
           End If
       End If
    Next layerIndex
           

    If polyline Is Nothing Then
      MsgBox "No rivernet found"
      Exit Sub
    End If
    If d Is Nothing Then
      MsgBox "No DEM found"
      Exit Sub
    End If
    
  Dim fc_point As IFeatureClass
  Dim idFieldName As String
  Dim orderFieldName As String
  idFieldName = "SP_ID"
  orderFieldName = "Order"

  Set fc_point = CreateShapefile("slopeFallPoint", _
                          esriGeometryPoint, _
                           idFieldName, _
                           esriFieldTypeInteger, _
                           orderFieldName, _
                           esriFieldTypeInteger)
                           
  Dim idField As Integer
  Dim orderField As Integer
  idField = fc_point.FindField(idFieldName)
  orderField = fc_point.FindField(orderFieldName)
                           
  Dim r As RiverNet
  Set r = New RiverNet
  
  Set r.DEM = d
  Set r.polylines = polyline
  
  Dim points As IGeometryCollection
  Set points = r.RiverNetPoints()
  
                           
     
   'Insert single Features using a cursor
   Dim pFeatCur As IFeatureCursor
   Set pFeatCur = fc_point.Insert(True)
   
   
  'Create the point shape first
  For i = 0 To points.GeometryCount - 1
       Dim pFeatBuf As IFeatureBuffer
       Set pFeatBuf = fc_point.CreateFeatureBuffer
       Dim Point As IPoint
       Set Point = points.Geometry(i)
       Set pFeatBuf.Shape = Point
       pFeatBuf.Value(idField) = Point.ID
       pFeatBuf.Value(orderField) = Point.M
       Dim v As Variant 'ID of the new Feature
       v = pFeatCur.InsertFeature(pFeatBuf)
       
  Next i
  
  Set pFeatCur = Nothing
    
    Dim m_pApp As IApplication
    Set m_pApp = Application

    MiscUtil.AddFeatureLayer m_pApp, fc_point
End Sub


Public Sub testSlope()

    If Not TestFor3DAnalyst() Then
       MsgBox "Please Activate 3D Analyst Extension"
       Exit Sub
    End If
    
    'frmRasterEffectsSample for ideas
    Dim s As Slope
    Set s = New Slope
    
    Dim pMxDoc As IMxDocument
    'Dim pEnumFeature As IEnumFeature
    
    'Dim pRWS As IRasterWorkspace
    Dim pLayer As ILayer
    Dim m_pMap As IMap
    
    Dim d As IFunctionalSurface
    Dim polygon As IPolygon
    Dim line As IPath
    
    
    Set pMxDoc = Application.Document
    Set m_pMap = pMxDoc.FocusMap
    
    If m_pMap.LayerCount = 0 Then Exit Sub
    
    Dim layerIndex As Long
    
    For layerIndex = 0 To m_pMap.LayerCount - 1
       Set pLayer = m_pMap.Layer(layerIndex)
       If TypeOf pLayer Is IRasterLayer Then
          'Create IFunctionalSurface(TIN) or IRasterSurface from IRasterLayer
          Dim rasterLayer As IRasterLayer
          Dim surface As IRasterSurface
          
          Set rasterLayer = pLayer
          ' From ArcObjects Component Help (3DExt) IRasterSurface Example


          Dim p3DProp As I3DProperties
          Dim pLE As ILayerExtensions
          Set pLE = pLayer
          
          ' look for 3D properties of layer:
          Dim i As Integer
          For i = 0 To pLE.ExtensionCount - 1
            If TypeOf pLE.Extension(i) Is I3DProperties Then
              Set p3DProp = pLE.Extension(i)
              Exit For
            End If
          Next
        
        
          ' We want the IRasterSurface of the layer;
          ' Look first for base surface of layer itself:
          If Not p3DProp Is Nothing Then
            Set surface = p3DProp.BaseSurface
          End If
        
        
          ' if base surface of layer is not set, create the IRasterSurface from
          ' the first band of the raster:
          If surface Is Nothing Then
            If Not rasterLayer.Raster Is Nothing Then
              Set surface = New RasterSurface
              Dim pBands As IRasterBandCollection
              Set pBands = rasterLayer.Raster
              surface.RasterBand = pBands.Item(0)
            End If
          End If
        
        ' End From ArcObjects Component Help (3DExt) IRasterSurface Example
        
          
          'Set surface = New RasterSurface
          'surface.PutRaster rasterLayer.Raster, 1
          Set d = surface
       ElseIf TypeOf pLayer Is FeatureLayer Then
           Dim fl As IGeoFeatureLayer
           Set fl = pLayer
           Dim pFeatureClass As IFeatureClass
           Set pFeatureClass = fl.FeatureClass
           Dim pFeature As IFeature
           Dim pGeometryCollection As IGeometryCollection
           If pFeatureClass.ShapeType = esriGeometryPolygon Then
              'Get the first shape and use it as catchment
              Set pFeature = pFeatureClass.GetFeature(0)
              Set polygon = pFeature.ShapeCopy
           ElseIf pFeatureClass.ShapeType = esriGeometryPolyline Then
              'Get the first shape and use it as slopefallline
              Set pFeature = pFeatureClass.GetFeature(0)
              Set pGeometryCollection = pFeature.ShapeCopy
              If Not pGeometryCollection.GeometryCount = 1 Then
                     MsgBox "The line feature does not consist of a single, " & _
                         "connected path. Please check for missing connections " & _
                         "and points where the line splits."
                    Exit Sub
              End If
              Set line = pGeometryCollection.Geometry(0)
           End If
       End If
    Next layerIndex
           
    If line Is Nothing Then
      MsgBox "No slope fall line found"
      Exit Sub
    End If
    If polygon Is Nothing Then
      MsgBox "No subcatchment found"
      Exit Sub
    End If
    If d Is Nothing Then
      MsgBox "No DEM found"
      Exit Sub
    End If
    
    
    'Dim pGraphicsContainer As IGraphicsContainer
    'Set pGraphicsContainer = pMxDoc.FocusMap
    'Set pEnumFeature = pMxDoc.FocusMap.FeatureSelection
    
    'pEnumFeature.Reset
    'Set pFeature = pEnumFeature.Next
  
    'Do While Not pFeature Is Nothing
      'Determine the geometry type
      'Select Case pFeature.Shape.GeometryType
        'Case esriGeometryPoint
          'Set pElement = New MarkerElement
        'Case esriGeometryPolyline
          'Set pElement = New LineElement
        'Case esriGeometryPolygon
          'Set pElement = New PolygonElement
      'End Select
      

  Dim fc_point As IFeatureClass
  Dim fc_poly As IFeatureClass
  Dim idFieldName As String
  Dim widthFieldName As String
  Dim areaFieldName As String
  
  idFieldName = "SP_ID"
  widthFieldName = "Width"
  areaFieldName = "Area"
  
  Set fc_point = CreateShapefile("slopeFallPoint", _
                          esriGeometryPoint, _
                           idFieldName, _
                           esriFieldTypeInteger, _
                           widthFieldName, _
                           esriFieldTypeDouble)
   idFieldName = "Unused"
  Set fc_poly = CreateShapefile("thiessen", _
                           esriGeometryPolygon, _
                           idFieldName, _
                           esriFieldTypeInteger, _
                           areaFieldName, _
                           esriFieldTypeDouble)
                           
    
    s.ID = 1
    Set s.SlopePolygon = polygon
    Set s.SlopeFallLine = line
    Set s.DEM = d
    Set s.SlopePointFeatureClass = fc_point
    Set s.ThiessenPolygonFeatureClass = fc_poly
      
    s.updatePointFeatureClass
    
    s.updateThiessenFeatureClass
    
    Dim m_pApp As IApplication
    Set m_pApp = Application
 
    MiscUtil.AddFeatureLayer m_pApp, fc_poly
    MiscUtil.AddFeatureLayer m_pApp, fc_point
End Sub

Public Function TestFor3DAnalyst() As Boolean

' Get the IExtensionConfig interface from the 3D extension object
     Dim pExtConfig As IExtensionConfig
     Set pExtConfig = Application.FindExtensionByName("3D Analyst")
     
' Indicate whether a license has been checked out.
     TestFor3DAnalyst = (pExtConfig.state = esriESEnabled)
End Function


Public Function CreateShapefile(title As String, pType As esriGeometryType, idFieldName As String, idFieldType As esriFieldType, otherFieldName As String, otherFieldType As esriFieldType) As IFeatureClass
    
    'from GetSpatialReferenceInfo
    
    ' +++ Set up browser
    Dim pBrowser As IGxDialog
    Set pBrowser = New GxDialog
    Dim pEnumGX As IEnumGxObject

    ' +++ Open browser
    Dim blnFlag As Boolean
    pBrowser.title = title
    pBrowser.ButtonCaption = "Save"
    pBrowser.AllowMultiSelect = False
    pBrowser.RememberLocation = True
    Set pBrowser.ObjectFilter = New GxFilterFeatureClasses
  
 
    ' +++ Open browser
    blnFlag = pBrowser.DoModalSave(0)
    If blnFlag = False Then Exit Function
    
    Dim folder As IGxObject
    Set folder = pBrowser.FinalLocation
    
  
   ' see utilities, createnewShapefile for example how to get filename

  Dim strFolder As String
  Dim strName As String
  strFolder = folder.FullName
  strName = pBrowser.Name
  If Right(strName, 4) = ".shp" Then
      strName = Left(strName, Len(strName) - 4)
  End If
  Dim strShapeFieldName As String
  strShapeFieldName = "Shape"
  
  'This does not work
  'If pBrowser.ReplacingObject = True Then
  'End If
  
  'Test for existing File
  If fileExists(strFolder, strName) Then Exit Function
  '   Err.Raise vbObjectError, "Slope.Initialize", "Directory " & _
  '         strFolder & " does not exist."
  'End If
  
  ' Open the folder to contain the shapefile as a workspace
  Dim pFWS As IFeatureWorkspace
  Dim pWorkspaceFactory As IWorkspaceFactory
  Set pWorkspaceFactory = New ShapefileWorkspaceFactory
  Set pFWS = pWorkspaceFactory.OpenFromFile(strFolder, 0)
  
  ' Set up a simple fields collection
  Dim pFields As IFields
  Dim pFieldsEdit As IFieldsEdit
  Set pFields = New esriGeoDatabase.Fields
  Set pFieldsEdit = pFields
  
  Dim pField As IField
  Dim pFieldEdit As IFieldEdit
  
  ' Make the shape field
  ' it will need a geometry definition, with a spatial reference
  Set pField = New esriGeoDatabase.Field
  Set pFieldEdit = pField
  pFieldEdit.Name = strShapeFieldName
  pFieldEdit.Type = esriFieldTypeGeometry
  
  Dim pGeomDef As IGeometryDef
  Dim pGeomDefEdit As IGeometryDefEdit
  Set pGeomDef = New GeometryDef
  Set pGeomDefEdit = pGeomDef
  With pGeomDefEdit
    .GeometryType = pType
    Set .SpatialReference = New UnknownCoordinateSystem
  End With
  Set pFieldEdit.GeometryDef = pGeomDef
  pFieldsEdit.AddField pField

  ' Add id field
  Set pField = New esriGeoDatabase.Field
  Set pFieldEdit = pField
  With pFieldEdit
      .Name = idFieldName
      .Type = idFieldType
  End With
  pFieldsEdit.AddField pField
  
  ' Add another field
  Set pField = New esriGeoDatabase.Field
  Set pFieldEdit = pField
  With pFieldEdit
      .Name = otherFieldName
      .Type = otherFieldType
  End With
  pFieldsEdit.AddField pField
  
  ' Create the shapefile
  ' (some parameters apply to geodatabase options and can be defaulted as Nothing)
  Dim pFeatClass As IFeatureClass
  
CreateFeature:
'  On Error GoTo Err_notCreated
    Set pFeatClass = pFWS.CreateFeatureClass(strName, pFields, Nothing, _
                                          Nothing, esriFTSimple, strShapeFieldName, "")
'  On Error GoTo 0
  Set CreateShapefile = pFeatClass
'  Exit Function
  
'Err_notCreated:
'  MsgBox Err.Description
'  GoTo CreateFeature
  
End Function
Public Function fileExists(dir As String, strName As String) As Boolean
   Dim fs As FileSystemObject
   Set fs = CreateObject("Scripting.FileSystemObject")
   
   Dim FileName As String
   FileName = dir & "\" & strName & "."
   If fs.fileExists(FileName & "shp") Then
      Dim answ As Integer
      answ = MsgBox(FileName & "shp exists! " & Chr(13) & _
         "Delete all files " & FileName & "* ?", vbYesNo)
      If answ = vbYes Then
         fs.DeleteFile FileName & "*", True
      Else
         fileExists = True
         Exit Function
      End If
   End If
   fileExists = False
       
       
End Function

Private Function testForDirectory(dir As String, strName As String) As Boolean
   Dim fs As FileSystemObject
   Set fs = CreateObject("Scripting.FileSystemObject")
   testForDirectory = fs.FolderExists(dir)
   
   Dim FileName As String
   FileName = dir & "\" & strName & "."
   If fs.fileExists(FileName & "shp") Then
      fs.DeleteFile FileName & "*", True
   End If
       
       
End Function

Public Static Function positiveRoundUp(dblValue As Double) As Integer
  ' Copied from Thiessen.frm
  ' This function always rounds a number up if it contains a fraction.
  '
  If dblValue < 0 Then
    positiveRoundUp = 0
  Else
    If (dblValue - Int(dblValue)) > 0 Then
      positiveRoundUp = Int(dblValue) + 1
    Else
      positiveRoundUp = Int(dblValue)
    End If
  End If
End Function

Public Function findNearest(from As IPoint, compare As Multipoint) As IPoint

  Dim coll As IGeometryCollection
  Set coll = compare
  
  Dim nearest As IPoint
  Dim counter As Integer
  Dim current As Integer
  Dim dist As Double
  Dim newDist As Double
  
  
  Set nearest = coll.Geometry(0)
  dist = distance(from, nearest)
  
  
  For counter = 1 To coll.GeometryCount - 1
     newDist = distance(from, coll.Geometry(counter))
     If (dist > newDist) Then
          dist = newDist
          current = counter
          Set nearest = coll.Geometry(counter)
     End If
  Next
  Set findNearest = nearest
  'Debug.Print from.X & ", " & from.Y & ", " & current & ", " & dist
End Function

Public Function distance(from As IPoint, toPoint As IPoint) As Double
   distance = Sqr((from.X - toPoint.X) ^ 2 + (from.Y - toPoint.Y) ^ 2)
End Function

Public Function numberFormat(n As Double) As String
    Dim a As String
    a = Replace(Format(n, "0.00000"), ",", ".")
    Do While Len(a) < 16
       a = " " & a
    Loop
    numberFormat = a
End Function


Public Sub parseValue(inValue As String, store As Double, theType As Integer)
   
   Dim parsed As Double
   parsed = Val(inValue)
   On Error GoTo parse_notValid
   testValue parsed, theType
   store = parsed
parse_exit:
   Exit Sub
parse_notValid:
   MsgBox Err.Description, , "Error setting value"
   Resume parse_exit
End Sub

Public Sub testValue(theValue As Double, theType As Integer)
   
   Select Case theType
          Case positiveValue
              If theValue <= 0 Then
                 Err.Raise vbObjectError, "testValue", "Value must be > 0"
              End If
          Case positiveOrZeroValue
              If theValue < 0 Then
                 Err.Raise vbObjectError, "testValue", "Value must be >= 0"
              End If
          Case negativeValue
              If theValue >= 0 Then
                 Err.Raise vbObjectError, "testValue", "Value must be < 0"
              End If
          Case negativeOrZeroValue
              If theValue > 0 Then
                 Err.Raise vbObjectError, "testValue", "Value must be <= 0"
              End If
          Case booleanValue
              If Not (theValue = 0 Or theValue = 1) Then
                 Err.Raise vbObjectError, "testValue", "Value must be 1 (true) or 0 (false)"
              End If
          Case everyValue
             
   End Select
   
   
End Sub


' Single Dimension Sort with Single Compare -- either 0 or 1 based
' ***************************************************************************
' Source: http://www.vba-programmer.com/VB_Code/Quick_Sort_Single.txt
' 25.8.04
Public Sub Quick_sort(ByRef SortArray As Variant, ByVal First As Long, ByVal Last As Long)
  Dim Low As Long, High As Long
  Dim Temp As Variant, List_Separator As Variant
  Low = First
  High = Last
  List_Separator = SortArray((First + Last) / 2)
  Do
    Do While (SortArray(Low) < List_Separator)
      Low = Low + 1
    Loop
    Do While (SortArray(High) > List_Separator)
      High = High - 1
    Loop
    If (Low <= High) Then
      Temp = SortArray(Low)
      SortArray(Low) = SortArray(High)
      SortArray(High) = Temp
      Low = Low + 1
      High = High - 1
    End If
  Loop While (Low <= High)
  If (First < High) Then Quick_sort SortArray, First, High
  If (Low < Last) Then Quick_sort SortArray, Low, Last
End Sub


' ////////////////////////////////////////////////////////////////
' // See also: Array Converted to Delimited Text String
' //           Building an Array of Filenames (after browse)
' //           Delimited Text to an Array (similar to Split())
' //           Determining Upper & Lower Array Bounds
' //           Erasing an Array (removing all the elements)
' //           Feed an Array into a New Document (del dupes)
' //           Filename Array from Active Directory
' //           QuickSort (Fast!!) (Multidimensional on 2 dims)
' //           QuickSort (Fast!!) (Multidimensional on 3 dims)
' //           QuickSort (Fast!!) (Single Dimension)
' //           Removing Duplicates from an Array
' //           SQL Query Results placed in an Array
' //           Using Split() function to create Array
' ////////////////////////////////////////////////////////////////

Public Sub releaseLock(pFeatClass As IFeatureClass)
  'This is copied and modified from AddXY.frm
  
  
  ' If appropriate, finish the edit session
  Dim pDataset As IDataset
  Set pDataset = pFeatClass
  Dim pWorkspaceEdit As IWorkspaceEdit
  Set pWorkspaceEdit = pDataset.Workspace
  
  If pWorkspaceEdit.IsBeingEdited Then
    pWorkspaceEdit.StopEditOperation
    pWorkspaceEdit.StopEditing True
  End If
  
  ' Release the lock on the dataset
  Dim pSchemalock As ISchemaLock
  Set pSchemalock = pFeatClass
  pSchemalock.ChangeSchemaLock esriSharedSchemaLock

End Sub

Public Function getFeatureCursor(pFeatClass As IFeatureClass, _
                                  fieldNames() As String, _
                                  ByRef fieldIDs() As Integer, _
                                  Optional whereClause As String = "" _
                                  ) As IFeatureCursor
  'Check passed variables
  If pFeatClass Is Nothing Then
        Err.Raise vbObjectError, _
             "Slope.getFeatureCursor", _
             "Feature class must not be nothing"
  End If
  If (LBound(fieldNames) <> LBound(fieldIDs)) _
     Or (UBound(fieldNames) <> UBound(fieldIDs)) Then
           Err.Raise vbObjectError, _
             "Slope.getFeatureCursor", _
             "filedNames and fieldIDs arrays must have same size"
  End If
  If (UBound(fieldNames) - LBound(fieldNames)) < 0 Then
        Err.Raise vbObjectError, _
             "Slope.getFeatureCursor", _
             "At least one field required for featureCursor"
  End If
  
  
  
  'Construct String with fieldNames
  'i.e. firstFieldName & "," & secondFieldName
  Dim subFieldNames As String
  subFieldNames = fieldNames(LBound(fieldNames))
  Dim counter As Integer
  For counter = LBound(fieldNames) + 1 To UBound(fieldNames)
    subFieldNames = subFieldNames & "," & fieldNames(counter)
  Next
  
  Dim pQueryFilter As IQueryFilter
  Set pQueryFilter = New QueryFilter
  pQueryFilter.SubFields = subFieldNames
  If Not (whereClause = "") Then
       pQueryFilter.whereClause = whereClause
  End If
  
  
  ' Create the update feature cursor
  Set getFeatureCursor = pFeatClass.Update(pQueryFilter, False)
  
  ' Get the positions of the fields to update
  For counter = LBound(fieldIDs) To UBound(fieldIDs)
    fieldIDs(counter) = getFeatureCursor.FindField(fieldNames(counter))
  Next
  
End Function
  ' Returns TRUE if the Table can be edited outside of an edit session
  ' Copied from AddXY.frm (ESRI Developer Help)
Public Function canEditWOEditSession(pTable As ITable) As Boolean

  Dim pVersionedObject As IVersionedObject
  Dim pObjClassInfo2 As IObjectClassInfo2
  Dim bolVersioned As Boolean
  Dim bolEditable As Boolean
  
  ' See if the data is versioned
  If Not TypeOf pTable Is IVersionedObject Then
    bolVersioned = False
  Else
    Set pVersionedObject = pTable
    bolVersioned = pVersionedObject.IsRegisteredAsVersioned
  End If
  
  ' Check the CanBypassEditSession property
  Set pObjClassInfo2 = pTable
  bolEditable = pObjClassInfo2.CanBypassEditSession

  If bolEditable And Not bolVersioned Then
    canEditWOEditSession = True
  Else
    canEditWOEditSession = False
  End If

End Function

