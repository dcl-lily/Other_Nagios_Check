# Other_Nagios_Check

以下是在Nagios运维中的一些奇葩开发脚本，

##Check_SPN.vbs   检查windos AD中的指定用户下SPN注册状态

使用方法：

    Check_SPN.vbs 用户名 SPN
    
    example：
     
     Check_SPN.vbs sqladmin MSSQLSvc/MySQL.company.com:1433

	 
##check_directory.vbs  检查指定目录的状况
	
	注：脚本的告警阈值，请修改脚本的中的内容(14~15行位置)
	Warning=53964800
	Critical=1073741824
	
	使用方法：
	       
	check_directory.vbs c:\windos
	
	
	
	
##check_uptime.vbs   检查系统启动时间

	使用方法：
	
		check_uptime.vbs 10 gt 如果系统启动时间大于指定小时数告警
		
		check_uptime.vbs 10 lt 如果系统启动时间小于指定小时数告警
		
		
		
##check_microsoft_cluster.vbs   微软群集检查，继承Creation脚本完善

	使用方法：
	
		check_microsoft_cluster.vbs CLRESP  资源状态监控，是否在首选节点
		check_microsoft_cluster.vbs CLRES   也是资源节点监控，不监控是否在首选节点上
		check_microsoft_cluster.vbs	CLNODE  节点状态监控
		
		
##mssql_job_check.py   SQLsERVER数据库JOB执行监控

	使用方法：
	
			mssql_job_check.py -h  自己查看吧写得很详细，注需要pymssql 支持
			

##check_time.vbs  windos时间同步检查


	使用方法：
	
		check_time.vbs -h 查看吧
		
	注意：如果系统是windos2003以上的版本，脚本中需要修改地方为：
	   
	   第30行 ： strCommand = "%SystemRoot%\System32\w32tm.exe /monitor /computers:" & serverlist
	   
	   修改为：  strCommand = "%SystemRoot%\System32\w32tm.exe /monitor /nowarn /computers:" & serverlist
	
##check_apache.py  检查Apache状态

	使用方法：
		
		check_apache.py -H 127.0.0.1 -o IdleWorkers -w 80 -c 90 C gt
	
		check_apache.py -h 其他用法请查看帮助吧
		
	注意：需要python支持,脚本为python2.7下开发，需要apache启用管理
	
	
##check_apache.py  检查Apache状态

	使用方法：
		
		check_mysql.py -H 127.0.0.1 -u mysqluser -p mysqlpassword -o Max_Used_Connections -w 80 -c 90 C gt
	
		check_mysql.py -h 其他用法请查看帮助吧
		
	注意：需要python支持,脚本为python2.7下开发，需要pymysql支持，可使用pip install MySQLdb进行安装，mysql目前只支持5.7以下版本。
	
	    
		