#!/bin/bash
#
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# Convenient wrappers for executing SCP and/or SSH across a collections of machines sequentially.
# See help() for further details.

# BOTH SCP AND SSH
    DESTINATION_MACHINES_LIST="()"
    REMOTE_USER=""

# SCP ONLY
    PATHS_TO_COPY_LIST="()"
    DESTINATION_DIRECTORY="~"

# SSH ONLY
    REMOTE_COMMAND=""
    REMOTE_ARGUMENTS=""

# Path to settings file provided as an argument to this script.
    SETTINGS_FILE=

# Usage messaging
help_both()
{
    echo "Cannot batch $1 until the following variables are assigned"
    echo "DESTINATION_MACHINES_LIST: Array of remote machines"
    #todo:
}
help_scp()
{
    help_both "scp"
    #todo:
}
help_ssh()
{
    help_both "ssh"
    #todo:
}
help()
{
    echo
    echo "This script $SCRIPT_NAME will executing SCP and/or SSH across a collections of machines sequentially"
    echo
    echo "Options:"
    echo "  -s|--settings-file  Path to settings"
    echo
    echo
    echo "This script can be used in at least three different ways."
    echo "  1. Callers can 'bash' execute the script itself providing a parameter settings files."
    echo "      This is the best technique for cron."
    echo
    echo "  2. Callers can 'export' the required vars and then 'bash' execute OR 'source' this."
    echo
    echo "  3. Callers can 'source' this file, assign the required variables, then invoke desired"
    echo "      methods directly. Callers should first ensure that REMOTE_USER is either not set"
    echo "      or an empty string before using this method. A simple REMOTE_USER= assignment OR"
    echo "      a [[ -z REMOTE_USER ]] precondition should be sufficient."
    echo
}

# Parse script parameters
parse_args()
{
    while [[ "$#" -gt 0 ]]
        do

        # Output parameters to facilitate troubleshooting
        echo "Option $1 set with value $2"

        case "$1" in
            -s|--settings-file)
                SETTINGS_FILE=$2
                shift # argument
                ;;
            -h|--help)
                help
                exit 2
                ;;
            *) # unknown option
                echo "ERROR. Option -${BOLD}$2${NORM} not allowed."
                help
                exit 2
                ;;
        esac

        shift # argument
    done
}

source_wrapper()
{
    if [[ -f "$1" ]]
    then
        echo "Sourcing file $1"
        source "$1"
    else
        echo "Cannot find file at $1"
        help
        exit 1
    fi
}

# These functions "return" the first "false" response via $? by immediately exiting the function.
valid_scp_settings()
{
    [[ -n $DESTINATION_MACHINES_LIST ]] || return
    (( ${#DESTINATION_MACHINES_LIST[@]} > 0 )) || return

    [[ -n $PATHS_TO_COPY_LIST ]] || return
    (( ${#PATHS_TO_COPY_LIST[@]} > 0 )) || return

    [[ -n $REMOTE_USER ]] || return
    [[ -n $DESTINATION_DIRECTORY ]] || return

    true
}
valid_ssh_settings()
{
    [[ -n $DESTINATION_MACHINES_LIST ]] || return
    (( ${#DESTINATION_MACHINES_LIST[@]} > 0 )) || return

    [[ -n $REMOTE_USER ]] || return
    [[ -n $REMOTE_COMMAND ]] || return
    [[ -n $REMOTE_ARGUMENTS ]] || return

    true
}

scp_wrapper()
{
    if valid_scp_settings ; then
        # Iterate over target machines
        for destinationHost in "${DESTINATION_MACHINES_LIST[@]}" ; do
            # Iterate over source path for copy
            for pathToCopy in "${PATHS_TO_COPY_LIST[@]}" ; do
                scp -r -o "StrictHostKeyChecking=no" \
                    $pathToCopy \
                    $REMOTE_USER@$destinationHost:$DESTINATION_DIRECTORY
            done
        done
    else
        help_scp
    fi
}

ssh_cmd_wrapper()
{
    if valid_ssh_settings ; then
        preCommand=""
        parentPath=`dirname $REMOTE_COMMAND`
        if [[ "$parentPath" != "." ]] ; then
            # The command is a path to a script.
            # Let's update working directory and configure permissions accordingly.
            preCommand="cd $parentPath && sudo chmod 755 $REMOTE_COMMAND && "
        fi

        for destinationHost in "${DESTINATION_MACHINES_LIST[@]}" ; do
            ssh -o "StrictHostKeyChecking=no" \
                $REMOTE_USER@$destinationHost \
                "$preCommand $REMOTE_COMMAND $REMOTE_ARGUMENTS"
        done
    else
        help_ssh
    fi
}

#todo:

scp_wrapper

ssh_cmd_wrapper
