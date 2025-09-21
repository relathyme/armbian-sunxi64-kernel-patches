#!/bin/bash

hash="$(dd if=/dev/urandom bs=1M count=1 2> /dev/null | md5sum | awk '{print $1}')"
hostname="${hash:0:9}"
sysctl -w kernel.hostname=$hostname
echo $hostname > /etc/hostname
sed -i "s/127.0.1.1\t.*/127.0.1.1\t$hostname/" /etc/hosts
