import MySQLdb
import collections
import os
import re
from datetime import datetime,timedelta
from smtplib import SMTP
from email.MIMEMultipart import MIMEMultipart
from email.MIMEText import MIMEText

def OutputMonthlySummary( f ):
    
    db = MySQLdb.connect(IP,User,Password,Database)
    cursor = db.cursor()

    sql = "SELECT xyear, xmonth, SUM(newaccount),SUM(activated),SUM(notactivated),SUM(failed),SUM(resend) FROM oxa.oxa_activationsummary \
          GROUP BY xyear,xmonth \
          ORDER BY xyear,xmonth"

    cursor.execute(sql)
    results = cursor.fetchall()
    f.write("YEAR-MONTH ACTIVATION STATISTICS:\r\n")
    f.write("=================================\r\n") 
    f.write('{:8s} {:6s} {:15s} {:15s} {:15s} {:25s} {:15s}'.format("YEAR","MONTH","NEW ACCOUNTS","ACTIVATED","NOT ACTIVATED","ACTIVATION EMAIL FAILED","RESENT EMAIL")+"\r\n")
    for row in results:
        y = str(row[0])
        m = str(row[1])
        n = str(row[2])
        a = str(row[3])
        na = str(row[4])
        fl = str(row[5])
        rs = str(row[6]) 
        f.write('{:8s} {:6s} {:15s} {:15s} {:15s} {:25s} {:15s}'.format(y,m,n,a,na,fl,rs)+"\r\n")

    f.write("\r\n\r\n")
    cursor.close()
    db.close()


def OutputCurrentMonthSummary( f ):
    db = MySQLdb.connect(IP,User,Password,Database)
    cursor = db.cursor()

    dt = datetime.now()
    
    sql = "SELECT xyear, xmonth, xday, SUM(newaccount),SUM(activated),SUM(notactivated),SUM(failed),SUM(resend) FROM oxa.oxa_activationsummary \
          WHERE xyear = "+str(dt.year)+" and xmonth = "+ str(dt.month) +"\
          GROUP BY xyear,xmonth,xday \
          ORDER BY xyear,xmonth,xday"

    cursor.execute(sql)
    results = cursor.fetchall()
    f.write(str(dt.year) + " " +dt.strftime("%B").upper()+" ACTIVATION STATISTICS:\r\n")
    f.write("=====================================\r\n")
    f.write('{:6s} {:15s} {:15s} {:15s} {:25s} {:15s}'.format("DAY","NEW ACCOUNTS","ACTIVATED","NOT ACTIVATED","ACTIVATION EMAIL FAILED","RESENT EMAIL")+"\r\n")
    for row in results:
        y = str(row[0])
        m = str(row[1])
        d = str(row[2])
        n = str(row[3])
        a = str(row[4])
        na = str(row[5])
        fl = str(row[6])
        rs = str(row[7])
        f.write('{:6s} {:15s} {:15s} {:15s} {:25s} {:15s}'.format(d,n,a,na,fl,rs)+"\r\n")
        if ( fl > 0 ):
            cursor.execute("SELECT * FROM oxa.oxa_activationfailed WHERE xyear="+y+" and xmonth="+m+" and xday="+d)
            results = cursor.fetchall()
            for row in  results:
                resent = ""
                if row[9] == 1:
                    resent = " | Resent on " + row[10].strftime("%Y-%m-%d %H:%M:%S")
                f.write("  "+row[5]+" | " + row[6] + " | "+row[7].strftime("%Y-%m-%d %H:%M:%S") + " | " + row[8].strftime("%Y-%m-%d %H:%M:%S") + " | " +row[11]+resent+"\r\n");
               
    f.write("\r\n\r\n")
     
    cursor.close()
    db.close()

def OutputAllFailedEmailActivation( f ):
    db = MySQLdb.connect(IP,User,Password,Database)
    cursor = db.cursor()

    dt = datetime.now()

    sql = "SELECT * FROM oxa.oxa_activationfailed \
          WHERE is_processed=0 \
          ORDER BY xyear,xmonth,xday,hostvmip"

    cursor.execute(sql)
    results = cursor.fetchall()
    f.write("OUTSTANDING FAILED ACTIVATION EMAILS:\r\n\r\n")
    f.write("=============================\r\n")
    f.write('{:8s} {:6s} {:6s} {:50s} {:36s} {:24s} {:24s} {:20s}'.format("YEAR","MONTH","DAY","EMAIL","ACTIVATION KEY","DATE JOINED","DATE FAILED","VM IP")+"\r\n")
    for row in results:
        y = str(row[1])
        m = str(row[2])
        d = str(row[3])
        line = '{:8s} {:6s} {:6s} {:50s} {:36s} {:24s} {:24s} {:20s}'.format(y,m,d,row[5],row[6],row[7].strftime("%Y-%m-%d %H:%M:%S"),row[8].strftime("%Y-%m-%d %H:%M:%S"),row[11])
        f.write(line +"\r\n");

    f.write("\r\n\r\n")
    cursor.close()
    db.close()

def GetNotProcessedEmailActivationFailures():
    db = MySQLdb.connect(IP,User,Password,Database)
    cursor = db.cursor()


    sql = "SELECT * FROM oxa.oxa_activationfailed \
          WHERE user_id > 0 and is_processed=0 \
          ORDER BY xyear,xmonth,xday,hostvmip"

    cursor.execute(sql)
    results = cursor.fetchall()
    cursor.close()
    db.close()

    return results

def GetMailServerConnection():
    mailserver = SMTP("smtp-server",port)
    mailserver.starttls()
    mailserver.login("UserName", "Password")
    return mailserver

def SendMail(mailserver, message, toMail, subject, attachment=None):
    from_addr = ""
    msg = MIMEMultipart()
    msg['From'] = ""
    msg['To'] = toMail
    msg['Subject'] = subject
    msg.attach(MIMEText(message))

    if ( attachment != None ):
        for filename in attachment:  
            with open("/oxa/"+filename,'r') as f:
                data = f.read()
                cnt = MIMEText(data)
                cnt.add_header('Content-Disposition', 'attachment', filename=filename)
                msg.attach(cnt)

    mailserver.sendmail(from_addr,toMail,msg.as_string())

def WriteLog( log, error=None ):
    if error == None:
        os.system("echo '"+str(datetime.now())+" "+ log + "' >> /oxa/oxa_email_notify.log")
    else:
        os.system("echo '"+str(datetime.now())+" "+ log + ": "+str(error)+"' >> /oxa/oxa_email_notify.log")

def GetActivationEmailForUser( activation_key ):
    msg = "\r\nThank you for creating an account with Microsoft Learning!\r\n\r\nThere's just one more step before you can enroll in a course: you need to activate your Microsoft Learning account. To activate your account, click the following link. If that doesn't work, copy and paste the link into your browser's address bar.\r\n\r\n  https://openedx.microsoft.com/activate/"+activation_key+"\r\n\r\nIf you didn't create an account, you don't need to do anything. If you need assistance, please do not reply to this email message. Check the Support link at the bottom of the Microsoft Learning website.\r\n\r\n\r\n----\r\nMicrosoft respects your privacy. Please read our online Privacy Statement: http://go.microsoft.com/fwlink/?LinkId=521839\r\n\r\nThis is a mandatory service communication. To set your contact preferences for other communications, visit the Promotional Communications Manager: http://go.microsoft.com/fwlink/?LinkId=243191\r\n\r\nMicrosoft Corporation\r\nOne Microsoft Way\r\nRedmond, WA 98052 USA\r\n"

    return msg

def MarkDatabaseActivationEMailSent( row ):
    db = MySQLdb.connect(IP,User,Password,Database)
    cursor = db.cursor()

    dt = datetime.now()
    sql = "UPDATE oxa.oxa_activationfailed SET is_processed = 1, date_processed = '"+str(dt)+"' WHERE id="+str(row[0])
    cursor.execute(sql)
    sql = "UPDATE oxa.oxa_activationsummary SET resend = resend+1 WHERE xyear="+str(row[1])+" and xmonth="+str(row[2])+" and xday="+str(row[3])    
    cursor.execute(sql)

    db.commit()
    cursor.close()
    db.close()

email_monitor_receivers_eng = ""
email_monitor_receivers_sup = ""

WriteLog("Started running process")
dt = datetime.now()
subject = dt.strftime("%Y-%m-%d %H:%M:%S")
filename = dt.strftime("%Y%m%d%H%M%S") + ".mail.txt"
f = open("/oxa/"+filename,"w")

OutputMonthlySummary(f)
OutputCurrentMonthSummary(f)
OutputAllFailedEmailActivation(f)
f.close()

mailserver = None
try:
    mailserver = GetMailServerConnection()
except Exception, ex:
    WriteLog("Email Server Connection Error",ex)

if mailserver != None:
    try:
        results = GetNotProcessedEmailActivationFailures() 
        activated_emails = "Activation email sent to these users:\r\n\r\n"
        activated_emails_keys = "Activation email sent to these users:\r\n\r\n"
        activated_count = 0
        for row in results:
            msg = GetActivationEmailForUser(row[6])
            try:
                SendMail(mailserver,msg,row[5],"Activate Your Microsoft Learning Account")
                MarkDatabaseActivationEMailSent(row)
                WriteLog("Activation email is sent to user "+row[5]+" with key "+row[6])
                activated_count = activated_count + 1
                activated_emails = activated_emails + row[5]+"\r\n"
                activated_emails_keys = activated_emails_keys + '{:50s} {:36s}'.format(row[5],row[6])+"\r\n"

            except Exception, ex:
                WriteLog("Failed to send activation key to user "+row[5] + " with key " + row[6],ex) 
        
        dt = datetime.now()
        subject = dt.strftime("%Y-%m-%d %H:%M:%S")
        filename = dt.strftime("%Y%m%d%H%M%S") + ".mail.txt"
        f = open("/oxa/"+filename,"w")

        OutputMonthlySummary(f)
        OutputCurrentMonthSummary(f)
        OutputAllFailedEmailActivation(f)

        if activated_count > 0:
            f.write(activated_emails_keys)
        f.close()
        
        body_msg = "Please see the attachment for summary."
        if activated_count > 0:
            body_msg = body_msg + "\r\n\r\n" + activated_emails
        SendMail(mailserver,body_msg,email_monitor_receivers_eng,"OXA Activation EMail Monitoring : ["+ subject+"]",[filename])
        WriteLog("Sent summary email to " + email_monitor_receivers_eng) 
         
        if activated_count > 0:
            SendMail(mailserver,"To the attention of Microsoft Azure Training T2 Support Team.\r\n\r\n"+activated_emails,email_monitor_receivers_sup,"OXA Activation EMail Monitoring : ["+ subject+"]")          
            WriteLog("Sent summary email to " + email_monitor_receivers_sup)

    except Exception, ex:
        WriteLog("Failed to send email",ex)

WriteLog("Finished running process")

if mailserver != None:
    mailserver.quit()

