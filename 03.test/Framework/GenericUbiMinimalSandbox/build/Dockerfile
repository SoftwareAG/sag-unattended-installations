ARG SRC_IMAGE=registry.access.redhat.com/ubi8/ubi-minimal:latest
FROM ${SRC_IMAGE}

# Hopefully this layer is cacheable
RUN microdnf -y update ;\ 
    microdnf -y install \
        gettext \
        gzip \
        java-11-openjdk-headless \
        less \
        nc \
        procps \
        shadow-utils \
        tar \
        which \
        ;\ 
    microdnf clean all ;\ 
    rm -rf /var/cache/yum

# Note:
# mounting binary files has some limits depending on the host os and FS type
# in some situations chmod +x doesn't work, in other they remain root owned with no possibility of changing
# For this reason, installer.bin adn sum-bootstrap.bin will be mounted, but not directly in the executable
# path declared with ${SUIF_INSTALL_INSTALLER_BIN} and ${SUIF_PATCH_SUM_BOOTSTRAP_BIN}

ARG __suif_audit_base_dir=/app/audit
ARG __suif_home=/mnt/suif
ARG __suif_install_image_file=/mnt/products.zip
ARG __suif_install_install_dir=/app/sag/version/flavor
ARG __suif_install_installer_bin_mount_point=/mnt/installer.bin
ARG __suif_local_scripts_home=/mnt/scripts/local
ARG __suif_patch_fixes_image_file=/mnt/fixes.zip
ARG __suif_patch_sum_bootstrap_bin_mount_point=/mnt/sum-bootstrap.bin
ARG __suif_sag_user_grp_id=1804
ARG __suif_sag_user_name=sag
ARG __suif_sum_home=/app/sum11
ARG __suif_work_dir=/mnt/work

ENV \
    JAVA_HOME=${__suif_install_install_dir}/jvm/jvm/ \
    JRE_HOME=${__suif_install_install_dir}/jvm/jvm/jre/ \
    SUIF_AUDIT_BASE_DIR=${__suif_audit_base_dir} \
    SUIF_INSTALL_INSTALLER_BIN_MOUNT_POINT=${__suif_install_installer_bin_mount_point} \
    SUIF_HOME=${__suif_home} \
    SUIF_INSTALL_INSTALL_DIR=${__suif_install_install_dir} \
    SUIF_INSTALL_IMAGE_FILE=${__suif_install_image_file} \
    SUIF_LOCAL_SCRIPTS_HOME=${__suif_local_scripts_home} \
    SUIF_PATCH_FIXES_IMAGE_FILE=${__suif_patch_fixes_image_file} \
    SUIF_PATCH_SUM_BOOTSTRAP_BIN_MOUNT_POINT=${__suif_patch_sum_bootstrap_bin_mount_point} \
    SUIF_SAG_GROUP_NAME=${__suif_sag_user_name}group \
    SUIF_SAG_USER_NAME=${__suif_sag_user_name} \
    SUIF_SUM_HOME=${__suif_sum_home} \
    SUIF_WORK_DIR=${__suif_work_dir}

# this layer will be sandbox specific, cacheable if user passes the same args
RUN \
    groupadd -g ${__suif_sag_user_grp_id} ${SUIF_SAG_GROUP_NAME} ;\
    useradd -u ${__suif_sag_user_grp_id} -m -g ${SUIF_SAG_GROUP_NAME} ${__suif_sag_user_name} ;\ 
    mkdir -p \
        "${__suif_audit_base_dir}"  \
        "${__suif_home}" \
        "${__suif_install_install_dir}" \
        "${__suif_local_scripts_home}" \
        "${__suif_sum_home}" \
        "${__suif_work_dir}" \
        ;\ 
    touch \
        "${__suif_install_image_file}" \
        "${__suif_install_installer_bin_mount_point}" \
        "${__suif_patch_fixes_image_file}" \
        "${__suif_patch_sum_bootstrap_bin_mount_point}" \
        ;\
    chown ${__suif_sag_user_name}:${SUIF_SAG_GROUP_NAME} \
        "${__suif_install_image_file}" \
        "${__suif_install_installer_bin}" \
        "${__suif_patch_fixes_image_file}" \
        "${__suif_patch_sum_bootstrap_bin_mount_point}" \
        "${__suif_work_dir}" \
        ;\
	chown -R ${__suif_sag_user_name}:${SUIF_SAG_GROUP_NAME} \
        "${__suif_audit_base_dir}" \
        "${__suif_home}" \
        "${__suif_install_install_dir}" \
        "${__suif_local_scripts_home}" \
        "${__suif_sum_home}" \
        "${__suif_work_dir}"

USER ${__suif_sag_user_name}

VOLUME \
    "${__suif_audit_base_dir}" \
    "${__suif_home}" \
    "${__suif_install_install_dir}" \
    "${__suif_local_scripts_home}" \
    "${__suif_sum_home}" \
    "${__suif_work_dir}"
