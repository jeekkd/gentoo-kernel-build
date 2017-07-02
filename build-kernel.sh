#!/usr/bin/env sh
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
	while true; do
		printf "\n"
		printf "Do you also need a initramfs? Enter [y/n] \n"
		read -r initramfsAnswer
		if [ "$initramfsAnswer" = "Y" ] || [ "$initramfsAnswer" = "y" ]; then
			while true; do
				printf "Press 1 - Standard genkernel initramfs. \n"
				printf "Press 2 - Genkernel initramfs with support for luks, lvm, busybox. \n"
				printf "Press 3 - Generic host-only dracut initramfs. \n"
				printf "Press 4 - To skip this part. \n"
				read -r initramfsType
				if [ "$initramfsType" -gt "0" ] && [ "$initramfsType" -lt "5" ]; then
					printf "\n"
					break
				else
					printf "Error: Please enter the numbers 1 to 4 as your input. Anything else is an invalid option. \n"
					printf "\n"
				fi
			done
			
			if [ "$initramfsType" = "1" ]; then
				isInstalled "sys-kernel/genkernel-next"
				genkernel --install initramfs
				if [ $? -gt 0 ]; then
					genkernel --install initramfs
				fi
				break
			elif [ "$initramfsType" = "2" ]; then
				isInstalled "sys-kernel/genkernel-next"
				genkernel --luks --lvm --busybox initramfs
				if [ $? -gt 0 ]; then
					genkernel --luks --lvm --busybox initramfs
				fi
				break
			elif [ "$initramfsType" = "3" ]; then
				mkdir -p /etc/portage/package.keywords/
				printf "sys-kernel/dracut" >> /etc/portage/package.keywords/dracut
				isInstalled "sys-kernel/dracut"
				dracut --hostonly '' "$currentKernel"
				break
			elif [ "$initramfsType" = "4" ]; then
				printf "Skipping adding an initramfs.. \n"
				break
			fi
		elif [ "$initramfsAnswer" = "N" ] || [ "$initramfsAnswer" = "n" ]; then
			printf "Skipping adding an initramfs.. \n"
			break
		else
			printf "Error: Invalid selection, Enter [y/n] \n"
		fi
	done
}

# confUpdate()
# if a configuration file needs to be updated during an emerge it will update it then retry the emerge
confUpdate() {
	emerge --autounmask-write -q $@
	if [ $? -eq 1 ]; then
		etc-update --automode -5
		emerge --autounmask-write -q $@
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
    if [ -z ${packageTest} ]; then
		confUpdate "$package"
    fi
}

# unmaskKernel() 
# Unmask the users selected kernel so unstable versions may be installed
unmaskKernel() {
	if [ "$unmaskAnswer" = "Y" ] || [ "$unmaskAnswer" = "y" ]; then
		kernelName=$(printf "$1" | cut -f 2 -d "/")	
		mkdir -p /etc/portage/package.keywords/
		printf "$1\n" > /etc/portage/package.keywords/"$kernelName"
	fi
}

# ifSuccessBreak()
# If the action directly occuring before the function is called is successful, break out of
# the loop.
ifSuccessBreak() {
	if [ $? -eq 0 ]; then
		printf "\n"
		break
	fi
}

mainBanner() {
	printf "\n"
	printf "============================================================= \n"
	printf "Gentoo kernel build \n"
	printf "https://github.com/jeekkd/gentoo-kernel-build \n"
	printf "============================================================= \n"
	printf "\n"
	printf "If you run into any problems, please open an issue so it can fixed. Thanks! \n"
}

mainBanner

while true; do
	printf "\n"
	printf "Select the kernel you'd like to install/update by typing its number: \n"
	printf "\n"
	printf "1. gentoo-sources \n"
	printf "2. hardened-sources \n"
	printf "3. ck-sources \n"
	printf "4. pf-sources \n"
	printf "5. vanilla-sources \n" 
	printf "6. zen-sources \n"
	printf "7. git-sources \n"
	printf "8. aufs-sources \n"
	printf "9. rt-sources \n"
	printf "10. tuxonice-sources \n"
	printf "11. Skip this selection \n"
	printf "\n"
	read -r kernelSelection
	if [ "$kernelSelection" -ge "1" ] && [ "$kernelSelection" -le "10" ]; then
		printf "\n"
		printf "Update Portage tree? Enter [y/n] \n"
		read -r portageUpdate
		if [ "$portageUpdate" = "Y" ] || [ "$portageUpdate" = "y" ]; then
			printf "\n"
			printf "* Syncing.. Be patient this couple take a couple minutes \n"
			emerge --sync -q
		fi
		printf "\n"
		printf "Would you like to unmask testing version of the selected kernel? Enter [y/n] \n"
		read -r unmaskAnswer
	fi

	if [ "$kernelSelection" = "1" ]; then
		unmaskKernel "sys-kernel/gentoo-sources"
		confUpdate "sys-kernel/gentoo-sources"
		ifSuccessBreak
	elif [ "$kernelSelection" = "2" ]; then
		unmaskKernel "sys-kernel/hardened-sources"
		confUpdate "sys-kernel/hardened-sources"
		ifSuccessBreak
	elif [ "$kernelSelection" = "3" ]; then
		unmaskKernel "sys-kernel/ck-sources"
		confUpdate "sys-kernel/ck-sources"
		ifSuccessBreak
	elif [ "$kernelSelection" = "4" ]; then
		unmaskKernel "sys-kernel/pf-sources"
		confUpdate "sys-kernel/pf-sources"
		ifSuccessBreak
	elif [ "$kernelSelection" = "5" ]; then
		unmaskKernel "sys-kernel/vanilla-sources"
		confUpdate "sys-kernel/vanilla-sources"
		ifSuccessBreak
	elif [ "$kernelSelection" = "6" ]; then
		unmaskKernel "sys-kernel/zen-sources"
		confUpdate "sys-kernel/zen-sources"
		ifSuccessBreak
	elif [ "$kernelSelection" = "7" ]; then
		unmaskKernel "sys-kernel/git-sources"
		confUpdate "sys-kernel/git-sources"
		ifSuccessBreak
	elif [ "$kernelSelection" = "8" ]; then
		unmaskKernel "sys-kernel/aufs-sources"
		confUpdate "sys-kernel/aufs-sources"
		ifSuccessBreak
	elif [ "$kernelSelection" = "9" ]; then
		unmaskKernel "sys-kernel/rt-sources"
		confUpdate "sys-kernel/rt-sources"
		ifSuccessBreak
	elif [ "$kernelSelection" = "10" ]; then
		unmaskKernel "sys-kernel/tuxonice-sources"
		confUpdate "sys-kernel/tuxonice-sources"
		ifSuccessBreak
	elif [ "$kernelSelection" = "11" ]; then
		printf "Skipping kernel installation/update... \n"
		ifSuccessBreak
	else
		printf "Error: please choose an option between 1 to 11. \n"
	fi
done

while true; do
	printf "\n"
	printf "Listing installed kernel versions... \n"
	eselect kernel list
	printf "\n"
	printf "Which kernel do you want to use? Type a number: \n"
	read -r inputNumber
	eselect kernel set "$inputNumber"
	if [ $? -eq 250 ]; then
		printf "\n"
		printf "Error: There was no input, re-prompting \n"
	else
		break
	fi
done

while true; do
	printf "\n"
	printf "Installing gentoolkit is necessary if hardware detection, genkernel kernel build or genkernel created initramfs, options are used. Install? Y/N \n"
	read -r gentoolkitAnswer
	if [ "$gentoolkitAnswer" = "Y" ] || [ "$gentoolkitAnswer" = "y" ]; then
		confUpdate "app-portage/gentoolkit"
		ifSuccessBreak
	elif [ "$gentoolkitAnswer" = "N" ] || [ "$gentoolkitAnswer" = "n" ]; then
		printf "\n"
		printf "Skipping gentoolkit installation.. \n"
		break
	else
		printf "\n"
		printf "Error: Invalid selection, Enter [y/n] \n"
	fi
done

currentKernel=$(eselect kernel list | awk '/*/{print $3}')
if [ "$currentKernel" = "*" ]; then 
	currentKernel=$(eselect kernel list | awk '/*/{print $2}')
else
	printf "\n"
	printf "Warning: eselect kernel was unset, defaulting to first kernel.. \n"
	eselect kernel set 1
	currentKernel=$(eselect kernel list | awk '/*/{print $2}')
fi

while true; do
	printf "\n"
	printf "Press 1 - Do you want to search the current directory for configs named .config? \n"
	printf "Press 2 - Do you want to copy your running kernel config to the new kernel directory? \n"
	printf "Press 3 - Search for a kernel config. \n"
	printf "Press 4 - To skip this part. \n"
	printf "\n"
	printf "Tip: If you want option 1 but you do not have the config there yet, use another terminal to copy it \n"
	read -r configAnswer
	if [ "$configAnswer" = "1" ]; then
		configLocation=$(find . -maxdepth 1 -name '.config*' | tail -n 1)
		pathRemove=${configLocation##*/}
		cp "$pathRemove" /usr/src/"$currentKernel"/.config
		ifSuccessBreak
	elif [ "$configAnswer" = "2" ]; then
		modprobe configs
		if [ $? -gt 0 ]; then
			printf "Error: failed to probe configs kernel module, must not be enabled - try another method. \n"
		else
			break
		fi
		zcat /proc/config.gz > /usr/src/"$currentKernel"/.config
		if [ $? -gt 0 ]; then
			printf "Error: failed to copy /proc/config.gz to /usr/src/$currentKernel/.config - try another method. \n"
		else
			break
		fi
	elif [ "$configAnswer" = "3" ]; then
		configLocation=$(find /boot/ -name '*config*' | tail -n 1)
		if [ $? -gt 0 ]; then
			configLocation=$(find /usr/src/* -name '.config' | tail -n 1)
			if [ $? -gt 0 ]; then
				configLocation=$(find /usr/src/* -name '.config*' | tail -n 1)
			fi	
		fi	
		printf "\n"
		printf "Proceed with using config $configLocation? Y/N \n"
		read -r kernelConfigAnswer
		if [ $kernelConfigAnswer = "Y" ] || [ $kernelConfigAnswer = "y" ]; then
			cp "$configLocation" /usr/src/"$currentKernel"/.config
			ifSuccessBreak
		else
			printf "Try another option or manually copy a kernel config to /usr/src/$currentKernel. \n"
		fi
	elif [ "$configAnswer" = "4" ]; then
		printf "\n"
		printf "Skipping copying kernel configuration.. \n"
		break
	else 
		printf "\n"
		printf "Error: Select an option that is the number 1 to 4. \n"
	fi
	
	if [ ! -f /usr/src/"$currentKernel"/.config ]; then
		printf "\n"
		printf "Warning: .config at /usr/src/$currentKernel does not exist - try again or press 4 to skip. \n"
	fi
done

while true; do
	printf "\n"
	printf "Would you like to use the package 'kergen' to detect your systems hardware? Y/N \n"
	printf "This updates the .config for the current selected kernel with support for your systems hardware that does not have support enabled currently. \n"
	read -r kergenAnswer
	if [ "$kergenAnswer" = "Y" ] || [ "$kergenAnswer" = "y" ]; then
		if [ ! -f /etc/portage/package.use/sys-kernel_kergen~ ] && [ ! -f /etc/portage/package.keywords/kergen ]; then
			printf "sys-kernel/kergen" > /etc/portage/package.keywords/kergen
		fi
		isInstalled "sys-kernel/kergen"
		kergen -g
		break
	elif [ "$kergenAnswer" = "N" ] || [ "$kergenAnswer" = "n" ]; then
		printf "\n"
		printf "Skipping using kergen.. \n"
		break
	else
		printf "\n"
		printf "Error: Invalid selection, Enter [y/n] \n"
	fi
done

while true; do
	printf "\n"
	printf "Press 1 - Compiling using the standard, make method \n"
	printf "Press 2 - Sakakis build kernel script \n"
	printf "Press 3 - Genkernel \n"
	printf "Press 4 - To skip this part. \n"
	read -r compileMethod
	if [ "$compileMethod" -gt "0" ] && [ "$compileMethod" -lt "5" ]; then
		printf "\n"
		break
	else
		printf "Error: Please enter the numbers 1 to 4 as your input. Anything else is an invalid option. \n"
	fi
done
	
if [ "$compileMethod" = "1" ]; then
	while true; do
		printf "\n"
		printf "Press 1 to use menuconfig. \n"
		printf "Press 2 to use gconfig. \n"
		printf "Press 3 to use silentoldconfig. \n"
		printf "Press 4 to skip this and go straight to compiling. \n"
		read -r configTypeAnswer
		if [ "$configTypeAnswer" -gt "0" ] && [ "$configTypeAnswer" -lt "5" ]; then
			printf "\n"
			break
		else
			printf "Error: Please enter the numbers 1 to 4 as your input. Anything else is an invalid option. \n"
		fi
	done
	printf "\n"
	coreTotal=$(cat /proc/cpuinfo | awk '/^processor/{print $3}' | tail -1)
	coreCount=$((coreTotal + 1))
	printf "How many CPU cores would you like to compile with? You have: $coreCount available \n"
	read -r coreCount
	coreCount=$((coreCount + 1))
	
	cd /usr/src/"$currentKernel"/
	correctDir=/usr/src/"$currentKernel"/
	presentDir=$(pwd)
	if [ "$presentDir" != "$correctDir" ]; then  
		currentKernel=$(eselect kernel list | awk '/*/{print $3}')
		if [ "$currentKernel" = "*" ]; then 
			currentKernel=$(eselect kernel list | awk '/*/{print $2}')
			cd /usr/src/"$currentKernel"
			if [ $? -gt 0 ]; then
				printf "Error: cannot change directory to /usr/src/$currentKernel - exiting \n"
				exit 1
			fi
		fi
	fi
	printf "\n"
	if [ "$configTypeAnswer" = "1" ]; then  
		printf "Launching make menuconfig... \n"
		make menuconfig
	elif [ "$configTypeAnswer" = "2" ]; then  
		printf "Launching make gconfig... \n"
		make gconfig
	elif [ "$configTypeAnswer" = "3" ]; then  
		printf "Launching make silentoldconfig... \n"
		make silentoldconfig
	elif [ "$configTypeAnswer" = "4" ]; then  
		printf "Skipping launching a kernel configuration menu, going straight to compiling... \n"
	fi	
	printf "\n"
	printf "Cleaning directory... \n"
	make clean
	printf "\n"
	printf "Starting to build kernel.. please wait... \n"
	make -j "$coreCount"
	if [ $? -eq 0 ]; then
		printf "\n"
		printf "Installing modules and the kernel... \n"
		make modules_install
		make install
	fi
elif [ "$compileMethod" = "2" ]; then
	printf "Starting to build the kernel... \n"
	buildkernel --ask --verbose
elif [ "$compileMethod" = "3" ]; then
	currentKernel=$(eselect kernel list | awk '/*/{print $3}')
	if [ "$currentKernel" = "*" ]; then 
		currentKernel=$(eselect kernel list | awk '/*/{print $2}')
	fi
	isInstalled "sys-kernel/genkernel-next"
	printf "\n"
	printf "Starting to build the kernel... \n"
	printf "\n"
	while true; do
		printf "\n"
		printf "Press 1 to use menuconfig. \n"
		printf "Press 2 to use gconfig. \n"
		printf "Press 3 to skip this and go straight to compiling. \n"
		read -r configTypeAnswer
		if [ "$configTypeAnswer" -gt "0" ] && [ "$configTypeAnswer" -lt "4" ]; then
			printf "\n"
			break
		else
			printf "\n"
			printf "Error: Please enter the numbers 1 to 3 as your input. Anything else is an invalid option. \n"
		fi
	done	
	coreTotal=$(cat /proc/cpuinfo | awk '/^processor/{print $3}' | tail -1)
	coreCount=$((coreTotal + 1))
	printf "How many CPU cores would you like to compile with? You have: $coreCount available \n"
	read -r coreCount
	coreCount=$((coreCount + 1))
	printf "\n"
	if [ ! -f /usr/src/$currentKernel/.config ]; then
		while true; do
			printf "\n"
			printf "Error: .config at /usr/src/$currentKernel doesn't exist \n"
			printf "\n"
			printf "Press 1 to continue anyway \n"
			printf "Press 2 to use generic configuration provided by genkernel \n"
			read -r selectionAnswer
			if [ "$selectionAnswer" -gt "0" ] && [ "$selectionAnswer" -lt "3" ]; then
				printf "Continuing.. \n"
				printf "\n"
				selectionAnswerSet=Y
				break
			else
				printf "\n"
				printf "Error: Please enter the numbers 1 to 2 as your input. Anything else is an invalid option. \n"
			fi
		done
			
			if [ "$selectionAnswer" = "2" ]; then  
				genkernel --clean --install kernel
				printf "\n"
				while true; do
					if [ "$configTypeAnswer" = "1" ]; then  
						genkernel --install --makeopts=-j"$coreCount" --clean --no-mrproper --menuconfig kernel
						ifSuccessBreak
					elif [ "$configTypeAnswer" = "2" ]; then  
						genkernel --install --makeopts=-j"$coreCount" --clean --no-mrproper --gconfig kernel
						ifSuccessBreak
					elif [ "$configTypeAnswer" = "3" ]; then  
						genkernel --install --makeopts=-j"$coreCount" --clean --no-mrproper kernel
						ifSuccessBreak
					fi
				done
			fi
	fi
	
	printf "\n"
	while true; do
		if [ "$selectionAnswerSet" = "Y" ]; then
			printf "\n"
			break
		fi
		
		if [ "$configTypeAnswer" = "1" ]; then  
			genkernel --install --makeopts=-j"$coreCount" --clean --no-mrproper --kernel-config=/usr/src/"$currentKernel"/.config --menuconfig kernel
			ifSuccessBreak
		elif [ "$configTypeAnswer" = "2" ]; then  
			genkernel --install --makeopts=-j"$coreCount" --clean --no-mrproper --kernel-config=/usr/src/"$currentKernel"/.config --gconfig kernel
			ifSuccessBreak
		elif [ "$configTypeAnswer" = "3" ]; then  
			genkernel --install --makeopts=-j"$coreCount" --clean --no-mrproper --kernel-config=/usr/src/"$currentKernel"/.config kernel
			ifSuccessBreak
		else
			printf "Error: Please enter the numbers 1 to 3 as your input. Anything else is an invalid option. \n"
		fi
	done
elif [ "$compileMethod" = "4" ]; then
	printf "Skipping building the kernel... \n"
fi

askInitramfs

while true; do
	printf "\n"
	printf "Would you like to update your grub.cfg? Y/N \n"
	read -r updateGrub
	if [ "$updateGrub" = "Y" ] || [ "$updateGrub" = "y" ] || [ "$updateGrub" = "N" ] || [ "$updateGrub" = "n" ]; then
		printf "\n"
		break
	else
		printf "Error: Invalid selection, Enter [y/n] \n"
	fi
done

if [ "$updateGrub" = "Y" ] || [ "$updateGrub" = "y" ]; then		
	isInstalled "sys-boot/grub:2"
	isInstalled "sys-boot/os-prober"
	printf "\n"
	isBootMounted=$(mount | grep /boot)
	if [ -z "${isBootMounted}" ]; then
		printf "Warning: /boot is not mounted - mount before attempting to proceed with GRUB installation. \n"
		read -p "Press any key to continue..."
	fi
	
	if [ ! -d /boot/grub/ ]; then
		printf "\n"
		printf "Error: /boot/grub/ directory does not exist. Install grub onto main disk? Y/N \n"
		read -r installGrub
		if [ "$installGrub" = "Y" ] || [ $installGrub = "y" ]; then
			printf "\n"
			printf "Is this a BIOS with MBR or BIOS with GPT (press 1) or UEFI with GPT (press 2)? \n"
			read -r grubType
			printf "\n"
			lsblk
			printf "\n"
			if [ "$grubType" = "1" ]; then
				printf "\n"
				printf "Which disk do you want to install GRUB onto? Ex: /dev/sda \n"
				read -r whichDisk
				grub-install "$whichDisk"
				printf "\n"
			elif [ "$grubType" = "2" ]; then
				grub-install --efi-directory=/boot/efi
				printf "\n"
			else
				printf "Error: Enter a number that is either 1 or 2 \n"
			fi
		else
			printf "User entered: $installGrub - cannot proceed with updating GRUB without installing it first. \n"
			break
		fi
	fi
	
	if [ -z "${grubType}" ]; then
		printf "Is this a BIOS with MBR or BIOS with GPT (press 1) or UEFI with GPT (press 2)? \n"
		read -r grubType
	fi
	
	if [ -f /boot/grub/grub.cfg ]; then
		rm -f /boot/grub/grub.cfg
		
	elif [ -f /boot/efi/EFI/GRUB/grub.cfg ]; then
		rm -f /boot/efi/EFI/GRUB/grub.cfg
	fi
	
	if [ "$grubType" = "1" ]; then
		printf "\n"
		grub-mkconfig -o /boot/grub/grub.cfg
		if [ $? -eq 0 ]; then
			if [ -f /boot/grub/grub.cfg.new ]; then
				mv /boot/grub/grub.cfg.new /boot/grub/grub.cfg
			fi
		fi
		if [ ! -f /boot/grub/grub.cfg ]; then	
			printf "Error: grub.cfg does not exist - running mkconfig again to attempt to fix the issue \n"
			grub-mkconfig -o /boot/grub/grub.cfg
		fi
	elif [ "$grubType" = "2" ]; then
		printf "\n"
		grub-mkconfig -o /boot/efi/EFI/GRUB/grub.cfg
		if [ -f /boot/efi/EFI/GRUB/grub.cfg.new ]; then
			mv /boot/efi/EFI/GRUB/grub.cfg.new /boot/efi/EFI/GRUB/grub.cfg
		fi
		
		if [ ! -f /boot/efi/EFI/GRUB/grub.cfg ]; then	
			printf "Error: grub.cfg does not exist - running mkconfig again to attempt to fix the issue \n"
			grub-mkconfig -o /boot/efi/EFI/GRUB/grub.cfg
		fi
	fi
fi

printf "\n" 
printf "Complete! \n"
