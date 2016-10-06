#!/usr/bin/env bash
# Written by: https://gitlab.com/u/huuteml
# Website: https://daulton.ca
# Purpose: Automating the kernel emerge, eselect, compile, install, etc to save some
# effort when installing, upgrading, or trying a new kernel.

# askInitramfs()
# Function to ask the user if they also need a initramfs, if yes it will create and install the initramfs.
askInitramfs() {
	echo "Do you also need a initramfs? Y/N"
	read -r answer
	if [[ $answer == "Y" ]] || [[ $answer == "y" ]]; then
		genkernel --install initramfs
		if [ $? -gt 0 ]; then
			confUpdate "sys-kernel/genkernel-next"
			genkernel --install initramfs
		fi
	fi	
}

# confUpdate()
# if a configuration file needs to be updated during an emerge it will update it then retry the emerge
confUpdate() {
	emerge --autounmask-write -q $1
	if [ $? -eq 1 ]; then
		etc-update --automode -5
		emerge --autounmask-write -q $1
	fi
	env-update && source /etc/profile
}

control_c() {
	echo "Control-c pressed - exiting NOW"
	exit 1
}

trap control_c SIGINT

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
if [[ $answer -ge "1" ]] && [[ $answer -le "7" ]]; then
	echo
	emerge-webrsync
fi

if [[ $answer == "1" ]]; then
	confUpdate "sys-kernel/gentoo-sources"
elif [[ $answer == "2" ]]; then
	confUpdate "sys-kernel/hardened-sources"
elif [[ $answer == "3" ]]; then
	confUpdate "sys-kernel/ck-sources"
elif [[ $answer == "4" ]]; then
	confUpdate "sys-kernel/pf-sources"
elif [[ $answer == "5" ]]; then
	confUpdate "sys-kernel/vanilla-sources"
elif [[ $answer == "6" ]]; then
	confUpdate "sys-kernel/zen-sources"
elif [[ $answer == "7" ]]; then
	confUpdate "sys-kernel/git-sources"
elif [[ $answer == "skip" || $answer == "Skip" || $answer = "SKIP" ]]; then
	echo "Skipping new kernel install/update..."
else
	echo "Please choose an option between 1 to 7 or type skip."
fi

echo
echo "Listing installed kernel versions..."
eselect kernel list

echo
echo "Which kernel do you want to use? Type a number: "
read -r inputNumber
eselect kernel set "$inputNumber"

echo
echo "Do you want to copy your current kernels config to the new kernels directory? Y/N"
read -r answer
if [[ $answer == "Y" || $answer == "y" ]]; then
	echo
	echo "Do you want to search the current directory for configs named .config? Y/N"
	echo "Note: If you want this but you do not have the config there yet, use another terminal to copy it"
	read -r answer
	if [[ $answer == "Y" || $answer == "y" ]]; then
		configLocation=$(find . -maxdepth 1 -name '.config*' | tail -n 1)
		pathRemove=${configLocation##*/}
		cp "$pathRemove" /usr/src/linux/.config
		if [ $? -gt 0 ]; then
			configLocation=$(find . -maxdepth 1 -name 'config-*' | tail -n 1)
			pathRemove=${configLocation##*/}
			cp "$pathRemove" /usr/src/linux/.config
		fi
	fi
	if [ $? -gt 0 ]; then
		modprobe configs
		zcat /proc/config.gz > /usr/src/linux/.config
		if [ $? -gt 0 ]; then
			configLocation=$(find /boot/* -name 'config-*' | tail -n 1)
			cp "$configLocation" /usr/src/linux/.config
			if [ $? -gt 0 ]; then
				configLocation=$(find /usr/src/* -name '.config' | tail -n 1)
				cp "$configLocation" /usr/src/linux/.config
				if [ $? -gt 0 ]; then
					configLocation=$(find /usr/src/* -name '.config*' | tail -n 1)
					cp "$configLocation" /usr/src/linux/.config
				fi	
			fi	
		fi
	fi
fi

echo
echo "Would you like to use the package 'kergen' to detect your systems hardware? Y/N
This updates the .config for the current selected kernel with support for your
systems hardware that does not have support enabled currently."
read -r answer
if [[ $answer == "Y" ]] || [[ $answer == "y" ]]; then  
	confUpdate "sys-kernel/kergen"
	kergen -g
fi

echo
echo "Do you want to build using the regular method or Sakakis build kernel script?"
echo "1 for regular, 2 for Sakakis build kernel script, 3 for genkernel and type skip to skip this"
read -r answer
if [[ $answer == "1" ]]; then
	confUpdate "sys-kernel/genkernel-next"
	cd /usr/src/linux || echo "Error: Cannot change directory to /usr/src/linux" && exit 1
	echo "Cleaning directory..."
	make clean
	echo "Launching make menuconfig..."
	make menuconfig
	echo "Starting to build kernel.. please wait..."
	detectCores=$(cat /proc/cpuinfo | awk '/^processor/{print $3}' | tail -1)
	make -j"$detectCores"
	echo "Installing modules and the kernel..."
	make modules_install && make install
	if [ $? -eq 0 ]; then
		askInitramfs
	fi
elif [[ $answer == "2" ]]; then
	echo "Starting to build the kernel..."
	buildkernel --ask --verbose
elif [[ $answer == "3" ]]; then
	confUpdate "sys-kernel/genkernel-next"
	echo
	echo "Starting to build the kernel..."
	echo "Notice: This configuration for genkernel only makes and installs the kernel. For additional"
	echo "options you may need to manually configure the parameters for your usage case. There is an"
	echo "optional prompt at the end of the compiling to create an initramfs."
	read -p "Press any key to continue... "
	genkernel --install kernel
	askInitramfs
elif [[ $answer == "skip" || $answer == "Skip" || $answer = "SKIP" ]]; then
	echo "Skipping building the kernel..."
else
	echo "Please choose an option between 1 to 3 or type skip"
fi

echo
echo "Complete!"
echo "Notice: Remember to update your bootloader to use the new kernel"
