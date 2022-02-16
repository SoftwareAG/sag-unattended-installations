ARG SRC_IMAGE=centos:7
FROM centos:7

ARG SUIF_TEST_GPG_KEYS_FILE_1=/etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

ENV SUIF_TEST_GPG_KEYS_FILE_1=${SUIF_TEST_GPG_KEYS_FILE_1}

RUN if [ -f "$SUIF_TEST_GPG_KEYS_FILE_1" ] ; then rpmkeys --import "${SUIF_TEST_GPG_KEYS_FILE_1}" ; fi &&\ 
    yum -y update &&\
    rpmkeys --import https://download.docker.com/linux/centos/gpg && \
    yum install ca-certificates &&\
    yum -y install which less gettext telnet sudo &&\
    yum-config-manager \
	  --add-repo https://download.docker.com/linux/centos/docker-ce.repo && \
    yum install -y docker-ce && \
    yum clean all &&\
    rm -rf /var/cache/yum

USER root
