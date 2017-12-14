#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;

my $keep_vbox_vm;

GetOptions("keep"=> \$keep_vbox_vm);

my $disk = $ARGV[0];

die "usage: $0 [ --keep ] disk image" if !$disk;

my $vm_name = 'test_vm';

system("./import2vbox.pl --vcpus 2 --memory 384 $disk --name $vm_name");

#system("VBoxManage import --dry-run${vm_name}.ovf");
system("VBoxManage import ${vm_name}.ovf");
system("ovftool --verifyOnly ${vm_name}.ovf");
system("VBoxManage showvminfo $vm_name --machinereadable | grep storagecontrollerportcount0");
system("VBoxManage unregistervm $vm_name --delete") if !$keep_vbox_vm;

