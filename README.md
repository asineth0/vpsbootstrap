# vpsbootstrap

Creates a ~90MB ISO image for installing a custom OS onto a VPS.

## Concept

1. Build image with your SSH keys integrated.
2. SCP the ISO image to your VPS.
3. Use `dd` to write it to your VPS's main disk.
4. Force reboot the VPS with `reboot -f`.
5. SSH into the VPS on port 8022.
6. Overwrite the disk and install whatever you want.

Most distributions have guides on how to do step #6.

* [Ubuntu](https://help.ubuntu.com/lts/installation-guide/armhf/apds04.html)
* [Debian](https://www.debian.org/releases/stretch/amd64/apds03.html.en)
* [Arch](https://wiki.archlinux.org/index.php/Install_Arch_Linux_from_existing_Linux)
* [Alpine](https://wiki.alpinelinux.org/wiki/Installation)

For other distributions, it usually goes like this:

1. Download a rootfs of your favorite distro.
2. Partition your VPS's disk.
3. Create filesystems for root (and swap).
4. Extract the rootfs to the newly created filesystem.
5. Use `chroot` to configure the system.
6. Unmount everything and run `sync`.
7. Reboot into the distro.

## Features

* Automatic network configuration.
* SSH configured on port 8022.
* Just enough to install whatever you want.
* Based on Alpine Linux.
* Runs entirely from system RAM.

## Building

```sh
cat ~/.ssh/*.pub > authorized_keys
sudo ./build.sh
```
