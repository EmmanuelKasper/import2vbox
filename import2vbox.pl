#!/usr/bin/perl -w
# Copyright (C) 2015 Richard W.M. Jones <rjones@redhat.com>
# Copyright (C) 2015 Red Hat Inc.
# Copyright (C) 2016 Emmanuel Kasper <emmanuel@libera.cc>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use warnings;
use strict;
use English;

use Pod::Usage;
use Getopt::Long;
use File::Temp qw(tempdir);
use POSIX qw(_exit setgid setuid strftime);
use XML::Writer;
use Cwd;

use Sys::Guestfs;

=head1 NAME

import2vbox - Import virtual machine disk image to VirtualBox

=head1 SYNOPSIS

 ./import2vbox.pl disk.vmdk

=head1 IMPORTANT NOTES

This is a command line script for generating a OVF file from a vmdk disk image,
so that disk image(s) and OVF can be imported in VirtualBox.
The script assumes that the guest already has drivers for a SATA controller
and an Intel PRO/1000 MT Desktop (82540EM), because this is what will be presented to the VM.

=head2 Basic usage

Basic usage is just:

 ./import2vbox.pl [list of disks] 

The list of disks should all belong to a single guest (most guests
will only have a single disk).  If you want to import multiple guests,
you must run the script multiple times.

=head2 Network card and disk model

This scripts adds an Intel E1000 MT Desktop network card and a SATA disk controller
to the hardware of the virtual machine. Popular OSes released after 2003
should all include drivers for this hardware.

=head1 OPTIONS

=over 4

=cut

my $help;

=item B<--help>

Display brief help and exit.

=cut

my $man;

=item B<--man>

Display the manual page and exit.

=cut

my $memory_mb = 1024;

=item B<--memory> MB

Set the memory size I<in megabytes>.  The default is 1024.

=cut

my $name;

=item B<--name> name

Set the guest name.  If not present, a name is made up based on
the filename of the first disk.

=cut

my $vcpus = 1;

=item B<--vcpus> N

Set the number of virtual CPUs.  The default is 1.

=cut

my $vmtype = "Desktop";

=item B<--vmtype> Desktop

=item B<--vmtype> Server

Set the VmType field in the OVF.  It must be C<Desktop> or
C<Server>.  The default is C<Desktop>.

=cut

=back

=cut

$| = 1;

GetOptions ("help|?" => \$help,
            "man" => \$man,
            "memory=i" => \$memory_mb,
            "name=s" => \$name,
            "vcpus=i" => \$vcpus,
            "vmtype=s" => \$vmtype,
    )
    or die "$0: unknown command line option\n";

pod2usage (1) if $help;
pod2usage (-exitval => 0, -verbose => 2) if $man;

# Get the parameters.
if (@ARGV < 1) {
    die "Use '$0 --man' to display the manual.\n"
}

#my @disks = @ARGV[0 .. $#ARGV-1];
my @disks;
foreach my $disk (@ARGV) {
    push @disks, $disk
}
my $output = $ARGV[$#ARGV];

if (!defined $name) {
    $name = $disks[0];
    $name =~ s{.*/}{};
    $name =~ s{\.[^.]+}{};
}

if ($vmtype =~ /^Desktop$/i) {
    $vmtype = 0;
} elsif ($vmtype =~ /^Server$/i) {
    $vmtype = 1;
} else {
    die "$0: --vmtype parameter must be 'Desktop' or 'Server'\n"
}

# Does qemu-img generally work OK?
system ("qemu-img create -f qcow2 .test.qcow2 10M >/dev/null") == 0
    or die "qemu-img command not installed or not working\n";

# Does this version of qemu-img support compat=0.10?  RHEL 6
# did NOT support it.
my $qemu_img_supports_compat = 0;
system ("qemu-img create -f qcow2 -o compat=0.10 .test.qcow2 10M >/dev/null 2>&1") == 0
    and $qemu_img_supports_compat = 1;
unlink ".test.qcow2";

# Open the guest in libguestfs so we can inspect it.
my $g = Sys::Guestfs->new ();
eval { $g->set_program ("virt-import-to-ovirt"); };
$g->add_drive_opts ($_, readonly => 1) foreach (@disks);
$g->launch ();
my @roots = $g->inspect_os ();
if (@roots == 0) {
    die "$0: no operating system was found on the disk\n"
}
if (@roots > 1) {
    die "$0: either this is a multi-OS disk, or you passed multiple unrelated guest disks on the command line\n"
}
my $root = $roots[0];

# Save the inspection data.
my $type = $g->inspect_get_type ($root); #debian
my $distro = $g->inspect_get_distro ($root); #linux
my $arch = $g->inspect_get_arch ($root); #x86_64
my $major_version = $g->inspect_get_major_version ($root); #7
my $minor_version = $g->inspect_get_major_version ($root); #7
my $product_name = $g->inspect_get_product_name ($root); #7.11
my $product_variant = $g->inspect_get_product_variant ($root); #unknown

# Get the virtual size of each disk.
my @virtual_sizes;
foreach (@disks) {
    push @virtual_sizes, $g->disk_virtual_size ($_);
}

$g->close ();

# http://schemas.dmtf.org/wbem/cim-html/2+/
# and enum CIMOSType_T VBox/Main/include/ovfreader.h
# Map inspection data to OVF ostype.
my $ostype;
if ($type eq "linux" && $distro eq "rhel") {
    if ($arch eq "x86_64") {
        $ostype = 80
    } else {
        $ostype = 79
    }
}
elsif ($type eq "linux" && $distro eq "debian") {
    if ($arch eq "x86_64") {
        $ostype = 96
    } else {
        $ostype = 95
    }
}
elsif ($type eq "linux") {
    $ostype = "OtherLinux"
}
elsif ($type eq "windows" && $major_version == 5 && $minor_version == 1) {
    $ostype = "WindowsXP"
}
elsif ($type eq "windows" && $major_version == 5 && $minor_version == 2) {
    if ($product_name =~ /XP/) {
        $ostype = "WindowsXP"
    } elsif ($arch eq "x86_64") {
        $ostype = "Windows2003x64"
    } else {
        $ostype = "Windows2003"
    }
}
elsif ($type eq "windows" && $major_version == 6 && $minor_version == 0) {
    if ($arch eq "x86_64") {
        $ostype = "Windows2008x64"
    } else {
        $ostype = "Windows2008"
    }
}
elsif ($type eq "windows" && $major_version == 6 && $minor_version == 1) {
    if ($product_variant eq "Client") {
        if ($arch eq "x86_64") {
            $ostype = "Windows7x64"
        } else {
            $ostype = "Windows7"
        }
    } else {
        $ostype = "Windows2008R2x64"
    }
}
elsif ($type eq "windows" && $major_version == 6 && $minor_version == 2) {
   if ($product_variant eq "Client") {
       if ($arch eq "x86_64") {
           $ostype = "windows_8x64"
       } else {
           $ostype = "windows_8"
       }
   } else {
       $ostype = "windows_2012x64"
   }
}
elsif ($type eq "windows" && $major_version == 6 && $minor_version == 3) {
    $ostype = "windows_2012R2x64"
}
else {
    $ostype = "Unassigned"
}

my $files_output_dir = getcwd;
#my $files_output_dir = $files_output_dir;
#$files_output_dir =~ s{.*/}{};

# Start the import.
print "Importing $type $distro $arch $product_name ...\n";

# Generate a UUID.
sub uuidgen
{
    local $_ = `uuidgen -r`;
    chomp;
    die unless length $_ >= 30; # Sanity check.
    $_;
}

# Generate some random UUIDs.
my $vm_uuid = uuidgen ();
my @image_uuids;
foreach (@disks) {
    push @image_uuids, uuidgen ();
}
my @vol_uuids;
foreach (@disks) {
    push @vol_uuids, uuidgen ();
}

# Make sure the output is deleted on unsuccessful exit.  We set
# $delete_output_on_exit to false at the end of the script.
my $delete_output_on_exit = 1;
my @converted_disks;
END {
    if ($delete_output_on_exit) {
        foreach my $disk (@converted_disks) {
            print ("rm", "-rf", "$files_output_dir/images/$_\n");
            unlink $disk;
        }
    }
};

# Copy and convert the disk images.
my $i;
my $time = time ();
my $iso_time = strftime ("%Y/%m/%d %H:%M:%S", gmtime ());
my $imported_by = "Imported by import2vbox.pl";
#my @real_sizes;

my $disk_format = "vmdk";

for ($i = 0; $i < @disks; ++$i) {
    my $input_file = $disks[$i];

    if ($input_file =~ /\.vmdk$/) {
        print "not converting $input_file \n";
        push @converted_disks, $input_file;
        next;
    }

    my $output_file = $input_file =~ s/\..*$/\.\Q$disk_format\E/r;
    open (my $fh, ">", $output_file) or die "open: $output_file: $!";
    print "Converting $input_file to $output_file ...\n ";
    my @compat_option = ();
    if ($qemu_img_supports_compat) {
        @compat_option = ("-o", "compat=0.10") # for RHEL 6-based ovirt nodes
    }
    system ("qemu-img", "convert", "-p",
            "-O", "$disk_format",
#            @compat_option,
            $input_file,
            $output_file) == 0
               or die "qemu-img: $input_file: failed (status $?)";
    print "calling qemu ....\n";
    push @converted_disks, $output_file;
    #push @real_sizes, -s $output_file;

    #my $size_in_sectors = $virtual_sizes[$i] / 512;

}
# Create the OVF.
print "Creating OVF metadata ...\n";

my $rasd_ns = "http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_ResourceAllocationSettingData";
my $vssd_ns = "http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_VirtualSystemSettingData";
my $xsi_ns = "http://www.w3.org/2001/XMLSchema-instance";
my $ovf_ns = "http://schemas.dmtf.org/ovf/envelope/1/";
my %prefix_map = (
    $rasd_ns => "rasd",
    $vssd_ns => "vssd",
    $xsi_ns => "xsi",
    $ovf_ns => "ovf",
);
my @forced_ns_decls = keys %prefix_map;

my $ovf = "";
my $w = XML::Writer->new (
    OUTPUT => \$ovf,
    NAMESPACES => 1,
    PREFIX_MAP => \%prefix_map,
    FORCED_NS_DECLS => \@forced_ns_decls,
    DATA_MODE => 1,
    DATA_INDENT => 4,
);

$w->xmlDecl("UTF-8");
$w->comment ($imported_by);

$w->startTag ([$ovf_ns, "Envelope"],
              [$ovf_ns, "version"] => "0.9");

$w->startTag ("References");

for ($i = 0; $i < @converted_disks; ++$i)
{
    my $href = $converted_disks[$i];
    $w->startTag ("File",
                  [$ovf_ns, "href"] => $href,
                  [$ovf_ns, "id"] => $name . $i,
                  [$ovf_ns, "size"] => $virtual_sizes[$i],
                  [$ovf_ns, "description"] => $imported_by);
    $w->endTag ();
}

$w->endTag ();

$w->startTag ("Section",
              [$xsi_ns, "type"] => "ovf:NetworkSection_Type");
$w->startTag ("Info");
$w->characters ("List of networks");
$w->endTag ();
$w->endTag ();

$w->startTag ("Section",
              [$xsi_ns, "type"] => "ovf:DiskSection_Type");
$w->startTag ("Info");
$w->characters ("List of Virtual Disks");
$w->endTag ();

for ($i = 0; $i < @converted_disks; ++$i)
{
    my $href = $converted_disks[$i];

    my $boot_drive;
    if ($i == 0) {
        $boot_drive = "True";
    } else {
        $boot_drive = "False";
    }

    $w->startTag ("Disk",
                  [$ovf_ns, "diskId" ] => "vmdisk" . $i,
                  [$ovf_ns, "capacity"] => $virtual_sizes[$i],
                  [$ovf_ns, "fileRef"] => $name . $i,
                  [$ovf_ns, "format"] => "http://en.wikipedia.org/wiki/Byte",
                  [$ovf_ns, "disk-type"] => "System",
                  [$ovf_ns, "boot"] => $boot_drive);
    $w->endTag ();
}

$w->endTag ();

$w->startTag ("Content",
              [$ovf_ns, "id"] => "$name",
              [$xsi_ns, "type"] => "ovf:VirtualSystem_Type");
$w->startTag ("Name");
$w->characters ($name);
$w->endTag ();
$w->startTag ("Description");
$w->characters ($imported_by);
$w->endTag ();
$w->startTag ("VmType");
$w->characters ($vmtype);
$w->endTag ();

$w->startTag ("Section",
              [$ovf_ns, "id"] => $ostype,
              [$ovf_ns, "required"] => "false",
              [$xsi_ns, "type"] => "ovf:OperatingSystemSection_Type");
$w->startTag ("Info");
$w->characters ($product_name);
$w->endTag ();
$w->startTag ("Description");
$w->characters (join (' ', $distro, $type, $arch, $product_name));
$w->endTag ();
$w->endTag ();

$w->startTag ("Section",
              [$xsi_ns, "type"] => "ovf:VirtualHardwareSection_Type");
$w->startTag ("Info");
$w->characters (sprintf ("%d CPU, %d Memory", $vcpus, $memory_mb));
$w->endTag ();

$w->startTag ("Item");
$w->startTag ([$rasd_ns, "Caption"]);
$w->characters (sprintf ("%d virtual cpu", $vcpus));
$w->endTag ();
$w->startTag ([$rasd_ns, "Description"]);
$w->characters ("Number of virtual CPU");
$w->endTag ();
$w->startTag ([$rasd_ns, "InstanceId"]);
$w->characters ("1");
$w->endTag ();
$w->startTag ([$rasd_ns, "ResourceType"]);
$w->characters ("3");
$w->endTag ();
$w->startTag ([$rasd_ns, "num_of_sockets"]);
$w->characters ($vcpus);
$w->endTag ();
$w->startTag ([$rasd_ns, "cpu_per_socket"]);
$w->characters (1);
$w->endTag ();
$w->endTag ("Item");

$w->startTag ("Item");
$w->startTag ([$rasd_ns, "Caption"]);
$w->characters (sprintf ("%d MB of memory", $memory_mb));
$w->endTag ();
$w->startTag ([$rasd_ns, "Description"]);
$w->characters ("Memory Size");
$w->endTag ();
$w->startTag ([$rasd_ns, "InstanceId"]);
$w->characters ("2");
$w->endTag ();
$w->startTag ([$rasd_ns, "ResourceType"]);
$w->characters ("4");
$w->endTag ();
$w->startTag ([$rasd_ns, "AllocationUnits"]);
$w->characters ("MegaBytes");
$w->endTag ();
$w->startTag ([$rasd_ns, "VirtualQuantity"]);
$w->characters ($memory_mb);
$w->endTag ();
$w->endTag ("Item");

$w->startTag ("Item");
$w->startTag ([$rasd_ns, "Caption"]);
$w->characters ("sataController0");
$w->endTag ();
$w->startTag ([$rasd_ns, "Address"]);
$w->characters ("0");
$w->endTag ();
$w->startTag ([$rasd_ns, "Description"]);
$w->characters ("SATA Controller");
$w->endTag ();
$w->startTag ([$rasd_ns, "ElementName"]);
$w->characters ("sataController0");
$w->endTag ();
$w->startTag ([$rasd_ns, "InstanceId"]);
$w->characters ("3");
$w->endTag ();
$w->startTag ([$rasd_ns, "ResourceSubType"]);
$w->characters ("AHCI");
$w->endTag ();
$w->startTag ([$rasd_ns, "ResourceType"]);
$w->characters ("20");
$w->endTag ();
$w->endTag ("Item");

$w->startTag ("Item");
$w->startTag ([$rasd_ns, "AutomaticAllocation"]);
$w->characters ("true");
$w->endTag ();
$w->startTag ([$rasd_ns, "Caption"]);
$w->characters ("Ethernet adapter on 'NAT'");
$w->endTag ();
$w->startTag ([$rasd_ns, "Connection"]);
$w->characters ("NAT");
$w->endTag ();
$w->startTag ([$rasd_ns, "ElementName"]);
$w->characters ("Ethernet Adapter on 'NAT'");
$w->endTag ();
$w->startTag ([$rasd_ns, "InstanceId"]);
$w->characters ("4");
$w->endTag ();
$w->startTag ([$rasd_ns, "ResourceType"]);
$w->characters ("10");
$w->endTag ();
$w->startTag ([$rasd_ns, "ResourceSubType"]);
$w->characters ("E1000e");
$w->endTag ();
$w->endTag ("Item");

for ($i = 0; $i < @disks; ++$i)
{
    my $href = $disks[$i];

    $w->startTag ("Item");

    $w->startTag ([$rasd_ns, "Caption"]);
    $w->characters ("Drive " . ($i));
    $w->endTag ();
    $w->startTag ([$rasd_ns, "AddressOnParent"]);
    $w->characters (($i));
    $w->endTag ();

    $w->startTag ([$rasd_ns, "InstanceId"]);
    $w->characters (5 + $i);
    $w->endTag ();
    $w->startTag ([$rasd_ns, "ResourceType"]);
    $w->characters ("17");
    $w->endTag ();
    $w->startTag ("Type");
    $w->characters ("disk");
    $w->endTag ();
    $w->startTag ([$rasd_ns, "HostResource"]);
    $w->characters ("ovf:/disk/" . "vmdisk" . $i);
    $w->endTag ();
    $w->startTag ([$rasd_ns, "Parent"]);
    $w->characters ("3");
    $w->endTag ();

    $w->endTag ("Item");
}

$w->endTag ("Section"); # ovf:VirtualHardwareSection_Type

$w->endTag ("Content");

$w->endTag ([$ovf_ns, "Envelope"]);
$w->end ();

#print "OVF:\n$ovf\n";

my $ovf_file = "$name.ovf";
open (my $ovf_fh, ">", $ovf_file) or die "open: $ovf_file: $!";
print $ovf_fh $ovf;

# Finished.
$delete_output_on_exit = 0;
print "\n";
print "OVF written to $ovf_file\n";
print "In Virtualbox, go to File -> Import a virtual appliance\n";
print "and select the ovf file.\n";
print "Or import from the command line with: \n";
print "\$ VBoxManage import $ovf_file\n";
exit 0;

__END__

=head1 TO DO

=over 4

=back

=head1 DEBUGGING IMPORT FAILURES

To be done

=head1 SEE ALSO

L<https://bugzilla.redhat.com/show_bug.cgi?id=1049604>,
L<virt-v2v(1)>,
L<engine-image-uploader(8)>.

=head1 AUTHOR

Richard W.M. Jones <rjones@redhat.com>
Emmanuel Kasper <emmanuel@libera.cc>

=head1 COPYRIGHT

Copyright (C) 2015 Richard W.M. Jones <rjones@redhat.com>
Copyright (C) 2015 Red Hat Inc.
Copyright (C) 2016 Emmanuel Kasper <emmanuel@libera.cc>


=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
