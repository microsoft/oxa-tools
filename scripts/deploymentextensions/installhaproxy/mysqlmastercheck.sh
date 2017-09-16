#!/bin/bash
#
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

#
# This script serves as a custom probe for HAProxy Mysql access.
# This is intended for use in a master-slave replicated topology and ensures that HAProxy only communicates to the 
# valid master server.
#

# Source our utilities for logging and other base functions (we need this staged with the installer script)
# we expect utilities to be in a known path
utilities_path=/oxa/oxa-tools/templates/stamp/utilities.sh

# check if the utilities file exists. If not, bail out.
if [[ ! -e $utilities_path ]]; 
then  
    echo "Utilities not present"
    exit 3
fi

# source the utilities now
source $utilities_path

# Input Parameters 
# These values will be replaced at runtime by overrides supplied by user
mysql_user=
mysql_user_password=
replication_serverlist="10.0.0.16 10.0.0.17 10.0.0.18"

# Variables
encoded_replication_serverlist=`echo $replication_serverlist | base64`
local_server_ip=`ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'`

# main function call
is_valid_master=`is_master_server ${encoded_replication_serverlist} ${local_server_ip} "${mysql_user}" "${mysql_user_password}"`

# Based on the response (0=Not Valid Master, 1=Valid Master), return an appropriate HTTP status code for the probe
if [[ $is_valid_master == 1 ]];
then
    # server is a valid master, return http 200
    echo -e "HTTP/1.1 200 OK \r\n"
    echo -e "Content-Type: Content-Type: text/plain \r\n"
    echo -e "\r\n"
    echo -e "${local_server_ip} is a valid replication master.\r\n"
    echo -e "\r\n"
else
    # server is not valid master, return http 503
    echo -e "HTTP/1.1 503 Service Unavailable\r\n"
    echo -e "Content-Type: Content-Type: text/plain\r\n"
    echo -e "\r\n"
    echo -e "${local_server_ip} is a not a valid replication master.\r\n"
    echo -e "\r\n"
fi