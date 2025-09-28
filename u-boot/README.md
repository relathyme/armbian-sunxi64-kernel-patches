- patches source: https://github.com/armbian/build/commit/d25a12e782aa988cd9c27a93eafd2bfef4cf1d8b
- tested : atf v2.12.6 with u-boot v2025.10-rc5

# my config additions:
```
+CONFIG_EFI_RT_VOLATILE_STORE
+CONFIG_CMD_UFETCH
```
