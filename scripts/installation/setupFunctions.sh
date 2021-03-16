#!/bin/sh

# Dependency

if [ ! $SUIF_COMMON_SOURCED ]; then
    echo "Source common framework functions before the setup functions"
    exit 1
fi

installProducts(){
    # Parameters - installProducts
    # $1 - installer binary file
    # $2 - script file for installer
    # $3 - OPIONAL: audit folder for output
    # $4 - OPIONAL: log trace file
    # $5 - OPIONAL: debugLevel for installer
    # $6 - OPTIONAL: SLS log file

    if [ -f "${1}" ]; then
        logI "Installing according to script ${2}" "${6}"
        if [ -f "${2}" ]; then
            if [ $(which envsubst) ]; then
                d=`date +%y-%m-%dT%H.%M.%S_%3N`
                auditFolder=${3:-"/tmp/${d}"}
                mkdir -p ${auditFolder}
                logFile=${4:-"${auditFolder}/script.log"}
                debugLevel=${5:-"verbose"}

                # apply environment substitutions
                envsubst < "${2}" > /dev/shm/install.wmscript

                installCmd="${1}"
                installCmd="${installCmd} -readScript /dev/shm/install.wmscript"
                installCmd="${installCmd} -debugLvl ${debugLevel}"
                installCmd="${installCmd} -debugFile "'"'"${auditFolder}/debugInstall.log"'"'
                controlledExec "${installCmd}" "${d}.product-install" "${auditFolder}"
                
                RESULT_installProducts=$?
                if [ ${RESULT_installProducts} -eq 0 ] ; then
                    logI "Product installation successful" "${6}"
                else
                    logE "Product installation failed, code ${RESULT_installProducts}" "${6}"
                fi
                unset auditFolder logFile debugLevel d
            else
                logE "Product installation requires envsubst to be installed!" "${6}"
                RESULT_installProducts=3
            fi
        else
            logE "Product installation failed: invalid installer script file: ${2}" "${6}"
            RESULT_installProducts=2
        fi
    else
        logE "Product installation failed: invalid installer file: ${1}" "${6}"
        RESULT_installProducts=1
    fi
}

bootstrapSum(){
    # Parameters - bootstrapSum
    # $1 Update Manager Boostrap file
    # $2 OTPIONAL Where to install (SUM Home), default /opt/sag/sum
    # $3 OPTIONAL Audit folder
    # $4 OPTIONAL SLS log file

    if [ -f  ${1} ]; then
        SUM_HOME=${2:-"/opt/sag/sum"}
        d=`date +%y-%m-%dT%H.%M.%S_%3N`
        auditFolder=${3:-"/tmp/${d}"}
        mkdir -p ${auditFolder}
        bootstrapCmd="${1} --accept-license -d "'"'"${SUM_HOME}"'"'
        logI "Bootstrapping SUM from ${1} into ${SUM_HOME}..." "${4}"
        controlledExec "${bootstrapCmd}" "${d}.sum-bootstrap" "${auditFolder}"

        if [ ${RESULT_controlledExec} -eq 0 ]; then
            logI "SUM Bootstrap successful" "${4}"
            RESULT_bootstrapSum=0
        else
            logE "SUM Boostrap failed, code ${RESULT_controlledExec}" "${4}"
            RESULT_bootstrapSum=2
        fi
        unset SUM_HOME auditFolder bootstrapCmd d
    else
        logE "Software AG Update Manager boostrap file not found: ${1}" "${4}"
        RESULT_bootstrapSum=1
    fi
}

patchInstallation(){
    # Parameters - patchInstallation
    # $1 - Fixes Image (this will allways happen offline in this framework)
    # $2 OTPIONAL SUM Home, default /opt/sag/sum
    # $3 OTPIONAL Products Home, default /opt/sag/products
    # $4 OPTIONAL audit folder, default /tmp
    # $5 OPTIONAL SLS log file

    if [ -f ${1} ]; then
        SUM_HOME=${2:-"/opt/sag/sum"}
        PRODUCTS_HOME=${3:-"/opt/sag/products"}
        d=`date +%y-%m-%dT%H.%M.%S_%3N`
        auditFolder=${4:-"/tmp/${d}"}
        mkdir -p ${auditFolder}

        logI "Applying fixes from image ${1} to installation ${PRODUCTS_HOME} using SUM in ${SUM_HOME}..." "${5}"

        echo "installSP=N" >/dev/shm/fixes.wmscript.txt
        echo "installDir=${PRODUCTS_HOME}" >>/dev/shm/fixes.wmscript.txt
        echo "selectedFixes=spro:all" >>/dev/shm/fixes.wmscript.txt
        echo "action=Install fixes from image" >> /dev/shm/fixes.wmscript.txt
        echo "imageFile=${1}" >> /dev/shm/fixes.wmscript.txt

        pushd . >/dev/null
        cd "${SUM_HOME}/bin"

        controlledExec "./UpdateManagerCMD.sh -readScript /dev/shm/fixes.wmscript.txt" "${d}.PatchInstallation" "${auditFolder}"

        if [ ${RESULT_controlledExec} -eq 0 ]; then
            logI "Patch successful"  "${5}"
            RESULT_patchInstallation=0
        else
            logE "Patch failed, code ${RESULT_controlledExec}"  "${5}"
            RESULT_patchInstallation=2
        fi
        
        rm -f /dev/shm/fixes.wmscript.txt
        popd >/dev/null
        unset SUM_HOME auditFolder bootstrapCmd d
    else
        logE "Fixes image file not found: ${1}"
        RESULT_patchInstallation=1
    fi
}

setupProductsAndFixes(){
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

    if [ ! -f ${1} ]; then
        logE "Installer binary file not found: ${1}" "${7}"
        RESULT_setupProductsAndFixes=1
    else
        if [ ! -f ${2} ]; then
            logE "Installer script file not found: ${2}" "${7}"
            RESULT_setupProductsAndFixes=2
        else
            if [ ! -f ${3} ]; then
                logE "Update Manager bootstrap binary file not found: ${3}" "${7}"
                RESULT_setupProductsAndFixes=3
            else
                if [ ! -f ${4} ]; then
                    logE "Fixes image file not found: ${3}" "${7}"
                    RESULT_setupProductsAndFixes=4
                else
                    # apply environment substitutions
                    # Note: this is done twice for reusability reasons
                    envsubst < "${2}" > /dev/shm/install.wmscript.tmp

                    lProductImageFile=$(grep imageFile /dev/shm/install.wmscript.tmp | cut -d "=" -f 2)
                    if [ ! -f ${lProductImageFile} ]; then
                        logE "Product image file not found: ${lProductImageFile}" "${7}"
                        RESULT_setupProductsAndFixes=5
                    else
                        lInstallDir=$(grep InstallDir /dev/shm/install.wmscript.tmp | cut -d "=" -f 2)
                        if [ -d ${lInstallDir} ]; then 
                            logW "Install folder already present..." "${7}"
                            if [ $(ls -1A ${lInstallDir} | wc -l) -gt 0 ]; then 
                                logW "Install folder is not empty!" "${7}"
                            fi
                        else
                            mkdir -p ${lInstallDir}
                        fi
                        if [ ! -d ${lInstallDir} ]; then
                            logE "Cannot create the installation directory!" "${7}"
                            RESULT_setupProductsAndFixes=6
                        else
                            d=`date +%y-%m-%dT%H.%M.%S_%3N`
                            auditFolder=${6:-"/tmp/${d}"}
                            mkdir -p ${auditFolder}
                            installerLogFile=${8:-"${auditFolder}/script.log"}
                            installerDebugLevel=${9:-"verbose"}
                            # Parameters - installProducts
                            # $1 installer binary file
                            # $2 script file for installer
                            # $3 OPTIONAL: audit folder for output
                            # $4 OPTIONAL: install log trace file
                            # $5 OPTIONAL: debugLevel for installer
                            # $6 OPTIONAL: SLS log file
                            installProducts "${1}" "${2}" "${auditFolder}" "${installerLogFile}" "${installerDebugLevel}" "${7}"
                            if [ RESULT_installProducts -ne 0 ]; then
                                logE "installProducts failed, code ${RESULT_installProducts}!" "${7}"
                                RESULT_setupProductsAndFixes=7
                            else
                                # Parameters - bootstrapSum
                                # $1 Update Manager Boostrap file
                                # $2 OTPIONAL Where to install (SUM Home), default /opt/sag/sum
                                # $3 OPTIONAL Audit folder
                                # $4 OPTIONAL SLS log file
                                lSumHome=${5:-"/opt/sag/sum"}
                                bootstrapSum "${3}" "${lSumHome}" "${auditFolder}" "${7}"
                                if [ RESULT_bootstrapSum -ne 0 ]; then
                                    logE "Update Manager bootstrap failed, code ${RESULT_bootstrapSum}!" "${7}"
                                    RESULT_setupProductsAndFixes=8
                                else
                                    # Parameters - patchInstallation
                                    # $1 Fixes Image (this will allways happen offline in this framework)
                                    # $2 OTPIONAL SUM Home, default /opt/sag/sum
                                    # $3 OTPIONAL Products Home, default /opt/sag/products
                                    # $4 OPTIONAL audit folder, default /tmp
                                    # $5 OPTIONAL SLS log file
                                    patchInstallation "${4}" "${lSumHome}" "${lInstallDir}" "${auditFolder}" "${7}"
                                    if [ RESULT_patchInstallation -ne 0 ]; then
                                        logE "Patch Installation failed, code ${RESULT_patchInstallation}!" "${7}"
                                        RESULT_setupProductsAndFixes=9
                                    else
                                        logI "Product and Fixes setup completed successfully" "${7}"
                                        RESULT_setupProductsAndFixes=0
                                    fi
                                fi
                                unset lSumHome
                            fi
                            unset d auditFolder installerLogFile installerDebugLevel
                        fi
                        unset lInstallDir
                    fi
                    unset lProductImageFile
                fi
            fi
        fi
    fi
}

export SUIF_SETUP_FUNCTIONS_SOURCED=1