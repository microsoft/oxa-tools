#!/usr/bin/env bash
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# Every nine minutes
seconds=$((9 * 60))
message="Ah, ha, ha, ha, stayin' alive, stayin' alive"

for (( a=1; a<=5; a++ )) ; do
    echo "$message"
    sleep $seconds
done

echo "$message"
