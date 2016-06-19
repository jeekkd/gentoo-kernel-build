#!/usr/bin/env bash
# Written by: https://gitlab.com/u/huuteml
# Website: https://daulton.ca
# Purpose: Automating the kernel emerge, eselect, compile, install, etc to save some
# effort when installing, upgrading, or trying a new kernel.

rbacStatus=$(gradm -S >/dev/null 2>&1)
enabledMessage="The RBAC system is currently enabled."
if [ "$(diff -q $rbacStatus $enabledMessage 2>&1)" = "" ] ; then
	echo "Grsecurity RBAC is enabled, do you need to disable it or auth to admin? YES/NO"
	read -r rbacAnswer
	if [[ $rbacAnswer == "YES" || $rbacAnswer == "yes" ]]; then
		echo "Would you like to disable it (press 1) or would you like to auth to admin (press 2)"
		read -r answer
		if [[ $answer == "1" ]]; then
			gradm -D
		elif [[ $answer == "2" ]]; then
			gradm -a admin
		elif [[ $answer == "skip" || $answer == "Skip" || $answer = "SKIP" ]]; then
			echo "Skipping..."
		else
			echo "Please choose an option between 1-2 or type skip."
		fi	
	fi
fi

echo "Select the kernel you'd like to install/update. Type skip to skip this."
echo
echo "1. gentoo-sources"
echo "2. hardened-sources"
echo "3. ck-sources"
echo "4. pf-sources"
echo "5. vanilla-sources"
echo "6. zen-sources"
echo "7. git-sources"
read -r answer
if [[ $answer == "1" ]]; then
	emerge --ask sys-kernel/gentoo-sources
elif [[ $answer == "2" ]]; then
	emerge --ask sys-kernel/hardened-sources
elif [[ $answer == "3" ]]; then
	emerge --ask sys-kernel/ck-sources
elif [[ $answer == "4" ]]; then
	emerge --ask sys-kernel/pf-sources
elif [[ $answer == "5" ]]; then
	emerge --ask sys-kernel/vanilla-sources
elif [[ $answer == "6" ]]; then
	emerge --ask sys-kernel/zen-sources
elif [[ $answer == "7" ]]; then
	emerge --ask sys-kernel/git-sources
elif [[ $answer == "skip" || $answer == "Skip" || $answer = "SKIP" ]]; then
	echo "Skipping new kernel install/update..."
else
	echo "Please choose an option between 1-7 or type skip."
fi

echo
echo "Listing installed kernel versions..."
eselect kernel list

echo
echo "Which kernel do you want to use? Type a number: "
read -r inputNumber
eselect kernel set "$inputNumber"

echo
echo "Do you want to copy your current kernels config to the new kernels directory? YES/NO"
read -r answer
if [[ $answer == "YES" || $answer == "Yes" || $answer == "yes" ]]; then
	modprobe configs
	zcat /proc/config.gz > /usr/src/linux/.config
	if [ $? -gt 0 ]; then
		configLocation=$(find /usr/src/* -name '.config' | tail -n 1)
		cp "$configLocation" /usr/src/linux/.config
		if [ $? -gt 0 ]; then
			configLocation=$(find /boot/* -name 'config-*' | tail -n 1)
			cp "$configLocation" /usr/src/linux/.config
		fi
	fi	
fi

echo
echo "Do you want to build using the regular method or Sakakis build kernel script?"
echo "1 for regular, 2 for Sakakis build kernel script, 3 for genkernel and type skip to skip this"
read -r answer
if [[ $answer == "1" ]]; then
	cd /usr/src/linux || exit
	echo "Cleaning directory..."
	make clean
	echo "Launching make menuconfig..."
	make menuconfig
	echo "Starting to build kernel.. please wait..."
	make -j 5
	echo "Installing kernel..."
	make modules_install && make install
elif [[ $answer == "2" ]]; then
	echo "Starting to build the kernel..."
	buildkernel --ask --verbose
elif [[ $answer == "3" ]]; then
	echo "Starting to build the kernel..."
	genkernel --install kernel
elif [[ $answer == "skip" || $answer == "Skip" || $answer = "SKIP" ]]; then
	echo "Skipping building the kernel..."
else
	echo "Please choose an option between 1-2 or type skip"
fi

if [[ $rbacAnswer == "YES" || $rbacAnswer == "yes" ]]; then
	gradm -D
	gradm -u admin
fi

echo "Complete!"
