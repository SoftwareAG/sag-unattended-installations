# Images generator

The purpose of this helper is to generate product and fixes images for the setup and patching templates.
The user may keep a volume or a local folder with these images. The image creation is incremental, i.e. it will create only the images that do not already esist in the provided volume.

Paths to the images follow the same structure as the setup templates.

## Prerequisites

- Local docker and docker compose
- Internet access, scripting assets are cloned from GitHub
- Installer and update manager bootstrap binaries
- Empower credentials able to download Software aG products

Assumption: the user is allowed to download all involved products. If this is not the case, manually remove the out of scope templates. If the need arises, a "template ignore" feature will be eventually added.

## Quickstart

All prerequisite files are in mentioned in the file .env_example.

1. Procure prerequisite Software AG files
2. Copy .env_example into .env
3. Modify .env to point to your local Software AG files
4. run the following command (also written in run.bat)

```sh
docker-compose run --rm img-gen /mnt/scripts/containerEntrypoint.sh
```
