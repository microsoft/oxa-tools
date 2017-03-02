# Before running this script, run euc_db_fetch.py which will generate tuple.pickle file
# After running this script we will have the ficus only migration application name and migration number list in the file fic_migration_info.txt
import MySQLdb
import sys
import pickle
from collections import OrderedDict

def ficus_migration_info():
        connection = MySQLdb.connect (db = "edxapp_csmh")
        cursor = connection.cursor ()
        cursor.execute ("select app,name from django_migrations")
        data = cursor.fetchall ()
        pickle_in = open("tuple.pickle","rb")
        euc_migrations = pickle.load(pickle_in)
        dic=OrderedDict()
        sys.stdout=open("fic_migration_info.txt","w")
        for item in data:                
                if item not in euc_migrations:
                        onemigration=item                        
                        print(onemigration[0]+"\t"+onemigration[1][:4])                        
        sys.stdout.close()
     

ficus_migration_info()
