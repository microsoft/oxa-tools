#!/bin/bash
# Run euc_db_fetch and fic_db_fetch first then run this script to generate the /tmp/fic_lms_migration.sql migration sql script
while read line; do

cd /edx/app/edxapp/edx-platform
source /edx/app/edxapp/edxapp_env
echo "/*============$line=============================*/"
sudo -E -u edxapp env "PATH=$PATH" /edx/app/edxapp/venvs/edxapp/bin/python manage.py lms sqlmigrate --settings=aws $line
done < fic_migration_info.txt > /tmp/fic_lms_migration.sql

# the below code is hard coded since users_tasks migration is CMS not LMS
cd /edx/app/edxapp/edx-platform
source /edx/app/edxapp/edxapp_env
echo "/*============users_tasks=============================*/" >>/tmp/fic_lms_migration.sql
sudo -E -u edxapp env "PATH=$PATH" /edx/app/edxapp/venvs/edxapp/bin/python manage.py cms sqlmigrate --settings=aws users_tasks 0001 >> /tmp/fic_lms_migration.sql
sudo -E -u edxapp env "PATH=$PATH" /edx/app/edxapp/venvs/edxapp/bin/python manage.py cms sqlmigrate --settings=aws users_tasks 0002 >> /tmp/fic_lms_migration.sql

