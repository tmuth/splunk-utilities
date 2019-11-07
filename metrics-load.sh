#!/bin/bash

# This script is meant to streamline the process of getting files into Splunk.
# The goal is to:
# 1. Delete all events in the specified INDEX
# 2. Reload the input, fields, transforms, and props configs
# 3. oneshot load all of the files in specified directory using the defined sourcetype and INDEX
# 4. Count the number of events and show the field summary

#SPLUNK_HOST=localhost:8089
SPLUNK_HOST=localhost:8089
SPLUNK_USERNAME=admin
SPLUNK_PASS=welcome1
INDEX=drive_error_metrics
SOURCETYPE=prometheus:metric
DIRECTORY=/Users/tmuth/Downloads/data-sample

function splunk_search {
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

#splunk_search "search index=${INDEX} | delete"
# cant delete metrics, so:
# splunk clean eventdata -index ${INDEX}

config_reload "conf-inputs"
config_reload "conf-fields"
config_reload "conf-transforms"
config_reload "conf-props"

for i in `ls -1 ${DIRECTORY}`
do
  echo $i
  splunk add oneshot ${DIRECTORY}/$i -index ${INDEX} -sourcetype ${SOURCETYPE} -host foo ;
done

echo "Waiting a few seconds so some of the files will be indexed..."
sleep 3

splunk_search "| mcatalog values(metric_name) WHERE index=${INDEX} | stats count "
splunk_search "| mcatalog values(metric_name) WHERE index=${INDEX}"

# splunk_search "search index=${INDEX} | fieldsummary | fields field,count"
