#!/usr/bin/env python
#_*_ coding:utf-8 _*_
'''
Created on 2017年4月18日

@author: Alex
'''
try:
    import sys
    import pymssql,optparse
except Exception,e:
    print e
    sys.exit(3)
optp = optparse.OptionParser()
optp.add_option('-H', help=u'SQL数据库地址或FQDN', dest='host',metavar='10.0.0.1')
optp.add_option('-u', help=u'数据库访问用户名', default='sa',dest='user', metavar='sa')
optp.add_option('-p', help=u'数据库用户密码',default='sa123', dest='passwd', metavar='sa123')
optp.add_option('-P', help=u'数据库连接端口', default=1433,dest='port', metavar='1433')
optp.add_option('-j', help=u'指定监控的JOB名，ALL监控所有JOB，GET获取所有的JOB名，默认为ALL', default='ALL',dest='jobname', metavar='SQL-JOB-name')
optp.add_option('-e', help=u'排除包含指定的名称的JOB,多个JOB使用|分离,Test|Demo', dest='exclude', metavar='Test|Demo')
opts, args = optp.parse_args()
if opts.host is None:
    print "You must specify the SQL instance IP address or FQDN"
    optp.print_help()
    sys.exit(3)

class Mssql_Job_Check:
    
    def __init__(self,dic={}):
        self.dict=dic
        self.STATUS_OK=0
        self.STATUS_Warning=1
        self.STATUS_Critical=2
        self.STATUS_Unknown=3
        self.pref_ok = " | job=0;1;2;0;2"
        self.pref_warn = " | job=1;1;2;0;2"
        self.pref_crit = " | job=2;1;2;0;2"
        try:
            self.exclude_list=[str(x) for x in self.dict['exclude'].split('|')]
        except AttributeError:
            pass  
    def __GetConnect(self):
        """
                            得到连接信息
                            返回: conn.cursor()
        """
        if not self.dict['db']:
            raise(NameError,"No database information is set")
        try:
            self.conn = pymssql.connect(host=self.dict['host'],user=self.dict['user'],password=self.dict['pwd'],database=self.dict['db'],charset="utf8",port=self.dict['port'])
            cur = self.conn.cursor()
        except Exception,e:
            print "Failed to connect to database,Please check connection information"
            sys.exit(self.STATUS_Unknown)
        if not cur:
            raise(NameError,"Failed to connect to database")
        else:
            return cur
        
    def ExecQuery(self,sql):
        """
                        执行查询语句
                        返回的是一个包含tuple的list，list的元素是记录行，tuple的元素是每行记录的字段         
                        调用示例：
        ms = MSSQL(host="localhost",user="sa",pwd="123456",db="PythonWeiboStatistics")
        resList = ms.ExecQuery("SELECT id,NickName FROM WeiBoUser")
        for (id,NickName) in resList:
            print str(id),NickName
        """
        cur = self.__GetConnect()
        cur.execute(sql)
        resList = cur.fetchall()
        self.conn.close()
        return resList  
    
    def ExecNonQuery(self,sql):
        """
                        执行非查询语句
                
                        调用示例：
        cur = self.__GetConnect()
        cur.execute(sql)
        self.conn.commit()
        self.conn.close()
        """
        cur = self.__GetConnect()
        cur.execute(sql)
        self.conn.commit()
        self.conn.close()
        
    def GetJobName(self):
        rows=self.ExecQuery("select name from sysjobs where enabled =1")
        return_str=[]
        for row in rows:
            return_str.append("JonName:%s"%row[0])
        
        return  self.STATUS_OK,'\r\n'.join(return_str)
    
    def CheckJobName(self):
        self.rows=self.ExecQuery('exec sp_help_job')
        self.jobrows()
        if self.dict['job'] == 'ALL':
            status_temp=self.STATUS_OK
            messages=[]
            for index in self.row_dict:
                
                if not self.dict['exclude']  is None:
                    if self.Exclude(index):
                        continue
                self.dict['job']=index
                (rcode,message)=self.Check_Status(self.row_dict[index])
                if rcode ==self.STATUS_Critical:
                    status_temp=self.STATUS_Critical
                elif rcode ==self.STATUS_Warning and status_temp <> self.STATUS_Critical:
                    status_temp=self.STATUS_Warning
                messages.append(message)    
            
            if status_temp ==self.STATUS_Critical:
                return self.STATUS_Critical,"%s %s"%('\r\n'.join(messages),self.pref_crit)
            elif status_temp == self.STATUS_Warning:
                return self.STATUS_Warning,"%s %s"%('\r\n'.join(messages),self.pref_warn)
            else:
                return self.STATUS_OK,"%s %s"%('\r\n'.join(messages),self.pref_ok)
        else:
            try:
                job_status=self.row_dict[self.dict['job']]
            except KeyError:
                return self.STATUS_Critical,"Please specify the JOB name correctly and use -j ALL to get the ALL JOB"
            
            (rcode,message)=self.Check_Status(job_status)
            if rcode==self.STATUS_Critical:
                return self.STATUS_Critical,"%s %s" %(message,self.pref_crit)
            elif rcode==self.STATUS_Warning:
                return self.STATUS_Warning,"%s %s" %(message,self.pref_warn)
            else:
                return self.STATUS_OK,"%s %s" %(message,self.pref_ok)
    
    def Exclude(self,jobname):
        for index in self.exclude_list:
            if index in jobname:
                return True
        return False
    
    def Check_Status(self,job_status):
        if job_status ==1:
            if self.checkWarningState() > 0:
                return self.STATUS_Warning,"WARNING : JOB Warning :%s %s "%(self.dict['job'],self.getLastMessage())
            else:
                return self.STATUS_OK,"OK : JOB Succeeded :%s "%(self.dict['job'])
        else:
            return self.STATUS_Critical,"CRITICAL : JOB FAILED :%s %s "%(self.dict['job'],self.getLastMessage())
    
    def jobrows(self):
        self.row_dict={}
        for row in self.rows:
            if row[3] == 0 :
                continue
            self.row_dict[row[2]]=row[21]
            
    def getLastMessage(self):
        sql="""select top 1  sjh.message,sjh.step_name
                from dbo.sysjobhistory sjh inner join dbo.sysjobs sj on sjh.job_id = sj.job_id 
                inner join dbo.sysjobsteps sjs on sj.job_id = sjs.job_id and sjh.step_id = sjs.step_id 
                where sj.name = '%s' and sjh.run_status = 0
                order by sjh.run_date desc, sjh.run_time desc 
        """%self.dict['job']
        rows=self.ExecQuery(sql)
        if len(rows) <>0:
            return "step: %s : %s"%(rows[0][1],rows[0][0])
        else:
            return "not fount message"
            
    def checkWarningState(self):
        sql="""select count(*) as ile from msdb.dbo.sysjobhistory sjh inner join msdb.dbo.sysjobs sj on sjh.job_id = sj.job_id
            inner join msdb.dbo.sysjobsteps sjs on sj.job_id = sjs.job_id and sjh.step_id = sjs.step_id
             where sjh.run_status = 0 and sjs.last_run_outcome = 0 and sj.name = '%s' 
             and step_uid not in (
            select step_uid from msdb.dbo.sysjobhistory a
            join msdb.dbo.sysjobs b on a.job_id = b.job_id
            inner join msdb.dbo.sysjobsteps c on b.job_id = a.job_id and a.step_id = c.step_id where sj.job_id = a.job_id and c.last_run_date >= sjs.last_run_date 
            and c.[last_run_outcome] = 1 and c.last_run_time > sjs.last_run_time
             )"""%(self.dict['job'])
        rows=self.ExecQuery(sql)
        return rows[0][0]   
    
if __name__ == '__main__':
    dic={}
    dic['host']=opts.host
    dic['user']=opts.user
    dic['pwd']=opts.passwd
    dic['port']=opts.port
    dic['db']='msdb'
    dic['job']=opts.jobname 
    dic['exclude']=opts.exclude
    msql=Mssql_Job_Check(dic)
    if opts.jobname == 'GET' :
        (rcode,message)=msql.GetJobName()
    else:
        (rcode,message)=msql.CheckJobName()    

    print message
    sys.exit(rcode)