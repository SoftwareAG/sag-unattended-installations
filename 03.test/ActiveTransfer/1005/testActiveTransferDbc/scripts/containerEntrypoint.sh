#!/bin/sh

# This scripts sets up the local installation

if [ ! -d ${SUIF_HOME} ]; then
    echo "SUIF_HOME variable MUST point to an existing local folder! Current value is ${SUIF_HOME}"
    exit 1
fi

# our configuration takes precedence in front of framework defaults, set it before sourcing the framework functions
if [ ! -d "${SUIF_LOCAL_SCRIPTS_HOME}" ]; then
    echo "Scripts folder not found: ${SUIF_LOCAL_SCRIPTS_HOME}"
    exit 2
fi

if [ ! -f "${SUIF_LOCAL_SCRIPTS_HOME}/set_env.sh" ]; then
    echo "set_env script not found: ${SUIF_LOCAL_SCRIPTS_HOME}/set_env.sh"
    exit 3
fi

. "${SUIF_LOCAL_SCRIPTS_HOME}/set_env.sh"

# Source framework functions
. "${SUIF_HOME}/01.scripts/commonFunctions.sh" || exit 4
. "${SUIF_HOME}/01.scripts/installation/setupFunctions.sh" || exit 5

# If the installation is not present, do it now
if [ ! -d "${SUIF_INSTALL_InstallDir}/common" ]; then
    echo "Starting up for the first time, setting up ..."

    # Parameters - applySetupTemplate
    # $1 - Setup template directory, relative to <repo_home>/02.templates/01.setup
    applySetupTemplate "AT/1005/DBC4AT" || exit 6
fi

logI "Calling dbConfigurator.sh"

"${SUIF_INSTALL_InstallDir}/common/db/bin/dbConfigurator.sh"
lResCall=$?

if [ ${lResCall} -eq 0 ]; then
    logI "Installation successful"
else
    logE "Installation failed!"
fi
unset lResCall

logW "Startup complete, open a shell if you want to play! Interrupt otherwise..."

tail -f /dev/null
