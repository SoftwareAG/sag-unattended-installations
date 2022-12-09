ARG __from_img=registry.access.redhat.com/ubi8/ubi-minimal:latest
# ARG __from_img used below on the final stage
FROM registry.access.redhat.com/ubi8/ubi-minimal:latest as installer

# Tamporary until buildah fix will be available: one argument for ARG
ARG __i_bin=/tmp/installer.bin
ARG __s_bin=/tmp/sum-bootstrap.bin
ARG __sag_home=/opt/softwareag

RUN microdnf -y update ;\
    microdnf -y install \
        gettext \
        git \
        gzip \
        less \
        nc \
        procps \
        shadow-utils \
        tar \
        which \
        ;\
    microdnf clean all ;\
    rm -rf /var/cache/yum

COPY ./installer.bin ${__i_bin}
COPY ./sum-bootstrap.bin ${__s_bin}
COPY ./products.zip /tmp/products.zip
COPY ./fixes.zip /tmp/fixes.zip
COPY ./msr-license.xml /tmp/msr-license.xml
COPY ./brms-license.xml /tmp/brms-license.xml
COPY ./install.sh /tmp/install/install.sh

ENV SUIF_SUM_HOME=/tmp/sumv11 \
    SUIF_AUDIT_BASE_DIR=/tmp/SUIF_AUDIT \
    SUIF_DEBUG_ON=0 \
    SUIF_HOME=/tmp/SUIF \
    SUIF_INSTALL_IMAGE_FILE="/tmp/products.zip" \
    SUIF_INSTALL_INSTALL_DIR="${__sag_home}" \
    SUIF_INSTALL_INSTALLER_BIN="${__i_bin}" \
    SUIF_INSTALL_TIME_ADMIN_PASSWORD=manage01 \
    SUIF_ONLINE_MODE=0 \
    SUIF_PATCH_AVAILABLE=1 \
    SUIF_PATCH_FIXES_IMAGE_FILE="/tmp/fixes.zip" \
    SUIF_PATCH_SUM_BOOSTSTRAP_BIN="${__s_bin}" \
    SUIF_SDC_ONLINE_MODE=0 \
    SUIF_SETUP_TEMPLATE_BRMS_LICENSE_FILE="/tmp/brms-license.xml" \
    SUIF_SETUP_TEMPLATE_MSR_LICENSE_FILE="/tmp/msr-license.xml"

RUN cd /tmp/install; chmod u+x ./install.sh; ./install.sh

# When mature enough lose the audit
RUN tar czf "${SUIF_INSTALL_INSTALL_DIR}/install.audit.tgz" "${SUIF_AUDIT_BASE_DIR}"

FROM alpine as packer

ARG __sag_home=/opt/softwareag

ENV SAG_HOME ${__sag_home}

# When mature enough might lose the audit
COPY --from=installer ${SAG_HOME}/install.audit.tgz ${SAG_HOME}/install.audit.tgz

COPY --from=installer ${SAG_HOME}/jvm/jvm/ ${SAG_HOME}/jvm/jvm/
COPY --from=installer ${SAG_HOME}/install/products/ ${SAG_HOME}/install/products/

COPY --from=installer ${SAG_HOME}/common/bin/ ${SAG_HOME}/common/bin/
COPY --from=installer ${SAG_HOME}/common/conf/ ${SAG_HOME}/common/conf/
COPY --from=installer ${SAG_HOME}/common/db/ ${SAG_HOME}/common/db/
COPY --from=installer ${SAG_HOME}/common/metering/ ${SAG_HOME}/common/metering/
COPY --from=installer ${SAG_HOME}/common/lib/ ${SAG_HOME}/common/lib/

COPY --from=installer ${SAG_HOME}/WS-Stack/ ${SAG_HOME}/WS-Stack/

COPY --from=installer ${SAG_HOME}/IntegrationServer/bin/ ${SAG_HOME}/IntegrationServer/bin/
COPY --from=installer ${SAG_HOME}/IntegrationServer/lib/ ${SAG_HOME}/IntegrationServer/lib/
COPY --from=installer ${SAG_HOME}/IntegrationServer/updates/ ${SAG_HOME}/IntegrationServer/updates/
COPY --from=installer ${SAG_HOME}/IntegrationServer/web/ ${SAG_HOME}/IntegrationServer/web/
COPY --from=installer ${SAG_HOME}/IntegrationServer/docker/ ${SAG_HOME}/IntegrationServer/docker/
COPY --from=installer ${SAG_HOME}/IntegrationServer/replicate/ ${SAG_HOME}/IntegrationServer/replicate/

COPY --from=installer ${SAG_HOME}/IntegrationServer/.tc.custom.log4j2.properties ${SAG_HOME}/IntegrationServer/.tc.custom.log4j2.properties

COPY --from=installer ${SAG_HOME}/IntegrationServer/config/ ${SAG_HOME}/IntegrationServer/config/

COPY --from=installer ${SAG_HOME}/IntegrationServer/packages/Default/ ${SAG_HOME}/IntegrationServer/packages/Default/
COPY --from=installer ${SAG_HOME}/IntegrationServer/packages/WmAdmin/ ${SAG_HOME}/IntegrationServer/packages/WmAdmin/
COPY --from=installer ${SAG_HOME}/IntegrationServer/packages/WmART/ ${SAG_HOME}/IntegrationServer/packages/WmART/
COPY --from=installer ${SAG_HOME}/IntegrationServer/packages/WmARTExtDC/ ${SAG_HOME}/IntegrationServer/packages/WmARTExtDC/

COPY --from=installer ${SAG_HOME}/IntegrationServer/packages/WmCloud/ ${SAG_HOME}/IntegrationServer/packages/WmCloud/
COPY --from=installer ${SAG_HOME}/IntegrationServer/packages/WmConsul/ ${SAG_HOME}/IntegrationServer/packages/WmConsul/
COPY --from=installer ${SAG_HOME}/IntegrationServer/packages/WmFlatFile/ ${SAG_HOME}/IntegrationServer/packages/WmFlatFile/
COPY --from=installer ${SAG_HOME}/IntegrationServer/packages/WmISExtDC/ ${SAG_HOME}/IntegrationServer/packages/WmISExtDC/
COPY --from=installer ${SAG_HOME}/IntegrationServer/packages/WmJDBCAdapter/ ${SAG_HOME}/IntegrationServer/packages/WmJDBCAdapter/
COPY --from=installer ${SAG_HOME}/IntegrationServer/packages/WmJSONAPI/ ${SAG_HOME}/IntegrationServer/packages/WmJSONAPI/
COPY --from=installer ${SAG_HOME}/IntegrationServer/packages/WmPublic/ ${SAG_HOME}/IntegrationServer/packages/WmPublic/
COPY --from=installer ${SAG_HOME}/IntegrationServer/packages/WmRoot/ ${SAG_HOME}/IntegrationServer/packages/WmRoot/
COPY --from=installer ${SAG_HOME}/IntegrationServer/packages/WmSAP/ ${SAG_HOME}/IntegrationServer/packages/WmSAP/
COPY --from=installer ${SAG_HOME}/IntegrationServer/packages/WmXSLT/ ${SAG_HOME}/IntegrationServer/packages/WmXSLT/
COPY --from=installer ${SAG_HOME}/IntegrationServer/packages/WmBusinessRules/ ${SAG_HOME}/IntegrationServer/packages/WmBusinessRules/

RUN rm ${SAG_HOME}/IntegrationServer/config/licenseKey.xml; touch ${SAG_HOME}/IntegrationServer/config/licenseKey.xml

FROM "${__from_img}"

ARG __sag_home=/opt/softwareag
ARG __user_group_id=1724

ENV SAG_HOME=${__sag_home} \
    JAVA_HOME=${__sag_home}/jvm/jvm/ \
    JRE_HOME=${__sag_home}/jvm/jvm/ \
    JDK_HOME=${__sag_home}/jvm/jvm/

RUN microdnf -y update ;\ 
    microdnf -y install \
        procps \
        shadow-utils \
        ;\
    microdnf clean all ;\
    rm -rf /var/cache/yum ;\
    groupadd -g ${__user_group_id} sagadmin ;\
    useradd -u ${__user_group_id} -m -g ${__user_group_id} -d ${__sag_home} sagadmin

COPY --from=packer --chown=${__user_group_id}:${__user_group_id} ${__sag_home} ${__sag_home}

USER sagadmin

#RUN cd /opt/softwareag/IntegrationServer/docker; ./is_container.sh updateDockerConfigFiles -Ddocker.isHomeDir=${SAG_HOME}/IntegrationServer -Ddocker.rootDir=${SAG_HOME};
EXPOSE 5555
EXPOSE 9999
EXPOSE 5553

ENTRYPOINT "/bin/bash" "-c" "${SAG_HOME}/IntegrationServer/bin/startContainer.sh"
