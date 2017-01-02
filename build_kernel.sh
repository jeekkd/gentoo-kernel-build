#!/usr/bin/env bash
# Written by: 	Daulton
# Website: 		https://daulton.ca
# Repository:	https://github.com/jeekkd
#
# Purpopse: Automating the kernel emerge, eselect, compile, configuration copying and detection, 
# hardware detection install, etc along with grub configuration updating to save some effort when 
# installing, upgrading, or trying a new kernel.

# askInitramfs()
# Function to ask the user if they also need a initramfs, if yes it will create and install the initramfs.
askInitramfs() {
	echo
	echo "Do you also need a initramfs? Y/N"
	read -r initramfsAnswer
	if [[ $initramfsAnswer == "Y" ]] || [[ $initramfsAnswer == "y" ]]; then
		echo "Standard genkernel initramfs (Press 1)"
		echo "Genkernel initramfs with support for luks, lvm, busybox (Press 2)"
		echo "Generic host-only dracut initramfs (Press 3)"
		read -r initramfsType
		if [[ $initramfsType == "1" ]]; then
			isInstalled "sys-kernel/genkernel-next"
			genkernel --install initramfs
			if [ $? -gt 0 ]; then
				genkernel --install initramfs
			fi
		elif [[ $initramfsType == "2" ]]; then
			isInstalled "sys-kernel/genkernel-next"
			genkernel --luks --lvm --busybox initramfs
			if [ $? -gt 0 ]; then
				genkernel --luks --lvm --busybox initramfs
			fi
		elif [[ $initramfsType == "2" ]]; then
			mkdir -p /etc/portage/package.keywords/
			echo "sys-kernel/dracut" >> /etc/portage/package.keywords/dracut
			isInstalled "sys-kernel/dracut"
			dracut --hostonly '' "$currentKernel"
		else
			echo "Error: Select an option that is the numeric value of 1 to 3"
			exit 1
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

# isInstalled
# If given a valid package atom it will check if the package is installed on the local system
# Example: isInstalled "sys-kernel/genkernel-next" 
# If the package is not installed it will call confUpdate and install the package
isInstalled() {
	package=$1
    packageTest=$(equery -q list "$package")
    if [[ -z ${packageTest} ]]; then
		confUpdate "$package"
    fi
}


# control_c()
# Trap Ctrl-C for a quick exit when necessary
control_c() {
	echo "Control-c pressed - exiting NOW"
	exit 1
}

# unmaskKernel() 
# Unmask the users selected kernel so unstable versions may be installed
unmaskKernel() {
	if [[ $unmaskAnswer == "Y" ]] || [[ $unmaskAnswer == "y" ]]; then
		kernelName=$(echo "$1" | cut -f 2 -d "/")	
		mkdir -p /etc/portage/package.keywords/
		echo "$1" > /etc/portage/package.keywords/"$kernelName"
	fi
}

trap control_c SIGINT

echo "Select the kernel you'd like to install/update: "
echo
echo "1. gentoo-sources"
echo "2. hardened-sources"
echo "3. ck-sources"
echo "4. pf-sources"
echo "5. vanilla-sources"
echo "6. zen-sources"
echo "7. git-sources"
echo "8. aufs-sources"
echo "9. rt-sources"
echo "10. tuxonice-sources"
echo "11. Skip this selection"
read -r answer
if [[ $answer -ge "1" ]] && [[ $answer -le "10" ]]; then
	echo
	emerge --sync
	echo
	echo "Would you like to unmask testing version of the selected kernel? Y/N"
	read -r unmaskAnswer
fi

if [[ $answer == "1" ]]; then
	unmaskKernel "sys-kernel/gentoo-sources"
	confUpdate "sys-kernel/gentoo-sources"
elif [[ $answer == "2" ]]; then
	unmaskKernel "sys-kernel/hardened-sources"
	confUpdate "sys-kernel/hardened-sources"
elif [[ $answer == "3" ]]; then
	unmaskKernel "sys-kernel/ck-sources"
	confUpdate "sys-kernel/ck-sources"
elif [[ $answer == "4" ]]; then
	unmaskKernel "sys-kernel/pf-sources"
	confUpdate "sys-kernel/pf-sources"
elif [[ $answer == "5" ]]; then
	unmaskKernel "sys-kernel/vanilla-sources"
	confUpdate "sys-kernel/vanilla-sources"
elif [[ $answer == "6" ]]; then
	unmaskKernel "sys-kernel/zen-sources"
	confUpdate "sys-kernel/zen-sources"
elif [[ $answer == "7" ]]; then
	unmaskKernel "sys-kernel/git-sources"
	confUpdate "sys-kernel/git-sources"
elif [[ $answer == "8" ]]; then
	unmaskKernel "sys-kernel/aufs-sources"
	confUpdate "sys-kernel/aufs-sources"
elif [[ $answer == "9" ]]; then
	unmaskKernel "sys-kernel/rt-sources"
	confUpdate "sys-kernel/rt-sources"
elif [[ $answer == "10" ]]; then
	unmaskKernel "sys-kernel/tuxonice-sources"
	confUpdate "sys-kernel/tuxonice-sources"
elif [[ $answer == "11" ]]; then
	echo "Skipping kernel installation/update..."
else
	echo "Error: please choose an option between 1 to 11."
	exit 1
fi

echo
echo "Listing installed kernel versions..."
eselect kernel list

for (( ; ; )); do
	echo
	echo "Which kernel do you want to use? Type a number: "
	read -r inputNumber
	eselect kernel set "$inputNumber"
	if [ $? -eq 250 ]; then
		echo
		echo "Error: There was no input, re-prompting"
	else
		break
	fi
done

echo
echo "Installing gentoolkit is necessary if hardware detection and/or genkernel kernel build
options are used. Install? Y/N"
read -r gentoolkitAnswer
if [[ $gentoolkitAnswer == "Y" ]] || [[ $gentoolkitAnswer == "y" ]]; then
	confUpdate "app-portage/gentoolkit"
fi

currentKernel=$(eselect kernel list | awk '/*/{print $3}')
if [[ $currentKernel == "*" ]]; then 
	currentKernel=$(eselect kernel list | awk '/*/{print $2}')
fi

for (( ; ; )); do
	echo
	echo "Press 1 - Do you want to search the current directory for configs named .config?"
	echo "Press 2 - Do you want to copy your running kernel config to the new kernel directory?"
	echo "Press 3 - To skip this part."
	echo
	echo "Tip: If you want option 2 but you do not have the config there yet, use another terminal to copy it"
	read -r configAnswer
	if [[ $configAnswer == "1" ]]; then
		configLocation=$(find . -maxdepth 1 -name '.config*' | tail -n 1)
		pathRemove=${configLocation##*/}
		cp "$pathRemove" /usr/src/"$currentKernel"/.config
		if [ $? -gt 0 ]; then
			configLocation=$(find . -maxdepth 1 -name 'config-*' | tail -n 1)
			pathRemove=${configLocation##*/}
			cp "$pathRemove" /usr/src/"$currentKernel"/.config
		fi
	elif [[ $configAnswer == "2" ]]; then
		modprobe configs
		zcat /proc/config.gz > /usr/src/"$currentKernel"/.config
		if [ $? -gt 0 ]; then
			configLocation=$(find /boot/* -name 'config-*' | tail -n 1)
			cp "$configLocation" /usr/src/"$currentKernel"/.config
			if [ $? -gt 0 ]; then
				configLocation=$(find /usr/src/* -name '.config' | tail -n 1)
				cp "$configLocation" /usr/src/"$currentKernel"/.config
				if [ $? -gt 0 ]; then
					configLocation=$(find /usr/src/* -name '.config*' | tail -n 1)
					cp "$configLocation" /usr/src/"$currentKernel"/.config
				fi	
			fi	
		fi
	elif [[ $configAnswer == "3" ]]; then
		echo "Skipping copying previous kernel configuration or a custom one..."
	else 
		echo "Error: Select an option that is the number 1 to 2 or skip"
		exit 1
	fi
	
	if [ ! -f /usr/src/"$currentKernel"/.config ]; then
		echo
		echo "Warning: .config at /usr/src/$currentKernel does not exist - try again or press 3 to skip."
	else
		break
	fi
done

echo
echo "Would you like to use the package 'kergen' to detect your systems hardware? Y/N
This updates the .config for the current selected kernel with support for your
systems hardware that does not have support enabled currently."
read -r answer
if [[ $answer == "Y" ]] || [[ $answer == "y" ]]; then
	if [ ! -f /etc/portage/package.use/sys-kernel_kergen~ ]; then
		echo "sys-kernel/kergen" > /etc/portage/package.keywords/kergen
	fi
	isInstalled "sys-kernel/kergen"
	kergen -g
fi

echo
echo "Press 1 - Compiling using the regular method
Press 2 - Sakakis build kernel script
Press 3 - genkernel
Press 4 - To skip this part."
read -r answer
if [[ $answer == "1" ]]; then
	echo
	echo "Press 1 to use menuconfig."
	echo "Press 2 to use gconfig."
	echo "Press 3 to skip this and go straight to compiling."
	read -r answer
	echo
	coreTotal=$(cat /proc/cpuinfo | awk '/^processor/{print $3}' | tail -1)
	coreCount=$((coreTotal + 1))
	echo "How many CPU cores would you like to compile with? You have: $coreCount available"
	read -r coreCount
	coreCount=$((coreCount + 1))
	
	cd /usr/src/"$currentKernel"/
	correctDir=/usr/src/"$currentKernel"/
	presentDir=$(pwd)
	if [[ $presentDir != $correctDir ]]; then  
		currentKernel=$(eselect kernel list | awk '/*/{print $3}')
		if [[ $currentKernel == "*" ]]; then 
			currentKernel=$(eselect kernel list | awk '/*/{print $2}')
			cd /usr/src/"$currentKernel"
			if [ $? -gt 0 ]; then
				echo "Error: cannot change directory to /usr/src/$currentKernel - exiting"
				exit 1
			fi
		fi
	fi
	
	echo
	if [[ $answer == "1" ]]; then  
		echo "Launching make menuconfig..."
		make menuconfig
	elif [[ $answer == "2" ]]; then  
		echo "Launching make gconfig..."
		make gconfig
	elif [[ $answer == "3" ]]; then  
		echo "Skipping launching a kernel configuration menu, going straight to compiling..."
	else
		echo "Error: Please enter the numbers 1 to 3 as your input. Anything else is an invalid option."
		exit 1
	fi
	echo
	echo "Cleaning directory..."
	make clean
	echo
	echo "Starting to build kernel.. please wait..."
	make -j "$coreCount"
	if [ $? -eq 0 ]; then
		echo
		echo "Installing modules and the kernel..."
		make modules_install
		make install
		if [ $? -eq 0 ]; then
			askInitramfs
		fi
	fi
elif [[ $answer == "2" ]]; then
	echo "Starting to build the kernel..."
	buildkernel --ask --verbose
elif [[ $answer == "3" ]]; then
	currentKernel=$(eselect kernel list | awk '/*/{print $3}')
	isInstalled "sys-kernel/genkernel-next"
	echo
	echo "Starting to build the kernel..."
	echo "Notice: This configuration for genkernel only makes and installs the kernel. For additional"
	echo "options you may need to manually configure the parameters for your usage case. There is an"
	echo "optional prompt at the end of the compiling to create an initramfs."
	read -p "Press any key to continue... "
	echo
	echo "Press 1 to use menuconfig."
	echo "Press 2 to use gconfig."
	echo "Press 3 to skip this and go straight to compiling."
	read -r answer
	echo
	coreTotal=$(cat /proc/cpuinfo | awk '/^processor/{print $3}' | tail -1)
	coreCount=$((coreTotal + 1))
	echo "How many CPU cores would you like to compile with? You have: $coreCount available"
	read -r coreCount
	coreCount=$((coreCount + 1))
	echo
	if [ ! -f /usr/src/"$currentKernel"/.config ]; then
		echo "Error: .config at /usr/src/$currentKernel doesn't exist"
		echo "Continue (press 1) or use generic configuration provided by genkernel (press 2)?"
		read -r selectionAnswer
		if [[ $selectionAnswer == "1" ]]; then  
			echo "Continuing.."
		elif [[ $selectionAnswer == "2" ]]; then  
			genkernel --clean --install all
		else
			echo "Error: Invalid selection entered, please enter the numbers 1 or 2 - exiting"
			exit 1
		fi
	fi
	echo
	if [[ $answer == "1" ]]; then  
		genkernel --install --makeopts=-j"$coreCount" --clean --no-mrproper --kernel-config=/usr/src/"$currentKernel"/.config --menuconfig kernel
		if [ $? -eq 0 ]; then
			askInitramfs
		fi
	elif [[ $answer == "2" ]]; then  
		genkernel --install --makeopts=-j"$coreCount" --clean --no-mrproper --kernel-config=/usr/src/"$currentKernel"/.config --gconfig kernel
		if [ $? -eq 0 ]; then
			askInitramfs
		fi
	elif [[ $answer == "3" ]]; then  
		genkernel --install --makeopts=-j"$coreCount" --clean --no-mrproper --kernel-config=/usr/src/"$currentKernel"/.config kernel
		if [ $? -eq 0 ]; then
			askInitramfs
		fi
	else
		echo "Error: Please enter the numbers 1 to 3 as your input. Anything else is an invalid option."
		exit 1
	fi
elif [[ $answer == "4" ]]; then
	echo "Skipping building the kernel..."
else
	echo "Please choose an option between 1 to 4. Anything else is an invalid option."
	exit 1
fi

echo
echo "Would you like to update your grub.cfg? Y/N"
read -r updateGrub
if [[ $updateGrub == "Y" || $updateGrub == "y" ]]; then		
	isInstalled "sys-boot/grub:2"
	isInstalled "sys-boot/os-prober"
	echo
	isBootMounted=$(mount | grep /boot)
	if [[ -z ${isBootMounted} ]]; then
		echo "Error: /boot is not mounted - mount before attempting to proceed with GRUB installation."
		exit 1
	fi
	
	if [ ! -d /boot/grub/ ]; then
		echo "Error: /boot/grub/ directory does not exist. Install grub onto main disk? Y/N"
		read -r installGrub
		if [[ $installGrub == "Y" || $installGrub == "y" ]]; then
			echo
			echo "Is this a BIOS with MBR or BIOS with GPT (press 1) or UEFI with GPT (press 2)?"
			read -r grubType
			echo
			lsblk
			echo
			if [[ $grubType == "1" ]]; then
				echo
				echo "Which disk do you want to install GRUB onto? Ex: /dev/sda"
				read -r whichDisk
				grub-install "$whichDisk"
				echo
			elif [[ $grubType == "2" ]]; then
				grub-install --efi-directory=/boot/efi
				echo
			else
				echo "Error: Enter a number that is either 1 or 2"
			fi
		else
			echo "User entered: $installGrub - cannot proceed with updating GRUB without installing"
			echo "it first."
			break
		fi
	fi
	
	if [ -f /boot/grub/grub.cfg ]; then
		rm -f /boot/grub/grub.cfg
	elif [ -f /boot/efi/EFI/GRUB/grub.cfg ]; then
		rm -f /boot/efi/EFI/GRUB/grub.cfg
	fi
	
	if [[ $grubType == "1" ]]; then
		grub-mkconfig -o /boot/grub/grub.cfg
		if [ $? -eq 0 ]; then
			# Sometimes grub saves new config with .new extension so this is assuring that an existing config is 
			# removed and the new one is renamed after installation so it can be used properly
			if [ -f /boot/grub/grub.cfg.new ]; then
				mv /boot/grub/grub.cfg.new /boot/grub/grub.cfg
			fi
		fi
		if [ ! -f /boot/grub/grub.cfg ]; then	
			echo "Error: grub.cfg does not exist - running mkconfig again to attempt to fix the issue"
			grub-mkconfig -o /boot/grub/grub.cfg
		fi
	elif [[ $grubType == "2" ]]; then
		grub-mkconfig -o /boot/efi/EFI/GRUB/grub.cfg
		if [ -f /boot/efi/EFI/GRUB/grub.cfg.new ]; then
			mv /boot/efi/EFI/GRUB/grub.cfg.new /boot/efi/EFI/GRUB/grub.cfg
		fi
		
		if [ ! -f /boot/efi/EFI/GRUB/grub.cfg ]; then	
			echo "Error: grub.cfg does not exist - running mkconfig again to attempt to fix the issue"
			grub-mkconfig -o /boot/efi/EFI/GRUB/grub.cfg
		fi
	fi
fi

echo
echo "Complete!"
