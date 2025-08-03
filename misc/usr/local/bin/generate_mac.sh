#!/bin/bash

if test -z $1; then exit 1; fi

if ! ip link show $1 > /dev/null; then exit 2; fi

mac="02:"

for i in {2..6}; do
	oct=$(printf "%02x" $((RANDOM%256)))
	if [ $i != 6 ]; then
		mac+="$oct:"
	else
		mac+="$oct"
	fi
done

if ! test -e /tmp/$1.macchanged; then
	ip link set $1 down
	ip link set $1 address $mac
	ip link set $1 up
	touch /tmp/$1.macchanged
fi
