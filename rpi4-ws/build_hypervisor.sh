#!/bin/bash

set -e

CONFIG_REPO="$ROOT/rpi4-ws/configs"
cd "$ROOT/CROSSCON-Hypervisor"
# Check if patch is applied: https://stackoverflow.com/a/66755317
set +e
git apply --check "$ROOT/rpi4-ws/patches/0001-armv8-aborts.c-add-printk-to-aborts_data_lower.patch" 2>/dev/null
git_check_apply=$?
git apply --reverse --check "$ROOT/rpi4-ws/patches/0001-armv8-aborts.c-add-printk-to-aborts_data_lower.patch" 2>/dev/null
git_check_reverse_apply=$?
set -e

if [[ $git_check_apply -eq 0 && $git_check_reverse_apply -ne 0 ]]; then
    git apply "$ROOT/rpi4-ws/patches/0001-armv8-aborts.c-add-printk-to-aborts_data_lower.patch"
elif [[ $git_check_apply -ne 0 && $git_check_reverse_apply -ne 0 ]]; then
    echo "Can't apply patch"
    exit 1
fi
cd "$ROOT"

if [ -z "$CONFIG" ]; then
    echo "Set CONFIG variable to config you want to use e.g. 'rpi4-single-vTEE'"
    return 1
fi

make -C CROSSCON-Hypervisor/ \
    PLATFORM=rpi4 \
    CONFIG_BUILTIN=y \
    CONFIG_REPO=$CONFIG_REPO \
    CONFIG="$CONFIG" \
    OPTIMIZATIONS=0 \
        SDEES="sdSGX sdTZ" \
    CROSS_COMPILE=aarch64-none-elf- \
        clean

make -C CROSSCON-Hypervisor/ \
    PLATFORM=rpi4 \
    CONFIG_BUILTIN=y \
    CONFIG_REPO=$CONFIG_REPO \
    CONFIG="$CONFIG" \
    OPTIMIZATIONS=0 \
        SDEES="sdSGX sdTZ" \
    CROSS_COMPILE=aarch64-none-elf- \
        -j "$(nproc)"
