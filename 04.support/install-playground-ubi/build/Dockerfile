ARG __src_image=registry.access.redhat.com/ubi8/ubi-minimal:latest
FROM ${__src_image}

ARG __installDir=/app/sag/version/products

ENV SUIF_INSTALL_InstallDir=${__installDir} \
    JAVA_HOME=${__installDir}/jvm/jvm/ \
    JRE_HOME=${__installDir}/jvm/jvm/jre/ \
    SUIF_USER_HOME=/home/sag \
    SUIF_SUM_HOME=/app/sag/sumv11 \
    SUIF_LOCAL_SCRIPTS_HOME=/mnt/scripts \
    SUIF_AUDIT_BASE_DIR=/app/audit

RUN microdnf -y update ;\
    microdnf -y install which less gettext telnet ;\
    microdnf clean all ;\
    rm -rf /var/cache/yum ;\
    groupadd -g 1803 saggroup ;\
    useradd -u 1803 -m -g saggroup sag ;\
    mkdir -p "${SUIF_SUM_HOME}" "${SUIF_AUDIT_BASE_DIR}" \
      "${__installDir}" "${SUIF_LOCAL_SCRIPTS_HOME}" ;\
    chown -R sag:saggroup "${SUIF_LOCAL_SCRIPTS_HOME}" ;\
    chown -R sag:saggroup "${SUIF_SUM_HOME}" ;\
    chown -R sag:saggroup "${SUIF_AUDIT_BASE_DIR}" ;\
    chown -R sag:saggroup "${__installDir}"

USER sag
