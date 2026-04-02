#!/bin/sh
# Script for using udhcpc (started by ifup) with wpa_supplicant.
#
# Distributed under the same license as wpa_supplicant itself.
# Copyright (c) 2015,2018 Sören Tempel <soeren+alpine@soeren-tempel.net>

if [ $# -ne 2 ]; then
	logger -t wpa_cli "this script should be called from wpa_cli(8)"
	exit 1
fi

IFNAME="${1}"
ACTION="${2}"

if [ "$IFNAME" != wlan0 ]; then
	exit 0
fi

logger -t wpa_cli "interface ${IFNAME} ${ACTION}"
case "${ACTION}" in
	CONNECTED)
		udhcpc -b -R -p /var/run/udhcpc.wlan0.pid -i wlan0
		ntpd -q -p pool.ntp.org
		echo 0 > /sys/class/leds/red\:power/brightness
		echo 1 > /sys/class/leds/green\:status/brightness
		;;
	DISCONNECTED)
		PID=$(cat /var/run/udhcpc.wlan0.pid)
		kill $PID
		echo 1 > /sys/class/leds/red\:power/brightness
		echo 0 > /sys/class/leds/green\:status/brightness
		;;
	*)
		logger -t wpa_cli "unknown action '${ACTION}'"
		exit 1
esac
