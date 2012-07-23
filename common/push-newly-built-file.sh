#!/bin/sh

[ x$1 = x-a ] && PUSH_ALL=1

DEVICE_TYPE=iM9828_evb_v3
PRODUCT_OUT_DIR=out/target/product/$DEVICE_TYPE
which adb 2>&1 >/dev/null || export PATH=out/host/linux-x86/bin:$PATH

echo "waiting for device..."
while true; do
    [ `adb devices | wc -l` -lt 3 ] && echo -n '.' || break
    sleep 1
done
adb shell mount -o remount,rw /
adb remount

find $PRODUCT_OUT_DIR/system -newer $PRODUCT_OUT_DIR/system.img | \
    tee new-files.lst | \
    while read new_file_path; do
        [ -d "$new_file_path" ] && continue;
        board_file_path=${new_file_path#${PRODUCT_OUT_DIR}};
        board_file_time=`adb shell stat -c '%Y' $board_file_path 2>/dev/null | sed -e 's/\r//g' | grep -x '[0-9]*'`
        [ -z "$board_file_time" ] && {
            echo "*** $board_file_path doesn't exists, skip"; #continue;
        }
        new_file_time=`stat -c '%Y' $new_file_path`
        [ "$new_file_time" -le "${board_file_time:-0}" -a x$PUSH_ALL != x1 ] && {
            # echo "not new. skip $board_file_path";
            continue;
        }
        echo -n "push -> $board_file_path : ";
        adb push $new_file_path $board_file_path;
    done
