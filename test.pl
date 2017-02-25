#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;

my $keep_vbox_vm;

GetOptions("keep"=> \$keep_vbox_vm);

my $disk = $ARGV[0];

die "usage: $0 [ --keep ] disk image" if !$disk;

my ($shortname, $extension) = split/\./, $disk;

system("./import2vbox.pl --vcpus 2 --memory 384 $disk");

#system("VBoxManage import --dry-run${shortname}.ovf");
system("VBoxManage import ${shortname}.ovf");
system("ovftool --verifyOnly ${shortname}.ovf");
system("VBoxManage showvminfo $shortname --machinereadable | grep storagecontrollerportcount0");
system("VBoxManage unregistervm $shortname --delete") if !$keep_vbox_vm;

