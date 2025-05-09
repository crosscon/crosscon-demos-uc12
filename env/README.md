# Docker for CROSSCON Hypervisor

## Overview

The purpose of this repo is to provide the environment required for
compilation of the CROSSCON hypervisor.

## Clone the repository

Clone the repository by executing following command.
```bash
git clone --recurse-submodules git@github.com:3mdeb/CROSSCON-Hypervisor-and-TEE-Isolation-Demos.git crosscon-demos && \
cd crosscon-demos
```

## Build & run the container

Build docker container.

```bash
docker build -t crosscon_hv -f env/Dockerfile .
```

The resulting image will have a `crosscon_hv` tag.
After the image has been built, execute `env/run.sh` script to run
the container.

```bash
env/run.sh
```

## Building the rpi4-ws demo

Inside the container, use below script to build the demo `rpi4-ws` package.

```bash
env/build_rpi4.sh
```

The script steps follow exactly what can be found in
[the README](../rpi4-ws/README.md) on how to build the demo.


## Copying the files to the SD card.

Inside the container, follow the
"[Prepare SDCard](https://github.com/3mdeb/CROSSCON-Hypervisor-and-TEE-Isolation-Demos/blob/master/rpi4-ws/README.md#prepare-sdcard)"
chapter to setup the filesystem on SD card.  
**NOTE: Make sure your card did not get mounted by default on host!**

### Building and copying the CROSSCON Hypervisor

Scripts `rpi4-ws/build-demo-vtee.sh` and `rpi4-ws/build-demo-dual-vtee.sh`
build the hypervisor and transfer the files to the SD card. More can be read
[here](https://github.com/3mdeb/CROSSCON-Hypervisor-and-TEE-Isolation-Demos/blob/master/rpi4-ws/README.md#simple-demo).

The `env/hyp_build_and_copy.sh` script can be used to build hypervisor and copy
all needed files ono SD card. **Warning**: The script auto-mounts
`/dev/mmcblk0p1` partition and copies files there. If this is not how the device
is represented on your system modify the script accordingly.

```bash
env/hyp_build_and_copy.sh
```

## QEMU build

The docker image contains all the neccessary dependencies to build the QEMU
images as well (RISCV included), so all that needs to be done is following
the instructions from [the readme](../README.md).
