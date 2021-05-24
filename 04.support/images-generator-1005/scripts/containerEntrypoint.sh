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

if [ -d "${SUIF_USER_HOME}/SUIF" ];then
    echo "SUIF already cloned previously, pulling the latest version"
    cd "${SUIF_USER_HOME}/SUIF/sag-unattented-installations"
    git pull
else
    echo "Cloning SUIF..."
    mkdir "${SUIF_USER_HOME}/SUIF"
    cd "${SUIF_USER_HOME}/SUIF"
    git clone https://github.com/Myhael76/sag-unattented-installations.git
fi


find . -type f -name *.sh -exec chmod u+x "{}" \;
. "${SUIF_USER_HOME}/SUIF/sag-unattented-installations/01.scripts/commonFunctions.sh"
. "${SUIF_USER_HOME}/SUIF/sag-unattented-installations/01.scripts/installation/setupFunctions.sh"


if [ -d "${SUIF_SUM_HOME}/bin" ];then
    logI "UpdateManager already present, skipping installation..."
else
    # Parameters - bootstrapSum
    # $1 - Update Manager Boostrap file
    # $2 - Fixes image file, mandatory for offline mode
    # $3 - OTPIONAL Where to install (SUM Home), default /opt/sag/sum
    bootstrapSum "${SUIF_PATCH_SUM_BOOSTSTRAP_BIN}" "" "${SUIF_SUM_HOME}" 

    cd "${SUIF_SUM_HOME}/bin"
    # first ensure SUM is able to self update"
    lCmd="./UpdateManagerCMD.sh -selfUpdate true"
    lCmd="${lCmd} -empowerUser ${SUIF_EMPOWER_USER}"
    lCmd="${lCmd} -empowerPass '${SUIF_EMPOWER_PASSWORD}'"

    controlledExec "${lCmd}" "SUM-Self-Update"

    unset lCmd
fi

logI "Inspecting SUIF for setup templates"
cd "${SUIF_USER_HOME}/SUIF/sag-unattented-installations/02.templates/01.setup"
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

if [ "${SUIF_DEBUG_ON}" -eq 1 ]; then
    logD "Stopping execution for debug"
    tail -f /dev/null
fi