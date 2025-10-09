- patches source: [armbian](https://github.com/armbian/build/commit/d25a12e782aa988cd9c27a93eafd2bfef4cf1d8b)
- tested: atf sandbox/lts-v2.12.7-20251003T1600 with u-boot v2025.10
- toolchain used: [aarch64-none-elf-gcc (Arm GNU Toolchain 14.3.Rel1 (Build arm-14.174)) 14.3.1 20250623](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads)

# my config additions:
```
+CONFIG_EFI_RT_VOLATILE_STORE
+CONFIG_CMD_UFETCH
```
