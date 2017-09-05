'----------------------
'获得文件夹的大小
'Author  = Alex
'Version = 1.0
'Date  = 2017-6-21
'----------------------
Option Explicit
'On Error Resume Next
Dim objFSO, objLocalFolder, strArg, longLocalFolderSize, strSizeMess
dim Warning,Critical,STATUS_OK,STATUS_Warning,STATUS_Critical,STATUS_Unknown,retun_code
'判断是不是没有路径参数

'单位已Bit计算,例如50M 就是50 *1024 * 1024 = 53964800
Warning=53964800
Critical=1073741824

STATUS_OK=0
STATUS_Warning=1
STATUS_Critical=2
STATUS_Unknown=3

If WScript.Arguments.Count < 1 Then
  WScript.Echo "No directory"
  WScript.Quit STATUS_Unknown
Else
  strArg = WScript.Arguments(0)
End If
 
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objLocalFolder = objFSO.GetFolder(strArg)
 
If objLocalFolder = Empty Then
  WScript.Echo "Invalid directory"
  WScript.Quit STATUS_Unknown
End If
 
longLocalFolderSize = objLocalFolder.Size 
 
If longLocalFolderSize>=1024 And longLocalFolderSize<1024*1024 Then
  strSizeMess = Round( longLocalFolderSize/1024, 3 ) & "K"
  ElseIf longLocalFolderSize>=1024*1024 And longLocalFolderSize<1024*1024*1024 Then
  strSizeMess = Round( longLocalFolderSize/1024/1024, 3 ) & "M"
  ElseIf longLocalFolderSize>=1024*1024*1024 Then
   strSizeMess = Round( longLocalFolderSize/1024/1024/1024, 3 ) & "G"
   Else
   strSizeMess = longLocalFolderSize & "B"
End If

Set objFSO = Nothing
Set objLocalFolder = Nothing

if longLocalFolderSize > Critical then

	WScript.Echo "Critical-directory Size:" & strSizeMess & "| directory_Size=" & longLocalFolderSize & ";" & Warning & ";" & Critical
	retun_code=STATUS_Critical

elseif longLocalFolderSize > Warning then

	WScript.Echo "Warning-directory Size:" & strSizeMess & "| directory_Size=" & longLocalFolderSize & ";" & Warning & ";" & Critical
	retun_code=STATUS_Warning
else

	WScript.Echo "OK-directory Size:" & strSizeMess & "| directory_Size=" & longLocalFolderSize & ";" & Warning & ";" & Critical
	retun_code=STATUS_OK
end if

WScript.Quit retun_code