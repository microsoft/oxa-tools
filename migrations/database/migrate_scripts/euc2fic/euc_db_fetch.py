# Run this on eucalyptus fullstack VM
# This will get the applied migrations list and will write into file tuple.pick which will be used by fic_db_fetch.py 
import MySQLdb
import sys
import pickle

def euc_applied_migrations():
   connection = MySQLdb.connect (db = "edxapp_csmh")
   cursor = connection.cursor ()
   cursor.execute ("select app,name from django_migrations")
   data = cursor.fetchall ()
   pickle_out=open("tuple.pickle","wb")
   pickle.dump(data,pickle_out)
   pickle_out.close()

euc_applied_migrations()

