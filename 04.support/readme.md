# Support folder

This folder is provided for code authoring and general linux support, such as quickly testing commands for scripts.

For example

```sh
if [ $(sysctl "vm.max_map_count" | cut -d " " -f 3) -gt 10000000 ]; then echo 1; else echo 0; fi
```

Another use case is environment preparation, for example for setting API Gateway prerequisites
