#fyi: this is an unmodified fork from rex pilot. #todo: fix this

#!/bin/bash

echo " Mongo DB Restore using mongorestore
       USAGE: ./rex_mongo_db_restore.sh [password] [tar_gz_blobName] "

source /tmp/transfer/backup/storage_keys.sh
export container_name=mongobackup
export AZURE_STORAGE_ACCOUNT=$StorageAccountName
export AZURE_STORAGE_ACCESS_KEY=$StorageAccountKey1
current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
restore_dir=("$current_dir/mongobackup")
mongo_admin_pwd=""
echo $restore_dir
if [ ! -z "$1" ]
then
    mongo_admin_pwd=$1
fi

if [ -z "$2" ]
then
    files=$(azure storage blob list $container_name --json | jq '.[] .name')
    if [ -z "$files"]
    then 
        echo "There is no backup file avaialable"
        exit 0
    fi
    arr=$(echo $files | tr " " "\n")
    i=1
    for x in $arr
    do
        echo "$i> $x"
        i=$((i+1))
    done
    echo "enter the backup file name"
    read file
  
else
    file=$2
fi

blobfile=$(echo "$file" | sed -e 's/^"//'  -e 's/"$//')

if [ ! -d $restore_dir ]
then
    mkdir -p $restore_dir
fi

azure storage blob download $container_name $blobfile $restore_dir/$blobfile

mongodump_dir=$(echo ${blobfile/.tar.gz/})

tar xzf $restore_dir/$blobfile -C $restore_dir/
echo "Restoring mongo database.."

if [ -z "$mongo_admin_pwd" ]
then
    mongorestore --drop --noIndexRestore $restore_dir/$mongodump_dir
else
    mongorestore -u admin -p$mongo_admin_pwd --drop --noIndexRestore $restore_dir/$mongodump_dir
fi

read -r -p "You want to delete the backup directory? [Y/n]" response
case "$response" in
  y|Y ) response=1;;
  n|N ) response=0;;
  * ) response=1;;
esac
if [ "$response" != 0 ]; then
   rm -r $restore_dir
fi
