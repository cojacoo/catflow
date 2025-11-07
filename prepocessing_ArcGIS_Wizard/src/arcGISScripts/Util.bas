Attribute VB_Name = "Util"
Public Function SetRasterWorkspace(sPath As String) As IWorkspace
' Given a pathname, returns the raster workspace object for that path
    On Error GoTo ErrorSetWorkspace
    Dim pWSF As IWorkspaceFactory
    Set pWSF = New RasterWorkspaceFactory
    If pWSF.IsWorkspace(sPath) Then
        Set SetRasterWorkspace = pWSF.OpenFromFile(sPath, 0)
        Set pWSF = Nothing
    End If
    Exit Function
ErrorSetWorkspace:
    Set SetRasterWorkspace = Nothing
End Function
Public Function SetFeatureShapeWorkspace(sPath As String) As IWorkspace
' Given a pathname, returns the shapefile workspace object for that path
    On Error GoTo ErrorSetWorkspace
    Dim pWSF As IWorkspaceFactory
    Set pWSF = New ShapefileWorkspaceFactory
    If pWSF.IsWorkspace(sPath) Then
        Set SetFeatureShapeWorkspace = pWSF.OpenFromFile(sPath, 0)
        Set pWSF = Nothing
    End If
    Exit Function

ErrorSetWorkspace:
    Set SetFeatureShapeWorkspace = Nothing
End Function
Public Function OpenRasterDataset(path As String, FileName As String) As IRasterDataset
    On Error GoTo erh
    Dim pWSFact As IWorkspaceFactory
    Dim pWS As IWorkspace
    Dim pRasterWS As IRasterWorkspace

    Set pWSFact = New RasterWorkspaceFactory
    If pWSFact.IsWorkspace(path) Then
        Set pWS = pWSFact.OpenFromFile(path, 0)
        Set pRasterWS = pWS
        Set OpenRasterDataset = pRasterWS.OpenRasterDataset(FileName)
    End If
    Set pWSFact = Nothing
    Set pWS = Nothing
    Set pRasterWS = Nothing
    Exit Function
erh:
MsgBox "Failed in open dataset. " & Err.Description
End Function

Public Sub SetSpatialAnalysisSettings(pEnv1 As IRasterAnalysisEnvironment, pEnv2 As IRasterAnalysisEnvironment)
    On Error GoTo erh
    If Not pEnv2 Is Nothing Then
        Set pEnv1.OutWorkspace = pEnv2.OutWorkspace
        If Not pEnv2.OutSpatialReference Is Nothing Then
            Set pEnv1.OutSpatialReference = pEnv2.OutSpatialReference
        End If
        pEnv1.DefaultOutputRasterPrefix = pEnv2.DefaultOutputRasterPrefix
        pEnv1.DefaultOutputVectorPrefix = pEnv2.DefaultOutputVectorPrefix
        If Not pEnv2.Mask Is Nothing Then
            Set pEnv1.Mask = pEnv2.Mask
        End If
        Dim nCellSize As Double
        pEnv2.GetCellSize 3, nCellSize
        If nCellSize <> 0 Then
            pEnv1.SetCellSize 3, nCellSize
        End If
        Dim pExtent As IEnvelope
        pEnv2.GetExtent 3, pExtent
        If Not pExtent Is Nothing Then
            pEnv1.SetExtent 3, pExtent
        End If
        pEnv1.VerifyType = pEnv2.VerifyType
    End If
    Exit Sub
erh:
    MsgBox "Failed in SetSpatialAnalysisSettings: " & Err.Description
End Sub

Function GetUniqueName(Name As String, folderPath As String) As String
On Error GoTo EH
' Find file, if exists, increment number
  Dim FSO 'As FileSystemObject
  Dim pFolder 'As Folder
  Dim pFile 'As File
  Dim sCurrNum As String

  Set FSO = CreateObject("Scripting.FileSystemObject") ' New FileSystemObject
  Set pFolder = FSO.GetFolder(folderPath)
  sCurrNum = "0"
  For Each pFile In pFolder.Files
    If InStr(pFile.Name, Name) > 0 Then
      Dim s() As String
      s = Split(pFile.Name, ".")
      If IsNumeric(Right(s(0), 2)) Then
        If (CInt(Right(s(0), 2)) > CInt(sCurrNum)) Then
          sCurrNum = Right(s(0), 2)
        Else
          Exit For
        End If
      Else
        If IsNumeric(Right(s(0), 1)) Then
          If (CInt(Right(s(0), 1)) > CInt(sCurrNum)) Then
            sCurrNum = Right(s(0), 1)
          End If
        End If
      End If
    End If
  Next pFile
  If sCurrNum = "0" Then
    GetUniqueName = Name + "1"
  Else
    GetUniqueName = Name & CStr(CInt(sCurrNum) + 1)
  End If

  Set pFile = Nothing
  Set pFolder = Nothing
  Set FSO = Nothing
  Exit Function
EH:
  MsgBox Err.Number & vbLf & Err.Description, , "Error in GetUniqueName "
End Function
Function GetUniqueLayerName(Name As String, pApp As IApplication) As String
On Error GoTo erh
' Find layer, if exists, increment number
    Dim sCurrNum As Integer
    Dim LyrCount As Integer
    Dim pLayer As ILayer
    Dim pMap As IBasicMap
    Dim pMxDoc As IMxDocument
    Set pMxDoc = pApp.Document
    Set pMap = pMxDoc.FocusMap
    LyrCount = pMap.LayerCount
    sCurrNum = 0
    Dim i As Integer
    If LyrCount <> 0 Then
        For i = 0 To LyrCount - 1
            Dim s As String
            Set pLayer = pMap.Layer(i)
            s = pLayer.Name
            If InStr(s, Name) > 0 Then
                    If Len(Name) <> Len(s) Then
                        Dim s1 As String
                        s1 = Mid(s, Len(Name) + 1, Len(s) - Len(Name))
                        If IsNumeric(s1) Then
                            If (CInt(s1) > sCurrNum) Then
                                sCurrNum = CInt(s1)
                            End If
                        End If
                    End If
            End If
        Next i
    End If
    If sCurrNum = 0 Then
        GetUniqueLayerName = Name & "1"
    Else
        GetUniqueLayerName = Name & CStr(sCurrNum + 1)
    End If
    Set pMap = Nothing
    Set pLayer = Nothing
    Set mxdoc = Nothing
    Exit Function
erh:
    MsgBox "Failed in Creating duplicated layer name:" & Err.Description
End Function

Public Function CreateLineElement(pLine As IGeometry, lLineStyle As Long, _
        pColor As IRgbColor, lLineWidth As Double) As ILineElement
    On Error GoTo erh
    ' CREATE SYMBOL
    Dim pSym As ISimpleLineSymbol
    Set pSym = New SimpleLineSymbol
    With pSym
        .Width = lLineWidth
        .Style = lLineStyle
        .Color = pColor
    End With

    ' CREATE ELEMENT
    Dim pElem As ILineElement
    Set pElem = New LineElement
    With pElem
        .Symbol = pSym
    End With

    ' SET LOCATION OF ELEMENT
    Dim pElement As IElement
    Set pElement = pElem
    pElement.Geometry = pLine

    Set CreateLineElement = pElement
    Set pElem = Nothing
    Set pElement = Nothing
    Set pSym = Nothing
    Exit Function
erh:
    MsgBox "Failed in calling CreateLineElement:" & Err.Description
End Function
Public Function CreateMarkerElement(pPnt As IPoint, pClr As IRgbColor, lSize As Long, esriSMS As esriSimpleMarkerStyle) As IMarkerElement
   
  ' CREATE SYMBOL
  Dim pSym As ISimpleMarkerSymbol
  Set pSym = New SimpleMarkerSymbol
  With pSym
      .Style = esriSMS
      .Color = pClr
      .Size = lSize
  End With
       
  ' CREATE ELEMENT
  Dim pElem As IMarkerElement
  Set pElem = New MarkerElement
  With pElem
      .Symbol = pSym
  End With
      
  ' SET LOCATION OF ELEMENT
  Dim pElement As IElement
  Set pElement = pElem
  pElement.Geometry = pPnt
        
  Set CreateMarkerElement = pElement
  
End Function
Public Function CountOfRasterLayer(pMap As IMap) As Integer
    ' calculate the number of raster layers in the Map
    Dim pLy As ILayer
    Dim TotalCount, count, i   As Integer
    On Error GoTo erh
    TotalCount = pMap.LayerCount
    If TotalCount > 0 Then
        count = 0
        For i = 0 To TotalCount - 1
            Set pLy = pMap.Layer(i)
            If TypeOf pLy Is IRasterLayer Then count = count + 1
        Next i
        CountOfRasterLayer = count
    Else
        CountOfRasterLayer = 0
    End If
    Set pLy = Nothing
    Exit Function
erh:
    MsgBox "Failed in layer count." & Err.Description
    CountOfRasterLayer = 0
End Function

Public Sub AddRasterLayerToComboBox(cboBox As ComboBox, pMap As IMap)
    On Error GoTo erh
    cboBox.Clear
    Dim iLyrIndex As Long
    Dim pLyr As ILayer
    ' Add raster layers into  Combobox
    Dim iLayerCount As Integer
    iLayerCount = pMap.LayerCount
    If iLayerCount > 0 Then
        cboBox.Enabled = True
        For iLyrIndex = 0 To iLayerCount - 1
            Set pLyr = pMap.Layer(iLyrIndex)
            If (TypeOf pLyr Is IRasterLayer) Then
                cboBox.AddItem pLyr.Name
                cboBox.ItemData(cboBox.ListCount - 1) = iLyrIndex
            End If
        Next iLyrIndex
        If (cboBox.ListCount > 0) Then
            cboBox.ListIndex = 0
            cboBox.Text = pMap.Layer(cboBox.ItemData(0)).Name
        End If
    End If
    Exit Sub
erh:
    MsgBox "Add Layer to ComboBox:" & Err.Description
End Sub

Public Sub AddRasterLayerToComboBoxEdit(cboBox As ComboBox, pMap As IMap, sText As String)
    On Error GoTo erh
    cboBox.Clear
    Dim iLyrIndex As Long
    Dim pLyr As ILayer
    ' Add raster layers into  Combobox
    Dim iLayerCount As Integer
    iLayerCount = pMap.LayerCount
    If iLayerCount > 0 Then
        cboBox.Enabled = True
        For iLyrIndex = 0 To iLayerCount - 1
            Set pLyr = pMap.Layer(iLyrIndex)
            If (TypeOf pLyr Is IRasterLayer) Then
                cboBox.AddItem pLyr.Name
                cboBox.ItemData(cboBox.ListCount - 1) = iLyrIndex
            End If
        Next iLyrIndex
        If (cboBox.ListCount > 0) Then
            cboBox.ListIndex = 0
            If sText = "" Then
                cboBox.Text = pMap.Layer(cboBox.ItemData(0)).Name
            Else
                cboBox.Text = sText
            End If
        End If
        
    Else
        cboBox.Text = sText
'        cboBox.Enabled = False
'        cboBox.BackColor = vbMenuBar
    End If
    Exit Sub
erh:
    MsgBox "Add Layer to ComboBox:" & Err.Description
End Sub
Public Sub AddDirectionRasterLayerToComboBox(cboBox As ComboBox, pMap As IMap)
    On Error GoTo erh
    cboBox.Clear
    Dim iLyrIndex As Long
    Dim pLyr As ILayer
    ' Add raster layers into  Combobox
    Dim iLayerCount As Integer
    iLayerCount = pMap.LayerCount
    If iLayerCount > 0 Then
        cboBox.Enabled = True
        For iLyrIndex = 0 To iLayerCount - 1
            Set pLyr = pMap.Layer(iLyrIndex)
            If (TypeOf pLyr Is IRasterLayer) Then
                Dim pRaster As IRaster
                Dim pRLayer As IRasterLayer
                Set pRLayer = pLyr
                Set pRaster = pRLayer.Raster
                Dim pBandC As IRasterBandCollection
                Dim pBand As IRasterBand
                Set pBandC = pRaster
                Set pBand = pBandC.Item(0)
                Dim pTable As ITable
                Dim pRProp As IRasterProps
                Set pRProp = pRaster
                If pRProp.PixelType <> PT_FLOAT Then
                    On Error GoTo No_Table
                    If Not pBand.AttributeTable Is Nothing Then
                        Set pTable = pBand.AttributeTable
                        If pTable.RowCount(Nothing) <= 255 Then
                            cboBox.AddItem pLyr.Name
                            cboBox.ItemData(cboBox.ListCount - 1) = iLyrIndex
                        End If
                    End If
                End If
No_Table:
                Set pRaster = Nothing
                Set pRLayer = Nothing
                Set pBandC = Nothing
                Set pBand = Nothing
                Set pTable = Nothing
            End If
        Next iLyrIndex
        If (cboBox.ListCount > 0) Then
            cboBox.ListIndex = 0
            cboBox.Text = pMap.Layer(cboBox.ItemData(0)).Name
        End If
    End If
    Exit Sub
erh:
    MsgBox "Add Layer to ComboBox:" & Err.Description
End Sub

Public Sub AddRasterLayer(pApp As IApplication, pRaster As IRaster, Optional sName As String)
  On Error GoTo EH

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
  Dim pMap As IBasicMap
  Dim pMxDoc As IMxDocument
  Dim pActView As IActiveView
  Set pMxDoc = pApp.Document
  Set pMap = pMxDoc.FocusMap
  Set pActView = pMxDoc.ActiveView
  pMap.AddLayer pRasterLayer
  pActView.Refresh
  pMxDoc.UpdateContents
  Exit Sub
  Set pMxDoc = Nothing
  Set pActView = Nothing
  Set pMap = Nothing
  Set pRasterLayer = Nothing
EH:
  MsgBox "Util.AddRasterLayer: " & Err.Description
End Sub
Public Sub AddRasterLayer1(pApp As IApplication, pRasterDS As IRasterDataset, Optional sName As String)
  On Error GoTo EH

  Dim pRasterLayer As IRasterLayer
  Set pRasterLayer = New rasterLayer
  pRasterLayer.CreateFromDataset pRasterDS
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
  Dim pMap As IBasicMap
  Dim pMxDoc As IMxDocument
  Dim pActView As IActiveView
  Set pMxDoc = pApp.Document
  Set pMap = pMxDoc.FocusMap
  Set pActView = pMxDoc.ActiveView
  pMap.AddLayer pRasterLayer
  pActView.Refresh
  pMxDoc.UpdateContents
  Exit Sub
  Set pMxDoc = Nothing
  Set pActView = Nothing
  Set pMap = Nothing
  Set pRasterLayer = Nothing
EH:
  MsgBox "Util.AddRasterLayer: " & Err.Description
End Sub

Public Sub AddFeatureLayer(pApp As IApplication, pFClass As IFeatureClass, Optional sName As String)

  On Error GoTo EH

  Dim pFLayer As IFeatureLayer
  Set pFLayer = New FeatureLayer
  Set pFLayer.FeatureClass = pFClass
  If (sName = "") Then
    Dim pFDataset As IFeatureDataset
    Set pFDataset = pFClass.FeatureDataset
    Dim pDS As IDataset
    Set pDS = pFDataset
    pFLayer.Name = pDS.BrowseName
  Else
    pFLayer.Name = sName
  End If
  Dim pMap As IBasicMap
  Dim pMxDoc As IMxDocument
  Dim pActView As IActiveView
  Set pMxDoc = pApp.Document
  Set pMap = pMxDoc.FocusMap
  Set pActView = pMxDoc.ActiveView
  pMap.AddLayer pFLayer
  pActView.Refresh
  pMxDoc.UpdateContents
  Exit Sub
  Set pMxDoc = Nothing
  Set pActView = Nothing
  Set pMap = Nothing
  Set pRasterLayer = Nothing
EH:
  MsgBox "Util.AddRasterLayer: " & Err.Description
End Sub

Public Sub AddLayer(pApp As IApplication, pLayer As ILayer)

  On Error GoTo EH
  
  Dim pMap As IBasicMap
  
  If (TypeOf pApp Is IMxApplication) Then
    Dim pMxDoc As IMxDocument
    Set pMxDoc = pApp.Document
    Set pMap = pMxDoc.ActiveView.FocusMap
  End If
  pMap.AddLayer pLayer
  Exit Sub
EH:
  MsgBox "Util.AddLayer: " & Err.Description
End Sub

Public Function NumOfRow(pRaster As IRaster) As Integer
    Dim pBandC As IRasterBandCollection
    Dim pBand As IRasterBand
    Set pBandC = pRaster
    Set pBand = pBandC.Item(0)
    Dim pTab As ITable
    Set pTab = pBand.AttributeTable
    NumOfRow = pTab.RowCount(Nothing)
    Set pBandC = Nothing
    Set pBand = Nothing
    Set pTab = Nothing
End Function


Public Function GetUniqueFeatureClassName(pWS As IFeatureWorkspace, Optional sPrefix) As String
  On Error GoTo EH
  Dim sPreName As String
  If (sPrefix <> "") Then
    sPreName = sPrefix
  Else
    sPreName = "ai"
  End If
  Dim i As Long
  i = 1
  
  ' if shapefile workspace add .shp extension
  Dim pDataset As IDataset
  Set pDataset = pWS
  If (InStr(UCase(pDataset.Category), "SHAPEFILE") > 0) Then
    Dim sExt As String
    sExt = ".shp"
  Else
    sExt = ""
  End If

  Dim done As Boolean
  Do While Not done
    Dim pFC As IFeatureClass
    Dim sName As String
    sName = sPreName & Right(Str(i), Len(Str(i) - 1)) & sExt
    Set pFC = pWS.OpenFeatureClass(sName) ' this can raise an error if dataset doesn't exist so error handler should use it
    If (pFC Is Nothing) Then
      done = True
    Else
      i = i + 1
    End If
  Loop
  GetUniqueFeatureClassName = sName
  Exit Function
EH:
  GetUniqueFeatureClassName = sName
End Function

' sSuffix should include '.'
Public Function GetUniqueFileName(sDir As String, Optional sPrefix As String = "ai", Optional sSuffix As String = "") As String
  Dim fs As FileSystemObject
  Set fs = New FileSystemObject
  Dim i As Long
  Dim done As Boolean
  Dim Name As String
  done = False
  i = 1
  ' work whether or not input dir has "\" on end - like raster analysis workspace will
  Dim sDirNew As String
  sDirNew = sDir
  If (Right(sDir, 1) = "\") Then
    sDirNew = Left(sDir, Len(sDir) - 1)
  End If
  Do While Not done
    Name = sPrefix & Right(Str(i), Len(Str(i)) - 1) & sSuffix ' make sure to remove space the 'Str' function places before number
    If ((Not fs.FolderExists(sDirNew + "\" + Name)) And _
        (Not fs.fileExists(sDirNew + "\" + Name))) Then
      GetUniqueFileName = Name
      Exit Function
    End If
    i = i + 1
  Loop
End Function
Public Function SplitWorkspaceName(sWholeName As String) As String
    On Error GoTo erh
    Dim Pos As Integer
    Pos = InStrRev(sWholeName, "\")
    If Pos > 0 Then
        SplitWorkspaceName = Mid(sWholeName, 1, Pos - 1)
    Else
        Exit Function
    End If
erh:
    MsgBox "Workspace Split:" & Err.Description
End Function
Public Function SplitFileName(sWholeName As String) As String
    On Error GoTo erh
    Dim Pos As Integer
    Dim st, sName As String
    Pos = InStrRev(sWholeName, "\")
    If Pos > 0 Then
        st = Mid(sWholeName, 1, Pos - 1)
        If Pos = Len(sWholeName) Then
            Exit Function
        End If
        sName = Mid(sWholeName, Pos + 1, Len(sWholeName) - Len(st))
        Pos = InStr(sName, ".")
        If Pos > 0 Then
            SplitFileName = Mid(sName, 1, Pos - 1) & ".shp"
        Else
            SplitFileName = sName & ".shp"
        End If
    End If
    Exit Function
erh:
    MsgBox "Workspace Split:" & Err.Description
End Function
Public Function CanCreateFile(sInString As String, sType As String, sOutDir As String, sOutName As String) As Boolean
  Dim fs, f, s
  Set fs = CreateObject("Scripting.FileSystemObject")
  sOutDir = fs.GetParentFolderName(sInString)
  sOutName = fs.GetFileName(sInString)
  
  If sInString = "" Then
    CanCreateFile = False
    Exit Function
  End If
  
  If sType = "shapefile" Then
    If fs.GetExtensionName(sInString) = "" Then
        sOutName = sOutName + ".shp"
    End If
  ElseIf sType = "grid" Then
    sOutName = sOutName
  Else
    MsgBox "CanCreateFile dies not support this format"
    Exit Function
  End If
  If (sOutDir = "") Then
    sOutDir = "c:\temp"
  End If
 
  If ((fs.FolderExists(sOutDir & "\" & sOutName)) Or _
      (fs.fileExists(sOutDir & "\" & sOutName))) Then
      MsgBox "Specified output already exists, please choose a different one"
      CanCreateFile = False
      Exit Function
  End If
 
  If (fs.FolderExists(sOutDir)) Then
    CanCreateFile = True
  Else
    MsgBox "Specified output directory not found."
    CanCreateFile = False
  End If
End Function

Public Sub MakePerminentGrid(pRaster As IRaster, sOutPath As String, sOutName As String)
    On Error GoTo erh
    Dim pWS As IWorkspace
    Set pWS = SetRasterWorkspace(sOutPath)
    Dim pBandC As IRasterBandCollection
    Dim pBand As IRasterBand
    Set pBandC = pRaster
    Set pBand = pBandC.Item(0)
    Dim pRDS As IRasterDataset
    Set pRDS = pBand.RasterDataset
    Dim pDS As IDataset
    If Not pRDS.CanCopy Then
        Exit Sub
    End If
    pRDS.Copy sOutName, pWS
    Set pRDS = Nothing
    Set pDS = Nothing
    Set pWS = Nothing
    Exit Sub
erh:
    MsgBox "MakePerminebtGrid:" & Err.Description
End Sub
Public Function MakePermanentRaster(pRaster As IRaster, sOutputPath As String, sOutputName As String) As Boolean
On Error GoTo erh

    If sOutputPath = "" Or sOutputName = "" Then
        MakePermanentRaster = False
        Exit Function
    End If
    Dim iPos As Integer
    iPos = InStr(sOutputName, ".")
    Dim sExt As String
    If iPos > 0 Then
        sExt = Mid(sOutputName, iPos + 1)
    Else
        sExt = ""
    End If
    Dim sFormat As String
    Select Case sExt
        Case ""
            sFormat = "GRID"
        Case "tif"
            sFormat = "TIFF"
        Case "img"
            sFormat = "IMAGINE Image"
        Case Else
            MsgBox "Make Permanent Raster: Unsupported file extension"
            MakePermanentRaster = False
            Exit Function
    End Select

    Dim pWS As IWorkspace
    Set pWS = Util.SetRasterWorkspace(sOutputPath)
    Dim pBandC As IRasterBandCollection
    Set pBandC = pRaster
    pBandC.SaveAs sOutputName, pWS, sFormat
    MakePermanentRaster = True
    Exit Function
erh:
    MsgBox "Make Permanent Raster:" & Err.Description
    MakePermanentRaster = False
End Function


Function CheckSpatialAnalystLicense()
On Error GoTo erh
    Dim pLicManager As IExtensionManager
    Dim pLicAdmin As IExtensionManagerAdmin
    Set pLicManager = New ExtensionManager
    Set pLicAdmin = pLicManager
    '
    Dim saUID As Variant
    saUID = "esriCore.SAExtension.1"
    Dim pUID As New UID
    pUID.Value = saUID
    Dim v As Variant
    Call pLicAdmin.AddExtension(pUID, v)
    '
    Dim pExtension As IExtension
    Dim pExtensionConfig As IExtensionConfig
    Set pExtension = pLicManager.FindExtension(pUID)
    Set pExtensionConfig = pExtension
    pExtensionConfig.state = esriESEnabled
    Exit Function
erh:
    MsgBox "Failed in License Checking" & Err.Description
End Function

