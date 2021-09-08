#!/bin/bash
#
set -e
BUILDER_OUTDIR=/home/builder
./common/update_kernel_version.sh
CUR_DIR=$(pwd)
BUILD_EXTRA_PATH=${BUILDER_OUTDIR}/build_extra
BSP_PATH=${BUILD_EXTRA_PATH}/bsp_cyberdog
BUILD_DEBS_PATH=${BUILD_EXTRA_PATH}/deb_builder

ATHENA_KERNEL_PATH=${CUR_DIR}/../
ATHENA_DEB_PATH=${BUILD_DEBS_PATH}/debs
KERNEL_DEB_VERSION="1.0.32" #default kernel debs version
NV_BASE_VERSION="32.5.0-20210115151051"
KERNEL_CODE_VERSION="4.9.201"
target=jetson-xavier-nx-devkit-emmc
rootfs_dev=nvme0n1p1

KSRC_DIR=${CUR_DIR}/kernel # kernel source code folder
KOUT_DIR=${BUILD_EXTRA_PATH}/okernel # kernel build output folder
CROSS_GCC_PATH=${BUILDER_OUTDIR}/l4t_gcc
CROSS_COMPILE=${CROSS_GCC_PATH}/bin/aarch64-linux-gnu-

export USER=$(whoami)
export BOARDID=3668
export FAB=100
export BOARDSKU=0001
export BOARDREV=''
export CHIPREV=2

if [ -z ${ENV_KERNEL_DEB_VERSION} ]; then
	echo "'ENV_KERNEL_DEB_VERSION' is not set, use default kernel deb version(${KERNEL_DEB_VERSION}), plz check the build script !"
else
	KERNEL_DEB_VERSION=${ENV_KERNEL_DEB_VERSION}
fi
echo "KERNEL_DEB_VERSION is ${KERNEL_DEB_VERSION} !"

if [ -z ${ENV_KERNEL_DEB_VERSION} ]; then
        echo "'ENV_KERNEL_DEB_VERSION' is not set, use default kernel deb version(${KERNEL_DEB_VERSION}), plz check the build script !"
else
        KERNEL_DEB_VERSION=${ENV_KERNEL_DEB_VERSION}
fi
echo "KERNEL_DEB_VERSION is ${KERNEL_DEB_VERSION} !"
#make dobot-bootloader deb(bl+kernel+dtb partitions)++++++++++++++++++++++++
echo "make bl update payload...."
cd ${BSP_PATH}
./build_l4t_bup.sh ${target} ${rootfs_dev}
${BSP_PATH}/tools/Debian/nvdebrepack.sh -i ${BSP_PATH}/bootloader/payloads_t19x/bl_update_payload:/opt/ota_package/t19x/bl_update_payload \
                -i ${BSP_PATH}/bootloader/payloads_t19x/bl_only_payload:/opt/ota_package/t19x/bl_only_payload \
                -n "Qiu Wenguang <qiuwenguang@xiaomi.com>" \
                -v ${KERNEL_DEB_VERSION} \
                ${BSP_PATH}/bootloader/dobot-bootloader_*.deb
cp ${BSP_PATH}/tools/Debian/dobot-bootloader_*.deb ${ATHENA_DEB_PATH}/
echo "done!"

#make dobot-bootloader deb(bl+kernel+dtb partitions)++++++++++++++++++++++++

########################################################################################################################################

rm -rf ${ATHENA_DEB_PATH}/dobot_kernel_modules_deb
rm -rf ${ATHENA_DEB_PATH}/dobot_kernel_headers_deb
#make dobot-kernel-modules deb++++++++++++++++++++++++
echo "Prepare to make dobot-kernel-modules deb based on dobot-kernel_*.deb..."
find ${BSP_PATH}/kernel/ -name "dobot-kernel-modules_*.deb" -exec cp {} ${ATHENA_DEB_PATH}/ \;
mkdir -p ${ATHENA_DEB_PATH}/dobot_kernel_modules_deb/src/DEBIAN
dpkg -X ${ATHENA_DEB_PATH}/dobot-kernel-modules_*.deb ${ATHENA_DEB_PATH}/dobot_kernel_modules_deb/src
dpkg -e ${ATHENA_DEB_PATH}/dobot-kernel-modules_*.deb ${ATHENA_DEB_PATH}/dobot_kernel_modules_deb/src/DEBIAN
sed -i 's/Package: .*/Package: dobot-kernel-modules/' ${ATHENA_DEB_PATH}/dobot_kernel_modules_deb/src/DEBIAN/control
rm -f ${ATHENA_DEB_PATH}/dobot-kernel-modules_*.deb

#delete kernel only payload and /boot/Image, because kernel is included in dobot-bootloader
rm -rf ${ATHENA_DEB_PATH}/dobot_kernel_modules_deb/src/opt
rm -rf ${ATHENA_DEB_PATH}/dobot_kernel_modules_deb/src/boot

#delete old ko files and modules files
rm -rf ${ATHENA_DEB_PATH}/dobot_kernel_modules_deb/src/lib/modules/4.9.201-tegra/kernel/*
rm -rf ${ATHENA_DEB_PATH}/dobot_kernel_modules_deb/src/lib/modules/4.9.201-tegra/modules.*

#make a temporary fake deb !!!
dpkg -b ${ATHENA_DEB_PATH}/dobot_kernel_modules_deb/src/ ${ATHENA_DEB_PATH}

#collect .ko files
cd $KOUT_DIR
find ./ -regex ".*\.ko" | xargs -i cp --parents -rf {} ${ATHENA_DEB_PATH}/dobot_kernel_modules_deb/src/lib/modules/4.9.201-tegra/kernel/
ls ./ |grep "modules." | xargs -i cp -f {} ${ATHENA_DEB_PATH}/dobot_kernel_modules_deb/src/lib/modules/4.9.201-tegra/

#remove debug info to shrink the size
echo "remove debug info of ko files to shrink the size~"
find ${ATHENA_DEB_PATH}/dobot_kernel_modules_deb/src/lib/modules/4.9.201-tegra/kernel/ -regex ".*\.ko" | xargs -i ${CROSS_COMPILE}strip --strip-debug {}

#make dobot-kernel-modules deb--------------------------

########################################################################################################################################

#make dobot-kernel-headers deb++++++++++++++++++++++++
echo "Prepare to make dobot-kernel-headers deb..."
find ${BSP_PATH}/kernel/ -name "dobot-kernel-headers_*.deb" -exec cp {} ${ATHENA_DEB_PATH}/ \;
mkdir -p ${ATHENA_DEB_PATH}/dobot_kernel_headers_deb/src/DEBIAN
dpkg -X ${ATHENA_DEB_PATH}/dobot-kernel-headers_*.deb ${ATHENA_DEB_PATH}/dobot_kernel_headers_deb/src
dpkg -e ${ATHENA_DEB_PATH}/dobot-kernel-headers_*.deb ${ATHENA_DEB_PATH}/dobot_kernel_headers_deb/src/DEBIAN
sed -i 's/doboot/dobot/' ${ATHENA_DEB_PATH}/dobot_kernel_headers_deb/src/DEBIAN/control
sed -i 's/tegra-//' ${ATHENA_DEB_PATH}/dobot_kernel_headers_deb/src/DEBIAN/control
rm -f ${ATHENA_DEB_PATH}/dobot-kernel-headers_*.deb

#delete old header files files
rm -rf ${ATHENA_DEB_PATH}/dobot_kernel_headers_deb/src/usr/src/linux-headers-4.9.201-tegra-ubuntu18.04_aarch64/*

#make a temporary fake deb !!!
dpkg -b ${ATHENA_DEB_PATH}/dobot_kernel_headers_deb/src/ ${ATHENA_DEB_PATH}

WORK_DIR=${ATHENA_DEB_PATH}/dobot_kernel_headers_deb/src/usr/src/linux-headers-4.9.201-tegra-ubuntu18.04_aarch64 # target folder

cd $KSRC_DIR
find ./kernel-4.9 -regex ".*Makefile.*\|.*Kconfig.*\|.*Kbuild.*\|.*\.bc\|.*\.lds\|.*\.pl\|.*\.sh" | xargs -i cp --parents -rf {} $WORK_DIR
cp --parents -rf ./kernel-4.9/arch/arm/include ./kernel-4.9/arch/arm64/include ./kernel-4.9/scripts ./kernel-4.9/security/selinux/include ./kernel-4.9/include ./nvgpu/include ./nvidia/include $WORK_DIR

cd $KOUT_DIR
cp -f .config $WORK_DIR/kernel-4.9/
cp -f kernel/bounds.s $WORK_DIR/kernel-4.9/kernel/
cp -f arch/arm64/kernel/asm-offsets.s $WORK_DIR/kernel-4.9/arch/arm64/kernel/
cp -f Module.symvers $WORK_DIR/kernel-4.9/
cp -rf ./include/* $WORK_DIR/kernel-4.9/include
cp -rf ./arch/arm64/include/generated $WORK_DIR/kernel-4.9/arch/arm64/include/
cd ${CUR_DIR}
#make dobot-kernel-headers deb--------------------------


echo "==========Re-pack dobot-kernel-headers and dobot-kernel-modules !=========="
# delete "	-d "dobot-bootloader=${NV_BASE_VERSION}+${KERNEL_DEB_VERSION}" "
${BSP_PATH}/tools/Debian/nvdebrepack.sh \
	-D ${ATHENA_DEB_PATH}/dobot_kernel_modules_deb/src/lib/modules/4.9.201-tegra:/lib/modules/4.9.201-tegra \
	-n "Qiu Wenguang <qiuwenguang@xiaomi.com>" \
	-v ${KERNEL_DEB_VERSION} \
	${ATHENA_DEB_PATH}/dobot-kernel-modules_*.deb

${BSP_PATH}/tools/Debian/nvdebrepack.sh \
	-D ${ATHENA_DEB_PATH}/dobot_kernel_headers_deb/src/usr/src/linux-headers-4.9.201-tegra-ubuntu18.04_aarch64:/usr/src/linux-headers-4.9.201-tegra-ubuntu18.04_aarch64 \
	-n "Qiu Wenguang <qiuwenguang@xiaomi.com>" \
	-v ${KERNEL_DEB_VERSION} \
	${ATHENA_DEB_PATH}/dobot-kernel-headers_*.deb

#delete fake debs
rm -f ${ATHENA_DEB_PATH}/dobot-kernel-headers_${KERNEL_CODE_VERSION}-${NV_BASE_VERSION}_arm64.deb
rm -f ${ATHENA_DEB_PATH}/dobot-kernel-modules_${KERNEL_CODE_VERSION}-${NV_BASE_VERSION}_arm64.deb

cp ${BSP_PATH}/tools/Debian/dobot-kernel-headers_*.deb ${ATHENA_DEB_PATH}/
cp ${BSP_PATH}/tools/Debian/dobot-kernel-modules_*.deb ${ATHENA_DEB_PATH}/

echo "Make dobot-kernel-modules, dobot-kernel-headers done !"
