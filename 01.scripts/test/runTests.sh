#!/bin/sh

# shellcheck disable=SC3043

if [ ! -f "${SUIF_HOME}/01.scripts/commonFunctions.sh" ]; then
  echo "Tested functions do not exist: ${SUIF_HOME}/01.scripts/commonFunctions.sh"
  exit 1
fi

localTestDir=${SUIF_TEST_DIR:-/tmp/SUIF_TESTS}

if [ ! -f "${localTestDir}/shunit2" ]; then
  mkdir -p "${localTestDir}"
  curl https://raw.githubusercontent.com/kward/shunit2/master/shunit2 -o "${localTestDir}"/shunit2
fi

# shellcheck source=SCRIPTDIR/../commonFunctions.sh
. "${SUIF_HOME}/01.scripts/commonFunctions.sh"

testUrlEncode1(){
  str='a/c'
  encstr=$(urlencode "$str")
  assertEquals "$encstr" 'a%2fc'
}

# shellcheck source=/dev/null
. "${localTestDir}"/shunit2