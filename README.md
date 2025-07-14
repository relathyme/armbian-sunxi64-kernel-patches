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

# credits
- [Armbian](https://github.com/armbian/build)
