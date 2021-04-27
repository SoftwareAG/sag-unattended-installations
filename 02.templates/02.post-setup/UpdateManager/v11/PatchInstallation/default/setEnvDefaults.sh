#!/bin/sh

## User MUST provide
## Note: this assumes Update Manager v11 is already installed
export SUIF_SUM_HOME=${SUIF_SUM_HOME:-"/opt/sag/sum"}
export SUIF_PATCH_FIXES_IMAGE_FILE=${SUIF_PATCH_FIXES_IMAGE_FILE:-"/path/to/install/fixes.image.zip"}

## User MAY provide
## the commonsFunctions.sh must be present
export SUIF_CACHE_HOME=${SUIF_CACHE_HOME:-"/tmp/suifCacheHome"}
export SUIF_INSTALL_INSTALL_DIR=${SUIF_INSTALL_INSTALL_DIR:-"/opt/sag/products"}
export SUIF_ENG_PATCH_MODE=${SUIF_ENG_PATCH_MODE:-"N"}

## USER MUST provide if SUIF_ENG_PATCH_MODE="Y"
export SUIF_ENG_PATCH_DIAGS_KEY=${SUIF_ENG_PATCH_DIAGS_KEY:-""}