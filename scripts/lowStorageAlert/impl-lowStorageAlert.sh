#!/bin/bash

# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

#todo:inputParam
USAGE_THRESHOLD_PERCENT=33; #todo, 33% for now.

#todo:sourceUtilities then change echo to log. then change log to email

# List of <usage>$<path>
# for example:
#   "4%/"
#   "1%/datadisks/disk1"
diskUsages=`df --output=ipcent,target | grep -v -i "use%\|mounted on" | tr -d ' '`

# Iterate over list of <usage>$<path> pairs.
while read diskUsage; do
    # Split usage and path
    diskUsageArray=(`echo "$diskUsage" | tr '%' ' '`)
    percentUsed=${diskUsageArray[0]}
    directoryPath=${diskUsageArray[1]}

    # Alert for unexpected values (indicative of possible errors in script)
    if [[ -n ${diskUsageArray[2]} ]]; then
        echo "Error in script lowStorageAlert. Too many values"
        echo "Original string before split: $diskUsage"
        echo "Percentage used: $percentUsed"
        echo "For path: $directoryPath"
        echo "Extraneous value: ${diskUsageArray[2]}"

        continue;
    fi
    if [[ -z $percentUsed ]] || [[ -z $directoryPath ]]; then
        echo "Error in script lowStorageAlert. Missing partition usage or file system path"
        echo "Original string before split: $diskUsage"
        echo "Percentage used: $percentUsed"
        echo "For path: $directoryPath"

        continue
    fi

    # Alert when threshold is exceeded.
    if (( $(echo "$percentUsed > $USAGE_THRESHOLD_PERCENT" | bc -l) )); then

        # Help clarify messaging by appending trailing slash to directory.
        if [[ $directoryPath != '/' ]]; then
            directoryPath="${directoryPath}/"
        fi

        # Message
        echo "Directory $directoryPath on machine $HOSTNAME is using $percentUsed percent of available space"
        echo "Please cleanup this directory at your earliest convenience."
        echo "The top subfolders or subfiles in $directoryPath are:"
        # Get list of subitems and filesize, sort them, grab top five, indent, newline.
        printf "`du -sh $directoryPath* 2> /dev/null | sort -h -r | head -n 5 | sed -e 's/^/  /'`"
        echo

    fi

    # Newline between exections
    echo

done <<< "$diskUsages"
