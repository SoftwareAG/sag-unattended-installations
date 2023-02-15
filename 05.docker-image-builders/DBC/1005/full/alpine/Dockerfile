ARG __from_img=alpine:latest
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
COPY ./install.sh /tmp/install/install.sh

ENV SUIF_SUM_HOME=/tmp/sumv11 \
    SUIF_AUDIT_BASE_DIR=/tmp/SUIF_AUDIT \
    SUIF_DEBUG_ON=0 \
    SUIF_HOME=/tmp/SUIF \
    SUIF_INSTALL_IMAGE_FILE="/tmp/products.zip" \
    SUIF_INSTALL_INSTALL_DIR="${__sag_home}" \
    SUIF_INSTALL_INSTALLER_BIN="${__i_bin}" \
    SUIF_ONLINE_MODE=0 \
    SUIF_PATCH_AVAILABLE=1 \
    SUIF_PATCH_FIXES_IMAGE_FILE="/tmp/fixes.zip" \
    SUIF_PATCH_SUM_BOOTSTRAP_BIN="${__s_bin}" \
    SUIF_SDC_ONLINE_MODE=0

RUN cd /tmp/install; chmod u+x ./install.sh; ./install.sh

FROM alpine:latest as jre-packager-and-picker

ARG __sag_home=/opt/softwareag

RUN apk --no-cache add openjdk11-jdk openjdk11-jmods

# build minimal JRE
RUN /usr/lib/jvm/java-11-openjdk/bin/jlink \
    --verbose \
    --add-modules \
        java.base,java.sql,java.xml,java.desktop,java.management,java.security.jgss,java.instrument  \
    --compress 2 --strip-debug --no-header-files --no-man-pages \
    --release-info="add:IMPLEMENTOR=softwareag:IMPLEMENTOR_VERSION=softwareag_JRE_DBC_11" \
    --output "${__sag_home}/jvm/jvm/jre"

COPY --from=installer ${__sag_home}/common/lib/ ${__sag_home}/common/lib/
COPY --from=installer ${__sag_home}/common/db/ ${__sag_home}/common/db/


FROM ${__from_img}

ARG __sag_home=/opt/softwareag
ARG __sag_user_id=1824
ARG __sag_grp_id=1824
ARG __sag_grp_name=SAG_GROUP
ARG __sag_user_name=SAG_USER

ENV \
    JAVA_HOME="${__sag_home}/jvm/jvm/jre" \
    PATH="$PATH:${__sag_home}/jvm/jvm/jre/bin" \
    SAG_HOME="${__sag_home}"

RUN addgroup -g ${__sag_grp_id} "${__sag_grp_name}" && \
    adduser --shell /sbin/nologin --disabled-password \
    --no-create-home --uid ${__sag_user_id} --ingroup "${__sag_grp_name}"  "${__sag_user_name}"

COPY --chown=${__sag_user_id}:${__sag_grp_id} --from=jre-packager-and-picker ${__sag_home} ${__sag_home}

USER ${__sag_user_id}

RUN mkdir -p ${__sag_home}/common/db/logs

VOLUME ${__sag_home}/common/db/logs