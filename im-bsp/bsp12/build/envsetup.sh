function help() {
cat <<EOF
Invoke ". build/envsetup.sh" from your shell to add the following functions to your environment:
- croot:   Changes directory to the top of the tree.
- m:       Makes from the top of the tree.
- mm:      Builds all of the modules in the current directory.
- mmm:     Builds all of the modules in the supplied directories.
- cgrep:   Greps on all local C/C++ files.
- jgrep:   Greps on all local Java files.
- resgrep: Greps on all local res/*.xml files.
- godir:   Go to the directory containing a file.

Look at the source to view more functions. The complete list is:
EOF
    T=$(gettop)
    local A
    A=""
    for i in `cat $T/build/envsetup.sh | sed -n "/^function /s/function \([a-z_]*\).*/\1/p" | sort`; do
      A="$A $i"
    done
    echo $A
}

# Get the value of a build variable as an absolute path.
function get_abs_build_var()
{
    T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP." >&2
        return
    fi
    CALLED_FROM_SETUP=true BUILD_SYSTEM=build/core \
      make --no-print-directory -C "$T" -f build/core/config.mk dumpvar-abs-$1
}

# Get the exact value of a build variable.
function get_build_var()
{
    T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP." >&2
        return
    fi
    CALLED_FROM_SETUP=true BUILD_SYSTEM=build/core \
      make --no-print-directory -C "$T" -f build/core/config.mk dumpvar-$1
}

# check to see if the supplied product is one we can build
function check_product()
{
    T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP." >&2
        return
    fi
    CALLED_FROM_SETUP=true BUILD_SYSTEM=build/core \
        TARGET_PRODUCT=$1 TARGET_BUILD_VARIANT= \
        TARGET_SIMULATOR= TARGET_BUILD_TYPE= \
        TARGET_BUILD_APPS= \
        get_build_var TARGET_DEVICE > /dev/null
    # hide successful answers, but allow the errors to show
}

VARIANT_CHOICES=(user userdebug eng)

# check to see if the supplied variant is valid
function check_variant()
{
    for v in ${VARIANT_CHOICES[@]}
    do
        if [ "$v" = "$1" ]
        then
            return 0
        fi
    done
    return 1
}

function setpaths()
{
    T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP."
        return
    fi

    ##################################################################
    #                                                                #
    #              Read me before you modify this code               #
    #                                                                #
    #   This function sets ANDROID_BUILD_PATHS to what it is adding  #
    #   to PATH, and the next time it is run, it removes that from   #
    #   PATH.  This is required so lunch can be run more than once   #
    #   and still have working paths.                                #
    #                                                                #
    ##################################################################

    # out with the old
    if [ -n $ANDROID_BUILD_PATHS ] ; then
        export PATH=${PATH/$ANDROID_BUILD_PATHS/}
    fi

    # and in with the new
    CODE_REVIEWS=
    prebuiltdir=$(getprebuilt)
    export ANDROID_EABI_TOOLCHAIN=$prebuiltdir/toolchain/arm-eabi-4.4.0/bin
    export ANDROID_TOOLCHAIN=$ANDROID_EABI_TOOLCHAIN
    export ANDROID_QTOOLS=$T/development/emulator/qtools
    export ANDROID_BUILD_PATHS=:$(get_build_var ANDROID_BUILD_PATHS):$ANDROID_QTOOLS:$ANDROID_TOOLCHAIN:$ANDROID_EABI_TOOLCHAIN$CODE_REVIEWS
    export PATH=$PATH$ANDROID_BUILD_PATHS

    unset ANDROID_PRODUCT_OUT
    export ANDROID_PRODUCT_OUT=$(get_abs_build_var PRODUCT_OUT)
    export OUT=$ANDROID_PRODUCT_OUT
    unset ANDROID_REL_PRODUCT_OUT
    export ANDROID_REL_PRODUCT_OUT=${ANDROID_PRODUCT_OUT#$T/}

    unset TARGET_DEVICE
    export TARGET_DEVICE=$(get_build_var TARGET_DEVICE)

    # needed for building linux on MacOS
    # TODO: fix the path
    #export HOST_EXTRACFLAGS="-I "$T/system/kernel_headers/host_include

    # needed for OProfile to post-process collected samples
    export OPROFILE_EVENTS_DIR=$prebuiltdir/oprofile
}

function printconfig()
{
    T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP." >&2
        return
    fi
    get_build_var report_config
}

function set_stuff_for_environment()
{
    settitle
    setpaths
    set_sequence_number

    # Don't try to do preoptimization until it works better on OSX.
    export DISABLE_DEXPREOPT=true

    export ANDROID_BUILD_TOP=$(gettop)
}

function set_sequence_number()
{
    export BUILD_ENV_SEQUENCE_NUMBER=9
}

function settitle()
{
    if [ "$STAY_OFF_MY_LAWN" = "" ]; then
        local product=$TARGET_PRODUCT
        local variant=$TARGET_BUILD_VARIANT
        local apps=$TARGET_BUILD_APPS
        if [ -z "$apps" ]; then
            export PROMPT_COMMAND="echo -ne \"\033]0;[${product}-${variant}] ${USER}@${HOSTNAME}: ${PWD}\007\""
        else
            export PROMPT_COMMAND="echo -ne \"\033]0;[$apps $variant] ${USER}@${HOSTNAME}: ${PWD}\007\""
        fi
    fi
}

case `uname -s` in
    Linux)
        function choosesim()
        {
            echo "Build for the simulator or the device?"
            echo "     1. Device"
            echo "     2. Simulator"
            echo

            export TARGET_SIMULATOR=
            local ANSWER
            while [ -z $TARGET_SIMULATOR ]
            do
                echo -n "Which would you like? [1] "
                if [ -z "$1" ] ; then
                    read ANSWER
                else
                    echo $1
                    ANSWER=$1
                fi
                case $ANSWER in
                "")
                    export TARGET_SIMULATOR=false
                    ;;
                1)
                    export TARGET_SIMULATOR=false
                    ;;
                Device)
                    export TARGET_SIMULATOR=false
                    ;;
                2)
                    export TARGET_SIMULATOR=true
                    ;;
                Simulator)
                    export TARGET_SIMULATOR=true
                    ;;
                *)
                    echo
                    echo "I didn't understand your response.  Please try again."
                    echo
                    ;;
                esac
                if [ -n "$1" ] ; then
                    break
                fi
            done

            set_stuff_for_environment
        }
        ;;
    *)
        function choosesim()
        {
            echo "Only device builds are supported for" `uname -s`
            echo "     Forcing TARGET_SIMULATOR=false"
            echo
            if [ -z "$1" ]
            then
                echo -n "Press enter: "
                read
            fi

            export TARGET_SIMULATOR=false
            set_stuff_for_environment
        }
        ;;
esac

function choosetype()
{
    echo "Build type choices are:"
    echo "     1. release"
    echo "     2. debug"
    echo

    local DEFAULT_NUM DEFAULT_VALUE
    if [ $TARGET_SIMULATOR = "false" ] ; then
        DEFAULT_NUM=1
        DEFAULT_VALUE=release
    else
        DEFAULT_NUM=2
        DEFAULT_VALUE=debug
    fi

    export TARGET_BUILD_TYPE=
    local ANSWER
    while [ -z $TARGET_BUILD_TYPE ]
    do
        echo -n "Which would you like? ["$DEFAULT_NUM"] "
        if [ -z "$1" ] ; then
            read ANSWER
        else
            echo $1
            ANSWER=$1
        fi
        case $ANSWER in
        "")
            export TARGET_BUILD_TYPE=$DEFAULT_VALUE
            ;;
        1)
            export TARGET_BUILD_TYPE=release
            ;;
        release)
            export TARGET_BUILD_TYPE=release
            ;;
        2)
            export TARGET_BUILD_TYPE=debug
            ;;
        debug)
            export TARGET_BUILD_TYPE=debug
            ;;
        *)
            echo
            echo "I didn't understand your response.  Please try again."
            echo
            ;;
        esac
        if [ -n "$1" ] ; then
            break
        fi
    done

    set_stuff_for_environment
}

#
# This function isn't really right:  It chooses a TARGET_PRODUCT
# based on the list of boards.  Usually, that gets you something
# that kinda works with a generic product, but really, you should
# pick a product by name.
#
function chooseproduct()
{
    if [ "x$TARGET_PRODUCT" != x ] ; then
        default_value=$TARGET_PRODUCT
    else
        if [ "$TARGET_SIMULATOR" = true ] ; then
            default_value=sim
        else
            default_value=generic
        fi
    fi

    export TARGET_PRODUCT=
    local ANSWER
    while [ -z "$TARGET_PRODUCT" ]
    do
        echo -n "Which product would you like? [$default_value] "
        if [ -z "$1" ] ; then
            read ANSWER
        else
            echo $1
            ANSWER=$1
        fi

        if [ -z "$ANSWER" ] ; then
            export TARGET_PRODUCT=$default_value
        else
            if check_product $ANSWER
            then
                export TARGET_PRODUCT=$ANSWER
            else
                echo "** Not a valid product: $ANSWER"
            fi
        fi
        if [ -n "$1" ] ; then
            break
        fi
    done

    set_stuff_for_environment
}

function choosevariant()
{
    echo "Variant choices are:"
    local index=1
    local v
    for v in ${VARIANT_CHOICES[@]}
    do
        # The product name is the name of the directory containing
        # the makefile we found, above.
        echo "     $index. $v"
        index=$(($index+1))
    done

    local default_value=eng
    local ANSWER

    export TARGET_BUILD_VARIANT=
    while [ -z "$TARGET_BUILD_VARIANT" ]
    do
        echo -n "Which would you like? [$default_value] "
        if [ -z "$1" ] ; then
            read ANSWER
        else
            echo $1
            ANSWER=$1
        fi

        if [ -z "$ANSWER" ] ; then
            export TARGET_BUILD_VARIANT=$default_value
        elif (echo -n $ANSWER | grep -q -e "^[0-9][0-9]*$") ; then
            if [ "$ANSWER" -le "${#VARIANT_CHOICES[@]}" ] ; then
                export TARGET_BUILD_VARIANT=${VARIANT_CHOICES[$(($ANSWER-$_arrayoffset))]}
            fi
        else
            if check_variant $ANSWER
            then
                export TARGET_BUILD_VARIANT=$ANSWER
            else
                echo "** Not a valid variant: $ANSWER"
            fi
        fi
        if [ -n "$1" ] ; then
            break
        fi
    done
}

function choosecombo()
{
    choosesim $1

    echo
    echo
    choosetype $2

    echo
    echo
    chooseproduct $3

    echo
    echo
    choosevariant $4

    echo
    set_stuff_for_environment
    printconfig
}

# Clear this variable.  It will be built up again when the vendorsetup.sh
# files are included at the end of this file.
unset LUNCH_MENU_CHOICES
function add_lunch_combo()
{
    local new_combo=$1
    local c
    for c in ${LUNCH_MENU_CHOICES[@]} ; do
        if [ "$new_combo" = "$c" ] ; then
            return
        fi
    done
    LUNCH_MENU_CHOICES=(${LUNCH_MENU_CHOICES[@]} $new_combo)
}

# add the default one here
add_lunch_combo generic-eng

# if we're on linux, add the simulator.  There is a special case
# in lunch to deal with the simulator
if [ "$(uname)" = "Linux" ] ; then
    add_lunch_combo simulator
fi

function print_lunch_menu()
{
    local uname=$(uname)
    echo
    echo "You're building on" $uname
    echo
    echo "Lunch menu... pick a combo:"

    local i=1
    local choice
    for choice in ${LUNCH_MENU_CHOICES[@]}
    do
        echo "     $i. $choice"
        i=$(($i+1))
    done

    echo
}

function lunch()
{
    croot
    local answer
    if [ "$1" ] ; then
        answer=$1
    else
        print_lunch_menu
        echo -n "Which would you like? [generic-eng] "
        read answer
    fi

    local selection=

    if [ -z "$answer" ]
    then
        selection=generic-eng
    elif [ "$answer" = "simulator" ]
    then
        selection=simulator
    elif (echo -n $answer | grep -q -e "^[0-9][0-9]*$")
    then
        if [ $answer -le ${#LUNCH_MENU_CHOICES[@]} ]
        then
            selection=${LUNCH_MENU_CHOICES[$(($answer-$_arrayoffset))]}
        fi
    elif (echo -n $answer | grep -q -e "^[^\-][^\-]*-[^\-][^\-]*$")
    then
        selection=$answer
    fi

    if [ -z "$selection" ]
    then
        echo
        echo "Invalid lunch combo: $answer"
        return 1
    fi

    export TARGET_BUILD_APPS=

    # special case the simulator
    if [ "$selection" = "simulator" ]
    then
        export TARGET_PRODUCT=sim
        export TARGET_BUILD_VARIANT=eng
        export TARGET_SIMULATOR=true
        export TARGET_BUILD_TYPE=debug
    else
        local product=$(echo -n $selection | sed -e "s/-.*$//")
        check_product $product
        if [ $? -ne 0 ]
        then
            echo
            echo "** Don't have a product spec for: '$product'"
            echo "** Do you have the right repo manifest?"
            product=
        fi

        local variant=$(echo -n $selection | sed -e "s/^[^\-]*-//")
        check_variant $variant
        if [ $? -ne 0 ]
        then
            echo
            echo "** Invalid variant: '$variant'"
            echo "** Must be one of ${VARIANT_CHOICES[@]}"
            variant=
        fi

        if [ -z "$product" -o -z "$variant" ]
        then
            echo
            return 1
        fi

        export TARGET_PRODUCT=$product
        export TARGET_BUILD_VARIANT=$variant
        export TARGET_SIMULATOR=false
        export TARGET_BUILD_TYPE=release
    fi # !simulator

    echo

    set_stuff_for_environment
    printconfig
    create_im_links
}

unset ENVSETUP_SOURCED
ECHO="echo -e"

function warn() {
    $ECHO -n "\033[31;1m"
    $ECHO $@"\033[0m"
}
export ECHO
export -f warn

function get_process_cnt_for_build() {
    PROCESSOR_CNT=$(cat /proc/cpuinfo | grep "^processor" | wc -l)
    $ECHO $PROCESSOR_CNT
}
[ -z "$MAKEFLAGS" ] && MAKEFLAGS=-j$(get_process_cnt_for_build)
export MAKEFLAGS
warn "Do all the make with MAKEFLAGS=$MAKEFLAGS"

function prompt_for_confirm() {
    local user_confirm
    $ECHO -n "Are you sure to do the action? [y/n] default:[n] "
    [ "$NEED_CONFIRM" = 0 ] && { $ECHO y; return 0; } || read user_confirm
    [ x${user_confirm,,?} = xy ] && return 0 || return 1
}
export -f prompt_for_confirm

unset IM_DEVICE_NAME_LIST
IM_DEVICE_NAME_LIST=( iM9816 
                iM9828_evb_v1 
                iM9828_evb_v2 
                iM9828_evb_v3 
                iM9828_evb_v3_wvga)
export X_IM_DEVICE_NAME_LIST=$(printf '%q ' "${IM_DEVICE_NAME_LIST[@]}")

function get_dev_name_index() {
    local i=0
    local im_device_name
    for im_device_name in ${IM_DEVICE_NAME_LIST[@]}; do
        [ "$im_device_name" = "$1" ] && break
        i=$((i+1))
    done
    [ "${IM_DEVICE_NAME_LIST[$i]}" = "$1" ] && $ECHO $i || $ECHO "-1"
}
export -f get_dev_name_index

function chk_if_lunch_im() {
    $ECHO "$TARGET_DEVICE" | egrep -qi 'iM98.*_evb_v[0-9]'
    return $?
}

function chk_lunch_and_rerun() {
    chk_if_lunch_im || {
        warn "you did not select a infomax device. please select again!";
        lunch;
    }
    $ECHO -n "You've choosen device: ";  warn ${TARGET_DEVICE:-UNKNOWN_DEVICE}
    echo "ANDROID_PRODUCT_OUT = $ANDROID_PRODUCT_OUT"
    echo "ANDROID_REL_PRODUCT_OUT = $ANDROID_REL_PRODUCT_OUT"
}

function create_im_links() {
    warn "create links"
    croot
    chk_lunch_and_rerun
    #local IM_KERNEL_VERSION="kernel_3.0"
    #local IM_BAREBOX_VERSION="barebox_2010.10"
    ## for different kernel version
    #[ -e kernel -a ! -L kernel ] && { warn "kernel exists, but is not a symbolic link."; return; }
    #ln -sfT $IM_KERNEL_VERSION/ kernel
    #
    ## for different barebox version
    #[ -e barebox -a ! -L barebox ] && { warn "barebox exists, but is not a symbolic link."; return; }
    #ln -sfT $IM_BAREBOX_VERSION/ barebox

    INFOMAX_IMG_DIR=infomax_images
    export INFOMAX_IMG_DIR
    mkdir -p $ANDROID_PRODUCT_OUT || { warn "fail to create $ANDROID_PRODUCT_OUT"; return; }
    mkdir -p $INFOMAX_IMG_DIR
    local ANDROID_PRODUCT_IMGS=(boot.img recovery.img system.img userdata.img kernel barebox.bin)
    local img_name img_path
    for img_name in ${ANDROID_PRODUCT_IMGS[@]}
    do
        img_path=${ANDROID_REL_PRODUCT_OUT}/$img_name
        chmod 755 $img_path &>/dev/null
        ln -sfT ../$img_path $INFOMAX_IMG_DIR/${img_name}_$TARGET_DEVICE
    done
}

function bbarebox() {
    croot
    chk_lunch_and_rerun
    cd barebox
    [ $# = 0 ] && BUILD_OPTS=( ) || BUILD_OPTS=$@
    ./android_build_barebox.sh $BUILD_OPTS
    local ret=$?
    warn -n "Build ${FUNCNAME#b} "; [ $ret = 0 ] && warn "succeed" || warn "failed"
    cd ..
    return $ret
}

function fix_blcr(){
    croot
    cd external/$BLCR_VERSION
    ./run.sh
    cd ../../
}

function bkernel() {
    croot
    chk_lunch_and_rerun
    cd kernel
    [ $# = 0 ] && BUILD_OPTS=( ) || BUILD_OPTS=$@
    ./android_build_kernel.sh $BUILD_OPTS
    local ret=$?
    warn -n "Build ${FUNCNAME#b} "; [ $ret = 0 ] && warn "succeed" || warn "failed"
    cd ..
    return $ret
}

function bramdisk() {
    croot
    chk_lunch_and_rerun
    make $ANDROID_REL_PRODUCT_OUT/ramdisk.img
    local ret=$?
    warn -n "Build ${FUNCNAME#b} "; [ $ret = 0 ] && warn "succeed" || warn "failed"
}

#MKBOOTIMG=out/host/linux-x86/bin/mkbootimg

function bboot() {
    croot
    chk_lunch_and_rerun
    [ ! -e "$ANDROID_REL_PRODUCT_OUT/kernel" ] && { 
        warn "kernel isn't built yet. build now.";
        bkernel $@;
    }
    make $ANDROID_REL_PRODUCT_OUT/boot.img
    local ret=$?
    warn -n "Build ${FUNCNAME#b} "; [ $ret = 0 ] && warn "succeed" || warn "failed"
}

function bsystem() {
    croot
    chk_lunch_and_rerun
    fix_blcr
    NEED_CONFIRM=1
    for opt in $@; do [ "$opt" = "-y" ] && { NEED_CONFIRM=0; break; } done
    for opt in $@; do
        case $opt in
        -c) $ECHO "make clean, will delete out directory"
            #prompt_for_confirm && make clean
            prompt_for_confirm && echo "fake make clean" 
            shift
            ;;
        -y) shift
            ;;
        -h) warn "\nUsage: $opt, Available options are:\n" \
            "-y  say y to all confirmation\n" \
            "-c  make clean\n"
            return 1
            ;;
        esac
    done

    [ ! -e "$ANDROID_REL_PRODUCT_OUT/kernel" ] && { 
        warn "kernel isn't built yet. build now.";
        bkernel -y;
    }

    [ -d android_obj ] && sh -x build/rel_obj_put_back.sh
    schedtool -B -n 1 -e ionice -n 1 make $@
    local ret=$?
    warn -n "Build ${FUNCNAME#b} "; [ $ret = 0 ] && warn "succeed" || warn "failed"
    return $ret
}

function brecovery() {
    croot
    chk_lunch_and_rerun
    [ ! -e "$ANDROID_REL_PRODUCT_OUT/kernel" ] && { 
        warn "kernel isn't built yet. build now.";
        bkernel;
    }
    make $ANDROID_REL_PRODUCT_OUT/recovery.img
    local ret=$?
    warn -n "Build ${FUNCNAME#b} "; [ $ret = 0 ] && warn "succeed" || warn "failed"
}

function ball() {
    NEED_CONFIRM=1
    local CONFIRM_OPT
    for opt in $@; do
        case $opt in
        -y) NEED_CONFIRM=0
            CONFIRM_OPT="-y"
            ;;
        *)  warn "Unknown arguments $opt. only -y is available"
            return 1
            ;;
        esac
    done

    warn "This will clean all previous builds.\n" \
        "And will do a complete build then.\n" \
        "It will takes a long time."
    prompt_for_confirm &&
    bbarebox $CONFIRM_OPT -c -d &&
    bboot $CONFIRM_OPT -c -d &&
    bsystem $CONFIRM_OPT -c &&
    warn "All build is succeed!" ||
    warn "Some build is failed! Please check!"

}


export ENVSETUP_SOURCED=1

function mka() {
    schedtool -B -n 1 -e ionice -n 1 make -j `cat /proc/cpuinfo | grep "^processor" | wc -l` "$@"
}

unset INFOMAX_BRUNCH_MENU_CHOICES
INFOMAX_BRUNCH_MENU_CHOICES=(barebox boot recovery system all)
## specifi BLCR version to build
BLCR_VERSION="blcr-0.8.4"
function infomax_brunch()
{

    BOARD_LIST=( iM9816 iM9828_EVB_V1 iM9828_EVB_V2 iM9828_EVB_V3 iM9828_EVB_V3_WVGA)
    DEVICE_NAME_LIST=( iM9816 iM9828_evb_v1 iM9828_evb_v2 iM9828_evb_v3 iM9828_evb_v3_wvga)
    ANDROID_BOARD_LIST=( device/infomax/iM9816 device/infomax/iM9828_evb_v1 device/infomax/iM9828_evb_v2 device/infomax/iM9828_evb_v3 device/infomax/iM9828_evb_v3_wvga)
    ANDROID_SYSTEM_LIST=( generic_iM9816-eng generic_iM9828_evb_v1-eng generic_iM9828_evb_v2-eng generic_iM9828_evb_v3-eng generic_iM9828_evb_v3_wvga-eng)

    if [ "$2" ] ; then
        BOARD_NUMBER=$2
    else
        for element in $(seq 0 $((${#BOARD_LIST[@]} - 1)))
        do
            echo $element ${BOARD_LIST[$element]}
        done

        read -p "Which Board do you choice?" BOARD_NUMBER
    fi

    BOARD_TYPE=${BOARD_LIST[$BOARD_NUMBER]}
    DEVICE_NAME_TYPE=${DEVICE_NAME_LIST[$BOARD_NUMBER]}
    ANDROID_BOARD_TYPE=${ANDROID_BOARD_LIST[$BOARD_NUMBER]}
    ANDROID_SYSTEM_TYPE=${ANDROID_SYSTEM_LIST[$BOARD_NUMBER]}

    local selection
    if [ "$1" ] ; then
        selection=$1
    else
        echo
        echo "You're building Infomax Platform"
        echo
        echo "Infomax brunch menu:"

        local i=1
        local choice
        for choice in ${INFOMAX_BRUNCH_MENU_CHOICES[@]}
        do
            echo "     $i. $choice"
            i=$(($i+1))
        done

        echo
        echo -n "Which would you like? [all] "
        read selection
    fi

    if [ -z "$selection" ]
    then
        selection=all
    fi

    if [ -d infomax_images ]
    then
        echo "The folder, infomax_images, already exists."
    else
        mkdir infomax_images
    fi

    if [ "$selection" = barebox ]
    then
        echo "Build barebox"
        echo
        cd barebox/
        ./export_build.sh $BOARD_NUMBER
        if [ -e barebox.bin ]
        then
            cp barebox.bin ../infomax_images/barebox.bin_$DEVICE_NAME_TYPE
            echo "barebox.bin has been copied into infomax_images/."
        fi
        cd ../
    elif [ "$selection" = boot ]
    then
        echo "Build Linux Kernel"
        cd kernel/
        ./mkScript.sh $BOARD_NUMBER
        if [ -e arch/arm/boot/zImage ]
        then
            cp arch/arm/boot/zImage ../infomax_images/
            echo "arch/arm/boot/zImage has been copied into infomax_images/."
        fi
        ## ARKT for BLCR.b
        cd ../external/$BLCR_VERSION
        ./run.sh
        cd ../
        ## ARKT for BLCR.e
        cd ../
        echo "Create Boot Image"
        if [ ! -e infomax_images/zImage ]
        then
            echo "infomax_images/zImage does not exist."
            echo "Please build Linux kernel first."
            exit
        fi
        if [ ! -e out/target/product/$DEVICE_NAME_TYPE/ramdisk.img ]
        then
            echo "out/target/product/$DEVICE_NAME_TYPE/ramdisk.img does not exist."
            echo "Please build Android system first."
            echo
            echo "infomax_brunch system"
            echo
        fi
        if [ -e out/host/linux-x86/bin/mkbootimg ]
        then
            out/host/linux-x86/bin/mkbootimg --kernel infomax_images/zImage --ramdisk out/target/product/$DEVICE_NAME_TYPE/ramdisk.img --cmdline "no_console_suspend=1 console=null" --base 0x43800000 --output infomax_images/boot.img_$DEVICE_NAME_TYPE
            echo "boot.img_$DEVICE_NAME_TYPE has been created into infomax_images/."
        fi
    elif [ "$selection" = recovery ]
    then
        echo "Build Linux Kernel"
        cd kernel/
        ./mkScript.sh $BOARD_NUMBER
        if [ -e arch/arm/boot/zImage ]
        then
            cp arch/arm/boot/zImage ../infomax_images/
            echo "arch/arm/boot/zImage has been copied into infomax_images/."
        fi
        ## ARKT for BLCR.b
        cd ../external/$BLCR_VERSION
        ./run.sh
        cd ../
        ## ARKT for BLCR.e
        cd ../
        echo "Create Recovery Image"
        if [ ! -e infomax_images/zImage ]
        then
            echo "infomax_images/zImage does not exist."
            echo "Please build Linux kernel first."
            exit
        fi
        if [ ! -e out/target/product/$DEVICE_NAME_TYPE/ramdisk-recovery.img ]
        then
            echo "out/target/product/$DEVICE_NAME_TYPE/ramdisk-recovery.img does not exist."
            echo "Please build Android system first."
            echo
            echo "infomax_brunch system"
            echo
        fi
        if [ -e out/host/linux-x86/bin/mkbootimg ]
        then
            out/host/linux-x86/bin/mkbootimg --kernel infomax_images/zImage --ramdisk out/target/product/$DEVICE_NAME_TYPE/ramdisk-recovery.img --cmdline "no_console_suspend=1 console=null" --base 0x43800000 --output infomax_images/recovery.img_$DEVICE_NAME_TYPE
            echo "recovery.img_$DEVICE_NAME_TYPE has been created into infomax_images/."
        fi
    elif [ "$selection" = system ]
    then
        echo "Build Android"
        if [ ! -e device/infomax/$DEVICE_NAME_TYPE/kernel ]
        then
            echo "device/infomax/$DEVICE_NAME_TYPE/kernel does not exist."
            echo
            echo "Build Linux kernel first."
            echo
            echo "Build Linux Kernel..."
            cd kernel/
            ./mkScript.sh $BOARD_NUMBER all
            ## ARKT for BLCR.b
            cd ../external/$BLCR_VERSION
            ./run.sh
            cd ../
            ## ARKT for BLCR.e
            cd ../
        fi
        ## check if blcr is built
        if [ ! -e external/$BLCR_VERSION/include/blcr_common.h ]
        then
            echo ""
            echo ""
            echo "!!!!!!!!! BLCR header file not generated, built first.  !!!!!!"
            echo ""
            echo ""
            cd external/$BLCR_VERSION
            ./run.sh
            cd ../..
        fi
        lunch $ANDROID_SYSTEM_TYPE

        if [ -d android_obj ]; then
            sh -x build/rel_obj_put_back.sh
        fi

        mka
        if [ -e out/target/product/$DEVICE_NAME_TYPE/boot.img ]
        then
            cp out/target/product/$DEVICE_NAME_TYPE/boot.img infomax_images/boot.img_$DEVICE_NAME_TYPE
            echo "boot.img_$DEVICE_NAME_TYPE has been created into infomax_images/."
        fi
        if [ -e out/target/product/$DEVICE_NAME_TYPE/recovery.img ]
        then
            cp out/target/product/$DEVICE_NAME_TYPE/recovery.img infomax_images/recovery.img_$DEVICE_NAME_TYPE
            echo "recovery.img_$DEVICE_NAME_TYPE has been created into infomax_images/."
        fi
        if [ -e out/target/product/$DEVICE_NAME_TYPE/system.img ]
        then
            cp out/target/product/$DEVICE_NAME_TYPE/system.img infomax_images/system.img_$DEVICE_NAME_TYPE
            echo "system.img_$DEVICE_NAME_TYPE has been created into infomax_images/."
        fi
    elif [ "$selection" = all ]
    then
        echo "Build barebox"
        echo
        cd barebox/
        ./export_build.sh $BOARD_NUMBER all
        if [ -e barebox.bin ]
        then
            cp barebox.bin ../infomax_images/barebox.bin_$DEVICE_NAME_TYPE
            echo "barebox.bin has been copied into infomax_images/."
        fi
        cd ../
        echo "Build Linux Kernel"
        cd kernel/
        ./mkScript.sh $BOARD_NUMBER all
        ## ARKT for BLCR.b
        cd ../external/$BLCR_VERSION
        ./run.sh
        cd ../
        ## ARKT for BLCR.e
        cd ../
        echo "Build Android"
        lunch $ANDROID_SYSTEM_TYPE
        make clean

        if [ -d android_obj ]; then
            sh -x build/rel_obj_put_back.sh
        fi

        mka
        if [ -e out/target/product/$DEVICE_NAME_TYPE/boot.img ]
        then
            cp out/target/product/$DEVICE_NAME_TYPE/boot.img infomax_images/boot.img_$DEVICE_NAME_TYPE
            echo "boot.img_$DEVICE_NAME_TYPE has been created into infomax_images/."
        fi
        if [ -e out/target/product/$DEVICE_NAME_TYPE/recovery.img ]
        then
            cp out/target/product/$DEVICE_NAME_TYPE/recovery.img infomax_images/recovery.img_$DEVICE_NAME_TYPE
            echo "recovery.img_$DEVICE_NAME_TYPE has been created into infomax_images/."
        fi
        if [ -e out/target/product/$DEVICE_NAME_TYPE/system.img ]
        then
            cp out/target/product/$DEVICE_NAME_TYPE/system.img infomax_images/system.img_$DEVICE_NAME_TYPE
            echo "system.img_$DEVICE_NAME_TYPE has been created into infomax_images/."
        fi
    fi

}

# Configures the build to build unbundled apps.
# Run tapas with one ore more app names (from LOCAL_PACKAGE_NAME)
function tapas()
{
    local variant=$(echo -n $(echo $* | xargs -n 1 echo | grep -E '^(user|userdebug|eng)$'))
    local apps=$(echo -n $(echo $* | xargs -n 1 echo | grep -E -v '^(user|userdebug|eng)$'))

    if [ $(echo $variant | wc -w) -gt 1 ]; then
        echo "tapas: Error: Multiple build variants supplied: $variant"
        return
    fi
    if [ -z "$variant" ]; then
        variant=eng
    fi

    export TARGET_PRODUCT=generic
    export TARGET_BUILD_VARIANT=$variant
    export TARGET_SIMULATOR=false
    export TARGET_BUILD_TYPE=release
    export TARGET_BUILD_APPS=$apps

    set_stuff_for_environment
    printconfig
}

function gettop
{
    local TOPFILE=build/core/envsetup.mk
    if [ -n "$TOP" -a -f "$TOP/$TOPFILE" ] ; then
        echo $TOP
    else
        if [ -f $TOPFILE ] ; then
            # The following circumlocution (repeated below as well) ensures
            # that we record the true directory name and not one that is
            # faked up with symlink names.
            PWD= /bin/pwd
        else
            # We redirect cd to /dev/null in case it's aliased to
            # a command that prints something as a side-effect
            # (like pushd)
            local HERE=$PWD
            T=
            while [ \( ! \( -f $TOPFILE \) \) -a \( $PWD != "/" \) ]; do
                cd .. > /dev/null
                T=`PWD= /bin/pwd`
            done
            cd $HERE > /dev/null
            if [ -f "$T/$TOPFILE" ]; then
                echo $T
            fi
        fi
    fi
}

function m()
{
    T=$(gettop)
    if [ "$T" ]; then
        make -C $T $@
    else
        echo "Couldn't locate the top of the tree.  Try setting TOP."
    fi
}

function findmakefile()
{
    TOPFILE=build/core/envsetup.mk
    # We redirect cd to /dev/null in case it's aliased to
    # a command that prints something as a side-effect
    # (like pushd)
    local HERE=$PWD
    T=
    while [ \( ! \( -f $TOPFILE \) \) -a \( $PWD != "/" \) ]; do
        T=$PWD
        if [ -f "$T/Android.mk" ]; then
            echo $T/Android.mk
            cd $HERE > /dev/null
            return
        fi
        cd .. > /dev/null
    done
    cd $HERE > /dev/null
}

function mm()
{
    # If we're sitting in the root of the build tree, just do a
    # normal make.
    if [ -f build/core/envsetup.mk -a -f Makefile ]; then
        make $@
    else
        # Find the closest Android.mk file.
        T=$(gettop)
        local M=$(findmakefile)
        # Remove the path to top as the makefilepath needs to be relative
        local M=`echo $M|sed 's:'$T'/::'`
        if [ ! "$T" ]; then
            echo "Couldn't locate the top of the tree.  Try setting TOP."
        elif [ ! "$M" ]; then
            echo "Couldn't locate a makefile from the current directory."
        else
            ONE_SHOT_MAKEFILE=$M make -C $T files $@
        fi
    fi
}

function mmm()
{
    T=$(gettop)
    if [ "$T" ]; then
        local MAKEFILE=
        local ARGS=
        local DIR TO_CHOP
        local DASH_ARGS=$(echo "$@" | awk -v RS=" " -v ORS=" " '/^-.*$/')
        local DIRS=$(echo "$@" | awk -v RS=" " -v ORS=" " '/^[^-].*$/')
        for DIR in $DIRS ; do
            DIR=`echo $DIR | sed -e 's:/$::'`
            if [ -f $DIR/Android.mk ]; then
                TO_CHOP=`echo $T | wc -c | tr -d ' '`
                TO_CHOP=`expr $TO_CHOP + 1`
                START=`PWD= /bin/pwd`
                MFILE=`echo $START | cut -c${TO_CHOP}-`
                if [ "$MFILE" = "" ] ; then
                    MFILE=$DIR/Android.mk
                else
                    MFILE=$MFILE/$DIR/Android.mk
                fi
                MAKEFILE="$MAKEFILE $MFILE"
            else
                if [ "$DIR" = snod ]; then
                    ARGS="$ARGS snod"
                elif [ "$DIR" = showcommands ]; then
                    ARGS="$ARGS showcommands"
                else
                    echo "No Android.mk in $DIR."
                    return 1
                fi
            fi
        done
        ONE_SHOT_MAKEFILE="$MAKEFILE" make -C $T $DASH_ARGS files $ARGS
    else
        echo "Couldn't locate the top of the tree.  Try setting TOP."
    fi
}

function croot()
{
    T=$(gettop)
    if [ "$T" ]; then
        cd $(gettop)
    else
        echo "Couldn't locate the top of the tree.  Try setting TOP."
    fi
}

function cproj()
{
    TOPFILE=build/core/envsetup.mk
    # We redirect cd to /dev/null in case it's aliased to
    # a command that prints something as a side-effect
    # (like pushd)
    local HERE=$PWD
    T=
    while [ \( ! \( -f $TOPFILE \) \) -a \( $PWD != "/" \) ]; do
        T=$PWD
        if [ -f "$T/Android.mk" ]; then
            cd $T
            return
        fi
        cd .. > /dev/null
    done
    cd $HERE > /dev/null
    echo "can't find Android.mk"
}

function pid()
{
   local EXE="$1"
   if [ "$EXE" ] ; then
       local PID=`adb shell ps | fgrep $1 | sed -e 's/[^ ]* *\([0-9]*\).*/\1/'`
       echo "$PID"
   else
       echo "usage: pid name"
   fi
}

# systemstack - dump the current stack trace of all threads in the system process
# to the usual ANR traces file
function systemstack()
{
    adb shell echo '""' '>>' /data/anr/traces.txt && adb shell chmod 776 /data/anr/traces.txt && adb shell kill -3 $(pid system_server)
}

function gdbclient()
{
   local OUT_ROOT=$(get_abs_build_var PRODUCT_OUT)
   local OUT_SYMBOLS=$(get_abs_build_var TARGET_OUT_UNSTRIPPED)
   local OUT_SO_SYMBOLS=$(get_abs_build_var TARGET_OUT_SHARED_LIBRARIES_UNSTRIPPED)
   local OUT_EXE_SYMBOLS=$(get_abs_build_var TARGET_OUT_EXECUTABLES_UNSTRIPPED)
   local PREBUILTS=$(get_abs_build_var ANDROID_PREBUILTS)
   if [ "$OUT_ROOT" -a "$PREBUILTS" ]; then
       local EXE="$1"
       if [ "$EXE" ] ; then
           EXE=$1
       else
           EXE="app_process"
       fi

       local PORT="$2"
       if [ "$PORT" ] ; then
           PORT=$2
       else
           PORT=":5039"
       fi

       local PID
       local PROG="$3"
       if [ "$PROG" ] ; then
           PID=`pid $3`
           adb forward "tcp$PORT" "tcp$PORT"
           adb shell gdbserver $PORT --attach $PID &
           sleep 2
       else
               echo ""
               echo "If you haven't done so already, do this first on the device:"
               echo "    gdbserver $PORT /system/bin/$EXE"
                   echo " or"
               echo "    gdbserver $PORT --attach $PID"
               echo ""
       fi

       echo >|"$OUT_ROOT/gdbclient.cmds" "set solib-absolute-prefix $OUT_SYMBOLS"
       echo >>"$OUT_ROOT/gdbclient.cmds" "set solib-search-path $OUT_SO_SYMBOLS"
       echo >>"$OUT_ROOT/gdbclient.cmds" "target remote $PORT"
       echo >>"$OUT_ROOT/gdbclient.cmds" ""

       arm-eabi-gdb -x "$OUT_ROOT/gdbclient.cmds" "$OUT_EXE_SYMBOLS/$EXE"
  else
       echo "Unable to determine build system output dir."
   fi

}

case `uname -s` in
    Darwin)
        function sgrep()
        {
            find -E . -type f -iregex '.*\.(c|h|cpp|S|java|xml|sh|mk)' -print0 | xargs -0 grep --color -n "$@"
        }

        ;;
    *)
        function sgrep()
        {
            find . -type f -iregex '.*\.\(c\|h\|cpp\|S\|java\|xml\|sh\|mk\)' -print0 | xargs -0 grep --color -n "$@"
        }
        ;;
esac

function jgrep()
{
    find . -type f -name "*\.java" -print0 | xargs -0 grep --color -n "$@"
}

function cgrep()
{
    find . -type f \( -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o -name '*.h' \) -print0 | xargs -0 grep --color -n "$@"
}

function resgrep()
{
    for dir in `find . -name res -type d`; do find $dir -type f -name '*\.xml' -print0 | xargs -0 grep --color -n "$@"; done;
}

case `uname -s` in
    Darwin)
        function mgrep()
        {
            find -E . -type f -iregex '.*/(Makefile|Makefile\..*|.*\.make|.*\.mak|.*\.mk)' -print0 | xargs -0 grep --color -n "$@"
        }

        function treegrep()
        {
            find -E . -type f -iregex '.*\.(c|h|cpp|S|java|xml)' -print0 | xargs -0 grep --color -n -i "$@"
        }

        ;;
    *)
        function mgrep()
        {
            find . -regextype posix-egrep -iregex '(.*\/Makefile|.*\/Makefile\..*|.*\.make|.*\.mak|.*\.mk)' -type f -print0 | xargs -0 grep --color -n "$@"
        }

        function treegrep()
        {
            find . -regextype posix-egrep -iregex '.*\.(c|h|cpp|S|java|xml)' -type f -print0 | xargs -0 grep --color -n -i "$@"
        }

        ;;
esac

function getprebuilt
{
    get_abs_build_var ANDROID_PREBUILTS
}

function tracedmdump()
{
    T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP."
        return
    fi
    local prebuiltdir=$(getprebuilt)
    local KERNEL=$T/prebuilt/android-arm/kernel/vmlinux-qemu

    local TRACE=$1
    if [ ! "$TRACE" ] ; then
        echo "usage:  tracedmdump  tracename"
        return
    fi

    if [ ! -r "$KERNEL" ] ; then
        echo "Error: cannot find kernel: '$KERNEL'"
        return
    fi

    local BASETRACE=$(basename $TRACE)
    if [ "$BASETRACE" = "$TRACE" ] ; then
        TRACE=$ANDROID_PRODUCT_OUT/traces/$TRACE
    fi

    echo "post-processing traces..."
    rm -f $TRACE/qtrace.dexlist
    post_trace $TRACE
    if [ $? -ne 0 ]; then
        echo "***"
        echo "*** Error: malformed trace.  Did you remember to exit the emulator?"
        echo "***"
        return
    fi
    echo "generating dexlist output..."
    /bin/ls $ANDROID_PRODUCT_OUT/system/framework/*.jar $ANDROID_PRODUCT_OUT/system/app/*.apk $ANDROID_PRODUCT_OUT/data/app/*.apk 2>/dev/null | xargs dexlist > $TRACE/qtrace.dexlist
    echo "generating dmtrace data..."
    q2dm -r $ANDROID_PRODUCT_OUT/symbols $TRACE $KERNEL $TRACE/dmtrace || return
    echo "generating html file..."
    dmtracedump -h $TRACE/dmtrace >| $TRACE/dmtrace.html || return
    echo "done, see $TRACE/dmtrace.html for details"
    echo "or run:"
    echo "    traceview $TRACE/dmtrace"
}

# communicate with a running device or emulator, set up necessary state,
# and run the hat command.
function runhat()
{
    # process standard adb options
    local adbTarget=""
    if [ $1 = "-d" -o $1 = "-e" ]; then
        adbTarget=$1
        shift 1
    elif [ $1 = "-s" ]; then
        adbTarget="$1 $2"
        shift 2
    fi
    local adbOptions=${adbTarget}
    echo adbOptions = ${adbOptions}

    # runhat options
    local targetPid=$1
    local outputFile=$2

    if [ "$targetPid" = "" ]; then
        echo "Usage: runhat [ -d | -e | -s serial ] target-pid [output-file]"
        return
    fi

    # confirm hat is available
    if [ -z $(which hat) ]; then
        echo "hat is not available in this configuration."
        return
    fi

    adb ${adbOptions} shell >/dev/null mkdir /data/misc
    adb ${adbOptions} shell chmod 777 /data/misc

    # send a SIGUSR1 to cause the hprof dump
    echo "Poking $targetPid and waiting for data..."
    adb ${adbOptions} shell kill -10 $targetPid
    echo "Press enter when logcat shows \"hprof: heap dump completed\""
    echo -n "> "
    read

    local availFiles=( $(adb ${adbOptions} shell ls /data/misc | grep '^heap-dump' | sed -e 's/.*heap-dump-/heap-dump-/' | sort -r | tr '[:space:][:cntrl:]' ' ') )
    local devFile=/data/misc/${availFiles[0]}
    local localFile=/tmp/$$-hprof

    echo "Retrieving file $devFile..."
    adb ${adbOptions} pull $devFile $localFile

    adb ${adbOptions} shell rm $devFile

    echo "Running hat on $localFile"
    echo "View the output by pointing your browser at http://localhost:7000/"
    echo ""
    hat $localFile
}

function getbugreports()
{
    local reports=(`adb shell ls /sdcard/bugreports | tr -d '\r'`)

    if [ ! "$reports" ]; then
        echo "Could not locate any bugreports."
        return
    fi

    local report
    for report in ${reports[@]}
    do
        echo "/sdcard/bugreports/${report}"
        adb pull /sdcard/bugreports/${report} ${report}
        gunzip ${report}
    done
}

function startviewserver()
{
    local port=4939
    if [ $# -gt 0 ]; then
            port=$1
    fi
    adb shell service call window 1 i32 $port
}

function stopviewserver()
{
    adb shell service call window 2
}

function isviewserverstarted()
{
    adb shell service call window 3
}

function smoketest()
{
    if [ ! "$ANDROID_PRODUCT_OUT" ]; then
        echo "Couldn't locate output files.  Try running 'lunch' first." >&2
        return
    fi
    T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP." >&2
        return
    fi

    (cd "$T" && mmm tests/SmokeTest) &&
      adb uninstall com.android.smoketest > /dev/null &&
      adb uninstall com.android.smoketest.tests > /dev/null &&
      adb install $ANDROID_PRODUCT_OUT/data/app/SmokeTestApp.apk &&
      adb install $ANDROID_PRODUCT_OUT/data/app/SmokeTest.apk &&
      adb shell am instrument -w com.android.smoketest.tests/android.test.InstrumentationTestRunner
}

# simple shortcut to the runtest command
function runtest()
{
    T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP." >&2
        return
    fi
    ("$T"/development/testrunner/runtest.py $@)
}

function godir () {
    if [[ -z "$1" ]]; then
        echo "Usage: godir <regex>"
        return
    fi
    T=$(gettop)
    if [[ ! -f $T/filelist ]]; then
        echo -n "Creating index..."
        (cd $T; find . -wholename ./out -prune -o -wholename ./.repo -prune -o -type f > filelist)
        echo " Done"
        echo ""
    fi
    local lines
    lines=($(grep "$1" $T/filelist | sed -e 's/\/[^/]*$//' | sort | uniq)) 
    if [[ ${#lines[@]} = 0 ]]; then
        echo "Not found"
        return
    fi
    local pathname
    local choice
    if [[ ${#lines[@]} > 1 ]]; then
        while [[ -z "$pathname" ]]; do
            local index=1
            local line
            for line in ${lines[@]}; do
                printf "%6s %s\n" "[$index]" $line
                index=$(($index + 1)) 
            done
            echo
            echo -n "Select one: "
            unset choice
            read choice
            if [[ $choice -gt ${#lines[@]} || $choice -lt 1 ]]; then
                echo "Invalid choice"
                continue
            fi
            pathname=${lines[$(($choice-$_arrayoffset))]}
        done
    else
        # even though zsh arrays are 1-based, $foo[0] is an alias for $foo[1]
        pathname=${lines[0]}
    fi
    cd $T/$pathname
}

# Force JAVA_HOME to point to java 1.5 if it isn't already set
if [ "$STAY_OFF_MY_LAWN" = "" ]; then
    if [ ! "$JAVA_HOME" ]; then
        case `uname -s` in
            Darwin)
                export JAVA_HOME=/System/Library/Frameworks/JavaVM.framework/Versions/1.5/Home
                ;;
            *)
                export JAVA_HOME=/usr/lib/jvm/java-1.5.0-sun
                ;;
        esac
    fi
fi

# determine whether arrays are zero-based (bash) or one-based (zsh)
_xarray=(a b c)
if [ -z "${_xarray[${#_xarray[@]}]}" ]
then
    _arrayoffset=1
else
    _arrayoffset=0
fi
unset _xarray

croot
# Execute the contents of any vendorsetup.sh files we can find.
for f in `/bin/ls vendor/*/vendorsetup.sh vendor/*/build/vendorsetup.sh device/*/*/vendorsetup.sh 2> /dev/null`
do
    echo "including $f"
    . $f
done
unset f
cd -
