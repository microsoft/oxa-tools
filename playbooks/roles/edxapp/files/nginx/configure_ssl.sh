#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

add_port_to_url_rewrite() {
  sed "s/rewrite \^ https:\/\/\$host\$request_uri/rewrite \^ https:\/\/\$host:$2\$request_uri/" -i $1
}

harden_ssl_config() {
  # To prevent downgrade attacks we will disable old SSL protocols. SSL was superseded by TLS 1.0 in 1999; TLS 1.2 is the latest version.
  # SSLv2 is disabled by default but we will also disable SSLv3.  Note that all versions of Edge, Chrome, Firefox and Safari support at 
  # least TLS 1.0. With this change we will break Internet Explorer 6 and earlier, which top out at SSLv3.  The list of cyphers we are using 
  # is based on the MVA site which scores an A rating using Qualys SSL Lab's online security service (https://www.ssllabs.com/ssltest) which 
  # performs a deep analysis of the configuration of any SSL web server on the Internet.
  local pattern="# request the browser to use SSL for all connections"
  local line1="  ssl_protocols TLSv1 TLSv1.1 TLSv1.2;"
  local line2="  ssl_ciphers 'ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA';"
  local line3="  ssl_prefer_server_ciphers on;"
  local newline="\n"
  local append="$line1$newline$line2$newline$line3$newline"

  if ! grep -Fq "ssl_protocols" $1 ; then
    sed "/$pattern/i $append" -i $1
  fi
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

    echo "Harden LMS/CMS/Preview SSL configurations"
    harden_ssl_config $lms_file_path
    harden_ssl_config $cms_file_path
    harden_ssl_config $preview_file_path

    echo "Update LMS/CMS/Preview to allow the heartbeat to remain accessible via http"
    support_http_heartbeat $lms_file_path $2
    support_http_heartbeat $cms_file_path $3
    support_http_heartbeat $preview_file_path $4
  fi
}

update_nginx_site_configs "$@"
