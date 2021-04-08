ARG BASE_IMG=centos:7
FROM ${BASE_IMG}

ARG WMLAB_GPG_KEYS_FILE_1=/etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

RUN if [ -f "$WMLAB_GPG_KEYS_FILE_1" ] ; then rpmkeys --import "${WMLAB_GPG_KEYS_FILE_1}" ; fi &&\ 
    yum -y update &&\
    yum install -y net-tools unzip less telnet &&\
    yum clean all &&\
    rm -rf /var/cache/yum

RUN groupadd -g 1801 author &&\
    useradd -u 1801 -m -g 1801 author

USER 1801
