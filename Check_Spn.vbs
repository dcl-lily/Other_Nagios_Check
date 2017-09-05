' Auth :	Alex
' File:        querySpn.vbs
' Contents:   Query  SPN in a  UserName
' History:   2017-9-4    creat 
Option Explicit     
Dim oConnection, oCmd, oRecordSet
Dim oGC, oNSP
Dim strGCPath, strUserName, strADOQuery
Dim vSPNs, vName
Dim STATUS,SPN_Name,SPN_Count,SPN_RE

ParseCommandLine()

'--- Set up the connection ---
Set oConnection = CreateObject("ADODB.Connection")
Set oCmd = CReateObject("ADODB.Command")
oConnection.Provider = "ADsDSOObject"
oConnection.Open "ADs Provider"
Set oCmd.ActiveConnection = oConnection
oCmd.Properties("Page Size") = 100

'--- Build the query string ---
strADOQuery = "<" & strGCPath & ">;(samAccountName=" & strUserName & ");servicePrincipalName"

'----Wscript.Echo strADOQuery
oCmd.CommandText = strADOQuery

'--- Execute the query for the object in the directory ---
Set oRecordSet = oCmd.Execute
SPN_Count=0
If oRecordSet.EOF and oRecordSet.Bof Then
	STATUS=False
Else
	STATUS=False
	SPN_Name=True
	If WScript.Arguments.Count <> 2 Then
		SPN_Name=False
		STATUS=True
	End if 
	 While Not oRecordset.Eof
		vSPNs = oRecordset.Fields("servicePrincipalName")
		if varType(vSPNs) <> 1 then
			For Each vName in vSPNs
			if SPN_Name then
				if vName = WScript.Arguments(1) then
					STATUS=True
					SPN_RE=vName
					SPN_Count= SPN_Count + 1
				end if
			else
				SPN_RE =SPN_RE + "  --" + vName
				SPN_Count= SPN_Count + 1
			end if
		Next
		else
			STATUS=False
		end if
		oRecordset.MoveNext
	 Wend
End If

if STATUS then
	Wscript.Echo "OK - Fount User:"&strUserName&" SPN number:" & SPN_Count & " SPNS:" & SPN_RE & "|Spn_number="&SPN_Count
	wscript.quit 1
else
	Wscript.Echo "Critical-No SPN found in User " & strUserName  & "|Spn_number="&SPN_Count
	wscript.quit 2
end if 
oRecordset.Close
oConnection.Close

Sub ShowUsage()
   Wscript.Echo "Check that only the specified SPN is used under the user "
   Wscript.Echo "There are authorized users running on any member server in the domain"
   Wscript.Echo "Use:    " & WScript.ScriptName & _
        " UserName SPN_Name "
   Wscript.Echo
   Wscript.Echo " EXAMPLES: " 
   Wscript.Echo "           " & WScript.ScriptName & _
        " sqladmin MSSQLSvc/MySQL.company.com:1433"
   Wscript.Echo "           " & WScript.ScriptName & _
        " administrator"
   Wscript.Quit 0
End Sub

Sub ParseCommandLine()
  If WScript.Arguments.Count <> 1 And WScript.Arguments.Count <> 2 Then
		ShowUsage()  '查看帮助信息
  Else
   strUserName = WScript.Arguments(0)
    '--- Get GC -- 
    Set oNSP = GetObject("GC:")
    For Each oGC in oNSP
      strGCPath = oGC.ADsPath
    Next
 End If 
End Sub