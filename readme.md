# 目录结构

```
teddy@teddy-ubuntu:~/work/mini2440-lab$ tree -L 1
.
├── busybox：busybox代码。
├── image：放编译出来的镜像。
├── kernel：内核代码。
├── Makefile
├── nfs：这里放的是根文件系统。
├── qemu：2440定制版的qemu代码。
├── readme.md
├── scripts：工具脚本。
└── uboot：uboot代码。
```



# 使用方法

1、编译qemu。

```
make qemu-config
make qemu
```

2、编译uboot。

```
make uboot-defconfig
make uboot
```

3、编译kernel

```
make kernel-defconfig
make kernel
```

4、编译busybox。

```
make busybox-defconfig
make busybox
make busybox-install   这个就是安装到nfs目录下。
```

5、编译得到rootfs

```
make rootfs
```

6、得到nand.bin文件。

```
make nand
```

7、运行。

```
sudo make boot
```

然后进入到uboot的命令行。输入：

```
nand read 0x31000000 0x60000 0x500000
set bootargs noinitrd root=/dev/mtdblock3   rootfstype=jffs2 mtdparts=mtdparts=nandflash0:256k@0(boot),128k(params),5m(kernel),16m(root) console=ttySAC0,115200  
bootm 0x31000000
```

然后就启动进入到linux。就可以进行使用了。

8、带图形界面运行。

这个需要在Ubuntu的图像界面下执行命令。不能远程ssh来执行。

```
make boot-ui
```

