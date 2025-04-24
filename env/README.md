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
env/scripts/build_rpi4-ws_demo.sh
```

The script follows exactly what can be found in [the README](../rpi4-ws/README.md) on how to build the demo.


## Copying the files to the SD card.

Inside the container, follow the
"[Prepare SDCard](https://github.com/3mdeb/CROSSCON-Hypervisor-and-TEE-Isolation-Demos/blob/master/rpi4-ws/README.md#prepare-sdcard)"
chapter to setup the filesystem on SD card.  
**NOTE: Make sure your card did not get mounted by default on host!**

### Copying firmware files and linux device tree

To copy firmware files and Linux and device tree image onto the SD, mount the
card at `/media/$USER/boot`

```bash
sudo mkdir -p /media/root/boot
sudo mount /dev/mmcblk0p1 /media/root/boot
```

...and use the following commands.

```bash
SDCARD=/media/root/boot

sudo cp -vr rpi4-ws/firmware/boot/* $SDCARD
sudo cp -v rpi4-ws/config.txt $SDCARD
sudo cp -v rpi4-ws/bin/bl31.bin $SDCARD
sudo cp -v rpi4-ws/bin/u-boot.bin $SDCARD
sudo cp -v lloader/linux-rpi4.bin $SDCARD
```

### Building and copying the CROSSCON Hypervisor

Scripts `rpi4-ws/build-demo-vtee.sh` and `rpi4-ws/build-demo-dual-vtee.sh`
build the hypervisor and transfer the files to the SD card. More can be read
[here](https://github.com/3mdeb/CROSSCON-Hypervisor-and-TEE-Isolation-Demos/blob/master/rpi4-ws/README.md#simple-demo).

The scripts cannot be used directly due to privileges being set up the way they
are inside the container, so we'll have to build hypervisor and copy the files manually.

To build the hypervisor run the following.

```bash
cd rpi4-ws

CONFIG_REPO=`pwd`/configs

pushd ..

make -C CROSSCON-Hypervisor/ \
	PLATFORM=rpi4 \
	CONFIG_BUILTIN=y \
	CONFIG_REPO=$CONFIG_REPO \
	CONFIG=rpi4-single-vTEE \
	OPTIMIZATIONS=0 \
        SDEES="sdSGX sdTZ" \
	CROSS_COMPILE=aarch64-none-elf- \
        clean

make -C CROSSCON-Hypervisor/ \
	PLATFORM=rpi4 \
	CONFIG_BUILTIN=y \
	CONFIG_REPO=$CONFIG_REPO \
	CONFIG=rpi4-single-vTEE \
	OPTIMIZATIONS=0 \
        SDEES="sdSGX sdTZ" \
	CROSS_COMPILE=aarch64-none-elf- \
        -j`nproc`

popd

cd -
```

To copy the files onto SD card, run:

```bash
sudo cp -vr rpi4-ws/firmware/boot/start* "$SDCARD" && \
sudo cp -uv CROSSCON-Hypervisor/bin/rpi4/builtin-configs/rpi4-single-vTEE/crossconhyp.bin "$SDCARD" && \
sudo umount "$SDCARD"
```

## QEMU build

The docker image contains all the neccessary dependencies to build the QEMU
images as well (RISCV included), so all that needs to be done is following
the instructions from [the readme](../README.md).
