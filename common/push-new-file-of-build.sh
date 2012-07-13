#!/bin/sh

DEVICE_TYPE=iM9828_evb_v3
PRODUCT_OUT_DIR=out/target/product/$DEVICE_TYPE
which adb 2>&1 >/dev/null || export PATH=out/host/linux-x86/bin:$PATH

adb shell mount -o remount,rw /
adb remount

find $PRODUCT_OUT_DIR/system -newer $PRODUCT_OUT_DIR/system.img | \
    tee new-files.lst | \
    while read line; do 
        [ -d "$line" ] && continue;
        board_path=${line#${PRODUCT_OUT_DIR}};
        echo -n "-> $board_path : ";
        adb push $line $board_path;
    done
