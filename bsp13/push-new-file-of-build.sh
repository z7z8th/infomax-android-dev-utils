adb remount
find out/target/product/iM9828_evb_v3 -newer out/target/product/iM9828_evb_v3/system.img |tee new-files.lst | grep -v -E '_v3\/obj|\.mk$|_v3\/symbol' | while read line; do [ -d "$line" ] && continue; echo ${line#*_v3}; adb push $line ${line#*_v3}; done
