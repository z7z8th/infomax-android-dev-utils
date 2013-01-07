#!/bin/sh

#croot
BT_LOG_TAG=BT
BT_CODE_NAME=bcm4329_bt
BT_KMOD_NAME=$BT_CODE_NAME.ko
adb push kernel/drivers/bluetooth/$BT_KMOD_NAME /data/
adb shell rmmod $BT_CODE_NAME
adb shell insmod /data/$BT_KMOD_NAME
adb shell dmesg |grep $BT_LOG_TAG

#adb shell chown system.system /sys/class/rfkill/rfkill0/state
adb shell ls -l /sys/class/rfkill/
adb shell chmod 777 /sys/class/rfkill/rfkill*/state
