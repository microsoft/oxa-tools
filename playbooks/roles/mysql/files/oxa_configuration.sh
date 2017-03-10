#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.
mysql edxapp --host=$1 --user=$2 --password=$3  < edxapp.sql

if [ "$7" == "true" ] || [ "$7" == "True" ]; then
echo "BEGIN; " > edxapp_aad.sql
echo "DELETE FROM third_party_auth_oauth2providerconfig where backend_name='azuread-oauth2';" >> edxapp_aad.sql
echo "INSERT INTO third_party_auth_oauth2providerconfig " >> edxapp_aad.sql
echo "(change_date,enabled,icon_class,name,secondary,skip_registration_form,skip_email_verification,backend_name,third_party_auth_oauth2providerconfig.key,secret,other_settings,icon_image,site_id,visible,provider_slug) " >> edxapp_aad.sql
echo " VALUES " >> edxapp_aad.sql
echo "(NOW(),1,'fa-sign-in','$4',0,1,1,'azuread-oauth2','$5','$6','','',1,1,'azuread-oauth2');" >> edxapp_aad.sql
echo " COMMIT; " >> edxapp_aad.sql

mysql edxapp --host=$1 --user=$2 --password=$3  < edxapp_aad.sql
fi



