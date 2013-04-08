#!/bin/bash

[ -z "$ENVSETUP_SOURCED" ] && { echo -e "\033[31;1mplease source build/envsetup.sh first. exit...\033[31;1m"; exit 1; } 
[ -z "$TARGET_DEVICE" ] && { warn "please run lunch first. exiting..."; exit 1;}

ECHO="echo -e"
warn "\nBuild kernel\n"

export PATH=../prebuilt/linux-x86/toolchain/arm-eabi-4.4.3/bin:$PATH
# export PATH=../prebuilt/linux-x86/toolchain/arm-linux-androideabi-4.4.x/bin:$PATH
export ARCH=arm
export CROSS_COMPILE=arm-eabi-
# export CROSS_COMPILE=arm-linux-androideabi-

CONFIG_LIST=( im98xxv1_android_defconfig 
              im98xxv1_android_defconfig 
              im98xxv2_android_defconfig 
              im98xxv3_android_defconfig 
              im98xxv3_wvga_android_defconfig
              im98xxv4_android_defconfig 
              im98xxv4_wvga_android_defconfig)

BUILD=""
BUILD_MODULES="modules"

eval "IM_DEVICE_NAME_LIST=(${X_IM_DEVICE_NAME_LIST[*]})"
BOARD_NUMBER=$(get_dev_name_index $TARGET_DEVICE)
#warn $BOARD_NUMBER : ${IM_DEVICE_NAME_LIST[@]}
[ $BOARD_NUMBER -lt 0 ] && { $ECHO "wrong board number. you must have choosen the wrong lunch combo"; exit 1; }
CONFIG_TYPE=${CONFIG_LIST[$BOARD_NUMBER]}

$ECHO -n "You've choosen device: "; warn ${TARGET_DEVICE:-UNKNOWN_DEVICE}
$ECHO -n "Select "; warn ${CONFIG_TYPE:-UNKNOWN_CONFIG_TYPE}

DEFAULT_CMD_OPT_LIST=(-c -d -m)
[ $# != 0 ] && { CMD_OPT_LIST=$@; } || { CMD_OPT_LIST=${DEFAULT_CMD_OPT_LIST[@]}; }
NEED_CONFIRM=1
for opt in $@; do [ "$opt" = "-y" ] && { NEED_CONFIRM=0; break; } done

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
        -y) ;;
        *) warn "\nUnknow option: $opt, Available options are:\n" \
            "-y  say y to all confirmation" \
            "-c  make distclean\n" \
            "-d  make $CONFIG_TYPE\n" \
            "-m  make menuconfig\n"
            exit 1
        ;;
    esac
done


#Copy release object files back if the obj directroy exists
if [ -d ../kernel_obj ] ; then
    $ECHO "This is a release version"
    $ECHO "Copying object files for the compilation"
    sh rel_obj_put_back.sh
    $ECHO "Copying done"
fi

$ECHO "====================Building====================="
make CONFIG_DEBUG_SECTION_MISMATCH=y $BUILD

if [ $? = 0 ]; then
    mkdir -p $ANDROID_PRODUCT_OUT
    cp arch/arm/boot/zImage ../device/infomax/$TARGET_DEVICE/kernel
    cp arch/arm/boot/zImage $ANDROID_PRODUCT_OUT/kernel
    if [ -e drivers/net/wireless/rda5990p/rda5890.ko ] ; then
        cp drivers/net/wireless/rda5990p/rda5890.ko ../hardware/im98xx/wlan/rda/rda5990p/module/rda5890.ko
    fi
    if [ -e drivers/net/wireless/bcm4329/bcm4329.ko ] ; then
        cp drivers/net/wireless/bcm4329/bcm4329.ko ../hardware/broadcom/wlan/bcm4329/module/bcm4329.ko
    fi

    git log -n 1 > $ANDROID_PRODUCT_OUT/kernel.version
    $ECHO "\n=== kernel Build Completed Sucessfully. ==="
    $ECHO "=== please find the image at infomax_images ===\n"
    exit 0
else
    $ECHO "\n*** kernel Build Failed. ***\n"
    exit 1
fi

#$ECHO "make modules"
#$ECHO "=================================================="
#make $BUILD_MODULES
#$ECHO "=================================================="
#$ECHO " Copy kernel modules to ../vendor/infomax/iM9815 "
#$ECHO "=================================================="
#find . -name *.ko | xargs cp -f -t ../vendor/infomax/iM9815

