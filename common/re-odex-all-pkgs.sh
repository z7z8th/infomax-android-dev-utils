
echo "=====================================start reodex======================="

DEX_PREOPT=dalvik/tools/dex-preopt
AAPT=out/host/linux-x86/bin/aapt
ZIPALIGN=out/host/linux-x86/bin/zipalign
ACP=out/host/linux-x86/bin/acp

DEVICE_TYPE=iM9828_evb_v3
PRODUCT_OUT_DIR=out/target/product/$DEVICE_TYPE
OBJ_APPS_DIR=$PRODUCT_OUT_DIR/obj/APPS
SYSTEM_APP_DIR=$PRODUCT_OUT_DIR/system/app

COMMON_OUT_DIR=out/target/common
COMMON_JAVALIB_OUT_DIR=$COMMON_OUT_DIR/obj/JAVA_LIBRARIES
PRODUCT_DEX_BOOTJARS_OUT_DIR=$PRODUCT_OUT_DIR/dex_bootjars/system/framework
PRODUCT_JAVALIB_OUT_DIR=$PRODUCT_OUT_DIR/obj/JAVA_LIBRARIES

function reodex_framework_components() {
    #FRAMEWORK_COMPONENTS='core:core-junit:bouncycastle:ext:framework:android.policy:services:apache-xml:filterfw:android.test.runner:com.android.location.provider:javax.obex'
    FRAMEWORK_COMPONENTS='
    core
    core-junit
    bouncycastle
    ext
    framework
    android.policy
    services
    apache-xml
    filterfw
    android.test.runner
    com.android.location.provider
    javax.obex
    bu
    am
    bmgr
    ime
    input
    monkey
    pm
    svc'

    #FRAMEWORK_COMPONENTS=`echo $FRAMEWORK_COMPONENTS | sed -e 's/:/ /g'`
    for COMPONENT in $FRAMEWORK_COMPONENTS;
    do
        echo "COMPONENT=$COMPONENT"
        COMMON_JAVALIB_JAR_PATH=$COMMON_JAVALIB_OUT_DIR/${COMPONENT}_intermediates/javalib.jar
        PRODUCT_DEX_BOOTJARS_NODEX_JAR_PATH=$PRODUCT_DEX_BOOTJARS_OUT_DIR/${COMPONENT}_nodex.jar
        PRODUCT_DEX_BOOTJARS_JAR_PATH=$PRODUCT_DEX_BOOTJARS_OUT_DIR/${COMPONENT}.jar
        PRODUCT_DEX_BOOTJARS_ODEX_PATH=$PRODUCT_DEX_BOOTJARS_OUT_DIR/${COMPONENT}.odex

        PRODUCT_JAVALIB_DIR=$PRODUCT_JAVALIB_OUT_DIR/${COMPONENT}_intermediates
        PRODUCT_JAVALIB_JAR_PATH=$PRODUCT_JAVALIB_DIR/javalib.jar
        PRODUCT_JAVALIB_ODEX_PATH=$PRODUCT_JAVALIB_DIR/javalib.odex

        FINAL_JAR_PATH=$PRODUCT_OUT_DIR/system/framework/$COMPONENT.jar
        FINAL_ODEX_PATH=$PRODUCT_OUT_DIR/system/framework/$COMPONENT.odex

        $ACP -fp $COMMON_JAVALIB_JAR_PATH $PRODUCT_DEX_BOOTJARS_NODEX_JAR_PATH
        $AAPT remove $PRODUCT_DEX_BOOTJARS_NODEX_JAR_PATH classes.dex
        $ACP -fp $PRODUCT_DEX_BOOTJARS_NODEX_JAR_PATH $PRODUCT_JAVALIB_JAR_PATH
        rm -rf $PRODUCT_DEX_BOOTJARS_ODEX_PATH
        $ACP -fp $COMMON_JAVALIB_JAR_PATH $PRODUCT_DEX_BOOTJARS_JAR_PATH
        $DEX_PREOPT --dexopt=host/linux-x86/bin/dexopt --build-dir=out --product-dir=target/product/$DEVICE_TYPE/dex_bootjars --boot-dir=system/framework --boot-jars=core:core-junit:bouncycastle:ext:framework:android.policy:services:apache-xml:filterfw --uniprocessor ${PRODUCT_DEX_BOOTJARS_JAR_PATH#out/} ${PRODUCT_DEX_BOOTJARS_ODEX_PATH#out/}
        $ACP -fp $PRODUCT_DEX_BOOTJARS_ODEX_PATH $PRODUCT_JAVALIB_ODEX_PATH
        $ACP -fp $PRODUCT_JAVALIB_ODEX_PATH $FINAL_ODEX_PATH
        $ACP -fp $PRODUCT_JAVALIB_JAR_PATH  $FINAL_JAR_PATH
    done
}


function reodex_system_apps() {
    #echo "OBJ_APPS_DIR=$OBJ_APPS_DIR"
    SYSTEM_APP_LIST='
    ApplicationsProvider:shared.x509.pem:shared.pk8
    BackupRestoreConfirmation
    Bluetooth
    Browser
    Calculator
    Calendar
    CalendarProvider:testkey.x509.pem:testkey.pk8
    Camera
    CertInstaller
    Contacts:shared.x509.pem:shared.pk8
    ContactsProvider:shared.x509.pem:shared.pk8
    DefaultContainerService
    DeskClock
    Development
    DownloadProvider:media.x509.pem:media.pk8
    DownloadProviderUi:media.x509.pem:media.pk8
    DrmProvider:media.x509.pem:media.pk8
    Email
    Exchange
    Gallery2
    HTMLViewer
    KeyChain
    LatinIME
    Launcher2
    MediaProvider:media.x509.pem:media.pk8
    Mms
    Music
    MusicFX
    PackageInstaller
    Phone
    PicoTts
    Provision
    QuickSearchBox
    Settings
    SettingsProvider
    SharedStorageBackup
    SoundRecorder
    SpeechRecorder
    SystemUI
    TelephonyProvider
    UserDictionaryProvider:shared.x509.pem:shared.pk8
    VpnDialogs
    '

    #find $OBJ_APPS_DIR/ -name 'package.apk.unsigned' | while read UNSIGNED_APK_PATH;
    for APK_ITEM in $SYSTEM_APP_LIST;
    do
        echo 
        APK_NAME=`echo $APK_ITEM | cut -d : -f 1`
        echo $APK_ITEM | grep -q ':' && {
            PEM_FILE=`echo $APK_ITEM | cut -d : -f 2`;
            PK8_FILE=`echo $APK_ITEM | cut -d : -f 3`;
        } || {
            PEM_FILE=platform.x509.pem
            PK8_FILE=platform.pk8
        }
        echo "APK_NAME=$APK_NAME"
        echo "PEM_FILE=$PEM_FILE"
        echo "PK8_FILE=$PK8_FILE"

        INTERMEDIATES_APK_DIR=$OBJ_APPS_DIR/${APK_NAME}_intermediates
        UNSIGNED_APK_PATH=$INTERMEDIATES_APK_DIR/package.apk.unsigned
        APK_PATH=$INTERMEDIATES_APK_DIR/package.apk
        ODEX_PATH=$INTERMEDIATES_APK_DIR/package.odex
        SIGNED_APK_PATH=$APK_PATH.signed
        UNALIGNED_APK_PATH=$APK_PATH.unaligned
        ALIGNED_APK_PATH=$APK_PATH.aligned

        FINAL_APK_PATH=$SYSTEM_APP_DIR/$APK_NAME.apk
        FINAL_ODEX_PATH=$SYSTEM_APP_DIR/$APK_NAME.odex

        echo "APK_PATH=$APK_PATH"
        java -jar out/host/linux-x86/framework/signapk.jar build/target/product/security/${PEM_FILE} build/target/product/security/${PK8_FILE} $UNSIGNED_APK_PATH  $SIGNED_APK_PATH
        mv $SIGNED_APK_PATH $APK_PATH
        mv $APK_PATH $UNALIGNED_APK_PATH
        $ZIPALIGN -f 4 $UNALIGNED_APK_PATH $ALIGNED_APK_PATH
        mv $ALIGNED_APK_PATH $APK_PATH

        rm -f $ODEX_PATH
        $DEX_PREOPT --dexopt=host/linux-x86/bin/dexopt --build-dir=out --product-dir=target/product/$DEVICE_TYPE/dex_bootjars --boot-dir=system/framework --boot-jars=core:core-junit:bouncycastle:ext:framework:android.policy:services:apache-xml:filterfw --uniprocessor ${APK_PATH#out/} ${ODEX_PATH#out/}
        $AAPT remove $APK_PATH classes.dex
        $ACP -fp $ODEX_PATH $FINAL_ODEX_PATH
        $ACP -fp $APK_PATH  $FINAL_APK_PATH
    done
}

croot
read -p "====== reodex framework jars [y/n]?? " confirm
[ x$confirm = xy ] && reodex_framework_components

read -p "====== reodex app apks [y/n]?? " confirm
[ x$confirm = xy ] && reodex_system_apps

