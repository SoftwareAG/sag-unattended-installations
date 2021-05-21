#!/bin/sh

# This scripts sets up the local installation

. "${SUIF_LOCAL_SCRIPTS_HOME}/set_env.sh" || exit 1

onInterrupt(){
    echo "Interrupted!"
}

onKill(){
	echo "Killed!"
}

# Parameters
# $1 -> setup template
# $2 -> OPTIONAL - platform string, default LNXAMD64
generateProductsImageFromTemplate(){
    logI "Addressing products image for setup template ${1}..."
    local lProductsImageFile="${SUIF_PRODUCT_IMAGES_OUTPUT_DIRECTORY}/${templateId}/products.zip"
    if [ -f "${lProductsImageFile}" ]; then
        logI "Products image for template ${1} already exists, nothing to do."
    else
        local lPermanentScritpFile="${SUIF_PRODUCT_IMAGES_OUTPUT_DIRECTORY}/${1}/createProductImage.wmscript"
        if [ -f "${lPermanentScritpFile}" ]; then
            logI "Permanent product image creation script file already present..."
        else
            logI "Permanent product image creation script file not present, creating now..."

            local lPlatformString=${2:-LNXAMD64}

            mkdir -p "${SUIF_PRODUCT_IMAGES_OUTPUT_DIRECTORY}/${1}"
            echo "###Generated" > "${lPermanentScritpFile}"
            echo "LicenseAgree=Accept" >> "${lPermanentScritpFile}"
            echo "InstallLocProducts=" >> "${lPermanentScritpFile}"
            cat "${SUIF_USER_HOME}/SUIF/sag-unattented-installations/02.templates/01.setup/${1}/template.wmscript" | \
                grep "InstallProducts" >> "${lPermanentScritpFile}"
            echo "imagePlatform=${lPlatformString}" >> "${lPermanentScritpFile}"
            echo "imageFile=${lProductsImageFile}" >> "${lPermanentScritpFile}"

            logI "Permanent product image creation script file created"
        fi

        logI "Creating the volatile script ..."
        local lVolatileScritpFile="/dev/shm/SUIF/setup/templates/${templateId}/createProductImage.wmscript"
        mkdir -p "/dev/shm/SUIF/setup/templates/${templateId}/"
        cp "${lPermanentScritpFile}" "${lVolatileScritpFile}"
        echo "Username=${SUIF_EMPOWER_USER}" >> "${lVolatileScritpFile}"
        echo "Password=${SUIF_EMPOWER_PASSWORD}" >> "${lVolatileScritpFile}"
        logI "Volatile script created..."
        ## TODO: check if error management enforcement is needed: what if the grep produced nothing?

        ## TODO: not space safe, but it shouldn't matter for now
        local lCmd="${SUIF_INSTALL_INSTALLER_BIN} -readScript ${lVolatileScritpFile}"
        lCmd="${lCmd} -writeImage ${lProductsImageFile}"

        logI "Creating the product image ${lProductsImageFile}... "
        controlledExec "${lCmd}" "Create-products-image-for-template-${1//\//-}"
        logI "Image ${lProductsImageFile} creation completed, result: $?"
        rm -f "${lVolatileScritpFile}"
    fi
}

trap "onInterrupt" SIGINT SIGTERM
trap "onKill" SIGKILL

mkdir "${SUIF_USER_HOME}/SUIF"
cd "${SUIF_USER_HOME}/SUIF"
git clone https://github.com/Myhael76/sag-unattented-installations.git

find . -type f -name *.sh -exec chmod u+x "{}" \;
. "${SUIF_USER_HOME}/SUIF/sag-unattented-installations/01.scripts/commonFunctions.sh"
. "${SUIF_USER_HOME}/SUIF/sag-unattented-installations/01.scripts/installation/setupFunctions.sh"

# Parameters - bootstrapSum
# $1 - Update Manager Boostrap file
# $2 - Fixes image file, mandatory for offline mode
# $3 - OTPIONAL Where to install (SUM Home), default /opt/sag/sum
#bootstrapSum "${SUIF_PATCH_SUM_BOOSTSTRAP_BIN}" "" "${SUIF_SUM_HOME}" 

logI "Inspecting SUIF for setup templates"
cd "${SUIF_USER_HOME}/SUIF/sag-unattented-installations/02.templates/01.setup"
find . -type f -name template.wmscript -print0 | while IFS= read -r -d '' wmsfile; do
    templateId=${wmsfile%'/template.wmscript'}
    templateId=${templateId#'./'}
    logI "Found template ${templateId} (from file ${wmsfile})"

    # Parameters
    # $1 -> setup template
    # $2 -> platform string
    generateProductsImageFromTemplate "${templateId}" "${SUIF_PLATFORM_STRING}"

    ## TODO: I remained here, produce images for...
done


if [ "${SUIF_DEBUG_ON}" -eq 1 ]; then
    logD "Stopping execution for debug"
    tail -f /dev/null
fi