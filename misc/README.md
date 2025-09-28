# update-dtbs
- only for debian and its derivatives
- updates dtb and dtbo files in boot directory
- update from currently running kernel:
```bash
$ sudo update-dtbs
```
- update from other kernel (deb must be installed):
```bash
$ sudo update-dtbs 6.12.30-0fbc9e4
```

# update-dtbs.conf
- configuration for `update-dtbs`
- `VENDOR`, `DTB`, `BOOT_DTB_DIR` are mandatory
- `OVERLAYS` is a space-delimited list, can be removed if overlays are not used

# boot.cmd
- u-boot script used to boot efi binary
- compile to u-boot format with:
```bash
$ sudo mkimage -C none -A arm -T script -d /boot/efi/boot.cmd /boot/efi/boot.scr
```

# env.txt
- config for boot script
- `boot_loader`, `boot_dtb` are mandatory
- `overlays` is a space-delimited list (without quotes)
- if overlays are not used set it like:
```
overlays=
```

# generate_mac.sh
- usage: `generate_mac.sh <interface>`
- sets random mac address for interface
- as a service: `systemctl enable mac-spoof@<interface>`

# generate_hostname.sh
- usage: `generate_hostname.sh`
- sets random hostname
- system must have `127.0.1.1	localhost` record in /etc/hosts (tab, not space)
- as a service: `systemctl enable hostname-spoof`

# generate_kaslrseed.sh
- usage: `generate_kaslrseed.sh`, but better to use it with `systemctl start kaslr-seed` to isolate tmp directory
- generates kaslr seed for next boot
- OVERLAY_PATH must be set in script and `kaslr-seed.dtbo` overlay must be enabled in your env
- make sure your overlay dir is not readable for non-root users
- as a service: `systemctl enable kaslr-seed`
