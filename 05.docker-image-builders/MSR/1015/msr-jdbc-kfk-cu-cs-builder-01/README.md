# Custom Builder for MSR with Central Users, CDS, JDBC and Kafka Adapters, CloudStreams Server

This custom builder is a multi stage evolution of the out of the box Dockerfile, arranged in a multi-stage manner and thought to be used in unattended DevOps pipelines.

The Dockerfile requires that the installer, update manager and the product and fix images are built or prepared beforehand.

## How to use

- copy Dockerfile and install.sh in a build context folder
- copy the following upfront prepared files in the same build context folder
  - ./installer.bin
    - linux installer binary
  - ./sum-bootstrap.bin
    - linux Update Manager Bootstrapper binary
  - ./products.zip
    - Installer image containing MSR/1015/jdbc_kfk_cu_cs component
  - ./fixes.zip
    - Update Manager fixes image containing MSR/1015/jdbc_kfk_cu_cs fixes
  - ./msr-license.xml
    - Microservices runtime license file
