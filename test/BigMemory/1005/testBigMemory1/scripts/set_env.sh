#!/bin/sh

# Base Framework Variables
export SUIF_AUDIT_BASE_DIR=${SUIF_AUDIT_BASE_DIR:-"/tmp"}
export SUIF_INSTALL_imageFile=${SUIF_INSTALL_imageFile:-"/tmp/product.image.zip"}
export SUIF_FIXES_imageFile=${SUIF_FIXES_imageFile:-"/tmp/fixes.image.zip"}

# Setup Framework Variables
export SUIF_INSTALLER_BIN=${SUIF_INSTALLER_BIN:-"/tmp/installer.bin"}
export SUIF_SUM_BOOSTSTRAP_BIN=${SUIF_SUM_BOOSTSTRAP_BIN:-"/tmp/sum-boostrap.bin"}
export SUIF_INSTALL_InstallDir=${SUIF_INSTALL_InstallDir:-"/opt/sag/products"}

# Specific product setup variables

export SUIF_INSTALL_TES_License_Path=${SUIF_INSTALL_TES_License_Path:-"/tmp/terracotta-license.key"}

export SUIF_INSTALL_SPMHttpsPort=${SUIF_INSTALL_SPMHttpsPort:-"9083"}
export SUIF_INSTALL_SPMHttpPort=${SUIF_INSTALL_SPMHttpPort:-"9082"}
export SUIF_TC_SERVER_LOGS_DIR=${SUIF_TC_SERVER_LOGS_DIR:-"./logs"}
export SUIF_TC_SERVER_DATA_DIR=${SUIF_TC_SERVER_DATA_DIR:-"./data"}
export SUIF_TC_SERVER_PORT=${SUIF_TC_SERVER_PORT:-"9510"}
export SUIF_TC_SERVER_GROUP_PORT=${SUIF_TC_SERVER_GROUP_PORT:-"9540"}
export SUIF_TC_SERVER_OFFHEAP_MEM_DATA_SIZE=${SUIF_TC_SERVER_OFFHEAP_MEM_DATA_SIZE:-"2048m"}
