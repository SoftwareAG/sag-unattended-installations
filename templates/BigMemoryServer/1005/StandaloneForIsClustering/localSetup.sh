#!/bin/sh

# This scripts sets up the local installation
# if workFolder is already set up with the required scripts, downloads are not occuring
# alternatively, download may be done from the specified variables, here presenting default values

# Dependency 1
if [ ! $SUIF_COMMON_SOURCED ]; then
    if [ ! -f "./commonFunctions.sh" ]; then
        COMMON_FUNCTIONS_URL=${COMMON_FUNCTIONS_URL:-"https://raw.githubusercontent.com/Myhael76/sag-unattented-installations/main/scripts/commonFunctions.sh"}
        curl "${COMMON_FUNCTIONS_URL}" -o ./commonFunctions.sh
        if [ $? -ne 0 ]; then
            logE "curl failed for common functions URL ${COMMON_FUNCTIONS_URL}"
            exit 102
        fi
    fi
    . ./commonFunctions.sh
fi

# Dependency 2
if [ ! $SUIF_SETUP_FUNCTIONS_SOURCED ]; then
    if [ ! -f "./setupFunctions.sh" ]; then
        SETUP_FUNCTIONS_URL=${SETUP_FUNCTIONS_URL:-"https://raw.githubusercontent.com/Myhael76/sag-unattented-installations/main/scripts/installation/setupFunctions.sh"}
        curl "${SETUP_FUNCTIONS_URL}" -o ./setupFunctions.sh
        if [ $? -ne 0 ]; then
            logE "curl failed for setup functions URL ${COMMSETUP_FUNCTIONS_URLON_FUNCTIONS_URL}"
            exit 102
        fi
    fi
    . ./setupFunctions.sh
fi

if [ ! -f "./set_env_defaults.sh" ]; then
    SET_ENV_DEFAULTS_URL=${SET_ENV_DEFAULTS_URL:-"https://raw.githubusercontent.com/Myhael76/sag-unattented-installations/main/templates/BigMemoryServer/1005/StandaloneForIsClustering/set_env_defaults.sh"}
    curl "${SET_ENV_DEFAULTS_URL}" -o ./set_env_defaults.sh
    if [ $? -ne 0 ]; then
        logE "curl failed for set env defaults URL ${SET_ENV_DEFAULTS_URL}"
        exit 102
    fi
fi
. ./set_env_defaults.sh

if [ ! -f "./tc.config.template.xml" ]; then
    TC_CONFIG_TEMPLATE_URL=${TC_CONFIG_TEMPLATE_URL:-"https://raw.githubusercontent.com/Myhael76/sag-unattented-installations/main/templates/BigMemoryServer/1005/StandaloneForIsClustering/tc.config.template.xml"}
    curl "${TC_CONFIG_TEMPLATE_URL}" -o ./tc.config.template.xml
    if [ $? -ne 0 ]; then
        logE "curl failed for tc-config template URL ${TC_CONFIG_TEMPLATE_URL}"
        exit 102
    fi
fi

if [ ! -f "./tcAndTmc.template.wmscript" ]; then
    TC_INSTALL_TEMPLATE_URL=${TC_INSTALL_TEMPLATE_URL:-"https://raw.githubusercontent.com/Myhael76/sag-unattented-installations/main/templates/BigMemoryServer/1005/tcAndTmc.template.wmscript"}
    curl "${TC_INSTALL_TEMPLATE_URL}" -o ./tcAndTmc.template.wmscript
    if [ $? -ne 0 ]; then
        logE "curl failed for the installation template URL ${TC_INSTALL_TEMPLATE_URL}"
        exit 102
    fi
fi

# Parameters - setupProductsAndFixes
# $1 - Installer binary file
# $2 - Script file for installer
# $3 - Update Manager Boostrap file
# $4 - Fixes Image (this will allways happen offline in this framework)
# $5 - OTPIONAL Where to install (SUM Home), default /opt/sag/sum
# $6 - OPTIONAL: debugLevel for installer
setupProductsAndFixes \
    "${SUIF_INSTALLER_BIN}" \
    "./tcAndTmc.template.wmscript" \
    "${SUIF_SUM_BOOSTSTRAP_BIN}" \
    "${SUIF_FIXES_imageFile}" \
    "${SUIF_SUM_HOME}" \
    "verbose" \
    || exit $?

if [ ! -f "${SUIF_INSTALL_InstallDir}/Terracotta/server/wrapper/conf/tc-config.xml" ]; then
    logE "Expected installation file ${SUIF_INSTALL_InstallDir}/Terracotta/server/wrapper/conf/tc-config.xml not found. Cannot continue."
    logFullEnv
    exit 100
fi

mv "${SUIF_INSTALL_InstallDir}/Terracotta/server/wrapper/conf/tc-config.xml" \
   "${SUIF_INSTALL_InstallDir}/Terracotta/server/wrapper/conf/tc-config.xml.orig"

envsubst < "./tc.config.template" > "${SUIF_INSTALL_InstallDir}/Terracotta/server/wrapper/conf/tc-config.xml"
RESULT_TC_CONFIG_PREP=$?
if [ "${RESULT_TC_CONFIG_PREP}" -ne 0 ]; then
    logE "Environment variable subtitutions for ./tc.config.template failed, code: ${RESULT_TC_CONFIG_PREP}"
    logFullEnv
    return 101
fi