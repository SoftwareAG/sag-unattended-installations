#!/bin/bash

# /bin/sh breakes in the the do while with pushd / popd for some reason

# This scripts sets up the local installation

. "${SUIF_LOCAL_SCRIPTS_HOME}/set_env.sh" || exit 1
. "${SUIF_LOCAL_SCRIPTS_HOME}/functions.sh" || exit 2

onInterrupt(){
    echo "Interrupted!"
}

onKill(){
	echo "Killed!"
}

trap "onInterrupt" SIGINT SIGTERM
trap "onKill" SIGKILL

if [ ! -d "${SUIF_HOME}/02.templates/01.setup" ];then
    echo "SUIF not mounted, cannot continue"
    exit 3
fi

. "${SUIF_HOME}/01.scripts/commonFunctions.sh"
. "${SUIF_HOME}/01.scripts/installation/setupFunctions.sh"


if [ -d "${SUIF_SUM_HOME}/bin/UpdateManager/conf " ];then
    logI "UpdateManager already present, skipping installation..."
else
    # Parameters - bootstrapSum
    # $1 - Update Manager Boostrap file
    # $2 - Fixes image file, mandatory for offline mode
    # $3 - OTPIONAL Where to install (SUM Home), default /opt/sag/sum
    bootstrapSum "${SUIF_PATCH_SUM_BOOSTSTRAP_BIN}" "" "${SUIF_SUM_HOME}" 
fi

logI "Attempting to update Update Manager itself..."
cd "${SUIF_SUM_HOME}/bin"
# first ensure SUM is able to self update"
lCmd="./UpdateManagerCMD.sh -selfUpdate true"
lCmd="${lCmd} -empowerUser ${SUIF_EMPOWER_USER}"
lCmd="${lCmd} -empowerPass '${SUIF_EMPOWER_PASSWORD}'"

controlledExec "${lCmd}" "SUM-Self-Update"

result_SUM_SELF_UPDATE=$?

if [ ${result_SUM_SELF_UPDATE} -ne 0 ]; then
    logE "Update Manager Self Online Update failed, code ${result_SUM_SELF_UPDATE}"
fi

unset lCmd

# TODO: initialize lTemplateFiles only if not already provided

SUIF_PROCESS_TEMPLATE=${SUIF_PROCESS_TEMPLATE:-all}

if [ "${SUIF_PROCESS_TEMPLATE}" == "all" ];then
    logI "Inspecting SUIF for setup templates"
    cd "${SUIF_HOME}/02.templates/01.setup"
    lTemplateFiles=(`find . -type f -name template.wmscript`)

    for wmsfile in "${lTemplateFiles[@]}"
    do
        templateId=${wmsfile%'/template.wmscript'}
        templateId=${templateId#'./'}
        logI "Found template ${templateId} (from file ${wmsfile})"

        # Parameters
        # $1 -> setup template
        # $2 -> platform string
        generateProductsImageFromTemplate "${templateId}" "${SUIF_PLATFORM_STRING}"
        generateFixesImageFromTemplate "${templateId}" "${SUIF_PLATFORM_STRING}"
    done
else
    if [ -d "${SUIF_HOME}/02.templates/01.setup/${SUIF_PROCESS_TEMPLATE}" ]; then
        logI "Preparing images for specified template ${SUIF_PROCESS_TEMPLATE}"
        generateProductsImageFromTemplate "${SUIF_PROCESS_TEMPLATE}" "${SUIF_PLATFORM_STRING}"
        generateFixesImageFromTemplate "${SUIF_PROCESS_TEMPLATE}" "${SUIF_PLATFORM_STRING}"
    else
        logE "Template ${SUIF_PROCESS_TEMPLATE} not found!"
    fi
fi

if [ "${SUIF_DEBUG_ON}" -eq 1 ]; then
    logD "Stopping execution for debug"
    tail -f /dev/null
fi