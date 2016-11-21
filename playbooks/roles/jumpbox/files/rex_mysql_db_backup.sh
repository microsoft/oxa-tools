#fyi: this is an unmodified fork from rex pilot.

#todo: fix below

#!/bin/bash
echo "mysql backup using mysqldump"
source /tmp/transfer/backup/storage_keys.sh
root_password="R3x0p3n3dx!"
NOW=$(date +"%m-%d-%Y-%H%M%S")
export file_to_upload="mysqlbackup_$NOW.tar.gz"
export backup_filename="mysqlbackup_$NOW.sql"
export AZURE_STORAGE_ACCOUNT=$StorageAccountName
export AZURE_STORAGE_ACCESS_KEY=$StorageAccountKey1
export container_name=mysqlbackup
export blob_name="mysqlbackup_$NOW.tar.gz"
export destination_folder=/home/openedxuser

cd $(dirname ${BASH_SOURCE[0]})

mysqldump -u root -p$root_password --all-databases --single-transaction > $backup_filename
tar -czf $file_to_upload $backup_filename

sc=$(azure storage container show $container_name --json)
if [[ -z $sc ]]; then
    echo "Creating the container..." + $container_name
    azure storage container create $container_name
fi

echo "Uploading the backup file..."
res=$(azure storage blob upload $file_to_upload $container_name $blob_name --json | jq '.blob')
if [ "$res"!="" ]; then
   echo "$res blob file uploaded successfully"
else
	echo "Upload blob file failed"   
fi

rm -f $file_to_upload
rm -f $backup_filename
