Purpose
===

The purpose of this script is to for automating the kernel emerge, eselect, compile, install, etc to save some
effort when installing, upgrading, or trying a new kernel.

Pictures
===

![daulton.ca](https://daulton.ca/lib/exe/fetch.php/bash_script_pictures:build_kernel_00.png?w=700&h=861&tok=8cb493)
![daulton.ca](https://daulton.ca/lib/exe/fetch.php/bash_script_pictures:build_kernel_01.png?w=700&h=494&tok=9a9a85)

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

- Now you launch the script like so

```
sudo bash build_kernel.sh
```

----------

Additionally, here how you can add the script to be globally runnable. This is super convenient 
since you can merely type something such as the following and have the script run:

```
sudo build_kernel
```

Here's how we can do this:

```
# Syntax of doing so:

sudo ln <script location/script name> /usr/local/bin/<name you want to type to launch the script>

# More real example:

sudo ln /home/<user>/build_kernel.sh /usr/local/bin/build_kernel

Whichever name you choose, just make sure it does not conflict with the name of an existing command
```
