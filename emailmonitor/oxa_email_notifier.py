# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# This python script reads the data in MySQL and sends summary emails
# This script also sends activation emails to users that failed in the first time

import MySQLdb
import collections
import os
import re
from datetime import datetime,timedelta
from smtplib import SMTP
from email.MIMEMultipart import MIMEMultipart
from email.MIMEText import MIMEText


def read_app_config():
    config = {}
    with open('oxa_email_config.cfg') as f:
        for line in f:
            line = line.strip()
	        (key, _, value) = line.partition("=")
            config[key]=value
			
    return config
	
# Sample output:
# YEAR-MONTH ACTIVATION STATISTICS:
# =================================
# YEAR     MONTH  NEW ACCOUNTS    ACTIVATED       NOT ACTIVATED   ACTIVATION EMAIL FAILED   RESENT EMAIL   
# 2016     11     173             152             21              0                         0              
# 2016     12     22552           19648           2904            0                         0     
def output_monthly_summary( f, config ):
    db = MySQLdb.connect(config["mysql_host"],config["mysql_user"],config["mysql_password"],config["mysql_database"])
    cursor = db.cursor()

    sql = "SELECT activation_year, activation_month, SUM(newaccount),SUM(activated),SUM(notactivated),SUM(failed),SUM(resend) FROM oxa.oxa_activationsummary \
          GROUP BY activation_year,activation_month \
          ORDER BY activation_year,activation_month"

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

# Sample output:
# 2017 JUNE ACTIVATION STATISTICS:
# =====================================
# DAY    NEW ACCOUNTS    ACTIVATED       NOT ACTIVATED   ACTIVATION EMAIL FAILED   RESENT EMAIL   
# 1      448             377             71              0                         0              
# 2      432             333             99              1                         1              	
#  someuser@domain.com | 99c6f6fc0a23458888e88537e034fd99 | 2017-06-07 02:57:41 | 2017-06-07 02:57:43 | 10.0.0.21 | Resent on 2017-06-12 15:27:32
def output_current_month_summary( f , config):
    db = MySQLdb.connect(config["mysql_host"],config["mysql_user"],config["mysql_password"],config["mysql_database"])
    cursor = db.cursor()

    dt = datetime.now()
    
    sql = "SELECT activation_year, activation_month, activation_day, SUM(newaccount),SUM(activated),SUM(notactivated),SUM(failed),SUM(resend) FROM oxa.oxa_activationsummary \
          WHERE activation_year = "+str(dt.year)+" and activation_month = "+ str(dt.month) +"\
          GROUP BY activation_year,activation_month,activation_day \
          ORDER BY activation_year,activation_month,activation_day"

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
            cursor.execute("SELECT * FROM oxa.oxa_activationfailed WHERE activation_year="+y+" and activation_month="+m+" and activation_day="+d)
            results = cursor.fetchall()
            for row in  results:
                resent = ""
                if row[9] == 1:
                    resent = " | Resent on " + row[10].strftime("%Y-%m-%d %H:%M:%S")
                f.write("  "+row[5]+" | " + row[6] + " | "+row[7].strftime("%Y-%m-%d %H:%M:%S") + " | " + row[8].strftime("%Y-%m-%d %H:%M:%S") + " | " +row[11]+resent+"\r\n");
               
    f.write("\r\n\r\n")
     
    cursor.close()
    db.close()

# Sample output:
# OUTSTANDING FAILED ACTIVATION EMAILS:
#
# =============================
# YEAR     MONTH  DAY    EMAIL                                              ACTIVATION KEY                       DATE JOINED              DATE FAILED              VM IP               
# 2017     5      2      kenneth.masterfox@gmail.com                        Not Found!!!                         2017-05-03 04:37:20      2017-05-03 04:37:20      10.0.0.21           
# 2017     5      18     villanuevachrisallen@gmail.com                     Not Found!!!                         2017-05-19 02:29:41      2017-05-19 02:29:41      10.0.0.5   	
def output_all_failed_email_activation( f , config ):
    db = MySQLdb.connect(config["mysql_host"],config["mysql_user"],config["mysql_password"],config["mysql_database"])
    cursor = db.cursor()

    dt = datetime.now()

    sql = "SELECT * FROM oxa.oxa_activationfailed \
          WHERE is_processed=0 \
          ORDER BY activation_year,activation_month,activation_day,hostvmip"

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

def get_not_processed_email_activation_failures( config ):
    db = MySQLdb.connect(config["mysql_host"],config["mysql_user"],config["mysql_password"],config["mysql_database"])
    cursor = db.cursor()


    sql = "SELECT * FROM oxa.oxa_activationfailed \
          WHERE user_id > 0 and is_processed=0 \
          ORDER BY activation_year,activation_month,activation_day,hostvmip"

    cursor.execute(sql)
    results = cursor.fetchall()
    cursor.close()
    db.close()

    return results

# Using the SMTP credentials and server and port get mailserver object
def get_mail_server_connection( config ):
    mailserver = SMTP(config["smtp_host"],int(config["smtp_port"]))
    mailserver.starttls()
    mailserver.login(config["smtp_user"], config["smtp_password"])
    return mailserver

# Send the email to mailserver
def send_mail(mailserver, message, toMail, subject, attachment=None):
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

# Write info or error log to log file /oxa/oxa_email_notify.log
def write_log(config, log, error=None ):
    if error == None:
        os.system("echo '"+str(datetime.now())+" "+ log + "' >> "+config["log_path"]+"/oxa_email_notify.log")
    else:
        os.system("echo '"+str(datetime.now())+" "+ log + ": "+str(error)+"' >> "+config["log_path"]+"/oxa_email_notify.log")

# Create the activation email body for the given activation key (GUID)
def get_activation_email_for_user( activation_key ):
    msg = "\r\nThank you for creating an account with Microsoft Learning!\r\n\r\nThere's just one more step before you can enroll in a course: you need to activate your Microsoft Learning account. To activate your account, click the following link. If that doesn't work, copy and paste the link into your browser's address bar.\r\n\r\n  https://openedx.microsoft.com/activate/"+activation_key+"\r\n\r\nIf you didn't create an account, you don't need to do anything. If you need assistance, please do not reply to this email message. Check the Support link at the bottom of the Microsoft Learning website.\r\n\r\n\r\n----\r\nMicrosoft respects your privacy. Please read our online Privacy Statement: http://go.microsoft.com/fwlink/?LinkId=521839\r\n\r\nThis is a mandatory service communication. To set your contact preferences for other communications, visit the Promotional Communications Manager: http://go.microsoft.com/fwlink/?LinkId=243191\r\n\r\nMicrosoft Corporation\r\nOne Microsoft Way\r\nRedmond, WA 98052 USA\r\n"

    return msg

# After sending activation email to user successfully, mark database table raw as email sent with timestamp. 
# Also update the RESEND statistic for the corresponding YYYY,MM,DD
def mark_database_activation_email_sent( row , config ):
    db = MySQLdb.connect(config["mysql_host"],config["mysql_user"],config["mysql_password"],config["mysql_database"])
    cursor = db.cursor()

    dt = datetime.now()
    sql = "UPDATE oxa.oxa_activationfailed SET is_processed = 1, date_processed = '"+str(dt)+"' WHERE id="+str(row[0])
    cursor.execute(sql)
    sql = "UPDATE oxa.oxa_activationsummary SET resend = resend+1 WHERE activation_year="+str(row[1])+" and activation_month="+str(row[2])+" and activation_day="+str(row[3])    
    cursor.execute(sql)

    db.commit()
    cursor.close()
    db.close()

config = read_app_config()
# Engineering team mail address. You can put multiple email addresses by separating with semicolumn
email_monitor_receivers_eng = config["mail_list_eng"]
# Support team mail address. You can put multiple email addresses by separating with semicolumn
email_monitor_receivers_sup = config["mail_list_sup"]

write_log(config, "Started running process")

# Create the SMTP mail server object and send the summary email with proper exception handling and error and info logging
# Also send activation emails to failed users and log this and update database and statistics
mailserver = None
try:
    mailserver = get_mail_server_connection(config)
except Exception, ex:
    write_log(config, "Email Server Connection Error",ex)

if mailserver != None:
    try:
        results = get_not_processed_email_activation_failures(config) 
        activated_emails = "Activation email sent to these users:\r\n\r\n"
        activated_emails_keys = "Activation email sent to these users:\r\n\r\n"
        activated_count = 0
        for row in results:
            msg = get_activation_email_for_user(row[6])
            try:
                # Send activation emails to failed users and log this and update database and statistics
                send_mail(mailserver,msg,row[5],"Activate Your Microsoft Learning Account")
                try:
				    mark_database_activation_email_sent(row,config)
			    except Exception, ex:
                    write_log(config, "[mark_database_activation_email_sent] MySQL database connection error",ex)
					
                write_log(config, "Activation email is sent to user "+row[5]+" with key "+row[6])
                activated_count = activated_count + 1
                activated_emails = activated_emails + row[5]+"\r\n"
                activated_emails_keys = activated_emails_keys + '{:50s} {:36s}'.format(row[5],row[6])+"\r\n"

            except Exception, ex:
                write_log(config, "Failed to send activation key to user "+row[5] + " with key " + row[6],ex) 
        
		# Create the timestamp string for summary email subject and also for temp file
        dt = datetime.now()
        subject = dt.strftime("%Y-%m-%d %H:%M:%S")
        filename = dt.strftime("%Y%m%d%H%M%S") + ".mail.txt"
		# Create the temp email file and with the functions below fill in the sections.
        f = open("/oxa/"+filename,"w")

        try:
		    # YYYY, MM statistics summary section
            output_monthly_summary(f,config)
        except Exception, ex:
            write_log(config, "[output_monthly_summary] MySQL database connection error",ex)
		
        try:
		    # YYYY, MM, DD  statistics summary section for current month
            output_current_month_summary(f,config)
        except Exception, ex:
            write_log(config, "[output_current_month_summary] MySQL database connection error",ex)
        try:
		    # All failed activation emails that not resent yet
            output_all_failed_email_activation(f,config)
	    except Exception, ex:
            write_log(config, "[output_all_failed_email_activation] MySQL database connection error",ex)

        if activated_count > 0:
            f.write(activated_emails_keys)
		# Close file 	
        f.close()
        
		# Send the summary email with report attachment
        body_msg = "Please see the attachment for summary."
        if activated_count > 0:
            body_msg = body_msg + "\r\n\r\n" + activated_emails
        send_mail(mailserver,body_msg,email_monitor_receivers_eng,"OXA Activation EMail Monitoring : ["+ subject+"]",[filename])
        write_log(config, "Sent summary email to " + email_monitor_receivers_eng) 
         
        if activated_count > 0:
            send_mail(mailserver,"To the attention of Microsoft Azure Training T2 Support Team.\r\n\r\n"+activated_emails,email_monitor_receivers_sup,"OXA Activation EMail Monitoring : ["+ subject+"]")          
            write_log(config, "Sent summary email to " + email_monitor_receivers_sup)

    except Exception, ex:
        write_log(config, "Failed to send email",ex)

write_log(config, "Finished running process")

if mailserver != None:
    mailserver.quit()

