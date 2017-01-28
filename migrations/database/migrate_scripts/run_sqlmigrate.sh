#!/bin/bash

while read line; do

cd /edx/app/edxapp/edx-platform
source /edx/app/edxapp/edxapp_env
echo "/*============$line=============================*/"
sudo -E -u edxapp env "PATH=$PATH" /edx/app/edxapp/venvs/edxapp/bin/python manage.py lms sqlmigrate --settings=aws $line
done < lms_upgrade.log > /tmp/lms_migration_sql.sql
# the below code is hard coded since tagging migration is missing in the upgrade.log file
cd /edx/app/edxapp/edx-platform
source /edx/app/edxapp/edxapp_env
echo "/*============$line=============================*/" >>/tmp/lms_migration_sql.sql
sudo -E -u edxapp env "PATH=$PATH" /edx/app/edxapp/venvs/edxapp/bin/python manage.py cms sqlmigrate --settings=aws tagging 0001 >> /tmp/lms_migration_sql.sql

