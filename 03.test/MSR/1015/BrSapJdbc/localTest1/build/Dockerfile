ARG SRC_IMAGE=registry.access.redhat.com/ubi8/ubi-minimal:latest
FROM ${SRC_IMAGE}

ARG __suif_install_install_dir=/app/sag/1015/msras2
ARG __suif_audit_base_dir=/app/audit
ARG __suif_install_installer_bin=/mnt/installer.bin
ARG __suif_install_image_file=/mnt/products.zip
ARG __suif_local_scripts_home=/mnt/scripts/local
ARG __suif_sag_user_name=sag
ARG __suif_sag_user_grp_id=1804
ARG __suif_home=/mnt/suif
ARG __suif_sum_home=/app/sum11

ENV \
    SUIF_HOME=${__suif_home} \
	SUIF_SUM_HOME=${__suif_sum_home} \
    SUIF_INSTALL_INSTALL_DIR=${__suif_install_install_dir} \
    JAVA_HOME=${__suif_install_install_dir}/jvm/jvm/ \
    JRE_HOME=${__suif_install_install_dir}/jvm/jvm/jre/ \
    SUIF_USER_HOME=/home/${__suif_sag_user_name} \
    SUIF_LOCAL_SCRIPTS_HOME=${__suif_local_scripts_home} \
    SUIF_AUDIT_BASE_DIR=${__suif_audit_base_dir} \
    SUIF_SAG_USER_NAME=${__suif_sag_user_name} \
    SUIF_SAG_GROUP_NAME=${__suif_sag_user_name}group

RUN microdnf -y update ;\ 
    microdnf -y install \
        gettext \
        gzip \
        less \
        nc \
        procps \
        shadow-utils \
        tar \
        which \
        ;\ 
    microdnf clean all ;\ 
    rm -rf /var/cache/yum ;\ 
    groupadd -g ${__suif_sag_user_grp_id} ${SUIF_SAG_GROUP_NAME} ;\
    useradd -u ${__suif_sag_user_grp_id} -m -g ${SUIF_SAG_GROUP_NAME} ${SUIF_SAG_USER_NAME} ;\ 
    mkdir -p "${SUIF_AUDIT_BASE_DIR}"  "${SUIF_HOME}" "${SUIF_INSTALL_INSTALL_DIR}" "${SUIF_LOCAL_SCRIPTS_HOME}" "${SUIF_SUM_HOME}"  ;\ 
    touch "${__suif_install_image_file}" "${__suif_install_installer_bin}" ;\ 
    chown ${SUIF_SAG_USER_NAME}:${SUIF_SAG_GROUP_NAME} "${__suif_install_image_file}" "${__suif_install_installer_bin}" ;\ 
	chown -R ${SUIF_SAG_USER_NAME}:${SUIF_SAG_GROUP_NAME} "${SUIF_AUDIT_BASE_DIR}" ;\
    chown -R ${SUIF_SAG_USER_NAME}:${SUIF_SAG_GROUP_NAME} "${SUIF_HOME}" ;\
    chown -R ${SUIF_SAG_USER_NAME}:${SUIF_SAG_GROUP_NAME} "${SUIF_INSTALL_INSTALL_DIR}" ;\
    chown -R ${SUIF_SAG_USER_NAME}:${SUIF_SAG_GROUP_NAME} "${SUIF_LOCAL_SCRIPTS_HOME}" ;\
    chown -R ${SUIF_SAG_USER_NAME}:${SUIF_SAG_GROUP_NAME} "${SUIF_SUM_HOME}"


USER ${SUIF_SAG_USER_NAME}

VOLUME "${SUIF_AUDIT_BASE_DIR}" "${SUIF_HOME}" "${SUIF_INSTALL_INSTALL_DIR}" "${SUIF_LOCAL_SCRIPTS_HOME}" "${SUIF_SUM_HOME}"
