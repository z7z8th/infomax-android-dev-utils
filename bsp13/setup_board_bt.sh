#!/bin/sh
set -x
croot
adb shell insmod /data/bcm4329-bt.ko
adb shell dmesg |grep -i bcm4329

adb shell chown system.system /sys/class/rfkill/rfkill0/state
adb shell ls -l /sys/class/rfkill/rfkill0/state
