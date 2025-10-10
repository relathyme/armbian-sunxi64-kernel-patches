setenv boot_tmp_addr '0x45000000'
setenv boot_device ${devtype} ${devnum}

load ${boot_device} ${boot_tmp_addr} /env.txt
env import -t ${boot_tmp_addr} ${filesize}

load ${boot_device} ${kernel_addr_r} ${boot_loader}
load ${boot_device} ${fdt_addr_r} ${boot_dtb}
fdt addr ${fdt_addr_r}
fdt resize 65536

for overlay in ${overlays}; do
	if load ${boot_device} ${boot_tmp_addr} /dtb/overlay/${overlay}.dtbo; then
		echo "applying overlay: ${overlay}"
		fdt apply ${boot_tmp_addr}
	fi
done

bootefi ${kernel_addr_r} ${fdt_addr_r}
