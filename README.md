Purpose
===

Automating the kernel emerge, eselect, compile, configuration copying and detection, 
hardware detection install, etc along with grub configuration updating to save some effort when 
installing, upgrading, or trying a new kernel.

Features
===

- A selection of kernels including gentoo-sources, hardened-sources, vanilla-sources, pf-sources, etc
- The option to unmask testing versions of your selected kernel
- Handles the eselect kernel set by giving a list of installed kernels to select in an easy manner
- If dependencies are not installed, you are prompted for the script to install them
- The option to copy a kernel .config from the scripts running directory to the selected kernels location or using the kernel from the running system
- Makes use of kergen for enabling hardware support for the currently running system in the selected kernel
- Options of compiling the kernel with the regular make method, Sakakis build kernel script, or Genkernel
- In all compiling methods, you are given the amount of CPU cores available and prompted to select how many to use
- In the regular make method and Genkernel selections you are given the option of using menuconfig or gconfig for kernel customization
- Supports updating your GRUB config. If GRUB is not installed it will be, walking you through configuration by prompting which disk to install to, etc.
- Among other nifty features..

Pictures
===

![daulton.ca](https://daulton.ca/lib/exe/fetch.php?cache=&media=bash_script_pictures:build-kernel-01.png)

> **Note:** 
> Kernel compilation output cut, of course.

![daulton.ca](https://daulton.ca/lib/exe/fetch.php?cache=&media=bash_script_pictures:build-kernel-02.png)

> **Note:** 
> Genkernel initramfs output cut.

![daulton.ca](https://daulton.ca/lib/exe/fetch.php?cache=&media=bash_script_pictures:build-kernel-03.png)


How to use
===

- Lets get the source

```
git clone https://github.com/jeekkd/gentoo-kernel-build.git && cd gentoo-kernel-build
```

- First we must change the scripts permissions. This will make the script readable, writable, and 
executable to root and your user

```
sudo chmod 770 build_kernel.sh
```

> **Note:** 
> This script can detect .configs in your current directory if you want to use your own custom configuration
> instead of your running kernels configuration as an example

- Now you launch the script like so

```
sudo bash build_kernel.sh
```

