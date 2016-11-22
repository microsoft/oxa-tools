#fyi: this is an unmodified fork from rex pilot.

#todo: fix below

#!/bin/bash
echo "mongodb backup using mongodump"
source /tmp/transfer/backup/storage_keys.sh

NOW=$(date +"%m-%d-%Y-%H%M%S")
export file_to_upload="mongobackup_$NOW.tar.gz"
export AZURE_STORAGE_ACCOUNT=$StorageAccountName
export AZURE_STORAGE_ACCESS_KEY=$StorageAccountKey1
export container_name=mongobackup
export mongo_backup="mongobackup_$NOW"
export blob_name="mongobackup_$NOW.tar.gz"
mongo_admin_pwd="R3x0p3n3dx!"

cd $(dirname ${BASH_SOURCE[0]})

mongodump -u admin -p$mongo_admin_pwd -o $mongo_backup
tar -zcvf $file_to_upload $mongo_backup

echo "Upload the backup file to azure blob storage"

sc=$(azure storage container show $container_name --json)
if [[ -z $sc ]]; then
        echo "Creating the container..." + $container_name
    azure storage container create $container_name
fi

res=$(azure storage blob upload $file_to_upload $container_name $blob_name --json | jq '.blob')
if [ "$res"!="" ]; then
   echo "$res blob file uploaded successfully"
else
	echo "Upload blob file failed"
fi

rm -f $file_to_upload
rm -r $mongo_backup