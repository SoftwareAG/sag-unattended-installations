FROM adminer
USER root

RUN apk --no-cache add libaio libnsl libc6-compat curl && \
  ln -s /lib/libc.so.6 /usr/lib/libresolv.so.2 && \
  cd /tmp

ENV ORACLE_BASE /usr/local/oracle
ENV LD_LIBRARY_PATH /usr/local/oracle/instantclient_21_7:/lib64
ENV TNS_ADMIN /usr/local/oracle/instantclient_21_7/network/admin
ENV ORACLE_HOME /usr/local/oracle

# # Install Oracle Client and build OCI8 (Oracle Command Interface 8 - PHP extension)
RUN \
## Download and unarchive Instant Client v11
  mkdir /usr/local/oracle && \
  curl -o /tmp/sdk.zip https://download.oracle.com/otn_software/linux/instantclient/217000/instantclient-sdk-linux.x64-21.7.0.0.0dbru.zip && \
  curl -o /tmp/basic_lite.zip https://download.oracle.com/otn_software/linux/instantclient/217000/instantclient-basiclite-linux.x64-21.7.0.0.0dbru.zip && \
  unzip -d /usr/local/oracle /tmp/sdk.zip && \
  unzip -d /usr/local/oracle /tmp/basic_lite.zip

## Build OCI8 with PECL
RUN \
  C_INCLUDE_PATH=/usr/local/oracle/instantclient_21_7/sdk/include/ docker-php-ext-configure oci8 --with-oci8=instantclient,/usr/local/oracle/instantclient_21_7 && docker-php-ext-install oci8

#  Clean up
RUN \
  rm -rf /tmp/*.zip /var/cache/apk/* /tmp/pear/
USER adminer