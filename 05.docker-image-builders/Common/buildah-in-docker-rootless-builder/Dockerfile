FROM alpine

RUN apk add --no-cache --update \
        buildah \
        git \
        ; \
    echo bind:10000:65536 >> /etc/subuid; \
    echo bind:10000:65536 >> /etc/subgid; \
    adduser -D bind; \
    mkdir -p /mnt/scripts /mnt/project-home; \
    chown -R bind:bind /mnt/project-home; \
    chown -R bind:bind /mnt/scripts

USER bind
