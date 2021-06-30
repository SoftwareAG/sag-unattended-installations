#!/bin/sh

# This scripts apply the post-setup configuration for the current template

# Dependency 1
if [ ! "`type -t huntForSuifFile`X" == "functionX" ]; then
    echo "sourcing commonFunctions.sh again (lost?)"
    if [ ! -f "$SUIF_CACHE_HOME/01.scripts/commonFunctions.sh" ]; then
        echo "Panic, framework issue!"
        exit 500
    fi
    . "$SUIF_CACHE_HOME/01.scripts/commonFunctions.sh"
fi
thisFolder="02.templates/02.post-setup/BigMemoryServer/1005/ThreeNodeCluster"

huntForSuifFile "${thisFolder}" "setEnvDefaults.sh"

if [ ! -f "${SUIF_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh" ]; then
    logE "File not found: ${SUIF_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh"
    exit 100
fi

chmod u+x "${SUIF_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh" 

logI "Sourcing variables from ${SUIF_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh"
. "${SUIF_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh"

huntForSuifFile "${thisFolder}" "tc.config.template.xml"

if [ ! -f "${SUIF_INSTALL_INSTALL_DIR}/Terracotta/server/wrapper/conf/tc-config.xml" ]; then
    logE "Expected installation file ${SUIF_INSTALL_INSTALL_DIR}/Terracotta/server/wrapper/conf/tc-config.xml not found. Cannot continue."
    logFullEnv
    exit 100
fi

mv "${SUIF_INSTALL_INSTALL_DIR}/Terracotta/server/wrapper/conf/tc-config.xml" \
   "${SUIF_INSTALL_INSTALL_DIR}/Terracotta/server/wrapper/conf/tc-config.xml.orig"

envsubst < "${SUIF_CACHE_HOME}/${thisFolder}/tc.config.template.xml" > "${SUIF_INSTALL_INSTALL_DIR}/Terracotta/server/wrapper/conf/tc-config.xml"
RESULT_TC_CONFIG_PREP=$?
if [ "${RESULT_TC_CONFIG_PREP}" -ne 0 ]; then
    logE "Environment variable subtitutions for ${SUIF_CACHE_HOME}/${thisFolder}/tc.config.template.xml failed, code: ${RESULT_TC_CONFIG_PREP}"
    logFullEnv
    exit 101
fi

logI "Generating default configuration for TMC"

pushd . >/dev/null
cd ~
mkdir -p "./.tc/mgmt/client"
mkdir -p "./.tc/mgmt/server"
if [ -f "./.tc/mgmt/settings.ini" ]; then
    logW "File ./.tc/mgmt/settings.ini already exists, overwriting..."
    rm "./.tc/mgmt/settings.ini"
fi

touch "./.tc/mgmt/settings.ini"
echo "#Template Settings, generated on "`date +%y-%m-%dT%H.%M.%S_%3N` >> "./.tc/mgmt/settings.ini"
echo "authenticationEnabled=false" >> "./.tc/mgmt/settings.ini"
echo "firstRun=false" >> "./.tc/mgmt/settings.ini"
echo "" >> "./.tc/mgmt/settings.ini"
popd >/dev/null
