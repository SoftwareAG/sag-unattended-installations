#!/bin/sh

# Source framework functions
. "${SUIF_HOME}/01.scripts/commonFunctions.sh" || exit 4
. "${SUIF_HOME}/01.scripts/installation/setupFunctions.sh" || exit 5

if [ ! -d "${SUIF_INSTALL_INSTALL_DIR}/IntegrationServer" ]; then
    logFullEnv

    applySetupTemplate "MSR/1011/lean" || exit 6

    cd /app/sag/1011/MSR/IntegrationServer/docker
    ./is_container.sh createLeanDockerfile
else
    logW "Product has already been set up." 
fi
