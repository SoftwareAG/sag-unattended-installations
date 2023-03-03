#!/bin/sh

# shellcheck source=/dev/null
. "${SUIF_HOME}/01.scripts/commonFunctions.sh"

# eval "$(parse_yaml /mnt/SUIF1.yaml SUIF_)"

load_env_from_yaml /mnt/SUIF1.yaml

logFullEnv

