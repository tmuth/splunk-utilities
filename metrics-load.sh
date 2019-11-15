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
INDEX=metrics_a
APP_NAME=drive_metrics
SOURCETYPE="prometheus:metric:ts2"
DIRECTORY=/Users/tmuth/Downloads/metric-sample

function splunk_search {
  curl -k -u ${SPLUNK_USERNAME}:${SPLUNK_PASS}  \
    https://${SPLUNK_HOST}/services/search/jobs/ \
    -d search="${1}" \
    -d exec_mode=oneshot -d count=100 -d output_mode=csv
}

function config_reload {
  local CONFIG="${1}"
  curl -k -u ${SPLUNK_USERNAME}:${SPLUNK_PASS}  \
    -X GET https://${SPLUNK_HOST}/servicesNS/nobody/search/admin/${CONFIG}/_reload
    #-X POST https://${SPLUNK_HOST}/services/configs/${CONFIG}/_reload
    /servicesNS/nobody/search/admin/props-extract/_reload
}

# delete the metrics index
curl -k -u ${SPLUNK_USERNAME}:${SPLUNK_PASS}  \
  -X DELETE https://${SPLUNK_HOST}/servicesNS/nobody/${APP_NAME}/data/indexes/${INDEX}
# create the metrics index
curl -k -u ${SPLUNK_USERNAME}:${SPLUNK_PASS}  \
 https://${SPLUNK_HOST}/servicesNS/nobody/${APP_NAME}/data/indexes  \
    -d name=${INDEX} \
    -d datatype=metric


config_reload "conf-inputs"
#config_reload "conf-fields"
#config_reload "conf-transforms"
#config_reload "conf-props"

config_reload "props-eval"
config_reload "props-extract"
config_reload "props-lookup"
config_reload "transforms-extract"
config_reload "transforms-lookup/"
config_reload "transforms-reload"
config_reload "metric-schema-reload"
#config_reload ""


for i in `ls -1 ${DIRECTORY}`
do
  echo $i
  splunk add oneshot ${DIRECTORY}/$i -index "${INDEX}" -sourcetype "${SOURCETYPE}" -host foo ;
done

echo "Waiting a few seconds so some of the files will be indexed..."
sleep 2

metric_count=`splunk_search "| msearch index=${INDEX} | stats count "`
echo ${metric_count}
splunk_search "| mcatalog values(metric_name) WHERE index=${INDEX}"
splunk_search "| mcatalog values(_dims) WHERE index=${INDEX}"
splunk_search "| msearch index=${INDEX} | head 5 | table _raw"
splunk_search "| mstats avg(_value) as value WHERE metric_name=* AND index=${INDEX} span=10s by metric_name | table * | head 10 | fields - _time"
