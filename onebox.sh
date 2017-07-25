#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# Export all bash variable assignments (for use by sub-processes)
# Write all commands to the console
# Immmediately exit on error
set -axe

readonly DEFAULT_STRING="insecureDefault"

##########################
# Script Defaults that can be overriden via
# - parameter arguments OR
# - assignment here
##########################
TEMPLATE_TYPE=fullstack # or devstack
BRANCH_VERSIONS=edge    # or stable
DEFAULT_PASSWORD=

MONGO_USER=oxamongoadmin
MONGO_PASSWORD=$DEFAULT_STRING

MYSQL_ADMIN_USER=root
MYSQL_ADMIN_PASSWORD=

MYSQL_USER=oxamysql
MYSQL_PASSWORD=$DEFAULT_STRING

EDXAPP_SU_USERNAME=edx_admin
EDXAPP_SU_PASSWORD=$DEFAULT_STRING

##########################
# Settings
##########################
readonly BASE_URL=$HOSTNAME
readonly LMS_URL=$BASE_URL # vanity
readonly CMS_URL=$BASE_URL
readonly PREVIEW_URL=$BASE_URL
readonly PLATFORM_NAME="Microsoft Learning on $HOSTNAME"
readonly EDXAPP_IMPORT_KITCHENSINK_COURSE=true
readonly EDXAPP_ENABLE_THIRD_PARTY_AUTH=false
readonly EDXAPP_SU_EMAIL="${EDXAPP_SU_USERNAME}@microsoft.com"
readonly PLATFORM_EMAIL="$EDXAPP_SU_EMAIL"
readonly EDX_BRANCH="open-release/ficus.master"

##########################
# Script Parameter Arguments
##########################
parse_args() 
{
    while [[ "$#" -gt 0 ]] ; do
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
            TEMPLATE_TYPE="${arg_value,,}" # convert to lowercase
            ;;
          -b|--branches)
            BRANCH_VERSIONS="${arg_value,,}" # convert to lowercase
            ;;
          -d|--default-password)
            DEFAULT_PASSWORD="${arg_value}"
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
            ;;
        esac

        shift # past argument or value

        if [[ $shift_once -eq 0 ]] ; then
            shift # past argument or value
        fi

    done
}
fix_args()
{
    # Harden credentials if none were provided.
    set +x
    MONGO_PASSWORD=`harden $MONGO_PASSWORD`
    #MYSQL_ADMIN_PASSWORD=`harden $MYSQL_ADMIN_PASSWORD`
    MYSQL_PASSWORD=`harden $MYSQL_PASSWORD`
    EDXAPP_SU_PASSWORD=`harden $EDXAPP_SU_PASSWORD`
    VAGRANT_USER_PASSWORD=$EDXAPP_SU_PASSWORD
    set -x

    # Allow for synonyms
    if [[ $TEMPLATE_TYPE == full ]] || [[ $TEMPLATE_TYPE == fs ]] || [[ $TEMPLATE_TYPE == f ]] ; then
        TEMPLATE_TYPE=fullstack
    elif [[ $TEMPLATE_TYPE == dev ]] || [[ $TEMPLATE_TYPE == ds ]] || [[ $TEMPLATE_TYPE == d ]] ; then
        TEMPLATE_TYPE=devstack
    fi

    # Allow for synonyms
    if [[ $BRANCH_VERSIONS == production ]] || [[ $BRANCH_VERSIONS == prod ]] || [[ $BRANCH_VERSIONS == master ]] || [[ $BRANCH_VERSIONS == release ]] ; then
        BRANCH_VERSIONS=stable
    elif [[ $BRANCH_VERSIONS == development ]] || [[ $BRANCH_VERSIONS == dev ]] || [[ $BRANCH_VERSIONS == beta ]] || [[ $BRANCH_VERSIONS == pre ]] || [[ $BRANCH_VERSIONS == int ]] ; then
        BRANCH_VERSIONS=edge
    fi
}
test_args()
{
    if [[ $TEMPLATE_TYPE != fullstack ]] && [[ $TEMPLATE_TYPE != devstack ]] ; then
        echo "TEMPLATE_TYPE is set to $TEMPLATE_TYPE"
        echo "but should be fullstack or devstack"
        exit 1
    fi

    if [[ $BRANCH_VERSIONS != stable ]] && [[ $BRANCH_VERSIONS != edge ]] ; then
        echo "BRANCH_VERSIONS is set to $BRANCH_VERSIONS"
        echo "but should be stable or edge"
        exit 1
    fi
}

##########################
# Helpers
##########################
get_branch()
{
    if [[ $BRANCH_VERSIONS == stable ]] ; then
        echo "oxa/master.fic"
    elif [[ $BRANCH_VERSIONS == edge ]] ; then
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
get_current_branch()
{
    prefix='* '

    # Current branch is prefixed with an asterisk. Remove it.
    branchInfo=`git branch | grep "$prefix" | sed "s/$prefix//g"`

    # Ensure branch information is useful.
    if [[ -z "$branchInfo" ]] || [[ $branchInfo == *"no branch"* ]] || [[ $branchInfo == *"detached"* ]] ; then
        branchInfo="oxa/df_noConfig"
        #todo: switch to get_branch before merging.
        #branchInfo="`get_branch "oldStyle"`"
    fi

    echo "$branchInfo"
}
harden()
{
    # Is the current password insecure?
    if [[ -z $1 ]] || [[ $1 == $DEFAULT_STRING ]] ; then
        if [[ -n $DEFAULT_PASSWORD ]] ; then
            # A default was provided. Use it.
            echo $DEFAULT_PASSWORD
        else
            # No default was provided.
            # Generate a random one (persisted to oxa.yml)
            pwgen -s 33 1
        fi
    else
        # Don't overwrite existing password
        echo $1
    fi
}
get_org()
{
    echo "Microsoft"
}

##########################
# Execution Starts
##########################

echo "installing pwgen and curl..."
apt install -y -qq pwgen curl

parse_args "$@"
fix_args
test_args

# get current dir
CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
bootstrap="scripts/bootstrap.sh"
if [[ ! -f scripts/bootstrap.sh ]] ; then
    curl https://raw.githubusercontent.com/$(get_org)/oxa-tools/$(get_current_branch)/$bootstrap --create-dirs -o $bootstrap
fi

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
        $EDX_BRANCH \
    --forumversion \
        $EDX_BRANCH
