#!/bin/sh

[ x$1 = x-a ] && PUSH_ALL=1

DEVICE_TYPE=iM9828_evb_v3
PRODUCT_OUT_DIR=out/target/product/$DEVICE_TYPE
which adb 2>&1 >/dev/null || export PATH=out/host/linux-x86/bin:$PATH

adb shell mount -o remount,rw /
adb remount

find $PRODUCT_OUT_DIR/system -newer $PRODUCT_OUT_DIR/system.img | \
    tee new-files.lst | \
    while read new_file_path; do
        [ -d "$new_file_path" ] && continue;
        board_file_path=${new_file_path#${PRODUCT_OUT_DIR}};
        board_file_time=`adb shell stat -c '%Y' $board_file_path | sed -e 's/\r//g'`
        new_file_time=`stat -c '%Y' $new_file_path`
        [ "$new_file_time" -le "$board_file_time" -a x$PUSH_ALL != x1 ] && {
            # echo "not new. skip $board_file_path";
            continue;
        }
        echo -n "push -> $board_file_path : ";
        adb push $new_file_path $board_file_path;
    done
