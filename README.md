# !!! experimental !!!
- playing around [qemu orangepi-pc emulator](https://www.qemu.org/docs/master/system/arm/orangepi.html)

# get source
- clone this repo to ~/kernel-patches (make sure you clone corrent branch)
```bash
$ cd ~/

$ ARMBIAN_VERSION=0fbc9e4c6b5cb817eb42530c084debb4493a3e2b # or other commit

$ KERNEL_FAMILY=sunxi-6.12 # or other version

$ wget https://github.com/armbian/build/archive/$ARMBIAN_VERSION.tar.gz

$ tar xvf $ARMBIAN_VERSION.tar.gz 
```

# convert armbian patches series to patch our kernel
- cd to kernel directory first
```bash
$ cat ~/build-$ARMBIAN_VERSION/patch/kernel/archive/$KERNEL_FAMILY/series.conf | sed "/^[#-]/d; /^$/d; s#\t#$HOME/build-$ARMBIAN_VERSION/patch/kernel/archive/$KERNEL_FAMILY/#g" > series.conf
```

# apply patches
```bash
$ for patch in ~/kernel-patches/uwe5622-$KERNEL_FAMILY/*.patch; do patch -sNp1 < "$patch"; done

$ for patch in ~/kernel-patches/generic/*.patch; do patch -sNp1 < "$patch"; done

$ for patch in $(cat series.conf); do patch -sp1 < "$patch"; done
```
- uwe5622 patches are extracted according to https://github.com/armbian/build/blob/main/lib/functions/compilation/patch/drivers_network.sh (function driver_uwe5622())

# build debian kernel package
```bash
$ mkdir out

$ cp ~/kernel-patches/config_$KERNEL_FAMILY out/.config

$ make \
    O=out \
    ARCH=arm \
    LLVM=1 \
    LLVM_IAS=1 \
    KCFLAGS="-march=armv7-a -mtune=cortex-a7 -Wno-incompatible-pointer-types-discards-qualifiers -I$PWD/drivers/net/wireless/uwe5622/unisocwcn/include" \
    LOCALVERSION="-${ARMBIAN_VERSION:0:7}" \
    KBUILD_BUILD_USER="nobody" \
    KBUILD_BUILD_HOST="localhost" \
    KBUILD_BUILD_TIMESTAMP="$(date -Ru)" \
    bindeb-pkg -j$(nproc) 2>&1 | tee -a out/build.log
```
- building headers package fails for some reason

# boot qemu
- using official image
- prepare image file:
```bash
$ qemu-img convert -p -f raw -O qcow2 Orangepipc_2.0.8_debian_buster_server_linux5.4.65.img Orangepipc_2.0.8_debian_buster_server_linux5.4.65.qcow2
$ qemu-img resize -f qcow2 Orangepipc_2.0.8_debian_buster_server_linux5.4.65.qcow2 8G
```
- boot:
```bash
qemu-system-arm \
        -M orangepi-pc \
        -accel tcg,thread=multi \
        -sd Orangepipc_2.0.8_debian_buster_server_linux5.4.65.qcow2 \
        -nic user \
        -nographic
```

# fetch
```
        _,met$$$$$gg.          orangepi@orangepipc
     ,g$$$$$$$$$$$$$$$P.       -------------------
   ,g$$P""       """Y$$.".     OS: Orange Pi 2.0.8 Buster armv7l
  ,$$P'              `$$$.     Host: Xunlong Orange Pi PC
',$$P       ,ggs.     `$$b:    Kernel: Linux 6.12.37-b313587
`d$$'     ,$P"'   .    $$$     Uptime: 25 mins
 $$P      d$'     ,    $$P     Packages: 444 (dpkg)
 $$:      $$.   -    ,d$$'     Shell: bash 5.0.3
 $$;      Y$b._   _,d$P'       Terminal: /dev/pts/0
 Y$$.    `.`"Y$$$$P"'          CPU: sun8i-h3 (4)
 `$$b      "-.__               Memory: 103.78 MiB / 996.77 MiB (10%)
  `Y$$b                        Swap: 0 B / 498.38 MiB (0%)
   `Y$$.                       Disk (/): 1.32 GiB / 7.68 GiB (17%) - ext4
     `$$b.                     Disk (/var/log): 1.00 MiB / 48.40 MiB (2%) - ext4
       `Y$$b.                  Local IP (eth0): 192.168.x.x/24
         `"Y$b._               Locale: en_US.UTF-8
             `""""
```

# credits
- [Armbian](https://github.com/armbian/build)
