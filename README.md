[![Build kernels](https://github.com/relathyme/armbian-sunxi64-kernel-patches/actions/workflows/build.yml/badge.svg)](https://github.com/relathyme/armbian-sunxi64-kernel-patches/actions/workflows/build.yml)
# general notes
- you can download prebuilt kernel releases from [actions](https://github.com/relathyme/armbian-sunxi64-kernel-patches/actions)
- kernel configs from here are made to boot with [u-boot EFI](https://docs.u-boot.org/en/stable/develop/uefi/uefi.html), you can use some efi bootmanager like systemd-boot for them as well
- preferable to have storage gpt-partitioned with ESP FAT32 /boot/efi partition and (must?) to have u-boot on SPI to use EFI boot
- if you don't use u-boot EFI you have to disable `CONFIG_EFI` kernel config, or use release prefixed with `non-efi`
- my config additions are listed in config_diff_from_official.txt
- armbian u-boot should work, refer to u-boot directory to build it manually
- toolchain used: https://mirrors.edge.kernel.org/pub/tools/llvm/files
- some auxiliary tools you can find in misc directory

# get source
- clone this repo to ~/kernel-patches
```bash
$ cd ~/

$ ARMBIAN_VERSION=a9b84c88f249db10a8ae73dce8e165d449c2460a # or other commit

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
- apply backported rtw88 in case you need RTL8812AU/RTL8821AU support (ONLY 6.12, optional):
```bash
$ for patch in ~/kernel-patches/generic/rtw88/*.patch; do patch -sNp1 < "$patch"; done
```
- uwe5622 patches are extracted according to https://github.com/armbian/build/blob/main/lib/functions/compilation/patch/drivers_network.sh (function driver_uwe5622())

# build debian kernel package
```bash
$ mkdir out

$ cp ~/kernel-patches/config_$KERNEL_FAMILY out/.config

$ make \
    O=out \
    ARCH=arm64 \
    LLVM=1 \
    LLVM_IAS=1 \
    KCFLAGS="-march=armv8-a+crc+crypto -mtune=cortex-a53 -Wno-incompatible-pointer-types-discards-qualifiers -I$PWD/drivers/net/wireless/uwe5622/unisocwcn/include" \
    LOCALVERSION="-${ARMBIAN_VERSION:0:7}" \
    KBUILD_BUILD_USER="nobody" \
    KBUILD_BUILD_HOST="localhost" \
    KBUILD_BUILD_TIMESTAMP="$(date -Ru)" \
    bindeb-pkg -j$(nproc) 2>&1 | tee -a out/build.log
```

# credits
- [Armbian](https://github.com/armbian/build)
