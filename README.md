# Software AG Unattented Installation Assets

- [Software AG Unattented Installation Assets](#software-ag-unattented-installation-assets)
  - [Folders](#folders)
    - [01.scripts](#01scripts)
    - [02.templates](#02templates)
      - [02.templates.01.setup](#02templates01setup)
      - [02.templates.02.post-setup](#02templates02post-setup)
    - [03.test](#03test)
    - [04.support](#04support)
  - [Important notes](#important-notes)

Collection of scripts to be "curled" during unattended cloud installations for Software AG products

## Folders

### 01.scripts

Contain the scripting assets for this repository. This is the core of the overall project.

### 02.templates

Contains templates for installations which leverage the core functions in the scripting assets. These are further divided in

#### 02.templates.01.setup

#### 02.templates.02.post-setup

### 03.test

Contain test harnesses for the scripts and templates

### 04.support

Utilities supporting the considered use cases, e.g. a kernel properties setter for Elasticsearch.

## Important notes

All files must have unix style endlines even when using docker desktop for Windows. Clone accordingly!
