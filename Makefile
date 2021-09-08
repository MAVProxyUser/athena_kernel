.DEFAULT_GOAL := build

.PHONY: build
.PHONY: no_targets list

SHELL = /usr/bin/env bash

-include common/common.mk

#############
# Variables # 
#############
# Git
CI_BUILD_CONCURRECY ?= 40
CI_COMMIT_SHORT_SHA ?= no_sha
CI_COMMIT_REF_NAME ?= master
CI_PROJECT_DIR ?= $(shell pwd)
GIT_CLONE_COMMAND ?= git clone --recurse-submodules -j$(CI_BUILD_CONCURRECY)
GIT_BUILD_EXTRA_REPO_URL ?= https://partner-gitlab.mioffice.cn/cyberdog/build_extra.git

REPO_NAME := $(lastword $(subst /, ,$(CI_PROJECT_DIR)))
# Athena l4t_kernel_source build variables
ARCH ?= arm64
LOCALVERSION ?= -tegra
CROSS_GCC_FILE_URL ?= https://cdn.cnbj2m.fds.api.mi-img.com/cyberdog-package/build/l4t_gcc_7.3.1.tgz
CROSS_GCC_PATH ?= $(BUILDER_OUTDIR)/l4t_gcc
CROSS_COMPILE ?= $(CROSS_GCC_PATH)/bin/aarch64-linux-gnu-
TEGRA_KERNEL_OUT ?= $(BUILD_EXTRA_PATH)/okernel

export ARCH LOCALVERSION CROSS_GCC_PATH CROSS_COMPILE TEGRA_KERNEL_OUT

#################
# BUILD TARGET  #
#################
build: download-gcc download-extra touch-files build-files build-debs package-files

download-gcc:
ifeq (,$(wildcard $(CROSS_GCC_PATH)))
	curl -s ${CROSS_GCC_FILE_URL} | tar zx -C ${BUILDER_OUTDIR}/
endif

download-extra:
	@echo "[INFO] download build config module_version file" && \
		rm -f $(MODULE_VERSION_FILE) && \
		mkdir -p $(MODULE_VERSION_DIR) && \
		$(FDS_COMMAND_DOWNLOAD) $(FDS_MODULE_VERSION_PATH)/$(lastword $(subst /, ,$(MODULE_VERSION_FILE))) $(MODULE_VERSION_FILE)
	@echo "[INFO] download build_extra....." && \
		rm -rf $(BUILD_EXTRA_PATH) && \
		mkdir -p $(BUILD_EXTRA_PATH) && \
		$(GIT_CLONE_COMMAND) $(GIT_BUILD_EXTRA_REPO_URL) $(BUILD_EXTRA_PATH)

touch-files:
	mkdir -p $(TEGRA_KERNEL_OUT)/kernel/dtb

build-files:
	cd kernel/kernel-4.9 && \
		$(MAKE) ARCH=$(ARCH) O=$(TEGRA_KERNEL_OUT) tegra_defconfig && \
		$(MAKE) ARCH=$(ARCH) O=$(TEGRA_KERNEL_OUT) -j$(CI_BUILD_CONCURRECY)
build-debs:
	@echo "[INFO] Make bootloader and kernel related debs....."
	cp -f ${TEGRA_KERNEL_OUT}/arch/arm64/boot/Image ${BSP_PATH}/kernel && \
	cp -f ${TEGRA_KERNEL_OUT}/arch/arm64/boot/dts/*.dtb* ${BSP_PATH}/kernel/dtb/
	./common/make_bl_kernel_debs.sh

package-files:
	@echo "[INFO] package bl&kernel debs" && \
		cd $(ATHENA_DEB_PATH) && \
		tar czf $(ATHENA_DEB_PATH)/$(ATHENA_BUILD_BL_KERNEL_DEBS_FILE) *.deb

upload-files:
	@echo "[INFO] upload build bootloader and kernel debs" && \
		cd $(ATHENA_DEB_PATH) && \
		$(FDS_COMMAND_UPLOAD) $(ATHENA_BUILD_BL_KERNEL_DEBS_FILE) $(ATHENA_BUILD_BL_KERNEL_DEBS_FILE_PATH)/$(ATHENA_BUILD_BL_KERNEL_DEBS_FILE)

################
# Minor Targets#
################
no_targets:
list:
	@sh -c "$(MAKE) -p no_targets | awk -F':' '/^[a-zA-Z0-9][^\$$#\/\\t=]*:([^=]|$$)/ {split(\$$1,A,/ /);for(i in A)print A[i]}' | grep -v '__\$$' \
		| grep -v 'make'| grep -v 'list'| grep -v 'no_targets' |grep -v 'Makefile' | sort | uniq"
