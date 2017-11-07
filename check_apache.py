#!/usr/bin/env python
# _*_ coding:utf-8 _*_

import getopt,sys,urllib
global Apache_Host,Apache_Port,Warning_Value,Critical_Value,Compare_Value,Check_Option
Apache_Host=''
Apache_Port='80'
Compare_Value='lt'
Check_Option='Uptime'
Warning_Value=''
Critical_Value=''

def Usage():
    print 'check_apache.py     Apache状态检查'
    print '-H, --Host: 指定指定Apache状态页面地址[IP add / FQDN]，必选项'
    print '-P, --Port: Apache状态页面端口,默认为80'
    #print '-u,--user:链接数据库的用户名，必须项'
    #print '-p,--password:链接数据库用户名的密码，必须项'
    print '-o,--option:需要监控的选项，默认为Uptime'
    print '-w,--warning: 警告阈值,可选项'
    print '-c,--critical: 严重阈值，可选项'
    print '-C,--Compare:告警比较算法，默认是lt小于[lt,gt]'
    print '-h,--help: 查看帮助信息.'
    print '-v, --version: 查看版本信息'
    print './check_apache.py -H 127.0.0.1 -o IdleWorkers -w 80 -c 90 C gt'

def Version():
    print 'Check_apache.py 1.0.0.0.1'
    print '关于每个监控值得含义，请去青鸟技术联盟进行查看'
    print ' http://bbs.qnjslm.com'
    print  '目前不支持账号密码认证,不支持Https访问'
    print './check_apache.py -H 127.0.0.1 -o IdleWorkers -w 80 -c 90 C gt'

def Get_Check_Option(argv):
    try:
        opts, args = getopt.getopt(argv[1:], 'H:P:o:w:c:C:hv', ['Host=','Port=',  'option=', 'warning=', 'critical=', 'Compare=','version','help'])
    except getopt.GetoptError, err:
        print str(err)
        Usage()
        sys.exit(3)
    global Apache_Host,Apache_Port,Warning_Value,Critical_Value,Compare_Value,Check_Option
    for o, a in opts:
        if o in ('-h', '--help'):
            Usage()
            sys.exit(0)
        elif o in ('-v', '--version'):
            Version()
            sys.exit(0)
        elif o in ('-H', '--Host'):
            Apache_Host=a
        elif o in ('-P', '--Port'):
            Apache_Port=a
        elif o in ('-o', '--option'):
            Check_Option=a
        elif o in ('-w', '--warning'):
            Warning_Value=a
        elif o in ('-c', '--critical'):
            Critical_Value=a
        elif o in ('-C', '--Compare'):
            Compare_Value=a

#匹配相关值
def Get_Value(WebContent,MatchingValue):
    if MatchingValue=='TotalAccess':
        MatchingValue='Total Accesses'
    elif MatchingValue=='TotalTraffic':
        MatchingValue='Total kBytes'

    for i in WebContent.split('\n'):
        if MatchingValue in i:
            return i.split(':')[1]
    return 'Nagios_Err'

#获取Apache状态
def Get_WebContent(option):
    url = 'http://%s/server-status?auto&match=www&errors=0'%option
    try:
        wp = urllib.urlopen(url)
        file_content = wp.read()
        return file_content
    except Exception:
        print "状态链接页面获取失败"
        sys.exit(3)

def Uptime(Results):
    global Apache_Host
    hour=int(Results)/3600
    min=(int(Results) - hour * 3600)/60
    sec=(int(Results)-hour*3600-min*60)
    return "Server UP:%sh %sm %ss.on Host %s"%(hour,min,sec,Apache_Host)

def IdleWorkers(Results):
    global Apache_Host
    return  "Server Idele Workers: %s on %s"%(Results,Apache_Host)

def TotalAccess(Results):
    global Apache_Host
    return "Server Total Access:%s on %s" %(Results,Apache_Host)

def TotalTraffic(Results):
    global Apache_Host
    return "Server Total kBytes:%s kb on %s"%(Results,Apache_Host)

def ReqPerSec(Results):
    global Apache_Host
    return 'Server Request Per Second : %s on %s'%(float(Results),Apache_Host)

def BytesPerSec(Results):
    global Apache_Host
    return "Server Kbytes PerSec:%s on %s"%(Results,Apache_Host)
def BytesPerReq(Results):
    global Apache_Host
    return "Server Kbytes Per Request:%s on %s"%(Results,Apache_Host)

def BusyWorkers(Results):
    global Apache_Host
    return "Server Busy Workers:%s on %s"%(Results,Apache_Host)

#格式化为Nagios数据
def Retun_Nagios_Format(status,option,value,warning='',critical=''):
    """
    :param status: 状态
    :param describe: 描述显示
    :param value: 值
    :param warning: 警告值
    :param critical: 严重值
    :return: str nagios format
    """
    global Check_Option
    str="%s - %s|%s=%s;%s;%s"%(status,option,Check_Option,value,warning,critical)
    return str

#f阈值判断
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


if __name__ == '__main__':
    Get_Check_Option(sys.argv)
    nagios_status_description=['OK','Warning','Critical','UNKNOWN']
    Monitor_Object=['Uptime','IdleWorkers','TotalAccess','TotalTraffic','ReqPerSec','BytesPerSec','BytesPerReq','BusyWorkers']
    if Apache_Host =='':
        print "没有指定主机信息：请使用 -H 指定Apache主机 -H bbs.qnjslm.com 或者 -H 27.54.210.49"
        sys.exit(3)
    if Check_Option not in Monitor_Object:
        print "指定的检查项不存在，请使用-h 查看帮助"
        print Monitor_Object
        sys.exit(3)

    Results_Value=Get_Value(Get_WebContent(Apache_Host),Check_Option).strip() 
    if Results_Value =='Nagios_Err':
        if Check_Option=='IdleWorkers':
            Results_Value=Get_Value(Get_WebContent(Apache_Host),'IdleServers').strip() 
            if Results_Value == 'Nagios_err':
                print "没有获取相关的值"
                sys.exit(3)
        elif Check_Option=='BusyWorkers':
            Results_Value=Get_Value(Get_WebContent(Apache_Host),'BusyServers').strip() 
            if Results_Value == 'Nagios_err':
                print "没有获取相关的值"
                sys.exit(3)
        else:
            print "没有获取相关的值"
            sys.exit(3)


    Result_Status_Value=Value_Compare(Results_Value,Warning_Value,Critical_Value,Compare_Value) if Warning_Value<>''  or Critical_Value<>'' else 0
    print Retun_Nagios_Format(nagios_status_description[Result_Status_Value],eval(Check_Option)(Results_Value),Results_Value,Warning_Value,Critical_Value)
