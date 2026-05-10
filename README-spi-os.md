# creating linux micro-os for orangepi zero3
- as shipped spi micro-linux too outdated and broken
# patch kernel
```bash
$ OPENWRT_VERSION=25.12.3
$ KERNEL_FAMILY=sunxi-6.12
$ for patch in ~/openwrt-$OPENWRT_VERSION/target/linux/generic/backport-6.12/*.patch; do patch -p1 < "$patch"; done
$ for patch in ~/openwrt-$OPENWRT_VERSION/target/linux/generic/hack-6.12/*.patch; do patch -p1 < "$patch"; done
$ for patch in ~/openwrt-$OPENWRT_VERSION/target/linux/generic/pending-6.12/*.patch; do patch -p1 < "$patch"; done
$ cp -r ~/openwrt-$OPENWRT_VERSION/target/linux/generic/files/* .
$ for patch in ~/openwrt-$OPENWRT_VERSION/target/linux/sunxi/patches-6.12/*.patch; do patch -p1 < "$patch"; done
$ for patch in ~/kernel-patches/uwe5622-$KERNEL_FAMILY/*.patch; do patch -sNp1 < "$patch"; done
$ patch -p1 < ~/kernel-patches/generic/0001-uwe5622-makefile.patch
$ patch -p1 < ~/build-<any-armbian-version>/patch/kernel/archive/$KERNEL_FAMILY/patches.armbian/arm64-dts-h616-add-wifi-support-for-orange-pi-zero-2-and-zero3.patch
```

# build kernel
```bash
$ cp ~/kernel-patches/config_$KERNEL_FAMILY .config
$ make \
    ARCH=arm64 \
    CROSS_COMPILE=aarch64-none-elf- \
    KCFLAGS="-march=armv8-a+crc+crypto -mtune=cortex-a53" \
    KBUILD_BUILD_USER="nobody" \
    KBUILD_BUILD_HOST="localhost" \
    KBUILD_BUILD_TIMESTAMP="$(date -Ru)" \
    -j$(nproc) 2>&1 | tee -a build.log
```

# prepare dtb and create uImage
```bash
$ cd arch/arm64/boot
$ lzma -e9 -k Image
$ dtc -I dtb -O dts dts/allwinner/sun50i-h618-orangepi-zero3.dtb -o dt.dts
$ nano dt.dts # add partitions nodes to flash@0
$ dtc -I dts -O dtb dt.dts -o dt.dtb
$ cp ~/kernel-patches/misc/usr/local/etc/uImage-spi.its .
$ mkimage -f uImage-spi.its uImage.itb
```

# install modules to target rootfs
- alpine 3.23 arm64 is able to fit in 10mb when compressed (even with wpa_supplicant)
```bash
$ sudo make \
    ARCH=arm64 \
    CROSS_COMPILE=aarch64-none-elf- \
    KCFLAGS="-march=armv8-a+crc+crypto -mtune=cortex-a53" \
    KBUILD_BUILD_USER="nobody" \
    KBUILD_BUILD_HOST="localhost" \
    KBUILD_BUILD_TIMESTAMP="$(date -Ru)" \
    INSTALL_MOD_PATH=/root/jffs INSTALL_MOD_STRIP=1 modules_install -j$(nproc) 2>&1 | tee -a build.log
```

# build jffs2 image
- it is required to use mtd-utils with openwrt patches, default mtd-utils won't work here, also we need lzma compression
```bash
$ git clone git://git.infradead.org/mtd-utils.git -b v2.3.0 --depth=1 --single-branch --no-tags
$ cd mtd-utils
$ for patch in ~/openwrt-$OPENWRT_VERSION/tools/mtd-utils/patches/*.patch; do patch -p1 < "$patch"; done
$ ./autogen.sh
$ ./configure --without-tests --without-lsmtd --with-jffs --without-ubifs --with-zlib --with-xattr --without-lzo --without-zstd --with-lzma --without-selinux --without-crypto
$ sudo make DESTDIR=/opt/mtd-utils-openwrt install
```
- make sure you added new mtd-utils to PATH
```bash
# mkfs.jffs2 -r jffs/ -e 4KiB -m size -y 90:lzma -x rtime -o jffs.img --with-xattr
```

# install to spi
- transfer uImage.itb and jffs.img to target device
```bash
# cat /proc/mtd
dev:    size   erasesize  name
mtd0: 000f0000 00001000 "bootloader"
mtd1: 00010000 00001000 "env"
mtd2: 00080000 00001000 "firmware"
mtd3: 00400000 00001000 "uimage"
mtd4: 00a80000 00001000 "os"
# flashcp -Av jffs.img /dev/mtd4
# flashcp -Av uImage.itb /dev/mtd3
```

# boot from spi
- remove sd card in order to save env for automatic boot
```bash
=> setenv boot_tmp_addr 0x45000000
=> setenv bootcmd 'sf probe 0; sf read ${boot_tmp_addr} 0x180000 0x400000; bootm ${boot_tmp_addr}'
=> setenv bootargs 'root=/dev/mtdblock4 rw rootwait rootfstype=jffs2 init=/sbin/init panic=0 console=ttyS0,115200'
=> env save
=> run bootcmd
```
- optionally you can install `overlay-init` script from `misc/usr/local/bin/overlay-init`, update `init=` in bootargs accordingly

# using wifi
- prebuilt wifi firmware squashfs is available at `uwe5622-firmware/firmware.img`
- if using `overlay-init` make sure you have firmware.img installed on /dev/mtdblock2 (or comment out corresponding mount and modprobe lines)
```bash
# mkdir /mnt/firmware
# mount /dev/mtdblock2 /mnt/firmware/
# ln -s /mnt/firmware/* /lib/firmware/
# modprobe sprdwl_ng
# ip l show wlan0
3: wlan0: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN qlen 1000
    link/ether *** brd ff:ff:ff:ff:ff:ff
```
- connect wifi (also [generate wpa_supplicant config](https://wiki.alpinelinux.org/wiki/Wi-Fi#Manual_configuration))
```bash
# service wpa_supplicant start
# udhcpc -i wlan0
# ip a show wlan0
3: wlan0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP qlen 1000
    link/ether *** brd ff:ff:ff:ff:ff:ff
    inet 192.168.***/24 brd 192.168.*** scope global wlan0
       valid_lft forever preferred_lft forever
```
- [udhcpc through wpa_cli](https://wiki.alpinelinux.org/wiki/Wi-Fi#Launching_udhcpc_through_wpa_cli_actions) is useful for showing wifi status using onboard leds and syncing system time (see also: `misc/etc/wpa_supplicant/wpa_cli_wlan0.sh`)

# avoid unneccessary mtd writes
- fstab:
```
tmpfs /var/log tmpfs defaults,nosuid,noexec,nodev,size=40M 0 0
tmpfs /var/cache tmpfs defaults,nosuid,noexec,nodev,size=40M 0 0
tmpfs /root tmpfs defaults,nosuid,nodev,size=40M 0 0
tmpfs /tmp tmpfs defaults,nosuid,nodev,size=40M 0 0
```
- `apk` operations are dangerous (can cause 'no space left on device' errors), use only with overlay-init (ram or persist)

# overlay-init
- `overlay-init` will try to mount ext4 fs labeled `persist` and setup it for persistent storage instead of jffs, if not success it will fallback to tmpfs
- switch `skip_overlay=` will skip mounting any overlay if set to `1`
- switch `force_ram=` will always use tmpfs for overlay if set to `1`
- also it tries to mount partition labeled `boot` to `/mnt/boot`
- mounts firmware mtd partition and loads `sprdwl_ng`
- replaces self with `/sbin/init` (busybox init on alpine)

# system
```bash
# cat /etc/os-release 
NAME="Alpine Linux"
ID=alpine
VERSION_ID=3.23.3
PRETTY_NAME="Alpine Linux v3.23"
HOME_URL="https://alpinelinux.org/"
BUG_REPORT_URL="https://gitlab.alpinelinux.org/alpine/aports/-/issues"
# df -h
Filesystem                Size      Used Available Use% Mounted on
/dev/root                10.5M      9.0M      1.5M  85% /
devtmpfs                 10.0M         0     10.0M   0% /dev
/dev/mtdblock2          512.0K    512.0K         0 100% /mnt/firmware
tmpfs                   788.4M    196.0K    788.2M   0% /run
shm                       1.9G         0      1.9G   0% /dev/shm
tmpfs                    40.0M      4.0K     40.0M   0% /var/log
tmpfs                    40.0M         0     40.0M   0% /var/cache
tmpfs                    40.0M      4.0K     40.0M   0% /root
tmpfs                    40.0M         0     40.0M   0% /tmp
# rc-update
             dropbear |                                 sysinit
            hwdrivers |                                 sysinit
                 mdev |                                 sysinit
           networking | boot                                   
               syslog | boot                                   
              wpa_cli | boot                                   
       wpa_supplicant | boot
```
- with `overlay-init`:
```bash
# df -h
Filesystem                Size      Used Available Use% Mounted on
devtmpfs                 10.0M         0     10.0M   0% /dev
overlay                 120.1M     18.9M     91.8M  17% /
/dev/mmcblk0p1           54.7M     23.8M     26.4M  47% /mnt/boot
/dev/mtdblock2          512.0K    512.0K         0 100% /mnt/firmware
tmpfs                   788.4M    196.0K    788.2M   0% /run
shm                       1.9G         0      1.9G   0% /dev/shm
tmpfs                    40.0M      4.0K     40.0M   0% /var/log
tmpfs                    40.0M         0     40.0M   0% /var/cache
tmpfs                    40.0M         0     40.0M   0% /tmp
# fastfetch --logo none
root@opi
-------
OS: Alpine Linux v3.23 aarch64
Host: OrangePi Zero3
Kernel: Linux 6.12.87
Uptime: 19 mins
Packages: 55 (apk)
Shell: sh
Terminal: vt100
CPU: sun50i-h618 (4) @ 1.42 GHz
Memory: 71.54 MiB / 3.85 GiB (2%)
Swap: Disabled
Disk (/): 18.90 MiB / 120.08 MiB (16%) - overlay
Disk (/mnt/boot): 23.84 MiB / 54.72 MiB (44%) - ext4
Disk (/mnt/firmware): 512.00 KiB / 512.00 KiB (100%) - squashfs [Read-only]
Local IP (wlan0): 192.168.***/24
Locale: C.UTF-8
```
