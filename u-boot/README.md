- tested : atf v2.12.2 with u-boot v2025.04

# my config additions:
```
+CONFIG_EFI_RT_VOLATILE_STORE
+CONFIG_CMD_UFETCH
+CONFIG_INITIAL_USB_SCAN_DELAY=5000
```