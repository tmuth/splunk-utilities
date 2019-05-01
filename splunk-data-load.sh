#!/bin/bash

# This script is meant to streamline the process of getting files into Splunk.
# The goal is to:
# 1. Delete all events in the specified INDEX
# 2. Reload the input, fields, transforms, and props configs
# 3. oneshot load all of the files in specified directory using the defined sourcetype and INDEX
# 4. Count the number

#SPLUNK_HOST=localhost:8089
SPLUNK_HOST=localhost:8091
SPLUNK_USERNAME=admin
SPLUNK_PASS=changeme
INDEX=fio-test
SOURCETYPE=_json
DIRECTORY=~tmuth/Temp/fio-test

function splunk_search {
  local port="${1:-8000}"
  curl -k -u ${SPLUNK_USERNAME}:${SPLUNK_PASS}  \
    https://${SPLUNK_HOST}/services/search/jobs/ \
    -d search="${1}" \
    -d exec_mode=oneshot -d count=100 -d output_mode=csv
}

function config_reload {
  local CONFIG="${1}"
  curl -k -u ${SPLUNK_USERNAME}:${SPLUNK_PASS}  \
    -X POST https://${SPLUNK_HOST}/services/configs/${CONFIG}/_reload
}

splunk_search "search index=${INDEX} | delete"

config_reload "conf-inputs"
config_reload "conf-fields"
config_reload "conf-transforms"
config_reload "conf-props"

for i in `ls -1 ${DIRECTORY}`
do
  echo $i
  splunk add oneshot ${DIRECTORY}/$i -index ${INDEX} -sourcetype ${SOURCETYPE};
done

echo "Waiting a few seconds so some of the files will be indexed..."
sleep 3

splunk_search "search index=${INDEX} | stats count"
splunk_search "search index=${INDEX} | fieldsummary | fields field,count"
