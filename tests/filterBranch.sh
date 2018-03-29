#!/usr/bin/env bash
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

set -e

get_branch()
{
    local branchInfo=

    if [[ -n $CIRCLE_BRANCH ]] ; then
        branchInfo=$CIRCLE_BRANCH
    else
        branchInfo=$(get_current_branch)
    fi

    echo "$branchInfo"
}

get_base_branch()
{
    local baseBranch=

    if [[ -n $CIRCLE_PULL_REQUEST ]] ; then
        # Construct github API url
        local g="github.com"
        local apiURL=$(echo "$CIRCLE_PULL_REQUEST" | sed "s#/$g/#/api.$g/repos/#g" | sed "s#/pull/#/pulls/#g") > /dev/null
        baseBranch=$(curl -sSl $apiURL | jq -r '.base.ref')
    fi

    echo "$baseBranch"
}

branch_in_list()
{
    local branch=$1

    for filter in $ONLY_BRANCHES; do
        if [[ $branch == $filter ]] ; then
            echo
            log "branch in filter"
            return 0
        fi
    done

    return 1
}

CURRENT_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
env
source $CURRENT_SCRIPT_DIR/../templates/stamp/utilities.sh
sudo apt -qq update > /dev/null 2>&1 
sudo apt -qq install -y jq curl > /dev/null 2>&1

echo
log "ONLY_BRANCHES=$ONLY_BRANCHES"

current_branch=$(get_branch)
log "current_branch=$current_branch"
if is_valid_branch $current_branch ; then
    if branch_in_list $current_branch ; then
        exit 0
    fi
fi

base_branch=$(get_base_branch)
log "base_branch=$base_branch"
if is_valid_branch $base_branch ; then
    if branch_in_list $base_branch ; then
        exit 0
    fi
fi

echo
log "branch NOT in filter"
exit 1
