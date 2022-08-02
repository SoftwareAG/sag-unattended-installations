ARG __from_img=centos:8
# ARG __from_img used below on the final stage
FROM centos:7 as installer

# Tamporary until buildah fix will be available: one argument for ARG
ARG __i_bin=/tmp/installer.bin
ARG __s_bin=/tmp/sum-bootstrap.bin
ARG __sag_home=/opt/softwareag
ARG __suif_template=MSR/1011/lean
ARG __suif_tag=main

RUN yum -y update ;\ 
    yum -y install git curl gettext which

COPY ./installer.bin ${__i_bin}
COPY ./sum-bootstrap.bin ${__s_bin}
COPY ./products.zip /tmp/products.zip
COPY ./fixes.zip /tmp/fixes.zip
COPY ./msr-license.xml /tmp/msr-license.xml
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
    SUIF_SETUP_TEMPLATE_MSR_LICENSE_FILE="/tmp/msr-license.xml" \
    SUIF_TAG="${__suif_tag}" \
    SUIF_TEMPLATE="${__suif_template}"

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

# All packages
COPY --from=installer ${SAG_HOME}/IntegrationServer/packages/ ${SAG_HOME}/IntegrationServer/packages/

RUN rm ${SAG_HOME}/IntegrationServer/config/licenseKey.xml; touch ${SAG_HOME}/IntegrationServer/config/licenseKey.xml

FROM "${__from_img}"

ARG __sag_home=/opt/softwareag
ARG __user_group_id=1724

ENV SAG_HOME=${__sag_home} \
    JAVA_HOME=${__sag_home}/jvm/jvm/ \
    JRE_HOME=${__sag_home}/jvm/jvm/

RUN groupadd -g ${__user_group_id} sagadmin ;\
    useradd -u ${__user_group_id} -m -g ${__user_group_id} -d ${SAG_HOME} sagadmin

COPY --from=packer --chown=${__user_group_id}:${__user_group_id} ${SAG_HOME} ${SAG_HOME}

USER sagadmin

# following line is from the originally generated dockerfile, but it is not useful as we maintained the same home for all operations
#RUN cd /opt/softwareag/IntegrationServer/docker; ./is_container.sh updateDockerConfigFiles -Ddocker.isHomeDir=${SAG_HOME}/IntegrationServer -Ddocker.rootDir=${SAG_HOME};

EXPOSE 5555
EXPOSE 9999
EXPOSE 5553

ENTRYPOINT "/bin/bash" "-c" "${SAG_HOME}/IntegrationServer/bin/startContainer.sh"
