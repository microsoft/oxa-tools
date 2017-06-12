import MySQLdb
import collections
import os
import re
from datetime import datetime,timedelta


def CreateYearMonthDay():
    db = MySQLdb.connect(IP,User,Password,Database)
    cursor = db.cursor()

    sql = "SELECT YEAR(date_joined), MONTH(date_joined), DAY(date_joined), COUNT(*) FROM edxapp.auth_user \
          GROUP BY DATE(date_joined) \
          ORDER BY DATE(date_joined)"

    cursor.execute(sql)
    results = cursor.fetchall()
    
    for row in results:
        y = str(row[0])
        m = str(row[1])
        d = str(row[2])
        sql2 = "SELECT id FROM oxa.oxa_activationsummary WHERE xyear="+y+" and xmonth="+m+" and xday="+d
        cursor.execute(sql2)
        if cursor.rowcount < 1: 
            sql3 = "INSERT INTO oxa.oxa_activationsummary (xyear, xmonth, xday) \
                   VALUES ("+y+","+m+","+d+")"
            cursor.execute(sql3) 

    db.commit()
    cursor.close()
    db.close()


def UpdateAccountsCreated():
    db = MySQLdb.connect(IP,User,Password,Database)
    cursor = db.cursor()

    sql = "SELECT YEAR(date_joined), MONTH(date_joined), DAY(date_joined), COUNT(*) FROM edxapp.auth_user \
          GROUP BY DATE(date_joined) \
          ORDER BY DATE(date_joined)"

    cursor.execute(sql)
    results = cursor.fetchall()

    for row in results:
        y = str(row[0])
        m = str(row[1])
        d = str(row[2])
        c = str(row[3])
        sql2 = "UPDATE oxa.oxa_activationsummary SET newaccount="+c+" \
               WHERE xyear="+y+" and xmonth="+m+" and xday="+d
             
        cursor.execute(sql2)

    db.commit()
    cursor.close()
    db.close()

def UpdateAccountsActivated():
    db = MySQLdb.connect(IP,User,Password,Database)
    cursor = db.cursor()

    sql = "SELECT YEAR(date_joined), MONTH(date_joined), DAY(date_joined), COUNT(*) FROM edxapp.auth_user \
          WHERE is_active=1 \
          GROUP BY DATE(date_joined) \
          ORDER BY DATE(date_joined)"

    cursor.execute(sql)
    results = cursor.fetchall()

    for row in results:
        y = str(row[0])
        m = str(row[1])
        d = str(row[2])
        c = str(row[3])
        sql2 = "UPDATE oxa.oxa_activationsummary SET activated="+c+" \
               WHERE xyear="+y+" and xmonth="+m+" and xday="+d

        cursor.execute(sql2)

    db.commit()
    cursor.close()
    db.close()

def UpdateAccountsNotActivated():
    db = MySQLdb.connect(IP,User,Password,Database)
    cursor = db.cursor()

    sql = "SELECT YEAR(date_joined), MONTH(date_joined), DAY(date_joined), COUNT(*) FROM edxapp.auth_user \
          WHERE is_active=0 \
          GROUP BY DATE(date_joined) \
          ORDER BY DATE(date_joined)"

    cursor.execute(sql)
    results = cursor.fetchall()

    for row in results:
        y = str(row[0])
        m = str(row[1])
        d = str(row[2])
        c = str(row[3])
        sql2 = "UPDATE oxa.oxa_activationsummary SET notactivated="+c+" \
               WHERE xyear="+y+" and xmonth="+m+" and xday="+d

        cursor.execute(sql2)

    db.commit()
    cursor.close()
    db.close()

def ProcessErrorLine( cursor, line ):
    
    m = re.search('/tmp/oxa_log_files/(.+?)/.+:([0-9]{4}?)-([0-9]{2}?)-([0-9]{2}?)\s([0-9]{2}?):([0-9]{2}?):([0-9]{2}?),.+to\s"(.+?)"',line)
    if m:
        ip = m.group(1)
        y = m.group(2)
        mo = m.group(3)
        d = m.group(4)
        h = m.group(5)
        mi = m.group(6)
        s = m.group(7)        
        dt_obj = datetime(int(y),int(mo),int(d),int(h),int(mi),int(s))       
        email = m.group(8)
                
        cursor.execute("SELECT id from oxa.oxa_activationfailed where email='"+email+"'")
        if cursor.rowcount <= 0: 
            cursor.execute("SELECT id,date_joined from edxapp.auth_user WHERE email='"+email+"'")
            user_id = 0
            date_joined = dt_obj + timedelta(hours=7)
            date_failed = date_joined
            activation_key = "Not Found!!!"
            if cursor.rowcount > 0:
                result = cursor.fetchall()         
                user_id = result[0][0]
                date_joined = result[0][1] 
                cursor.execute("SELECT activation_key FROM edxapp.auth_registration WHERE user_id="+str(user_id)) 
                if cursor.rowcount > 0:
                    result = cursor.fetchall()
                    activation_key = result[0][0]
                
            cursor.execute("INSERT INTO oxa.oxa_activationfailed (xyear,xmonth,xday,user_id,email,activation_key,date_joined,date_failed,hostvmip) VALUES("+y+","+mo+","+d+","+str(user_id)+",'"+email+"','"+activation_key+"','"+str(date_joined)+"','"+str(date_failed)+"','"+ip+"')")
            cursor.execute("UPDATE oxa.oxa_activationsummary SET failed=failed+1 WHERE  xyear="+y+" and xmonth="+mo+" and xday="+d)    
             
        

    

def FetchAndGrepLogFiles():
    os.system('rm -fr /tmp/oxa_log_files')
    os.system('mkdir /tmp/oxa_log_files')

    vms = ('10.0.0.','10.0.0.','10.0.0.','10.0.0.','10.0.0.')
    for ip in vms:
        os.system('mkdir /tmp/oxa_log_files/'+ip)    
        os.system('scp '+ip+':/edx/var/log/supervisor/*default* /tmp/oxa_log_files/'+ip+'/')

    os.system("grep 'Unable to send activation email' /tmp/oxa_log_files/*/* > /tmp/oxa_log_files/notsentemails.txt")
    db = MySQLdb.connect(IP,User,Password,Database)
    cursor = db.cursor()
    with open('/tmp/oxa_log_files/notsentemails.txt') as f:
        for line in f:
            ProcessErrorLine(cursor,line)

    db.commit()
    cursor.close() 
    db.close()

    
os.system("echo "+str(datetime.now())+" Started running process >> /oxa/oxa_mail_monitor.log")
CreateYearMonthDay()
UpdateAccountsCreated()
UpdateAccountsActivated()
UpdateAccountsNotActivated()
FetchAndGrepLogFiles()
os.system("echo "+str(datetime.now())+" Finished running process >> /oxa/oxa_mail_monitor.log")

print "Done"

