z7z8th@z7z8th-pc { /opt/android4.0 }
$ mmm frameworks/base/packages/SettingsProvider/
#============================================
PLATFORM_VERSION_CODENAME=REL
PLATFORM_VERSION=4.0.3
TARGET_PRODUCT=full_iM9828_evb_v3
TARGET_BUILD_VARIANT=eng
TARGET_BUILD_TYPE=release
TARGET_BUILD_APPS=
TARGET_ARCH=arm
TARGET_ARCH_VARIANT=armv5te
HOST_ARCH=x86
HOST_OS=linux
HOST_BUILD_TYPE=release
BUILD_ID=IML74K
#============================================
No private recovery resources for TARGET_DEVICE iM9828_evb_v3
No recovery.fstab for TARGET_DEVICE iM9828_evb_v3
#make: Entering directory `/opt/android4.0'
echo "target Package: SettingsProvider (out/target/product/iM9828_evb_v3/obj/APPS/SettingsProvider_intermediates/package.apk)"

mkdir -p out/target/product/iM9828_evb_v3/obj/APPS/SettingsProvider_intermediates/
touch out/target/product/iM9828_evb_v3/obj/APPS/SettingsProvider_intermediates//dummy
(cd out/target/product/iM9828_evb_v3/obj/APPS/SettingsProvider_intermediates/ && jar cf package.apk dummy)
zip -qd out/target/product/iM9828_evb_v3/obj/APPS/SettingsProvider_intermediates/package.apk dummy
rm out/target/product/iM9828_evb_v3/obj/APPS/SettingsProvider_intermediates//dummy
out/host/linux-x86/bin/aapt package -u  -z -c en_US,en_GB,fr_FR,it_IT,de_DE,es_ES,mdpi,nodpi  -M frameworks/base/packages/SettingsProvider/AndroidManifest.xml -S frameworks/base/packages/SettingsProvider/res  -I out/target/common/obj/APPS/framework-res_intermediates/package-export.apk --min-sdk-version 15 --target-sdk-version 15 --product default --version-code 15 --version-name 4.0.3-eng.z7z8th.20120719.194447   -F out/target/product/iM9828_evb_v3/obj/APPS/SettingsProvider_intermediates/package.apk

_adtp_classes_dex=out/target/common/obj/APPS/SettingsProvider_intermediates/classes.dex; cp out/target/common/obj/APPS/SettingsProvider_intermediates/noproguard.classes.dex $_adtp_classes_dex && out/host/linux-x86/bin/aapt add -k out/target/product/iM9828_evb_v3/obj/APPS/SettingsProvider_intermediates/package.apk $_adtp_classes_dex && rm -f $_adtp_classes_dex

# sign apk
mv out/target/product/iM9828_evb_v3/obj/APPS/SettingsProvider_intermediates/package.apk out/target/product/iM9828_evb_v3/obj/APPS/SettingsProvider_intermediates/package.apk.unsigned
java -jar out/host/linux-x86/framework/signapk.jar build/target/product/security/platform.x509.pem build/target/product/security/platform.pk8 out/target/product/iM9828_evb_v3/obj/APPS/SettingsProvider_intermediates/package.apk.unsigned out/target/product/iM9828_evb_v3/obj/APPS/SettingsProvider_intermediates/package.apk.signed
# move .apk.signed to .apk
mv out/target/product/iM9828_evb_v3/obj/APPS/SettingsProvider_intermediates/package.apk.signed out/target/product/iM9828_evb_v3/obj/APPS/SettingsProvider_intermediates/package.apk
# Alignment must happen after all other zip operations.
# move .apk to .apk.unaligned
mv out/target/product/iM9828_evb_v3/obj/APPS/SettingsProvider_intermediates/package.apk out/target/product/iM9828_evb_v3/obj/APPS/SettingsProvider_intermediates/package.apk.unaligned
# align .apk.unaligned, gen apk.aligned
out/host/linux-x86/bin/zipalign -f 4 out/target/product/iM9828_evb_v3/obj/APPS/SettingsProvider_intermediates/package.apk.unaligned out/target/product/iM9828_evb_v3/obj/APPS/SettingsProvider_intermediates/package.apk.aligned
# move apk.aligned to .apk
mv out/target/product/iM9828_evb_v3/obj/APPS/SettingsProvider_intermediates/package.apk.aligned out/target/product/iM9828_evb_v3/obj/APPS/SettingsProvider_intermediates/package.apk

# remove .odex
rm -f out/target/product/iM9828_evb_v3/obj/APPS/SettingsProvider_intermediates/package.odex
# gen .odex from .apk
dalvik/tools/dex-preopt --dexopt=host/linux-x86/bin/dexopt --build-dir=out --product-dir=target/product/iM9828_evb_v3/dex_bootjars --boot-dir=system/framework --boot-jars=core:core-junit:bouncycastle:ext:framework:android.policy:services:apache-xml:filterfw --uniprocessor target/product/iM9828_evb_v3/obj/APPS/SettingsProvider_intermediates/package.apk target/product/iM9828_evb_v3/obj/APPS/SettingsProvider_intermediates/package.odex
# remove classes.dex from .apk
out/host/linux-x86/bin/aapt remove out/target/product/iM9828_evb_v3/obj/APPS/SettingsProvider_intermediates/package.apk classes.dex

# copy .odex .apk to system/app/
echo "Install: out/target/product/iM9828_evb_v3/system/app/SettingsProvider.odex"
mkdir -p out/target/product/iM9828_evb_v3/system/app/
out/host/linux-x86/bin/acp -fp out/target/product/iM9828_evb_v3/obj/APPS/SettingsProvider_intermediates/package.odex out/target/product/iM9828_evb_v3/system/app/SettingsProvider.odex
echo "Install: out/target/product/iM9828_evb_v3/system/app/SettingsProvider.apk"
mkdir -p out/target/product/iM9828_evb_v3/system/app/
out/host/linux-x86/bin/acp -fp out/target/product/iM9828_evb_v3/obj/APPS/SettingsProvider_intermediates/package.apk out/target/product/iM9828_evb_v3/system/app/SettingsProvider.apk
#make: Leaving directory `/opt/android4.0'
z7z8th@z7z8th-pc { /opt/android4.0 }

$ ls SettingsProvider_intermediates/
package.apk  package.apk.unaligned  package.apk.unsigned  package.odex
