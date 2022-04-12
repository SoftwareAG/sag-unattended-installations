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

# Source framework functions
. "${SUIF_HOME}/01.scripts/commonFunctions.sh" || exit 4
. "${SUIF_HOME}/01.scripts/installation/setupFunctions.sh" || exit 5

# If the DBC installation is not present, do it now
if [ ! -f "${SUIF_INSTALL_INSTALL_DIR_DBC}/common/db/bin/dbConfigurator.sh" ]; then
    echo "Database configurator is not present, setting up ..."

    export SUIF_INSTALL_IMAGE_FILE="${SUIF_INSTALL_IMAGE_FILE_DBC4AT}"
    export SUIF_PATCH_FIXES_IMAGE_FILE="${SUIF_PATCH_FIXES_IMAGE_FILE_DBC4AT}"
    export SUIF_INSTALL_INSTALL_DIR="${SUIF_INSTALL_INSTALL_DIR_DBC}"

    # Parameters - applySetupTemplate
    # $1 - Setup template directory, relative to <repo_home>/02.templates/01.setup
    applySetupTemplate "AT/1011/DBC4AT" || echo "would exit 6"; tail -f /dev/null # exit 6
fi

if [ "${SUIF_DEBUG_ON}" -eq 1 ]; then
  logW "Stopping for debug"
  tail -f /dev/null
fi
