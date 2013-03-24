#!/bin/bash

#
# setup environment
# edit CC to match your toolchain path if you're not working inside the CM/AOSP built tree
#
CC="../../../prebuilts/gcc/linux-x86/arm/arm-eabi-4.6/bin/arm-eabi-"
DATE=$(date +%m%d)
J=$(cat /proc/cpuinfo | grep "^processor" | wc -l)
HOME=$(pwd)
WORK=$(dirname $0)

DIE() { exit 1; }
LOG() { printf "$@\n\n"; }
TRY() { "$@" || DIE; }
ZIP() {
	TRY cd zip;
	TRY cp ../arch/arm/boot/zImage boot.img;
	TRY cp $(find ../ -name *.ko) system/lib/modules;
	TRY zip -r kernel_update-$DATE.zip . ;
	TRY mv kernel_update-$DATE.zip $HOME
}

#
# no CC?!? GTFO!
#
if [ ! -e "$WORK/$CC"gcc ]; then
	LOG "You must have a valid cross compiler installed !"
	LOG "Would you like to download and automatically configure your toolchain ?"
	LOG "Type Y or N"
	read answer

	if [ $answer == 'Y' ]; then
		LOG "This may take a while..."
		TRY git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-eabi-4.6 $WORK/../arm-eabi-4.6
		TRY sed -i "s/..\/..\/..\/prebuilts\/gcc\/linux-x86\/arm/../g" $0
		CC="$WORK/../arm-eabi-4.6/bin/arm-eabi-"
	else
		LOG "WTF is \"$answer\" supposed to mean anyways ?"
		DIE
	fi
fi

#
# cleanup
#
TRY bash $WORK/clean

#
# setup android initramfs
#
TRY cd $WORK/ramdisk/root
TRY find . -print | cpio -o -H crc | gzip -9n > ../ramdisk.img

#
# setup recovery initramfs
#
TRY cd ../recovery
TRY find . -print | cpio -o -H crc | gzip -9n > ../ramdisk-recovery.img

#
# setup config
#
TRY cd ../..
TRY make ARCH=arm CROSS_COMPILE=$CC cyanogenmod_fascinatemtd_defconfig
TRY sed -i "s/source\/usr\/fascinatemtd_initramfs.list/usr\/fascinatemtd_standalone_initramfs.list/g" .config

#
# compile
#
TRY make -j $J ARCH=arm CROSS_COMPILE=$CC zImage
TRY make -j $J ARCH=arm CROSS_COMPILE=$CC modules

#
# package
#
if [ ! -e arch/arm/boot/zImage ]; then
	LOG "Sumthin done fucked up. I suggest you fix it."
	DIE
else
	ZIP
fi

#
# Fin
#
LOG "Done !"
