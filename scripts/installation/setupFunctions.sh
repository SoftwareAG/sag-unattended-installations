#!/bin/sh

# Dependency
if [ ! $SUIF_COMMON_SOURCED ]; then
    echo "Source common framework functions before the setup functions"
    exit 1
fi

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

    debugLevel=${3:-"verbose"}
    d=`date +%y-%m-%dT%H.%M.%S_%3N`

    # apply environment substitutions
    envsubst < "${2}" > /dev/shm/install.wmscript || return 5

    installCmd="${1} -readScript /dev/shm/install.wmscript"
    installCmd="${installCmd} -debugLvl ${debugLevel}"
    installCmd="${installCmd} -debugFile "'"'"${SUIF_AUDIT_SESSION_DIR}/debugInstall.log"'"'
    controlledExec "${installCmd}" "${d}.product-install"
    
    RESULT_installProducts=$?
    unset debugLevel d installCmd
    if [ ${RESULT_installProducts} -eq 0 ] ; then
        logI "Product installation successful"
    else
        logE "Product installation failed, code ${RESULT_installProducts}"
        return 4
    fi
}

# Parameters - bootstrapSum
# $1 - Update Manager Boostrap file
# $2 - OTPIONAL Where to install (SUM Home), default /opt/sag/sum
bootstrapSum(){
    if [ ! -f  ${1} ]; then
        logE "Software AG Update Manager boostrap file not found: ${1}"
        return 1
    fi

    SUM_HOME=${2:-"/opt/sag/sum"}
    d=`date +%y-%m-%dT%H.%M.%S_%3N`

    bootstrapCmd="${1} --accept-license -d "'"'"${SUM_HOME}"'"'
    logI "Bootstrapping SUM from ${1} into ${SUM_HOME}..."
    controlledExec "${bootstrapCmd}" "${d}.sum-bootstrap"
    RESULT_controlledExec=$?
    unset SUM_HOME bootstrapCmd d

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

    SUM_HOME=${2:-"/opt/sag/sum"}
    PRODUCTS_HOME=${3:-"/opt/sag/products"}
    d=`date +%y-%m-%dT%H.%M.%S_%3N`

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
    unset SUM_HOME PRODUCTS_HOME d
    rm -f /dev/shm/fixes.wmscript.txt
    popd >/dev/null

    if [ ${RESULT_controlledExec} -eq 0 ]; then
        logI "Patch successful"
    else
        logE "Patch failed, code ${RESULT_controlledExec}"
        return 2
    fi
}

# Parameters - setupProductsAndFixes
# $1 - Installer binary file
# $2 - Script file for installer
# $3 - Update Manager Boostrap file
# $4 - Fixes Image (this will allways happen offline in this framework)
# $5 - OTPIONAL Where to install (SUM Home), default /opt/sag/sum
# $6 - OPTIONAL: debugLevel for installer
setupProductsAndFixes(){

    if [ ! -f ${1} ]; then
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

    lProductImageFile=$(grep imageFile /dev/shm/install.wmscript.tmp | cut -d "=" -f 2)

    # note no inline returns from now as we need to clean locally allocated resources
    if [ ! -f ${lProductImageFile} ]; then
        logE "Product image file not found: ${lProductImageFile}"
        RESULT_setupProductsAndFixes=6
    else
        lInstallDir=$(grep InstallDir /dev/shm/install.wmscript.tmp | cut -d "=" -f 2)
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
            d=`date +%y-%m-%dT%H.%M.%S_%3N`
            installerDebugLevel=${6:-"verbose"}

            # Parameters - installProducts
            # $1 - installer binary file
            # $2 - script file for installer
            # $3 - OPIONAL: debugLevel for installer
            installProducts "${1}" "${2}"  "${installerDebugLevel}"
            if [ ${RESULT_installProducts} -ne 0 ]; then
                logE "installProducts failed, code ${RESULT_installProducts}!"
                RESULT_setupProductsAndFixes=8
            else
                # Parameters - bootstrapSum
                # $1 - Update Manager Boostrap file
                # $2 - OTPIONAL Where to install (SUM Home), default /opt/sag/sum
                lSumHome=${5:-"/opt/sag/sum"}
                bootstrapSum "${3}" "${lSumHome}"
                if [ ${RESULT_bootstrapSum} -ne 0 ]; then
                    logE "Update Manager bootstrap failed, code ${RESULT_bootstrapSum}!"
                    RESULT_setupProductsAndFixes=9
                else
                    # Parameters - patchInstallation
                    # $1 - Fixes Image (this will allways happen offline in this framework)
                    # $2 - OTPIONAL SUM Home, default /opt/sag/sum
                    # $3 - OTPIONAL Products Home, default /opt/sag/products
                    patchInstallation "${4}" "${lSumHome}" "${lInstallDir}"
                    if [ ${RESULT_patchInstallation} -ne 0 ]; then
                        logE "Patch Installation failed, code ${RESULT_patchInstallation}!"
                        RESULT_setupProductsAndFixes=10
                    else
                        logI "Product and Fixes setup completed successfully"
                        RESULT_setupProductsAndFixes=0
                    fi
                fi
                unset lSumHome
            fi
            unset d installerDebugLevel
        fi
        unset lInstallDir
    fi
    unset lProductImageFile
    return ${RESULT_setupProductsAndFixes}
}

export SUIF_SETUP_FUNCTIONS_SOURCED=1