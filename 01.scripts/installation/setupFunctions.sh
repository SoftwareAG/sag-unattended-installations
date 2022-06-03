#!/bin/sh

# Dependency
if [ ! "`type -t logI`X" == "functionX" ]; then
    echo "sourcing commonFunctions.sh ..."
    if [ ! -f "${SUIF_CACHE_HOME}/01.scripts/commonFunctions.sh" ]; then
        echo "Panic, framework issue! File ${SUIF_CACHE_HOME}/01.scripts/commonFunctions.sh does not exist. SUIF_CACHE_HOME=${SUIF_CACHE_HOME}"
        exit 500
    fi
    . "${SUIF_CACHE_HOME}/01.scripts/commonFunctions.sh"
fi

init(){
    # Section 1 - the caller MUST provide
    ## Framework - Install
    export SUIF_INSTALL_INSTALLER_BIN=${SUIF_INSTALL_INSTALLER_BIN:-"/tmp/installer.bin"}
    export SUIF_INSTALL_IMAGE_FILE=${SUIF_INSTALL_IMAGE_FILE:-"/path/to/install/product.image.zip"}
    export SUIF_PATCH_AVAILABLE=${SUIF_PATCH_AVAILABLE:-"0"}
    ## Framework - Patch
    export SUIF_PATCH_SUM_BOOSTSTRAP_BIN=${SUIF_PATCH_SUM_BOOSTSTRAP_BIN:-"/tmp/sum-boostrap.bin"}
    export SUIF_PATCH_FIXES_IMAGE_FILE=${SUIF_PATCH_FIXES_IMAGE_FILE:-"/path/to/install/fixes.image.zip"}

    # Section 2 - the caller MAY provide
    ## Framework - Install
    export SUIF_INSTALL_INSTALL_DIR=${SUIF_INSTALL_INSTALL_DIR:-"/opt/sag/products"}
    export SUIF_INSTALL_SPM_HTTPS_PORT=${SUIF_INSTALL_SPM_HTTPS_PORT:-"9083"}
    export SUIF_INSTALL_SPM_HTTP_PORT=${SUIF_INSTALL_SPM_HTTP_PORT:-"9082"}
    export SUIF_INSTALL_DECLARED_HOSTNAME=${SUIF_INSTALL_DECLARED_HOSTNAME:-"localhost"}
    ## Framework - Patch
    export SUIF_SUM_HOME=${SUIF_SUM_HOME:-"/opt/sag/sum"}
}

init

# Online mode for SDC separated from Online mode for SUIF:
export SUIF_ONLINE_MODE=${SUIF_ONLINE_MODE:-1} # default is online for SUIF
export SUIF_SDC_ONLINE_MODE=${SUIF_SDC_ONLINE_MODE:-0} # default if offline for SDC

# Parameters - installProducts
# $1 - installer binary file
# $2 - script file for installer
# $3 - OPIONAL: debugLevel for installer
installProducts(){

    if [ ! -f "${1}" ]; then
        logE "[setupFunctions.sh/installProducts()] - Product installation failed: invalid installer file: ${1}"
        return 1
    fi

    if [ ! -f "${2}" ]; then
        logE "[setupFunctions.sh/installProducts()] - Product installation failed: invalid installer script file: ${2}"
        return 2
    fi

    if [ ! $(which envsubst) ]; then
        logE "[setupFunctions.sh/installProducts()] - Product installation requires envsubst to be installed!"
        return 3
    fi

    logI "Installing according to script ${2}"

    local debugLevel=${3:-"verbose"}
    local d=`date +%y-%m-%dT%H.%M.%S_%3N`

    # apply environment substitutions
    envsubst < "${2}" > /dev/shm/install.wmscript || return 5

    local installCmd="${1} -readScript /dev/shm/install.wmscript -console"
    local installCmd="${installCmd} -debugLvl ${debugLevel}"
    if [ ${SUIF_DEBUG_ON} -ne 0 ]; then
        local installCmd="${installCmd} -scriptErrorInteract yes"
    else
        local installCmd="${installCmd} -scriptErrorInteract no"
    fi
    local installCmd="${installCmd} -debugFile "'"'"${SUIF_AUDIT_SESSION_DIR}/debugInstall.log"'"'
    controlledExec "${installCmd}" "${d}.product-install"
    
    RESULT_installProducts=$?
    if [ ${RESULT_installProducts} -eq 0 ] ; then
        logI "Product installation successful"
    else
        logE "[setupFunctions.sh/installProducts()] - Product installation failed, code ${RESULT_installProducts}"
        logD "Dumping the install.wmscript file into the session audit folder..."
        if [ ${SUIF_DEBUG_ON} -ne 0 ]; then
            cp /dev/shm/install.wmscript "${SUIF_AUDIT_SESSION_DIR}/"
        fi
        return 4
    fi
}

# Parameters - bootstrapSum
# $1 - Update Manager Boostrap file
# $2 - Fixes image file, mandatory for offline mode
# $3 - OTPIONAL Where to install (SUM Home), default /opt/sag/sum
bootstrapSum(){
    if [ ! -f  ${1} ]; then
        logE "[setupFunctions.sh/bootstrapSum()] - Software AG Update Manager boostrap file not found: ${1}"
        return 1
    fi

    if [ ${SUIF_SDC_ONLINE_MODE} -eq 0 ]; then
        if [ ! -f  "${2}" ]; then
            logE "[setupFunctions.sh/bootstrapSum()] - Fixes image file not found: ${2}"
            return 2
        fi
    fi

    local SUM_HOME=${3:-"/opt/sag/sum"}

    if [ -d "${SUM_HOME}/UpdateManager" ]; then
        logI "Update manager already present, skipping bootstrap, attempting to update from given image..."
        patchSum "${2}" "${SUM_HOME}"
        return 0
    fi

    local d=`date +%y-%m-%dT%H.%M.%S_%3N`

    local bootstrapCmd="${1} --accept-license -d "'"'"${SUM_HOME}"'"'
    if [ ${SUIF_SDC_ONLINE_MODE} -eq 0 ]; then
        bootstrapCmd="${bootstrapCmd=} -i ${2}"
        # note: everything is always offline except this, as it is not requiring empower credentials
        logI "Bootstrapping SUM from ${1} using image ${2} into ${SUM_HOME}..."
    else
        logI "Bootstrapping SUM from ${1} into ${SUM_HOME} using ONLINE mode"
    fi
    controlledExec "${bootstrapCmd}" "${d}.sum-bootstrap"
    RESULT_controlledExec=$?

    if [ ${RESULT_controlledExec} -eq 0 ]; then
        logI "SUM Bootstrap successful"
    else
        logE "[setupFunctions.sh/bootstrapSum()] - SUM Boostrap failed, code ${RESULT_controlledExec}"
        return 3
    fi
}

# Parameters - patchSum()
# $1 - Fixes Image (this will allways happen offline in this framework)
# $2 - OTPIONAL SUM Home, default /opt/sag/sum
patchSum(){
    if [ ${SUIF_SDC_ONLINE_MODE} -ne 0 ]; then
        logI "patchSum() ignored in online mode"
        return 0
    fi

    if [ ! -f "${1}" ]; then
        logE "[setupFunctions.sh/patchSum()] - Fixes images file ${1} does not exist!"
    fi
    local SUM_HOME=${2:-"/opt/sag/sum"}
    local d=`date +%y-%m-%dT%H.%M.%S_%3N`

    if [ ! -d "${SUM_HOME}/UpdateManager" ]; then
        logI "Update manager missing, nothing to patch..."
        return 0
    fi

    logI "Updating SUM from image ${1} ..."
    pushd . >/dev/null
    cd "${SUM_HOME}/bin"
    controlledExec "./UpdateManagerCMD.sh -selfUpdate true -installFromImage "'"'"${1}"'"' "${d}.PatchSum"
    RESULT_controlledExec=$?
    if [ "${RESULT_controlledExec}" -ne 0 ]; then
        logE "[setupFunctions.sh/patchSum()] - Update Manager Self Update failed with code ${RESULT_controlledExec}"
        return 1
    fi
    popd >/dev/null
}

# Parameters - removeDiagnoserPatch
# $1 - Engineering patch diagnoser key (e.g. "5437713_PIE-68082_5")
# $2 - Engineering patch ids list (expected one id only, but we never know e.g. "5437713_PIE-68082_1.0.0.0005-0001")
# $3 - OTPIONAL SUM Home, default /opt/sag/sum
# $4 - OTPIONAL Products Home, default /opt/sag/products
removeDiagnoserPatch(){
    local SUM_HOME=${3:-"/opt/sag/sum"}
    if [ ! -f "${SUM_HOME}/bin/UpdateManagerCMD.sh" ]; then
        logE "[setupFunctions.sh/removeDiagnoserPatch()] - Update manager not found at the inficated location ${SUM_HOME}"
        return 1
    fi
    local PRODUCTS_HOME=${4:-"/opt/sag/products"}
    if [ ! -d "${PRODUCTS_HOME}" ]; then
        logE "[setupFunctions.sh/removeDiagnoserPatch()] - Product installation folder is missing: ${PRODUCTS_HOME}"
        return 2
    fi

    local d=`date +%y-%m-%dT%H.%M.%S_%3N`
    local tmpScriptFile="/dev/shm/fixes.${d}.wmscript.txt"

    echo "installSP=Y" > "${tmpScriptFile}"
    echo "diagnoserKey=${1}" >> "${tmpScriptFile}"
    echo "installDir=${PRODUCTS_HOME}" >>"${tmpScriptFile}"
    echo "selectedFixes=${2}" >>"${tmpScriptFile}"
    echo "action=Uninstall fixes" >> "${tmpScriptFile}"

    pushd . >/dev/null
    cd "${SUM_HOME}/bin"

    logI "Taking a snapshot of existing fixes..."
    controlledExec './UpdateManagerCMD.sh -action viewInstalledFixes -installDir "'"${PRODUCTS_HOME}"'"' "${d}.FixesBeforeSPRemoval"

    logI "Removing support patch ${1} from installation ${PRODUCTS_HOME} using SUM in ${SUM_HOME}..." 
    controlledExec "./UpdateManagerCMD.sh -readScript "${tmpScriptFile}"" "${d}.SPFixRemoval"
    RESULT_controlledExec=$?

    logI "Taking a snapshot of fixes after the execution of SP removal..."
    controlledExec './UpdateManagerCMD.sh -action viewInstalledFixes -installDir "'"${PRODUCTS_HOME}"'"' "${d}.FixesAfterSPRemoval"

    popd >/dev/null

    if [ ${RESULT_controlledExec} -eq 0 ]; then
        logI "Support patch removal was successful"
    else
        logE "[setupFunctions.sh/removeDiagnoserPatch()] - Support patch removal failed, code ${RESULT_controlledExec}"
        if [ ${SUIF_DEBUG_ON} ]; then
            logD "Recovering Update Manager logs for further investigations"
            mkdir -p ${SUIF_AUDIT_SESSION_DIR}/UpdateManager
            cp -r ${SUM_HOME}/logs ${SUIF_AUDIT_SESSION_DIR}/
            cp -r ${SUM_HOME}/UpdateManager/logs ${SUIF_AUDIT_SESSION_DIR}/UpdateManager/
            cp "${tmpScriptFile}" ${SUIF_AUDIT_SESSION_DIR}/
        fi
        return 3
    fi

    if [ ${SUIF_DEBUG_ON} -ne 0 ]; then
        # if we are debugging, we want to see the generated script
        cp "${tmpScriptFile}" "${SUIF_AUDIT_SESSION_DIR}/fixes.D.${d}.wmscript.txt"
    fi

    rm -f "${tmpScriptFile}"
}

# Parameters - patchInstallation
# $1 - Fixes Image (this will allways happen offline in this framework)
# $2 - OTPIONAL SUM Home, default /opt/sag/sum
# $3 - OTPIONAL Products Home, default /opt/sag/products
# $4 - OTPIONAL Engineering patch modifier (default "N")
# $5 - OTPIONAL Engineering patch diagnoser key (default "5437713_PIE-68082_5", however user must provide if $4=Y)
patchInstallation(){
    if [ ! -f ${1} ]; then
        logE "[setupFunctions.sh/patchInstallation()] - Fixes image file not found: ${1}"
        return 1
    fi

    local SUM_HOME=${2:-"/opt/sag/sum"}
    local PRODUCTS_HOME=${3:-"/opt/sag/products"}
    local d=`date +%y-%m-%dT%H.%M.%S_%3N`
    local epm=${4:-"N"}

    echo "installSP=${epm}" >/dev/shm/fixes.wmscript.txt
    echo "installDir=${PRODUCTS_HOME}" >>/dev/shm/fixes.wmscript.txt
    echo "selectedFixes=spro:all" >>/dev/shm/fixes.wmscript.txt
    echo "action=Install fixes from image" >> /dev/shm/fixes.wmscript.txt
    echo "imageFile=${1}" >> /dev/shm/fixes.wmscript.txt

    if [ "${epm}" == "Y" ]; then
        local dKey=${5:-"5437713_PIE-68082_5"}
        echo "diagnoserKey=${dKey}" >> /dev/shm/fixes.wmscript.txt
    fi

    pushd . >/dev/null
    cd "${SUM_HOME}/bin"

    logI "Taking a snapshot of existing fixes..."
    controlledExec './UpdateManagerCMD.sh -action viewInstalledFixes -installDir "'"${PRODUCTS_HOME}"'"' "${d}.FixesBeforePatching"

    logI "Explictly patch SUM itself, if required..."
    patchSum "${1}" "${SUM_HOME}"

    logI "Applying fixes from image ${1} to installation ${PRODUCTS_HOME} using SUM in ${SUM_HOME}..." 

    controlledExec "./UpdateManagerCMD.sh -readScript /dev/shm/fixes.wmscript.txt" "${d}.PatchInstallation"
    RESULT_controlledExec=$?

    logI "Taking a snapshot of fixes after the patching..."
    controlledExec './UpdateManagerCMD.sh -action viewInstalledFixes -installDir "'"${PRODUCTS_HOME}"'"' "${d}.FixesAfterPatching"

    popd >/dev/null

    if [ ${RESULT_controlledExec} -eq 0 ]; then
        logI "Patch successful"
    else
        logE "[setupFunctions.sh/patchInstallation()] - Patch failed, code ${RESULT_controlledExec}"
        if [ ${SUIF_DEBUG_ON} ]; then
            logD "Recovering Update Manager logs for further investigations"
            mkdir -p ${SUIF_AUDIT_SESSION_DIR}/UpdateManager
            cp -r ${SUM_HOME}/logs ${SUIF_AUDIT_SESSION_DIR}/
            cp -r ${SUM_HOME}/UpdateManager/logs ${SUIF_AUDIT_SESSION_DIR}/UpdateManager/
            cp /dev/shm/fixes.wmscript.txt ${SUIF_AUDIT_SESSION_DIR}/
        fi
        return 2
    fi

    if [ ${SUIF_DEBUG_ON} -ne 0 ]; then
        # if we are debugging, we want to see the generated script
        cp /dev/shm/fixes.wmscript.txt "${SUIF_AUDIT_SESSION_DIR}/fixes.${d}.wmscript.txt"
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
        logE "[setupFunctions.sh/setupProductsAndFixes()] - Installer binary file not found: ${1}"
        return 1
    fi
    if [ ! -f ${2} ]; then
        logE "[setupFunctions.sh/setupProductsAndFixes()] - Installer script file not found: ${2}"
        return 2
    fi

    if [ "${SUIF_PATCH_AVAILABLE}" -ne 0 ];  then 
        if [ ! -f ${3} ]; then
                logE "[setupFunctions.sh/setupProductsAndFixes()] - Update Manager bootstrap binary file not found: ${3}"
                return 3
        fi
        if [ ! -f ${4} ]; then
            logE "[setupFunctions.sh/setupProductsAndFixes()] - Fixes image file not found: ${4}"
            return 4
        fi
    fi
    if [ ! $(which envsubst) ]; then
        logE "[setupFunctions.sh/setupProductsAndFixes()] - Product installation requires envsubst to be installed!"
        return 5
    fi
    # apply environment substitutions
    # Note: this is done twice for reusability reasons
    envsubst < "${2}" > /dev/shm/install.wmscript.tmp

    local lProductImageFile=$(grep imageFile /dev/shm/install.wmscript.tmp | cut -d "=" -f 2)

    # note no inline returns from now as we need to clean locally allocated resources
    if [ ! -f "${lProductImageFile}" ]; then
        logE "[setupFunctions.sh/setupProductsAndFixes()] - Product image file not found: ${lProductImageFile}. Does the wmscript have the imageFile=... line?"
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
            logE "[setupFunctions.sh/setupProductsAndFixes()] - Cannot create the installation directory!"
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
                logE "[setupFunctions.sh/setupProductsAndFixes()] - installProducts failed, code ${RESULT_installProducts}!"
                RESULT_setupProductsAndFixes=8
            else

                if [ "${SUIF_PATCH_AVAILABLE}" -ne 0 ];  then 

                    # Parameters - bootstrapSum
                    # $1 - Update Manager Boostrap file
                    # $2 - OTPIONAL Where to install (SUM Home), default /opt/sag/sum
                    local lSumHome=${5:-"/opt/sag/sum"}
                    bootstrapSum "${3}" "${4}" "${lSumHome}"
                    local RESULT_bootstrapSum=$?
                    if [ ${RESULT_bootstrapSum} -ne 0 ]; then
                        logE "[setupFunctions.sh/setupProductsAndFixes()] - Update Manager bootstrap failed, code ${RESULT_bootstrapSum}!"
                        RESULT_setupProductsAndFixes=9
                    else
                        # Parameters - patchInstallation
                        # $1 - Fixes Image (this will allways happen offline in this framework)
                        # $2 - OTPIONAL SUM Home, default /opt/sag/sum
                        # $3 - OTPIONAL Products Home, default /opt/sag/products
                        patchInstallation "${4}" "${lSumHome}" "${lInstallDir}"
                        RESULT_patchInstallation=$?
                        if [ ${RESULT_patchInstallation} -ne 0 ]; then
                            logE "[setupFunctions.sh/setupProductsAndFixes()] - Patch Installation failed, code ${RESULT_patchInstallation}!"
                            RESULT_setupProductsAndFixes=10
                        else
                            logI "Product and Fixes setup completed successfully"
                            RESULT_setupProductsAndFixes=0
                        fi
                    fi
                else
                    logI "Skipping patch installation, fixes not available."
                fi
            fi
        fi
    fi
    return ${RESULT_setupProductsAndFixes}
}

# Parameters - applySetupTemplate
# $1 - Setup template directory, relative to <repo_home>/02.templates/01.setup
# Environment must have valid values for vars SUIF_CACHE_HOME, SUIF_INSTALL_INSTALLER_BIN, SUIF_PATCH_SUM_BOOSTSTRAP_BIN, SUIF_SUM_HOME
# Environment must also have valid values for the vars required by the referred template
applySetupTemplate(){
    # TODO: render checkPrerequisites.sh optional
    logI "Applying Setup Template ${1}"
    huntForSuifFile "02.templates/01.setup/${1}" "template.wmscript" || return 1
    huntForSuifFile "02.templates/01.setup/${1}" "setEnvDefaults.sh" || return 2
    huntForSuifFile "02.templates/01.setup/${1}" "checkPrerequisites.sh" || return 4
    logI "Sourcing variable values for template ${1} ..."
    . "${SUIF_CACHE_HOME}/02.templates/01.setup/${1}/setEnvDefaults.sh"
    logI "Checking installation prerequisites for template ${1} ..."
    chmod u+x "${SUIF_CACHE_HOME}/02.templates/01.setup/${1}/checkPrerequisites.sh" > /dev/null
    if [ -f "${SUIF_CACHE_HOME}/02.templates/01.setup/${1}/checkPrerequisites.sh" ]; then
        "${SUIF_CACHE_HOME}/02.templates/01.setup/${1}/checkPrerequisites.sh" || return 5
    fi
    chmod u+x "${SUIF_CACHE_HOME}/02.templates/01.setup/${1}/setEnvDefaults.sh" > /dev/null
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
        logE "[setupFunctions.sh/applySetupTemplate()] - Setup for template ${1} failed, code ${RESULT_setupProductsAndFixes}"
        return 3
    fi
}

# Parameters - assureDownloadableFile
# $1 - Target File: a local path of the file to be assured
# $2 - URL from where to get
# $3 - SHA256 sum of the file (Use before reuse: for now we only need sha256sum)
# $4 - Optional (future TODO - BA user for the URL)
# $5 - Optional (future TODO - BA pass for the URL)
assureDownloadableFile(){
    if [ ! -f "${1}" ]; then
        logI "File ${1} does not exist, attempting download from ${2}"
        if ! which curl ; then
            logE "[setupFunctions.sh/assureDownloadableFile()] - Cannot find curl"
            return 1
        fi
        if ! curl "${2}" -o "${1}" ; then
            logE "[setupFunctions.sh/assureDownloadableFile()] - Cannot download from ${2}"
            return 2 
        fi
        if [ ! -f "${1}" ]; then
            logE "[setupFunctions.sh/assureDownloadableFile()] - File ${1} waa not downloaded even if curl command succeded"
            return 3
        fi
    fi
    if ! echo "${3} ${1}" | sha256sum -c - ; then
        logE "[setupFunctions.sh/assureDownloadableFile()] - sha256sum check for file ${1} failed"
        return 4
    fi
}

# Parameters
# $1 - OPTIONAL installer binary location, defaulted to ${SUIF_INSTALL_INSTALLER_BIN}, which is also defaulted to /tmp/installer.bin
assureDefaultInstaller(){
    local installerUrl="https://empowersdc.softwareag.com/ccinstallers/SoftwareAGInstaller20220221-Linux_x86_64.bin"
    local installerSha256Sum="ef59cbead6086da9b844bc02eca34440ad14ed7af6c828721f883f37ec958a2f"
    SUIF_INSTALL_INSTALLER_BIN="${SUIF_INSTALL_INSTALLER_BIN:-/tmp/installer.bin}"
    local installerBin="${1:-$SUIF_INSTALL_INSTALLER_BIN}"
    if ! assureDownloadableFile "${installerBin}" "${installerUrl}" "${installerSha256Sum}" ; then
        logE "[setupFunctions.sh/assureDefaultInstaller()] - Cannot assure default installer!"
        return 1
    fi
}

# Parameters
# $1 - OPTIONAL SUM bootstrap binary location, defaulted to ${SUIF_PATCH_SUM_BOOSTSTRAP_BIN}, which is also defaulted to /tmp/sum-bootstrap.bin
assureDefaultSumBoostrap(){
    local sumBoostrapUrl="https://empowersdc.softwareag.com/ccinstallers/SoftwareAGUpdateManagerInstaller20210921-11-LinuxX86.bin"
    local sumBoostrapSha256Sum="4cf2fcb232500674f6d8189588ad3dd6a8f1c1723dc41670fdd610c88c2c2020"
    SUIF_PATCH_SUM_BOOSTSTRAP_BIN="${SUIF_PATCH_SUM_BOOSTSTRAP_BIN:-/tmp/sum-bootstrap.bin}"
    local lSumBootstrap="${1:-SUIF_PATCH_SUM_BOOSTSTRAP_BIN}"
    if ! assureDownloadableFile ${lSumBootstrap} "${sumBoostrapUrl}" "${sumBoostrapSha256Sum}" ; then
        logE "[setupFunctions.sh/assureDefaultSumBoostrap()] - Cannot assure default sum bootstrap!"
        return 1
    fi
}

# TODO: generalize
# Parameters
# $1 -> setup template
# $2 -> OPTIONAL - output folder, default /tmp/images/product
# $3 -> OPTIONAL - fixes tag. Defaulted to current day
# $4 -> OPTIONAL - platform string, default LNXAMD64
# $5 -> OPTIONAL - sum home, default /tmp/sumv11
# $6 -> OPTIONAL - sum-bootstrap binary location, default /tmp/sum-bootstrap.bin
# NOTE: pass SDC credentials in env variables SUIF_EMPOWER_USER and SUIF_EMPOWER_PASSWORD
generateFixesImageFromTemplate(){
    local lCrtDate=$(date +%y-%m-%d)
    local lFixesTag="${3:-$lCrtDate}"
    logI "Addressing fixes image for setup template ${1} and tag ${lFixesTag}..."

    local lOutputDir="${2:-/tmp/images/fixes}"
    local lFixesDir="${lOutputDir}/${1}/${lFixesTag}"
    mkdir -p "${lFixesDir}"
    local lFixesImageFile="${lFixesDir}/fixes.zip"
    local lPermanentInventoryFile="${lFixesDir}/inventory.json"
    local lPermanentScriptFile="${lFixesDir}/createFixesImage.wmscript"
    local lPlatformString="${4:-LNXAMD64}"

    if [ -f "${lFixesImageFile}" ]; then
        logI "[setupFunctions.sh/generateFixesImageFromTemplate()] - Fixes image for template ${1} and tag ${lFixesTag} already exists, nothing to do."
        return 0
    fi

    local lSumHome="${5:-/tmp/sumv11}"
    if [ ! -d "${lSumHome}/bin" ]; then
        logW "[setupFunctions.sh/generateFixesImageFromTemplate()] - SUM Home does not contain a SUM installation, trying to bootstrap now..."
        local lSumBootstrapBin=${6:-/tmp/sum-bootstrap.bin}
        if [ ! -f "${lSumBootstrapBin}" ]; then
            logW "[setupFunctions.sh/generateFixesImageFromTemplate()] - SUM Bootstrap binary not found, trying to obtain the default one..."
            assureDefaultSumBoostrap "${lSumBootstrapBin}" || return $?
            # Parameters - bootstrapSum
            # $1 - Update Manager Boostrap file
            # $2 - Fixes image file, mandatory for offline mode
            # $3 - OTPIONAL Where to install (SUM Home), default /opt/sag/sum
            # NOTE: SUIF_SDC_ONLINE_MODE must be 1 (non 0)
            bootstrapSum "${lSumBootstrapBin}" '' "${lSumHome}" || return $?
        fi
    fi

    if [ -f "${lPermanentInventoryFile}" ];then
        logI "[setupFunctions.sh/generateFixesImageFromTemplate()] - Inventory file ${lPermanentInventoryFile} already exists, skipping creation."
    else
        logI "[setupFunctions.sh/generateFixesImageFromTemplate()] - Inventory file ${lPermanentInventoryFile} does not exists, creating now."
        pwsh "${SUIF_HOME}/01.scripts/pwsh/generateInventoryFileFromInstallScript.ps1" \
            -file "${SUIF_HOME}/02.templates/01.setup/${1}/template.wmscript" -outfile "${lPermanentInventoryFile}" \
            -sumPlatformString "${lPlatformString}"
    fi

    if [ -f "${lPermanentScriptFile}" ];then
        logI "[setupFunctions.sh/generateFixesImageFromTemplate()] - Permanent script file ${lPermanentScriptFile} already exists, skipping creation..."
    else
        logI "[setupFunctions.sh/generateFixesImageFromTemplate()] - Permanent script file ${lPermanentScriptFile} does not exist, creating now..."
        echo "# Generated" > "${lPermanentScriptFile}"
        echo "scriptConfirm=N" >> "${lPermanentScriptFile}"
        # use before reuse -> diagnosers not covered for now
        echo "installSP=N " >> "${lPermanentScriptFile}"
        echo "action=Create or add fixes to fix image" >> "${lPermanentScriptFile}"
        echo "selectedFixes=spro:all" >> "${lPermanentScriptFile}"
        echo "installDir=${lPermanentInventoryFile}" >> "${lPermanentScriptFile}"
        echo "imagePlatform=${lPlatformString}" >> "${lPermanentScriptFile}"
        echo "createEmpowerImage=C " >> "${lPermanentScriptFile}"
    fi

    local lCmd="./UpdateManagerCMD.sh -selfUpdate false -readScript "'"'"${lPermanentScriptFile}"'"'
    lCmd="${lCmd} -installDir "'"'"${lPermanentInventoryFile}"'"'
    lCmd="${lCmd} -imagePlatform ${lPlatformString}"
    lCmd="${lCmd} -createImage "'"'"${lFixesImageFile}"'"' 
    lCmd="${lCmd} -empowerUser ${SUIF_EMPOWER_USER}"
    echo "SUM command to execute: ${lCmd} -empowerPass ***"
    lCmd="${lCmd} -empowerPass '${SUIF_EMPOWER_PASSWORD}'"

    pushd . >/dev/null
    cd "${lSumHome}/bin"
    controlledExec "${lCmd}" "Create-fixes-image-for-template-${1//\//-}-tag-${lFixesTag}"
    local lResultFixCreation=$?
    popd >/dev/null
    logI "[setupFunctions.sh/generateFixesImageFromTemplate()] - Fix image creation for template ${1} finished, result: ${lResultFixCreation}"
}

# Parameters
# $1 -> setup template
# $2 -> OPTIONAL - installer binary location, default /tmp/installer.bin
# $3 -> OPTIONAL - output folder, default /tmp/images/product
# $4 -> OPTIONAL - platform string, default LNXAMD64
# NOTE: default URLs for download are fit for Europe. Use the ones without "-hq" for Americas
# NOTE: pass SDC credentials in env variables SUIF_EMPOWER_USER and SUIF_EMPOWER_PASSWORD
# NOTE: /dev/shm/productsImagesList.txt may be created upfront if image caches are available
generateProductsImageFromTemplate(){

    local lDebugOn=${SUIF_DEBUG_ON:-0}

    logI "Addressing products image for setup template ${1}..."
    local lInstallerBin="${2:-/tmp/installer.bin}"
    if [ ! -f ${lInstallerBin} ]; then
        logE "[setupFunctions.sh/generateProductsImageFromTemplate()] - Installer file ${lInstallerBin} not found, attempting to use the default one..."
        assureDefaultInstaller "${lInstallerBin}" || return 1
    fi
    local lProductImageOutputDir="${3:-/tmp/images/product}"
    local lProductsImageFile="${lProductImageOutputDir}/${1}/products.zip"

    if [ -f "${lProductsImageFile}" ]; then
        logI "[setupFunctions.sh/generateProductsImageFromTemplate()] - Products image for template ${1} already exists, nothing to do."
        return 0
    fi

    local lDebugLogFile="${lProductImageOutputDir}/${1}/debug.log"

    local lPermanentScriptFile="${lProductImageOutputDir}/${1}/createProductImage.wmscript"
    if [ -f "${lPermanentScriptFile}" ]; then
        logI "[setupFunctions.sh/generateProductsImageFromTemplate()] - Permanent product image creation script file already present... Using the existing one."
    else
        logI "[setupFunctions.sh/generateProductsImageFromTemplate()] - Permanent product image creation script file not present, creating now..."
        local lPlatformString=${4:-LNXAMD64}

        # current default
        if [[ ${1} == *"/1011/"* ]]; then
            local lSdcServerUrl=${SUIF_SDC_SERVER_URL_1011:-"https\://sdc-hq.softwareag.com/cgi-bin/dataservewebM1011.cgi"}
        else
            if [[ ${1} == *"/1005/"* ]]; then
                lSdcServerUrl=${SUIF_SDC_SERVER_URL_1005:-"https\://sdc-hq.softwareag.com/cgi-bin/dataservewebM105.cgi"}
            else
                if [[ ${1} == *"/1007/"* ]]; then
                    lSdcServerUrl=${SUIF_SDC_SERVER_URL_1007:-"https\://sdc-hq.softwareag.com/cgi-bin/dataservewebM107.cgi"}
                else
                    logW "[setupFunctions.sh/generateProductsImageFromTemplate()] - Unsupported version in template ${1}. Continuing using the 10.11 SDC URL..."
                fi
            fi
        fi

        mkdir -p "${lProductImageOutputDir}/${1}"
        echo "###Generated" > "${lPermanentScriptFile}"
        echo "LicenseAgree=Accept" >> "${lPermanentScriptFile}"
        echo "InstallLocProducts=" >> "${lPermanentScriptFile}"
        cat "${SUIF_HOME}/02.templates/01.setup/${1}/template.wmscript" | \
            grep "InstallProducts" >> "${lPermanentScriptFile}"
        echo "imagePlatform=${lPlatformString}" >> "${lPermanentScriptFile}"
        echo "imageFile=${lProductsImageFile}" >> "${lPermanentScriptFile}"
        echo "ServerURL=${lSdcServerUrl}" >> "${lPermanentScriptFile}"

        logI "[setupFunctions.sh/generateProductsImageFromTemplate()] - Permanent product image creation script file created"
    fi

    logI "[setupFunctions.sh/generateProductsImageFromTemplate()] - Creating the volatile script ..."
    local lVolatileScriptFile="/dev/shm/SUIF/setup/templates/${1}/createProductImage.wmscript"
    mkdir -p "/dev/shm/SUIF/setup/templates/${1}/"
    cp "${lPermanentScriptFile}" "${lVolatileScriptFile}"
    echo "Username=${SUIF_EMPOWER_USER}" >> "${lVolatileScriptFile}"
    echo "Password=${SUIF_EMPOWER_PASSWORD}" >> "${lVolatileScriptFile}"
    logI "Volatile script created."

    ## TODO: check if error management enforcement is needed: what if the grep produced nothing?
    ## TODO: dela with \ escaping in the password. For now avoid using '\' - backslash in the password string

    ## TODO: not space safe, but it shouldn't matter for now
    local lCmd="${lInstallerBin} -readScript ${lVolatileScriptFile}"
    if [ "${lDebugOn}" -ne 0 ]; then
        lCmd="${lCmd} -debugFile '${lDebugLogFile}' -debugLvl verbose"
    fi
    lCmd="${lCmd} -writeImage ${lProductsImageFile}"
    # explictly tell installer we are running unattended
    lCmd="${lCmd} -scriptErrorInteract no"

    # avoid downloading what we already have
    if [ -s /dev/shm/productsImagesList.txt ]; then
        lCmd="${lCmd} -existingImages /dev/shm/productsImagesList.txt"
    fi

    logI "[setupFunctions.sh/generateProductsImageFromTemplate()] - Creating the product image ${lProductsImageFile}... This may take some time..."
    logD "[setupFunctions.sh/generateProductsImageFromTemplate()] - Command is ${lCmd}"
    controlledExec "${lCmd}" "Create-products-image-for-template-${1//\//-}"
    local lCreateImgResult=$?
    logI "[setupFunctions.sh/generateProductsImageFromTemplate()] - Image ${lProductsImageFile} creation completed, result: ${lCreateImgResult}"
    rm -f "${lVolatileScriptFile}"

    return ${lCreateImgResult}
}

logI "Setup Functions sourced"