ARG SRC_IMAGE=ubuntu:20.04
FROM ${SRC_IMAGE}

ARG SUIF_AUDIT_BASE_DIR=/dockerfile/default/audit
ARG SUIF_INSTALL_INSTALL_DIR=/dockerfile/default/install
ARG SUIF_LOCAL_SCRIPTS_HOME=/dockerfile/default/scripts/local
ARG SUIF_SAG_USER_NAME=sag
ARG SUIF_SUM_HOME=/dockerfile/sumv11

ENV \
    SUIF_INSTALL_INSTALL_DIR=${SUIF_INSTALL_INSTALL_DIR} \
    JAVA_HOME=${SUIF_INSTALL_INSTALL_DIR}/jvm/jvm/ \
    SUIF_LOCAL_SCRIPTS_HOME=${SUIF_LOCAL_SCRIPTS_HOME} \
    SUIF_AUDIT_BASE_DIR=${SUIF_AUDIT_BASE_DIR} \
    SUIF_SAG_USER_NAME=${SUIF_SAG_USER_NAME} \
    SUIF_SAG_GROUP_NAME=${SUIF_SAG_USER_NAME}group \
    SUIF_SUM_HOME=${SUIF_SUM_HOME}

RUN apt-get -qq -y update ;\
    apt-get -qq install -y \
        ca-certificates \
        curl \
        gettext-base \
        gnupg2 \
        telnet \
        wget \
        ;\
    . /etc/os-release ; \
    echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /" | tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list ; \
    wget -nv "https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_${VERSION_ID}/Release.key" -O /dev/shm/r.key ;\
    apt-key add < /dev/shm/r.key ; \
    mkdir /log ;\
    apt-get -y update >> /log/debug.log  ;\
    apt-get -y install buildah >> /log/debug.log ;\
    apt-get install --only-upgrade bash >> /log/debug.log  ;\
    rm -rf /var/lib/apt/lists/* ;\
    mkdir -p \
        "${SUIF_AUDIT_BASE_DIR}" \
        "${SUIF_LOCAL_SCRIPTS_HOME}" \
        "${SUIF_INSTALL_INSTALL_DIR}" \
        "${SUIF_SUM_HOME}";\
    groupadd -g 1804 ${SUIF_SAG_GROUP_NAME} ;\
    useradd -u 1804 -m -g ${SUIF_SAG_GROUP_NAME} ${SUIF_SAG_USER_NAME} ;\
    chown -R ${SUIF_SAG_USER_NAME}:${SUIF_SAG_GROUP_NAME} "${SUIF_LOCAL_SCRIPTS_HOME}" ;\
    chown -R ${SUIF_SAG_USER_NAME}:${SUIF_SAG_GROUP_NAME} "${SUIF_AUDIT_BASE_DIR}" ;\
    chown -R ${SUIF_SAG_USER_NAME}:${SUIF_SAG_GROUP_NAME} "${SUIF_INSTALL_INSTALL_DIR}" ;\
    chown -R ${SUIF_SAG_USER_NAME}:${SUIF_SAG_GROUP_NAME} "${SUIF_SUM_HOME}"

USER ${SUIF_SAG_USER_NAME}
