# Common makefile for global variables
# WARN: All Git Repos Must Use git@xxx Format
# Other sensitive variable ref: https://partner-gitlab.mioffice.cn/groups/cyberdog/-/settings/ci_cd

#############
# Variables # 
#############
# Git
CI_BUILD_CONCURRECY ?= 40
CI_COMMIT_SHORT_SHA ?= no_sha
CI_COMMIT_REF_NAME ?= master
CI_PROJECT_DIR ?= $(shell pwd)
GIT_CLONE_COMMAND ?= git clone --recurse-submodules -j$(CI_BUILD_CONCURRECY)
REPO_NAME := $(lastword $(subst /, ,$(CI_PROJECT_DIR)))

# Time
DATETIME ?= $(shell date "+%Y.%m.%d")

# Daily Build
#TODO replace module version control to advanced release methods, #WHEN CHANGE FILE NEED RUN!!! [ dos2unix module_version.txt ] avoid \r
BUILDER_OUTDIR=/home/builder
MODULE_VERSION_DIR=$(BUILDER_OUTDIR)/athena/config
MODULE_VERSION_FILE=$(MODULE_VERSION_DIR)/module_version.txt

BUILD_EXTRA_GIT_URL ?= https://partner-gitlab.mioffice.cn/cyberdog/build_extra.git
BUILD_EXTRA_GIT_REPO ?= $(firstword $(subst ., ,$(lastword $(subst /, ,$(BUILD_EXTRA_GIT_URL)))))
BUILD_EXTRA_PATH ?= ${BUILDER_OUTDIR}/${BUILD_EXTRA_GIT_REPO}
BSP_PATH ?= ${BUILD_EXTRA_PATH}/bsp_cyberdog
BUILD_DEBS_PATH ?= ${BUILD_EXTRA_PATH}/deb_builder
ATHENA_DEB_PATH ?= ${BUILD_DEBS_PATH}/debs

# DEB
BL_KERNEL_DEBS ?= bl_kernel_debs

# FDS   
# Other FDS sensitive variable ref: https://partner-gitlab.mioffice.cn/groups/cyberdog/-/settings/ci_cd
# Daily Build Config variables
FDS_MODULE_VERSION_PATH ?= $(FDS_URL_PREFIX)/cyberdog-tools

# Daily Build locomotion variables
FDS_LOCOMOTION_PATH ?= fds://cyberdog-package/build

# Athena cyberdog TEMP FDS build variables
# use git short sha avoid override
ATHENA_BUILD_BL_KERNEL_DEBS_FILE ?= $(BL_KERNEL_DEBS)-$(CI_COMMIT_SHORT_SHA).tgz
ATHENA_BUILD_BL_KERNEL_DEBS_FILE_PATH ?= $(FDS_URL_PREFIX)/$(REPO_NAME)/$(CI_COMMIT_REF_NAME)
