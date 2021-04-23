#!/bin/sh

# Dependency
if [ ${SUIF_COMMON_SOURCED} -ne 1 ]; then
    echo "Source common framework functions before the setup functions"
    exit 1
fi

init(){
    # Section 1 - the caller MUST provide
    ## Framework - Install
    export SUIF_INSTALL_INSTALLER_BIN=${SUIF_INSTALL_INSTALLER_BIN:-"/path/to/installer.bin"}
    export SUIF_INSTALL_IMAGE_FILE=${SUIF_INSTALL_IMAGE_FILE:-"/path/to/install/product.image.zip"}
    ## Framework - Patch
    export SUIF_PATCH_SUM_BOOSTSTRAP_BIN=${SUIF_PATCH_SUM_BOOSTSTRAP_BIN:-"/path/to/sum-boostrap.bin"}
    export SUIF_PATCH_FIXES_IMAGE_FILE=${SUIF_PATCH_FIXES_IMAGE_FILE:-"/path/to/install/fixes.image.zip"}

    # Section 2 - the caller MAY provide
    ## Framework - Install
    export SUIF_INSTALL_INSTALL_DIR=${SUIF_INSTALL_INSTALL_DIR:-"/opt/sag/products"}
    export SUIF_INSTALL_SPM_HTTPS_PORT=${SUIF_INSTALL_SPM_HTTPS_PORT:-"9083"}
    export SUIF_INSTALL_SPM_HTTP_PORT=${SUIF_INSTALL_SPM_HTTP_PORT:-"9082"}
    ## Framework - Patch
    export SUIF_SUM_HOME=${SUIF_SUM_HOME:-"/opt/sag/sum"}
}

init

# Parameters - installProducts
# $1 - installer binary file
# $2 - script file for installer
# $3 - OPIONAL: debugLevel for installer
installProducts(){

    if [ ! -f "${1}" ]; then
        logE "Product installation failed: invalid installer file: ${1}"
        return 1
    fi

    if [ ! -f "${2}" ]; then
        logE "Product installation failed: invalid installer script file: ${2}"
        return 2
    fi

    if [ ! $(which envsubst) ]; then
        logE "Product installation requires envsubst to be installed!"
        return 3
    fi

    logI "Installing according to script ${2}"

    local debugLevel=${3:-"verbose"}
    local d=`date +%y-%m-%dT%H.%M.%S_%3N`

    # apply environment substitutions
    envsubst < "${2}" > /dev/shm/install.wmscript || return 5

    local installCmd="${1} -readScript /dev/shm/install.wmscript"
    local installCmd="${installCmd} -debugLvl ${debugLevel}"
    local installCmd="${installCmd} -debugFile "'"'"${SUIF_AUDIT_SESSION_DIR}/debugInstall.log"'"'
    controlledExec "${installCmd}" "${d}.product-install"
    
    RESULT_installProducts=$?
    if [ ${RESULT_installProducts} -eq 0 ] ; then
        logI "Product installation successful"
    else
        logE "Product installation failed, code ${RESULT_installProducts}"
        return 4
    fi
}

# Parameters - bootstrapSum
# $1 - Update Manager Boostrap file
# $2 - Fixes image file, mandatory for offline mode
# $3 - OTPIONAL Where to install (SUM Home), default /opt/sag/sum
bootstrapSum(){
    if [ ! -f  ${1} ]; then
        logE "Software AG Update Manager boostrap file not found: ${1}"
        return 1
    fi

    if [ ! -f  ${2} ]; then
        logE "Fixes image file not found: ${2}"
        return 2
    fi

    local SUM_HOME=${3:-"/opt/sag/sum"}
    local d=`date +%y-%m-%dT%H.%M.%S_%3N`

    local bootstrapCmd="${1} --accept-license -d "'"'"${SUM_HOME}"'"'
    if [ ${SUIF_ONLINE_MODE} -eq 0 ]; then
        bootstrapCmd="${bootstrapCmd=} -i ${2}"
    fi
    # note: everything is always offline excepti this, as it is not requiring empower credentials
    logI "Bootstrapping SUM from ${1} using image ${2} into ${SUM_HOME}..."
    controlledExec "${bootstrapCmd}" "${d}.sum-bootstrap"
    RESULT_controlledExec=$?

    if [ ${RESULT_controlledExec} -eq 0 ]; then
        logI "SUM Bootstrap successful"
    else
        logE "SUM Boostrap failed, code ${RESULT_controlledExec}"
        return 2
    fi
}

# Parameters - patchInstallation
# $1 - Fixes Image (this will allways happen offline in this framework)
# $2 - OTPIONAL SUM Home, default /opt/sag/sum
# $3 - OTPIONAL Products Home, default /opt/sag/products
patchInstallation(){
    if [ ! -f ${1} ]; then
        logE "Fixes image file not found: ${1}"
        return 1
    fi

    local SUM_HOME=${2:-"/opt/sag/sum"}
    local PRODUCTS_HOME=${3:-"/opt/sag/products"}
    local d=`date +%y-%m-%dT%H.%M.%S_%3N`

    logI "Applying fixes from image ${1} to installation ${PRODUCTS_HOME} using SUM in ${SUM_HOME}..." 

    echo "installSP=N" >/dev/shm/fixes.wmscript.txt
    echo "installDir=${PRODUCTS_HOME}" >>/dev/shm/fixes.wmscript.txt
    echo "selectedFixes=spro:all" >>/dev/shm/fixes.wmscript.txt
    echo "action=Install fixes from image" >> /dev/shm/fixes.wmscript.txt
    echo "imageFile=${1}" >> /dev/shm/fixes.wmscript.txt

    pushd . >/dev/null
    cd "${SUM_HOME}/bin"

    controlledExec "./UpdateManagerCMD.sh -readScript /dev/shm/fixes.wmscript.txt" "${d}.PatchInstallation"
    RESULT_controlledExec=$?
    popd >/dev/null

    if [ ${RESULT_controlledExec} -eq 0 ]; then
        logI "Patch successful"
    else
        logE "Patch failed, code ${RESULT_controlledExec}"
        if [ ${SUIF_DEBUG_ON} ]; then
            logD "Recovering Update Manager logs for further investigations"
            mkdir -p ${SUIF_AUDIT_SESSION_DIR}/UpdateManager
            cp -r ${SUM_HOME}/logs ${SUIF_AUDIT_SESSION_DIR}/
            cp -r ${SUM_HOME}/UpdateManager/logs ${SUIF_AUDIT_SESSION_DIR}/UpdateManager/
            cp /dev/shm/fixes.wmscript.txt ${SUIF_AUDIT_SESSION_DIR}/
        fi
        return 2
    fi
    rm -f /dev/shm/fixes.wmscript.txt
}

# Parameters - setupProductsAndFixes
# $1 - Installer binary file
# $2 - Script file for installer
# $3 - Update Manager Boostrap file
# $4 - Fixes Image (this will allways happen offline in this framework)
# $5 - OTPIONAL Where to install (SUM Home), default /opt/sag/sum
# $6 - OPTIONAL: debugLevel for installer
setupProductsAndFixes(){

    if [ ! -f "${1}" ]; then
        logE "Installer binary file not found: ${1}"
        return 1
    fi
    if [ ! -f ${2} ]; then
        logE "Installer script file not found: ${2}"
        return 2
    fi
    if [ ! -f ${3} ]; then
        logE "Update Manager bootstrap binary file not found: ${3}"
        return 3
    fi
    if [ ! -f ${4} ]; then
        logE "Fixes image file not found: ${3}"
        return 4
    fi
    if [ ! $(which envsubst) ]; then
        logE "Product installation requires envsubst to be installed!"
        return 5
    fi
    # apply environment substitutions
    # Note: this is done twice for reusability reasons
    envsubst < "${2}" > /dev/shm/install.wmscript.tmp

    local lProductImageFile=$(grep imageFile /dev/shm/install.wmscript.tmp | cut -d "=" -f 2)

    # note no inline returns from now as we need to clean locally allocated resources
    if [ ! -f "${lProductImageFile}" ]; then
        logE "Product image file not found: ${lProductImageFile}"
        RESULT_setupProductsAndFixes=6
    else
        local lInstallDir=$(grep InstallDir /dev/shm/install.wmscript.tmp | cut -d "=" -f 2)
        if [ -d ${lInstallDir} ]; then 
            logW "Install folder already present..."
            if [ $(ls -1A ${lInstallDir} | wc -l) -gt 0 ]; then 
                logW "Install folder is not empty!"
            fi
        else
            mkdir -p ${lInstallDir}
        fi
        if [ ! -d ${lInstallDir} ]; then
            logE "Cannot create the installation directory!"
            RESULT_setupProductsAndFixes=7
        else
            local d=`date +%y-%m-%dT%H.%M.%S_%3N`
            local installerDebugLevel=${6:-"verbose"}

            # Parameters - installProducts
            # $1 - installer binary file
            # $2 - script file for installer
            # $3 - OPIONAL: debugLevel for installer
            installProducts "${1}" "${2}" "${installerDebugLevel}"
            RESULT_installProducts=$?
            if [ ${RESULT_installProducts} -ne 0 ]; then
                logE "installProducts failed, code ${RESULT_installProducts}!"
                RESULT_setupProductsAndFixes=8
            else
                # Parameters - bootstrapSum
                # $1 - Update Manager Boostrap file
                # $2 - OTPIONAL Where to install (SUM Home), default /opt/sag/sum
                local lSumHome=${5:-"/opt/sag/sum"}
                bootstrapSum "${3}" "${4}" "${lSumHome}"
                local RESULT_bootstrapSum=$?
                if [ ${RESULT_bootstrapSum} -ne 0 ]; then
                    logE "Update Manager bootstrap failed, code ${RESULT_bootstrapSum}!"
                    RESULT_setupProductsAndFixes=9
                else
                    # Parameters - patchInstallation
                    # $1 - Fixes Image (this will allways happen offline in this framework)
                    # $2 - OTPIONAL SUM Home, default /opt/sag/sum
                    # $3 - OTPIONAL Products Home, default /opt/sag/products
                    patchInstallation "${4}" "${lSumHome}" "${lInstallDir}"
                    RESULT_patchInstallation=$?
                    if [ ${RESULT_patchInstallation} -ne 0 ]; then
                        logE "Patch Installation failed, code ${RESULT_patchInstallation}!"
                        RESULT_setupProductsAndFixes=10
                    else
                        logI "Product and Fixes setup completed successfully"
                        RESULT_setupProductsAndFixes=0
                    fi
                fi
            fi
        fi
    fi
    return ${RESULT_setupProductsAndFixes}
}

# Parameters - applySetupTemplate
# $1 - Setup template directory, relative to <repo_home>/02.templates/01.setup
applySetupTemplate(){
    logI "Applying Setup Template ${1}"
    huntForSuifFile "02.templates/01.setup/${1}" "template.wmscript" || return 1
    huntForSuifFile "02.templates/01.setup/${1}" "setEnvDefaults.sh" || return 2
    huntForSuifFile "02.templates/01.setup/${1}" "checkPrerequisites.sh" || return 4
    logI "Sourcing variable values for template ${1} ..."
    . "${SUIF_CACHE_HOME}/02.templates/01.setup/${1}/setEnvDefaults.sh"
    logI "Checking installation prerequisites for template ${1} ..."
    chmod u+x "${SUIF_CACHE_HOME}/02.templates/01.setup/${1}/checkPrerequisites.sh" > /dev/null
    "${SUIF_CACHE_HOME}/02.templates/01.setup/${1}/checkPrerequisites.sh" || return 5
    logI "Setting up products and fixes for template ${1} ..."
    setupProductsAndFixes \
        "${SUIF_INSTALL_INSTALLER_BIN}" \
        "${SUIF_CACHE_HOME}/02.templates/01.setup/${1}/template.wmscript" \
        "${SUIF_PATCH_SUM_BOOSTSTRAP_BIN}" \
        "${SUIF_PATCH_FIXES_IMAGE_FILE}" \
        "${SUIF_SUM_HOME}" \
        "verbose"
    local RESULT_setupProductsAndFixes=$?
    if [ ${RESULT_setupProductsAndFixes} -ne 0 ]; then
        logE "Setup for template ${1} failed, code ${RESULT_setupProductsAndFixes}"
        return 3
    fi
}

export SUIF_SETUP_FUNCTIONS_SOURCED=1