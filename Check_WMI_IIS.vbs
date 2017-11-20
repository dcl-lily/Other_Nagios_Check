'======================================================
'
'   通过WMI读取IIS相关的性能值Win32_PerfRawData_W3SVC_WebService
'   详细说明请产考：
'   https://msdn.microsoft.com/zh-cn/subscriptions/downloads/aa394298(v=vs.85).aspx
'
'   使用方法 ：
'    cscript //Nologo 脚本名.vbs 站点名 对象名 警告阈值 严重阈值 比较方式
'   站点名和对象名必须指定，对象名称产考以上MSDN网站
'   警告、严重阈值，可以不指定，指定必须两个同时指定，而且必须为数值
'   比较方式 非必须，默认为gt 大于方式比较，还可以指定lt 小于方式比较
'
' example：
'    cscript //nologo Check_WMI_IIS.vbs mail BytesTotalPersec
'
'    cscript //nologo Check_WMI_IIS.vbs mail TotalLockedErrors 5 10
'
'    cscript //nologo Check_WMI_IIS.vbs mail ServiceUptime 3600 2400 lt
'
'   @author: AlexDu
'	@version: 1.1
'	@copyright: IT经验.
'	@license: GPLv3
'   https://www.qnjslm.com
'
'	2017-11-20
'=====================================================

strComputer ="."
dim war,crt,Compare_Check,OptionName,SiteName,Return_Code,Compare_type
Set Args = WScript.Arguments
If WScript.Arguments.Count < 2 Then
WScript.Echo"Use:"
WScript.Echo"cscript //Nologo" & Wscript.scriptname &" SiteName  OptionName [War] [Crt] [lt|gt]"
WScript.Echo"Example:"
WScript.Echo"cscript //Nologo" & Wscript.scriptname &" Default BytesReceivedPersec 80 100"
Wscript.Quit(3)
End if
SiteName = Args.Item(0)
OptionName = Args.Item(1)
If WScript.Arguments.Count > 3 Then
	war = Args.Item(2)
	crt = Args.Item(3)
	if not IsNumeric(crt) or not IsNumeric(war) then
		WScript.Echo " The threshold must be in the form of numbers"
		Wscript.Quit(3)
	end if 
	Compare_Check=True
else
	war=0
	crt=0
	Compare_Check=False
End If
Compare_type="gt"
if WScript.Arguments.Count > 4 then
	if Args.Item(4) = "lt" then
		Compare_type="lt"
	end if 
end if


Function Check_Value(val)
	Status = "OK-"
	Return_Code=0
	if Compare_Check then
		if IsNumeric(val) then
			if Compare_type = "gt" then
				if Clng(val) > Clng(crt) then
					Status= "Critical-"
					Return_Code=2
				elseif Clng(val) > Clng(war) then
					Status= "Warning-"
					Return_Code=1
				end if 
			else
				if Clng(val) < Clng(crt) then
					Status= "Critical-"
					Return_Code=2
				elseif Clng(val) < Clng(war) then
					Status= "Warning-"
					Return_Code=1
				end if 
	end if 
		end if
	end if
	
	WScript.Echo Status & OptionName & ": value is " & val & " on Site " & SiteName & "|" & OptionName & "=" & val & ";" & war & ";" & crt 
	Wscript.Quit(Return_Code)
end function

Set objWMIService = GetObject("winmgmts:\\"& strComputer &"\root\cimv2")
Set colItems = objWMIService.ExecQuery("Select * from Win32_PerfRawData_W3SVC_WebService where name='" & SiteName &"'",,48)

For Each objItem in colItems
	Select Case OptionName
	case "AnonymousUsersPersec" 
	'Rate at which users are making anonymous connections using the web service.
		Check_Value(objItem.AnonymousUsersPersec)
    case "BytesReceivedPersec" 
	'Rate at which bytes are received by the web service.
		Check_Value(objItem.BytesReceivedPersec)
    case "BytesSentPersec" 
	'Rate at which bytes are sent by the web service.
		Check_Value(objItem.BytesSentPersec)
    case "BytesTotalPersec" 
	'Sum of BytesSentPerSec and BytesReceivedPerSec. This is the total rate of bytes transferred by the web service.
		Check_Value(objItem.BytesTotalPersec)
    case "Caption"
	'Short textual description for the statistic or metric. This property is inherited from CIM_StatisticalInformation.
		Check_Value(objItem.Caption)
    case "CGIRequestsPersec" 
	'Rate of CGI requests that are simultaneously being processed by the web service.
		Check_Value(objItem.CGIRequestsPersec)
    case "ConnectionAttemptsPersec" 
	'Rate at which connections using the web service are being attempted.
		Check_Value(objItem.ConnectionAttemptsPersec)
    case "CopyRequestsPersec" 
	'Rate at which HTTP requests using the COPY method are made. COPY requests are used for copying files and directories.
		Check_Value(objItem.CopyRequestsPersec)
    case "CurrentAnonymousUsers" 
	'Number of users who currently have an anonymous connection using the web service.
		Check_Value(objItem.CurrentAnonymousUsers)
    case "CurrentBlockedAsyncIPerORequests" 
	'Current requests temporarily blocked due to bandwidth throttling settings.
		Check_Value(objItem.CurrentBlockedAsyncIPerORequests)
    case "CurrentCALcountforauthenticatedusers" 
	'
		Check_Value(objItem.CurrentCALcountforauthenticatedusers)
    case "CurrentCALcountforSSLconnections" 
		Check_Value(objItem.CurrentCALcountforSSLconnections)
    case "CurrentCGIRequests" 
	'Current number of CGI requests that are simultaneously being processed by the web service.
		Check_Value(objItem.CurrentCGIRequests)
    case "CurrentConnections" 
	'Current number of connections established with the web service.
		Check_Value(objItem.CurrentConnections)
    case "CurrentISAPIExtensionRequests" 
	'Current number of ISAPI extension requests that are simultaneously being processed by the web service.
		Check_Value(objItem.CurrentISAPIExtensionRequests)
    case "CurrentNonAnonymousUsers" 
	'Number of users who currently have a non-anonymous connection using the web service.
		Check_Value(objItem.CurrentNonAnonymousUsers)
    case "DeleteRequestsPersec" 
	'Rate at which HTTP requests using the DELETE method are made. DELETE requests are generally used for file removal.
		Check_Value(objItem.DeleteRequestsPersec)
    case "Description"
	'Textual description of the statistic or metric. This property is inherited from CIM_StatisticalInformation.
		Check_Value(objItem.Description)
    case "FilesPersec" 
	'Rate at which files are transferred; that is, sent and received by the web service.
		Check_Value(objItem.FilesPersec)
    case "FilesReceivedPersec" 
	'Rate at which files are received by the web service.
		Check_Value(objItem.FilesReceivedPersec)
    case "FilesSentPersec" 
	'Rate at which files are sent by the web service.
		Check_Value(objItem.FilesSentPersec)
    case "Frequency_Object" 
	'Frequency, in ticks per second, of Timestamp_Object. This property is defined by the provider. This property is inherited from Win32_Perf.
	'For more information about using uint64 values in scripts, see Scripting in WMI.
		Check_Value(objItem.Frequency_Object)
    case "Frequency_PerfTime" 
	'Frequency, in ticks per second, of Timestamp_Perftime. A value could be obtained by calling the Windows function QueryPerformanceCounter. This property is inherited from Win32_Perf.
	'For more information about using uint64 values in scripts, see Scripting in WMI.
		Check_Value(objItem.Frequency_PerfTime)
    case "Frequency_Sys100NS" 
	'Frequency, in ticks per second, of Timestamp_Sys1NS (10000000). This property is inherited from Win32_Perf.
	'For more information about using uint64 values in scripts, see Scripting in WMI.
		Check_Value(objItem.Frequency_Sys100NS)
    case "GetRequestsPersec" 
	'Rate at which HTTP requests using the GET method are made. GET requests are generally used for basic file retrievals or image maps, though they can be used with forms.
		Check_Value(objItem.GetRequestsPersec)
    case "HeadRequestsPersec" 
	'Rate at which HTTP requests using the HEAD method are made. HEAD requests generally indicate that clients are querying the state of documents they already have to see if they must be refreshed.
		Check_Value(objItem.HeadRequestsPersec)
    case "ISAPIExtensionRequestsPersec" 
	'Rate of ISAPI extension requests that are simultaneously being processed by the web service.
		Check_Value(objItem.ISAPIExtensionRequestsPersec)
    case "LockedErrorsPersec" 
	'Rate of errors due to requests that cannot be satisfied by the server because the requested document was locked. These are generally reported as an HTTP 423 error code to the client.
		Check_Value(objItem.LockedErrorsPersec)
    case "LockRequestsPersec" 
	'Rate at which HTTP requests using the LOCK method are made. LOCK requests are used to lock a file for one user so that only that user can modify the file.
		Check_Value(objItem.LockRequestsPersec)
    case "LogonAttemptsPersec" 
	'Rate at which logons using the web service are being attempted.
		Check_Value(objItem.LogonAttemptsPersec)
    case "MaximumAnonymousUsers" 
	'Maximum number of users who established concurrent anonymous connections using the web service (counted after service start up).
		Check_Value(objItem.MaximumAnonymousUsers)
    case "MaximumCALcountforauthenticatedusers" 
	
		Check_Value(objItem.MaximumCALcountforauthenticatedusers)
    case "MaximumCALcountforSSLconnections" 
		Check_Value(objItem.MaximumCALcountforSSLconnections)
    case "MaximumCGIRequests" 
	'Maximum number of CGI requests simultaneously processed by the web service.
		Check_Value(objItem.MaximumCGIRequests)
    case "MaximumConnections" 
	'Maximum number of simultaneous connections established with the web service.
		Check_Value(objItem.MaximumConnections)
    case "MaximumISAPIExtensionRequests" 
	'Maximum number of ISAPI extension requests simultaneously processed by the web service.
		Check_Value(objItem.MaximumISAPIExtensionRequests)
    case "MaximumNonAnonymousUsers" 
	'Maximum number of users who established concurrent non-anonymous connections using the web service (counted after service start up).
		Check_Value(objItem.MaximumNonAnonymousUsers)
    case "MeasuredAsyncIPerOBandwidthUsage" 
	'Measured bandwidth of asynchronous I/O averaged over a minute.
		Check_Value(objItem.MeasuredAsyncIPerOBandwidthUsage)
    case "MkcolRequestsPersec" 
	'Rate at which HTTP requests using the MKCOL method are made. MKCOL requests are used to create directories on the server.
		Check_Value(objItem.MkcolRequestsPersec)
    case "MoveRequestsPersec" 
	'Rate HTTP requests using the MOVE method are made. MOVE requests are used for moving files and directories.
		Check_Value(objItem.MoveRequestsPersec)
    case "Name" 
	'Label by which the statistic or metric is known. When sub-classed, the property can be overridden to be a key property. This property is inherited from CIM_StatisticalInformation.
		Check_Value(objItem.Name)
    case "NonAnonymousUsersPersec" 
	'Rate at which users are making non-anonymous connections using the web service.
		Check_Value(objItem.NonAnonymousUsersPersec)
    case "NotFoundErrorsPersec" 
	'Rate of errors due to requests that could not be  satisfied by the server because the requested document could not be found. These errors are generally reported as an HTTP 404 error code to the client.
		Check_Value(objItem.NotFoundErrorsPersec)
    case "OptionsRequestsPersec" 
	'Rate at which HTTP requests using the OPTIONS method are made.
		Check_Value(objItem.OptionsRequestsPersec)
    case "OtherRequestMethodsPersec" 
	'Rate at which HTTP requests are made that do not use the OPTIONS, GET, HEAD, POST, PUT, DELETE, TRACE, MOVE, COPY, MKCOL, PROPFIND, PROPPATCH, MS-SEARCH, LOCK or UNLOCK methods. These may include LINK or other methods supported by gateway applications.
		Check_Value(objItem.OtherRequestMethodsPersec)
    case "PostRequestsPersec" 
	'Rate at which HTTP requests using the POST method are made. POST requests are generally used for forms or gateway requests.
		Check_Value(objItem.PostRequestsPersec)
    case "PropfindRequestsPersec"
	'Rate at which HTTP requests using the PROPFIND method are made. PROPFIND requests retrieve property values on files and directories.
		Check_Value(objItem.PropfindRequestsPersec)
    case "ProppatchRequestsPersec" 
	'Rate at which HTTP requests using the PROPPATCH method are made. PROPPATCH requests set property values on files and directories.
		Check_Value(objItem.ProppatchRequestsPersec)
    case "PutRequestsPersec" 
	'Rate at which HTTP requests using the PUT method are made.
		Check_Value(objItem.PutRequestsPersec)
    case "SearchRequestsPersec" 
	'Rate at which HTTP requests using the MS-SEARCH method are made. MS-SEARCH requests query the server to find resources that match a set of client-provided conditions.
		Check_Value(objItem.SearchRequestsPersec)
    case "ServiceUptime" 
	'Time that the web service is available to users. 
		Check_Value(objItem.ServiceUptime)
    case "Timestamp_Object" 
	'Object-defined timestamp, defined by the provider. This property is inherited from Win32_Perf.
	'For more information about using uint64 values in scripts, see Scripting in WMI.
		Check_Value(objItem.Timestamp_Object)
    case "Timestamp_PerfTime" 
	'High Performance counter timestamp. A value can be obtained by calling the Windows function QueryPerformanceCounter. This property is inherited from Win32_Perf.
	'For more information about using uint64 values in scripts, see Scripting in WMI.
		Check_Value(objItem.Timestamp_PerfTime)
    case "Timestamp_Sys100NS" 
	'Timestamp value in 100 nanosecond units. This property is inherited from Win32_Perf.
	'For more information about using uint64 values in scripts, see Scripting in WMI.
		Check_Value(objItem.Timestamp_Sys100NS)
    case "TotalAllowedAsyncIPerORequests" 
	'Total requests that are allowed by bandwidth throttling settings (counted after service start up).
		Check_Value(objItem.TotalAllowedAsyncIPerORequests)
    case "TotalAnonymousUsers"
	'Total number of users who established an anonymous connection with the web service (counted after service start up).
		Check_Value(objItem.TotalAnonymousUsers)
    case "TotalBlockedAsyncIPerORequests"
	'Total requests that are temporarily blocked due to bandwidth throttling settings (counted after service startup).
		Check_Value(objItem.TotalBlockedAsyncIPerORequests)
    case "TotalCGIRequests" 
	'Total number of Common Gateway Interface (CGI) requests after service startup. CGI requests are custom gateway executable files (.exe) that the administrator can install to add forms processing or other dynamic data sources. CGI requests spawn a process on the server which can be a large drain on server resources.
		Check_Value(objItem.TotalCGIRequests)
    case "TotalConnectionAttemptsallinstances" 
	'Number of connections that have been attempted using the web service (counted after service startup). This property is for all instances listed.
		Check_Value(objItem.TotalConnectionAttemptsallinstances)
    case "TotalCopyRequests" 
	'Number of HTTP requests using the COPY method (counted after service startup). COPY requests are used for copying files and directories.
		Check_Value(objItem.TotalCopyRequests)
    case "TotalcountoffailedCALrequestsforauthenticatedusers" 
	'
		Check_Value(objItem.TotalcountoffailedCALrequestsforauthenticatedusers)
    case "TotalcountoffailedCALrequestsforSSLconnections" 
		Check_Value(objItem.TotalcountoffailedCALrequestsforSSLconnections)
    case "TotalDeleteRequests" 
	'Number of HTTP requests using the DELETE method (counted after service startup). DELETE requests are generally used for file removals.
		Check_Value(objItem.TotalDeleteRequests)
    case "TotalFilesReceived" 
	'Total number of files received by the web service (counted after service startup).
		Check_Value(objItem.TotalFilesReceived)
    case "TotalFilesSent" 
	'Total number of files sent by the web service (counted after service startup).
		Check_Value(objItem.TotalFilesSent)
    case "TotalFilesTransferred" 
	'Sum of FilesSentPerSec and FilesReceivedPerSec. This is the total number of files transferred by the web service (counted after service startup).
		Check_Value(objItem.TotalFilesTransferred)
    case "TotalGetRequests" 
	'Number of HTTP requests using the GET method (counted after service startup). GET requests are generally used for basic file retrievals or image maps, though they can be used with forms.
		Check_Value(objItem.TotalGetRequests)
    case "TotalHeadRequests" 
	'Number of HTTP requests using the HEAD method (counted after service startup). HEAD requests generally indicate that a client is querying the state of a document they already have to see if it must be refreshed.
		Check_Value(objItem.TotalHeadRequests)
    case "TotalISAPIExtensionRequests" 
	'Total number of ISAPI extension requests after service startup. ISAPI extensions are custom gateway dynamic link libraries (DLLs) that the administrator can install to add forms processing or other dynamic data sources. Unlike CGI requests, ISAPI requests are simple calls to a DLL routine; thus they are better suited to high performance gateway applications. The count is the total since service startup.
		Check_Value(objItem.TotalISAPIExtensionRequests)
    case "TotalLockedErrors" 
	'Number of requests that could not be satisfied by the server because the requested file was locked. These are generally reported as an HTTP 423 error code to the client. The count is the total after service startup.
		Check_Value(objItem.TotalLockedErrors)
    case "TotalLockRequests" 
	'Number of HTTP requests using the LOCK method (counted after service startup). LOCK requests are used to lock a file for one user so that only that user can modify the file.
		Check_Value(objItem.TotalLockRequests)
    case "TotalLogonAttempts"
	'Number of logons that have been attempted using the web service (counted after service startup).
		Check_Value(objItem.TotalLogonAttempts)
    case "TotalMethodRequests"
	'Rate at which all HTTP requests are made.
		Check_Value(objItem.TotalMethodRequests)
    case "TotalMethodRequestsPersec" 
	'Rate at which all HTTP requests are made per second.
		Check_Value(objItem.TotalMethodRequestsPersec)
    case "TotalMkcolRequests" 
	'Number of HTTP requests using the MKCOL method (counted after service startup). MKCOL requests are used to create directories on the server.
		Check_Value(objItem.TotalMkcolRequests)
    case "TotalMoveRequests" 
	'Number of HTTP requests using the MOVE method (counted after service startup). MOVE requests are used for moving files and directories.
		Check_Value(objItem.TotalMoveRequests)
    case "TotalNonAnonymousUsers" 
	'Total number of users who established a non-anonymous connection with the web service (counted after service startup).
		Check_Value(objItem.TotalNonAnonymousUsers)
    case "TotalNotFoundErrors" 
	'Number of requests that could not be satisfied by the server because the requested document could not be found. These are generally reported as an HTTP 404 error code to the client. The count is the total after service startup.
		Check_Value(objItem.TotalNotFoundErrors)
    case "TotalOptionsRequests" 
	'Number of HTTP requests using the OPTIONS method (counted after service startup).
		Check_Value(objItem.TotalOptionsRequests)
    case "TotalOtherRequestMethods" 
	'Number of HTTP requests that are not OPTIONS, GET, HEAD, POST, PUT, DELETE, TRACE, MOVE, COPY, MKCOL, PROPFIND, PROPPATCH, MS-SEARCH, LOCK or UNLOCK methods (counted after service startup). These may include LINK or other methods supported by gateway applications.
		Check_Value(objItem.TotalOtherRequestMethods)
    case "TotalPostRequests"
	'Number of HTTP requests using the POST method (counted after service startup). POST requests are generally used for forms or gateway requests.
		Check_Value(objItem.TotalPostRequests)
    case "TotalPropfindRequests" 
	'Number of HTTP requests using the PROPFIND method (counted after service startup). PROPFIND requests retrieve property values on files and directories.
		Check_Value(objItem.TotalPropfindRequests)
    case "TotalProppatchRequests" 
	'Number of HTTP requests using the PROPPATCH method (counted after service startup). PROPPATCH requests set property values on files and directories.
		Check_Value(objItem.TotalProppatchRequests)
    case "TotalPutRequests" 
	'Number of HTTP requests using the PUT method (counted after service startup).
		Check_Value(objItem.TotalPutRequests)
    case "TotalRejectedAsyncIPerORequests" 
	'Total requests rejected due to bandwidth throttling settings (counted after service startup).
		Check_Value(objItem.TotalRejectedAsyncIPerORequests)
    case "TotalSearchRequests" 
	'Number of HTTP requests using the MS-SEARCH method (counted after service startup). MS-SEARCH requests are used to query the server to find resources that match a set of client-provided conditions.
		Check_Value(objItem.TotalSearchRequests)
    case "TotalTraceRequests" 
	'Number of HTTP requests using the TRACE method (counted after service startup). TRACE requests allow the client to see what is being received at the end of the request chain and use the information for diagnostic purposes.
		Check_Value(objItem.TotalTraceRequests)
    case "TotalUnlockRequests" 
	'Number of HTTP requests using the UNLOCK method (counted after service startup). UNLOCK requests are used to remove locks from files.
		Check_Value(objItem.TotalUnlockRequests)
    case "TraceRequestsPersec" 
	'ate at which HTTP requests using the TRACE method are made. TRACE requests allow the client to see what is being received at the end of the request chain and use the information for diagnostic purposes.
		Check_Value(objItem.TraceRequestsPersec)
    case "UnlockRequestsPersec" 
	'Rate at which HTTP requests using the UNLOCK method are made. UNLOCK requests are used to remove locks from files.
		Check_Value(objItem.UnlockRequestsPersec)
	End Select
Next

