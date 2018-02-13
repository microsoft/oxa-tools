#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# Export all bash variable assignments (for use by sub-processes)
# Immmediately exit on error
set -ae

# static strings
readonly MSFT="microsoft"
readonly EDX="edx"
readonly USE_MSFT="useMsftRepo"
readonly TAGS="tags/"
readonly FICUS="${TAGS}open-release/ficus.1"
readonly GINKGO="${TAGS}open-release/ginkgo.2"
readonly FS="fullstack"
readonly DS="devstack"

##########################
# Script Defaults that can be overriden via
# - parameter arguments OR
# - assignment here
##########################

TEMPLATE_TYPE=$FS       # fullstack or devstack
BRANCH_VERSIONS=edge    # edge or release or stable or edx
DEFAULT_PASSWORD=
MSFT_AUTH=

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
EDXAPP_ENABLE_THIRD_PARTY_AUTH=

# The upstream tag in common with our forks
# is ficus1 (edx-platform and configuration)
EDX_BRANCH=$FICUS

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

        # convert to lowercase
        case "${1,,}" in
          -r|--role|-s|--stack)
            # convert to lowercase
            TEMPLATE_TYPE=`parse_template "${arg_value,,}"`
            ;;
          -b|--branches|--branch)
            # convert to lowercase
            BRANCH_VERSIONS=`parse_branch "${arg_value,,}"`
            ;;
          -d|--default-password)
            DEFAULT_PASSWORD="${arg_value}"
            ;;
          --msft-oauth|--msft-auth)
            # convert to lowercase
            MSFT_AUTH="${arg_value,,}"
            ;;
          *)
            # Unknown option encountered
            echo "Option '${BOLD}$1${NORM} ${arg_value}' not allowed."
            exit 1
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
            echo "$FS"
        ;;
        dev|ds|d)
            echo "$DS"
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
        pre|beta|int)
            echo "release"
        ;;
        development|dev|bvt)
            echo "edge"
        ;;
        ficus|up|ed|f|edx_ficus|edx|upstream)
            echo "edx_f"
        ;;
        ginkgo|up_g|ed_g|g|edx_ginkgo)
            echo "edx_g"
        ;;
        *)
            # no additional mappings for edx_master (at this time)
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

    case "$BRANCH_VERSIONS" in
        edx_f|edx_g|edx_master)
            EDXAPP_ENABLE_COMPREHENSIVE_THEMING=false
            COMBINED_LOGIN_REGISTRATION=true
            NGINX_SITES='[certs, cms, lms, forum, xqueue]'

            if [[ $BRANCH_VERSIONS == edx_g ]] ; then
                EDX_BRANCH=$GINKGO
            elif [[ $BRANCH_VERSIONS == edx_master ]] ; then
                EDX_BRANCH=master
            fi

            # The upstream doesn't have the relevant
            # changes to leverage MYSQL_ADMIN_PASSWORD
            # For details, see msft/edx-configuration commit:
            # 65e2668672bda0112a64aabb86cf532ad228c4fa
            MYSQL_ADMIN_USER=root
            MYSQL_ADMIN_PASSWORD=
        ;;
        *)
            EDXAPP_ENABLE_COMPREHENSIVE_THEMING=true
            COMBINED_LOGIN_REGISTRATION=false
            # Microsoft repositories support the lms-preview subdomain.
            NGINX_SITES='[certs, cms, lms, lms-preview, forum, xqueue]'

            MYSQL_ADMIN_USER=lexoxamysqladmin
            MYSQL_ADMIN_PASSWORD=`harden $MYSQL_ADMIN_PASSWORD`
        ;;
    esac

    case "$MSFT_AUTH" in
        prod|int)
            EDXAPP_ENABLE_THIRD_PARTY_AUTH=true
        ;;
        *)
            EDXAPP_ENABLE_THIRD_PARTY_AUTH=false
        ;;
    esac
}

test_args()
{
    if [[ $TEMPLATE_TYPE != $FS ]] && [[ $TEMPLATE_TYPE != $DS ]] ; then
        set +x
        echo -e "\033[1;36m"
        echo -e "\n TEMPLATE_TYPE is set to $TEMPLATE_TYPE"
        echo -e " but should be $FS or $DS."
        echo -e " Use the -r param argument.\n"
        echo -e '\033[0m'
        exit 1
    fi

    echo -e "\n BRANCH_VERSIONS is set to $BRANCH_VERSIONS"
    case "$BRANCH_VERSIONS" in
        stable|release|edge|edx_f|edx_g|edx_master)
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
    override=$1

    if [[ $BRANCH_VERSIONS == stable ]] ; then
        echo "oxa/master.fic"
    elif [[ $BRANCH_VERSIONS == release ]] ; then
        echo "oxa/release.fic"
    elif [[ $BRANCH_VERSIONS == edge ]] || [[ $override == $USE_MSFT ]] ; then
        echo "oxa/dev.fic"
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
        branchInfo=`get_branch $USE_MSFT`
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
        edx_f|edx_g|edx_master)
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
        edx_f|edx_g|edx_master)
            echo "configuration"
        ;;
        *)
            echo "edx-configuration"
        ;;
    esac
}

wget_wrapper()
{
    local expectedPath="$1"
    local org="$2"
    local project="$3"
    local branch="$4"

    # Check if the file exists. If not, download from the public repository
    if [[ -f "$expectedPath" ]] ; then
        echo "$expectedPath"
    else
        local fileName=`basename $expectedPath`
        if [[ ! -f "$fileName" ]] ; then
            wget -q https://raw.githubusercontent.com/${org}/${project}/${branch}/$expectedPath -O $fileName
        fi

        echo "$fileName"
    fi
}

##########################
# Core Installation Operation
##########################

install-with-oxa()
{
    bootstrap=`wget_wrapper "scripts/bootstrap.sh" "${MSFT}" "oxa-tools" "$(get_current_branch)"`

    bash $bootstrap \
        --role \
            $TEMPLATE_TYPE \
        --retry-count \
            8 \
        --environment \
            "dev" \
        --msft-oauth \
            $MSFT_AUTH \
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
            `get_branch $USE_MSFT` \
        --edxversion \
            $EDX_BRANCH \
        --forumversion \
            `get_branch` \
        --azure-media-version \
            `get_branch $USE_MSFT` \
        --kitchen-sink-course-version \
            `get_branch $USE_MSFT`
}

devstack_preconditions()
{
    sandbox_path=$1

    if [[ $TEMPLATE_TYPE == $DS ]]; then
        # Use devstack playbook
        chmod 777 $sandbox_path
        sed -i "s|edx_sandbox|vagrant-devstack|g" $sandbox_path

        # Create required vagrant user account to avoid fatal error
        if ! id -u vagrant > /dev/null 2>&1 ; then
            adduser --disabled-password --gecos "" vagrant
        fi

        # Set the vagrant password
        if [[ -n $VAGRANT_USER_PASSWORD ]] ; then
            usermod --password $(echo $VAGRANT_USER_PASSWORD | openssl passwd -1 -stdin) vagrant
        fi

        # Devstack installs specific versions of chrome and firefox
        remove_browsers
    fi
}

install-with-edx-native()
{
    # from https://openedx.atlassian.net/wiki/spaces/OpenOPS/pages/146440579/Native+Open+edX+Ubuntu+16.04+64+bit+Installation

    # 1. Set the OPENEDX_RELEASE variable:
    OPENEDX_RELEASE=${EDX_BRANCH#$TAGS}

    # 2. Bootstrap the Ansible installation:
    local ans_bootstrap=`wget_wrapper "util/install/ansible-bootstrap.sh" "${EDX}" "$(get_conf_project_name)" "$OPENEDX_RELEASE"`
    sudo bash $ans_bootstrap

    # 3. (Optional) If this is a new installation, randomize the passwords:
    # todo: reconcile this w/ -d and /oxa/oxa.yml
    local gen_pass=`wget_wrapper "util/install/generate-passwords.sh" "${EDX}" "$(get_conf_project_name)" "$OPENEDX_RELEASE"`
    bash $gen_pass

    # 3b Enable retry
    local utilities=`wget_wrapper "templates/stamp/utilities.sh" "${MSFT}" "oxa-tools" "$(get_current_branch)"`
    source $utilities

    # 4. Install Open edX:
    local sandbox=`wget_wrapper "util/install/sandbox.sh" "${EDX}" "$(get_conf_project_name)" "$OPENEDX_RELEASE"`
    devstack_preconditions $sandbox
    set +e
    retry-command "bash $sandbox" 8 "$sandbox" "fixPackages"
    set -e

    # get status of edx services
    /edx/bin/supervisorctl status || true
}

##########################
# Execution Starts
##########################

echo "installing pwgen, wget, ssh..."
apt update -qq
apt install -y -qq pwgen wget ssh

parse_args "$@"

test_args

set_dynamic_vars

set -x
# We currently use sandbox.sh for ginkgo+. Therefore, it doesn't have our customizations.
#  - (fullstack) This is because vagrant-fullstack.yml was removed in March 2017 and
#  - (devstack) Something about our customizations result in an "elastic search" error
if [[ $BRANCH_VERSIONS == edx_g ]] || [[ $BRANCH_VERSIONS == edx_master ]] ; then
    install-with-edx-native
else
    install-with-oxa
fi
