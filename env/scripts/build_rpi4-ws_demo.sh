#!/bin/bash

set -e

export ROOT=`pwd`

header() {
    cat <<EOF
##########
# Step $1 #
##########
EOF
}

setup() {
    header S
    cd rpi4-ws
    export RPI4_WS=`pwd`

    mkdir bin

    git clone https://github.com/raspberrypi/firmware.git --depth 1 --branch 1.20230405

    git clone https://github.com/u-boot/u-boot.git --depth 1 --branch v2022.10
    cd u-boot
    make rpi_4_defconfig
    make -j`nproc`  CROSS_COMPILE=aarch64-none-elf-
    cp -v u-boot.bin ../bin/
    cd $RPI4_WS

    git clone https://github.com/bao-project/arm-trusted-firmware.git --branch bao/demo --depth 1
    cd arm-trusted-firmware
    make PLAT=rpi4 -j`nproc`  CROSS_COMPILE=aarch64-none-elf-
    cp -v build/rpi4/release/bl31.bin ../bin/
    cd $RPI4_WS
}

step_1() {
    header 1
    cd optee_os

    OPTEE_DIR="./"
    export O="$OPTEE_DIR/optee-rpi4"
    CC="aarch64-none-elf-"
    export CFLAGS=-Wno-cast-function-type
    PLATFORM="rpi4"
    ARCH="arm"
    SHMEM_START="0x08000000"
    SHMEM_SIZE="0x00200000"
    TZDRAM_START="0x10100000"
    TZDRAM_SIZE="0x00F00000"
    CFG_GIC=n

    rm -rf $O

    make -C $OPTEE_DIR \
        O=$O \
        CROSS_COMPILE=$CC \
        PLATFORM=$PLATFORM \
        PLATFORM_FLAVOR=$PLATFORM_FLAVOR \
        ARCH=$ARCH \
        CFG_PKCS11_TA=n \
        CFG_SHMEM_START=$SHMEM_START \
        CFG_SHMEM_SIZE=$SHMEM_SIZE \
        CFG_CORE_DYN_SHM=n \
        CFG_NUM_THREADS=1 \
        CFG_CORE_RESERVED_SHM=y \
        CFG_CORE_ASYNC_NOTIF=n \
        CFG_TZDRAM_SIZE=$TZDRAM_SIZE \
        CFG_TZDRAM_START=$TZDRAM_START \
        CFG_GIC=y \
        CFG_ARM_GICV2=y \
        CFG_CORE_IRQ_IS_NATIVE_INTR=n \
        CFG_ARM64_core=y \
        CFG_USER_TA_TARGETS=ta_arm64 \
        CFG_DT=n \
        CFG_CORE_ASLR=n \
        CFG_CORE_WORKAROUND_SPECTRE_BP=n \
        CFG_CORE_WORKAROUND_NSITR_CACHE_PRIME=n \
        CFG_TEE_CORE_LOG_LEVEL=1 \
        DEBUG=1 -j16


    OPTEE_DIR="./"
    export O="$OPTEE_DIR/optee2-rpi4"
    SHMEM_START="0x08200000"
    TZDRAM_START="0x20100000"

    rm -rf $O

    make -C $OPTEE_DIR \
        O=$O \
        CROSS_COMPILE=$CC \
        PLATFORM=$PLATFORM \
        PLATFORM_FLAVOR=$PLATFORM_FLAVOR \
        ARCH=$ARCH \
        CFG_PKCS11_TA=n \
        CFG_SHMEM_START=$SHMEM_START \
        CFG_SHMEM_SIZE=$SHMEM_SIZE \
        CFG_CORE_DYN_SHM=n \
        CFG_CORE_RESERVED_SHM=y \
        CFG_CORE_ASYNC_NOTIF=n \
        CFG_TZDRAM_SIZE=$TZDRAM_SIZE \
        CFG_TZDRAM_START=$TZDRAM_START \
        CFG_GIC=y \
        CFG_ARM_GICV2=y \
        CFG_CORE_IRQ_IS_NATIVE_INTR=n \
        CFG_ARM64_core=y \
        CFG_USER_TA_TARGETS=ta_arm64 \
        CFG_DT=n \
        CFG_CORE_ASLR=n \
        CFG_CORE_WORKAROUND_SPECTRE_BP=n \
        CFG_CORE_WORKAROUND_NSITR_CACHE_PRIME=n \
        CFLAGS="${CFLAGS} -DOPTEE2" \
        CFG_EARLY_TA=y \
        CFG_TEE_CORE_LOG_LEVEL=1 \
        DEBUG=1 -j16


    cd $ROOT
}

step_2() {
    header 2
    if [ ! -e buildroot ]; then
        wget https://buildroot.org/downloads/buildroot-2022.11.1.tar.gz
        tar -xf buildroot-2022.11.1.tar.gz
        mv buildroot-2022.11.1 buildroot
    fi

    mkdir -p buildroot/build-aarch64

    cp support/br-aarch64.config buildroot/build-aarch64/.config

    cd buildroot

    make O=build-aarch64/ -j`nproc` ||  echo "Building buildroot failed as expected!"

    cd $ROOT
}

step_3() {
    header 3
    cd optee_client

    git checkout master
    make CROSS_COMPILE=aarch64-none-linux-gnu- WITH_TEEACL=0 O=out-aarch64
    git checkout optee2
    make CROSS_COMPILE=aarch64-none-linux-gnu- WITH_TEEACL=0 O=out2-aarch64

    cd $ROOT
}

step_4() {
    header 4
    cd optee_test

    BUILDROOT=`pwd`/../buildroot/build-aarch64/
    export CROSS_COMPILE=$BUILDROOT/host/bin/aarch64-linux-
    export HOST_CROSS_COMPILE=$BUILDROOT/host/bin/aarch64-linux-
    export TA_CROSS_COMPILE=$BUILDROOT/host/bin/aarch64-linux-
    export ARCH=aarch64
    export PLATFORM=plat-vexpress
    export PLATFORM_FLAVOR=qemu_armv8a
    export TA_DEV_KIT_DIR=`pwd`/../optee_os/optee-rpi4/export-ta_arm64
    export TEEC_EXPORT=`pwd`/../optee_client/out-aarch64/export/usr/
    export OPTEE_CLIENT_EXPORT=`pwd`/../optee_client/out-aarch64/export/usr/
    export CFG_TA_OPTEE_CORE_API_COMPAT_1_1=y
    export DESTDIR=./to_buildroot-aarch64
    export DEBUG=0
    export CFG_TEE_TA_LOG_LEVEL=0
    export CFLAGS=-O2
    export O=`pwd`/out-aarch64
    export CFG_PKCS11_TA=n

    rm -rf $O
    rm -rf to_buildroot-aarch64/
    find . -name "Makefile" -exec sed -i "s/\-lteec2$/\-lteec/g" {} +
    find . -name "Makefile" -exec sed -i "s/optee2_armtz/optee_armtz/g" {} +
    make clean
    make -j`nproc`
    make install


    export O=`pwd`/out2-aarch64
    export DESTDIR=./to_buildroot-aarch64-2
    export TA_DEV_KIT_DIR=`pwd`/../optee_os/optee2-rpi4/export-ta_arm64
    export TEEC_EXPORT=`pwd`/../optee_client/out2-aarch64/export/usr/
    export OPTEE_CLIENT_EXPORT=`pwd`/../optee_client/out2-aarch64/export/usr/
    rm -rf `pwd`/out2-aarch64
    find . -name "Makefile" -exec sed -i "s/\-lteec$/\-lteec2/g" {} +
    find . -name "Makefile" -exec sed -i "s/optee_armtz/optee2_armtz/g" {} +
    make clean
    make -j`nproc`
    make install
    find . -name "Makefile" -exec sed -i "s/\-lteec2$/\-lteec/g" {} +
    find . -name "Makefile" -exec sed -i "s/optee2_armtz/optee_armtz/g" {} +

    mv $DESTDIR/bin/xtest $DESTDIR/bin/xtest2
    cd $ROOT
}

step_5() {
    header 5
    cd bitcoin-wallet

    BUILDROOT=`pwd`/../buildroot/build-aarch64/

    export CROSS_COMPILE=$BUILDROOT/host/bin/aarch64-linux-
    export HOST_CROSS_COMPILE=$BUILDROOT/host/bin/aarch64-linux-
    export TA_CROSS_COMPILE=$BUILDROOT/host/bin/aarch64-linux-
    export ARCH=aarch64
    export PLATFORM=plat-virt
    export TA_DEV_KIT_DIR=`pwd`/../optee_os/optee-rpi4/export-ta_arm64
    export TEEC_EXPORT=`pwd`/../optee_client/out-aarch64/export/usr/
    export OPTEE_CLIENT_EXPORT=`pwd`/../optee_client/out-aarch64/export/usr/
    export CFG_TA_OPTEE_CORE_API_COMPAT_1_1=n
    export DESTDIR=./to_buildroot-aarch64
    export DEBUG=0
    export CFG_TEE_TA_LOG_LEVEL=0
    export O=`pwd`/out-aarch64

    rm -rf out-aarch64/
    ## make sure we have things setup for first OP-TEE
    find . -name "Makefile" -exec sed -i "s/\-lteec2$/\-lteec/g" {} +
    find . -name "Makefile" -exec sed -i "s/optee2_armtz/optee_armtz/g" {} +
    make clean
    make -j`nproc`

    mkdir -p to_buildroot-aarch64/lib/optee_armtz
    mkdir -p to_buildroot-aarch64/bin

    cp out-aarch64/*.ta to_buildroot-aarch64/lib/optee_armtz
    cp host/wallet to_buildroot-aarch64/bin/bitcoin_wallet_ca
    chmod +x to_buildroot-aarch64/bin/bitcoin_wallet_ca

    ## setup second OP-TEE
    export O=`pwd`/out2-aarch64
    export DESTDIR=./to_buildroot-aarch64-2
    export TA_DEV_KIT_DIR=`pwd`/../optee_os/optee2-rpi4/export-ta_arm64
    export TEEC_EXPORT=`pwd`/../optee_client/out2-aarch64/export/usr/
    export OPTEE_CLIENT_EXPORT=`pwd`/../optee_client/out2-aarch64/export/usr/
    rm -rf `pwd`/out2-aarch64
    find . -name "Makefile" -exec sed -i "s/\-lteec/\-lteec2/g" {} +
    find . -name "Makefile" -exec sed -i "s/optee_armtz/optee2_armtz/g" {} +
    make clean
    make -j`nproc`
    ## undo changes
    find . -name "Makefile" -exec sed -i "s/\-lteec2/\-lteec/g" {} +
    find . -name "Makefile" -exec sed -i "s/optee2_armtz/optee_armtz/g" {} +

    mkdir -p to_buildroot-aarch64-2/lib/optee2_armtz
    mkdir -p to_buildroot-aarch64-2/bin

    cp out-aarch64/*.ta to_buildroot-aarch64-2/lib/optee2_armtz
    cp host/wallet to_buildroot-aarch64-2/bin/bitcoin_wallet_ca2
    chmod +x to_buildroot-aarch64-2/bin/bitcoin_wallet_ca2


    cd $ROOT
}

step_6() {
    header 6
    cd malicous_ta
    BUILDROOT=`pwd`/../buildroot/build-aarch64/
    export CROSS_COMPILE=$BUILDROOT/host/bin/aarch64-linux-
    export HOST_CROSS_COMPILE=$BUILDROOT/host/bin/aarch64-linux-
    export TA_CROSS_COMPILE=$BUILDROOT/host/bin/aarch64-linux-
    export ARCH=aarch64
    export PLATFORM=plat-virt
    export TA_DEV_KIT_DIR=`pwd`/../optee_os/optee-rpi4/export-ta_arm64
    export TEEC_EXPORT=`pwd`/../optee_client/out-aarch64/export/usr/
    export OPTEE_CLIENT_EXPORT=`pwd`/../optee_client/out-aarch64/export/usr/
    export CFG_TA_OPTEE_CORE_API_COMPAT_1_1=n
    export DESTDIR=./to_buildroot-aarch64
    export DEBUG=0
    export CFG_TEE_TA_LOG_LEVEL=2
    export O=`pwd`/out-aarch64
    export aarch64_TARGET=y
    rm -rf out-aarch64/
    ## make sure we have things setup for first OP-TEE
    find . -name "Makefile" -exec sed -i "s/\-lteec2$/\-lteec/g" {} +
    find . -name "Makefile" -exec sed -i "s/optee2_armtz/optee_armtz/g" {} +
    make clean
    make -j`nproc`
    if [ $? -ne 0 ]; then
        echo "Failed to compile malicious TA for first optee!"
        exit 1
    fi
    mkdir -p to_buildroot-aarch64/lib/optee_armtz
    mkdir -p to_buildroot-aarch64/bin
    cp out-aarch64/*.ta to_buildroot-aarch64/lib/optee_armtz
    cp host/malicious_ca to_buildroot-aarch64/bin/malicious_ca
    chmod +x to_buildroot-aarch64/bin/malicious_ca
    ## setup second OP-TEE
    export O=`pwd`/out2-aarch64
    export DESTDIR=./to_buildroot-aarch64-2
    export TA_DEV_KIT_DIR=`pwd`/../optee_os/optee2-rpi4/export-ta_arm64
    export TEEC_EXPORT=`pwd`/../optee_client/out2-aarch64/export/usr/
    export OPTEE_CLIENT_EXPORT=`pwd`/../optee_client/out2-aarch64/export/usr/
    rm -rf `pwd`/out2-aarch64
    find . -name "Makefile" -exec sed -i "s/\-lteec/\-lteec2/g" {} +
    find . -name "Makefile" -exec sed -i "s/optee_armtz/optee2_armtz/g" {} +
    make clean
    make -j`nproc`
    ## undo changes
    find . -name "Makefile" -exec sed -i "s/\-lteec2/\-lteec/g" {} +
    find . -name "Makefile" -exec sed -i "s/optee2_armtz/optee_armtz/g" {} +
    mkdir -p to_buildroot-aarch64-2/lib/optee2_armtz
    mkdir -p to_buildroot-aarch64-2/bin
    cp out2-aarch64/*.ta to_buildroot-aarch64-2/lib/optee2_armtz
    cp host/malicious_ca to_buildroot-aarch64-2/bin/malicious_ca2
    chmod +x to_buildroot-aarch64-2/bin/malicious_ca2
    cd $ROOT
}

step_7() {
    header 7
    cd buildroot

    make O=build-aarch64/ -j`nproc`

    cd $ROOT
}

step_8() {
    header 8
    mkdir linux/build-aarch64/
    cp support/linux-aarch64.config linux/build-aarch64/.config

    cd linux

    make ARCH=arm64 O=build-aarch64 CROSS_COMPILE=`realpath ../buildroot/build-aarch64/host/bin/aarch64-linux-` -j16 Image dtbs

    cd $ROOT
}

step_9() {
    header 9
    dtc -I dts -O dtb rpi4-ws/rpi4.dts > rpi4-ws/rpi4.dtb
        cd lloader

    rm -f linux-rpi4.bin
    rm -f linux-rpi4.elf
    make  \
        IMAGE=../linux/build-aarch64/arch/arm64/boot/Image \
        DTB=../rpi4-ws/rpi4.dtb \
        TARGET=linux-rpi4.bin \
        CROSS_COMPILE=aarch64-none-elf- \
        ARCH=aarch64

    cd $ROOT
}

setup
step_1
step_2
step_3
step_4
step_5
step_6
step_7
step_8
step_9

echo "Done!"
