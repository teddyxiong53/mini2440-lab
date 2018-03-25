.PHONY: boot kernel uboot kernel-modules kernel-menuconfig \
	nand busybox-defconfig busybox busybox-install boot-nfs \
	qemu qemu-config uboot uboot-defconfig kernel-defconfig \
	rootfs

ROOT_DIR=`pwd`

KERNEL_DIR=/home/teddy/work/linux-rpi/linux-rpi-4.4.y
#KERNEL_DIR=kernel/linux-2.6.35.1
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

qemu-config:
	cd $(QEMU_DIR); ./configure --target-list=arm-softmmu; cd -
	
qemu:
	cd $(QEMU_DIR); make -j4; cd -

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
	-mtdblock $(ROOT_DIR)/image/nand.bin  -sd ./sd.img

boot-nfs:
	$(ROOT_DIR)/qemu/arm-softmmu/qemu-system-arm  -M mini2440 -serial stdio -nographic -kernel ./image/uImage \
	-net nic,vlan=0 -net tap,vlan=0,ifname=tap0,script=no,downscript=no -mtdblock ./image/nand.bin