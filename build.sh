#!/bin/sh
for i in curl tar gzip cpio pigz grub-mkrescue xorriso mformat strip; do
	if ! command -v $i >/dev/null; then
		echo "[!] $i missing from PATH"
		exit 1
	fi
done

umount -lf work/root/* 2>/dev/null
rm -rf work
mkdir -p work/root
mkdir -p work/iso/boot/grub
cd work

echo '[*] fetching rootfs'
curl -sL "https://dl-cdn.alpinelinux.org/alpine/v3.13/releases/x86_64/alpine-minirootfs-3.13.1-x86_64.tar.gz" | tar -xzC root

echo '[*] mounting filesystems'
mount -o bind /dev root/dev
mount -o bind /sys root/sys
mount -o bind /proc root/proc

echo '[*] copying resolv.conf'
cp -i /etc/resolv.conf root/etc

echo '[*] configuring rootfs'
cat << ! | chroot root /usr/bin/env PATH=/bin:/sbin:/usr/bin:/usr/sbin /bin/sh >/dev/null
apk upgrade
apk add openrc udev dhcpcd dropbear
apk add --no-scripts linux-lts linux-firmware-none
rc-update add bootmisc
rc-update add hwdrivers
rc-update add dhcpcd
rc-update add dropbear
rc-update add udev
rc-update add udev-trigger
rc-update add udev-settle
!

echo '[*] cleaning up rootfs'
umount -lf root/* 2>/dev/null
rm -f root/etc/resolv.conf

echo '[*] copying ssh keys'
mkdir -p root/root/.ssh
cp -i ../authorized_keys root/root/.ssh

echo '[*] creatig init symlink'
ln -s sbin/init root/init

echo '[*] compressing kernel modules'
find root/lib/modules/* -type f -name "*.ko" | xargs -n1 -P`nproc` -- strip --strip-unneeded
find root/lib/modules/* -type f -name "*.ko" | xargs -n1 -P`nproc` -- pigz -9
find root/lib/modules/* -type f -name "*.ko.gz" | xargs -n1 -P`nproc` -- rename .ko.gz .ko

echo '[*] copying kernel to iso'
cp root/boot/vmlinuz-lts iso/boot/vmlinuz

echo '[*] creating initramfs'
cd root
find . | cpio -oH newc --quiet | pigz -9 > ../iso/boot/initramfs.gz
cd ..

echo '[*] configuring bootloader'
cat << ! > iso/boot/grub/grub.cfg
linux /boot/vmlinuz
initrd /boot/initramfs.gz
boot
!

echo '[*] creating iso'
grub-mkrescue -o ../vpsbootstrap.iso --fonts= --locales= --themes= iso >/dev/null 2>&1
