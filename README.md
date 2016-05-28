Purpose
===

The purpose of this script is to for automating the kernel emerge, eselect, compile, install, etc to save some
effort when installing, upgrading, or trying a new kernel.


How to use
===

- This will make the script readable, writable, and executable to root and your user. 

sudo chmod 770 build_kernel.sh

Launch the script by doing the following:

sudo bash build_kernel.sh

----------

As an added bonus here is how you can add the script to be globally runnable. This is super convenient 
since you can merely type something such as the following and have the script run:

sudo build_kernel

Here's how we can do this:

```
// Syntax of doing so:

sudo ln <script location/script name> /usr/local/bin/<name you want to type to launch the script>

// More real example:

sudo ln /home/<user>/build_kernel.sh /usr/local/bin/build_kernel
```
