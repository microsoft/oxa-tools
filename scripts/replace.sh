#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.
if [  $# -eq 2 ]
    then
        OIFS=$IFS IFS="=";
	while read -r key value; do
    	    case "$key" in
      		'#'*) ;;
      		*)
        	    sed -i "s/%%$key%%/$value/g" $2
    	    esac
	done < $1;
        IFS=$OIFS
    else
	echo -e "\nUsage:\n$0 <secrets file> <target file> \n"
        exit 1
fi
