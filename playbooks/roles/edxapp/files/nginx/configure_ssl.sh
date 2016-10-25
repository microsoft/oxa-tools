#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.
echo "Port: $2"

echo "Copy SSL cert from secrets folder"
mkdir -p /etc/nginx/ssl
cp $1/nginx/cert/openedx.microsoft.com.crt /etc/nginx/ssl/openedx.microsoft.com.crt
cp $1/nginx/cert/openedx.microsoft.com.key /etc/nginx/ssl/openedx.microsoft.com.key

echo "Preserve the original lms file"
if [ ! -f /edx/app/nginx/sites-available/lms-original ]; then
  cp /edx/app/nginx/sites-available/lms /edx/app/nginx/sites-available/lms-original
fi

echo "Copy the updated lms file" # symlinked: /etc/nginx/sites-enabled/lms -> /edx/app/nginx/sites-available/lms
if [[ $2 -eq 443 ]]; then
  echo "Enabling LMS using SSL"
  cp sites-available/SSL/lms /edx/app/nginx/sites-available/lms
else
  echo "Enabling LMS without SSL"
  cp /edx/app/nginx/sites-available/lms-original /edx/app/nginx/sites-available/lms
fi

echo "Preserve the original cms file"
if [ ! -f /edx/app/nginx/sites-available/cms-original ]; then
  cp /edx/app/nginx/sites-available/cms /edx/app/nginx/sites-available/cms-original
fi

echo "Copy the updated cms file" # symlinked: /etc/nginx/sites-enabled/cms -> /edx/app/nginx/sites-available/cms
if [[ $2 -eq 443 ]]; then
  echo "Enabling CMS using SSL"
  cp sites-available/SSL/cms /edx/app/nginx/sites-available/cms
else
  echo "Enabling CMS without SSL"
  cp /edx/app/nginx/sites-available/cms-original /edx/app/nginx/sites-available/cms
fi
