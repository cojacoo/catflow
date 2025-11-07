VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Queue"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
' By Chris Rae, 6/11/01
' The queues produced are one element too large - this
' is deliberate as it hugely simplifies the logic involved
' in handling empty ones.

Option Explicit
Const qtLIFO = 1
Const qtFIFO = 2
Const defqueuesize = 100
Const defqueuetype = qtFIFO
Private topidx As Integer ' Where the NEXT thing goes on top
Private bumidx As Integer ' Where the CURRENT thing is at the bottom
Private qtype As Integer
Private alldata() As Variant
Private qsize As Long
' The different queue types
Property Get qLIFO() As Integer
    qLIFO = qtLIFO
End Property
Property Get qFIFO() As Integer
    qFIFO = qtFIFO
End Property
Private Sub Class_Initialize()
    qtype = qFIFO
    Reset
End Sub
Public Sub Reset(Optional oftype As Integer = defqueuetype, Optional ofsize As Long = defqueuesize)
    ' FIFO (queue) by default
    qsize = ofsize + 1
    qtype = oftype
    ReDim alldata(0 To qsize) As Variant
    topidx = 0
    bumidx = 0
End Sub
Public Sub Push(topush As Variant)
    ' If the next item would overlap the current bottom one, stop
    If ((topidx + 1) Mod qsize) = bumidx Then
        Err.Raise vbObjectError + 1, , "Queue overflow"
    Else
        alldata(topidx) = topush
        topidx = ((topidx + 1) Mod qsize)
    End If
End Sub
Public Function IsEmpty() As Boolean
    IsEmpty = (bumidx = topidx)
End Function
Public Function IsFull() As Boolean
    IsFull = (((topidx + 1) Mod qsize) = bumidx)
End Function
Public Function Pop() As Variant
    If bumidx = topidx Then
        Err.Raise vbObjectError + 1, , "Queue underflow"
    Else
        If qtype = qFIFO Then
            Pop = alldata(bumidx)
            bumidx = ((bumidx + 1) Mod qsize)
        Else
            topidx = topidx - 1
            Pop = alldata(topidx)
        End If
    End If
End Function


