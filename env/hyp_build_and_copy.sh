#!/bin/bash

set -e

[ -z "${DEV_PATH}" ] && echo "export DEV_PATH pointing to the SD card partition device to be flashed (e.g. /dev/mmcblk0p1)" && exit 1

sudo mkdir -p /media/root/boot
sudo mount "${DEV_PATH}" /media/root/boot

sleep 2

SDCARD=/media/root/boot

sudo cp -vr rpi4-ws/firmware/boot/* $SDCARD
sudo cp -v rpi4-ws/config.txt $SDCARD
sudo cp -v rpi4-ws/bin/bl31.bin $SDCARD
sudo cp -v rpi4-ws/bin/u-boot.bin $SDCARD
sudo cp -v lloader/linux-rpi4.bin $SDCARD

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

sudo cp -vr rpi4-ws/firmware/boot/start* "$SDCARD"
sudo cp -uv CROSSCON-Hypervisor/bin/rpi4/builtin-configs/rpi4-single-vTEE/crossconhyp.bin "$SDCARD"
sudo sync
sudo umount "$SDCARD"

echo Done!

