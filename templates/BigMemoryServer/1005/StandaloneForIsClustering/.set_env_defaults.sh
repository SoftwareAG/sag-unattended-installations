#!/bin/sh

# Depends on framework commons
if [ ! $SUIF_COMMON_SOURCED ]; then
    echo "Source common framework functions before the setup functions"
    exit 1
fi

export SUIF_INSTALL_InstallDir=${SUIF_INSTALL_InstallDir:-"/opt/sag/products"}
export SUIF_INSTALL_SPMHttpsPort=${SUIF_INSTALL_SPMHttpsPort:-"9083"}
export SUIF_INSTALL_SPMHttpPort=${SUIF_INSTALL_SPMHttpPort:-"9082"}
export SUIF_TC_SERVER_LOGS_DIR=${SUIF_TC_SERVER_LOGS_DIR:-"./logs"}
export SUIF_TC_SERVER_DATA_DIR=${SUIF_TC_SERVER_DATA_DIR:-"./data"}
export SUIF_TC_SERVER_PORT=${SUIF_TC_SERVER_PORT:-"9510"}
export SUIF_TC_SERVER_GROUP_PORT=${SUIF_TC_SERVER_GROUP_PORT:-"9540"}
export SUIF_TC_SERVER_OFFHEAP_MEM_DATA_SIZE=${SUIF_TC_SERVER_OFFHEAP_MEM_DATA_SIZE:-"2048m"}

# for these the default values are hints
export SUIF_INSTALL_TES_License_Path=${SUIF_INSTALL_TES_License_Path:-"/provide/path/to/terracotta-license.key"}
export SUIF_INSTALL_imageFile=${SUIF_INSTALL_imageFile:-"/path/to/install/product.image.zip"}
export SUIF_FIXES_imageFile=${SUIF_INSTALL_imageFile:-"/path/to/install/fixes.image.zip"}

# Post processing
export SUIF_INSTALL_TES_License_UrlEncoded=$(urlencode ${SUIF_INSTALL_TES_License_Path})
