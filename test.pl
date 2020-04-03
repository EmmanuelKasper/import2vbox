#!/usr/bin/perl

use strict;
use warnings;
use feature 'say';

use Getopt::Long;
use Test::More tests => 4;

my $keep_vbox_vm;

GetOptions( 'keep' => \$keep_vbox_vm);

my $disk = $ARGV[0];

if ($disk && ! -f $disk){
die "usage: $0 [ --keep ] disk image" if ! -f $disk;
}


$disk = "ubuntu-18.04-minimal-cloudimg-amd64.img" if ! $disk;

if (! -f $disk) {
    system("wget https://cloud-images.ubuntu.com/minimal/releases/bionic/release/$disk");
}


my $vm_name = 'test_vm';

assert("./import2vbox.pl --vcpus 2 --memory 384 $disk --name $vm_name", 
    'successfull ovf generation');

assert("VBoxManage import ${vm_name}.ovf", "VBoxManage import ${vm_name}.ovf");
assert("ovftool --verifyOnly ${vm_name}.ovf", "ovftool --verifyOnly ${vm_name}.ovf");
open my $conf, "-|", "VBoxManage showvminfo $vm_name --machinereadable";
my $sata_port_count;
while (<$conf>) {
	if ($_ =~ m/^storagecontrollerportcount0="(.+)"$/) {
		$sata_port_count = $1;
    }
}

ok($sata_port_count == 1, "1 SATA port found");
done_testing();

system("VBoxManage unregistervm $vm_name --delete >/dev/null 2>&1") if !$keep_vbox_vm;
unlink "${vm_name}.ovf";
unlink "ubuntu-18.vmdk";

sub assert {
	my ($command, $description) = @_;
	my $rc = system("$command >/dev/null 2>&1");
	ok($rc == 0, $description);
}