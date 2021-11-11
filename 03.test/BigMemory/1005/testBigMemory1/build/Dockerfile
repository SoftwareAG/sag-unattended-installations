ARG SRC_IMAGE=centos:7
FROM ${SRC_IMAGE}

ARG SUIF_TEST_GPG_KEYS_FILE_1=/etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
ARG SUIF_INSTALL_InstallDir=/app/sag/1005/BigM43

ENV SUIF_INSTALL_InstallDir=${SUIF_INSTALL_InstallDir} \
    JAVA_HOME=${SUIF_INSTALL_InstallDir}/jvm/jvm/ \
    JRE_HOME=${SUIF_INSTALL_InstallDir}/jvm/jvm/jre/ \
    SUIF_USER_HOME=/home/sag \
    SUIF_SUM_HOME=/app/sag/sumv11 \
    SUIF_TC_SERVER_DATA_DIR=/mnt/tc/data \
    SUIF_TC_SERVER_LOGS_DIR=/mnt/tc/logs \
    SUIF_LOCAL_SCRIPTS_HOME=/mnt/scripts \
    SUIF_AUDIT_BASE_DIR=/app/audit

RUN if [ -f "$SUIF_TEST_GPG_KEYS_FILE_1" ] ; then rpmkeys --import "${SUIF_TEST_GPG_KEYS_FILE_1}" ; fi &&\ 
    yum -y update &&\
    yum -y install which less gettext telnet &&\
    yum clean all &&\
    rm -rf /var/cache/yum &&\
    groupadd -g 1803 saggroup &&\
    useradd -u 1803 -m -g saggroup sag &&\
    mkdir -p "${SUIF_SUM_HOME}" "${SUIF_AUDIT_BASE_DIR}" "${SUIF_TC_SERVER_LOGS_DIR}" \
      "${SUIF_TC_SERVER_DATA_DIR}" "${SUIF_INSTALL_InstallDir}" "${SUIF_LOCAL_SCRIPTS_HOME}" &&\
    chown -R sag:saggroup "${SUIF_TC_SERVER_LOGS_DIR}" &&\
    chown -R sag:saggroup "${SUIF_TC_SERVER_DATA_DIR}" &&\
    chown -R sag:saggroup "${SUIF_LOCAL_SCRIPTS_HOME}" &&\
    chown -R sag:saggroup "${SUIF_SUM_HOME}" &&\
    chown -R sag:saggroup "${SUIF_AUDIT_BASE_DIR}" &&\
    chown -R sag:saggroup "${SUIF_INSTALL_InstallDir}"

USER sag
