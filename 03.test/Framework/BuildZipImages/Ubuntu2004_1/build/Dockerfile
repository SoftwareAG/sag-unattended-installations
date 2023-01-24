FROM ubuntu:20.04

RUN apt-get -qy update; \
    apt-get -qy install curl wget; \
    mkdir /tmp/pwshInstall; \
    cd /tmp/pwshInstall || return 1; \
    . /etc/os-release; \
    wget -q https://packages.microsoft.com/config/ubuntu/${VERSION_ID}/packages-microsoft-prod.deb; \
    dpkg -i packages-microsoft-prod.deb; \
    apt-get -y update; \
    apt-get -y install powershell
