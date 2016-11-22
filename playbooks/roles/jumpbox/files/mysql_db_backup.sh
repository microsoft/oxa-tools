#fyi: this is a modified fork from rex pilot.

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
export destination_folder=/home/lexoxaadmin #todo: provide this secret dynamically

help()
{
    echo "This script will backup the mysql database"
    echo "Options:"
    echo "        --environment-file    Path to settings that are enviornment-specific"
}

# Parse script parameters
parse_args()
{
    while [[ "$#" -gt 0 ]]
        do

         # Log input parameters to facilitate troubleshooting
        echo "Option $1 set with value $2"

        case "$1" in
            -e|--environment-file)
                OS_ADMIN_USERNAME=$2
                shift # past argument
                ;;
            -h|--help)  # Helpful hints
                help
                exit 2
                ;;
            *) # unknown option
                echo "Option -${BOLD}$2${NORM} not allowed."
                help
                exit 2
                ;;
        esac

        shift # past argument or value
    done
}

# parse script arguments
parse_args $@

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
