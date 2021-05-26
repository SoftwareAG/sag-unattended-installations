#!/bin/sh

## User MUST provide
export SUIF_SQLSERVER_HOSTNAME=${SUIF_SQLSERVER_HOSTNAME-:"ProvideDBHostName!"}
export SUIF_SQLSERVER_DATABASE_NAME=${SUIF_SQLSERVER_DATABASE_NAME-:"ProvideDatabaseName!"}
export SUIF_SQLSERVER_USER_NAME=${SUIF_SQLSERVER_USER_NAME-:"ProvideUserName!"}
export SUIF_SQLSERVER_PASSWORD=${SUIF_SQLSERVER_PASSWORD-:"ProvideUserPAssowrd!"}

## User MUST provide only IF SUIF_DATABASE_ALREADY_CREATED is not 0
export SUIF_SQLSERVER_SA_PASSWORD=${SUIF_SQLSERVER_SA_PASSWORD-:"ProvideSaPassword!"}


## User MAY provide
export SUIF_CACHE_HOME=${SUIF_CACHE_HOME:-"/tmp/SUIF_CACHE"}
export SUIF_INSTALL_InstallDir=${SUIF_INSTALL_InstallDir-:"/opt/sag/products"}
# 0 means DB was not created, thus create now
export SUIF_DATABASE_ALREADY_CREATED=${SUIF_DATABASE_ALREADY_CREATED:-"0"}
export SUIF_SQLSERVER_PORT=${SUIF_SQLSERVER_PORT:-"1433"}
# By default create all components
export SUIF_DBC_COMPONENT_NAME=${SUIF_DBC_COMPONENT_NAME:-"All"}
# By default create the latest version
export SUIF_DBC_COMPONENT_VERSION=${SUIF_DBC_COMPONENT_VERSION:-"latest"}
