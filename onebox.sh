#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# Export all bash variable assignments (for use by sub-processes)
# Write all commands to the console
# Immmediately exit on error
set -axe

readonly MSFT="microsoft"

##########################
# Script Defaults that can be overriden via
# - parameter arguments OR
# - assignment here
##########################
TEMPLATE_TYPE=fullstack # fullstack or devstack
BRANCH_VERSIONS=edge    # edge or release or stable or edx
DEFAULT_PASSWORD=

##########################
# Settings
##########################
readonly MONGO_USER=oxamongoadmin
MONGO_PASSWORD=

# dynamically assigned below
MYSQL_ADMIN_USER=
MYSQL_ADMIN_PASSWORD=

readonly MYSQL_USER=oxamysql
MYSQL_PASSWORD=

readonly EDXAPP_SU_USERNAME=edx_admin
EDXAPP_SU_PASSWORD=

readonly BASE_URL=$HOSTNAME
readonly LMS_URL=$BASE_URL # vanity
readonly CMS_URL=$BASE_URL
readonly PREVIEW_URL=$BASE_URL
readonly PLATFORM_NAME="$MSFT Learning on $HOSTNAME"
readonly EDXAPP_IMPORT_KITCHENSINK_COURSE=true
readonly EDXAPP_ENABLE_THIRD_PARTY_AUTH=false
readonly NGINX_ENABLE_SSL=false
readonly EDXAPP_SU_EMAIL="${EDXAPP_SU_USERNAME}@${MSFT}.com"
readonly PLATFORM_EMAIL="$EDXAPP_SU_EMAIL"

# The common tag in the upstream to our fork is open-release/ficus.1
# Specifically: our forks of edx-platform and configuration
readonly EDX_BRANCH="tags/open-release/ficus.1"

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
          -r|--role|-s|--stack)
            TEMPLATE_TYPE="${arg_value,,}" # convert to lowercase
            ;;
          -b|--branches)
            BRANCH_VERSIONS="${arg_value,,}" # convert to lowercase
            ;;
          -d|--default-password)
            DEFAULT_PASSWORD="${arg_value}"
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
    # Allow for synonyms
    if [[ $TEMPLATE_TYPE == full ]] || [[ $TEMPLATE_TYPE == fs ]] || [[ $TEMPLATE_TYPE == f ]] ; then
        TEMPLATE_TYPE=fullstack
    elif [[ $TEMPLATE_TYPE == dev ]] || [[ $TEMPLATE_TYPE == ds ]] || [[ $TEMPLATE_TYPE == d ]] ; then
        TEMPLATE_TYPE=devstack
    fi

    # Allow for synonyms
    if [[ $BRANCH_VERSIONS == production ]] || [[ $BRANCH_VERSIONS == prod ]] || [[ $BRANCH_VERSIONS == master ]]; then
        BRANCH_VERSIONS=stable
    elif [[ $BRANCH_VERSIONS == pre ]] || [[ $BRANCH_VERSIONS == bvt ]] || [[ $BRANCH_VERSIONS == int ]] ; then
        BRANCH_VERSIONS=release
    elif [[ $BRANCH_VERSIONS == development ]] || [[ $BRANCH_VERSIONS == dev ]] || [[ $BRANCH_VERSIONS == beta ]] ; then
        BRANCH_VERSIONS=edge
    elif [[ $BRANCH_VERSIONS == upstream ]] || [[ $BRANCH_VERSIONS == up ]] || [[ $BRANCH_VERSIONS == ed ]] ; then
        BRANCH_VERSIONS=edx
    fi

    # Harden credentials if none were provided.
    set +x
    MONGO_PASSWORD=`harden $MONGO_PASSWORD`
    MYSQL_PASSWORD=`harden $MYSQL_PASSWORD`
    EDXAPP_SU_PASSWORD=`harden $EDXAPP_SU_PASSWORD`
    VAGRANT_USER_PASSWORD=$EDXAPP_SU_PASSWORD

    #todo: remove second condition after edx-configuration merge to releae,master
    # The upstream doesn't have the relevant
    # changes to leverage MYSQL_ADMIN_PASSWORD
    # For details, see msft/edx-configuration commit:
    # 65e2668672bda0112a64aabb86cf532ad228c4fa
    if [[ $BRANCH_VERSIONS == edx ]] || [[ $BRANCH_VERSIONS != edge ]]; then
        MYSQL_ADMIN_USER=root
        MYSQL_ADMIN_PASSWORD=
    else
        MYSQL_ADMIN_USER=lexoxamysqladmin
        MYSQL_ADMIN_PASSWORD=`harden $MYSQL_ADMIN_PASSWORD`
    fi
    set -x
}

test_args()
{
    if [[ $TEMPLATE_TYPE != fullstack ]] && [[ $TEMPLATE_TYPE != devstack ]] ; then
        set +x
        echo -e "\033[1;36m"
        echo -e "\n TEMPLATE_TYPE is set to $TEMPLATE_TYPE"
        echo -e " but should be fullstack or devstack."
        echo -e " Use the -r param argument.\n"
        echo -e '\033[0m'
        exit 1
    fi

    if [[ $BRANCH_VERSIONS != stable ]] && [[ $BRANCH_VERSIONS != release ]] && [[ $BRANCH_VERSIONS != edge ]] && [[ $BRANCH_VERSIONS != edx ]] ; then
        set +x
        echo -e "\033[1;36m"
        echo -e "\n BRANCH_VERSIONS is set to $BRANCH_VERSIONS"
        echo -e " but should be stable OR release OR edge OR edx .\n"
        echo -e " Use the -b param argument.\n"
        echo -e '\033[0m'
        exit 1
    fi
}

##########################
# Helpers
##########################
get_branch()
{
    useMsftRepo=$1
    useOldDevStyle=$2

    if [[ $BRANCH_VERSIONS == stable ]] ; then
        echo "oxa/master.fic"
    elif [[ $BRANCH_VERSIONS == release ]] ; then
        echo "oxa/release.fic"
    elif [[ $BRANCH_VERSIONS == edge ]] || [[ -n $useMsftRepo ]] ; then
        if [[ -n $useOldDevStyle ]] ; then
            # Legacy switch
            echo "oxa/devfic"
        else
            echo "oxa/dev.fic"
        fi
    elif [[ $BRANCH_VERSIONS == edx ]] ; then
        echo "$EDX_BRANCH"
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
        branchInfo=`get_branch useMsftRepo oldDevStyle`
    fi

    echo "$branchInfo"
}

harden()
{
    originalString=$1

    # Is the current password insecure?
    if [[ -z $originalString ]] ; then
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
        echo $originalString
    fi
}

get_org()
{
    if [[ $BRANCH_VERSIONS == edx ]] ; then
        echo "$BRANCH_VERSIONS"
    else
        echo "$MSFT"
    fi
}

get_conf_project_name()
{
    if [[ $BRANCH_VERSIONS == edx ]] ; then
        echo "configuration"
    else
        echo "edx-configuration"
    fi
}

update_nginx_sites()
{
    if [[ $BRANCH_VERSIONS == edx ]] ; then
        NGINX_SITES='[certs, cms, lms, forum, xqueue]'
    else
        # Microsoft repositories support the lms-preview subdomain.
        NGINX_SITES='[certs, cms, lms, lms-preview, forum, xqueue]'
    fi
}


##########################
# Execution Starts
##########################

echo "installing pwgen and wget..."
apt update -qq
apt install -y -qq pwgen wget

parse_args "$@"
fix_args
test_args

update_nginx_sites

# get current dir
CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
bootstrap="scripts/bootstrap.sh"
if [[ ! -f scripts/bootstrap.sh ]] ; then
    fileName=`basename $bootstrap`
    wget -q https://raw.githubusercontent.com/${MSFT}/oxa-tools/$(get_current_branch)/$bootstrap -O $fileName
    bootstrap=$fileName
fi

bash $bootstrap \
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
        `get_conf_project_name` \
    --edxconfiguration-public-github-projectbranch \
        `get_branch` \
    --edxplatform-public-github-accountname \
        `get_org` \
    --edxplatform-public-github-projectbranch \
        `get_branch` \
    --edxtheme-public-github-projectbranch \
        `get_branch useMsftRepo` \
    --edxversion \
        $EDX_BRANCH \
    --forumversion \
        $EDX_BRANCH
