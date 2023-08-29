# Custom Builder for MSR lean with JDBC Adapter 01

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
    - Installer image containing MSR/1011/AdapterSet1 component
  - ./fixes.zip
    - Update Manage fixes image containing MSR/1011/AdapterSet1 fixes
  - ./msr-license.xml
    - Microservices runtime license file
- build against the build context folder
