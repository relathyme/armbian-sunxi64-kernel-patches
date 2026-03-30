setenv boot_tmp_addr '0x45000000'
setenv boot_device ${devtype} ${devnum}

load ${boot_device} ${boot_tmp_addr} /env.txt
env import -t ${boot_tmp_addr} ${filesize}

if itest.s ${boot_spi} == "true"; then
	sf probe 0
	sf read ${boot_tmp_addr} 0x000f0000 0x00010000
	env import -d ${boot_tmp_addr}
	run bootcmd
fi

load ${boot_device} ${fdt_addr_r} ${boot_dtb}
fdt addr ${fdt_addr_r}
fdt resize 65536
for overlay in ${overlays}; do
	if load ${boot_device} ${boot_tmp_addr} /dtb/overlay/${overlay}.dtbo; then
		echo "applying overlay: ${overlay}"
		fdt apply ${boot_tmp_addr}
	fi
done

load ${boot_device} ${boot_tmp_addr} ${boot_kernel}
bootm ${boot_tmp_addr} ${boot_tmp_addr} ${fdt_addr_r}
