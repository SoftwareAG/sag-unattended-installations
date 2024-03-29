#!/bin/sh

## User MUST provide
export SUIF_DBSERVER_HOSTNAME="${SUIF_DBSERVER_HOSTNAME:-ora-db-server}"
export SUIF_DBSERVER_SERVICE_NAME="${SUIF_DBSERVER_SERVICE_NAME:-xe}"
export SUIF_DBSERVER_USER_NAME="${SUIF_DBSERVER_USER_NAME:-webm}"
export SUIF_DBSERVER_PASSWORD="${SUIF_DBSERVER_PASSWORD:-webm}"

## User MUST provide only IF SUIF_DATABASE_ALREADY_CREATED is not 0
export SUIF_DBSERVER_SA_PASSWORD="${SUIF_DBSERVER_SA_PASSWORD:-webm}"

## User MAY provide
export SUIF_CACHE_HOME="${SUIF_CACHE_HOME:-/tmp/SUIF_CACHE}"
export SUIF_INSTALL_InstallDir="${SUIF_INSTALL_InstallDir:-/opt/sag/products}"
# 0 means DB was not created, thus create now
export SUIF_DATABASE_ALREADY_CREATED="${SUIF_DATABASE_ALREADY_CREATED:-0}"
export SUIF_DBSERVER_PORT="${SUIF_DBSERVER_PORT:-1521}"
# By default create all components
export SUIF_DBC_COMPONENT_NAME="${SUIF_DBC_COMPONENT_NAME:-All}"
# By default create the latest version
export SUIF_DBC_COMPONENT_VERSION="${SUIF_DBC_COMPONENT_VERSION:-latest}"

# WIP
export SUIF_ORACLE_STORAGE_TABLESPACE_DIR="${SUIF_ORACLE_STORAGE_TABLESPACE_DIR:-/tmp}"