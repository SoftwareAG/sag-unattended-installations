#!/bin/sh

# shellcheck source=/dev/null

# shellcheck disable=SC3043
# shellcheck disable=SC3044
# shellcheck disable=SC3060

# our SUIF related parameters

assureVariables(){
  SUIF_INSTALL_INSTALLER_BIN="${TEST_OUTPUT_FOLDER}/installer.bin"
  export SUIF_INSTALL_INSTALLER_BIN

  SUIF_PATCH_SUM_BOOTSTRAP_BIN="${TEST_OUTPUT_FOLDER}/sum-bootstrap.bin"
  export SUIF_PATCH_SUM_BOOTSTRAP_BIN

  SUIF_PRODUCT_IMAGES_SHARED_DIRECTORY="${TEST_OUTPUT_FOLDER}/products"
  export SUIF_PRODUCT_IMAGES_SHARED_DIRECTORY
  SUIF_FIX_IMAGES_SHARED_DIRECTORY="${TEST_OUTPUT_FOLDER}/fixes"
  export SUIF_FIX_IMAGES_SHARED_DIRECTORY

  SUIF_AUDIT_BASE_DIR="${SUIF_AUDIT_BASE_DIR:-$TEST_OUTPUT_FOLDER/audit}"
  export SUIF_AUDIT_BASE_DIR

  SUIF_SESSION_TIMESTAMP="${SUIF_SESSION_TIMESTAMP:-$(date +%Y-%m-%dT%H.%M.%S_%3N)}"
  export SUIF_SESSION_TIMESTAMP

  SUIF_SUM_HOME="${SUIF_SUM_HOME:-"/tmp/sumv11"}"
  export SUIF_SUM_HOME

  SUIF_FIXES_DATE_TAG="$(date +%y-%m-%d)"
  export SUIF_FIXES_DATE_TAG

  SUIF_PRODUCT_IMAGES_PLATFORM="LNXAMD64"
  export SUIF_PRODUCT_IMAGES_PLATFORM

  TEST_Templates=${TEST_Templates:-"MSR/1011/lean"}
  export TEST_Templates
}

assureVariables

. "${SUIF_HOME}/01.scripts/commonFunctions.sh"
. "${SUIF_HOME}/01.scripts/installation/setupFunctions.sh"

checkEmpowerCredentials    || logW "Provided Empower credentials are incorrect!"
assureDefaultInstaller     || logW "Default installer not assured! Eventually clean the output folder."
assureDefaultSumBoostrap   || logW "Default Update Manager Bootstrap not assured! Eventually clean the output folder."

logI "Installing Update Manager..."
# mkdir -p "${SUIF_SUM_HOME}"
if ! bootstrapSum "${SUIF_PATCH_SUM_BOOTSTRAP_BIN}" "" "${SUIF_SUM_HOME}"; then
  logE "SUM bootstrap failed with code $?, stopping for debug. CTRL-C for the next instructions"
  tail -f /dev/null
fi

# Params:
# $1 - Template ID
processTemplate() {
  logI "Processing template ${template}..."

  if [ -f "${SUIF_PRODUCT_IMAGES_SHARED_DIRECTORY}/${1}}/products.zip" ]; then
    logI "Products image for template ${1} already exists, nothing to do."
  else
    # Parameters
    # $1 -> setup template
    # $2 -> OPTIONAL - installer binary location, default /tmp/installer.bin
    # $3 -> OPTIONAL - output folder, default /tmp/images/product
    # $4 -> OPTIONAL - platform string, default LNXAMD64
    # NOTE: default URLs for download are fit for Europe. Use the ones without "-hq" for Americas
    # NOTE: pass SDC credentials in env variables SUIF_EMPOWER_USER and SUIF_EMPOWER_PASSWORD
    # NOTE: /dev/shm/productsImagesList.txt may be created upfront if image caches are available
    generateProductsImageFromTemplate \
      "${template}" \
      "${SUIF_INSTALL_INSTALLER_BIN}" \
      "${SUIF_PRODUCT_IMAGES_SHARED_DIRECTORY}" \
      "${SUIF_PRODUCT_IMAGES_PLATFORM}"
    
    logI "Products file generated for template ${template}"
  fi

  if [ -f "${SUIF_FIX_IMAGES_SHARED_DIRECTORY}/${1}/${SUIF_FIXES_DATE_TAG}/fixes.zip" ]; then
    logI "Fixes image for template ${1} and tag ${SUIF_FIXES_DATE_TAG} already exists, nothing to do."
  else
    # TODO: generalize
    # Parameters
    # $1 -> setup template
    # $2 -> OPTIONAL - output folder, default /tmp/images/product
    # $3 -> OPTIONAL - fixes tag. Defaulted to current day
    # $4 -> OPTIONAL - platform string, default LNXAMD64
    # $5 -> OPTIONAL - sum home, default /tmp/sumv11
    # $6 -> OPTIONAL - sum-bootstrap binary location, default /tmp/sum-bootstrap.bin
    # NOTE: pass SDC credentials in env variables SUIF_EMPOWER_USER and SUIF_EMPOWER_PASSWORD
    generateFixesImageFromTemplate "${template}" \
      "${SUIF_FIX_IMAGES_SHARED_DIRECTORY}" \
      "${SUIF_FIXES_DATE_TAG}" \
      "${SUIF_PRODUCT_IMAGES_PLATFORM}" \
      "${SUIF_SUM_HOME}"

    logI "Fixes file generated for template ${template}"
  fi

  logI "Template $template processed."
}

for template in ${TEST_Templates}; do
  processTemplate "${template}"
done

#logI "stopping for debug"
#tail -f /dev/null
