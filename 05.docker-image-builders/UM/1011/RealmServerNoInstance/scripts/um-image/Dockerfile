ARG BASE_IMG=redhat/ubi8-init
FROM ${BASE_IMG}

ARG __sag_home=/opt/softwareag \
    __um_port=9000

ENV	SAG_HOME=${__sag_home} \
    UM_HOME=${__sag_home}/UniversalMessaging \
    UM_PORT=${__um_port} \
    USERS_DIR=${__sag_home}/common/conf \
    SERVER_COMMON_CONF_FILE=Server_Common.conf \
    TOOLS_DIR=${__sag_home}/UniversalMessaging/tools \
    PATH=${__sag_home}/UniversalMessaging/tools/runner/:$PATH

RUN yum install ca-certificates ;\
    yum -y update ;\
    yum clean all ;\
    rm -rf /var/cache/yum ;\
    groupadd -g 1804 ${SUIF_SAG_GROUP_NAME} ;\
    useradd -u 1804 -m -g ${SUIF_SAG_GROUP_NAME} ${SUIF_SAG_USER_NAME} ;\
    mkdir -p "${UM_HOME}/server" ;\
    chown ${SUIF_SAG_USER_NAME}:${SUIF_SAG_GROUP_NAME} "${UM_HOME}/server"  

## Copy the entry point script
COPY --chown=${SUIF_SAG_USER_NAME}:${SUIF_SAG_GROUP_NAME} ./ $SAG_HOME/

USER ${SUIF_SAG_USER_NAME}

## Create the Persistent storage for data directory, logs directory, licence directory and users directory
VOLUME "${UM_HOME}/server"

## Change the work directory, where the entry point script is present.
WORKDIR $SAG_HOME
ENTRYPOINT ["sh", "umstart.sh"]

HEALTHCHECK --interval=15s --timeout=30s --start-period=60s  CMD $UM_HOME/tools/runner/runUMTool.sh GetServerTime -rname=nsp://localhost:${UM_PORT} || exit 1

EXPOSE $PORT