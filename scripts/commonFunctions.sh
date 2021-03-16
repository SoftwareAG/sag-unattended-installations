#!/bin/sh

# This file is a collection of functions used by all the other scripts

## Framework variables
# Convention: all variables from this framework are prefixed with SUIF_
# Variables defaults are specified in the init function
# client projects should source their variables with en .env file

init(){
    # For internal dependency checks
    export SUIF_COMMON_SOURCED=1
    export SUIF_LOG_TOKEN=${SUIF_LOG_TOKEN:-"SLS"}

    # SUPPRESS_STDOUT means we will not produce STD OUT LINES
    # Normally we want the see the output when we prepare scripts, and suppress it when we finished
    export SUIF_SUPPRESS_STDOUT=${SUIF_SUPPRESS_STDOUT:-0}
}
init # made function for authoring convenience, run it immeediately

# all log functions recieve 2 parameters
# $1 - Message to log
# $2 - OPTIONAL File to append the message to
logI(){
    if [ ${SUIF_SUPPRESS_STDOUT} -eq 0 ]; then echo `date +%y-%m-%dT%H.%M.%S_%3N`" ${SUIF_LOG_TOKEN} -INFO - ${1}"; fi
    if [ -f "${2}" ]; then echo `date +%y-%m-%dT%H.%M.%S_%3N`" ${SUIF_LOG_TOKEN} -INFO - ${1}" >> "${2}"; fi
}

logW(){
    if [ ! ${SUIF_SUPPRESS_STDOUT} ]; then echo `date +%y-%m-%dT%H.%M.%S_%3N`" ${SUIF_LOG_TOKEN} -WARN - ${1}"; fi
    echo `date +%y-%m-%dT%H.%M.%S_%3N`" ${SUIF_LOG_TOKEN} -WARN - ${1}" >> "${2}"
}

logE(){
    if [ ! ${SUIF_SUPPRESS_STDOUT} ]; then echo `date +%y-%m-%dT%H.%M.%S_%3N`" ${SUIF_LOG_TOKEN} -ERROR - ${1}"; fi
    echo `date +%y-%m-%dT%H.%M.%S_%3N`" ${SUIF_LOG_TOKEN} -ERROR- ${1}" >> "${2}"
}

logI "SLS common framework functions initialized"

# Convention: 
# f() function creates a RESULT_f variable for the outcome
# if not otherwise specified, 0 means success

controlledExec(){
    # Param $1 - command to execute in a controlled manner
    # Param $2 - tag for trace files
    # Param $3 - destination folder to write the stdout / stderr
    eval "${1}" >"${3}/controlledExec_${2}.out" 2>"${3}/controlledExec_${2}.err"
    RESULT_controlledExec=$?
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