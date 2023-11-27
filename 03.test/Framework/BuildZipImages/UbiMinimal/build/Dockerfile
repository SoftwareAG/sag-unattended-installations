FROM registry.access.redhat.com/ubi8/ubi-minimal

# Hopefully this layer is cacheable
RUN microdnf -y update &&\ 
    microdnf -y install \
        gettext \
        gzip \
        java-11-openjdk-devel \
        less \
        nc \
        procps \
        shadow-utils \
        tar \
        which \
        &&\
    curl https://packages.microsoft.com/config/rhel/8/prod.repo | tee /etc/yum.repos.d/microsoft.repo &&\
    microdnf install -y powershell ;\
    microdnf -y update ;\
    microdnf -y clean all ;\ 
    rm -rf /var/cache/yum

