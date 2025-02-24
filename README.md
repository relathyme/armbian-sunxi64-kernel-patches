# get source
- clone this repo to ~/kernel-patches
```bash
$ cd ~/

$ ARMBIAN_VERSION=8e75c8ebd1e54f84cf55830de04f96937e388f9c # or other commit

$ KERNEL_FAMILY=sunxi-6.6 # or other version

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

$ make O=out ARCH=arm64 LLVM=1 LLVM_IAS=1 KCFLAGS="-march=armv8-a+crc+crypto -mtune=cortex-a53 -Wno-incompatible-pointer-types-discards-qualifiers -I$PWD/drivers/net/wireless/uwe5622/unisocwcn/include" LOCALVERSION="-${ARMBIAN_VERSION:0:7}" KBUILD_BUILD_USER="nobody" KBUILD_BUILD_HOST="localhost" KBUILD_BUILD_TIMESTAMP="$(date -Ru)" -j10 olddefconfig 2>&1 | tee -a out/build.log

$ make O=out ARCH=arm64 LLVM=1 LLVM_IAS=1 KCFLAGS="-march=armv8-a+crc+crypto -mtune=cortex-a53 -Wno-incompatible-pointer-types-discards-qualifiers -I$PWD/drivers/net/wireless/uwe5622/unisocwcn/include" LOCALVERSION="-${ARMBIAN_VERSION:0:7}" KBUILD_BUILD_USER="nobody" KBUILD_BUILD_HOST="localhost" KBUILD_BUILD_TIMESTAMP="$(date -Ru)" -j10 bindeb-pkg 2>&1 | tee -a out/build.log
```
- note: it works same for rpm packages just replace `bindeb-pkg` with `binrpm-pkg`
