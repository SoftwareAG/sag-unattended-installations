#!/bin/sh

# This scripts apply the post-setup configuration for the current template

# shellcheck disable=SC2143
if [ ! "$(command -V 'huntForSuifFile1' 2>/dev/null | grep -qwi function)" ]; then
    echo "sourcing commonFunctions.sh again (lost?)"
    if [ ! -f "$SUIF_CACHE_HOME/01.scripts/commonFunctions.sh" ]; then
        echo "Panic, framework issue!"
        exit 201
    fi

     # shellcheck source=SCRIPTDIR/../../../../../01.scripts/commonFunctions.sh
    . "$SUIF_CACHE_HOME/01.scripts/commonFunctions.sh"
fi

# shellcheck disable=SC2046
if [ ! $(which envsubst) ]; then
    logE "This template requires envsubst to be installed!"
    exit 1
fi

# shellcheck disable=SC2046
if [ ! $(which curl) ]; then
    logE "This template requires curl to be installed!"
    exit 2
fi

thisFolder="02.templates/02.post-setup/IntegrationServer/1005/ChangeAdministratorPassword"

huntForSuifFile "${thisFolder}" "setEnvDefaults.sh"

if [ ! -f "${SUIF_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh" ]; then
    logE "File not found: ${SUIF_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh"
    exit 100
fi

chmod u+x "${SUIF_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh" 

logI "Sourcing variables from ${SUIF_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh"
# shellcheck source=SCRIPTDIR/setEnvDefaults.sh
. "${SUIF_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh"


logI "Checking if the old password is valid"

if [ ! -f "/dev/shm/admin1.json" ]; then
    logE "Password declared as <<OLD>> is not currently valid. Checking if the new one is ..."
    curl -u "Administrator:${SUIF_IS_NEW_ADMINISTRATOR_PASSWORD}" \
        "${URL}" \
        -H "Accept: application/json" \
        --silent -o "/dev/shm/admin1.json"
    if [ -f "/dev/shm/admin1.json" ]; then
        logI "The new password is already effective, no need to change. Exiting."
        exit 0
    else
        logE "Neither of the provided passwords match the current one. Cannot continue."
        exit 3
    fi
fi

huntForSuifFile "${thisFolder}" "AdministratorUser.json"

envsubst \
    < "${SUIF_CACHE_HOME}/${thisFolder}/AdministratorUser.json" \
    > "/dev/shm/AdministratorUser.json"

logI "Changing the password for Administrator"
# TODO: this is rather brutal, we should just replace the password in the received json, however this approach is not tested

logI "URL to invoke ${URL}"

curlCmd='curl -u "Administrator:'
curlCmd="${curlCmd}${SUIF_IS_OLD_ADMINISTRATOR_PASSWORD}"
curlCmd=${curlCmd}'" -X PUT -H "Content-Type: application/json"'
curlCmd=${curlCmd}' -H "Accept: application/json"'
curlCmd=${curlCmd}' --silent'
curlCmd=${curlCmd}' -o /dev/null'
curlCmd=${curlCmd}' -d "@/dev/shm/AdministratorUser.json"'
curlCmd="${curlCmd} -w '%{http_code}'"
curlCmd="${curlCmd} ${URL}"

RESULT_change=`eval "${curlCmd}"`

if [[ "${RESULT_change}" == "200" ]]; then
    logI "Password changed successfully"
else
    logE "Error changing password, result is ${RESULT_change}"
    exit 4
fi