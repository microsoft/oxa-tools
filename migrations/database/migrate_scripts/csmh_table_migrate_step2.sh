# Original script is here https://github.com/edx/configuration/blob/master/util/csmh-extended/migrate-same-database-instance.sh

MINID=0
MAXID=0
STEP=10000
MIGRATE_USER=''
PASSWORD=''
HOST=''

for ((i=$MINID; i<=$MAXID; i+=$STEP)); do
echo -n "$i";
mysql -u $MIGRATE_USER -p$PASSWORD -h $HOST edxapp<<EOF
INSERT INTO edxapp_csmh.coursewarehistoryextended_studentmodulehistoryextended (version, created, state, grade, max_grade, student_module_id)
  SELECT version, created, state, grade, max_grade, student_module_id
  FROM edxapp.courseware_studentmodulehistory
  WHERE id BETWEEN $i AND $(($i+$STEP-1));
EOF
echo '.';
sleep 2
done
