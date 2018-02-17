#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# input parameters
mysql_host_name="${1}"
mysql_user_name="${2}"
mysql_user_password="${3}"
aad_button_name="${4}"
aad_client_id="${5}"
aad_security_key="${6}"
aad_enable="${7,,}" 
azure_cloud_db_server_name="${8}"

# Qualify the user name for azure cloud db login
if [[ -n "${azure_cloud_db_server_name}" ]];
then
    mysql_user_account="${mysql_user_name}@${azure_cloud_db_server_name}"
fi  

mysql edxapp --host="${mysql_host_name}" --user="${mysql_user_name}" --password="${mysql_user_password}"  < edxapp.sql

if [[ "${aad_enable}" == "true" ] ; then
    echo "BEGIN; " > edxapp_aad.sql
    echo "DELETE FROM third_party_auth_oauth2providerconfig where backend_name='azuread-oauth2';" >> edxapp_aad.sql
    echo "INSERT INTO third_party_auth_oauth2providerconfig " >> edxapp_aad.sql
    echo "(change_date,enabled,icon_class,name,secondary,skip_registration_form,skip_email_verification,backend_name,third_party_auth_oauth2providerconfig.key,secret,other_settings,icon_image,site_id,visible,provider_slug) " >> edxapp_aad.sql
    echo " VALUES " >> edxapp_aad.sql
    echo "(NOW(),1,'fa-sign-in','${aad_button_name}',0,1,1,'azuread-oauth2','${aad_client_id}','${aad_security_key}','','',1,1,'azuread-oauth2');" >> edxapp_aad.sql
    echo " COMMIT; " >> edxapp_aad.sql

    mysql edxapp --host="${mysql_host_name}" --user="${mysql_user_name}" --password="${mysql_user_password}" < edxapp_aad.sql
fi



