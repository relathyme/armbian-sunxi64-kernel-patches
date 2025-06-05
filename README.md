# general notes
- kernel configs from here are made to boot with [u-boot EFI](https://docs.u-boot.org/en/stable/develop/uefi/uefi.html), you can use some efi bootmanager like systemd-boot for them as well
- preferable to have storage gpt-partitioned with ESP FAT32 /boot/efi partition (to simplify installation of efi boot manager) and (must?) to have u-boot on SPI
- example boot.cmd:
```
load ${devtype} ${devnum} ${kernel_addr_r} /EFI/systemd/systemd-bootaa64.efi
load ${devtype} ${devnum} ${fdt_addr_r} <your FDT file>
bootefi ${kernel_addr_r} ${fdt_addr_r}
```
- these configs **won't** work with default armbian, you have to switch to efi or disable efi-related entries in kernel config
- my config additions are listed in config_diff_from_official.txt
- tbh i don't know how to maintain kernel patches so compatibility with latest kernel releases is not guaranteed, all thanks to armbian developers for their work
- armbian u-boot should work
- toolchain used: https://mirrors.edge.kernel.org/pub/tools/llvm/files

# get source
- clone this repo to ~/kernel-patches
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
    ARCH=arm64 \
    LLVM=1 \
    LLVM_IAS=1 \
    KCFLAGS="-march=armv8-a+crc+crypto -mtune=cortex-a53 -Wno-incompatible-pointer-types-discards-qualifiers -I$PWD/drivers/net/wireless/uwe5622/unisocwcn/include" \
    LOCALVERSION="-${ARMBIAN_VERSION:0:7}" \
    KBUILD_BUILD_USER="nobody" \
    KBUILD_BUILD_HOST="localhost" \
    KBUILD_BUILD_TIMESTAMP="$(date -Ru)" \
    olddefconfig -j$(nproc) 2>&1 | tee -a out/build.log

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
- note: it works same for rpm packages just replace `bindeb-pkg` with `binrpm-pkg`

# todo
- automate with script
- do not use hardcoded paths
- adapt to use not only with sunxi64 (?)
- add gcc build
