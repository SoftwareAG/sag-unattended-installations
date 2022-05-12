# Trial to run buildah in Docker

Current state is WIP.

The bbud command fails with:

```bash
buildah-msr1011-type-1-1  | 22-05-12T20.54.54_483 SUIF -INFO - Building container image in docker format...
buildah-msr1011-type-1-1  | time="2022-05-12T20:54:54Z" level=warning msg="error running newgidmap: exit status 1: newgidmap: write to gid_map failed: Operation not permitted\n"
buildah-msr1011-type-1-1  | time="2022-05-12T20:54:54Z" level=warning msg="falling back to single mapping"
buildah-msr1011-type-1-1  | time="2022-05-12T20:54:54Z" level=warning msg="error running newuidmap: exit status 1: newuidmap: write to uid_map failed: Operation not permitted\n"
buildah-msr1011-type-1-1  | time="2022-05-12T20:54:54Z" level=warning msg="falling back to single mapping"
buildah-msr1011-type-1-1  | 'overlay' is not supported over overlayfs, a mount_program is required: backing file system is unsupported for this graph driver
buildah-msr1011-type-1-1  | time="2022-05-12T20:54:54Z" level=warning msg="failed to shutdown storage: \"'overlay' is not supported over overlayfs, a mount_program is required: backing file system is unsupported for this graph driver\""
buildah-msr1011-type-1-1  | time="2022-05-12T20:54:54Z" level=error msg="exit status 125"
```

TODO: Research how to run a rootless buildah with docker compose
