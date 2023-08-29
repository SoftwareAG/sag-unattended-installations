# Installer Playground Helper based on UBI image

This project is provided to help the user create new setup templates, specifically for generating the scripts for installation.

## Usage

- Copy `EXAMPLE.env` into `.env` and provide the required variables
- Start an instance by issuing:

```sh
docker-compose up
```

- Start a separate shell in the container:

```sh
docker exec -ti install-playground-1-1 bash
```

- Look for the required licenses files or other prerequisites now or if you prefer in a separate shell

```sh
ls /mnt/sag-licenses/Integration_Server.xml
```

- Launch the installer and pick your desired configuration

```sh
${SUIF_INSTALL_INSTALLER_BIN} \
-installDir ${SUIF_INSTALL_InstallDir} \
-writeScript /mnt/output/yourTemplateNameHere.wmscript
```

- After all choices are made and immediately before the actual installation, installer writes the script file. Watch for the destination, when the file is created exit the installer. This moment may also be identified with the wizard step where you can see 

```sh
The products listed below are ready to be saved to script /mnt/output/yourTemplateNameHere.wmscript and installed.
```

- This procedure is supposed to be run online, but it can also be run against an existing image. If run online, as the first authoring step remove the Empower credentials from the output file and add the following lines at the bottom:

```sh
#Template variables
imageFile=${SUIF_INSTALL_IMAGE_FILE}
```

- Continue with the authoring of the output file by moving the lines containing variables from their original position to the bottom of the file and substituting the actual values with variable names. Example

```sh
#Template variables
imageFile=${SUIF_INSTALL_IMAGE_FILE}
InstallDir=${SUIF_INSTALL_INSTALL_DIR}
```

Installer also accepts a "LATEST" version of the components. To achieve this, run:

```sh
cd /mnt/scripts/
./setLatestVerForProducts.sh # implicit file is /mnt/output/yourTemplateNameHere.wmscript
# or
./setLatestVerForProducts.sh /path/to/install.wmscript
```
