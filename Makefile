.PHONY: boot kernel uboot kernel-modules kernel-menuconfig \
	nand busybox-defconfig busybox busybox-install boot-nfs \
	qemu qemu-config uboot uboot-defconfig kernel-defconfig \
	rootfs modules-copy

ROOT_DIR:=$(shell pwd)

# KERNEL_DIR=/home/teddy/work/linux-rpi/linux-rpi-4.4.y
#KERNEL_DIR=kernel/linux-2.6.35.1
KERNEL_DIR=kernel/linux-2.6.35
IMG_DIR=./image
BUSYBOX_DIR=./busybox/busybox-1.29.3
QEMU_DIR=./qemu

UBOOT_DIR=./uboot

ARCH=arm
CROSS_COMPILE=arm-linux-gnueabi-
export ARCH CROSS_COMPILE

help:
	@cat readme.md
	@echo ""
flashimg:
	cd code; \
	unzip flashimg-master.zip; \
	cd flashimg-master; \
	./autogen.sh; \
	./configure ;\
	make ;\
	sudo make install
	
pc-prepare:flashimg
	# install tools
	#echo "do nothing"
	sudo apt-get install -y u-boot-tools mtd-utils

qemu-prepare:
	# unzip file to qemu dir
	if [ ! -d ./qemu ]; then \
		tar -xf code/qemu.tar.gz -C ./; \
	fi
	# patch to compile ok
	cp code/qemu-patch/Makefile.target ./qemu -f



qemu-config:
	cd $(QEMU_DIR); ./configure --target-list=arm-softmmu --disable-sdl --disable-vnc-tls --disable-gfx-check; cd -

qemu:
	cd $(QEMU_DIR); make -j4; cd -
qemu-clean:
	cd $(QEMU_DIR); make clean; cd -

uboot-prepare:
	if [ ! -d ./uboot ]; then \
		tar -xf code/uboot.tgz -C ./ ; \
	fi
	# mkimage编译不过的，所以把tools下面的Makefile里去掉对mkimage的编译。
	cp code/uboot-patch/tools/Makefile $(UBOOT_DIR)/tools


uboot:
	cd $(UBOOT_DIR); make ARCH=arm CROSS_COMPILE=arm-none-eabi- -j4; cd -
	cp $(UBOOT_DIR)/u-boot.bin $(IMG_DIR) -f
uboot-defconfig:
	cd $(UBOOT_DIR); make mini2440_config; cd -

kernel-prepare:
	# https://mirrors.edge.kernel.org/pub/linux/kernel/v2.6/linux-2.6.35.tar.xz
	# 4.14.y的编译会报错。
	# 这个压缩包有50M左右，相对比较大。放在git下，clone也不方便。下载也不快。
	# 我放到我的微云上。
	tar -xf code/linux-2.6.35.tgz -C ./kernel
	# 这个版本kernel/timeconst.pl里，defined需要去掉。
	cp code/kernel-patch/kernel/timeconst.pl $(KERNEL_DIR)/kernel
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


rootfs:
	mkfs.jffs2 -n -s 512 -e 16KiB -d ./nfs -o ./image/rootfs.jffs2

nand:
	cd $(IMG_DIR) ;flashimg -s 64M -t nand -f nand.bin -p uboot.part -w boot,u-boot.bin -w kernel,uImage -w root,rootfs.jffs2 -z 512 ;cd -

busybox-prepare:
	tar -xf code/busybox-1.29.3.tgz -C ./busybox

busybox-defconfig:
	make -C $(BUSYBOX_DIR) defconfig CROSS_COMPILE=arm-linux-gnueabihf- ARCH=arm
busybox:
	make -C $(BUSYBOX_DIR) -j4 CROSS_COMPILE=arm-linux-gnueabihf- ARCH=arm
busybox-install:
	make -C $(BUSYBOX_DIR) install CONFIG_PREFIX=$(ROOT_DIR)/nfs CROSS_COMPILE=arm-linux-gnueabihf- ARCH=arm
busybox-menuconfig:
	make -C $(BUSYBOX_DIR) menuconfig CROSS_COMPILE=arm-linux-gnueabihf- ARCH=arm


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
