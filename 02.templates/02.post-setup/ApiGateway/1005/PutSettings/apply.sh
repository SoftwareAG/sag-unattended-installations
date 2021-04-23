#!/bin/sh

# This scripts apply the post-setup configuration for the current template

if [ ! "`type -t huntForSuifFile`X" == "functionX" ]; then
    echo "sourcing commonFunctions.sh again (lost?)"
    if [ ! -f "$SUIF_CACHE_HOME/01.scripts/commonFunctions.sh" ]; then
        echo "Panic, framework issue!"
        exit 500
    fi
    . "$SUIF_CACHE_HOME/01.scripts/commonFunctions.sh"
fi

if [ ! $(which envsubst) ]; then
    logE "This template requires envsubst to be installed!"
    exit 1
fi

if [ ! $(which curl) ]; then
    logE "This template requires curl to be installed!"
    exit 2
fi

thisFolder="02.templates/02.post-setup/ApiGateway/1005/PutSettings"

huntForSuifFile "${thisFolder}" "setEnvDefaults.sh"

if [ ! -f "${SUIF_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh" ]; then
    logE "File not found: ${SUIF_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh"
    exit 100
fi

chmod u+x "${SUIF_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh" 

logI "Sourcing variables from ${SUIF_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh"
. "${SUIF_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh"

if [ ! -f "${SUIF_APIGW_SETTINGS_JSON_FILE}" ]; then
    logE "The expected json configuration file for settings was not found: ${SUIF_APIGW_SETTINGS_JSON_FILE}"
    exit 4
fi

URL="${SUIF_APIGW_URL_PROTOCOL}://${SUIF_APIGW_DOMAINNAME}:${SUIF_APIGW_SERVICE_PORT}/rest/apigateway/configurations/settings"

logI "Checking if the given password is valid"
TMP_NOW=`date +%y-%m-%dT%H.%M.%S_%3N`
curl -u "Administrator:${SUIF_APIGW_ADMINISTRATOR_PASSWORD}" \
    "${URL}" \
    -H "Accept: application/json" \
    --silent -o "${SUIF_AUDIT_SESSION_DIR}/SETTINGS_BEFORE_CHANGE_AT_${TMP_NOW}.json"

if [ ! -f "${SUIF_AUDIT_SESSION_DIR}/SETTINGS_BEFORE_CHANGE_AT_${TMP_NOW}.json" ]; then
    logE "Given Administrator password is not currently valid. Cannot continue"
    exit 3
fi

envsubst \
    < "${SUIF_APIGW_SETTINGS_JSON_FILE}" \
    > "${SUIF_AUDIT_SESSION_DIR}/SETTINGS_PUT_AT_${TMP_NOW}.json"

logI "Changing the load balancer configuration"

curlCmd='curl -u "Administrator:'
curlCmd="${curlCmd}${SUIF_APIGW_ADMINISTRATOR_PASSWORD}"
curlCmd=${curlCmd}'" -X PUT -H "Content-Type: application/json"'
curlCmd=${curlCmd}' -H "Accept: application/json"'
curlCmd=${curlCmd}' --silent'
curlCmd=${curlCmd}' -o /dev/null'
curlCmd=${curlCmd}' -d "@${SUIF_AUDIT_SESSION_DIR}/SETTINGS_PUT_AT_${TMP_NOW}.json"'
curlCmd="${curlCmd} -w '%{http_code}'"
curlCmd="${curlCmd} ${URL}"

RESULT_change=`eval "${curlCmd}"`

if [[ "${RESULT_change}" == "200" ]]; then
    logI "Settings configuration changed successfully"
else
    logE "Error changing settings configuration, result is ${RESULT_change}"
    exit 5
fi

logI "Getting the settings again for audit"
curl -u "Administrator:${SUIF_APIGW_ADMINISTRATOR_PASSWORD}" \
    "${URL}" \
    -H "Accept: application/json" \
    --silent -o "${SUIF_AUDIT_SESSION_DIR}/SETTINGS_AFTER_CHANGE_AT_${TMP_NOW}.json"
