#!/bin/zsh

CROSS_GCC_PATH=$HOME/buildtool/l4t_gcc
cur_dir=$(pwd)

if [ -d "${CROSS_GCC_PATH}" ]; then
	echo "--ENV : cross gccis exist, env is ok"
else
	echo "--ENV : cross gcc not exist ; now download cross tools";
	git clone git@git.n.xiaomi.com:mirp/l4t_gcc.git $HOME/buildtool/l4t_gcc;
fi
#set ENV
export LOCALVERSION=-tegra
export TEGRA_KERNEL_OUT=$cur_dir/okernel
export CROSS_COMPILE=$CROSS_GCC_PATH/bin/aarch64-linux-gnu-
mkdir -p okernel
