#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

set -ex

msft_auth=$1
edx_platform_path=$2
oxa_tools_path=$3
email=$4

pushd $oxa_tools_path

echo "source utilities"
source templates/stamp/utilities.sh

popd

pushd $edx_platform_path

log "cherry-pick change"
count=`grep -i "live" lms/envs/aws.py | wc -l`
if (( "$count" == 0 )) ; then
    count=`git remote | grep "msft_plat" | wc -l`
    if (( "$count" == 0 )) ; then
        git remote add msft_plat https://github.com/microsoft/edx-platform.git
    fi

    git fetch msft_plat

    #todo: update hash after merge https://github.com/Microsoft/edx-platform/pull/115
    cherry_pick_wrapper 6180813cbbec2fdb8fd9285d886be840d411f735 "$email"
fi

pushd ../venvs/edxapp/lib

log "update urls for int"
if [[ $msft_auth == int ]] ; then
    find . -name 'live.py' -type f -exec sed -i 's/login\.live\./login\.live\-int\./' {} \;
fi

popd
popd

# This command won't succeed on devstack. Which is totally fine.
set +e
sudo /edx/bin/supervisorctl restart edxapp:

true
