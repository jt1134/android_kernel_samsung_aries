#!/bin/bash

#
# setup environment
# edit CC to match your toolchain path if you're not working inside the CM/AOSP built tree
#
CC="../../../prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.6/bin/arm-linux-androideabi-"
DATE=`date +%m%d`
J=`cat /proc/cpuinfo | grep "^processor" | wc -l`
WORK=`pwd`

#
# no CC?!? GTFO!
#
if [ ! -e "$CC"gcc ]; then
	echo You must have a valid cross compiler installed !
	echo
	echo Would you like to download and automatically configure your toolchain ?
	echo
	echo Type Y or N
	echo
	read answer

	if [ $answer == 'Y' ]; then
		echo This may take a while...
		echo
		cd ..
		git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.6
		echo
		cd $WORK
		sed -i "s/..\/..\/..\/prebuilts\/gcc\/linux-x86\/arm/../" $0
		CC="../arm-linux-androideabi-4.6/bin/arm-linux-androideabi-"
	else
		echo WTF is \"$answer\" supposed to mean anyways ?
		echo
		exit 1
	fi
fi

#
# cleanup
#
bash $WORK/clean
rm -f ramdisk/*.img zip/{boot.img,*.zip,system/lib/modules/*}

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
echo
if ! cp arch/arm/boot/zImage zip/boot.img ; then
	echo Sumthin done fucked up. I suggest you fix it.
	echo
	exit 1
else
	cp `find . -name *.ko` zip/system/lib/modules
	echo Creating update zip...
	echo
	cd zip && zip -r kernel_update-$DATE.zip .
fi

#
# Fin
#
echo
echo Done !
echo
