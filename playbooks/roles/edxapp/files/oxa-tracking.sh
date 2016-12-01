#!/bin/bash

cd /edx/app/edxapp/edx-platform
sudo /edx/bin/python.edxapp ./manage.py lms --settings aws ship_tracking_logs -f "$(hostname)" -c "tracking" -o True -d True
