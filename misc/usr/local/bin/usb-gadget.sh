#!/bin/bash

modprobe libcomposite

cd /sys/kernel/config/usb_gadget/
mkdir g1
cd g1/

echo 0x1d6b > idVendor
echo 0x1000 > idProduct
mkdir strings/0x409
echo 0000000000 > strings/0x409/serialnumber
echo Linux > strings/0x409/manufacturer
echo libcomposite > strings/0x409/product

mkdir configs/c.1
mkdir functions/acm.0
ln -s functions/acm.0/ configs/c.1/

mkdir functions/ncm.0
echo %MAC-A% > functions/ncm.0/dev_addr
echo %MAC-B% > functions/ncm.0/host_addr
ln -s functions/ncm.0/ configs/c.1/

ls /sys/class/udc/ > UDC
