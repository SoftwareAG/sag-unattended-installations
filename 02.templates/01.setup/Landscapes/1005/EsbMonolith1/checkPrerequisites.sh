#!/bin/sh

#shellcheck disable=SC3043
	
if ! commonFunctionsSourced 2>/dev/null; then
	if [ ! -f "${SUIF_CACHE_HOME}/01.scripts/commonFunctions.sh" ]; then
		echo "Panic, common functions not sourced and not present locally! Cannot continue"
		exit 254
	fi
	# shellcheck source=/dev/null
	. "$SUIF_CACHE_HOME/01.scripts/commonFunctions.sh"
fi

if ! setupFunctionsSourced 2>/dev/null; then
	if [ ! -f "${SUIF_CACHE_HOME}/01.scripts/installation/setupFunctions.sh" ]; then
		echo "Panic, setup functions not sourced and not present locally! Cannot continue"
		exit 253
	fi
	# shellcheck source=/dev/null
	. "$SUIF_CACHE_HOME/01.scripts/installation/setupFunctions.sh"
fi

checkSetupTemplateBasicPrerequisites || exit $?
# thisFolder="02.templates/01.setup/Labs/1005/EsbMonolith1"
