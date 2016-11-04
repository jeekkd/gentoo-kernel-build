Purpose
===

Automating the kernel emerge, eselect, compile, configuration copying and detection, 
hardware detection install, etc along with grub configuration updating to save some effort when 
installing, upgrading, or trying a new kernel.

Pictures
===

![daulton.ca](https://daulton.ca/lib/exe/fetch.php/bash_script_pictures:build_kernel_example.png?w=700&h=761&tok=40f9e0)

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

