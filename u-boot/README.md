- tested : atf v2.12.2 with u-boot v2025.04

# my config additions:
```
+CONFIG_EFI_RT_VOLATILE_STORE
+CONFIG_CMD_UFETCH
CONFIG_PREBOOT="setenv usb_pgood_delay 2500; usb start"
CONFIG_BOOTDELAY=0
```
