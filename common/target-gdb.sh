#!/bin/sh

[ "$#" -lt 2 ] && { echo "need arguement, \$1:process_name, \$2:symbols_root_dir"; exit 1; }
[ ! -e "$2" ] && { echo "symbols_root_dir $2 doesn't exists!"; exit 2; }

pname=$1
pid=`adb shell ps | grep $pname | head -n 1 | awk '{print $2}'`
port=12345
echo "target process: $pname, pid: $pid"
echo "start target gdbserver"
adb shell gdbserver :$port --attach $pid &

echo "forward port from target, port=$port"
adb forward tcp:$port tcp:$port

sleep 3s


cat >gdb-cmds <<EOF
set solib-absolute-prefix $2
set solib-search-path $2/system/lib/
target remote :12345
info shared
EOF

echo "start arm-eabi-gdb"
arm-eabi-gdb -x gdb-cmds $2/system/bin/$1
