# Elasticsearch Host Prerequisites

This little project is setting the required kernel parameters on the docker host.

For example the kernel parameter vm.max_map_count cannot be set at container level, while nofile ulimit can.

See run.bat for how to run the command.

The setting is done for the ccurrent session only, it is not permanent.

## Remember

Do not use privileged containers in normal operations, in this case it is required by the fact we are changing host kernel parameters.
