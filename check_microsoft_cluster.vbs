''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'
' NAME:		check_microsoft_cluster.vbs
' VERSION:	2.0
' AUTHOR:	Herbert Stadler (hestadler@gmx.at)
'
' COMMENT:	Script for Checking MSCS Cluster resources
'		    for use with Nagios and NSClient++
'
' Modification History: 
'			2010-04-15 Creation
'			2017-07-19	Alex 
'
' 
' License Information:
' This program is free software; you can redistribute it and/or modify
' it under the terms of the GNU General Public License as published by
' the Free Software Foundation; either version 3 of the License, or
' (at your option) any later version.
'
' This program is distributed in the hope that it will be useful,
' but WITHOUT ANY WARRANTY; without even the implied warranty of
' MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
' GNU General Public License for more details.
'
' You should have received a copy of the GNU General Public License
' along with this program; if not, see <http://www.gnu.org/licenses/>.
'
'
'
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' NAGIOS DEFINITIONS:
'
'  ### command definition ###
'
'  define command {
'  		command_name check_mscs
'  		command_line $USER1$/check_nrpe -H $HOSTADDRESS$ -p 5666 -t 30 -c check_mscs -a "$ARG1$" "$ARG2$"
'  }


'  ### service definition ###

'  define service{
'  		use generic-service
'  		host_name CLUSTERPPCL
'  		service_description Microsoft Cluster Resources
'  		process_perf_data 0
'  		check_command check_mscs!CLRES!"SQL Server,Disk S:"
'  }
'
' or
' 
'  check_command check_mscs!"CLRES"
'  check_command check_mscs!"CLRESP"
'  check_command check_mscs!"CLNODE"
'


Option explicit

Dim strArglist
Dim strWmiQuery
Dim strResName
Dim strNodeName
Dim strResultCritical
Dim strResultWarning
Dim strStatus
Dim arrResNames
Dim arrNodeNames
Dim objArgs
Dim objItem
Dim objWMIService
Dim colItems
Dim i
Dim strArg, objArg
Dim strCommand
Dim CheckedElement
Dim objCluster


'Nagios 返回状态
Const intOK = 0
Const intWarning = 1
Const intCritical = 2
Const intUnknown = 3

' 是否跳过未设置首选节点的资源
Const strCHECK_EMPTY_PREFERREDNODE = "NO"

strResultCritical = ""
strResultWarning = ""

'获取参数值
Set objArgs = WScript.Arguments

'判断是否有参数,如没有执行帮助
if objArgs.Count = 0 then 
	Display_Usage()
end if 

'判断是否有帮助参数
for Each objArg In objargs
	strArg = LCase(objArg)
		Select Case strArg
		Case "-h"
			Display_Usage()
		Case "--help"
			Display_Usage()
		Case "-help"
			Display_Usage()
		Case "-?"
			Display_Usage()
		Case "/?"
			Display_Usage()
		Case "/h"
			Display_Usage()
		End Select
Next

'第一个参数检查类型，CLRES 、CLNODE 、CLRESP
strCommand=UCase(objArgs(0))

strArglist=""
'判断第一个参数是否是预定的监控选项
'CLRES   判断资源状态是否正常online
'CLRESP  判断资源状态状态以及是否在首选节点上运行
'CLNODE  判断群集节点状态
'
'
'
if strCommand = "CLRES" or strCommand = "CLNODE" or strCommand = "CLRESP" Then
	'参数列表化
	If objArgs.Count > 1 Then
		for i = 1 to objArgs.Count - 1
			if objArgs(i) = "$ARG2$" or _
			   objArgs(i) = "$ARG3$" or _
			   objArgs(i) = "$ARG4$" then
			else
				If strArglist = "" Then
					strArglist = objArgs(i)
				Else
					strArglist = strArglist & " " & objArgs(i)
				End If
			end if
		next
	End if
End if

'连接到本地群集
Set objCluster = CreateObject("MSCluster.Cluster")
objCluster.Open ""  

'获取群集命名空间
Set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\mscluster")

'判断检查项，不同检查，不同过程
Select Case strCommand

	Case "CLRES"
		Check_CLRES(strCommand)

	Case "CLRESP"
		Check_CLRES(strCommand)

	Case "CLNODE"
		arrNodeNames = Split(strArglist, ",")
		
		'查询节点名称
		strWmiQuery = "Select * from MSCluster_Node"
		Set colItems = objWMIService.ExecQuery(strWmiQuery)
		
		'节点判断,如参数节点全存在则继续，否则结束
		if Entered_Values_Wrong(colItems,arrNodeNames) then
			Wscript.StdOut.WriteLine "节点未知: " & CheckedElement
			WScript.Quit(intUnknown)
		end if
		
		'遍历查询的节点
		For Each objItem in colItems
			do while true
				'
				if not Object_in_Array(objItem.Name, arrNodeNames) then
					exit do
				End if
				
				strStatus=Explain_Node_State (objItem.State)

				If strStatus = "paused" or strStatus = "joining" Then
					if strResultWarning <> "" then
						strResultWarning=strResultWarning & ", "
					end if
					strResultWarning = strResultWarning & objItem.Name & " (" & strStatus & ")"
				End If
				
				If strStatus = "down" or strStatus = "unknown" Then
					if strResultCritical <> "" then
						strResultCritical=strResultCritical & ", "
					end if
					strResultCritical = strResultCritical & objItem.Name & " (" & strStatus & ")"
				End If
				
				exit do
			loop
		next

		If strResultWarning = "" and strResultCritical = "" Then
			Wscript.StdOut.WriteLine "OK - Clusternodes"
			WScript.Quit(intOK)
		End If
		If strResultCritical = "" Then
			Wscript.StdOut.WriteLine "WARNING - Clusternodes: " & strResultWarning
			WScript.Quit(intWarning)
		Else
			dim strMsgOut
			strMsgOut="CRITICAL - Clusternodes: " & strResultCritical 
			if strResultWarning <> "" then
				strMsgOut=strMsgOut & ", " & strResultWarning
			end if
			Wscript.StdOut.WriteLine strMsgOut
			WScript.Quit(intCritical)
		End If
		
	Case "LIST"
		wscript.StdOut.WriteLine "List of Cluster Resource Information"
		wscript.StdOut.WriteLine "------------------------------------"
		strWmiQuery = "Select * from MSCluster_Resource"
		Set colItems = objWMIService.ExecQuery(strWmiQuery)
		For Each objItem in colItems
			wscript.StdOut.WriteLine Make_Length(objItem.Name,40) & vbTab & Explain_Res_State (objItem.State) & vbTab & objItem.Status
		next
		
		wscript.StdOut.WriteLine ""
		wscript.StdOut.WriteLine "List of Cluster Node Information"
		wscript.StdOut.WriteLine "----------------------------------"
		strWmiQuery = "Select * from MSCluster_Node"
		Set colItems = objWMIService.ExecQuery(strWmiQuery)
		For Each objItem in colItems
			wscript.StdOut.WriteLine objItem.Name & vbTab & vbTab & Explain_Node_State (objItem.State) & vbTab & objItem.Status
		next

		wscript.StdOut.WriteLine ""
		wscript.StdOut.WriteLine "List of Cluster Network Information"
		wscript.StdOut.WriteLine "-----------------------------------"
		strWmiQuery = "Select * from MSCluster_Network"
		Set colItems = objWMIService.ExecQuery(strWmiQuery)
		For Each objItem in colItems
			wscript.StdOut.WriteLine Make_Length(objItem.Name,20) & vbTab & Explain_Net_State (objItem.State) & vbTab & objItem.Status
		next
		
		wscript.StdOut.WriteLine ""
		wscript.StdOut.WriteLine "List of Cluster Resource Group Information"
		wscript.StdOut.WriteLine "------------------------------------------"
		strWmiQuery = "Select * from MSCluster_ResourceGroup"
		Set colItems = objWMIService.ExecQuery(strWmiQuery)
		For Each objItem in colItems
			wscript.StdOut.WriteLine Make_Length(objItem.Name,20) & vbTab & Explain_Group_State (objItem.State) & vbTab & objItem.Status & vbTab & objItem.AutoFailbackType
		next
		
		wscript.StdOut.WriteLine ""
		wscript.StdOut.WriteLine "List of Cluster Resource Group Preferred Node Information"
		wscript.StdOut.WriteLine "---------------------------------------------------------"
		strWmiQuery = "Select * from MSCluster_ResourceGroupToPreferredNode"
		Set colItems = objWMIService.ExecQuery(strWmiQuery)
		For Each objItem in colItems
			wscript.StdOut.WriteLine Make_Length(objItem.GroupComponent,20) & vbTab & objItem.PartComponent
		next
		
		Dim res
		Dim resGroup
		For Each res in objCluster.Nodes
			For Each resGroup in res.ResourceGroups
				If (resGroup.PreferredOwnerNodes.count > 0) Then
					For i=1 To resGroup.PreferredOwnerNodes.count
						if resGroup.OwnerNode.Name <> resGroup.PreferredOwnerNodes.Item(i).Name then
							wscript.StdOut.WriteLine "!!WARNING!! Resource Group " & resGroup.Name & " not on PreferredNode " & resGroup.PreferredOwnerNodes.Item(i).Name
						end if
					next
				else
					wscript.StdOut.WriteLine "!!WARNING!! Resource Group " & resGroup.Name & " no PreferredNode set"
				end if
			next
		next
		
		wscript.StdOut.WriteLine ""
		wscript.StdOut.WriteLine "List of Cluster Resource Type Information"
		wscript.StdOut.WriteLine "-----------------------------------------"
		strWmiQuery = "Select * from MSCluster_ResourceType"
		Set colItems = objWMIService.ExecQuery(strWmiQuery)
		For Each objItem in colItems
			wscript.StdOut.WriteLine Make_Length(objItem.Name,20) & vbTab & objItem.Status
		next

		wscript.StdOut.WriteLine ""
		wscript.StdOut.WriteLine "List of Cluster Service Information"
		wscript.StdOut.WriteLine "-----------------------------------"
		strWmiQuery = "Select * from MSCluster_Service"
		Set colItems = objWMIService.ExecQuery(strWmiQuery)
		For Each objItem in colItems
			wscript.StdOut.WriteLine Make_Length(objItem.Name,20) & vbTab & objItem.SystemName & vbTab & objItem.State & vbTab & objItem.Status 
		next

		wscript.StdOut.WriteLine ""
		wscript.StdOut.WriteLine "List of Cluster Information"
		wscript.StdOut.WriteLine "---------------------------"
		strWmiQuery = "Select * from MSCluster_Cluster"
		Set colItems = objWMIService.ExecQuery(strWmiQuery)
		For Each objItem in colItems
			wscript.StdOut.WriteLine Make_Length(objItem.Name,20) & vbTab & objItem.Status
		next

		
		WScript.Quit(intOK)
		
	Case else
		Wscript.StdOut.WriteLine "Parameter wrong: " & strCommand
		WScript.Quit(intUnknown)
		
End Select

Function Check_CLRES (strCommand)

	arrResNames = Split(strArglist, ",")
		
	strWmiQuery = "Select * from MSCluster_Resource"
	Set colItems = objWMIService.ExecQuery(strWmiQuery)
		
	if Entered_Values_Wrong(colItems,arrResNames) then
		Wscript.StdOut.WriteLine "Entered ResourceNames wrong: " & CheckedElement
		WScript.Quit(intUnknown)
	end if
		
	For Each objItem in colItems
		do while true 
			if not Object_in_Array(objItem.Name, arrResNames) then
				exit do
			End if
			
			strStatus=Explain_Res_State (objItem.State)

			If strStatus <> "online" Then
				if strResultCritical <> "" then
					strResultCritical=strResultCritical & ", "
				end if
				strResultCritical = strResultCritical & objItem.Name & " (" & strStatus & ")"
			End If
				
			exit do
		Loop
	Next

	If strResultCritical = "" Then
		if ( strCommand = "CLRESP" ) Then
			dim strPrefNode
			strPrefNode=Check_ClusterResource_PreferredNode()
			if ( strPrefNode <> "" ) then
				Wscript.StdOut.WriteLine "WARNING - Clusterresource: " & toUTF8(strPrefNode) & " not on preferred node"
				WScript.Quit(intWarning)
			End If
		end if
		Wscript.StdOut.WriteLine "OK - Clusterresource"
		WScript.Quit(intOK)
	Else
		Wscript.StdOut.WriteLine "CRITICAL - Clusterresource: " & toUTF8(strResultCritical)
		WScript.Quit(intCritical)
	End If
End Function

Function Check_ClusterResource_PreferredNode ()
	Dim res
	Dim resGroup
	Dim strResult
	Dim PerferrCount
	
	strResult=""
	
	For Each res in objCluster.Nodes
		For Each resGroup in res.ResourceGroups
			If (resGroup.PreferredOwnerNodes.count > 0) Then
				PerferrCount=resGroup.PreferredOwnerNodes.count
				For i=1 To PerferrCount
					if resGroup.OwnerNode.Name <> resGroup.PreferredOwnerNodes.Item(i).Name then
						if i=PerferrCount Then
							strResult=Build_String(strResult,resGroup.Name)
							Exit For
						end if
					else
						Exit for
					end if
				next
			else
				if ( strCHECK_EMPTY_PREFERREDNODE = "YES" ) Then
					'Wscript.StdOut.WriteLine  toUTF8(resGroup.Name)
					strResult=Build_String(strResult,resGroup.Name)
				End If
			end if
		next
	next
	
	Check_ClusterResource_PreferredNode=strResult
End Function

Function Build_String (strResult,strName)

	if ( strResult <> "" ) then
		strResult=strResult & ", "
	end if
	strResult=strResult & strName
	
	Build_String=strResult

End Function

Function Explain_Node_State (state)
	dim strStatus
	
	Select Case state
		Case 0 strStatus = "up"
		Case 1 strStatus = "down"
		Case 2 strStatus = "paused"
		Case 3 strStatus = "joining"
		Case Else strStatus = "unknown"
	End Select

	Explain_Node_State=strStatus

End Function

Function Explain_Group_State (state)
	dim strStatus
	
	Select Case state
		Case 0 strStatus = "Online"
		Case 1 strStatus = "Offline"
		Case 2 strStatus = "Failed"
		Case 3 strStatus = "PartialOnline"
		Case 4 strStatus = "Pending"
		Case Else strStatus = "StateUnknown"
	End Select

	Explain_Group_State=strStatus

End Function

Function Explain_Net_State (state)
	dim strStatus
	
	Select Case state
		Case 0 strStatus = "StateUnavailable"
		Case 1 strStatus = "Down"
		Case 2 strStatus = "Partitioned"
		Case 3 strStatus = "Up"
		Case Else strStatus = "StateUnknown"
	End Select

	Explain_Net_State=strStatus

End Function


Function Explain_Res_State (state)
	dim strStatus
	
	Select Case state
		Case 2 strStatus = "online"
		Case 3 strStatus = "offline"
		Case 4 strStatus = "failed"
		Case 129 strStatus = "online pending"
		Case 130 strStatus = "offline pending"
		Case Else strStatus = "unknown"
	End Select
	
	Explain_Res_State=strStatus

End Function

Function Display_Usage
' =================================
'
'
'    脚本使用方法
'    传入参数:无
'    返回值:直接结束运行，并返回使用方法，状态值为3
'
'
'============================
	Wscript.StdOut.WriteLine ""
	Wscript.StdOut.WriteLine "Check Microsoft Cluster Usage"
	Wscript.StdOut.WriteLine ""
	Wscript.StdOut.WriteLine "    check_microsoft_cluster.vbs CLRES  [resource list]" & vbcrlf
	wscript.StdOut.WriteLine "  same as above with checking if owner = preferred owner (preferred node)"  
	Wscript.StdOut.WriteLine "    check_microsoft_cluster.vbs CLRESP [resource list]" & vbcrlf                     
	Wscript.StdOut.WriteLine "    check_microsoft_cluster.vbs CLNODE [node list]"
	Wscript.StdOut.WriteLine vbcrlf & "  for debugging purposes:"
	Wscript.StdOut.WriteLine "    check_microsoft_cluster.vbs LIST"
	Wscript.StdOut.WriteLine ""
	Wscript.StdOut.WriteLine vbTab & "resource list    list of MSCS resource names to be monitored"
	Wscript.StdOut.WriteLine vbTab & "node list        list of MSCS node names to be monitored"
	Wscript.StdOut.WriteLine ""
	Wscript.StdOut.WriteLine "List items are comma separated."
	Wscript.StdOut.WriteLine ""
	WScript.Quit(intUnknown)

End Function

Function Make_Length (sstr, slen)

	Dim istrlen
	istrlen=len(sstr)

	istrlen = slen - istrlen
	if istrlen > 0 then
		Make_Length=sstr & space(istrlen)
	else
		Make_Length=sstr
	End If

End Function

Function Object_in_Array(strName, arrNames)

	dim strElement

	if ubound(arrNames) < 0 then
		Object_in_Array=true
		exit function
	end if
	
	
	For Each strElement in arrNames
		if StrComp(strName,strElement,0) = 0  then
			Object_in_Array=true
			exit function
		end if

	Next

	Object_in_Array=false
End Function

function Entered_Values_Wrong(colItems,arrNames)
'=======================================
'
'比较需要检查的组是否存储资源存储中，都存在返回False，否则返回True
'
'传入参数  两个数组
'
'返回值：  True or False
	
	dim strElement
	dim sFound
	
	'判断是否有相关的检查项，如没有返回False
	if ubound(arrNames) < 0 then
		Entered_Values_wrong=false
		exit function
	end if
	
	'检查参数中的检查项目是否存在,如都存在，返回true,如有一个不存在返回False
	For Each strElement in arrNames
		sFound=false
		CheckedElement=strElement
		For Each objItem in colItems
			if objItem.Name = strElement then
				sFound=true
			end if
		next
		if sFound = false then
			Entered_Values_wrong=true
			exit function
		end if
	next
	
	Entered_Values_wrong=false
	
end function

Function toUTF8(szInput)
    Dim wch, uch, szRet
    Dim x
    Dim nAsc, nAsc2, nAsc3
    '如果输入参数为空，则退出函数
    If szInput = "" Then
        toUTF8 = szInput
        Exit Function
    End If
    '开始转换
    For x = 1 To Len(szInput)
        '利用mid函数分拆GB编码文字
        wch = Mid(szInput, x, 1)
        '利用ascW函数返回每一个GB编码文字的Unicode字符代码
        '注：asc函数返回的是ANSI 字符代码，注意区别
        nAsc = AscW(wch)
		'Wscript.StdOut.WriteLine "fist GB:" & nAsc
        If nAsc < 0 Then nAsc = nAsc + 65536
   
        If (nAsc And &HFF80) = 0 Then
            szRet = szRet & wch
        Else
            If (nAsc And &HF000) = 0 Then
                uch = "%" & Hex(((nAsc / 2 ^ 6)) Or &HC0) & Hex(nAsc And &H3F Or &H80)
                szRet = szRet & uch
            Else
               'GB编码文字的Unicode字符代码在0800 - FFFF之间采用三字节模版
                uch = "%" & Hex((nAsc / 2 ^ 12) Or &HE0) & "%" & _
                            Hex((nAsc / 2 ^ 6) And &H3F Or &H80) & "%" & _
                            Hex(nAsc And &H3F Or &H80)
                szRet = szRet & uch
            End If
        End If
	next
    toUTF8 = szRet
End Function