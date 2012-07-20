
DEX_PREOPT=dalvik/tools/dex-preopt
AAPT=out/host/linux-x86/bin/aapt
ZIPALIGN=out/host/linux-x86/bin/zipalign
ACP=out/host/linux-x86/bin/acp

DEVICE_TYPE=iM9828_evb_v3
PRODUCT_OUT_DIR=out/target/product/$DEVICE_TYPE
OBJ_APPS_DIR=$PRODUCT_OUT_DIR/obj/APPS
SYSTEM_APP_DIR=$PRODUCT_OUT_DIR/system/app

croot
#echo "OBJ_APPS_DIR=$OBJ_APPS_DIR"
find $OBJ_APPS_DIR/ -name 'package.apk.unsigned' | while read UNSIGNED_APK_PATH;
do
    #echo "UNSIGNED_APK_PATH=$UNSIGNED_APK_PATH"
    [ -z "${UNSIGNED_APK_PATH##*res_intermediates*}" ] && {
        echo "res_intermediates, skip"; continue;
    }
    [ -z "${APK_NAME##*FrameworkCoreTests*}" ] && {
        echo "FrameworkCoreTests*, skip"; continue;
    }
    APK_NAME=${UNSIGNED_APK_PATH#${OBJ_APPS_DIR}/}
    APK_NAME=${APK_NAME%_intermediates/package.apk.unsigned}
    echo "APK_NAME=$APK_NAME"
    APK_PATH=${UNSIGNED_APK_PATH%.unsigned}
    ODEX_PATH=${APK_PATH%.apk}.odex
    FINAL_APK_PATH=$SYSTEM_APP_DIR/$APK_NAME.apk
    FINAL_ODEX_PATH=$SYSTEM_APP_DIR/$APK_NAME.odex
    SIGNED_APK_PATH=$APK_PATH.signed
    UNALIGNED_APK_PATH=$APK_PATH.unaligned
    ALIGNED_APK_PATH=$APK_PATH.aligned
    echo "APK_PATH=$APK_PATH"
    java -jar out/host/linux-x86/framework/signapk.jar build/target/product/security/platform.x509.pem build/target/product/security/platform.pk8 $UNSIGNED_APK_PATH  $SIGNED_APK_PATH
    mv $SIGNED_APK_PATH $APK_PATH
    mv $APK_PATH $UNALIGNED_APK_PATH
    $ZIPALIGN -f 4 $UNALIGNED_APK_PATH $ALIGNED_APK_PATH
    mv $ALIGNED_APK_PATH $APK_PATH

    rm -f $ODEX_PATH
    $DEX_PREOPT --dexopt=host/linux-x86/bin/dexopt --build-dir=out --product-dir=target/product/iM9828_evb_v3/dex_bootjars --boot-dir=system/framework --boot-jars=core:core-junit:bouncycastle:ext:framework:android.policy:services:apache-xml:filterfw --uniprocessor ${APK_PATH#out/} ${ODEX_PATH#out/}
    $AAPT remove $APK_PATH classes.dex
    $ACP -fp $ODEX_PATH $FINAL_ODEX_PATH
    $ACP -fp $APK_PATH  $FINAL_APK_PATH
    echo
done
