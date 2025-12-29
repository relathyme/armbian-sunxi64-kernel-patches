- patches source: [armbian](https://github.com/armbian/build/commit/d25a12e782aa988cd9c27a93eafd2bfef4cf1d8b)
- tested: atf v2.14 with u-boot v2026.01-rc5
- toolchain used: [aarch64-none-elf-gcc (Arm GNU Toolchain 15.2.Rel1 (Build arm-15.86)) 15.2.1 20251203](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads)

# my config additions:
```
+CONFIG_EFI_RT_VOLATILE_STORE
+CONFIG_CMD_UFETCH
```
