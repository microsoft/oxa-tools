#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# Export all bash variable assignments
# Write all commands to the console
# Immmediately exit on error
set -axe

##########################
# Script Defaults that can be overriden via parameter arguments OR assignment here)
##########################
role=fullstack # or devstack
branch_versions=stable_release # or development_edge
VAGRANT_USER_PASSWORD=
MONGO_USER=
MONGO_PASSWORD=
MYSQL_ADMIN_USER=
MYSQL_ADMIN_PASSWORD=
MYSQL_USER=
MYSQL_PASSWORD=

##########################
# Settings
##########################
BASE_URL=$HOSTNAME
LMS_URL=$BASE_URL # vanity
CMS_URL=$BASE_URL
PREVIEW_URL=$BASE_URL
PLATFORM_NAME="Microsoft Learning"
EDXAPP_IMPORT_KITCHENSINK_COURSE=true

##########################
# Script Parameter Arguments
##########################
parse_args() 
{
    while [[ "$#" -gt 0 ]]
    do
        arg_value="${2}"
        shift_once=0

        if [[ "${arg_value}" =~ "--" ]]; 
        then
            arg_value=""
            shift_once=1
        fi

         # Log input parameters to facilitate troubleshooting
        echo "Option '${1}' set with value '"${arg_value}"'"

        case "$1" in
          -r|--role)
            role="${arg_value}"
            ;;
          -b|--branches)
            branch_versions="${arg_value}"
            ;;
          --vagrant-pasword)
            VAGRANT_USER_PASSWORD="${arg_value}"
            ;;
          --mongo-user)
            MONGO_USER="${arg_value}"
            ;;
          --mongo-password)
            MONGO_PASSWORD="${arg_value}"
            ;;
          --mysql-admin-user)
            MYSQL_ADMIN_USER="${arg_value}"
            ;;
          --mysql-admin-password)
            MYSQL_ADMIN_PASSWORD="${arg_value}"
            ;;
          --mysql-user)
            MYSQL_USER="${arg_value}"
            ;;
          --mysql-password)
            MYSQL_PASSWORD="${arg_value}"
            ;;
          *)
            # Unknown option encountered
            echo "Option '${BOLD}$1${NORM} ${arg_value}' not allowed."
            display_usage
            ;;
        esac

        shift # past argument or value

        if [ $shift_once -eq 0 ]; 
        then
            shift # past argument or value
        fi

    done
}
test_args()
{
    if [[ $role != fullstack ]] && [[ $role != devstack ]] ; then
        echo "role is set to $role"
        echo "but should be fullstack or devstack"
        exit 1
    fi

    if [[ $branch_versions != stable_release ]] && [[ $branch_versions != development_edge ]] ; then
        echo "branch_versions is set to $branch_versions"
        echo "but should be stable_release or development_edge"
        exit 1
    fi

    warning $VAGRANT_USER_PASSWORD VAGRANT_USER_PASSWORD
    warning $MONGO_USER MONGO_USER
    warning $MONGO_PASSWORD MONGO_PASSWORD
    warning $MYSQL_ADMIN_USER MYSQL_ADMIN_USER
    warning $MYSQL_ADMIN_PASSWORD MYSQL_ADMIN_PASSWORD
    warning $MYSQL_USER MYSQL_USER
    warning $MYSQL_PASSWORD MYSQL_PASSWORD
}

##########################
# Helpers
##########################
get_branch()
{
    if [[ $branch_versions == stable_release ]] ; then
        echo "oxa/master.fic"
    elif [[ $branch_versions == stable_release ]] ;
        if [[ -n $1 ]] ; then
            # Legacy switch
            echo "oxa/devfic"
        else
            echo "oxa/dev.fic"
        fi
    else
        test_args
    fi
}
get_upstream_branch()
{
    echo "open-release/ficus.master"
}
warning()
{
    if [[ -z $1 ]] ; then
        echo "Please provide a $2 value if deploying to publicly available instance"
    fi
}
get_org()
{
    echo "Microsoft"
}

##########################
# Execution Starts
##########################
parse_args "$@"
test_args

#todo: get current dir
bootstrap.sh \
    --role \
        $role \
    --retry-count \
        5 \
    --environment \
        "dev" \
    \
    --oxatools-public-github-projectbranch \
        `get_branch "oldStyle"` \
    \
    --edxconfiguration-public-github-accountname \
        `get_org` \
    --edxconfiguration-public-github-projectname \
        "edx-configuration"
    --edxconfiguration-public-github-projectbranch \
        `get_branch` \
    \
    --edxplatform-public-github-accountname \
        `get_org` \
    --edxplatform-public-github-projectbranch \
        `get_branch` \
    \
    --edxtheme-public-github-projectbranch \
        `get_branch` \
    \
    --edxversion \
        `get_upstream_branch` \
    --forumversion \
        `get_upstream_branch`
