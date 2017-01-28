import os
import re
from subprocess import call
import sys, getopt
from collections import OrderedDict


pattern = r'Applying (.\w*).(.*?)... OK'
SEPARATOR = "."

def processLog(fileName):
  ctr = 0
  migration_Dict = OrderedDict()

  with open(fileName, 'r') as searchfile:
    for line in searchfile:
      if line.find("Running deferred SQL") > 0 : # if the line contains Running deferred SQL tag it
        ctr = ctr + 1

      if ctr == 1:    # process required migrations
        processLine(migration_Dict, line, "LMS")
      elif ctr == 2:  # ignore repeating migrations
        pass


  printSummary(migration_Dict, "LMS")
  writeToFile("lms_upgrade.log", migration_Dict, "LMS")


def processLine(d, line, label):
  pattern = r'Applying (.\w*).(.*?)... OK'

  if "Applying" in line:
    searchObj = re.search(pattern, line, re.M|re.I)
    if (searchObj):
        appName = searchObj.group(1)    #example - api_admin
        group2 = searchObj.group(2)
        ptr = group2.index("_")
        migrationNumber = group2[ : ptr]   #example - 0001 (any number)
        description = group2[ptr+1:]
        # the key is unique in the dictionary
        # key + value = file example api_admin.002_auto_20160325_1604
        # ideally I want this to be an object later on (class)
        key = appName + SEPARATOR + migrationNumber #example - api_admin.0001
        # print(key)
        value = description        #example - api_admin.0002_auto_20160325_1604
        # print(key+ SEPARATOR + value)
        d[key] = value

#function to print the summary
def printSummary(d, label):
  print("****************************")
  s = 'Total number of migrations = {}'.format(len(d))
  print(s)
  printDetails(d)

# function to print the statistics
def printDetails(d):
  if len(d) > 0:
    for key, value in d.items():
      appName, migrationNumber = parseKey(key)
      print(appName, migrationNumber)
  else:
      print("There are no migrations")

# function to parse appName and migration number
# given a key like microsite_configuration.0001

def parseKey(key):
  index = key.index(".")
  appName = key[0:index]
  migrationNumber = key[index + 1:]
  return appName, migrationNumber

#function to write contents to file
#by default the file is written in text mode
#if the file is
def writeToFile(filename, d, label):
  if filename is None:
    filename = label + ".sql"
  with open(filename, "w+") as f:
    for key, value in d.items():
      appName, migrationNumber = parseKey(key)
      f.write(appName + "\t"+ migrationNumber + "\n")
  print("done writing ::", label)


# it should take the full path of the filename
# check for main and help should be included..
processLog('upgrade.log')
os.system('bash run_sqlmigrate.sh')


