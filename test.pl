#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;

my $keep_vbox_vm;

GetOptions( 'keep' => \$keep_vbox_vm);

my $disk = $ARGV[0];

if ($disk && ! -f $disk){
die "usage: $0 [ --keep ] disk image" if ! -f $disk;
}


$disk = "ubuntu-16.04-server-cloudimg-amd64-disk1.vmdk" if ! $disk;

if (! -f $disk) {
    system("wget https://cloud-images.ubuntu.com/releases/16.04/release/$disk");
}


my $vm_name = 'test_vm';

system("./import2vbox.pl --vcpus 2 --memory 384 $disk --name $vm_name");

#system("VBoxManage import --dry-run${vm_name}.ovf");
system("VBoxManage import ${vm_name}.ovf");
system("ovftool --verifyOnly ${vm_name}.ovf");
system("VBoxManage showvminfo $vm_name --machinereadable | grep storagecontrollerportcount0");
system("VBoxManage unregistervm $vm_name --delete") if !$keep_vbox_vm;

#unlink "${vm_name}.ovf";
