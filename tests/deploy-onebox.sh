#!/usr/bin/env bash
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

set -eo pipefail

# Determine the appropriate github branch to clone
get_branch()
{
    prefix='* '

    # Current branch is prefixed with an asterisk. Remove it.
    branchInfo=`git branch | grep "$prefix" | sed "s/$prefix//g"`

    # Ensure branch information is useful.
    if [[ -z "$branchInfo" ]] || [[ $branchInfo == *"no branch"* ]] || [[ $branchInfo == *"detached"* ]] ; then
        branchInfo="master"
    fi

    echo "$branchInfo"
}

get_repo()
{
    repoInfo=$(git config --get remote.origin.url)

    # Convert ssh repo url into https
    if echo $repoInfo | grep "@.*:.*/" > /dev/null 2>&1 ; then
        echo $repoInfo | tr @ "\n" | tr : / | tail -1
        return
    fi

    echo "$repoInfo"
}

ONEBOX_PARAMS="--branch edx_master --role fullstack"
BRANCH=$(get_branch)
REPO=$(get_repo)
FOLDER=$(basename $REPO .git)
echo "BRANCH=$BRANCH, REPO=$REPO, FOLDER=$FOLDER, ONEBOX_PARAMS=$ONEBOX_PARAMS"


# keep alive
bash ./tests/keep-alive.sh &

# Connect to container
docker exec -i stepdo0 /bin/bash -s <<EOF

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
if git clone --quiet --depth=50 --branch=$BRANCH https://${REPO} ; then
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
