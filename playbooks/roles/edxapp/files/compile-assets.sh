#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# CSS from Microsoft/edx-theme is still missing if we run paver from the edX playbooks.
# The playbooks execute paver from under a venvs path, which doesn't seem to work from
# our OXA environments. This workaround will execute paver from edx-platform until we
# resolve the venvs issue.
#
# see edX playbooks (gather static assets) at:
#  * roles/edxapp/tasks/service_variant_config.yml
#  * roles/edxapp/templates/edx/bin/edxapp-update-assets-lms.j2
cd /edx/app/edxapp/edx-platform && source ../edxapp_env

# edX playbook command:
# sudo -E -u edxapp env "PATH=$PATH" /edx/app/edxapp/venvs/edxapp/bin/paver update_assets lms --settings aws

sudo -E -u edxapp env "PATH=$PATH" paver update_assets lms --settings aws
