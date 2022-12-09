# Custom Builder for MSR Lean No. 02

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
    - Installer image containing MSR/1015/BrSapJdbc component
  - ./fixes.zip
    - Update Manage fixes image containing MSR/1015/BrSapJdbc fixes
  - ./msr-license.xml
    - Microservies runtime license file
  - ./brms-license.xml
    - Busines rules server license file
- build against the build context folder
