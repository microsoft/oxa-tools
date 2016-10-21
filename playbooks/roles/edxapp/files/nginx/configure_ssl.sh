#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.
echo "Copy SSL cert from secrets folder"
mkdir -p /etc/nginx/ssl
cp $1/nginx/cert/openedx.microsoft.com.crt /etc/nginx/ssl/openedx.microsoft.com.crt
cp $1/nginx/cert/openedx.microsoft.com.key /etc/nginx/ssl/openedx.microsoft.com.key

echo "Preserve the original lms file"
if [ ! -f /edx/app/nginx/sites-available/lms-original ]; then
  mv /edx/app/nginx/sites-available/lms /edx/app/nginx/sites-available/lms-original
fi

echo "Copy the updated lms file" # symlinked: /etc/nginx/sites-enabled/lms -> /edx/app/nginx/sites-available/lms
cp sites-available/lms /edx/app/nginx/sites-available/lms

echo "Preserve the original cms file"
if [ ! -f /edx/app/nginx/sites-available/cms-original ]; then
  mv /edx/app/nginx/sites-available/cms /edx/app/nginx/sites-available/cms-original
fi

echo "Copy the updated cms file" # symlinked: /etc/nginx/sites-enabled/cms -> /edx/app/nginx/sites-available/cms
cp sites-available/cms /edx/app/nginx/sites-available/cms
