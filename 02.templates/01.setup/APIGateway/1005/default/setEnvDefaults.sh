#!/bin/sh

# Section 0 - Validations

# Check if commons have been sourced, we need urlencode() for the license
if ! command -V "urlencode" 2>/dev/null | grep function >/dev/null; then 
    echo "FATAL: common functions not sourced and not present locally! Cannot continue"
    exit 1
fi

# Section 1 - check what the caller MUST provide

## Framework - Install
export SUIF_INSTALL_INSTALLER_BIN=${SUIF_INSTALL_INSTALLER_BIN:-"/path/to/installer.bin"}
export SUIF_INSTALL_IMAGE_FILE=${SUIF_INSTALL_IMAGE_FILE:-"/path/to/install/product.image.zip"}

## Framework - Patch
export SUIF_PATCH_SUM_BOOTSTRAP_BIN=${SUIF_PATCH_SUM_BOOTSTRAP_BIN:-"/path/to/sum-boostrap.bin"}
export SUIF_PATCH_FIXES_IMAGE_FILE=${SUIF_PATCH_FIXES_IMAGE_FILE:-"/path/to/install/fixes.image.zip"}

## Current Template
export SUIF_SETUP_TEMPLATE_YAI_LICENSE_FILE=${SUIF_SETUP_TEMPLATE_YAI_LICENSE_FILE:-"/provide/path/to/YAI-license.xml"}

# Section 2 - the caller MAY provide
## Framework - Install
export SUIF_INSTALL_INSTALL_DIR=${SUIF_INSTALL_INSTALL_DIR:-"/opt/sag/products"}
export SUIF_INSTALL_SPM_HTTPS_PORT=${SUIF_INSTALL_SPM_HTTPS_PORT:-"9083"}
export SUIF_INSTALL_SPM_HTTP_PORT=${SUIF_INSTALL_SPM_HTTP_PORT:-"9082"}
export SUIF_INSTALL_DECLARED_HOSTNAME=${SUIF_INSTALL_DECLARED_HOSTNAME:-"localhost"}
## Framework - Patch
export SUIF_SUM_HOME=${SUIF_SUM_HOME:-"/opt/sag/sum"}
## YAI related
export SUIF_INSTALL_IS_MAIN_HTTP_PORT=${SUIF_INSTALL_IS_MAIN_HTTP_PORT:-"5555"}
export SUIF_INSTALL_IS_DIAGS_HTTP_PORT=${SUIF_INSTALL_IS_DIAGS_HTTP_PORT:-"9999"}
export SUIF_INSTALL_YAI_HTTP_PORT=${SUIF_INSTALL_YAI_HTTP_PORT:-"9072"}
export SUIF_INSTALL_YAI_HTTPS_PORT=${SUIF_INSTALL_YAI_HTTPS_PORT:-"9073"}
## Elasticsearch related
### Elasticsearch service port, API Gateway will connect here
export SUIF_INSTALL_CEL_HTTP_PORT=${SUIF_INSTALL_CEL_HTTP_PORT:-"9240"}
export SUIF_INSTALL_CEL_TCP_PORT=${SUIF_INSTALL_CEL_TCP_PORT:-"9340"}
## Section 3 - Post processing
## eventually provided values are overwritten!
export SUIF_SETUP_TEMPLATE_YAI_LICENSE_UrlEncoded=$(urlencode ${SUIF_SETUP_TEMPLATE_YAI_LICENSE_FILE})

logI "Template environment sourced successfully"
logEnv4Debug
