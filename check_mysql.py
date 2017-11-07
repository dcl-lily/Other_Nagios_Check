#!/usr/bin/env python
# _*_ coding:utf-8 _*_
'''
  mysql  check

'''
import getopt,sys
global Mysql_Host,Mysql_Port,Mysql_User,Mysql_Pwd,Warning_Value,Critical_Value,Compare_Value,Check_Option
Mysql_Host=None
Mysql_Port=3306
Mysql_User=None
Mysql_Pwd=None
Warning_Value=''
Critical_Value=''
Compare_Value='lt'
Check_Option='Up_Time'

def Usage():
    print 'check_mysql.py     Mysql数据库监控脚本'
    print '-H, --Host: 指定Mysql数据库地址[IP add / Hostname]，必选项'
    print '-P, --Port: 数据库的端口,默认为3306'
    print '-u,--user:链接数据库的用户名，必须项'
    print '-p,--password:链接数据库用户名的密码，必须项'
    print '-o,--option:需要监控的选项，默认为Up_Time '
    print '-w,--warning: 警告阈值,可选项'
    print '-c,--critical: 严重阈值，可选项'
    print '-C,--Compare:告警比较算法，默认是lt小于[lt,gt]'
    print '-h,--help: 查看帮助信息.'
    print '-v, --version: 查看版本信息'
    print './check_mysql.py -H 127.0.0.1 -u mysqluser -p mysqlpassword -o Max_Used_Connections -w 80 -c 90 C gt'

def Version():
    print 'Check_mysql.py 1.0.0.0.1'
    print '关于每个监控值得含义，请去青鸟技术联盟进行查看'
    print ' http://bbs.qnjslm.com'
    print  '目前版本只能监控mysql5.7 以下的版本。5.7以后的后期再增加'
    print './check_mysql.py -H 127.0.0.1 -u mysqluser -p mysqlpassword -o Max_Used_Connections -w 80 -c 90 C gt'

def Get_Check_Option(argv):
    try:
        opts, args = getopt.getopt(argv[1:], 'H:P:u:p:o:w:c:C:hv', ['Host=','Port=', 'user=', 'password=', 'option=', 'warning=', 'critical=', 'Compare=','version','help'])
    except getopt.GetoptError, err:
        print str(err)
        Usage()
        sys.exit(3)
    global Mysql_Host,Mysql_Port,Mysql_User,Mysql_Pwd,Warning_Value,Critical_Value,Compare_Value,Check_Option

    for o, a in opts:
        if o in ('-h', '--help'):
            Usage()
            sys.exit(0)
        elif o in ('-v', '--version'):
            Version()
            sys.exit(0)
        elif o in ('-H', '--Host'):
            Mysql_Host=a
        elif o in ('-P', '--Port'):
            Mysql_Port=a
        elif o in ('-u', '--user'):
            Mysql_User=a
        elif o in ('-p', '--password'):
            Mysql_Pwd=a
        elif o in ('-o', '--option'):
            Check_Option=a
        elif o in ('-w', '--warning'):
            Warning_Value=a
        elif o in ('-c', '--critical'):
            Critical_Value=a
        elif o in ('-C', '--Compare'):
            Compare_Value=a

def nagios_mysql_que(sql):
    '''
    :param sql:
    :return:
    执行SQl语句并返回结果
    '''
    try:
        INFORMATION_SCHEMA_CURSOR.execute(sql)
        return INFORMATION_SCHEMA_CURSOR.fetchone()
    except Exception:
        return 0

def global_status_sql(attribute):
    """
    attribute:  global_status 表中的列名
    :return:
    """
    sql="SELECT VARIABLE_VALUE FROM global_status WHERE VARIABLE_NAME = '%s'"%(attribute)
    return sql


def Retun_Nagios_Format(status,option,value,warning='',critical=''):
    """
    :param status: 状态
    :param describe: 描述显示
    :param value: 值
    :param warning: 警告值
    :param critical: 严重值
    :return: str nagios format
    """
    str="%s - %s:%s|%s=%s;%s;%s"%(status,option,value,option,value,warning,critical)
    return str

def Value_Compare(Value,warning='',critical='',compare='lt'):
    """    告警返回出来
    :param Value: 需要处理的值
    :param warning:  警告值
    :param critical:  严重值
    :param Compare:  大于还是小于 lt & gt
    :return:
    """
    global Warning_Value,Critical_Value
    if not compare=='lt' or compare=='gt':
        compare=='lt'

    try:
        criticalisok= True if critical<>'' and int(eval(critical)) else False
    except Exception:
        criticalisok=False
        Critical_Value=''

    try:
        warningisOK= True if warning<>'' and int(eval(warning)) else False
    except Exception:
        warningisOK=False
        Warning_Value=''

    if  compare=='lt':
        if criticalisok:
            if (float(Value) < float(critical)):
                return 2

        elif  warningisOK:
            if (float(Value) < float(warning)):
                return 1
    else:
        if criticalisok:
             if (float(Value) > float(critical)):
                return 2
        elif  warningisOK:
            if (float(Value) > float(warning)):
                return 1
    if not warningisOK and not criticalisok:
        print "警告阈值设置不正常"
        return 3
    return 0


#Total Memory Used (MB)
Total_Memory_Used ="""SELECT (
	SUM(VARIABLE_VALUE) *
	(SELECT VARIABLE_VALUE FROM session_variables WHERE VARIABLE_NAME = 'MAX_CONNECTIONS') +
	(SELECT VARIABLE_VALUE FROM session_variables WHERE VARIABLE_NAME = 'KEY_BUFFER_SIZE')
)/1024/1024
FROM session_variables
WHERE VARIABLE_NAME IN ('READ_BUFFER_SIZE', 'SORT_BUFFER_SIZE')"""

#Kilobytes Received
Kilobytes_Received=global_status_sql('BYTES_RECEIVED')

#Kilobytes Sent
Kilobytes_Sent=global_status_sql('BYTES_SENT')

#Created Temporary Disk Tables
Created_Temporary_Disk_Tables=global_status_sql('CREATED_TMP_DISK_TABLES')

#Created Temporary Files
Created_Temporary_Files=global_status_sql('CREATED_TMP_FILES')
#Created Temporary Tables
Created_Temporary_Tables=global_status_sql('CREATED_TMP_TABLES')

#Opened Table Definitions
Opened_Table_Definitions=global_status_sql('OPENED_TABLE_DEFINITIONS')

#Opened Tables
Opened_Tables=global_status_sql('OPENED_TABLES')

#Opened Files
Opened_Files=global_status_sql('OPENED_FILES')

#Statements Executed
Statements_Executed=global_status_sql('QUESTIONS')

#Key Reads
Key_Reads=global_status_sql('KEY_READS')

#Key Writes
Key_Writes=global_status_sql('KEY_WRITES')

#Table Locks Immediate
Table_Locks_Immediate=global_status_sql('TABLE_LOCKS_IMMEDIATE')

#Table Locks Waited
Table_Locks_Waited=global_status_sql('TABLE_LOCKS_WAITED')

#Threads Cached
Threads_Cached=global_status_sql('THREADS_CACHED')

#Threads Connected
Threads_Connected=global_status_sql('THREADS_CONNECTED')

#Threads Created
Threads_Created=global_status_sql('THREADS_CREATED')

#Threads Running
Threads_Running=global_status_sql('THREADS_RUNNING')

#Up Time
Up_Time=global_status_sql('UPTIME')

#Transactions that use disk
Transactions_that_use_disk=global_status_sql('BINLOG_CACHE_DISK_USE')

#Transactions that use cache
Transactions_that_use_cache=global_status_sql('BINLOG_CACHE_USE')

#Joins that perform table scans
Joins_that_perform_table_scans=global_status_sql('SELECT_FULL_JOIN')

#Joins that check for key usage
Joins_that_check_for_key_usage=global_status_sql('SELECT_RANGE_CHECK')

#Joins that perform full scan
Joins_that_perform_full_scan=global_status_sql('SELECT_SCAN')

#Slow Queries
Slow_Queries=global_status_sql('SLOW_QUERIES')

#Max Used Connections
Max_Used_Connections=global_status_sql('MAX_USED_CONNECTIONS')

#Free Memory in Query Cache (MB)
Free_Memory_Query_Cache=global_status_sql('QCACHE_FREE_MEMORY')

#Queries Registered in Query Cache
Queries_Registered_Query_Cache=global_status_sql('QCACHE_QUERIES_IN_CACHE')

#Deleted Queries from Cache
Deleted_Queries_Cache=global_status_sql('QCACHE_LOWMEM_PRUNES')

#Opened Connections
Opened_Connections="select count(*) from processlist"

#Aborted Connections
Aborted_Connections=global_status_sql('ABORTED_CONNECTS')

#Aborted Clients
Aborted_Clients=global_status_sql('ABORTED_CLIENTS')

#Thread Cache Size
Thread_Cache_Size='select variable_value from global_variables where variable_name = "thread_cache_size"'

#Slow Launch Threads
Slow_Launch_Threads=global_status_sql('SLOW_LAUNCH_THREADS')

#Sort Scan
Sort_Scan=global_status_sql('SORT_SCAN')

#Sort Rows
Sort_Rows=global_status_sql('SORT_ROWS')

#Queries
Queries=global_status_sql('QUERIES')

#Key Read Efficiency
Key_Read_Efficiency='''
select
(1-
(select variable_value from global_status where variable_name = "KEY_READS")/
(select variable_value from global_status where variable_name = "KEY_READ_REQUESTS")
)*100 "Key Read Efficiency"
'''

#Key Write Efficiency
Key_Write_Efficiency='''
select  if((select variable_value from global_status where variable_name = "KEY_WRITES")
/(select variable_value from global_status where variable_name = "KEY_WRITE_REQUESTS") is null, 100,
(((select variable_value from global_status where variable_name = "KEY_WRITES")
/(select variable_value from global_status where variable_name = "KEY_WRITE_REQUESTS"))*100 )) as "Key Write Efficiency"
'''
#Key Buffer Size
Key_Buffer_Size='select variable_value from global_variables where variable_name = "key_buffer_size"'

Monitor_Object=['Total_Memory_Used','Kilobytes_Received','Kilobytes_Sent','Created_Temporary_Disk_Tables',
'Created_Temporary_Files','Created_Temporary_Tables','Opened_Table_Definitions',
'Opened_Tables','Opened_Files','Statements_Executed','Key_Reads','Key_Writes',
'Table_Locks_Immediate','Table_Locks_Waited','Threads_Cached','Threads_Connected',
'Threads_Created','Threads_Running','Up_Time','Transactions_that_use_disk',
'Transactions_that_use_cache','Joins_that_perform_table_scans','Joins_that_check_for_key_usage',
'Joins_that_perform_full_scan','Slow_Queries','Max_Used_Connections','Free_Memory_Query_Cache',
'Queries_Registered_Query_Cache','Deleted_Queries_Cache','Opened_Connections',
'Aborted_Connections','Aborted_Clients','Thread_Cache_Size','Slow_Launch_Threads',
'Sort_Scan','Sort_Rows','Queries','Key_Read_Efficiency','Key_Write_Efficiency',
'Key_Buffer_Size']

if __name__ == '__main__':
    Get_Check_Option(sys.argv)
    nagios_status_description=['OK','Warning','Critical','UNKNOWN']
    #================================参数check Mysql==================================================
    #check 基本链接信息
    if Mysql_Host is None or Mysql_User is None or Mysql_Pwd is None:
        print "=====错误======"
        print "缺少必要的参数"
        Usage()
        print "=====错误======"
        sys.exit(3)
    #check Port
    if not isinstance(Mysql_Port,int):
        print "Mysql 链接端口填写错误，应该是纯数字的哦"
        sys.exit(3)
    #===================================程序开始部分=============================================
    try:
        import MySQLdb
    except Exception:
        print "请安装pythonmysql插件  pip install MySQLdb"
        sys.exit(3)
    #===============================Mysql链接===================================================
    try:
        INFORMATION_SCHEMA_CONN=MySQLdb.connect(host=Mysql_Host,user=Mysql_User,passwd=Mysql_Pwd,port=Mysql_Port,db="INFORMATION_SCHEMA",charset="utf8")
        INFORMATION_SCHEMA_CURSOR = INFORMATION_SCHEMA_CONN.cursor()
    except Exception:
        print "数据库连接失败"
        sys.exit(3)


    if Check_Option not in Monitor_Object:
        print "Critical-监控指标参数不正确,正确指标如下"
        print Monitor_Object
        sys.exit(3)
    else:

        Results_Value=nagios_mysql_que(eval(Check_Option))[0]
        if Results_Value ==0:
            print "Critica l- Mysql 语句执行失败，如问题持续，请检查版本，以及用户授权信息"
            sys.exit(3)


        Result_Status_Value=Value_Compare(Results_Value,Warning_Value,Critical_Value,Compare_Value) if Warning_Value<>''  or Critical_Value<>'' else 0

        Results_Retun_Value=Retun_Nagios_Format(nagios_status_description[Result_Status_Value],Check_Option,Results_Value,Warning_Value,Critical_Value)

    INFORMATION_SCHEMA_CURSOR.close()
    INFORMATION_SCHEMA_CONN.close()

    print   Results_Retun_Value
    sys.exit(Result_Status_Value)
