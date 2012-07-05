#!/bin/bash

[ -z "$ENVSETUP_SOURCED" ] && { echo -e "\033[31;1mplease source build/envsetup.sh first. exit...\033[31;1m"; exit 1; } 
[ -z "$TARGET_DEVICE" ] && { warn "please run lunch first. exiting..."; exit 1;}

ECHO="echo -e"
warn "\nBuild barebox\n"

export PATH=../prebuilt/linux-x86/toolchain/BSP12_arm-eabi-4.4.0/bin:$PATH
export ARCH=arm
export CROSS_COMPILE=arm-eabi-

cat  >include/git_commit.h  <<EOF
#if defined(GIT_COMMIT)
#define GIT_RELEASE GIT_COMMIT
#else
#define GIT_RELEASE " export"
#endif
EOF

CONFIG_LIST=( im9828v1_A9-520MHz-AHB-div2_XM-198MHz_A7-143MHz_defconfig 
              im9828v1_A9-520MHz-AHB-div2_XM-198MHz_A7-143MHz_defconfig 
              im9828v2_A9-520MHz-AHB-div2_XM-198MHz_A7-143MHz_defconfig 
              im9828v3_A9-520MHz-AHB-div2_XM-198MHz_A7-143MHz_defconfig 
              im9828v3_wvga_A9-520MHz-AHB-div2_XM-198MHz_A7-143MHz_defconfig)


eval "IM_DEVICE_NAME_LIST=(${X_IM_DEVICE_NAME_LIST[*]})"
BOARD_NUMBER=$(get_dev_name_index $TARGET_DEVICE)
#warn $BOARD_NUMBER : ${IM_DEVICE_NAME_LIST[@]}
[ $BOARD_NUMBER -lt 0 ] && { $ECHO "wrong board number. you must have choosen the wrong lunch combo"; exit 1; }
CONFIG_TYPE=${CONFIG_LIST[$BOARD_NUMBER]}

$ECHO -n "You've choosen device: "; warn ${TARGET_DEVICE:-UNKNOWN_DEVICE}
$ECHO -n "Select "; warn ${CONFIG_TYPE:-UNKNOWN_CONFIG_TYPE}

DEFAULT_CMD_OPT_LIST=(-c -d -m)
[ $# != 0 ] && { 
    CMD_OPT_LIST=$@; 
    NEED_CONFIRM=0; 
} || {
    CMD_OPT_LIST=${DEFAULT_CMD_OPT_LIST[@]};
    NEED_CONFIRM=1;
}

for opt in ${CMD_OPT_LIST[@]}; do
    case $opt in
        -c) $ECHO "\nDo clean"
            prompt_for_confirm && make distclean
            ;;
        -d) $ECHO "\nUse default config: $CONFIG_TYPE"
            prompt_for_confirm && make $CONFIG_TYPE
            ;;
        -m) $ECHO "\nRun menuconfig"
            prompt_for_confirm && make menuconfig
            ;;
         *) warn "\nUnknow option: $opt, Available options are:\n" \
             "-c  make distclean\n" \
             "-d  make $CONFIG_TYPE\n" \
             "-m  make menuconfig\n"
            ;;
    esac
done


$ECHO "=====================Building========================="
make

#[ -z "$ANDROID_PRODUCT_OUT" ] && echo fuck ANDROID_PRODUCT_OUT is null

if [ $? = 0 ]; then
    mkdir -p $ANDROID_PRODUCT_OUT
    cp barebox.bin $ANDROID_PRODUCT_OUT

    $ECHO "\n=== Barebox Build Completed Sucessfully. ==="
    $ECHO "=== please find the image at infomax_images ===\n"
    exit 0
else
    $ECHO "\n*** Barebox Build Failed. ***\n"
    exit 1
fi

