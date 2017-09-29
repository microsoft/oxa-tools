#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# Export all bash variable assignments (for use by sub-processes)
# Write all commands to the console
# Immmediately exit on error
set -axe

readonly MSFT="microsoft"
readonly EDX="edx"

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
readonly EDXAPP_COMPREHENSIVE_THEME_DIRS='[ "/edx/app/edxapp/themes" ]'
readonly EDXAPP_DEFAULT_SITE_THEME=comprehensive

##########################
# Dynamic settings. Assigned later on based on onebox.sh param arguments.
##########################

MYSQL_ADMIN_USER=
MYSQL_ADMIN_PASSWORD=
EDXAPP_ENABLE_COMPREHENSIVE_THEMING=
COMBINED_LOGIN_REGISTRATION=
NGINX_SITES=

# The common tag in the upstream to our
# forks (edx-platform and configuration)
# is ficus.1
EDX_BRANCH="tags/open-release/ficus.1"

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
            # convert to lowercase
            TEMPLATE_TYPE=`parse_template "${arg_value,,}"`
            ;;
          -b|--branches)
            # convert to lowercase
            BRANCH_VERSIONS=`parse_branch "${arg_value,,}"`
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

parse_template()
{
    userInput="$1"

    case "$userInput" in
        full|fs|f)
            echo "fullstack"
        ;;
        dev|ds|d)
            echo "devstack"
        ;;
        *)
            echo "$userInput"
        ;;
    esac
}

parse_branch()
{
    userInput="$1"

    case "$userInput" in
        production|prod|master)
            echo "stable"
        ;;
        pre|bvt|int)
            echo "release"
        ;;
        development|dev|beta)
            echo "edge"
        ;;
        ficus|up|ed|f|edx_ficus|edx|upstream)
            echo "edx_f"
        ;;
        ginkgo|up_g|ed_g|g|edx_ginkgo)
            echo "edx_g"
        ;;
        *)
            echo "$userInput"
        ;;
    esac
}

set_dynamic_vars()
{
    # Harden credentials if none were provided.
    set +x
    MONGO_PASSWORD=`harden $MONGO_PASSWORD`
    MYSQL_PASSWORD=`harden $MYSQL_PASSWORD`
    EDXAPP_SU_PASSWORD=`harden $EDXAPP_SU_PASSWORD`
    VAGRANT_USER_PASSWORD=$EDXAPP_SU_PASSWORD

    # The upstream doesn't have the relevant
    # changes to leverage MYSQL_ADMIN_PASSWORD
    # For details, see msft/edx-configuration commit:
    # 65e2668672bda0112a64aabb86cf532ad228c4fa
    if [[ $BRANCH_VERSIONS == edge ]]; then
        MYSQL_ADMIN_USER=lexoxamysqladmin
        MYSQL_ADMIN_PASSWORD=`harden $MYSQL_ADMIN_PASSWORD`
    else
        MYSQL_ADMIN_USER=root
        MYSQL_ADMIN_PASSWORD=
    fi
    set -x

    case "$BRANCH_VERSIONS" in
        edx_f|edx_g)
            EDXAPP_ENABLE_COMPREHENSIVE_THEMING=false
            COMBINED_LOGIN_REGISTRATION=true
            NGINX_SITES='[certs, cms, lms, forum, xqueue]'
        ;;
        *)
            EDXAPP_ENABLE_COMPREHENSIVE_THEMING=true
            COMBINED_LOGIN_REGISTRATION=false
            # Microsoft repositories support the lms-preview subdomain.
            NGINX_SITES='[certs, cms, lms, lms-preview, forum, xqueue]'
        ;;
    esac

    if [[ $BRANCH_VERSIONS == edx_g ]] ; then
        EDX_BRANCH="tags/open-release/ginkgo.1"
    fi
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

    echo -e "\n BRANCH_VERSIONS is set to $BRANCH_VERSIONS"
    case "$BRANCH_VERSIONS" in
        stable|release|edge|edx_f|edx_g)
            echo ""
        ;;
        *)
            set +x
            echo -e "\033[1;36m"
            echo -e " but should be stable OR release OR edge OR edx .\n"
            echo -e " Use the -b param argument.\n"
            echo -e '\033[0m'
            exit 1
        ;;
    esac
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
    else
        echo "$EDX_BRANCH"
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
    case "$BRANCH_VERSIONS" in
        edx_f|edx_g)
            echo "$EDX"
        ;;
        *)
            echo "$MSFT"
        ;;
    esac
}

get_conf_project_name()
{
    case "$BRANCH_VERSIONS" in
        edx_f|edx_g)
            echo "configuration"
        ;;
        *)
            echo "edx-configuration"
        ;;
    esac
}

##########################
# Core Installation Operation
##########################

install-with-oxa()
{
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
            9 \
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
}

install-with-edx-native()
{
    # from https://openedx.atlassian.net/wiki/spaces/OpenOPS/pages/146440579/Native+Open+edX+Ubuntu+16.04+64+bit+Installation

    # 1. Set the OPENEDX_RELEASE variable:
    OPENEDX_RELEASE=$EDX_BRANCH

    # 2. Bootstrap the Ansible installation:
    wget https://raw.githubusercontent.com/${EDX}/$(get_conf_project_name)/$OPENEDX_RELEASE/util/install/ansible-bootstrap.sh -O - | sudo bash

    # 3. (Optional) If this is a new installation, randomize the passwords:
    wget https://raw.githubusercontent.com/${EDX}/$(get_conf_project_name)/$OPENEDX_RELEASE/util/install/generate-passwords.sh -O - | bash

    #todo: 3a link file to /oxa/oxa.yml

    #todo: improve retry
    # 4. Install Open edX:
    set +e
    wget https://raw.githubusercontent.com/${EDX}/$(get_conf_project_name)/$OPENEDX_RELEASE/util/install/sandbox.sh -O sandbox.sh
    bash sandbox.sh || bash sandbox.sh || bash sandbox.sh || bash sandbox.sh || bash sandbox.sh || bash sandbox.sh || bash sandbox.sh || bash sandbox.sh || bash sandbox.sh
}

##########################
# Execution Starts
##########################

echo "installing pwgen and wget..."
apt update -qq
apt install -y -qq pwgen wget

parse_args "$@"

test_args

set_dynamic_vars
 
if [[ $TEMPLATE_TYPE == fullstack ]] && [[ $BRANCH_VERSIONS == edx_g ]] ; then
    install-with-edx-native
else
    install-with-oxa
fi
