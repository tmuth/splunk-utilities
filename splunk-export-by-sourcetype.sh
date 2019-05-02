#!/bin/bash

SPLUNK_HOST=localhost:8091
SPLUNK_USERNAME=admin
SPLUNK_PASS=changeme
EARLIEST="-1h"
TOP_N_SOURCETYPES=10
EVENTS_PER_SOURCETYPE=5


SOURCETYPE_SEARCH="index=* earliest=${EARLIEST} | fields - _raw _time \
  | stats count by sourcetype | sort - count \
  | head ${TOP_N_SOURCETYPES} \
  | table sourcetype "

function splunk_search {
  local SEARCH=$1
  local OUTPUT_MODE="${2:csv}"

  curl -s -k -u ${SPLUNK_USERNAME}:${SPLUNK_PASS}  \
    https://${SPLUNK_HOST}/services/search/jobs/export \
    -d "search=search ${SEARCH}" \
    -d output_mode="${OUTPUT_MODE}"
}

SOURCETYPES=`splunk_search "${SOURCETYPE_SEARCH}" "csv"`
echo $SOURCETYPES
SOURCETYPES_ARR=($SOURCETYPES)
# remove 1st element of array which is the header
SOURCETYPES_ARR=("${SOURCETYPES_ARR[@]:1}")

for i in "${SOURCETYPES_ARR[@]}"
do
	echo $i
  OUTPUT_FILE="${i//\"/}"
  OUTPUT_FILE="${OUTPUT_FILE//:/_}.csv"
  echo $OUTPUT_FILE
  EXPORT_SEARCH="sourcetype=${i} earliest=${EARLIEST} | fields _raw | head ${EVENTS_PER_SOURCETYPE}"
  splunk_search "${EXPORT_SEARCH}" "csv" > "${OUTPUT_FILE}"
done
