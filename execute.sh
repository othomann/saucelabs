#!/bin/bash

#********************************************************************************
# Copyright 2014, 2018 IBM
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#********************************************************************************

#############
# Colors    #
#############
export green='\e[0;32m'
export red='\e[0;31m'
export label_color='\e[0;33m'
export no_color='\e[0m' # No Color

##################################################
# Simple function to only run command if DEBUG=1 #
### ###############################################
debugme() {
  [[ $DEBUG = 1 ]] && "$@" || :
}

set +e
set +x

if [ -z "${SAUCE_USERNAME}" ]; then
    echo -e "${red}A SauceLabs service instance does not exist or is misconfigured. Please add or configure it properly.${no_color}"
    exit 1
fi

if [ -z "${SAUCE_ACCESS_KEY}" ]; then
    echo -e "${red}A SauceLabs service instance does not exist or is misconfigured. Please add or configure it properly.${no_color}"
    exit 1
fi

debugme echo "SAUCE_ACCESS_KEY: ${SAUCE_ACCESS_KEY}"
debugme echo "USER_ID: ${SAUCE_USERNAME}"

pip install -q requests

cmd_choice=$CMD_CHOICE

function execute {
    eval $cmd_choice
    RESULT=$?
    ${EXT_DIR}/sauce.py
    PY_RES=$?

    if [ "${DOWNLOAD_ASSETS}" == true ]; then
        echo "zipping files"
        zip -q selenium_logs.zip selenium-server-*
        zip -q videos.zip video-*
        mv selenium_logs.zip ${ARCHIVE_DIR}
        mv videos.zip ${ARCHIVE_DIR}
    fi
    mv job_data_collection.json ${ARCHIVE_DIR}

    if [ $RESULT -ne 0 ] || [ $PY_RES -ne 0 ]; then
        exit 1
    fi
}

if [[ $cmd_choice == "npm test" ]] || [[ $cmd_choice == "grunt test" ]] || [[ $cmd_choice == "grunt" ]]; then
    if [[ ! -f package.json ]]; then
        echo "No tests to run. Exiting..."
        exit 0
    fi
    npm install
    execute
fi
if [[ $cmd_choice == "ant test" ]] || [[ $cmd_choice == "mvn test" ]]; then
    execute
fi
if [[ $cmd_choice == "custom" ]]; then
    custom_cmd
fi
if [[ $cmd_choice == " " ]] || [[ -z "$cmd_choice" ]]; then
    ${EXT_DIR}/auto-detect.py
    AUTO_RESULT=$?
    if [ $AUTO_RESULT -ne 0 ]; then
        echo "Running grunt test..."
        cmd_choice="grunt test"
        npm install
        execute
    else
        echo "Running npm test..."
        cmd_choice="npm test"
        npm install
        execute
    fi
fi
