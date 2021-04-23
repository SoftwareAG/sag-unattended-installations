# Patch installation using Software AG Update Manager v11

## Usage

- Update Manager 11 must be already present
- ensure the variables mentioned in setEnvDefault point to the correct folders
- either directly call apply.sh or, preferably, use the framework function applyPostSetupTemplate()

## Important Note

This template applies all the fixes given in the image, with no filter; thus prepare the images appropriately.
Also, the user is responsible for eventual pre or post install operations that are documented in the readmes.
