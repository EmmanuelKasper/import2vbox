#!/bin/sh
set -e
set -x

if ! [ $1 ] ; then
    echo "usage: $0 raw disk image"
    exit 1
fi

shortname=$(echo $1 | sed 's/\..*$//')

./import2vbox.pl ${shortname}.raw
VBoxManage import ${shortname}.ovf
VBoxManage showvminfo $shortname | sed 1q
#VBoxManage unregistervm $shortname --delete
