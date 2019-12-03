.PHONY: boot kernel uboot kernel-modules kernel-menuconfig \
	nand busybox-defconfig busybox busybox-install boot-nfs \
	qemu qemu-config uboot uboot-defconfig kernel-defconfig \
	rootfs modules-copy

ROOT_DIR:=$(shell pwd)

KERNEL_DIR=/home/teddy/work/linux-rpi/linux-rpi-4.4.y
#KERNEL_DIR=kernel/linux-2.6.35.1
#KERNEL_DIR=kernel/linux-3.10
IMG_DIR=./image
BUSYBOX_DIR=./busybox/busybox-1.27.2
QEMU_DIR=./qemu

UBOOT_DIR=./uboot/uboot

ARCH=arm
CROSS_COMPILE=arm-linux-gnueabi-
export ARCH CROSS_COMPILE

help:
	@cat readme.md
	@echo ""
pc-prepare:
	# install tools
	sudo apt-get install libsdl1.2-dev -y
	sudo apt-get install -y libgnutls-dev
qemu-prepare:
	# unzip file to qemu dir
	if [ ! -d ./qemu ]; then \
		tar -xf code/qemu.tar.gz -C ./; \
	fi
	# patch to compile ok
	cp code/qemu-patch/Makefile.target ./qemu -f

uboot-prepare:

qemu-config:
	cd $(QEMU_DIR); ./configure --target-list=arm-softmmu --disable-sdl --disable-vnc-tls --disable-gfx-check; cd -

qemu:
	cd $(QEMU_DIR); make -j4; cd -
qemu-clean:
	cd $(QEMU_DIR); make clean; cd -
uboot:
	cd $(UBOOT_DIR); make -j4; cd -

uboot-defconfig:
	cd $(UBOOT_DIR); make mini2440_config; cd -


kernel:
	cd $(KERNEL_DIR); make ARCH=arm CROSS_COMPILE=arm-none-eabi- uImage -j4;cd -
	cp $(KERNEL_DIR)/arch/arm/boot/uImage $(IMG_DIR) -f
kernel-defconfig:
	cd $(KERNEL_DIR); make ARCH=arm CROSS_COMPILE=arm-none-eabi- mini2440_defconfig ;cd -
kernel-modules:
	cd $(KERNEL_DIR); make ARCH=arm CROSS_COMPILE=arm-none-eabi- modules;cd -
modules-copy:
	cd $(KERNEL_DIR); find ./drivers -name "*.ko" -exec cp {} $(ROOT_DIR)/nfs/ko \; ;cd -
kernel-menuconfig:
	cd $(KERNEL_DIR); make ARCH=arm CROSS_COMPILE=arm-none-eabi- menuconfig;cd -
uboot:
	cd uboot/uboot; make ARCH=arm CROSS_COMPILE=arm-none-eabi- -j4; cd -
	cp uboot/uboot/u-boot.bin $(IMG_DIR) -f

rootfs:
	mkfs.jffs2 -n -s 512 -e 16KiB -d ./nfs -o ./image/rootfs.jffs2

nand:
	cd $(IMG_DIR) ;flashimg -s 64M -t nand -f nand.bin -p uboot.part -w boot,u-boot.bin -w kernel,uImage -w root,rootfs.jffs2 -z 512 ;cd -


busybox-defconfig:
	make -C $(BUSYBOX_DIR) defconfig
busybox:
	make -C $(BUSYBOX_DIR) -j4
busybox-install:
	make -C $(BUSYBOX_DIR) install CONFIG_PREFIX=$(ROOT_DIR)/nfs
busybox-menuconfig:
	make -C $(BUSYBOX_DIR) menuconfig


boot:
	$(ROOT_DIR)/qemu/arm-softmmu/qemu-system-arm  -M mini2440 -serial stdio -nographic  \
	-mtdblock $(ROOT_DIR)/image/nand.bin

boot-usb:
	$(ROOT_DIR)/qemu/arm-softmmu/qemu-system-arm  -M mini2440 -serial stdio -nographic  \
	-mtdblock $(ROOT_DIR)/image/nand.bin  -usb -usbdevice disk::./usb.img

boot-ui:
	$(ROOT_DIR)/qemu/arm-softmmu/qemu-system-arm  -M mini2440 -serial stdio \
	-mtdblock $(ROOT_DIR)/image/nand.bin  \
	-usb -usbdevice keyboard -usbdevice mouse -show-cursor

boot-nfs:
	$(ROOT_DIR)/qemu/arm-softmmu/qemu-system-arm  -M mini2440 -serial stdio -nographic -kernel ./image/uImage \
	-net nic,vlan=0 -net tap,vlan=0,ifname=tap0,script=no,downscript=no -mtdblock ./image/nand.bin
