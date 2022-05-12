ARG SRC_IMAGE=ubuntu:20.04
FROM ${SRC_IMAGE}

ARG SUIF_TEST_GPG_KEYS_FILE_1=/etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
ARG SUIF_INSTALL_INSTALL_DIR=/dockerfile/default/install
ARG SUIF_AUDIT_BASE_DIR=/dockerfile/default/audit
ARG SUIF_INSTALL_INSTALLER_BIN=/dockerfile/default/installer.bin
ARG SUIF_INSTALL_IMAGE_FILE=/dockerfile/default/products.zip
ARG SUIF_LOCAL_SCRIPTS_HOME=/dockerfile/default/scripts/local
ARG SUIF_SAG_USER_NAME=sag

ENV \
    SUIF_INSTALL_INSTALL_DIR=${SUIF_INSTALL_INSTALL_DIR} \
    JAVA_HOME=${SUIF_INSTALL_INSTALL_DIR}/jvm/jvm/ \
    SUIF_USER_HOME=/home/${SUIF_SAG_USER_NAME} \
    SUIF_LOCAL_SCRIPTS_HOME=${SUIF_LOCAL_SCRIPTS_HOME} \
    SUIF_AUDIT_BASE_DIR=${SUIF_AUDIT_BASE_DIR} \
    SUIF_SAG_USER_NAME=${SUIF_SAG_USER_NAME} \
    SUIF_SAG_GROUP_NAME=${SUIF_SAG_USER_NAME}group

RUN apt-get -y update ;\
    apt-get install -y wget ca-certificates gnupg2 fuse-overlayfs ;\
    echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_20.04/ /' | tee /etc/apt/sources.list.d/ devel:kubic:libcontainers:stable.list ;\
    wget -nv https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_20.04/Release.key -O /tmp/Release.key ;\
    apt-key add - < /tmp/Release.key ;\
    apt-get -y update -qq ;\
    apt-get -qq -y install buildah ;\
    apt-get install --only-upgrade bash ;\
    rm -rf /var/lib/apt/lists/* ;\
    mkdir -p "${SUIF_AUDIT_BASE_DIR}" "${SUIF_LOCAL_SCRIPTS_HOME}" "${SUIF_INSTALL_INSTALL_DIR}" ;\
    touch "${SUIF_INSTALL_IMAGE_FILE}" "${SUIF_INSTALL_INSTALLER_BIN}" ;\
    groupadd -g 1804 ${SUIF_SAG_GROUP_NAME} ;\
    useradd -u 1804 -m -g ${SUIF_SAG_GROUP_NAME} ${SUIF_SAG_USER_NAME} ;\
    usermod -aG docker ${SUIF_SAG_USER_NAME} ;\
    usermod -aG wheel ${SUIF_SAG_USER_NAME} ;\
    chown ${SUIF_SAG_USER_NAME}:${SUIF_SAG_GROUP_NAME} "${SUIF_INSTALL_IMAGE_FILE}" "${SUIF_INSTALL_INSTALLER_BIN}" ;\
    chown -R ${SUIF_SAG_USER_NAME}:${SUIF_SAG_GROUP_NAME} "${SUIF_LOCAL_SCRIPTS_HOME}" ;\
    chown -R ${SUIF_SAG_USER_NAME}:${SUIF_SAG_GROUP_NAME} "${SUIF_AUDIT_BASE_DIR}" ;\
    chown -R ${SUIF_SAG_USER_NAME}:${SUIF_SAG_GROUP_NAME} "${SUIF_INSTALL_INSTALL_DIR}"

USER ${SUIF_SAG_USER_NAME}
