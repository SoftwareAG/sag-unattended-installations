#!/bin/sh

export SUIF_POST_TC_SERVER_LOGS_DIR=${SUIF_TC_SERVER_LOGS_DIR:-"./logs"}
export SUIF_POST_TC_SERVER_DATA_DIR=${SUIF_TC_SERVER_DATA_DIR:-"./data"}
export SUIF_POST_TC_SERVER_PORT=${SUIF_TC_SERVER_PORT:-"9510"}
export SUIF_POST_TC_SERVER_GROUP_PORT=${SUIF_TC_SERVER_GROUP_PORT:-"9540"}
export SUIF_POST_TC_SERVER_OFFHEAP_MEM_DATA_SIZE=${SUIF_TC_SERVER_OFFHEAP_MEM_DATA_SIZE:-"2048m"}
