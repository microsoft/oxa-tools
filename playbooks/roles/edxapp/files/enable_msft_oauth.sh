#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

set -ex

msft_auth=$1
edx_platform_path=$2
oxa_tools_path=$3
email=$4

src_utils()
{
    pushd $oxa_tools_path

    echo "source utilities"
    source templates/stamp/utilities.sh

    popd
}

fix_platform()
{
    pushd $edx_platform_path

    log "cherry-pick change to support MSA"

    count=`grep -i "live" lms/envs/aws.py | wc -l`
    if (( "$count" == 0 )) ; then
        log "Ensure remote has commit"
        count=`git remote | grep "msft_plat" | wc -l`
        if (( "$count" == 0 )) ; then
            git remote add msft_plat https://github.com/microsoft/edx-platform.git
        fi
        git fetch msft_plat > /dev/null 2>&1

        # Ficus Fix
        hash=86a53b8353ac76fbb761d4fa465bc0f363e264b3

        # Ginkgo fix
        count=`grep -i "social_core" lms/envs/aws.py | wc -l`
        if (( "$count" > 0 )) ; then
            hash=dd939e404c9f762b71eabb67f3340c14ba5ba9c3
        fi

        cherry_pick_wrapper $hash "$email"
    fi

    pushd ../venvs/edxapp/lib

    log "update urls for int"
    if [[ $msft_auth == int ]] ; then
        find . -name 'live.py' -type f -exec sed -i 's/login\.live\./login\.live\-int\./' {} \;
    fi

    popd
    popd
}

##########################
# Execution Starts
##########################

src_utils
fix_platform

# This command won't succeed on devstack. Which is totally fine.
set +e
sudo /edx/bin/supervisorctl restart edxapp || true
