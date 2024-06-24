ARG __src_image=registry.access.redhat.com/ubi8/ubi-minimal:latest
FROM ${__src_image}

ARG __install_dir=/app/sag/version/products

ENV SUIF_INSTALL_InstallDir=${__install_dir} \
    JAVA_HOME=${__install_dir}/jvm/jvm/ \
    JRE_HOME=${__install_dir}/jvm/jvm/jre/ \
    SUIF_USER_HOME=/home/sag \
    SUIF_SUM_HOME=/app/sag/sumv11 \
    SUIF_LOCAL_SCRIPTS_HOME=/mnt/scripts \
    SUIF_AUDIT_BASE_DIR=/app/audit

RUN microdnf -y update ;\
    microdnf -y install \
      findutils \
      gettext \
      gzip \
      less \
      shadow-utils \
      tar \
      which \
      ;\
    microdnf clean all ;\
    rm -rf /var/cache/yum; \
    /usr/sbin/groupadd -r -g 1803 saggroup ;\
    /usr/sbin/useradd -r -u 1803 -m -g saggroup sag ;\
    mkdir -p "${SUIF_SUM_HOME}" "${SUIF_AUDIT_BASE_DIR}" \
      "${__install_dir}" "${SUIF_LOCAL_SCRIPTS_HOME}" ;\
    chown -R sag:saggroup "${SUIF_LOCAL_SCRIPTS_HOME}" ;\
    chown -R sag:saggroup "${SUIF_SUM_HOME}" ;\
    chown -R sag:saggroup "${SUIF_AUDIT_BASE_DIR}" ;\
    chown -R sag:saggroup "${__install_dir}"

USER sag

# VOLUME /mnt/output
