#!/bin/sh

# This file is a collection of functions used by all the other scripts

## Framework variables
# Convention: all variables from this framework are prefixed with SUIF_
# Variables defaults are specified in the init function
# client projects should source their variables with en .env file

newAuditSession(){
    export SUIF_AUDIT_BASE_DIR=${SUIF_AUDIT_BASE_DIR:-"/tmp"}
    export SUIF_SESSION_TIMESTAMP=`date +%y-%m-%dT%H.%M.%S_%3N`
    export SUIF_AUDIT_SESSION_DIR="${SUIF_AUDIT_BASE_DIR}/${SUIF_SESSION_TIMESTAMP}"
    mkdir -p "${SUIF_AUDIT_SESSION_DIR}"
    return $?
}

init(){
    newAuditSession || return $?

    # For internal dependency checks, 
    export SUIF_COMMON_SOURCED=1
    export SUIF_DEBUG_ON=${SUIF_DEBUG_ON:-0}
    export SUIF_LOG_TOKEN=${SUIF_LOG_TOKEN:-"SUIF"}

    # SUPPRESS_STDOUT means we will not produce STD OUT LINES
    # Normally we want the see the output when we prepare scripts, and suppress it when we finished
    export SUIF_SUPPRESS_STDOUT=${SUIF_SUPPRESS_STDOUT:-0}
}

init || exit $?

# all log functions recieve 1 parameter
# $1 - Message to log

logI(){
    if [ ${SUIF_SUPPRESS_STDOUT} -eq 0 ]; then echo `date +%y-%m-%dT%H.%M.%S_%3N`" ${SUIF_LOG_TOKEN} -INFO - ${1}"; fi
    echo `date +%y-%m-%dT%H.%M.%S_%3N`" ${SUIF_LOG_TOKEN} -INFO - ${1}" >> "${SUIF_AUDIT_SESSION_DIR}/session.log"
}

logW(){
    if [ ${SUIF_SUPPRESS_STDOUT} -eq 0 ]; then echo `date +%y-%m-%dT%H.%M.%S_%3N`" ${SUIF_LOG_TOKEN} -WARN - ${1}"; fi
    echo `date +%y-%m-%dT%H.%M.%S_%3N`" ${SUIF_LOG_TOKEN} -WARN - ${1}" >> "${SUIF_AUDIT_SESSION_DIR}/session.log"
}

logE(){
    if [ ${SUIF_SUPPRESS_STDOUT} -eq 0]; then echo `date +%y-%m-%dT%H.%M.%S_%3N`" ${SUIF_LOG_TOKEN} -ERROR - ${1}"; fi
    echo `date +%y-%m-%dT%H.%M.%S_%3N`" ${SUIF_LOG_TOKEN} -ERROR- ${1}" >> "${SUIF_AUDIT_SESSION_DIR}/session.log"
}

logD(){
    if [ ${SUIF_DEBUG_ON} -ne 0 ]; then
        if [ ! ${SUIF_SUPPRESS_STDOUT} ]; then echo `date +%y-%m-%dT%H.%M.%S_%3N`" ${SUIF_LOG_TOKEN} -ERROR - ${1}"; fi
        echo `date +%y-%m-%dT%H.%M.%S_%3N`" ${SUIF_LOG_TOKEN} -ERROR- ${1}" >> "${SUIF_AUDIT_SESSION_DIR}/session.log"
    fi
}

logEnv(){
    if [ ${SUIF_DEBUG_ON} -ne 0  ]; then
        if [ ! ${SUIF_SUPPRESS_STDOUT} ]; then env | grep SUIF | sort; fi
        env | grep SUIF | sort >> "${SUIF_AUDIT_SESSION_DIR}/session.log"
    fi
}

logFullEnv(){
    if [ ${SUIF_DEBUG_ON} -ne 0  ]; then
        if [ ! ${SUIF_SUPPRESS_STDOUT} ]; then env | sort; fi
        env | grep SUIF | sort >> "${SUIF_AUDIT_SESSION_DIR}/session.log"
    fi
}

# Convention: 
# f() function creates a RESULT_f variable for the outcome
# if not otherwise specified, 0 means success

controlledExec(){
    # Param $1 - command to execute in a controlled manner
    # Param $2 - tag for trace files
    eval "${1}" >"${SUIF_AUDIT_SESSION_DIR}/controlledExec_${2}.out" 2>"${SUIF_AUDIT_SESSION_DIR}/controlledExec_${2}.err"
    return $?
}

portIsReachable(){
    # Params: $1 -> host $2 -> port
    if [ -f /usr/bin/nc ]; then 
        nc -z ${1} ${2}                                         # alpine image
    else
        temp=`(echo > /dev/tcp/${1}/${2}) >/dev/null 2>&1`      # centos image
    fi
    if [ $? -eq 0 ] ; then echo 1; else echo 0; fi
}

# urlencode / decode taken from https://gist.github.com/cdown/1163649
urlencode() {
    # urlencode <string>
    # usage A_ENC=$(urlencode ${A})

    old_lc_collate=$LC_COLLATE
    LC_COLLATE=C

    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:$i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf '%s' "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done

    LC_COLLATE=$old_lc_collate
    unset ld_lc_collate
}

urldecode() {
    # urldecode <string>
    # usage A=$(urldecode ${A_ENC})

    local url_encoded="${1//+/ }"
    printf '%b' "${url_encoded//%/\\x}"
}

logI "SLS common framework functions initialized"
