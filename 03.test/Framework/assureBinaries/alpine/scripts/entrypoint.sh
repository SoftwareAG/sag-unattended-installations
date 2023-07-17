#!/bin/sh

apk add curl

# shellcheck source=../../../../../01.scripts/commonFunctions.sh
. /mnt/SUIF/01.scripts/commonFunctions.sh

# shellcheck source=../../../../../01.scripts/installation/setupFunctions.sh
. /mnt/SUIF/01.scripts/installation/setupFunctions.sh

logEnv

errNo=0

assureDefaultInstaller || errNo=$((errNo+1))
assureDefaultSumBoostrap || errNo=$((errNo+1))

logI "Returning exit code $errNo"

if [ $errNo -ne 0 ]; then
  logE "TEST FAILED!"
else
  logI "SUCCESS"
fi

exit $errNo