Purpose
===

The purpose of this script is to for automating the kernel emerge, eselect, compile, install, etc to save some
effort when installing, upgrading, or trying a new kernel.

Pictures
===

![daulton.ca](https://daulton.ca/lib/exe/fetch.php/bash_script_pictures:build_kernel_example.png?w=700&h=761&tok=40f9e0)

How to use
===

- Lets get the source

```
git clone https://gitlab.com/huuteml/gentoo_kernel_build.git && cd gentoo_kernel_build
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

