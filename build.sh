#!/bin/bash

#
# setup environment
# edit CC to match your toolchain path if you're not working inside the CM/AOSP built tree
#
CC="../../../prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.6/bin/arm-linux-androideabi-"
J=`cat /proc/cpuinfo | grep "^processor" | wc -l`
WORK=`pwd`

#
# no CC?!? GTFO!
#
if [ ! -e "$CC"gcc ]; then
	echo You must have a valid cross compiler in your path!
	exit 1
fi

#
# cleanup
#
make clean mrproper
rm -f ramdisk/*.img

#
# setup android initramfs
#
cd ramdisk/root
find . -print | cpio -o -H crc | gzip -9n > ../ramdisk.img

#
# setup recovery initramfs
#
cd ../recovery
find . -print | cpio -o -H crc | gzip -9n > ../ramdisk-recovery.img
cd $WORK

#
# setup config
#
make -j $J ARCH=arm CROSS_COMPILE=$CC cyanogenmod_fascinatemtd_defconfig
sed -i "s/source\/usr\/fascinatemtd_initramfs.list/usr\/fascinatemtd_standalone_initramfs.list/" .config

#
# compile
#
make -j $J ARCH=arm CROSS_COMPILE=$CC zImage
make -j $J ARCH=arm CROSS_COMPILE=$CC modules

#
# package
#
#TODO
