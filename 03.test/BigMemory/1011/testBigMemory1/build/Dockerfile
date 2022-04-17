ARG SRC_IMAGE=centos:7
FROM ${SRC_IMAGE}

ARG SUIF_TEST_GPG_KEYS_FILE_1=/etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
# ATTN: match the names with the templates required variables!
ARG SUIF_INSTALL_INSTALL_DIR=/app/1011/TSA
ARG SUIF_SUM_HOME=/app/sum11
ARG SUIF_USER_HOME=/home/sag
ARG SUIF_LOCAL_SCRIPTS_HOME=/mnt/local/scripts
ARG SUIF_AUDIT_BASE_DIR=/app/audit
ARG SUIF_HOME=/mnt/SUIF
ARG SUIF_WMSCRIPT_TCDataDirID=/app/data
ARG SUIF_WMSCRIPT_TCLogsDirID=/app/logs

ENV \
  SUIF_INSTALL_INSTALL_DIR=${SUIF_INSTALL_INSTALL_DIR} \
  JAVA_HOME=${SUIF_INSTALL_INSTALL_DIR}/jvm/jvm/ \
  SUIF_USER_HOME=${SUIF_USER_HOME} \
  SUIF_SUM_HOME=${SUIF_SUM_HOME} \
  SUIF_LOCAL_SCRIPTS_HOME=${SUIF_LOCAL_SCRIPTS_HOME} \
  SUIF_AUDIT_BASE_DIR=${SUIF_AUDIT_BASE_DIR} \
  SUIF_HOME=${SUIF_HOME} \
  SUIF_WMSCRIPT_TCDataDirID=${SUIF_WMSCRIPT_TCDataDirID} \
  SUIF_WMSCRIPT_TCLogsDirID=${SUIF_WMSCRIPT_TCLogsDirID} 

RUN if [ -f "$SUIF_TEST_GPG_KEYS_FILE_1" ] ; then rpmkeys --import "${SUIF_TEST_GPG_KEYS_FILE_1}" ; fi ;\ 
    yum -y update ;\
    yum -y install \
      gettext \
      less \
      telnet \
      which \
      ;\
    yum clean all ;\
    rm -rf /var/cache/yum ;\
    groupadd -g 1803 saggroup ;\
    useradd -u 1803 -m -g saggroup sag ;\
    mkdir -p \
      "${SUIF_AUDIT_BASE_DIR}" \
      "${SUIF_HOME}" \
      "${SUIF_INSTALL_INSTALL_DIR}" \
      "${SUIF_LOCAL_SCRIPTS_HOME}" \
      "${SUIF_SUM_HOME}" \
      "${SUIF_WMSCRIPT_TCDataDirID}"\
      "${SUIF_WMSCRIPT_TCLogsDirID}"\ 
      ;\
    chown -R sag:saggroup "${SUIF_AUDIT_BASE_DIR}" ;\
    chown -R sag:saggroup "${SUIF_HOME}" ;\
    chown -R sag:saggroup "${SUIF_INSTALL_INSTALL_DIR}" ;\
    chown -R sag:saggroup "${SUIF_LOCAL_SCRIPTS_HOME}" ;\
    chown -R sag:saggroup "${SUIF_SUM_HOME}" ;\
    chown -R sag:saggroup "${SUIF_WMSCRIPT_TCDataDirID}" ;\
    chown -R sag:saggroup "${SUIF_WMSCRIPT_TCLogsDirID}" 
USER sag

VOLUME "${SUIF_AUDIT_BASE_DIR}" "${SUIF_HOME}" "${SUIF_INSTALL_INSTALL_DIR}" "${SUIF_LOCAL_SCRIPTS_HOME}" "${SUIF_SUM_HOME}" "${SUIF_WMSCRIPT_TCDataDirID}" "${SUIF_WMSCRIPT_TCLogsDirID}"
