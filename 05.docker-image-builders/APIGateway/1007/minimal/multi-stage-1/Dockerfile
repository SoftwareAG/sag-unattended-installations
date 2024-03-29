ARG __from_img=centos:8
# ARG __from_img used below on the final stage

############### Stage 1 - install the product and fixes from given zip image files
FROM centos:7 as installer

ARG __suif_tag=main

LABEL MAINTAINER MIUN@SAG

# Tamporary until buildah fix will be available: one argument for ARG
ARG __i_bin=/tmp/installer.bin
ARG __s_bin=/tmp/sum-bootstrap.bin
ARG __sag_home=/opt/softwareag

ENV SUIF_TAG=${__suif_tag}
# ENV INSTANCE_NAME default

RUN yum -y update ;\ 
    yum -y install git curl gettext which

COPY ./installer.bin ${__i_bin}
COPY ./sum-bootstrap.bin ${__s_bin}
COPY ./products.zip /tmp/products.zip
COPY ./fixes.zip /tmp/fixes.zip
COPY ./yai-license.xml /tmp/yai-license.xml
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
    SUIF_PATCH_SUM_BOOTSTRAP_BIN="${__s_bin}" \
    SUIF_SDC_ONLINE_MODE=0 \
    SUIF_SETUP_TEMPLATE_YAI_LICENSE_FILE="/tmp/yai-license.xml"

RUN cd /tmp/install; chmod u+x ./install.sh; ./install.sh;

# When mature enough lose the audit
RUN tar czf "${SUIF_INSTALL_INSTALL_DIR}/install.audit.tgz" "${SUIF_AUDIT_BASE_DIR}"

# work around if the folder does not exist, which it should not
# RUN mkdir -p ${SAG_HOME}/IntegrationServer/instances/${INSTANCE_NAME}/db

############### Stage 2 - pick the necessary files and folders
FROM centos:7 as packer

ARG __sag_home=/opt/softwareag

ENV SAG_HOME=${__sag_home} \
    JAVA_HOME=${__sag_home}/jvm/jvm/ \
    JRE_HOME=${__sag_home}/jvm/jvm/jre/ \
    INSTANCE_NAME=default

COPY --from=installer ${SAG_HOME}/jvm/jvm/ ${SAG_HOME}/jvm/jvm/
COPY --from=installer ${SAG_HOME}/install/jars/ ${SAG_HOME}/install/jars/
COPY --from=installer ${SAG_HOME}/install/profile/ ${SAG_HOME}/install/profile/
COPY --from=installer ${SAG_HOME}/install/products/ ${SAG_HOME}/install/products/

# trial 10, successful
COPY --from=installer ${SAG_HOME}/install/configurations/ ${SAG_HOME}/install/configurations/
COPY --from=installer ${SAG_HOME}/install/etc/ ${SAG_HOME}/install/etc/
COPY --from=installer ${SAG_HOME}/install/portparams/ ${SAG_HOME}/install/portparams/

COPY --from=installer ${SAG_HOME}/common/bin/ ${SAG_HOME}/common/bin/
COPY --from=installer ${SAG_HOME}/common/conf/ ${SAG_HOME}/common/conf/
COPY --from=installer ${SAG_HOME}/common/db/ ${SAG_HOME}/common/db/
COPY --from=installer ${SAG_HOME}/common/DigitalEventServices/ ${SAG_HOME}/common/DigitalEventServices/
COPY --from=installer ${SAG_HOME}/common/EventTypeStore/ ${SAG_HOME}/common/EventTypeStore/
COPY --from=installer ${SAG_HOME}/common/metering/ ${SAG_HOME}/common/metering/
COPY --from=installer ${SAG_HOME}/common/lib/ ${SAG_HOME}/common/lib/
COPY --from=installer ${SAG_HOME}/common/runtime/ ${SAG_HOME}/common/runtime/


COPY --from=installer ${SAG_HOME}/WS-Stack/ ${SAG_HOME}/WS-Stack/

COPY --from=installer ${SAG_HOME}/IntegrationServer/bin/ ${SAG_HOME}/IntegrationServer/bin/
COPY --from=installer ${SAG_HOME}/IntegrationServer/lib/ ${SAG_HOME}/IntegrationServer/lib/
COPY --from=installer ${SAG_HOME}/IntegrationServer/updates/ ${SAG_HOME}/IntegrationServer/updates/
#COPY --from=installer ${SAG_HOME}/IntegrationServer/web/ ${SAG_HOME}/IntegrationServer/web/
COPY --from=installer ${SAG_HOME}/IntegrationServer/docker/ ${SAG_HOME}/IntegrationServer/docker/
#COPY --from=installer ${SAG_HOME}/IntegrationServer/replicate/ ${SAG_HOME}/IntegrationServer/replicate/
COPY --from=installer ${SAG_HOME}/IntegrationServer/features/ ${SAG_HOME}/IntegrationServer/features/

COPY --from=installer ${SAG_HOME}/IntegrationServer/.tc.custom.log4j2.properties \
  ${SAG_HOME}/IntegrationServer/.tc.custom.log4j2.properties
#COPY --from=installer ${SAG_HOME}/IntegrationServer/config/ ${SAG_HOME}/IntegrationServer/config/
#COPY --from=installer ${SAG_HOME}/IntegrationServer/packages/ ${SAG_HOME}/IntegrationServer/packages/

########## IS instance section

COPY --from=installer \
  ${SAG_HOME}/IntegrationServer/instances/${INSTANCE_NAME}/web/ \
  ${SAG_HOME}/IntegrationServer/instances/${INSTANCE_NAME}/web/
COPY --from=installer \
  ${SAG_HOME}/IntegrationServer/instances/${INSTANCE_NAME}/updates/ \
  ${SAG_HOME}/IntegrationServer/instances/${INSTANCE_NAME}/updates/
COPY --from=installer \
  ${SAG_HOME}/IntegrationServer/instances/${INSTANCE_NAME}/replicate/ \
  ${SAG_HOME}/IntegrationServer/instances/${INSTANCE_NAME}/replicate/
COPY --from=installer \
  ${SAG_HOME}/IntegrationServer/instances/${INSTANCE_NAME}/lib/ \
  ${SAG_HOME}/IntegrationServer/instances/${INSTANCE_NAME}/lib/
COPY --from=installer \
  ${SAG_HOME}/IntegrationServer/instances/${INSTANCE_NAME}/bin/ \
  ${SAG_HOME}/IntegrationServer/instances/${INSTANCE_NAME}/bin/
# db folder present in the original dockerfile, but it actually does not exist before a first startup
# COPY --from=installer \
#   ${SAG_HOME}/IntegrationServer/instances/${INSTANCE_NAME}/db/ \
#   ${SAG_HOME}/IntegrationServer/instances/${INSTANCE_NAME}/db/
COPY --from=installer \
  ${SAG_HOME}/IntegrationServer/instances/${INSTANCE_NAME}/config/ \
  ${SAG_HOME}/IntegrationServer/instances/${INSTANCE_NAME}/config/
# All packages are inserted by default, but they are not really needed
COPY --from=installer \
  ${SAG_HOME}/IntegrationServer/instances/${INSTANCE_NAME}/packages/Default/ \
  ${SAG_HOME}/IntegrationServer/instances/${INSTANCE_NAME}/packages/Default/
COPY --from=installer \
  ${SAG_HOME}/IntegrationServer/instances/${INSTANCE_NAME}/packages/WmAdmin/ \
  ${SAG_HOME}/IntegrationServer/instances/${INSTANCE_NAME}/packages/WmAdmin/
COPY --from=installer \
  ${SAG_HOME}/IntegrationServer/instances/${INSTANCE_NAME}/packages/WmRoot/\
  ${SAG_HOME}/IntegrationServer/instances/${INSTANCE_NAME}/packages/WmRoot/
COPY --from=installer \
  ${SAG_HOME}/IntegrationServer/instances/${INSTANCE_NAME}/packages/WmPublic/ \
  ${SAG_HOME}/IntegrationServer/instances/${INSTANCE_NAME}/packages/WmPublic/
COPY --from=installer \
  ${SAG_HOME}/IntegrationServer/instances/${INSTANCE_NAME}/packages/WmCloud/ \
  ${SAG_HOME}/IntegrationServer/instances/${INSTANCE_NAME}/packages/WmCloud/
COPY --from=installer \
  ${SAG_HOME}/IntegrationServer/instances/${INSTANCE_NAME}/packages/WmAPIGateway/ \
  ${SAG_HOME}/IntegrationServer/instances/${INSTANCE_NAME}/packages/WmAPIGateway/
COPY --from=installer \
  ${SAG_HOME}/IntegrationServer/instances/is_instance.xml \
  ${SAG_HOME}/IntegrationServer/instances/is_instance.xml
COPY --from=installer \
  ${SAG_HOME}/IntegrationServer/instances/is_instance.sh \
  ${SAG_HOME}/IntegrationServer/instances/is_instance.sh
COPY --from=installer \
  ${SAG_HOME}/profiles/IS_${INSTANCE_NAME}/configuration/custom_wrapper.conf \
  ${SAG_HOME}/IntegrationServer/instances/custom_wrapper.conf.template

COPY --from=installer \
    ${SAG_HOME}/profiles/IS_${INSTANCE_NAME}/ \
    ${SAG_HOME}/profiles/IS_${INSTANCE_NAME}/


####### API Gatewy generated dockerfile section

RUN rm -f \
    ${SAG_HOME}/IntegrationServer/instances/${INSTANCE_NAME}/config/clusteruuid.dat \
    ${SAG_HOME}/IntegrationServer/instances/${INSTANCE_NAME}/config/backup/clusteruuid.dat

RUN chmod a+x \
    ${SAG_HOME}/profiles/IS_${INSTANCE_NAME}/apigateway/filebeat/filebeat_apigateway
RUN chmod 755 \
    ${SAG_HOME}/profiles/IS_${INSTANCE_NAME}/apigateway/filebeat/filebeat_apigateway.yml

RUN chmod a+x ${SAG_HOME}/profiles/IS_${INSTANCE_NAME}/bin/*.sh; 

RUN sed -i '/apigw.console.log/c\apigw.console.log = true' \
    ${SAG_HOME}/profiles/IS_${INSTANCE_NAME}/apigateway/config/uiconfiguration.properties

# When mature enough might lose the audit
COPY --from=installer ${SAG_HOME}/install.audit.tgz ${SAG_HOME}/install.audit.tgz

### Final cleanup and optimizations
# the config backup folder, if exists, does not make sense in containers
RUN rm -f ${SAG_HOME}/IntegrationServer/instances/${INSTANCE_NAME}/config/backup

RUN rm -f ${SAG_HOME}/IntegrationServer/instances/${INSTANCE_NAME}/config/licenseKey.xml; \
    touch ${SAG_HOME}/IntegrationServer/instances/${INSTANCE_NAME}/config/licenseKey.xml

# Trial 8: For some reason WmAPIGateway package does not load completely because this file is missing (?)
RUN touch ${SAG_HOME}/profiles/IS_default/apigateway/dashboard/config/kibana.yml

# eventually, but it doesn't seem the case here
# RUN mkdir-p ${SAG_HOME}/IntegrationServer/config; \
#     rm -f ${SAG_HOME}/IntegrationServer/config/licenseKey.xml; \
#     touch ${SAG_HOME}/IntegrationServer/config/licenseKey.xml


############### Stage 3 - final build of the API Gateway minimal image

FROM "${__from_img}"

ARG __sag_home=/opt/softwareag
ARG __user_group_id=1724

ENV SAG_HOME=${__sag_home} \
    JAVA_HOME=${__sag_home}/jvm/jvm/ \
    JRE_HOME=${__sag_home}/jvm/jvm/jre/ \
    INSTANCE_NAME=default \
    EXTERN_ELASTICSEARCH=true

RUN groupadd -g ${__user_group_id} sagadmin ;\
    useradd -u ${__user_group_id} -m -g ${__user_group_id} -d ${SAG_HOME} sagadmin

COPY --from=packer --chown=${__user_group_id}:${__user_group_id} ${SAG_HOME} ${SAG_HOME}

HEALTHCHECK --interval=200s CMD curl -f http://localhost:5555/rest/apigateway/health

USER sagadmin

# Unknown yet - to verify
#RUN cd ${SAG_HOME}/IntegrationServer/instances; ./is_instance.sh create-osgi-profile -Dinstance.name=${INSTANCE_NAME}
#RUN cd ${SAG_HOME}/IntegrationServer/docker; ./is_container.sh updateDockerConfigFiles -Ddocker.isHomeDir=${SAG_HOME}/IntegrationServer -Ddocker.rootDir=${SAG_HOME};
EXPOSE 5555
EXPOSE 9999
EXPOSE 5553

ENTRYPOINT "${SAG_HOME}/IntegrationServer/bin/startContainer.sh"
