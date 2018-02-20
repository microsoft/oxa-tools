#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

add_port_to_url_rewrite() {
  sed "s/rewrite \^ https:\/\/\$host\$request_uri/rewrite \^ https:\/\/\$host:$2\$request_uri/" -i $1
}

support_http_heartbeat() {
  local pattern="if (\$do_redirect_to_https \="
  local line1="  if (\$request_uri \~ \^\/heartbeat\$)"
  local line2="  \{"
  local line3="   set \$do_redirect_to_https \"false\";"
  local line4="  \}"
  local newline="\n"
  local append="$line1$newline$line2$newline$line3$newline$line4$newline"

  if ! grep -Fq "request_uri ~ ^/heartbeat" $1 ; then
    sed "/$pattern/i $append" -i $1
  fi
}

update_nginx_site_configs() {
  local sites_available_path="/edx/app/nginx/sites-available"
  local lms_file_path="$sites_available_path/lms"
  local cms_file_path="$sites_available_path/cms"
  local preview_file_path="$sites_available_path/lms-preview"

  if [[ $1 == True ]] ; then
    # SSL is enabled
    echo "Update LMS/CMS/Preview url rewrites to include SSL port number"
    add_port_to_url_rewrite $lms_file_path $2
    add_port_to_url_rewrite $cms_file_path $3
    add_port_to_url_rewrite $preview_file_path $4

    echo "Update LMS/CMS/Preview to allow the heartbeat to remain accessible via http"
    support_http_heartbeat $lms_file_path $2
    support_http_heartbeat $cms_file_path $3
    support_http_heartbeat $preview_file_path $4
  fi
}

update_nginx_site_configs "$@"
