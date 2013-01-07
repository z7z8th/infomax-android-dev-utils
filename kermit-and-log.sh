#!/bin/sh

log_prefix=kermit
kerm_conf=`sed -r -e 's/^[[:space:]]*//; /^#/ d;' ~/.kermrc`
serialline=`echo "$kerm_conf" | grep -E '^[[:space:]]*set[[:space:]]+line' | grep -E -o '/dev/tty[[:alnum:]]+'`
baudrate=`echo "$kerm_conf" | grep -E '^[[:space:]]*set[[:space:]]+speed' | grep -E -o '[0-9]+'`

[ -z "$serialline" -o -z "$baudrate" ] && { echo "*** error: can not find serialline or baudrate in ~/.kermrc!"; exit 1; }

chng_kerm_conf() {
    [ -z "$1" -o -z "$2" ] && { echo "*** error: chng_kerm_conf(): need 2 params!"; exit 1; }
    kerm_conf=`echo "$kerm_conf" |  sed -r -e "s|(^set[[:space:]]+$1[[:space:]]+)(.*)|\1$2|"`
}

set -- $(getopt -u -o "l:b:s:" -- $@)
while [ $# -gt 0 ]; do
    case $1 in
        -l)
            serialline=/dev/$2; shift;
            chng_kerm_conf line $serialline
            ;;
        -b)
            baudrate=$2; shift;
            chng_kerm_conf speed $baudrate
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

[ ! -e "$serialline" ] && { 
    echo "*** note: $serialline does not exists, will find next available line for you!"
    serial_idx=`echo $serialline | grep -E -o '[0-9]+$'`; 
    serial_prefix=`echo $serialline | sed -r -e "s|$serial_idx\$||"`
    try_next_cnt=16
    max_try_idx=$((serial_idx+try_next_cnt))
    while [ "$serial_idx" -lt "$max_try_idx" ]; do
        [ -e "${serial_prefix}${serial_idx}" ] && break
        serial_idx=$((serial_idx+1))
    done
    [ x$serial_idx = x$max_try_idx ] && { echo "*** error: tried next $try_next_cnt serial line. but none exists!"; exit 1;}
    serialline=${serial_prefix}${serial_idx}
    chng_kerm_conf line $serialline
    echo "*** note: find $serialline for you!"
}

kerm_conf=`echo "$kerm_conf" | tr '\n' ','`

log_name=$log_prefix-${serialline##*/}-$baudrate-`date +%Y_%m_%d--%H_%M_%S`.log
ln -sfT "$log_name"  "$log_prefix-latest.log"

kerm_log_conf="log session '$log_name',c"
kerm_conf="${kerm_conf}${kerm_log_conf}"
echo "kerm_conf=$kerm_conf\n"
#return

kermit -Y -C "$kerm_conf"
