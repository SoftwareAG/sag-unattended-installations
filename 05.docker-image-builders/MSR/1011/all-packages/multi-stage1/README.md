# Generic Custom Builder for MSR with all packages and multi-stage build No. 1

This custom builder is a multi-stage evolution of the out of the box Dockerfile, arranged in a multi-stage manner and thought to be used in unattended DevOps pipelines.

The Dockerfile requires that the installer, update manager and the product and fix images are built or prepared beforehand.

## How to use

- copy Dockerfile and install.sh in a build context folder
- copy the following upfront prepared files in the same build context folder
  - ./installer.bin
    - linux installer binary
  - ./sum-bootstrap.bin
    - linux Update Manager Bootstrapper binary
  - ./products.zip
    - Installer image containing the products for the template provided with `${SUIF_TEMPLATE}`
  - ./fixes.zip
    - Update Manage fixes image containing the fixes for the template provided with`${SUIF_TEMPLATE}`
  - ./msr-license.xml
    - License file for microservices runtime or specialization, e.g. CloudStreams Server
- build against the build context folder
