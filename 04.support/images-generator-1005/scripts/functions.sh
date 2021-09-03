#!/bin/bash

# This scripts sets up the local installation

. "${SUIF_LOCAL_SCRIPTS_HOME}/set_env.sh" || exit 1

# Parameters
# $1 -> setup template
# $2 -> OPTIONAL - platform string, default LNXAMD64
generateFixesImageFromTemplate(){
    logI "Addressing fixes image for setup template ${1} and tag ${SUIF_FIXES_DATE_TAG}..."
    local lFixesDir="${SUIF_FIX_IMAGES_OUTPUT_DIRECTORY}/${1}/${SUIF_FIXES_DATE_TAG}"
    mkdir -p ${lFixesDir}
    local lFixesImageFile="${lFixesDir}/fixes.zip"
    local lPermanentInventoryFile="${lFixesDir}/inventory.json"
    local lPermanentScriptFile="${lFixesDir}/createFixesImage.wmscript"
    local lPlatformString=${2:-LNXAMD64}

    if [ -f "${lFixesImageFile}" ]; then
        logI "Fixes image for template ${1} and tag ${SUIF_FIXES_DATE_TAG} already exists, nothing to do."
    else
        if [ -f "${lPermanentInventoryFile}" ];then
            logI "Inventory file ${lPermanentInventoryFile} already exists, skipping creation."
        else
            logI "Inventory file ${lPermanentInventoryFile} does not exists, creating now."
            pwsh "${SUIF_HOME}/01.scripts/pwsh/generateInventoryFileFromInstallScript.ps1" \
                -file "${wmsfile}" -outfile "${lPermanentInventoryFile}" \
                -sumPlatformString "${lPlatformString}"
        fi

        if [ -f "${lPermanentScriptFile}" ];then
            logI "Permanent script file ${lPermanentScriptFile} already exists, skipping creation..."
        else
            logI "Permanent script file ${lPermanentScriptFile} does not exist, creating now..."
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
        lCmd="${lCmd} -empowerPass '${SUIF_EMPOWER_PASSWORD}'"

        pushd . >/dev/null
        cd "${SUIF_SUM_HOME}/bin"
        controlledExec "${lCmd}" "Create-fixes-image-for-template-${1//\//-}-tag-${SUIF_FIXES_DATE_TAG}"
        local lResultFixCreation=$?
        popd >/dev/null
        logI "Fix image creation for template ${1} finished, result: ${lResultFixCreation}"
    fi
}

# Parameters
# $1 -> setup template
# $2 -> OPTIONAL - platform string, default LNXAMD64
generateProductsImageFromTemplate(){
    logI "Addressing products image for setup template ${1}..."
    local lProductsImageFile="${SUIF_PRODUCT_IMAGES_OUTPUT_DIRECTORY}/${1}/products.zip"
    local lDebugLogFile="${SUIF_PRODUCT_IMAGES_OUTPUT_DIRECTORY}/${1}/debug.log"
    if [ -f "${lProductsImageFile}" ]; then
        logI "Products image for template ${1} already exists, nothing to do."
    else
        local lPermanentScriptFile="${SUIF_PRODUCT_IMAGES_OUTPUT_DIRECTORY}/${1}/createProductImage.wmscript"
        if [ -f "${lPermanentScriptFile}" ]; then
            logI "Permanent product image creation script file already present..."
        else
            logI "Permanent product image creation script file not present, creating now..."

            local lPlatformString=${2:-LNXAMD64}

            # TODO: streamline

            # current default
            local lSdcServerUrl=${SUIF_SDC_SERVER_URL_1007:-"https\://sdc-hq.softwareag.com/cgi-bin/dataservewebM107.cgi"}
            if [[ ${1} == *"/1005/"* ]]; then
                lSdcServerUrl=${SUIF_SDC_SERVER_URL_1005:-"https\://sdc-hq.softwareag.com/cgi-bin/dataservewebM105.cgi"}
            else
                if [[ ${1} == *"/1011/"* ]]; then
                    logW "10.11 is not yet public..."
                    # Exception for preview mode

                    SUIF_EMPOWER_USER=${SUIF_SDC_1011_USER_NAME:-${SUIF_EMPOWER_USER}}
                    SUIF_EMPOWER_PASSWORD=${SUIF_SDC_1011_USER_PASSWORD:-${SUIF_EMPOWER_PASSWORD}}

                    logI "Installer download user set to ${SUIF_EMPOWER_USER}"
                    lSdcServerUrl=${SUIF_SDC_SERVER_URL_1011:-"https\://sdc-hq.softwareag.com/cgi-bin/dataservewebM1011.cgi"}
                fi
            fi

            mkdir -p "${SUIF_PRODUCT_IMAGES_OUTPUT_DIRECTORY}/${1}"
            echo "###Generated" > "${lPermanentScriptFile}"
            echo "LicenseAgree=Accept" >> "${lPermanentScriptFile}"
            echo "InstallLocProducts=" >> "${lPermanentScriptFile}"
            cat "${SUIF_HOME}/02.templates/01.setup/${1}/template.wmscript" | \
                grep "InstallProducts" >> "${lPermanentScriptFile}"
            echo "imagePlatform=${lPlatformString}" >> "${lPermanentScriptFile}"
            echo "imageFile=${lProductsImageFile}" >> "${lPermanentScriptFile}"
            echo "ServerURL=${lSdcServerUrl}" >> "${lPermanentScriptFile}"

            logI "Permanent product image creation script file created"
        fi

        logI "Creating the volatile script ..."
        local lVolatileScriptFile="/dev/shm/SUIF/setup/templates/${1}/createProductImage.wmscript"
        mkdir -p "/dev/shm/SUIF/setup/templates/${1}/"
        cp "${lPermanentScriptFile}" "${lVolatileScriptFile}"
        echo "Username=${SUIF_EMPOWER_USER}" >> "${lVolatileScriptFile}"
        echo "Password=${SUIF_EMPOWER_PASSWORD}" >> "${lVolatileScriptFile}"
        logI "Volatile script created."
        ## TODO: check if error management enforcement is needed: what if the grep produced nothing?

        local lDebugOn=${SUIF_DEBUG_ON:-0}

        ## TODO: not space safe, but it shouldn't matter for now
        local lCmd="${SUIF_INSTALL_INSTALLER_BIN} -readScript ${lVolatileScriptFile}"
        if [ "${lDebugOn}" -ne 0 ]; then
            lCmd="${lCmd} -debugFile '${lDebugLogFile}' -debugLvl verbose"
        fi
        lCmd="${lCmd} -writeImage ${lProductsImageFile}"
        #explictly tell installer we are running unattended
        lCmd="${lCmd} -scriptErrorInteract no"

        # avoid downloading what we already have
        if [ -f /dev/shm/productsImagesList.txt ]; then
            lCmd="${lCmd} -existingImages /dev/shm/productsImagesList.txt"
        fi

        logI "Creating the product image ${lProductsImageFile}... "
        logD "Command is ${lCmd}"
        controlledExec "${lCmd}" "Create-products-image-for-template-${1//\//-}"
        logI "Image ${lProductsImageFile} creation completed, result: $?"
        rm -f "${lVolatileScriptFile}"

        echo "lProductsImageFile" >> /dev/shm/productsImagesList.txt
    fi
}
