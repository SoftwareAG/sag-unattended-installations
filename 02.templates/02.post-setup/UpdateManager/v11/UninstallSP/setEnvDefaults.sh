#!/bin/sh

## User MUST provide
## Note: this assumes Update Manager v11 is already installed
export SUIF_SUM_HOME=${SUIF_SUM_HOME:-"/opt/sag/sum"}
# diagnoserKey e.g. 5437713_PIE-68082_5
export SUIF_ENG_PATCH_DIAGS_KEY=${SUIF_ENG_PATCH_DIAGS_KEY:-"please_provide_SUIF_ENG_PATCH_DIAGS_KEY"}
# fixesId e.g. 5437713_PIE-68082_1.0.0.0005-0001
export SUIF_ENG_PATCH_FIX_ID_LIST=${SUIF_ENG_PATCH_FIX_ID_LIST:-"please_provide_SUIF_ENG_PATCH_FIX_ID"}         # example 

## User MAY provide
## the commonsFunctions.sh must be present
export SUIF_CACHE_HOME=${SUIF_CACHE_HOME:-"/tmp/suifCacheHome"}
export SUIF_INSTALL_INSTALL_DIR=${SUIF_INSTALL_INSTALL_DIR:-"/opt/sag/products"}
