Attribute VB_Name = "MiscUtil"
'
' ESRI
' 3D Analyst Developer Sample Utility
' miscUtil.bas
' Methods for general ArcGIS data and Application tasks
'
' Requires references to
' ESRI ArcScene Object Library
' ESRI ArcMap Object Library
' ESRI TIN Object Library
' ESRI Object Library

Option Explicit

Private m_sErrorMsg As String
Private m_lErrorCode As Long

' SET CURSOR
Public Declare Function SetCursor Lib "user32" (ByVal hCursor As Long) As Long
Public Const CURSOR_HOURGLASS = 10
Public Const CURSOR_DEFAULT = 8

' SLEEP
Public Declare Sub Sleep Lib "kernel32" (ByVal dwMilliseconds As Long)

' WINDOW POSITIONING
Declare Function SetWindowPos Lib "user32" ( _
  ByVal hWnd As Long, ByVal hWndInsertAfter As Long, _
  ByVal X As Long, ByVal Y As Long, ByVal cx As Long, _
  ByVal cy As Long, ByVal wFlags As Long) As Long

' SetWindowPos Flags
Public Const SWP_NOSIZE = &H1
Public Const SWP_NOMOVE = &H2
Public Const SWP_NOZORDER = &H4
Public Const SWP_NOREDRAW = &H8
Public Const SWP_NOACTIVATE = &H10
Public Const SWP_FRAMECHANGED = &H20
Public Const SWP_SHOWWINDOW = &H40
Public Const SWP_HIDEWINDOW = &H80
Public Const SWP_NOCOPYBITS = &H100
Public Const SWP_NOOWNERZORDER = &H200
Public Const SWP_DRAWFRAME = SWP_FRAMECHANGED
Public Const SWP_NOREPOSITION = SWP_NOOWNERZORDER
Public Const FLAGS As Long = SWP_NOMOVE Or SWP_NOSIZE
Public Const HWND_TOP = 0
Public Const HWND_BOTTOM = 1
Public Const HWND_TOPMOST = -1
Public Const HWND_NOTOPMOST = -2

Public Sub SetWin_NOTOPMOST(hWnd As Long)
  SetWindowPos hWnd, HWND_NOTOPMOST, 0, 0, 0, 0, FLAGS
End Sub

Public Sub SetWin_TOPMOST(hWnd As Long)
  SetWindowPos hWnd, HWND_TOPMOST, 0, 0, 0, 0, FLAGS
End Sub
'
'  return the ILayer of the selected layer in the TOC of the
'  current SX or MX document
'
Public Function GetSelectedLayer() As ILayer
  On Error GoTo EH
  
  Dim pSxDoc As ISxDocument
  Dim pMxDoc As IMxDocument
  Dim pApp As IApplication
  Set pApp = New AppRef
  
  If TypeOf pApp.Document Is ISxDocument Then
    Set pSxDoc = pApp.Document
    Set GetSelectedLayer = pSxDoc.SelectedLayer
    Exit Function

  ElseIf TypeOf pApp.Document Is IMxDocument Then
    Set pMxDoc = pApp.Document
    Set GetSelectedLayer = pMxDoc.SelectedLayer
    Exit Function
  End If
  
  Exit Function
    
EH:

End Function

'
'  find the layer by name and return its' feature cursor
'
Public Function GetFeatureCursorFromLayer(sLayerName As String) As IFeatureCursor
  On Error GoTo EH
  
  Dim pLayer As ILayer
  Dim pSxDoc As ISxDocument
  Dim pMxDoc As IMxDocument
  Dim pEnumLayers As IEnumLayer
  Dim pFeatClass As IFeatureClass
  Dim pFeatLayer As IFeatureLayer
  Dim pFeatCursor As IFeatureCursor

  Dim pApp As IApplication
  Set pApp = New AppRef
  
  '  get the document
  If TypeOf pApp.Document Is ISxDocument Then
    Set pSxDoc = pApp.Document
    Set pEnumLayers = pSxDoc.Scene.Layers
      
  ElseIf TypeOf pApp.Document Is IMxDocument Then
    Set pMxDoc = pApp.Document
    Set pEnumLayers = pMxDoc.FocusMap.Layers
  End If
      
  If pEnumLayers Is Nothing Then Exit Function
  
  ' find the requested layer:
  Set pLayer = pEnumLayers.Next
  Do While Not pLayer Is Nothing
    If UCase(pLayer.Name) = UCase(sLayerName) Then Exit Do
    Set pLayer = pEnumLayers.Next
  Loop
    
  If pLayer Is Nothing Then
    ' layer not found:
    Exit Function
  End If
    

  ' get the feature cursor:
  Set pFeatLayer = pLayer
  Set pFeatClass = pFeatLayer.FeatureClass
  Set pFeatCursor = pFeatClass.Search(Nothing, False)
    
  ' return:
  Set GetFeatureCursorFromLayer = pFeatCursor
    
  Exit Function
    
EH:

End Function
'
'  return the envelope of the layer with name passed in
'
Public Function GetDomainFromLayer(sLayerName As String) As IEnvelope
  On Error GoTo EH
  
  Dim pLayer As ILayer
  Dim pSxDoc As ISxDocument
  Dim pMxDoc As IMxDocument
  Dim pEnumLayers As IEnumLayer
  Dim pRasterLayer As IRasterLayer
  Dim pTinLayer As ITinLayer
  Dim pFeatureLayer As IFeatureLayer
  Dim pGeo As IGeoDataset
  Dim pApp As IApplication
  Set pApp = New AppRef
  
  '  get the document
  If TypeOf pApp.Document Is ISxDocument Then
    Set pSxDoc = pApp.Document
    Set pEnumLayers = pSxDoc.Scene.Layers
      
  ElseIf TypeOf pApp.Document Is IMxDocument Then
    Set pMxDoc = pApp.Document
    Set pEnumLayers = pMxDoc.FocusMap.Layers
  End If
      
  If pEnumLayers Is Nothing Then Exit Function
    
'  find the requested layer:
  Set pLayer = pEnumLayers.Next
  Do While Not pLayer Is Nothing
    If UCase(pLayer.Name) = UCase(sLayerName) Then Exit Do
    Set pLayer = pEnumLayers.Next
  Loop
  
  If pLayer Is Nothing Then
    ' not found:
    Exit Function
  End If
    
'  QI the geodataset:
  If TypeOf pLayer Is IRasterLayer Then
    Set pRasterLayer = pLayer
    Set pGeo = pRasterLayer
  ElseIf TypeOf pLayer Is ITinLayer Then
    Set pTinLayer = pLayer
    Set pGeo = pTinLayer.Dataset
  ElseIf TypeOf pLayer Is IFeatureLayer Then
    Set pFeatureLayer = pLayer
    Set pGeo = pFeatureLayer
    
  End If
    
  '  return extent if found:
  If Not pGeo Is Nothing Then
    Set GetDomainFromLayer = pGeo.Extent
  End If

  Exit Function
    
EH:

End Function

'
'   return an IArray of selected layers in current document
'
Public Function GetSelectedLayers() As IArray
  Dim pSxDoc As ISxDocument
  Dim pMxDoc As IMxDocument
  Dim pTOC  As IContentsView
  Dim i As Integer
  Dim pScene As IScene
  Dim ppSet As ISet
  Dim P
  Dim pLayers As IArray
  Dim pLayer As ILayer
  Dim pApp As IApplication
  
  On Error GoTo GetDocLayers_ERR
  
  Set pApp = New AppRef
  
  Dim bOnlySelected As Boolean
  bOnlySelected = True
  
  If TypeOf pApp.Document Is ISxDocument Then
    Set pSxDoc = pApp.Document
    Set pScene = pSxDoc.Scene
    
    If Not bOnlySelected Then
      Set pLayers = New esriSystem.Array
      For i = 0 To pScene.LayerCount - 1
        pLayers.Add pScene.Layer(i)
      Next
      Set GetSelectedLayers = pLayers
      Exit Function
    Else
      Dim pSxTOC As ISxContentsView
      Set pSxTOC = pSxDoc.ContentsView(0)
    End If
      
  ElseIf TypeOf pApp.Document Is IMxDocument Then
    Set pMxDoc = pApp.Document
    
    If Not bOnlySelected Then
      Set pLayers = New esriSystem.Array
      For i = 0 To pMxDoc.FocusMap.LayerCount - 1
        pLayers.Add pMxDoc.FocusMap.Layer(i)
      Next
      Set GetSelectedLayers = pLayers
      Exit Function
    Else
      Set pTOC = pMxDoc.ContentsView(0)
    End If
        
  End If
    
  If Not pTOC Is Nothing Then
    If IsNull(pTOC.SelectedItem) Then Exit Function
    Set P = pTOC.SelectedItem
  ElseIf Not pSxTOC Is Nothing Then
    If IsNull(pSxTOC.SelectedItem) Then Exit Function
    Set P = pSxTOC.SelectedItem
  End If
  
  Set pLayers = New esriSystem.Array
    

  If TypeOf P Is ISet Then
    Set ppSet = P
    ppSet.Reset
    For i = 0 To ppSet.count
      Set pLayer = ppSet.Next
      If Not pLayer Is Nothing Then
        pLayers.Add pLayer
      End If
    Next
  ElseIf TypeOf P Is ILayer Then
    Set pLayer = P
    pLayers.Add pLayer
  End If
    
  Set GetSelectedLayers = pLayers
  
  Exit Function
  
GetDocLayers_ERR:
  Debug.Print "GetDocLayers_ERR: " & Err.Description
  Debug.Assert 0

End Function

'
'   return an IArray of (selected) layers in current document
'
Public Function GetDocLayers(Optional bOnlySelected As Boolean) As IArray
  Dim pSxDoc As ISxDocument
  Dim pMxDoc As IMxDocument
  Dim pTOC  As IContentsView
  Dim i As Integer
  Dim pScene As IScene
  Dim ppSet As ISet
  Dim P
  Dim pLayers As IArray
  Dim pLayer As ILayer
  Dim pApp As IApplication
  
  On Error GoTo GetDocLayers_ERR
  Set pApp = New AppRef

  If TypeOf pApp.Document Is ISxDocument Then
    Set pSxDoc = pApp.Document
    Set pScene = pSxDoc.Scene
    
    If Not bOnlySelected Then
      Set pLayers = New esriSystem.Array
      For i = 0 To pScene.LayerCount - 1
          pLayers.Add pScene.Layer(i)
      Next
      Set GetDocLayers = pLayers
      Exit Function
    Else
      Dim pSxTOC As ISxContentsView
      Set pSxTOC = pSxDoc.ContentsView(0)
    End If
    
  ElseIf TypeOf pApp.Document Is IMxDocument Then
    Set pMxDoc = pApp.Document
    
    If Not bOnlySelected Then
      Set pLayers = New esriSystem.Array
      For i = 0 To pMxDoc.FocusMap.LayerCount - 1
        pLayers.Add pMxDoc.FocusMap.Layer(i)
      Next
      Set GetDocLayers = pLayers
      Exit Function
    Else
      Set pTOC = pMxDoc.ContentsView(0)
    End If
    
  End If
  
  If Not pTOC Is Nothing Then
    If IsNull(pTOC.SelectedItem) Then Exit Function
    Set P = pTOC.SelectedItem
  ElseIf Not pSxTOC Is Nothing Then
    If IsNull(pSxTOC.SelectedItem) Then Exit Function
    Set P = pSxTOC.SelectedItem
  End If
  
  Set pLayers = New esriSystem.Array
  
  If TypeOf P Is ISet Then
    Set ppSet = P
    ppSet.Reset
    For i = 0 To ppSet.count
      Set pLayer = ppSet.Next
      If Not pLayer Is Nothing Then
        pLayers.Add pLayer
      End If
    Next
  ElseIf TypeOf P Is ILayer Then
    Set pLayer = P
    pLayers.Add pLayer
  End If
  
  Set GetDocLayers = pLayers
  
  Exit Function
    
GetDocLayers_ERR:
  Debug.Assert 0
  ' for debugging:
  On Error Resume Next
  If TypeOf Application Is ISxApplication Then
    Set pApp = Application
    Resume Next
  End If
  
End Function

'
'  accept a layername or index and return the corresponding ILayer
'
Public Function GetLayer(sLayer) As ILayer
  Dim pSxDoc As ISxDocument
  Dim pMxDoc As IMxDocument
  Dim pTOCs As ISxContentsView
  Dim pTOC  As IContentsView
  Dim i As Integer
  Dim pLayers As IEnumLayer
  Dim pLayer As ILayer
  
  On Error GoTo GetLayer_Err

  Dim pApp As IApplication
  Set pApp = New AppRef
  
  If IsNumeric(sLayer) Then
    '  if numeric index:
    If TypeOf pApp.Document Is ISxDocument Then
      Set pSxDoc = pApp.Document
      Set GetLayer = pSxDoc.Scene.Layer(sLayer)
    ElseIf TypeOf pApp.Document Is IMxDocument Then
      Set pMxDoc = pApp.Document
      Set GetLayer = pMxDoc.FocusMap.Layer(sLayer)
      Exit Function
    End If
  
  Else
    '  iterate through document layers looking for a name match:
    If TypeOf pApp.Document Is ISxDocument Then
      Set pSxDoc = pApp.Document
      Set pLayers = pSxDoc.Scene.Layers

      Set pLayer = pLayers.Next
      Do While Not pLayer Is Nothing
        If UCase(sLayer) = UCase(pLayer.Name) Then
          Set GetLayer = pLayer
          Exit Function
        End If
        Set pLayer = pLayers.Next
      Loop
            
    ElseIf TypeOf pApp.Document Is IMxDocument Then
      Set pMxDoc = pApp.Document
      Set pLayers = pMxDoc.FocusMap.Layers

      Set pLayer = pLayers.Next
      Do While Not pLayer Is Nothing
        If UCase(sLayer) = UCase(pLayer.Name) Then
          Set GetLayer = pLayer
          Exit Function
        End If
        Set pLayer = pLayers.Next
      Loop
    End If
  End If
  
  Exit Function
    
GetLayer_Err:
    
End Function

'
'  given an ILayer, return the full path to it's data
'
Public Function ReturnLayerFullPath(pLayer As ILayer) As String
  On Error GoTo EH
  
  Dim pDS As IDataset
  Dim pFC As IFeatureClass
  Dim pFLayer As IFeatureLayer
  Dim pTLayer As ITinLayer
  Dim pRLayer As IRasterLayer
  Dim sPath As String
  
  If TypeOf pLayer Is IFeatureLayer Then
    Set pFLayer = pLayer
    Set pFC = pFLayer.FeatureClass
    Set pDS = pFC
    sPath = pDS.Workspace.PathName
    If Right(sPath, 1) <> "\" Then sPath = sPath & "\"
    sPath = sPath & pDS.BrowseName
    
  ElseIf TypeOf pLayer Is ITinLayer Then
    Set pTLayer = pLayer
    Set pDS = pTLayer.Dataset
    sPath = pDS.Workspace.PathName
    If Right(sPath, 1) <> "\" Then sPath = sPath & "\"
    sPath = sPath & pDS.BrowseName
  ElseIf TypeOf pLayer Is IRasterLayer Then
    Set pRLayer = pLayer
    sPath = pRLayer.filePath
  End If
  
  ReturnLayerFullPath = sPath
  Exit Function
    
EH:

End Function
'
'  return the ITinSurface if found from the layer with the given index
'
Public Function GetTINSurfaceFromLayer(sLayer) As ITinSurface
  On Error GoTo EH
  
  Dim pLayer As ITinLayer
  Dim pTin As ITin

  '  get the layer:
  Set pLayer = GetLayer(sLayer)
  
  '  layer not found:
  If pLayer Is Nothing Then Exit Function
  
  '  get the dataset and QI the returned surface from it:
  Set pTin = pLayer.Dataset
  
  If Not pTin Is Nothing Then
    Set GetTINSurfaceFromLayer = pTin
  End If
    
  Exit Function
    
EH:
End Function

Public Sub AddLayer(pApp As IApplication, pLayer As ILayer)
  Dim pMap As IBasicMap
  If (TypeOf pApp Is IMxApplication) Then
    Dim pMxDoc As IMxDocument
    Set pMxDoc = pApp.Document
    Set pMap = pMxDoc.ActiveView.FocusMap
  ElseIf (TypeOf pApp Is ISxApplication) Then
    Dim pSxDoc As ISxDocument
    Set pSxDoc = pApp.Document
    Set pMap = pSxDoc.Scene
  End If
  pMap.AddLayer pLayer
End Sub

Public Sub AddFeatureLayer(pApp As IApplication, pFClass As IFeatureClass)
  Dim pLayer As IFeatureLayer
  Set pLayer = New FeatureLayer
  Dim pDataset As esriGeoDatabase.IDataset
  Set pDataset = pFClass
  pLayer.Name = pDataset.Name
  Set pLayer.FeatureClass = pFClass
  AddLayer pApp, pLayer
End Sub
 
Public Sub AddRasterLayer(pApp As IApplication, pRaster As IRaster, Optional sName As String)
  Dim pRasterLayer As IRasterLayer
  Set pRasterLayer = New rasterLayer
  pRasterLayer.CreateFromRaster pRaster
  If (sName = "") Then
    Dim pRasterBands As IRasterBandCollection
    Set pRasterBands = pRaster
    Dim pRasterBand As IRasterBand
    Set pRasterBand = pRasterBands.Item(0)
    Dim pDS As IDataset
    Set pDS = pRasterBand.RasterDataset
    pRasterLayer.Name = pDS.BrowseName
  Else
    pRasterLayer.Name = sName
  End If
  AddLayer pApp, pRasterLayer
End Sub

Public Sub RedrawLayer(pApp As IApplication, pLayer As ILayer)
  If (TypeOf pApp Is IMxApplication) Then
    Dim pMxDoc As IMxDocument
    Set pMxDoc = pApp.Document
    pMxDoc.ActiveView.PartialRefresh esriDPGeography, pLayer, Nothing
  ElseIf (TypeOf pApp Is ISxApplication) Then
    Dim pSxDoc As ISxDocument
    Set pSxDoc = pApp.Document
    Dim pSG As ISceneGraph
    Set pSG = pSxDoc.Scene.SceneGraph
    pSG.Invalidate pLayer, True, False
    pSG.RefreshViewers
  End If
End Sub

' Returns true if able to determine a valid zfactor, else false. dFactor set
' regardless. If false return dFactor will be 1.
Public Function CalcZFactor(pGDS As IGeoDataset, dFactor As Double) As Boolean
  CalcZFactor = False
  dFactor = 1
  
  Dim pSR As ISpatialReference
  Set pSR = pGDS.SpatialReference
  Dim pLUZ As ILinearUnit
  Set pLUZ = pSR.ZCoordinateUnit
  
  If (Not pLUZ Is Nothing) Then ' z units defined, continue.
    If (TypeOf pSR Is IProjectedCoordinateSystem) Then
      Dim pPCS As IProjectedCoordinateSystem
      Set pPCS = pSR
      Dim pLUXY As ILinearUnit
      Set pLUXY = pPCS.CoordinateUnit
      dFactor = pLUZ.ConversionFactor / pLUXY.ConversionFactor
      CalcZFactor = True
    End If
  End If
End Function



'
' Add graphic to passed papp. App needs to be ArcMap or ArcScene. If ArcMap, the graphic
' is added to the BasicGraphicsLayer of the ActiveView FocusMap. If ArcScene, the graphic is
' added to the BasicGraphicsLayer of the scene.
'
Public Sub AddGraphic(pApp As IApplication, _
  pGeom As IGeometry, _
  Optional pSym As ISymbol, _
  Optional bAddToSelection As Boolean = False, _
  Optional bSelect As Boolean = True, Optional sElementName As String) ' TODO this needs to change
  
  On Error GoTo AddGraphic_ERR
  
  If (pGeom.IsEmpty) Then
    Exit Sub
  End If
  
  Dim pElement As IElement
  
  Select Case pGeom.GeometryType
  Case esriGeometryPoint
    Set pElement = New MarkerElement
    Dim pPointElement As IMarkerElement
    Set pPointElement = pElement
    If (Not pSym Is Nothing) Then
      pPointElement.Symbol = pSym
    Else
      pPointElement.Symbol = GetDefaultSymbol(pApp, esriGeometryPoint)
    End If
  Case esriGeometryPolyline
    Set pElement = New LineElement
    Dim pLineElement As ILineElement
    Set pLineElement = pElement
    If (Not pSym Is Nothing) Then
      pLineElement.Symbol = pSym
    Else
      pLineElement.Symbol = GetDefaultSymbol(pApp, esriGeometryPolyline)
    End If
  Case esriGeometryPolygon
    Set pElement = New PolygonElement
    Dim pFillElement As IFillShapeElement
    Set pFillElement = pElement
    If (Not pSym Is Nothing) Then
      pFillElement.Symbol = pSym
    Else
      pFillElement.Symbol = GetDefaultSymbol(pApp, esriGeometryPolygon)
    End If
  Case esriGeometryMultiPatch
    Set pElement = New MultiPatchElement
    Set pFillElement = pElement
    If (Not pSym Is Nothing) Then
      pFillElement.Symbol = pSym
    Else
      pFillElement.Symbol = GetDefaultSymbol(pApp, esriGeometryPolygon)
    End If
  End Select
    
  pElement.Geometry = pGeom
  If Len(sElementName) > 0 Then
    Dim pElemProps As IElementProperties
    Set pElemProps = pElement
    pElemProps.Name = sElementName
  End If
  
  Dim pGLayer As IGraphicsLayer
  If (TypeOf pApp Is IMxApplication) Then
    Dim pMxDoc As IMxDocument
    Set pMxDoc = pApp.Document
    
    Dim pActiveView As IActiveView
    Set pActiveView = pMxDoc.FocusMap
        
    Set pGLayer = pMxDoc.FocusMap.BasicGraphicsLayer
  
    Dim pGCon As IGraphicsContainer
    Set pGCon = pGLayer

    pGCon.AddElement pElement, 0

    Dim pGCS As IGraphicsContainerSelect
    Set pGCS = pGCon
    If (Not bAddToSelection) Then
      ' unselect all other elements before selecting this one
      pGCS.UnselectAllElements
    End If
    pGCS.SelectElement pElement
    
    ' redraw graphics for entire view extent, rather than just extent of this element, in case there were
    ' other graphics present that became unselected and lost their selection handles
    pActiveView.PartialRefresh esriViewGraphics, pElement, pActiveView.Extent
  Else
    Dim pSxDoc As ISxDocument
    Set pSxDoc = pApp.Document
    
    Set pGLayer = pSxDoc.Scene.BasicGraphicsLayer
    
    Dim pGCon3D As IGraphicsContainer3D
    Set pGCon3D = pGLayer
    
    pGCon3D.AddElement pElement
    
    Dim pGS As IGraphicsSelection
    Set pGS = pGCon3D
    If (bSelect) Then
      If (Not bAddToSelection) Then
        ' unselect all other elements before selecting this one
        pGS.UnselectAllElements
      End If
      pGS.SelectElement pElement
    End If
    
    pSxDoc.Scene.SceneGraph.RefreshViewers
  End If
  
  Exit Sub
AddGraphic_ERR:
  Debug.Print "AddGraphic_ERR: " & Err.Description
  Debug.Assert 0
End Sub
'
'  return the value of the field for the given feature
'
Public Function FieldValue(pFeat As IFeature, sField As String) As Variant
  On Error GoTo EH
  
  Dim pFields As IFields
  Dim pValueField As IField
  Dim nField As Integer
  Dim pRow As IRowBuffer
  
  Set pRow = pFeat
  Set pFields = pRow.Fields
  nField = pFields.FindField(sField)
  FieldValue = pRow.Value(nField)
      
  Exit Function
    
EH:

End Function
'
'  return the SR of the doc
'
Public Function GetDocSpatialRef() As ISpatialReference
  On Error GoTo EH

  Dim pDoc As IBasicDocument
  Dim pApp As IApplication
  
  Set pApp = New AppRef
  
  Set pDoc = pApp.Document
  
  If TypeOf pDoc Is SxDocument Then
    Dim pSxDoc As ISxDocument
    Set pSxDoc = pDoc
    Set GetDocSpatialRef = pSxDoc.Scene.SpatialReference
  ElseIf TypeOf pDoc Is MxDocument Then
    Dim pMxDoc As IMxDocument
    Set pMxDoc = pDoc
    Set GetDocSpatialRef = pMxDoc.FocusMap.SpatialReference
  End If
  
  Exit Function
    
EH:
End Function

'
'  return the IBasicDocument from the current papp
'
Public Function GetDoc() As IBasicDocument
  On Error GoTo EH
  Dim pApp As IApplication
  Set pApp = New AppRef
  
  Set GetDoc = pApp.Document
  
  Exit Function
    
EH:

End Function

'
'  return an IFeatureCursor for the selected features
'
Public Function GetSelectedFeatures(sLayer) As IFeatureCursor
  On Error GoTo EH
  
  Dim pLayer As ILayer
  Dim pFLayer As IFeatureLayer
  
  Set pLayer = GetLayer(sLayer)
  If pLayer Is Nothing Then Exit Function
  
  '  exit if not applicable:
  If Not TypeOf pLayer Is IFeatureLayer Then
    Exit Function
  End If
  
  Dim pFSelection As IFeatureSelection
  
  Set pFLayer = pLayer
  Set pFSelection = pFLayer
  
  pFSelection.SelectionSet.Search Nothing, False, GetSelectedFeatures
  
  Exit Function
    
EH:
    
End Function
'
'  return the number of vertices in the giben feature
'
Public Function NumberOfVerticesInFeature(pFeat As IFeature) As Long
  On Error GoTo EH
  
  Dim pFeatPoints As IPointCollection
  
  Set pFeatPoints = pFeat.Shape
  NumberOfVerticesInFeature = pFeatPoints.pointCount
  
  Exit Function
  
EH:

End Function

'
'  using the papp and screen XY passed in, return an IPoint interface of the point
'
Public Function XYToPoint(pApp As IApplication, X As Long, Y As Long, nMode As esriScenePickMode, Optional pOutLayer As ILayer, Optional pOutFeature As IFeature, Optional bRemoveSceneExaggeration As Boolean) As IPoint

On Error GoTo XYToPoint2_ERR

  If TypeOf pApp Is IMxApplication Then
    Dim pMxDoc As IMxDocument
    Set pMxDoc = pApp.Document
    Dim pMapActiveView As IActiveView
    Set pMapActiveView = pMxDoc.FocusMap
    Set XYToPoint = pMapActiveView.ScreenDisplay.DisplayTransformation.ToMapPoint(X, Y)

  ElseIf TypeOf pApp Is ISxApplication Then
    Dim pSxDoc As ISxDocument
    Set pSxDoc = pApp.Document
    Dim pSG As ISceneGraph
    Set pSG = pSxDoc.Scene.SceneGraph
    Dim pViewer As ISceneViewer
    Set pViewer = pSG.ActiveViewer
    Dim pOwner As stdole.IUnknown
    Dim pObject As stdole.IUnknown
    Dim pPntReturn As IPoint
    
    pSG.Locate pViewer, X, Y, nMode, True, pPntReturn, pOwner, pObject
    
    If bRemoveSceneExaggeration And Not pPntReturn Is Nothing Then
      pPntReturn.Z = pPntReturn.Z / pSG.Scene.exaggerationFactor
    End If
    
    Set XYToPoint = pPntReturn
    
    '  optionally return the feature found:
    If Not IsMissing(pOutFeature) And Not pOutFeature Is Nothing Then
      If Not pObject Is Nothing Then
        If TypeOf pObject Is IFeature Then
          Set pOutFeature = pObject
        End If
      End If
    End If

    ' optionally return the layer found:
    If Not IsMissing(pOutLayer) And Not pOutLayer Is Nothing Then
      If Not pOwner Is Nothing Then
        If TypeOf pOwner Is ILayer Then
          Set pOutLayer = pOwner
        End If
      End If
    End If
    
    ' release objects:
    Set pOwner = Nothing
    Set pObject = Nothing

  End If
  
  Exit Function
    
XYToPoint2_ERR:
  Debug.Print "XYToPoint2_ERR: " & Err.Description
  Resume Next
    
End Function

'
'  build a new extent from all selected layers and zoom into this
'
Public Sub ZoomToSelectedLayers()
    
  On Error GoTo ZoomToSelectedLayers_ERR
  
  Dim pLayerArray As IArray
  
  '  get the selected layers; exit if there are none:
  Set pLayerArray = MiscUtil.GetDocLayers(True)
  If pLayerArray Is Nothing Then Exit Sub
  If pLayerArray.count < 1 Then Exit Sub
  
  Dim pSxDoc As ISxDocument
  Dim pMxDoc As IMxDocument
  Dim i As Integer
  Dim pExtent As IEnvelope
  Dim pLayer As ILayer
  Dim pLayersExtent As IEnvelope

  '  instantiate extent variables:
  Set pExtent = New Envelope
  Set pLayersExtent = New Envelope
  
  Dim xmax As Double, xmin As Double, ymin As Double, ymax As Double
  Dim zmax As Double, zmin As Double
  Dim bInScene As Boolean
  Dim bInMap As Boolean
  Dim pScene As IScene
    
  '  check once to see if we are in ArcMap or ArcScene:
  Dim pApp As IApplication
  Set pApp = New AppRef
  
  If TypeOf pApp.Document Is ISxDocument Then
    bInScene = True
    bInMap = False
  ElseIf TypeOf pApp.Document Is IMxDocument Then
    bInScene = False
    bInMap = True
  Else
    Exit Sub
  End If
    
    
'  set the new extent boundary to the first one:
  Set pLayer = pLayerArray.Element(0)
  With pLayer.AreaOfInterest
    xmin = .xmin
    xmax = .xmax
    ymin = .ymin
    ymax = .ymax
      
    '  need to ask the scenegraph for the z information:
    If bInScene Then
      Set pSxDoc = pApp.Document
      Set pScene = pSxDoc.Scene
      Set pExtent = pScene.SceneGraph.OwnerExtent(pLayer, False)
      zmax = pExtent.zmax
      zmin = pExtent.zmin
    End If
      
  End With
        
  '  iterate through each other selected layer and set new boundary coordinates
  '  if necessary:
  For i = 1 To pLayerArray.count - 1
    Set pLayer = pLayerArray.Element(i)
    With pLayer.AreaOfInterest
      If .xmax > xmax Then xmax = .xmax
      If .xmin < xmin Then xmin = .xmin
      If .ymax > ymax Then ymax = .ymax
      If .ymin > ymin Then ymin = .ymin
  
      If bInScene Then
        Set pExtent = pScene.SceneGraph.OwnerExtent(pLayer, False)
        If pExtent.zmax > zmax Then zmax = pExtent.zmax
        If pExtent.zmin < zmin Then zmin = pExtent.zmin
      End If
      
    End With
  Next
       
  Dim pZAware As IZAware
  Set pZAware = pLayersExtent
  pZAware.ZAware = True
         
  '  set boundary of new extent from our variables:
  With pLayersExtent
    .xmin = xmin
    .xmax = xmax
    .ymin = ymin
    .ymax = ymax
    .zmin = zmin
    .zmax = zmax
  End With
    
  '  call the appropriate method fro ArcScene or ArcMap:
  If bInScene Then
    Set pSxDoc = pApp.Document
    
    '  set default minimum bounding box:
    pSxDoc.Scene.SceneGraph.ActiveViewer.Camera.SetDefaultsMBB pLayersExtent
      
  ElseIf bInMap Then
    Set pMxDoc = pApp.Document
    
    Dim pDisplayTransform As IDisplayTransformation
    
    '  set the visible bounds:
    Set pDisplayTransform = pMxDoc.ActiveView.ScreenDisplay.DisplayTransformation
    pDisplayTransform.VisibleBounds = pLayersExtent
      
  Else
    Exit Sub
  End If
    
  '  call a refresh:
  RefreshDocument
  
  Exit Sub
  
ZoomToSelectedLayers_ERR:
  Debug.Print "ZoomToSelectedLayers_ERR: " & Err.Description
  Debug.Assert 0
    
End Sub

'
' refresh the document viewers
'
Public Sub RefreshDocument()
    
  On Error GoTo RefreshDocument_ERR
  Dim pApp As IApplication
  Set pApp = New AppRef
  
  If TypeOf pApp.Document Is ISxDocument Then
    Dim pSxDoc As ISxDocument
    Set pSxDoc = pApp.Document
    pSxDoc.Scene.SceneGraph.RefreshViewers
  Else
    Dim pMxDoc As IMxDocument
    Set pMxDoc = pApp.Document
    pMxDoc.ActiveView.Refresh
  End If
    
  Exit Sub
    
RefreshDocument_ERR:
  Debug.Print "RefreshDocument_ERR: " & Err.Description
  Debug.Assert 0
  
End Sub

'
'  given type of passed in IApplication and geometry type, return the default symbol
'
Public Function GetDefaultSymbol(pApp As IApplication, eType As esriGeometryType) As ISymbol
  On Error GoTo EH
  
  Dim pDefaults As IBasicDocumentDefaultSymbols
  Dim pSym As ISymbol
  
  If (TypeOf pApp Is IMxApplication) Then
    Dim pMxDoc As IMxDocument
    Set pMxDoc = pApp.Document
    Set pDefaults = pMxDoc
  Else
    Dim pSxDoc As ISxDocument
    Set pSxDoc = pApp.Document
    Set pDefaults = pSxDoc
  End If
  
  Select Case eType
    Case esriGeometryPoint
      Set pSym = pDefaults.MarkerSymbol
    Case esriGeometryPolyline
      Set pSym = pDefaults.LineSymbol
    Case esriGeometryPolygon
      Set pSym = pDefaults.FillSymbol
    Case esriGeometryMultiPatch
      Set pSym = pDefaults.FillSymbol
  End Select
  
  Set GetDefaultSymbol = pSym
  Exit Function
EH:

End Function
'
'  return the string name of the given element
'
Public Function GetElemName(pElem As IElement) As String
  On Error GoTo EH
  Dim pProps As IElementProperties
  
  If pElem Is Nothing Then Exit Function
  Set pProps = pElem
  GetElemName = pProps.Name
  Exit Function
    
EH:
End Function



'
'  call a partial refresh on the active view for the given layer
'
Public Sub RefreshLayer(pLayer As ILayer)
  Dim pMap As IBasicMap
  Dim pApp As IApplication
  Dim pAV As IActiveView
  
  On Error GoTo EH
  Set pApp = pApp
  
  If (TypeOf pApp Is IMxApplication) Then
      Dim pMxDoc As IMxDocument
      Set pMxDoc = pApp.Document
      Set pMap = pMxDoc.ActiveView.FocusMap
      Set pAV = pMap
      
  ElseIf (TypeOf pApp Is ISxApplication) Then
      Dim pSxDoc As ISxDocument
      Set pSxDoc = pApp.Document
      Set pMap = pSxDoc.Scene
      Set pAV = pMap
  End If
  
  If Not pAV Is Nothing Then
      pAV.PartialRefresh 2, pLayer, Nothing
  End If
    
    
  Exit Sub
  
EH:

End Sub
Public Function MyNew(factory As IObjectFactory, progID As String) As IUnknown
  On Error GoTo MyNew_ERR
  
  If (factory Is Nothing) Then
      Set MyNew = Nothing
      Exit Function
  End If

  Dim objid As New esriSystem.UID
  objid.Value = progID

  Set MyNew = factory.Create(objid)
    
  Exit Function
    
MyNew_ERR:
  Debug.Print "MyNew_ERR: " & Err.Description
  Debug.Assert 0
    
End Function

Public Sub GroupSelectedGraphics(pApp As IApplication)
  If (TypeOf pApp Is IMxApplication) Then
    Dim pMxDoc As IMxDocument
    Set pMxDoc = pApp.Document
    
    Dim pActiveView As IActiveView
    Set pActiveView = pMxDoc.ActiveView
    
    Dim pGLayer As IGraphicsLayer
    Set pGLayer = pMxDoc.FocusMap.BasicGraphicsLayer
  
    Dim pGCon As IGraphicsContainer
    Set pGCon = pGLayer

    Dim pGCS As IGraphicsContainerSelect
    Set pGCS = pGCon
    
    Dim pEnumElements As IEnumElement
    Set pEnumElements = pGCS.SelectedElements
    
    Dim pElement As IElement
    Set pElement = pEnumElements.Next
    
    Dim pGroup As IGroupElement
    Set pGroup = New GroupElement
    
    Do While (Not pElement Is Nothing)
      pGCon.MoveElementToGroup pElement, pGroup
      Set pElement = pEnumElements.Next
    Loop

    pGCon.AddElement pGroup, 0
    
    pGCS.SelectElement pGroup
    
    ' redraw graphics for entire view extent, rather than just extent of this element, in case there were
    ' other graphics present that became unselected and lost their selection handles
    pActiveView.PartialRefresh esriViewGraphics, pGroup, pActiveView.Extent
    
  End If
End Sub

' Returns nothing if there's no selection on the layer.
Public Function GetFeatureLayerSelection( _
  pFL As IFeatureLayer, _
  Optional bGetCount As Boolean = False, _
  Optional lCount As Long = 0) As IFeatureCursor
  
  Dim pFSelection As IFeatureSelection
  Set pFSelection = pFL
  
  Dim pSelSet As ISelectionSet
  Set pSelSet = pFSelection.SelectionSet
  
  ' Event layers currently don't support selection and will
  ' return nothing for a SelectionSet. Check for this case.
  If (pSelSet Is Nothing) Then
    Set GetFeatureLayerSelection = Nothing
    Exit Function
  End If
  
  If (pSelSet.count > 0) Then
    Dim pCursor As IFeatureCursor
    If (bGetCount) Then
      lCount = pSelSet.count
    End If
    pSelSet.Search Nothing, False, pCursor
    Set GetFeatureLayerSelection = pCursor
  Else
    Set GetFeatureLayerSelection = Nothing
  End If
End Function

' Returns the last location of the GxBrowser
Public Function GetLastBrowseLocation() As String
  On Error GoTo EH
  Dim wscr
  Set wscr = CreateObject("WScript.Shell")
  Dim sLoc As String
  sLoc = wscr.RegRead("HKEY_CURRENT_USER\Software\ESRI\ArcCatalog\Settings\LastBrowseLocation")
  GetLastBrowseLocation = sLoc
  Exit Function
EH: ' if the gx browser has yet to be used the reg entry isn't there, this is probably what happened
  GetLastBrowseLocation = "Catalog"
End Function

' This function was created in case we change the way scratch rasters are specified in analysis
' dialogs. All dialogs that output rasters can call this (directly or via ResolveoutputRasterName)
' to determine if the output is temporary or permanent.
Public Function IsTempRasterName(sName As String) As Boolean
  IsTempRasterName = (InStr(UCase(sName), "<TEMPORARY") > 0) ' all variations to date have at least started
End Function                                                 ' with this string

' Determine if the output from interpolation tools can be written to edit sketch.
Public Function CanWrite3DToEditor(pEditor As IEditor, eGeomType As esriGeometryType) As Boolean
  CanWrite3DToEditor = False
  
  ' see if the editor exists
  If (Not pEditor Is Nothing) Then
    ' see if we are editing
    If (pEditor.EditState = esriStateEditing) Then
      ' see if target feature class is correct type
      Dim pEditLayers As IEditLayers
      Set pEditLayers = pEditor
      
      Dim pTargetLayer As IFeatureLayer
      Set pTargetLayer = pEditLayers.CurrentLayer
      
      If (pTargetLayer.FeatureClass.ShapeType = eGeomType) Then
        ' see if target layer has Z's
        Dim pFC As IFeatureClass
        Set pFC = pTargetLayer.FeatureClass
        
        Dim pFields As IFields
        Set pFields = pFC.Fields
        
        Dim shapeIndex As Long
        shapeIndex = pFields.FindField(pFC.ShapeFieldName)
      
        Dim pShapeField As IField
        Set pShapeField = pFields.Field(shapeIndex)
      
        Dim pGeomDef As IGeometryDef
        Set pGeomDef = pShapeField.GeometryDef
      
        If (pGeomDef.HasZ) Then
          CanWrite3DToEditor = True
        End If
      End If
    End If
  End If
End Function

' Write geometry to edit sketch
Public Sub WriteToEditSketch(pEditor As IEditor, pGeom As IGeometry)
  Dim pEditSketch As IEditSketch2
  Set pEditSketch = pEditor
    
  Set pEditSketch.Geometry = pGeom
  pEditSketch.FinishSketch
  pEditSketch.ModifySketch
End Sub



' Call before running a TIN function that supports cancel tracker
Public Sub SetTinCancelTracker(pTin As ITinAdvanced, pApp As IApplication, bUseProgressor As Boolean, bUseStepProgressor As Boolean)
  Dim pCancel As ITrackCancel
  Set pCancel = New CancelTracker
  
  pApp.StatusBar.Message(0) = "Press ESC to cancel..."
  
  pCancel.CancelOnClick = False
  pCancel.CancelOnKeyPress = True
  If (bUseProgressor) Then
    If (bUseStepProgressor) Then
      Dim pProg As IProgressor
      Set pProg = pApp.StatusBar.ProgressBar
      pProg.Show
      pCancel.Progressor = pProg
    Else
      Dim pPA As IAnimationProgressor
      Set pPA = pApp.StatusBar.ProgressAnimation
      pPA.Animation = esriAnimationDrawing
      pPA.Show
      'pCancel.Progressor = pPA
    End If
  End If
  
  'DoEvents
  
  Set pTin.trackCancel = pCancel
End Sub

' Call after running a TIN function that supports cancel tracker. This will clean
' things up and indicate whether the process was canceled.
Public Function TinProcessCanceled(pTin As ITinAdvanced, pApp As IApplication) As Boolean
  TinProcessCanceled = pTin.ProcessCancelled
  
  Dim pTracker As ITrackCancel
  Set pTracker = pTin.trackCancel
  
  If (TypeOf pTracker.Progressor Is IStepProgressor) Then   ' only hide progress bars, not the animation picture
    pTracker.Progressor.Hide
  Else
    Dim pAP As IAnimationProgressor
    Set pAP = pTracker.Progressor
    pAP.Stop
  End If
  
  pApp.StatusBar.Message(0) = ""
  'DoEvents
  
  Set pTin.trackCancel = Nothing
End Function

Public Function GetSurfaceGeoDatasetFromLayer(pLayer As ILayer) As IGeoDataset
  If (TypeOf pLayer Is ITinLayer) Then
    Dim pTinLayer As ITinLayer
    Set pTinLayer = pLayer
    Set GetSurfaceGeoDatasetFromLayer = pTinLayer.Dataset
  Else
    Dim pRasterLayer As IRasterLayer
    Set pRasterLayer = pLayer
    
    Dim pRasterBands As IRasterBandCollection
    Set pRasterBands = pRasterLayer.Raster
  
    Dim pRasterBand As IRasterBand
    Set pRasterBand = pRasterBands.Item(0)
    
    Set GetSurfaceGeoDatasetFromLayer = pRasterBand.RasterDataset
  End If
End Function

' Since the VB debugger runs in a different process space than the papp
' when debugging a DLL we need to create an extension object in the debugger's
' process space and enable it to run licensed functions.
Public Function Make3DExtInLocalProc() As IExtensionConfig
  On Error GoTo EH
  
  Dim pEMA As IExtensionManagerAdmin
  Set pEMA = New ExtensionManager
  
  Dim pUID As New UID
  pUID.Value = "esricore.DDDEnvironment"
  pEMA.AddExtension pUID, 0

  Dim pEM As IExtensionManager
  Set pEM = pEMA
  
  Set Make3DExtInLocalProc = pEM.FindExtension("3D Analyst")
  
  Exit Function
EH:
  Set Make3DExtInLocalProc = Nothing
End Function

Public Function MakeTinInAppProc(pOF As IObjectFactory) As ITin
  Dim pUID As New UID
  pUID.Value = "esricore.Tin"
  Set MakeTinInAppProc = pOF.Create(pUID)
End Function

Public Function MakeTinLayerInAppProc(pOF As IObjectFactory) As ITinLayer
  Dim pUID As New UID
  pUID.Value = "esricore.TinLayer"
  Set MakeTinLayerInAppProc = pOF.Create(pUID)
End Function






'
'  return the I3DProperties from the given ILayer
'
Public Function Get3DPropsFromLayer(pLayer As ILayer) As I3DProperties
  On Error GoTo EH
  
  Dim i As Integer
  Dim pLayerExts As ILayerExtensions
    
  Set pLayerExts = pLayer
  
  '  get 3d properties from extension;
  '  layer must have it if it is in scene:
      
  For i = 0 To pLayerExts.ExtensionCount - 1
    Dim p3DProps As I3DProperties
    If TypeOf pLayerExts.Extension(i) Is I3DProperties Then
      Set p3DProps = pLayerExts.Extension(i)
      If (Not p3DProps Is Nothing) Then
        Set Get3DPropsFromLayer = p3DProps
        Exit Function
      End If
    End If
  Next
    
  Exit Function
    
EH:

End Function

Public Sub GetSurfaceZMinZMax(pGDS As IGeoDataset, ByRef zmin As Double, ByRef zmax As Double)
  If (TypeOf pGDS Is ITin) Then
    Dim pTin As ITinAdvanced
    Set pTin = pGDS
    
    zmin = pTin.Extent.zmin
    zmax = pTin.Extent.zmax
  Else
    Dim pRasterDS As IRasterDataset
    Set pRasterDS = pGDS
    
    Dim pRaster As IRaster
    Set pRaster = pRasterDS.CreateDefaultRaster
    
    Dim pRasterBands As IRasterBandCollection
    Set pRasterBands = pRaster
    
    Dim pRasterBand As IRasterBand
    Set pRasterBand = pRasterBands.Item(0)
        
    Dim pStats As IRasterStatistics
    Set pStats = pRasterBand.Statistics
    
    zmin = pStats.Minimum
    zmax = pStats.Maximum
  End If
End Sub

Public Function ReadRegistry(sKey As String) As String
  On Error GoTo EH
  Dim wscr
  Set wscr = CreateObject("WScript.Shell")
  ReadRegistry = wscr.RegRead(sKey)
  Exit Function
EH:
  ReadRegistry = ""
End Function

Public Function NewLayersVisible(pApp As IApplication) As Boolean
  Dim sKey As String
  If (TypeOf pApp Is IMxApplication) Then
    sKey = "HKEY_CURRENT_USER\Software\ESRI\ArcMap\Settings\LayerVisibility"
  ElseIf (TypeOf pApp Is ISxApplication) Then
    sKey = "HKEY_CURRENT_USER\Software\ESRI\ArcScene\Settings\LayerVisibility"
  End If
  Dim sVal As String
  sVal = ReadRegistry(sKey)
  If (IsNumeric(sVal)) Then
    NewLayersVisible = (CLng(sVal) = 1)
  Else
    NewLayersVisible = False
  End If
  Exit Function
EH:
  NewLayersVisible = False
End Function

