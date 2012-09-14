#!/bin/sh

pname=system_server
pid=`adb shell ps | grep $pname | awk '{print $2}'`
port=12345
echo "target process: $pname, pid: $pid"
echo "start target gdbserver"
adb shell gdbserver :$port --attach $pid &

echo "forward port from target, port=$port"
adb forward tcp:$port tcp:$port

sleep 3s

cat >gdb-cmds <<EOF
set solib-absolute-prefix /opt/a2-symbols/
set solib-search-path /opt/a2-symbols/system/lib/
target remote :12345
info shared
EOF

echo "start arm-eabi-gdb"
arm-eabi-gdb -x gdb-cmds iM98xx_evb_v3/symbols/system/bin/app_process
