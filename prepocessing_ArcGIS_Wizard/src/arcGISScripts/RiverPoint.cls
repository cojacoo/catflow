VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "RiverPoint"
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

'To store basic information
Private thePoint As IPoint
'neighbors of the RiverPoint
Private downstream As RiverPoint
Private upstream() As RiverPoint
Private numUpstream As Integer
Private maxUpstream As Integer

' Required to estimate ChannelDepth
Private depth As Double
Private depthIsOK As Boolean
Private slopeUpRiverPoint As RiverPoint
Private slopeDownRiverPoint As RiverPoint
'Catchment Area
Private cArea As Double
'Connected Slope
Private theSlope As slope
'Outlet does not have a downstream RiverPoint
Private isOutlet As Boolean
'This Point belongs to
Private theSegment As RiverSegment
Private theNet As RiverNet
'When is depth stable?
Private iterLimit As Double
Private Const defaultIterLimit As Double = 0.00001
'To avoid infinite loops
Private Const IterationUnstableCount As Integer = 500

Public Property Set slope(s As slope)
  If s Is Nothing Then
    Err.Raise vbObjectError, "RiverPoint.setSlope", "Slope must not be nothing"
  End If
  Set theSlope = s
End Property

Public Property Get slope() As slope
  Set slope = theSlope
End Property

Public Property Get slopeID() As Integer
  If theSlope Is Nothing Then
    slopeID = 0
  Else
    slopeID = theSlope.ID
  End If
End Property

Public Property Get SlopeArea() As Double
  
    SlopeArea = 0
    If Not theSlope Is Nothing Then
        SlopeArea = theSlope.Area
    End If
End Property

Public Property Get DepthIterationLimit() As Double
  If iterLimit = 0 Then
     iterLimit = defaultIterLimit
  End If
  DepthIterationLimit = iterLimit
End Property
Public Property Let DepthIterationLimit(n As Double)
  If n <= 0 Then
    Err.Raise vbObjectError, "RiverPoint.setDepthItereationLimit", "IterationLimit must be > 0"
  End If
  iterLimit = n
End Property

Public Property Set DownstreamRiverPoint(P As RiverPoint)
  If P Is Nothing Then
    Err.Raise vbObjectError, "RiverPoint.setDownstreamRiverPoint", "RiverPoint must not be nothing"
  End If
  Set downstream = P
End Property
Public Property Get DownstreamRiverPoint() As RiverPoint
  Set DownstreamRiverPoint = downstream
End Property
Public Sub AddUpstreamRiverPoint(RiverPoint As RiverPoint)
  If RiverPoint Is Nothing Then
    Err.Raise vbObjectError, "RiverPoint.addUpstreamRiverPoint", "RiverPoint must not be nothing"
  End If
  If numUpstream = maxUpstream Then
    Err.Raise vbObjectError, "RiverPoint.addUpstreamRiverPoint", "Maximum number of upstream riverpoints exceeded"
  End If
  Set upstream(numUpstream) = RiverPoint
  numUpstream = numUpstream + 1
End Sub
Public Function deleteUpstreamRiverPoint(RiverPoint As RiverPoint) As Boolean
  Dim counter As Integer
  For counter = 0 To numUpstream - 1
    If deleteUpstreamRiverPoint Then
      'move all upstreams above the hit
      upstream(counter - 1) = upstream(counter)
    Else
      If upstream(counter) = RiverPoint Then
        deleteUpstreamRiverPoint = True
        numUpstream = numUpstream - 1 'For loop is not affected
      End If
    End If
  Next
End Function
Public Property Get upStreamCount() As Integer
  upStreamCount = numUpstream
End Property
Public Property Get UpstreamRiverPoint(position As Integer) As RiverPoint
  If position < 0 Or position >= numUpstream Then
    Err.Raise vbObjectError, "RiverPoint.getUpstreamRiverPoint", "Position is outside the valid range"
  End If
  Set UpstreamRiverPoint = upstream(position)
End Property
Public Property Set RiverSegment(r As RiverSegment)
  If r Is Nothing Then
    Err.Raise vbObjectError, "RiverPoint.setRiverSegment", "RiverSegment must not be nothing"
  End If
  Set theSegment = r
End Property
Public Property Get RiverSegment() As RiverSegment
  Set RiverSegment = theSegment
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

Public Property Let IsTheOutlet(b As Boolean)
  isOutlet = b
End Property

Public Property Get IsTheOutlet() As Boolean
  IsTheOutlet = isOutlet
End Property

Public Property Get IPoint() As IPoint
   Set IPoint = thePoint
End Property

Public Property Get ChannelBottomElevation() As Double
   ChannelBottomElevation = thePoint.Z - ChannelDepth
End Property

Public Property Get currentChannelBottomElevation() As Double
  'Avoids infinite loops since estimated depth is used
   currentChannelBottomElevation = thePoint.Z - depth
End Property


Public Property Get ChannelDepth() As Double

  '1) Ein RiverPoint kriegt eine Anfrage, die die Tiefe benötigt und stellt
  '   fest, dass diese noch nicht berechnet wurde.
  
  If Not depthIsOK Then
     estimateDepth
     
  End If
  ChannelDepth = depth
End Property

Public Property Get ChannelBottomSlope() As Double
  ChannelBottomSlope = calcChannelBottomSlope(False)
End Property
Private Function calcChannelBottomSlope(iterating As Boolean) As Double

  Dim bottomSlope As Double
  
  'Use neighboring points for estimation?
  
  If slopeUpRiverPoint Is Nothing Then
    If isOutlet Then
        If numUpstream = 1 Then
          Set slopeUpRiverPoint = upstream(0)
        ElseIf numUpstream = 0 Then
          'Springs
          Set slopeUpRiverPoint = Me
        Else
          'find main channel
          Dim numberOfUpstreamWithHighestOrder As Integer
          Dim highestOrder As Integer
          Dim counter As Integer
          For counter = 0 To numUpstream - 1
            If upstream(counter).order > highestOrder Then
              highestOrder = upstream(counter).order
              numberOfUpstreamWithHighestOrder = 1
              Set slopeUpRiverPoint = upstream(counter)
            ElseIf upstream(counter).order = highestOrder Then
              numberOfUpstreamWithHighestOrder = numberOfUpstreamWithHighestOrder + 1
            End If
          Next
          'if there is no main channel, use myself for slope calculation
          If numberOfUpstreamWithHighestOrder <> 1 Then
            Set slopeUpRiverPoint = Me
          End If
        End If
    Else
      'Iteration does not converge if upstream riverpoint is used for calculating the slope
      Set slopeUpRiverPoint = Me
    End If
  End If
  
  If slopeDownRiverPoint Is Nothing Then
    If downstream Is Nothing Then
      If Not isOutlet Then
        Err.Raise vbObjectError, "RiverPoint.estimateDepth", "Please set downstream RiverPoint"
      End If
      Set slopeDownRiverPoint = Me
      If slopeDownRiverPoint Is slopeUpRiverPoint Then
        Err.Raise vbObjectError, "RiverPoint.calcChannelBottomSlope", _
                  "Error while calculating bottom slope. River network " & _
                  "outlet has multiple upstrem river points of the same " & _
                  "strahler order. Therefore " & _
                  "slope can not be calculated. Please make outlet river " & _
                  "segment longer."
      End If
    Else
      Set slopeDownRiverPoint = downstream
    End If
  End If
  
  If iterating Then
    'Calculate temporary Slope for iterationStep function
    bottomSlope = (slopeUpRiverPoint.currentChannelBottomElevation - slopeDownRiverPoint.currentChannelBottomElevation) _
                  / distance(slopeUpRiverPoint.IPoint, slopeDownRiverPoint.IPoint)
  Else
    'Calculate Slope
    bottomSlope = (slopeUpRiverPoint.ChannelBottomElevation - slopeDownRiverPoint.ChannelBottomElevation) _
                  / distance(slopeUpRiverPoint.IPoint, slopeDownRiverPoint.IPoint)
  End If
  
  'prevent negative values
  If bottomSlope <= 0 Then
      bottomSlope = 0.01
  End If
  
  calcChannelBottomSlope = bottomSlope
End Function
Private Function depthEstimationFormula(CriticalRainFall As Double, _
                                        CatchmentArea As Double, _
                                        ChannelWidthToDepthRatio As Double, _
                                        ChannelBankSlope As Double, _
                                        ChannelSlope As Double, _
                                        StricklerCoeff As Double _
                                        ) As Double
'Thomas Maurer, Physikalisch begründete zeitkontinuierliche Modellierung des Wassertransports in kleinen ländlichen
'               Einzugsgebieten, Institut für Hydrologie und Wasserwirtschaft, Heft 61, Karlsruhe 1997, p65
   depthEstimationFormula = (CriticalRainFall / 1000 / 3600 _
                               * CatchmentArea _
                               * (ChannelWidthToDepthRatio + 2 * Sqr(ChannelBankSlope ^ 2 + 1) _
                                 ) ^ (2 / 3) _
                               / (ChannelWidthToDepthRatio + ChannelBankSlope _
                                 ) ^ (5 / 3) _
                               / StricklerCoeff _
                               / Sqr(ChannelSlope) _
                            ) ^ (3 / 8)
End Function
Public Property Get CatchmentArea() As Double
  If Not cArea = -1 Then
     CatchmentArea = cArea
     Exit Property
  End If
  
  cArea = SlopeArea
  
  Dim counter As Integer
  For counter = 0 To numUpstream - 1
    cArea = cArea + upstream(counter).CatchmentArea
  Next
  CatchmentArea = cArea
End Property
Public Property Get ChannelBottomWidth() As Double
   If theSegment Is Nothing Then
      Err.Raise vbObjectError, "RiverPoint.estimateDepth", "Please set the RiverSegment for estimation of river depth"
  End If
   ChannelBottomWidth = ChannelDepth * theSegment.WidthToDepthRatio
End Property
Private Sub estimateDepth()

'Die Iteration für die Flusstiefe funktioniert so:
'
'1) Ein RiverPoint kriegt eine Anfrage, die die Tiefe benötigt und stellt
'   fest, dass diese noch nicht berechnet wurde.
'2) Dieser RiverPoint geht in eine Iterationsschleife, die die IterationStep -
'   Methode so lange aufruft, bis diese false (was anzeigt, dass sich keine
'   Änderung mehr ergeben hat) zurück gibt.
'3) IterationStep berechnet erst eine neue Tiefe. Dazu werden die momentan
'   geschätzten Tiefen (currentChannelBottomElevation) für angrenzende
'   RiverPoints benötigt, um die Steigung zu berechnen.
'4) IterationStep ruft nun die IterationStep für alle angrenzenden RiverPoints
'   auf, mit Ausnahme des aufrufendnen RiverPoints
'5) IterationStep setzt die momentan geschätzte Tiefe auf die jetztige Tiefe
'6) IterationStep gibt true zurück, falls die IterationStep Methode eines
'   der angrenzenden RiverPoints true zurück gab, oder wenn die neue Tiefe
'   mehr als ein Grenzwert von der alten Tiefe abweicht.
 


  'Need information from the segment
  If theSegment Is Nothing Then
      Err.Raise vbObjectError, "RiverPoint.estimateDepth", "Please set the RiverSegment for estimation of river depth"
  End If
 
  
'2) Dieser RiverPoint geht in eine Iterationsschleife, die die IterationStep -
'   Methode so lange aufruft, bis diese false (was anzeigt, dass sich keine
'   Änderung mehr ergeben hat) zurück gibt.

  'Dim debStream As TextStream
  'Set debStream = frmProcessSlopes.CreateTextStream("Datei für Debuging")
  Dim counter As Integer
  Do While iterationStep(Me)
      counter = counter + 1
      'debStream.WriteLine "Iterationsschritt " & counter
      'debStream.WriteBlankLines 2
      'allDepthsOutput Me, debStream
      If counter > IterationUnstableCount Then
         MsgBox "Iteration for depth is not stable after " & counter & _
                "steps. Using values as they are now. Check whether they " & _
                "are useful.", vbOKOnly, "Calculating river depth"
         allDepthsOK Me
         Exit Sub
      End If
  Loop
End Sub
Public Sub allDepthsOutput(calling As RiverPoint, s As TextStream)
    s.WriteLine ID & " " & depth
    If Not calling Is downstream And Not downstream Is Nothing Then
       downstream.allDepthsOutput Me, s
    End If
    Dim counter As Integer
    For counter = 0 To numUpstream - 1
      If Not calling Is upstream(counter) Then
        upstream(counter).allDepthsOutput Me, s
      End If
    Next
End Sub
Public Function allDepthsOK(calling As RiverPoint)
    depthIsOK = True
    If Not calling Is downstream And Not downstream Is Nothing Then
       downstream.allDepthsOK Me
    End If
    Dim counter As Integer
    For counter = 0 To numUpstream - 1
      If Not calling Is upstream(counter) Then
        upstream(counter).allDepthsOK Me
      End If
    Next
End Function
Public Function iterationStep(calling As RiverPoint) As Boolean

    '3) IterationStep berechnet erst eine neue Tiefe. Dazu werden die momentan
    '   geschätzten Tiefen (currentChannelBottomElevation) für angrenzende
    '   RiverPoints benötigt, um die Steigung zu berechnen.
    
    
    
    Dim newDepth As Double
    Dim bottomSlope As Double
    
    bottomSlope = calcChannelBottomSlope(True)
    
    
    
    newDepth = depthEstimationFormula(theSegment.CriticalRainFall, _
                                      CatchmentArea, _
                                      theSegment.WidthToDepthRatio, _
                                      theSegment.ChannelBankSlope, _
                                      bottomSlope, _
                                      theSegment.StricklerRoughness)
    
    '4) IterationStep ruft nun die IterationStep für alle angrenzenden RiverPoints
    '   auf, mit Ausnahme des aufrufendnen RiverPoints
    Dim changeOccured As Boolean
    changeOccured = False
    If Not calling Is downstream And Not downstream Is Nothing Then
       changeOccured = downstream.iterationStep(Me)
    End If
    Dim counter As Integer
    For counter = 0 To numUpstream - 1
      If Not calling Is upstream(counter) Then
        changeOccured = changeOccured Or upstream(counter).iterationStep(Me)
      End If
    Next
    
    
    '5) IterationStep setzt die momentan geschätzte Tiefe auf die jetztige Tiefe
    If Abs(depth - newDepth) > DepthIterationLimit Then
      changeOccured = True
    End If
    depth = newDepth
    '6) IterationStep gibt true zurück, falls die IterationStep Methode eines
    '   der angrenzenden RiverPoints true zurück gab, oder wenn die neue Tiefe
    '   mehr als ein Grenzwert von der alten Tiefe abweicht.
    
    If Not changeOccured Then depthIsOK = True

    
    iterationStep = changeOccured
    

End Function
Public Property Let ChannelDepth(n As Double)
  If depth <= 0 Then
    Err.Raise vbObjectError, "RiverPoint.setChannelDepth", "depth must be > 0"
  End If
  depth = ChannelDepth
  depthIsOK = True
End Property

Public Property Get X() As Double
  X = thePoint.X
End Property
Public Property Let X(n As Double)
  thePoint.X = n
End Property

Public Property Get Y() As Double
  Y = thePoint.Y
End Property
Public Property Let Y(n As Double)
  thePoint.Y = n
End Property
Public Property Get Z() As Double
  Z = thePoint.Z
End Property
Public Property Let Z(n As Double)
  thePoint.Z = n
End Property
Public Property Get ID() As Integer
  ID = thePoint.ID
End Property
Public Property Let ID(n As Integer)
  thePoint.ID = n
End Property
Public Property Get order() As Double
  order = thePoint.M
End Property
Public Property Let order(n As Double)
  thePoint.M = n
End Property

Private Sub Class_Initialize()
  Set thePoint = New Point
  depthIsOK = False
  isOutlet = False
  cArea = -1
  maxUpstream = 6
  numUpstream = 0
  ReDim upstream(maxUpstream)
End Sub

Public Sub CatflowParameterOutput(outStream As TextStream)
  'Need information from the segment
  If RiverSegment Is Nothing Then
      Err.Raise vbObjectError, "RiverPoint.CatflowParameterOutput", "Please set the RiverSegment "
  End If
  
  If RiverNet Is Nothing Then
      Err.Raise vbObjectError, "RiverPoint.CatflowParameterOutput", "Please set the RiverNet"
  End If
  
    ' ib INT  number of node, negative values mark nodes for which a hydrograph is dumped to the output file
    outStream.Write ID & " "
    '  ibnext INT  next downstream node number
    Dim theID As Integer
    If IsTheOutlet Then
      theID = 0
    Else
      theID = DownstreamRiverPoint.ID
    End If
    outStream.Write theID & " "
    '  ib_ord INT  Strahler order
    outStream.Write order & " "
    '  inhang  INT  number of hillslope connected to node
    outStream.Write slopeID & " "
    '  inarea  INT  sealed surface connected (1) / not connected (0)
    outStream.Write IIf(theSegment.SealedAreasConnected, 1, 0) & " "
    '  xba  REAL  relative x-coordinate [m]
    outStream.Write numberFormat(X - theSegment.XRef) & " "
    '  yba  REAL  relative y-coordinate [m]
    outStream.Write numberFormat(Y - theSegment.YRef) & " "
    '  b_vorl  REAL  DEM-elevation at node [m+NN]
    outStream.Write numberFormat(Z - theSegment.XRef) & " "
    '  b_dx  REAL  distance to next downstream node [m]
    Dim dist As Double
    Dim dh As Double
    Dim theSlope As Double
    If IsTheOutlet Then
      dist = 0
      dh = 0
      theSlope = 0
    Else
      dist = distance(Me.IPoint, DownstreamRiverPoint.IPoint)
      dh = Z - DownstreamRiverPoint.Z
      theSlope = dh / dist
    End If
    outStream.Write numberFormat(dist) & " "
    '   REAL  difference in elevation to next downstream node [m]
    outStream.Write numberFormat(dh) & " "
    '   INT  DEM-slope to next downstream node [-]
    outStream.Write numberFormat(theSlope) & " "
    '  aahang  REAL  hillslope surface [sqm]
    outStream.Write numberFormat(SlopeArea) & " "
    '  b_ezg  REAL  local catchment area [sqm]
    outStream.Write numberFormat(CatchmentArea) & " "
    '  ib_reg  INT  number of rainfall station associated to node
    outStream.Write Me.RiverNet.getRainstationID(Me.IPoint) & " "
    '  b_rauh  REAL  Strickler-roughness
    outStream.Write theSegment.StricklerRoughness & " "
    '  b_yso  REAL  elevation of channel bottom [m+NN]
    outStream.Write numberFormat(ChannelBottomElevation) & " "
    '  y_vorl  REAL  channel depth [m]
    outStream.Write numberFormat(ChannelDepth) & " "
    '  brso  REAL  bottom width of trapezoidial channel bottom [m]
    outStream.Write numberFormat(ChannelBottomWidth) & " "
    '  b_m  INT  slope of channel banks [-]
    outStream.Write theSegment.ChannelBankSlope & " "
    '  b_gef  REAL  bottom slope to next downstream node [-]
    outStream.Write numberFormat(ChannelBottomSlope) & " "
    '  weg_br  REAL  width of sealed surface parallel to channel [m]
    outStream.Write numberFormat(theSegment.SealedSurfaceWidthParallelToChannel) & " "
    '  qbas  REAL  lateral baseflow per unit channel length [cbm/s/m]
    outStream.Write "0. "
    ' flek REAL leakage factor used as weight factor for the soil hydraulic conductivity at the hillslope boundary to the channel
    outStream.Write "1. "
    ' iqsour REALspecifies whether a node is boundary node (iqsour = 1) or not (iqsour = 0)
    outStream.WriteLine "0"
End Sub
