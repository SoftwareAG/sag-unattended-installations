#!/bin/sh

# Section 0 - Framework Import

if ! commonFunctionsSourced 2>/dev/null; then
	if [ ! -f "${SUIF_CACHE_HOME}/01.scripts/commonFunctions.sh" ]; then
		echo "Panic, common functions not sourced and not present locally! Cannot continue"
		exit 254
	fi
	# shellcheck source=/dev/null
	. "$SUIF_CACHE_HOME/01.scripts/commonFunctions.sh"
fi

if ! setupFunctionsSourced 2>/dev/null; then
    huntForSuifFile "01.scripts/installation" "setupFunctions.sh" || exit 252
	if [ ! -f "${SUIF_CACHE_HOME}/01.scripts/installation/setupFunctions.sh" ]; then
		echo "Panic, setup functions not sourced and not present locally! Cannot continue"
		exit 253
	fi
	# shellcheck source=/dev/null
	. "$SUIF_CACHE_HOME/01.scripts/installation/setupFunctions.sh"
fi

checkSetupTemplateBasicPrerequisites || exit $?
