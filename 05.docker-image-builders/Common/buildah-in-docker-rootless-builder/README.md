# Buildah in Docker Rootless Local Builder

The purpose of this container build context is to provide a rootless build method for multi-stage builders.

Refer the build context from your project and the related `seccomp` file. The `seccomp` file is taken from the `buildah` code [here](https://github.com/containers/buildah/blob/main/vendor/github.com/containers/common/pkg/seccomp/seccomp.json).

