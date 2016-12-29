#!/bin/sh
set -e
set -x

if ! [ $1 ] ; then
    echo "usage: $0 raw disk image"
    exit 1
fi

shortname=$(echo $1 | sed 's/\..*$//')

./import2vbox.pl --vcpus 2 --memory 384 $1
#VBoxManage import --dry-run ${shortname}.ovf
VBoxManage import ${shortname}.ovf
ovftool --verifyOnly ${shortname}.ovf
VBoxManage showvminfo $shortname --machinereadable | grep storagecontrollerportcount0
VBoxManage unregistervm $shortname --delete
