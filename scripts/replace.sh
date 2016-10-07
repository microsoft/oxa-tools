#!/bin/bash
if [  $# -eq 2 ] 
    then
	while IFS="=" read -r key value; do
    	    case "$key" in
      		'#'*) ;;
      		*)
        	    sed -i "s/$key/$value/g" $2
    	    esac
	done < $1 
    else
	echo -e "\nUsage:\n$0 <secrets file> <target file> \n"
        exit 1
fi 
