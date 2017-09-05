Set Args = WScript.Arguments
If WScript.Arguments.Count < 3 Then
	Err = 3
	WScript.Echo "检查windos时间同步状态"
	WScript.Echo "使用: cscript /NoLogo check_time.vbs serverlist warn crit [biggest]"
	Wscript.Echo ""
	Wscript.Echo "选项:"
	Wscript.Echo " serverlist(必须选项) NTP服务器列表，一个或多个使用逗号分隔"
	Wscript.Echo " warn  (必须选项): 警告阈值"
	Wscript.Echo " crit  (必须选项): 严重阈值"
	Wscript.Echo " biggest (可选选项): 如果指定多个服务器，使用biggest使用偏移量最大的服务器做对比，默认使用最小的" 
	Wscript.Echo ""
	Wscript.Echo "例如:"
	Wscript.Echo "cscript /NoLogo check_time.vbs myserver1,myserver2 0.4 5 biggest"
	Wscript.Quit(Err)
End If

'参数获取
serverlist = Args.Item(0)
warn = Args.Item(1)
crit = Args.Item(2)
If WScript.Arguments.Count > 3 Then
	criteria = Args.Item(3)
  Else
	criteria = least
End If

'NTP时间偏移获取
Set objShell = CreateObject("Wscript.Shell")
strCommand = "%SystemRoot%\System32\w32tm.exe /monitor /computers:" & serverlist
set objProc = objShell.Exec(strCommand)

'NTP数据提取
input = ""
strOutput = ""
Do While Not objProc.StdOut.AtEndOfStream
	input = objProc.StdOut.ReadLine
	If InStr(input, "NTP") Then
		strOutput = strOutput & input
	End If
Loop

'通过正则表达式获取具体的值
Set myRegExp = New RegExp
myRegExp.IgnoreCase = True
myRegExp.Global = True
myRegExp.Pattern = " NTP: ([+-][0-9]+\.[0-9]+)s"
Set myMatches = myRegExp.Execute(strOutput)

result = ""
If myMatches(0).SubMatches(0) <> "" Then
	result = myMatches(0).SubMatches(0)
End If

'值判断
For Each myMatch in myMatches
	If myMatch.SubMatches(0) <> "" Then
		If criteria = "biggest" Then
			If abs(result) < Abs(myMatch.SubMatches(0)) Then
				result = myMatch.SubMatches(0)
			End If
		Else
			If abs(result) > Abs(myMatch.SubMatches(0)) Then
				result = myMatch.SubMatches(0)
			End If
		End If
	End If
'	Wscript.Echo myMatch.SubMatches(0) & " -debug"
Next

If result = "" Then
	Err = 3
	Status = "UNKNOWN"
ElseIf abs(result) > Cdbl(crit) Then
	Err = 2
	status = "CRITICAL"
elseif abs(result) > Cdbl(warn) Then
	Err = 1
	status = "WARNING"
Else
	Err = 0
	status = "OK"
End If

Wscript.Echo "NTP " & status & ": Offset " & result & " secs|'offset'=" & result & "s;" & warn & ";" & crit & ";"
Wscript.Quit(Err)