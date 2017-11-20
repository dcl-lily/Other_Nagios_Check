'  检查系统启动时间
'  
'
'
on error Resume Next
dim time_now,uptime,dateif
Set Args = WScript.Arguments
If Args.Count < 1  Then
	call help()
End If
Timediff = Args(0)
if Args.Count = 2 then
	TimeCompar = Args(1)
end if

const STATUS_OK=0
const STATUS_WARNING=1
const STATUS_Critical=2
const STATUS_Unknown=3

function help()
	WScript.Echo "检查windos启动时间差"
	Wscript.Echo ""
	Wscript.Echo "参数:"
	Wscript.Echo " 参数一输入一个小时数"
	Wscript.Echo " 参数二输入gt或者输入lt，默认lt"
	Wscript.Echo ""
	Wscript.Echo "例如:"
	Wscript.Echo "system_update.vbs 10 gt"
	Wscript.Quit(STATUS_Unknown)
end function
 
Set objWMIService = GetObject("winmgmts:\\.\root\CIMV2") 
Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_OperatingSystem",,48) 
For Each objItem in colItems 
    a =	objItem.LastBootUpTime 	
Next

time_now = CStr(Year(Now()))&"-"&Right("0"&Month(Now()),2)&"-"&Right("0"&Day(Now()),2)&" "&Right("0" & Hour(Now()),2)&":"&Right("0"&Minute(Now()),2)
uptime = Mid(a,1,4)&"-"&Mid(a,5,2)&"-"&Mid(a,7,2)&" "&Mid(a,9,2)&":"&Mid(a,11,2)

if isnumeric(Timediff) then
	dateif =datediff("h",uptime,time_now) 
	if TimeCompar = "gt" then			
		if	int(Timediff) >= int(dateif) then
				Return_Code = STATUS_Critical
				status = "Critical-System startup time "&uptime 
			else 
				Return_Code = STATUS_OK
				status =  "OK-System startup time "&uptime 
			end if
	else
		if	int(Timediff) <= int(dateif)  then
				Return_Code = STATUS_Critical
				status = "Critical-System startup time "&uptime	 			
			else
				Return_Code = STATUS_OK
				status =  "OK-System startup time "&uptime	
			end if
	end if	
else 
	WScript.Echo "Please enter the correct time difference"
	WScript.Echo "-----------"
	call help()
end if	
Wscript.Echo status & "|Start_time_diff="& dateif & ";;"& Timediff & ";0;"	
Wscript.Quit(Return_Code)
