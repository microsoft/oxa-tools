#!/bin/bash

# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# Detects low partition storage (then sends notification)

set -x

# Settings
    usage_threshold_percent=33 # Default to a third of the disk.

# Paths and file names.
    current_script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    script_name=`basename "$0"`

notification()
{
    percentUsed="$1"
    directoryPath="$2"

    # Alert when threshold is exceeded.
    if (( $(echo "$percentUsed > $usage_threshold_percent" | bc -l) )) ; then

        if [[ $directoryPath == '/' ]] ; then
            # We're processing the root. Get the full list of OTHER partitions/mounts/drives so we can exclude them.
            # We do this because each of those partitions/mounts/drives will be processed separately.
            # Example results: datadisks\|dev\|media\|mnt\|run\|sys
            remove="`df -l | awk '{ print $6 }' | grep -v -i "mounted\|${directoryPath}$" | cut -d "/" -f2 | sort | uniq | sed ':a;N;$!ba;s/\n/\\\|/g'`"
        else
            # Append trailing slash for non-root directories. This is required for the "du" command below AND helps clarify messaging
            directoryPath="${directoryPath}/"
            remove=""
        fi

        # Message
        log "Please cleanup this directory at your earliest convenience."
        log "The top subfolders or subfiles in $directoryPath are:"

        # Get list of subitems and corresponding filesizes in current folder.
        itemsInFolder=`du -sh $directoryPath* 2> /dev/null`

        if [[ -n $remove ]] ; then
            # Remove other partitions/mounts/drives. Those will be processed separately.
            itemsInFolder=`echo "$itemsInFolder" | grep -v "$remove"`
        fi

        # sort results, grab top five, indent.
        echo "`echo "$itemsInFolder" | sort -h -r | head -n 5 | sed -e 's/^/  /'`"
    fi
}

check_usage()
{
    # List of <usage>%<path>
    # Example output:
    #   "4%/"
    #   "1%/datadisks/disk1"
    diskUsages=`df -l | awk '{ print $5$6 }' | grep -v -i "use%\|mounted"`

    # Iterate over list of <usage>%<path> pairs.
    while read diskUsage ; do
        # Split usage and path
        diskUsageArray=(`echo "$diskUsage" | tr '%' ' '`)

        # Alert for unexpected values (indicative of possible errors in script and/or unexpected cases)
        if (( ${#diskUsageArray[@]} > 2 )) ; then
            log "Error in script $script_name. Too many values"
            log "First extraneous value: ${diskUsageArray[2]}"
            log "Entire array is ${diskUsageArray[@]}"

            # Let's still check the next partition
            continue
        fi

        percentUsed=${diskUsageArray[0]}
        directoryPath=${diskUsageArray[1]}

        log "Directory $directoryPath on machine $HOSTNAME is using $percentUsed percent of available space"

        if [[ -z $percentUsed ]] || [[ -z $directoryPath ]] ; then
            log "Error in script $script_name. Missing disk usage percentage or file system path"

            # Let's still check the next partition
            continue
        fi

        notification "$percentUsed" "$directoryPath"

        # Newline between exections
        echo

    done <<< "$diskUsages"
}

###############################################
# START CORE EXECUTION
###############################################

# Update working directory
pushd $current_script_path

shared="sharedOperations.sh"
echo "Sourcing file $shared"
source $shared || exit 1

# Source utilities. Exit on failure.
source_utilities || exit 1

log "Checking for low disk space"

# Script self-idenfitication
print_script_header

# Parse commandline arguments
parse_args "$@"

# Rotate log (if machine support it). Exit if file is missing.
# Rotation will no-op if mysql isn't installed on the machine.
source_wrapper "rotateLog.sh" || exit 1

# Pre-conditionals
exit_if_limited_user

check_usage

# Restore working directory
popd
