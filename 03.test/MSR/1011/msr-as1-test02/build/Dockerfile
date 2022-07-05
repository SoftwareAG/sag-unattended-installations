ARG __src_image=centos:7
FROM ${__src_image}

ARG __suif_test_gpg_keys_file_1=/etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 \
    __suif_install_install_dir=/app/sag/1011/MSRAdapters \
    __suif_audit_base_dir=/app/audit \
    __suif_install_installer_bin=/mnt/installer.bin \
    __suif_install_image_file=/mnt/products.zip \
    __suif_local_scripts_home=/mnt/scripts/local \
    __suif_sag_user_name=sag \
    __suif_home=/mnt/SUIF \
    __suif_sum_home=/app/sum11

ENV \
    SUIF_HOME=${__suif_home} \
	SUIF_SUM_HOME=${__suif_sum_home} \
    SUIF_TEST_GPG_KEYS_FILE_1=${__suif_test_gpg_keys_file_1} \
    SUIF_INSTALL_INSTALL_DIR=${__suif_install_install_dir} \
    JAVA_HOME=${__suif_install_install_dir}/jvm/jvm/ \
    JRE_HOME=${__suif_install_install_dir}/jvm/jvm/jre/ \
    SUIF_USER_HOME=/home/${__suif_sag_user_name} \
    SUIF_LOCAL_SCRIPTS_HOME=${__suif_local_scripts_home} \
    SUIF_AUDIT_BASE_DIR=${__suif_audit_base_dir} \
    SUIF_SAG_USER_NAME=${__suif_sag_user_name} \
    SUIF_SAG_GROUP_NAME=${__suif_sag_user_name}group

RUN if [ -f "${SUIF_TEST_GPG_KEYS_FILE_1}" ] ; then rpmkeys --import "${SUIF_TEST_GPG_KEYS_FILE_1}" ; fi ;\ 
    yum -y update ;\ 
    yum -y install which less gettext telnet nc;\ 
    yum clean all ;\ 
    rm -rf /var/cache/yum ;\ 
    groupadd -g 1804 ${SUIF_SAG_GROUP_NAME} ;\
    useradd -u 1804 -m -g ${SUIF_SAG_GROUP_NAME} ${SUIF_SAG_USER_NAME} ;\ 
    mkdir -p "${SUIF_AUDIT_BASE_DIR}"  "${SUIF_HOME}" "${SUIF_INSTALL_INSTALL_DIR}" "${SUIF_LOCAL_SCRIPTS_HOME}" "${SUIF_SUM_HOME}"  ;\ 
    touch "${SUIF_INSTALL_IMAGE_FILE}" "${SUIF_INSTALL_INSTALLER_BIN}" ;\ 
    chown ${SUIF_SAG_USER_NAME}:${SUIF_SAG_GROUP_NAME} "${SUIF_INSTALL_IMAGE_FILE}" "${SUIF_INSTALL_INSTALLER_BIN}" ;\ 
	chown -R ${SUIF_SAG_USER_NAME}:${SUIF_SAG_GROUP_NAME} "${SUIF_AUDIT_BASE_DIR}" ;\
    chown -R ${SUIF_SAG_USER_NAME}:${SUIF_SAG_GROUP_NAME} "${SUIF_HOME}" ;\
    chown -R ${SUIF_SAG_USER_NAME}:${SUIF_SAG_GROUP_NAME} "${SUIF_INSTALL_INSTALL_DIR}" ;\
    chown -R ${SUIF_SAG_USER_NAME}:${SUIF_SAG_GROUP_NAME} "${SUIF_LOCAL_SCRIPTS_HOME}" ;\
    chown -R ${SUIF_SAG_USER_NAME}:${SUIF_SAG_GROUP_NAME} "${SUIF_SUM_HOME}"


USER ${SUIF_SAG_USER_NAME}

VOLUME "${SUIF_AUDIT_BASE_DIR}" "${SUIF_HOME}" "${SUIF_INSTALL_INSTALL_DIR}" "${SUIF_LOCAL_SCRIPTS_HOME}" "${SUIF_SUM_HOME}"
