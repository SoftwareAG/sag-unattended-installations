ARG SRC_IMAGE=centos:7
FROM centos:7

ARG SUIF_TEST_GPG_KEYS_FILE_1=/etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
ARG SUIF_INSTALL_InstallDir=/app/sag/1005/NameYourInstallation

ENV SUIF_USER_HOME=/home/sag \
    SUIF_SUM_HOME=/app/sag/sum \
    SUIF_LOCAL_SCRIPTS_HOME=/mnt/scripts \
    SUIF_AUDIT_BASE_DIR=/app/audit

RUN if [ -f "$SUIF_TEST_GPG_KEYS_FILE_1" ] ; then rpmkeys --import "${SUIF_TEST_GPG_KEYS_FILE_1}" ; fi &&\ 
    curl -sSL https://packages.microsoft.com/keys/microsoft.asc > ./microsoft.asc &&\
    rpm --import ./microsoft.asc &&\
    curl https://packages.microsoft.com/config/rhel/7/prod.repo | tee /etc/yum.repos.d/microsoft.repo &&\
    yum -y update &&\
    yum -y install which less gettext telnet git powershell &&\
    yum -y update &&\
    yum clean all &&\
    rm -rf /var/cache/yum &&\
    groupadd -g 1803 saggroup &&\
    useradd -u 1803 -m -g saggroup sag &&\
    mkdir -p "${SUIF_SUM_HOME}" "${SUIF_AUDIT_BASE_DIR}" "${SUIF_LOCAL_SCRIPTS_HOME}" &&\
    chown -R sag:saggroup "${SUIF_LOCAL_SCRIPTS_HOME}" &&\
    chown -R sag:saggroup "${SUIF_SUM_HOME}" &&\
    chown -R sag:saggroup "${SUIF_AUDIT_BASE_DIR}"
    
USER sag
