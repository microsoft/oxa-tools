#!/bin/bash

# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# General Variables
ENV_FILE=

source_utilities_functions()
{
    # Working directory should be oxa-tools repo root.
    UTILITIES_FILE=templates/stamp/utilities.sh
    if [ -f $UTILITIES_FILE ];
    then
        # source our utilities for logging, error reporting, and other base functions
        source $UTILITIES_FILE
    else
        echo "Cannot find common utilities file at $UTILITIES_FILE"
        echo "exiting script"
        exit 1
    fi

    log "Sourced functions successfully imported."
}

help()
{
    SCRIPT_NAME=`basename "$0"`

    log "This script $SCRIPT_NAME will backup the database"
    log "Options:"
    log "        --environment-file    Path to settings that are enviornment-specific"
}

# Parse script parameters
parse_args()
{
    while [[ "$#" -gt 0 ]]
        do

         # Log input parameters to facilitate troubleshooting
        log "Option $1 set with value $2"

        case "$1" in
            -e|--environment-file)
                ENV_FILE=$2
                shift # past argument
                ;;
            -h|--help) # Helpful hints
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

source_env_values()
{
    # populate the environment variables
    source $ENV_FILE
    if [ -f $ENV_FILE ];
    then
        # source environment variables.
        source $ENV_FILE
    else
        echo "Cannot find environment variables file at $ENV_FILE"
        echo "exiting script"
        exit 1
    fi

    #todo: these variable aren't currently available outside of this scope function
    #       we'll therefore need to assign them to General variables
}
