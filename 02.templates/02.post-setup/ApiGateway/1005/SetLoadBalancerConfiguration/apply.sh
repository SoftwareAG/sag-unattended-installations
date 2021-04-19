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
    logE "Product installation requires envsubst to be installed!"
    exit 1
fi

if [ ! $(which curl) ]; then
    logE "This template requires curl to be installed!"
    exit 2
fi

thisFolder="02.templates/02.post-setup/ApiGateway/1005/SetLoadBalancerConfiguration"

huntForSuifFile "${thisFolder}" "setEnvDefaults.sh"

if [ ! -f "${SUIF_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh" ]; then
    logE "File not found: ${SUIF_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh"
    exit 100
fi

chmod u+x "${SUIF_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh"

logI "Sourcing variables from ${SUIF_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh"
. "${SUIF_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh"

URL="${SUIF_APIGW_URL_PROTOCOL}://${SUIF_APIGW_DOMAINNAME}:${SUIF_APIGW_SERVICE_PORT}/rest/apigateway/configurations/loadBalancer"

logI "Checking if the given password is valid"
curl -u "Administrator:${SUIF_APIGW_ADMINISTRATOR_PASSWORD}" \
    "${URL}" \
    -H "Accept: application/json" \
    -o "/dev/shm/LB1.json"

if [ ! -f "/dev/shm/LB1.json" ]; then
    logE "Given Administrator password is not currently valid. Cannot continue"
    exit 3
fi

if [ ! -f "${SUIF_APIGW_LB_JSON_FILE}" ]; then
    logE "The expected json configuration file for Load Balancers was not found: ${SUIF_APIGW_LB_JSON_FILE}"
    exit 4
fi

huntForSuifFile "${thisFolder}" "AdministratorUser.json"

envsubst \
    < "${SUIF_APIGW_LB_JSON_FILE}" \
    > "/dev/shm/LB.json"

logI "Changing the password for Administrator"
# TODO: this is rather brutal, we should just replace the password in the received json, however this approach is not tested

logI "URL to invoke ${URL}"

curlCmd='curl -u "Administrator:'
curlCmd="${curlCmd}${SUIF_APIGW_ADMINISTRATOR_PASSWORD}"
curlCmd=${curlCmd}'" -X PUT -H "Content-Type: application/json"'
curlCmd=${curlCmd}' -H "Accept: application/json"'
curlCmd=${curlCmd}' --silent'
curlCmd=${curlCmd}' -o /dev/null'
curlCmd=${curlCmd}' -d "@/dev/shm/LB.json"'
curlCmd="${curlCmd} -w '%{http_code}'"
curlCmd="${curlCmd} ${URL}"

logI "command is ${curlCmd}"

RESULT_change=`eval "${curlCmd}"`

if [[ "${RESULT_change}" == "200" ]]; then
    logI "Password changed successfully"
else
    logE "Error changing password, result is ${RESULT_change}"
    exit 3
fi