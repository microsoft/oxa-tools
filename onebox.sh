#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# Export all bash variable assignments (for use by sub-processes)
# Write all commands to the console
# Immmediately exit on error
set -axe

default=insecureDefault

##########################
# Script Defaults that can be overriden via parameter arguments OR assignment here
##########################
TEMPLATE_TYPE=fullstack # or devstack
branch_versions=edge # or stable

MONGO_USER=oxamongoadmin
MONGO_PASSWORD=$default

MYSQL_ADMIN_USER=root
MYSQL_ADMIN_PASSWORD=

MYSQL_USER=oxamysql
MYSQL_PASSWORD=$default

EDXAPP_SU_USERNAME=edx_admin
EDXAPP_SU_PASSWORD=$default

##########################
# Settings
##########################
BASE_URL=$HOSTNAME
LMS_URL=$BASE_URL # vanity
CMS_URL=$BASE_URL
PREVIEW_URL=$BASE_URL
PLATFORM_NAME="Microsoft Learning on $HOSTNAME"
EDXAPP_IMPORT_KITCHENSINK_COURSE=true
EDXAPP_ENABLE_THIRD_PARTY_AUTH=false
EDXAPP_SU_EMAIL="${EDXAPP_SU_USERNAME}@microsoft.com"
PLATFORM_EMAIL="$EDXAPP_SU_EMAIL"
VAGRANT_USER_PASSWORD=$EDXAPP_SU_PASSWORD

##########################
# Script Parameter Arguments
##########################
parse_args() 
{
    while [[ "$#" -gt 0 ]]
    do
        arg_value="${2}"
        shift_once=0

        if [[ "${arg_value}" =~ "--" ]] ; then
            arg_value=""
            shift_once=1
        fi

         # Log input parameters to facilitate troubleshooting
        echo "Option '${1}' set with value '"${arg_value}"'"

        case "$1" in
          -r|--role)
            TEMPLATE_TYPE="${arg_value}"
            ;;
          -b|--branches)
            branch_versions="${arg_value}"
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
          --edxapp-su-username)
            EDXAPP_SU_USERNAME="${arg_value}"
            ;;
          --edxapp-su-password)
            EDXAPP_SU_PASSWORD="${arg_value}"
            ;;
          *)
            # Unknown option encountered
            echo "Option '${BOLD}$1${NORM} ${arg_value}' not allowed."
            display_usage
            ;;
        esac

        shift # past argument or value

        if [[ $shift_once -eq 0 ]] ; then
            shift # past argument or value
        fi

    done
}
test_args()
{
    if [[ $TEMPLATE_TYPE != fullstack ]] && [[ $TEMPLATE_TYPE != devstack ]] ; then
        echo "TEMPLATE_TYPE is set to $TEMPLATE_TYPE"
        echo "but should be fullstack or devstack"
        exit 1
    fi

    if [[ $branch_versions != stable ]] && [[ $branch_versions != edge ]] ; then
        echo "branch_versions is set to $branch_versions"
        echo "but should be stable or edge"
        exit 1
    fi

    set +x
    echo "`warning $MONGO_PASSWORD MONGO_PASSWORD`"
    echo "`warning $MYSQL_ADMIN_PASSWORD MYSQL_ADMIN_PASSWORD`"
    echo "`warning $MYSQL_PASSWORD MYSQL_PASSWORD`"
    echo "`warning $EDXAPP_SU_PASSWORD EDXAPP_SU_PASSWORD`"
    set -x
}

##########################
# Helpers
##########################
get_branch()
{
    if [[ $branch_versions == stable ]] ; then
        echo "oxa/master.fic"
    elif [[ $branch_versions == edge ]] ; then
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
get_current_branch()
{
    prefix='* '

    # Current branch is prefixed with an asterisk. Remove it.
    branchInfo=`git branch | grep "$prefix" | sed "s/$prefix//g"`

    # Ensure branch information is useful.
    if [[ -z "$branchInfo" ]] || [[ $branchInfo == *"no branch"* ]] || [[ $branchInfo == *"detached"* ]] ; then
        branchInfo="`get_branch "oldStyle"`"
    fi

    echo "$branchInfo"
}
warning()
{
    if [[ -z $1 ]] || [[ $1 == $default ]] ; then
        echo -e "\n\nPlease provide a $2 value if deploying to publicly available instance\n\n"
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
#todo: admin in bootstrap
#todo: switch plat to get_branch before merging.
bash scripts/bootstrap.sh \
    --role \
        $TEMPLATE_TYPE \
    --retry-count \
        5 \
    --environment \
        "dev" \
    --oxatools-public-github-projectbranch \
        `get_current_branch` \
    --edxconfiguration-public-github-accountname \
        `get_org` \
    --edxconfiguration-public-github-projectname \
        "edx-configuration" \
    --edxconfiguration-public-github-projectbranch \
        `get_branch` \
    --edxplatform-public-github-accountname \
        `get_org` \
    --edxplatform-public-github-projectbranch \
        `get_current_branch` \
    --edxtheme-public-github-projectbranch \
        `get_branch` \
    --edxversion \
        `get_upstream_branch` \
    --forumversion \
        `get_upstream_branch`
