#!/bin/bash

set -e

OVERLAY_PATH="/boot/efi/dtb/overlay"

hash1="$(dd if=/dev/urandom bs=1M count=1 2> /dev/null | md5sum | awk '{print $1}')"
hash2="$(dd if=/dev/urandom bs=1M count=1 2> /dev/null | md5sum | awk '{print $1}')"

seed1="${hash1:0:8}"
seed2="${hash2:0:8}"

cat << EOF > /tmp/kaslr-seed.dts
/dts-v1/;
/plugin/;

/ {
	fragment@0 {
		target-path = "/chosen";
		__overlay__ {
			kaslr-seed = <0x$seed1 0x$seed2>;
		};
	};
};
EOF

dtc -I dts -O dtb -o "$OVERLAY_PATH"/kaslr-seed.dtbo /tmp/kaslr-seed.dts
