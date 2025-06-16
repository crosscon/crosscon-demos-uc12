#!/bin/bash

set -e

cd "$ROOT/memory-separation"
make clean
make CROSS_COMPILE=aarch64-none-elf- CONFIG_TEXT_BASE=0x20200000

cd "$ROOT/rpi4-ws"
CONFIG=rpi4-baremetal ./build_hypervisor.sh
