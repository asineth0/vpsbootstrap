#!/bin/sh
for i in curl tar gzip cpio pigz grub-mkrescue xorriso mformat strip xz rename; do
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

curl -L https://dl-cdn.alpinelinux.org/alpine/v3.13/releases/x86_64/alpine-minirootfs-3.13.1-x86_64.tar.gz | tar -xzC root
mount -o bind /dev root/dev
mount -o bind /sys root/sys
mount -o bind /proc root/proc
cp -i /etc/resolv.conf root/etc

cat << ! > root/etc/network/interfaces
auto lo
iface lo inet loopback
!

cat << ! > iso/boot/grub/grub.cfg
linux /boot/vmlinuz
initrd /boot/initramfs.gz
boot
!

cat << ! | chroot root /usr/bin/env PATH=/bin:/sbin:/usr/bin:/usr/sbin /bin/sh
apk upgrade
apk add openrc udev dhcpcd dropbear
apk add --no-scripts linux-lts linux-firmware-none
rc-update add bootmisc
rc-update add hwdrivers
rc-update add networking
rc-update add dhcpcd
rc-update add dropbear
rc-update add udev
rc-update add udev-trigger
rc-update add udev-settle
!

umount -lf root/* 2>/dev/null
rm -f root/etc/resolv.conf

mkdir -p root/root/.ssh
cp -i ../authorized_keys root/root/.ssh

ln -s sbin/init root/init

find root/lib/modules/* -type f -name "*.ko" | xargs -n1 -P`nproc` -- strip --strip-unneeded
find root/lib/modules/* -type f -name "*.ko" | xargs -n1 -P`nproc` -- pigz -9
find root/lib/modules/* -type f -name "*.ko.gz" | xargs -n1 -P`nproc` -- rename .ko.gz .ko

cp root/boot/vmlinuz-lts iso/boot/vmlinuz

cd root
find . | cpio -oH newc | pigz -9 > ../iso/boot/initramfs.gz
cd ..

grub-mkrescue -o ../vpsbootstrap.iso --fonts= --locales= --themes= iso
