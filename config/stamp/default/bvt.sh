#!/bin/bash

# Open edX configuration (server-vars.yml) can be tokenized such that variable expansion
# using oxa-tools-config environment configurations is possible. Note that defaults can
# be specified in the tokenized configuration. i.e., ${foo:-bar}
#
# see: http://www.tldp.org/LDP/abs/html/parameter-substitution.html

##########################
# ENVIRONMENT IDENTIFIER
##########################
ENVIRONMENT=bvt

##########################
# SITE URLS
##########################

# the site certificate files (.crt & .key) have to be named after the BASE_URL value
BASE_URL=bvt.oxa.microsoft.com 
LMS_URL=lms.$BASE_URL
CMS_URL=cms.$BASE_URL
PREVIEW_URL=preview.$BASE_URL

# deployment configuration
# URL-building will be replaced by the use of LMS_URL | CMS_URL (above)
# uri format: [lms|cms]-%%CLUSTERNAME%%-%%DEPLOYMENT_SLOT%%.%%REGION%%.cloudapp.azure.com
TEMPLATE_TYPE=stamp # stamp|fullstack|devstack
CLUSTERNAME={CLUSTERNAME}
ADMIN_USER=oxaadmin
OXA_TOOLS_VERSION=oxa/master.fic

# config/server-vars.yml
#YOUTUBE_API_KEY=todo
PLATFORM_NAME=
PLATFORM_EMAIL=

# config/versions.yml
CONFIGURATION_REPO=https://github.com/Microsoft/edx-configuration.git
CONFIGURATION_VERSION=oxa/master.fic
PLATFORM_REPO=https://github.com/Microsoft/edx-platform.git
PLATFORM_VERSION=oxa/master.fic
THEME_REPO=https://github.com/Microsoft/edx-theme.git
THEME_VERSION=oxa/master.fic
EDX_VERSION=open-release/ficus.master
FORUM_VERSION=open-release/ficus.master

# fullstack uses default EMAIL_HOST=localhost
# config/stamp/stamp.yml
EDXAPP_EMAIL_HOST=
EDXAPP_EMAIL_HOST_USER=
EDXAPP_EMAIL_HOST_PASSWORD=
EDXAPP_EMAIL_PORT=
EDXAPP_EMAIL_USE_TLS=true

# storage uploads
AZURE_ACCOUNT_NAME={AZURE_ACCOUNT_NAME}
AZURE_ACCOUNT_KEY={AZURE_ACCOUNT_KEY}

NGINX_ENABLE_SSL=True
NGINX_SSL_CERTIFICATE=/oxa/oxa-tools-config/env/bvt/cert.crt
NGINX_SSL_KEY=/oxa/oxa-tools-config/env/bvt/cert.key

##########################
# MONGO
##########################

# Mongo Credentials
MONGO_USER=
MONGO_PASSWORD=

# Mongo Replicaset Credentials
MONGO_REPLICASET_KEY=
MONGO_REPLICASET_NAME={MONGO_REPLICASET_NAME}

# MongoDB Installer Configurations
MONGO_INSTALLER_SCRIPT=mongodb-ubuntu-install.sh
MONGO_INSTALLER_BASE_URL=http://repo.mongodb.org/apt/ubuntu
MONGO_INSTALLER_PACKAGE_NAME=mongodb-org
MONGO_SERVER_IP_PREFIX=10.0.0.
MONGO_SERVER_IP_OFFSET=10
MONGO_SERVER_LIST=10.0.0.11,10.0.0.12,10.0.0.13

##########################
# MYSQL
##########################

# Mysql Credentials
MYSQL_ADMIN_USER=oxamysqladmin
MYSQL_ADMIN_PASSWORD=

# MySql Temporary Credentials
MYSQL_TEMP_USER=oxamysqlbackup
MYSQL_TEMP_PASSWORD=

# App and Replication accounts (same account??)
# TODO: separate the replication user from the edxapp user
MYSQL_USER=oxamysqlrepl
MYSQL_PASSWORD=
MYSQL_REPL_USER=oxamysqlrepl
MYSQL_REPL_USER_PASSWORD=

# Mysql Installer Configurations
MYSQL_INSTALLER_SCRIPT=mysql-ubuntu-install.sh
MYSQL_PACKAGE_VERSION="5.6"
MYSQL_MASTER_IP=10.0.0.16
MYSQL_SERVER_LIST=10.0.0.16,10.0.0.17,10.0.0.18

# Superuser Information (this gives front door access to the application. This value must be updated.)
EDXAPP_SU_PASSWORD=
EDXAPP_SU_EMAIL=
EDXAPP_SU_USERNAME=

# Azure Active Directory OAuth2 Third Party Authentication Configuration
EDXAPP_ENABLE_THIRD_PARTY_AUTH={EDXAPP_ENABLE_THIRD_PARTY_AUTH}
EDXAPP_AAD_CLIENT_ID="{EDXAPP_AAD_CLIENT_ID}"
EDXAPP_AAD_SECURITY_KEY="{EDXAPP_AAD_SECURITY_KEY}"
EDXAPP_AAD_BUTTON_NAME="{EDXAPP_AAD_BUTTON_NAME}"

# Comprehensive Theming Configuration
EDXAPP_ENABLE_COMPREHENSIVE_THEMING={EDXAPP_ENABLE_COMPREHENSIVE_THEMING}
EDXAPP_COMPREHENSIVE_THEME_DIRS=\[\ \"{EDXAPP_COMPREHENSIVE_THEME_DIRECTORY}\"\ \]
EDXAPP_DEFAULT_SITE_THEME="{EDXAPP_DEFAULT_SITE_THEME}"

# Import Kitchen Sink Course Configuration
EDXAPP_IMPORT_KITCHENSINK_COURSE={EDXAPP_IMPORT_KITCHENSINK_COURSE}

# Memcache server
# In order to support multiple VMSS resources, we have to support multiple memcache target servers to avoid collision of cache keys that result in 
# broken application experiences (cache poisoning). It is therefore necessary to add explicit configuration for the memcache server and allow 
# deployment-time overrides.
MEMCACHE_SERVER_IP=$MYSQL_MASTER_IP

# Conditionally enabling Mobile Rest Api in support of MPP integration scenarios
EDXAPP_ENABLE_OAUTH2_PROVIDER=false
EDXAPP_ENABLE_MOBILE_REST_API=false
OAUTH_ENFORCE_SECURE=false