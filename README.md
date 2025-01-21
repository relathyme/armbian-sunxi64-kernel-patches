# get source
- clone this repo to ~/kernel-patches
```bash
$ cd ~/

$ ARMBIAN_VERSION=500448d58842f627bf1f109b55dd4d4bd85caecd # or other commit

$ wget https://github.com/armbian/build/archive/$ARMBIAN_VERSION.tar.gz

$ tar xvf $ARMBIAN_VERSION.tar.gz 
```

# convert armbian patches series to patch our kernel
- cd to kernel directory first
```bash
$ cat ~/build-$ARMBIAN_VERSION/patch/kernel/archive/sunxi-6.6/series.megous | sed "s#\t#$HOME/build-$ARMBIAN_VERSION/patch/kernel/archive/sunxi-6.6/#g;/^#/d" > series.megous

# series.fixes is not always present
$ cat ~/build-$ARMBIAN_VERSION/patch/kernel/archive/sunxi-6.6/series.fixes | sed "s#\t#$HOME/build-$ARMBIAN_VERSION/patch/kernel/archive/sunxi-6.6/#g;/^#/d" > series.fixes

$ cat ~/build-$ARMBIAN_VERSION/patch/kernel/archive/sunxi-6.6/series.armbian | sed "s#\t#$HOME/build-$ARMBIAN_VERSION/patch/kernel/archive/sunxi-6.6/#g;/^#/d" > series.armbian
```

# apply patches
```bash
$ for patch in ~/kernel-patches/uwe5622-allwinner-v6.6/*.patch; do patch -sNp1 < "$patch"; done

$ for patch in ~/kernel-patches/generic/*.patch; do patch -sNp1 < "$patch"; done

$ for patch in $(cat series.megous); do patch -sNp1 < "$patch"; done

$ for patch in $(cat series.fixes); do patch -sNp1 < "$patch"; done

$ for patch in $(cat series.armbian); do patch -sNp1 < "$patch"; done
```

# build debian kernel package
```bash
$ mkdir out

$ cp ~/kernel-patches/config_6.6 out/.config

$ make O=out ARCH=arm64 LLVM=1 LLVM_IAS=1 KCFLAGS="-march=armv8-a+crc+crypto -mtune=cortex-a53 -Wno-incompatible-pointer-types-discards-qualifiers -I$PWD/drivers/net/wireless/uwe5622/unisocwcn/include" LOCALVERSION="-${ARMBIAN_VERSION:0:7}" KBUILD_BUILD_USER="nobody" KBUILD_BUILD_HOST="localhost" KBUILD_BUILD_TIMESTAMP="$(date -Ru)" CC="ccache clang" -j10 olddefconfig 2>&1 | tee -a out/build.log

$ make O=out ARCH=arm64 LLVM=1 LLVM_IAS=1 KCFLAGS="-march=armv8-a+crc+crypto -mtune=cortex-a53 -Wno-incompatible-pointer-types-discards-qualifiers -I$PWD/drivers/net/wireless/uwe5622/unisocwcn/include" LOCALVERSION="-${ARMBIAN_VERSION:0:7}" KBUILD_BUILD_USER="nobody" KBUILD_BUILD_HOST="localhost" KBUILD_BUILD_TIMESTAMP="$(date -Ru)" CC="ccache clang" -j10 bindeb-pkg 2>&1 | tee -a out/build.log
```