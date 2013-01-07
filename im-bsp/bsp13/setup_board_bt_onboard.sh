#!/bin/sh

#croot
BT_LOG_TAG=BT
BT_CODE_NAME=bcm4329_bt
BT_KMOD_NAME=$BT_CODE_NAME.ko
insmod /data/$BT_KMOD_NAME

#adb shell chown system.system /sys/class/rfkill/rfkill0/state
ls -l /sys/class/rfkill/
chmod 777 /sys/class/rfkill/rfkill*/state
