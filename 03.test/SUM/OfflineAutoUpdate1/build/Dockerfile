ARG SRC_IMAGE=centos:7
FROM centos:7

ARG SUIF_TEST_GPG_KEYS_FILE_1=/etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

ENV SUIF_USER_HOME=/home/sag \
    SUIF_SUM_HOME=/app/sag/sumv11 \
    SUIF_LOCAL_SCRIPTS_HOME=/mnt/scripts/local \
    SUIF_SUIF_SCRIPTS_HOME=/mnt/scripts/SUIF \
    SUIF_AUDIT_BASE_DIR=/app/audit \
    SUIF_SUM_BOOTSTRAP_BIN=/mnt/sum-booststrap.bin \
    SUIF_FIX_IMG_1=/mnt/fixesImage1.zip \
    SUIF_FIX_IMG_2=/mnt/fixesImage2.zip

RUN if [ -f "$SUIF_TEST_GPG_KEYS_FILE_1" ] ; then rpmkeys --import "${SUIF_TEST_GPG_KEYS_FILE_1}" ; fi &&\ 
    yum -y update &&\
    yum -y install which less gettext telnet &&\
    yum clean all &&\
    rm -rf /var/cache/yum &&\
    mkdir -p "${SUIF_SUM_HOME}" "${SUIF_AUDIT_BASE_DIR}" \
      "${SUIF_LOCAL_SCRIPTS_HOME}" "${SUIF_SUIF_SCRIPTS_HOME}" &&\
    touch "${SUIF_SUM_BOOTSTRAP_BIN}" "${SUIF_FIX_IMG_1}" "${SUIF_FIX_IMG_2}" &&\
    groupadd -g 1804 saggroup &&\
    useradd -u 1804 -m -g saggroup sag &&\
    chown sag:saggroup "${SUIF_SUM_BOOTSTRAP_BIN}" "${SUIF_FIX_IMG_1}" "${SUIF_FIX_IMG_2}" &&\
    chown -R sag:saggroup "${SUIF_LOCAL_SCRIPTS_HOME}" &&\
    chown -R sag:saggroup "${SUIF_SUIF_SCRIPTS_HOME}" &&\
    chown -R sag:saggroup "${SUIF_SUM_HOME}" &&\
    chown -R sag:saggroup "${SUIF_AUDIT_BASE_DIR}"

USER sag

VOLUME ["/app/audit", "/app/sag/sumv11", "/mnt/scripts/SUIF", "/mnt/scripts/SUIF", "/mnt/scripts/local"]
