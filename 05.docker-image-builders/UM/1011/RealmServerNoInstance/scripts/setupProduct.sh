#!/bin/sh

# Source framework functions
. "${SUIF_HOME}/01.scripts/commonFunctions.sh" || exit 4
. "${SUIF_HOME}/01.scripts/installation/setupFunctions.sh" || exit 5


if [ -d "${SUIF_INSTALL_INSTALL_DIR}/UniversalMessaging" ]; then
    logE "Error: Installation already exists, this builde requires a new installation"
    exit 1
fi


logFullEnv

applySetupTemplate "UM/1011/RealmServerNoInstance" || exit 6

# Clean up a bit

cd "${SUIF_INSTALL_INSTALL_DIR}"

mkdir -p \
        /tmp/product_home/common/conf/ \
        /tmp/product_home/common/runtime/bundles/platform/ \
        /tmp/product_home/jvm/ \
        /tmp/product_home/UniversalMessaging/tools

cp -r ./common/bin /tmp/product_home/common/
cp -r ./common/lib /tmp/product_home/common/
cp -r ./common/metering /tmp/product_home/common/
cp -r ./common/runtime/bundles/platform/eclipse /tmp/product_home/common/runtime/bundles/platform/
cp -r ./install /tmp/product_home/
cp -r ./jvm/jvm /tmp/product_home/jvm/
cp -r ./UniversalMessaging/lib /tmp/product_home/UniversalMessaging/
cp -r ./UniversalMessaging/tools/InstanceManager /tmp/product_home/UniversalMessaging/tools/
cp -r ./UniversalMessaging/tools/runner /tmp/product_home/UniversalMessaging/tools/
cp ./common/conf/users.txt /tmp/product_home/common/conf/users.txt
cp ./UniversalMessaging/tools/docker/3rdPartyLicenses.pdf /tmp/product_home/3rdPartyLicenses_NUM_UniversalMessagingDocker.pdf

# TODO: check if "install" folder can be reduced. Attempted, but it's taking too long

cp "${SUIF_LOCAL_SCRIPTS_HOME}/um-image/"* /tmp/product_home/

# remove license, it shouldn't be packed with the image
rm UniversalMessaging/server/templates/licence.xml 

# prepare for dynamic named realms
cd UniversalMessaging/
tar czf /tmp/product_home/UniversalMessaging/server.tgz server
