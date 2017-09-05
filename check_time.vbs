Set Args = WScript.Arguments
If WScript.Arguments.Count < 3 Then
	Err = 3
	WScript.Echo "���windosʱ��ͬ��״̬"
	WScript.Echo "ʹ��: cscript /NoLogo check_time.vbs serverlist warn crit [biggest]"
	Wscript.Echo ""
	Wscript.Echo "ѡ��:"
	Wscript.Echo " serverlist(����ѡ��) NTP�������б�һ������ʹ�ö��ŷָ�"
	Wscript.Echo " warn  (����ѡ��): ������ֵ"
	Wscript.Echo " crit  (����ѡ��): ������ֵ"
	Wscript.Echo " biggest (��ѡѡ��): ���ָ�������������ʹ��biggestʹ��ƫ�������ķ��������Աȣ�Ĭ��ʹ����С��" 
	Wscript.Echo ""
	Wscript.Echo "����:"
	Wscript.Echo "cscript /NoLogo check_time.vbs myserver1,myserver2 0.4 5 biggest"
	Wscript.Quit(Err)
End If

'������ȡ
serverlist = Args.Item(0)
warn = Args.Item(1)
crit = Args.Item(2)
If WScript.Arguments.Count > 3 Then
	criteria = Args.Item(3)
  Else
	criteria = least
End If

'NTPʱ��ƫ�ƻ�ȡ
Set objShell = CreateObject("Wscript.Shell")
strCommand = "%SystemRoot%\System32\w32tm.exe /monitor /computers:" & serverlist
set objProc = objShell.Exec(strCommand)

'NTP������ȡ
input = ""
strOutput = ""
Do While Not objProc.StdOut.AtEndOfStream
	input = objProc.StdOut.ReadLine
	If InStr(input, "NTP") Then
		strOutput = strOutput & input
	End If
Loop

'ͨ��������ʽ��ȡ�����ֵ
Set myRegExp = New RegExp
myRegExp.IgnoreCase = True
myRegExp.Global = True
myRegExp.Pattern = " NTP: ([+-][0-9]+\.[0-9]+)s"
Set myMatches = myRegExp.Execute(strOutput)

result = ""
If myMatches(0).SubMatches(0) <> "" Then
	result = myMatches(0).SubMatches(0)
End If

'ֵ�ж�
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