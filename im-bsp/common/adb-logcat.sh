#!/bin/sh

adb_bin=adb
log_prefix=$adb_bin

set -- $(getopt -u -o "a:s:" -- $@)
while [ $# -gt 0 ]; do
    case $1 in
        -a)
            adb_bin=$2; shift;
            ;;
        -s)
            session_name=$2; shift;
            log_prefix=$session_name-$log_prefix;
            ;;
        *)
            #echo "error opt"
            ;;
    esac
    shift
done


log_name=$log_prefix-`date +%Y_%m_%d--%H_%M_%S`.log
ln -sfT $log_name  $log_prefix-latest.log

$adb_bin logcat -v time 2>&1 | tee $log_name
