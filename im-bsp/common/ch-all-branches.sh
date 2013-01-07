#!/bin/sh

BSP_BRANCH='BSP13_ICS'

case $1 in
    list)
        repo forall -c "git branch | grep -q dev && git branch && pwd && echo "
        ;;
    showtmp)
        repo forall -c "git branch | grep -q tmp && git branch && pwd && echo "
        ;;
    dev)
        repo forall -c "git branch | grep -q dev && pwd && git checkout dev && echo"
        ;;
    syncdev)
        repo forall -c "git br |grep -q dev && pwd && git co $BSP_BRANCH && repo sync -c . && git co dev && git rebase $BSP_BRANCH && echo "
        ;;
    bsp)
        repo forall -c "git branch | grep -q '^  $BSP_BRANCH' && pwd && git checkout $BSP_BRANCH && echo || echo 'checkout $BSP_BRANCH, already on or not found'"
        ;;
        *)
        echo "unknown command";
        break;
esac

