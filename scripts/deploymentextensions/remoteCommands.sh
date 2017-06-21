#!/bin/bash
#
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# Convenient wrappers for executing SCP or SSH across a collections of machines sequentially.
# This file can be used in at least three different ways.
#   1. Callers can "bash" execute the script itself providing a parameter settings files. This file should contain the required variables. This is the best technique for cron.
#   2. Callers can "export" the required variables and then "bash" execute OR "source" this file without providing a settings file.
#   3. Callers can "source" this file, assign the required variables, invoke desired function directly.

# SCP ONLY
PATHS_TO_COPY_LIST="()"
DESTINATION_MACHINES_LIST="()"
DESTINATION_DIRECTORY="~"

# BOTH SCP AND SSH
REMOTE_USER=""

# SSH ONLY
REMOTE_COMMAND=""
REMOTE_ARGUMENTS=""

scp_wrapper()
{
    # Iterate over target machines
    for destinationHost in "${DESTINATION_MACHINES_LIST[@]}" ; do
        # Iterate over source path for copy
        for pathToCopy in "${PATHS_TO_COPY_LIST[@]}" ; do
            scp -r -o "StrictHostKeyChecking=no" \
                $pathToCopy \
                $REMOTE_USER@$destinationHost:$DESTINATION_DIRECTORY
        done
    done
}

ssh_cmd_wrapper()
{
    preCommand=""
    parentPath=`dirname $REMOTE_COMMAND`
    if [[ "$parentPath" != "." ]] then
        # The command is a path to a script.
        # Let's update working directory and configure permissions accordingly.
        preCommand="cd $parentPath && sudo chmod 755 $REMOTE_COMMAND && "
    fi

    for destinationHost in "${DESTINATION_MACHINES_LIST[@]}" ; do
        ssh -o "StrictHostKeyChecking=no" \
            $REMOTE_USER@$destinationHost \
            "$preCommand $REMOTE_COMMAND $REMOTE_ARGUMENTS"
    done
}

