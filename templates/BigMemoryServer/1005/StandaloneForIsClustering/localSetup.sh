#!/bin/sh

# This scripts sets up the local installation
# if workFolder is already set up with the required scripts, downloads are not occuring
# alternatively, download may be done from the specified variables, here presenting default values

crtDate=`date +%y-%m-%dT%H.%M.%S_%3N`
SUIF_AUDIT_BASE_FOLDER=${SUIF_AUDIT_BASE_FOLDER:-"/tmp/localSetup/${crtDate}"}
mkdir -p "${SUIF_AUDIT_BASE_FOLDER}"
cd "${SUIF_AUDIT_BASE_FOLDER}"
# Dependency 1
if [ ! $SUIF_COMMON_SOURCED ]; then
    if [ ! -f "./commonFunctions.sh" ]; then
        COMMON_FUNCTIONS_URL=${COMMON_FUNCTIONS_URL:-"https://raw.githubusercontent.com/Myhael76/sag-unattented-installations/main/scripts/commonFunctions.sh"}
        curl "${COMMON_FUNCTIONS_URL}" -o ./commonFunctions.sh
    fi
    . ./commonFunctions.sh
fi

# Dependency 2
if [ ! $SUIF_SETUP_FUNCTIONS_SOURCED ]; then
    if [ ! -f "./setupFunctions.sh" ]; then
        SETUP_FUNCTIONS_URL=${SETUP_FUNCTIONS_URL:-"https://raw.githubusercontent.com/Myhael76/sag-unattented-installations/main/scripts/installation/setupFunctions.sh"}
        curl "${COMMON_FUNCTIONS_URL}" -o ./setupFunctions.sh
    fi
    . ./setupFunctions.sh
fi

if [ ! -f "./set_env_defaults.sh" ]; then
    SET_ENV_DEFAULTS_URL=${SET_ENV_DEFAULTS_URL:-"https://raw.githubusercontent.com/Myhael76/sag-unattented-installations/main/templates/BigMemoryServer/1005/StandaloneForIsClustering/set_env_defaults.sh"}
    curl "${SET_ENV_DEFAULTS_URL}" -o ./set_env_defaults.sh
fi
. ./set_env_defaults.sh

if [ ! -f "./tc.config.template.xml" ]; then
    SET_ENV_DEFAULTS_URL=${SET_ENV_DEFAULTS_URL:-"https://raw.githubusercontent.com/Myhael76/sag-unattented-installations/main/templates/BigMemoryServer/1005/StandaloneForIsClustering/tc.config.template.xml"}
    curl "${SET_ENV_DEFAULTS_URL}" -o ./tc.config.template.xml
fi

if [ ! -f "./tcAndTmc.template.wmscript" ]; then
    SET_ENV_DEFAULTS_URL=${SET_ENV_DEFAULTS_URL:-"https://raw.githubusercontent.com/Myhael76/sag-unattented-installations/main/templates/BigMemoryServer/1005/tcAndTmc.template.wmscript"}
    curl "${SET_ENV_DEFAULTS_URL}" -o ./tcAndTmc.template.wmscript
fi


# Parameters - setupProductsAndFixes
# $1 Installer binary file
# $2 Script file for installer
# $3 Update Manager Boostrap file
# $4 Fixes Image (this will allways happen offline in this framework)
# $5 OTPIONAL Where to install (SUM Home), default /opt/sag/sum
# $6 OPTIONAL: audit folder for output
# $7 OPTIONAL SLS log file
# $8 OPTIONAL: install log trace file
# $9 OPTIONAL: debugLevel for installer
setupProductsAndFixes \
    "${SUIF_INSTALLER_BIN}" \
    "./tcAndTmc.template.wmscript" \
    "${SUIF_SUM_BOOSTSTRAP_BIN}" \
    "${SUIF_FIXES_imageFile}" \
    "${SUIF_SUM_HOME}" \
    "${SUIF_AUDIT_BASE_FOLDER}" \
    "${SUIF_AUDIT_BASE_FOLDER}/top.log" \
    "${SUIF_AUDIT_BASE_FOLDER}/install.trace.log" \
    "verbose" 

if [ ${RESULT_setupProductsAndFixes} -ne 0 ]; then
    logE "Setup products and fixes failed, code: ${RESULT_setupProductsAndFixes}"
    exit 1
else

fi