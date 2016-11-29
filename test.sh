#!/bin/sh

./import2vbox.pl source.vmdk
VBoxManage import source.ovf
VBoxManage showvminfo source | sed 1q
VBoxManage unregistervm source --delete
