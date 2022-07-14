ARG __src_image=centos:7
FROM ${__src_image}

# This image is a common base for tests, where SUIF base env variables are fixed for convenience or productivity

ARG __suif_test_gpg_keys_file_1=/etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

ENV \
  JAVA_HOME=/app/sag/products/jvm/jvm/ \
  JRE_HOME=/app/sag/products/jvm/jvm/ \
  SUIF_AUDIT_BASE_DIR=/app/audit \
  SUIF_INSTALL_INSTALL_DIR=/app/sag/products \
  SUIF_LOCAL_SCRIPTS_HOME=/mnt/scripts \
  SUIF_SUM_HOME=/app/sag/sumv11

RUN if [ -f "$__suif_test_gpg_keys_file_1" ] ; then rpmkeys --import "${__suif_test_gpg_keys_file_1}" ; fi &&\ 
    yum -y update &&\
    yum -y install which less gettext telnet &&\
    yum clean all &&\
    rm -rf /var/cache/yum &&\
    mkdir -p \
      "${SUIF_AUDIT_BASE_DIR}" \
      "${SUIF_INSTALL_INSTALL_DIR}" \
      "${SUIF_LOCAL_SCRIPTS_HOME}" \
      "${SUIF_SUM_HOME}" \
      &&\
    groupadd -g 1804 saggroup &&\
    useradd -u 1804 -m -g saggroup sag &&\
    chown -R sag:saggroup "${SUIF_AUDIT_BASE_DIR}" &&\
    chown -R sag:saggroup "${SUIF_INSTALL_INSTALL_DIR}" &&\
    chown -R sag:saggroup "${SUIF_LOCAL_SCRIPTS_HOME}" &&\
    chown -R sag:saggroup "${SUIF_SUM_HOME}"

USER sag

VOLUME \
  ${SUIF_AUDIT_BASE_DIR} \
  ${SUIF_INSTALL_INSTALL_DIR} \
  ${SUIF_SUM_HOME}

# SUIF_LOCAL_SCRIPTS_HOME not declared on purpose, to avoid the creation of ghost volumes