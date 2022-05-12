#!/bin/bash

# Source framework functions
. "${SUIF_HOME}/01.scripts/commonFunctions.sh" || exit 4
. "${SUIF_HOME}/01.scripts/installation/setupFunctions.sh" || exit 5

logFullEnv

# If the installation is not present, do it now
logI "Starting up for the first time, setting up ..."

# Parameters - applySetupTemplate
# $1 - Setup template directory, relative to <repo_home>/02.templates/01.setup
applySetupTemplate "MSR/1011/lean" || exit 6

logI "Generating IS dockerfile"
cd "${SUIF_INSTALL_INSTALL_DIR}/IntegrationServer/docker"
./is_container.sh createLeanDockerfile || exit 7

logI "IS dockerfile generated"

cd "${SUIF_INSTALL_INSTALL_DIR}"
logD "Dumping dockerfile"
logD $(cat ./Dockerfile_IS)

logI "Building container image in docker format..."

d=$(date +%y-%m-%dT%H.%M.%S_%3N)

buildah \
    bud -f ./Dockerfile_IS \
        --format docker \
        -t "sag-lean-msr-canonical_1011:${d}"

logI "Image built"
