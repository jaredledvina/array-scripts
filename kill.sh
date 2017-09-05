#!/bin/bash

echo "Performing emergency wipe of Yubikey"
/usr/bin/gpg-connect-agent -r /root/kill-yubikey

for drive in $(/bin/lsblk -dlnp --output NAME)
do
    echo "Performing emergency wipe of drive: $drive"
    /sbin/cryptsetup luksErase $drive
done

echo "Enabling sysrq for emergency shutdown"
echo 1 > /proc/sys/kernel/sysrq 

echo "Forcing emergency shutdown procedure now"
echo o > /proc/sysrq-trigger

echo "Fuck we are still up..."
echo "Going to just execute a standard shut down, hope it is fast enough"
/sbin/shutdown --no-wall now
