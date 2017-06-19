# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# This python script determines the failed activation email sends and also creates daily statistics in database
# This summary data and email failures used in another script for sending status reports and also for sending activation emails again

import MySQLdb
import collections
import os
import re
from datetime import datetime,timedelta

# Write an error or info log line with timestamp to the application log file /oxa/oxa_mail_monitor.log
def write_log( log, error=None ):
    if error == None:
        os.system("echo '"+str(datetime.now())+" "+ log + "' >> /oxa/oxa_email_monitor.log")
    else:
        os.system("echo '"+str(datetime.now())+" "+ log + ": "+str(error)+"' >> /oxa/oxa_email_monitor.log")
		
# This function creates the YYYY,MM,DD statistics raw in oxa.oxa_activationsummary table if it doesn't exists. This is rerunnable
def generate_activation_daily_summary():
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

# For each YYYY,MM,DD statistics raw in oxa.oxa_activationsummary table, this function updates the created accounts statistics based on edxapp.auth_user table. This is rerunnable
def update_accounts_created():
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

# For each YYYY,MM,DD statistics raw in oxa.oxa_activationsummary table, this function updates the activated accounts statistics based on edxapp.auth_user table. This is rerunnable
def update_accounts_activated():
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

# For each YYYY,MM,DD statistics raw in oxa.oxa_activationsummary table, this function updates the non-activated accounts statistics based on edxapp.auth_user table. This is rerunnable
def update_accounts_notactivated():
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

# For the given failed activation email line which has timestamp and user email address, update oxa database if it is not already processed
# This is rerunnable for logs and it process a line only once in database
def process_error_line( cursor, line ):

    # From the activation email error line, with regular expression fetch IP, year, month, day, hour, minute, second, and email    
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
                
	    # If this error line is not already processed (not in MySQL) , process it otherwise skip 		
        cursor.execute("SELECT id from oxa.oxa_activationfailed where email='"+email+"'")
        if cursor.rowcount <= 0: 
		    # Find user_id from email 
            cursor.execute("SELECT id,date_joined from edxapp.auth_user WHERE email='"+email+"'")
            user_id = 0
			# Here we are converting time to PST time by subtracting 7, Normally in log files it is UTC time. But in MySQL it is PST time. So we map them to eachother as PST time
            date_joined = dt_obj + timedelta(hours=7)
            date_failed = date_joined
            #Find the activation ket 
			activation_key = "Not Found!!!"
            # Find activation key from user_id
			if cursor.rowcount > 0:
                result = cursor.fetchall()         
                user_id = result[0][0]
                date_joined = result[0][1] 
                cursor.execute("SELECT activation_key FROM edxapp.auth_registration WHERE user_id="+str(user_id)) 
                if cursor.rowcount > 0:
                    result = cursor.fetchall()
                    activation_key = result[0][0]
            
			# Insert this new activation email failure to oxa.oxa_activationfailed table and update activation_failed statistics for corresponding day in oxa.oxa_activationsummary table
            cursor.execute("INSERT INTO oxa.oxa_activationfailed (xyear,xmonth,xday,user_id,email,activation_key,date_joined,date_failed,hostvmip) VALUES("+y+","+mo+","+d+","+str(user_id)+",'"+email+"','"+activation_key+"','"+str(date_joined)+"','"+str(date_failed)+"','"+ip+"')")
            cursor.execute("UPDATE oxa.oxa_activationsummary SET failed=failed+1 WHERE  xyear="+y+" and xmonth="+mo+" and xday="+d)    
             
        

    
# Fetch the error log files for the specified IP VMs and process them in order to determine activation email failures
def fetch_and_grep_log_files():
    # Remove if exists and create the folder for fethcing error log files from edxapp VMs
	os.system('rm -fr /tmp/oxa_log_files')
    os.system('mkdir /tmp/oxa_log_files')

	# For each VM, create folder with its IP and copy log files with scp 
    vms = ('10.0.0.?','10.0.0.?','10.0.0.?','10.0.0.?','10.0.0.?')
    for ip in vms:
        os.system('mkdir /tmp/oxa_log_files/'+ip)    
        os.system('scp '+ip+':/edx/var/log/supervisor/*default* /tmp/oxa_log_files/'+ip+'/')

	# In the copied log files search for failed activation emails and write to a temp file notsent	/tmp/oxa_log_files/notsentemails.txt
    os.system("grep 'Unable to send activation email' /tmp/oxa_log_files/*/* > /tmp/oxa_log_files/notsentemails.txt")
    
	# Now read each line from /tmp/oxa_log_files/notsentemails.txt and if it is not processed already process it and insert to table and update statistics for the corersponding YYYY,MM,DD 
	db = MySQLdb.connect(IP,User,Password,Database)
    cursor = db.cursor()
    with open('/tmp/oxa_log_files/notsentemails.txt') as f:
        for line in f:
            process_error_line(cursor,line)

    db.commit()
    cursor.close() 
    db.close()

write_log("Started running process")

# Create new YYYY, MM, DD statistic raws
generate_activation_daily_summary()

#Update the created account numbers for each day
update_accounts_created()

#Update the activated account numbers for each day
update_accounts_activated()

#Update the non-activated account numbers for each day
update_accounts_notactivated()

#Fetch the log files from edxapp VMs and determine activation email failures and update daily statistics
fetch_and_grep_log_files()

write_log("Finished running process")

print "Done"

