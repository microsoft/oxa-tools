#!/usr/bin/env bash
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

set -e

# Determine the appropriate github branch to clone
get_branch()
{
    local branchInfo=

    if [[ -n $CIRCLE_BRANCH ]] ; then
        branchInfo=$CIRCLE_BRANCH
    elif [[ -n $TRAVIS_BRANCH ]] ; then
        branchInfo=$TRAVIS_BRANCH
    elif [[ -n $TRAVIS_PULL_REQUEST_BRANCH ]] ; then
        branchInfo=$TRAVIS_PULL_REQUEST_BRANCH
    else
        branchInfo=$(get_current_branch)

        # Ensure branch information is useful.
        if ! is_valid_branch $branchInfo ; then
            echo "Unable to determine branch for testing"
            exit 1
        fi
    fi

    echo "$branchInfo"
}

get_repo()
{
    local protocol="https://"
    local repoInfo=

    if [[ -n $CIRCLE_PROJECT_USERNAME ]] && [[ $CIRCLE_PROJECT_REPONAME ]] ; then
        repoInfo="${protocol}github.com/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}"
    elif [[ -n $TRAVIS_REPO_SLUG ]] ; then
        repoInfo="${protocol}github.com/${TRAVIS_REPO_SLUG}"
    else
        if [[ -n $CIRCLE_REPOSITORY_URL ]] ; then
            repoInfo="${protocol}${CIRCLE_REPOSITORY_URL}"
        else
            repoInfo=$(git config --get remote.origin.url)
        fi

        # Convert ssh repo into https
        if echo $repoInfo | grep "@.*:.*/" > /dev/null 2>&1 ; then
            repoInfo=$(echo $repoInfo | tr : / | sed "s#git@#${protocol}#g")
        fi
    fi

    echo "$repoInfo"
}

CURRENT_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $CURRENT_SCRIPT_DIR/../templates/stamp/utilities.sh
BRANCH=$(get_branch)

set -o pipefail

REPO=$(get_repo)
FOLDER=$(basename $REPO .git)
CONTAINER_NAME=$(echo "$ONEBOX_PARAMS" | tr -d "-" | tr -d " ")

echo "BRANCH=$BRANCH, REPO=$REPO, FOLDER=$FOLDER"
echo "ONEBOX_PARAMS=$ONEBOX_PARAMS"
echo "CONTAINER_NAME=$CONTAINER_NAME"
echo

# keep alive
bash ./tests/keep-alive.sh &

# Connect to container
docker exec -i $CONTAINER_NAME /bin/bash -s <<EOF

# test systemd
if systemctl > /dev/null ; then
    echo "success: has systemd"
else
    echo "FAILURE: no systemd"
    exit 1
fi

# install git
apt update -qq
if apt install git -y -qq ; then
    echo "success: apt install git"
else
    echo "FAILURE: can't apt install git"
    exit 1
fi

# clone repo
mkdir /oxa
pushd /oxa
if git clone --quiet --depth=50 --branch=$BRANCH ${REPO} ; then
    echo "success: clone repo inside of container"
else
    echo "FAILURE: can't clone repo inside of container"
    exit 1
fi

pushd $FOLDER

# run custom tests
if bash onebox.sh $ONEBOX_PARAMS ; then
    echo "success: onebox deployed"
else
    echo "FAILURE: onebox wasn't deployed"
    exit 1
fi

EOF
