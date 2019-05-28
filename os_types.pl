#!/usr/bin/perl
use warnings;
use strict;
use English;
use Data::Dumper;
use feature ('say');

my @os_types = (
	{ id => 0, dtmf_name => 'Unknown'},
	{ id => 1, dtmf_name => 'Other' },
	{ id => 2, dtmf_name => 'MACOS' },
	{ id => 3, dtmf_name => 'ATTUNIX' },
	{ id => 4, dtmf_name => 'DGUX' },
	{ id => 5, dtmf_name => 'DECNT' },
	{ id => 6, dtmf_name => 'Tru64 UNIX' },
	{ id => 7, dtmf_name => 'OpenVMS' },
	{ id => 8, dtmf_name => 'HPUX' },
	{ id => 9, dtmf_name => 'AIX' },
	{ id => 10, dtmf_name => 'MVS' },
	{ id => 11, dtmf_name => 'OS400' },
	{ id => 12, dtmf_name => 'OS/2' },
	{ id => 13, dtmf_name => 'JavaVM' },
	{ id => 14, dtmf_name => 'MSDOS' },
	{ id => 15, dtmf_name => 'WIN3x' },
	{ id => 16, dtmf_name => 'WIN95' },
	{ id => 17, dtmf_name => 'WIN98' },
	{ id => 18, dtmf_name => 'WINNT' },
	{ id => 19, dtmf_name => 'WINCE' },
	{ id => 20, dtmf_name => 'NCR3000' },
	{ id => 21, dtmf_name => 'NetWare' },
	{ id => 22, dtmf_name => 'OSF' },
	{ id => 23, dtmf_name => 'DC/OS' },
	{ id => 24, dtmf_name => 'Reliant UNIX' },
	{ id => 25, dtmf_name => 'SCO UnixWare' },
	{ id => 26, dtmf_name => 'SCO OpenServer' },
	{ id => 27, dtmf_name => 'Sequent' },
	{ id => 28, dtmf_name => 'IRIX' },
	{ id => 29, dtmf_name => 'Solaris' },
	{ id => 30, dtmf_name => 'SunOS' },
	{ id => 31, dtmf_name => 'U6000' },
	{ id => 32, dtmf_name => 'ASERIES' },
	{ id => 33, dtmf_name => 'HP NonStop OS' },
	{ id => 34, dtmf_name => 'HP NonStop OSS' },
	{ id => 35, dtmf_name => 'BS2000' },
	{ id => 36, dtmf_name => 'LINUX' },
	{ id => 37, dtmf_name => 'Lynx' },
	{ id => 38, dtmf_name => 'XENIX' },
	{ id => 39, dtmf_name => 'VM' },
	{ id => 40, dtmf_name => 'Interactive UNIX' },
	{ id => 41, dtmf_name => 'BSDUNIX' },
	{ id => 42, dtmf_name => 'FreeBSD' },
	{ id => 43, dtmf_name => 'NetBSD' },
	{ id => 44, dtmf_name => 'GNU Hurd' },
	{ id => 45, dtmf_name => 'OS9' },
	{ id => 46, dtmf_name => 'MACH Kernel' },
	{ id => 47, dtmf_name => 'Inferno' },
	{ id => 48, dtmf_name => 'QNX' },
	{ id => 49, dtmf_name => 'EPOC' },
	{ id => 50, dtmf_name => 'IxWorks' },
	{ id => 51, dtmf_name => 'VxWorks' },
	{ id => 52, dtmf_name => 'MiNT' },
	{ id => 53, dtmf_name => 'BeOS' },
	{ id => 54, dtmf_name => 'HP MPE' },
	{ id => 55, dtmf_name => 'NextStep' },
	{ id => 56, dtmf_name => 'PalmPilot' },
	{ id => 57, dtmf_name => 'Rhapsody' },
	{ id => 58, dtmf_name => 'Windows 2000' },
	{ id => 59, dtmf_name => 'Dedicated' },
	{ id => 60, dtmf_name => 'OS/390' },
	{ id => 61, dtmf_name => 'VSE' },
	{ id => 62, dtmf_name => 'TPF' },
	{ id => 63, dtmf_name => 'Windows (R) Me' },
	{ id => 64, dtmf_name => 'Caldera Open UNIX' },
	{ id => 65, dtmf_name => 'OpenBSD' },
	{ id => 66, dtmf_name => 'Not Applicable' },
	{ id => 67, dtmf_name => 'Windows XP' },
	{ id => 68, dtmf_name => 'z/OS' },
	{ id => 69, dtmf_name => 'Microsoft Windows Server 2003' },
	{ id => 70, dtmf_name => 'Microsoft Windows Server 2003 64-Bit' },
	{ id => 71, dtmf_name => 'Windows XP 64-Bit' },
	{ id => 72, dtmf_name => 'Windows XP Embedded' },
	{ id => 73, dtmf_name => 'Windows Vista' },
	{ id => 74, dtmf_name => 'Windows Vista 64-Bit' },
	{ id => 75, dtmf_name => 'Windows Embedded for Point of Service' },
	{ id => 76, dtmf_name => 'Microsoft Windows Server 2008' },
	{ id => 77, dtmf_name => 'Microsoft Windows Server 2008 64-Bit' },
	{ id => 78, dtmf_name => 'FreeBSD 64-Bit' },
	{ id => 79, dtmf_name => 'RedHat Enterprise Linux' },
	{ id => 80, dtmf_name => 'RedHat Enterprise Linux 64-Bit' },
	{ id => 81, dtmf_name => 'Solaris 64-Bit' },
	{ id => 82, dtmf_name => 'SUSE' },
	{ id => 83, dtmf_name => 'SUSE 64-Bit' },
	{ id => 84, dtmf_name => 'SLES' },
	{ id => 85, dtmf_name => 'SLES 64-Bit' },
	{ id => 86, dtmf_name => 'Novell OES' },
	{ id => 87, dtmf_name => 'Novell Linux Desktop' },
	{ id => 88, dtmf_name => 'Sun Java Desktop System' },
	{ id => 89, dtmf_name => 'Mandriva' },
	{ id => 90, dtmf_name => 'Mandriva 64-Bit' },
	{ id => 91, dtmf_name => 'TurboLinux' },
	{ id => 92, dtmf_name => 'TurboLinux 64-Bit' },
	{ id => 93, dtmf_name => 'Ubuntu' },
	{ id => 94, dtmf_name => 'Ubuntu 64-Bit' },
	{ id => 95, dtmf_name => 'Debian', pve_type => 'Linux' },
	{ id => 96, dtmf_name => 'Debian 64-Bit' },
	{ id => 97, dtmf_name => 'Linux 2.4.x' },
	{ id => 98, dtmf_name => 'Linux 2.4.x 64-Bit' },
	{ id => 99, dtmf_name => 'Linux 2.6.x' },
	{ id => 100, dtmf_name => 'Linux 2.6.x 64-Bit' },
	{ id => 101, dtmf_name => 'Linux 64-Bit' },
	{ id => 102, dtmf_name => 'Other 64-Bit' },
	{ id => 103, dtmf_name => 'Microsoft Windows Server 2008 R2' },
	{ id => 104, dtmf_name => 'VMware ESXi' },
	{ id => 105, dtmf_name => 'Microsoft Windows 7' },
	{ id => 106, dtmf_name => 'CentOS 32-bit' },
	{ id => 107, dtmf_name => 'CentOS 64-bit' },
	{ id => 108, dtmf_name => 'Oracle Linux 32-bit' },
	{ id => 109, dtmf_name => 'Oracle Linux 64-bit' },
	{ id => 110, dtmf_name => 'eComStation 32-bitx' },
	{ id => 111, dtmf_name => 'Microsoft Windows Server 2011' },
	{ id => 112, dtmf_name => 'Microsoft Windows Server 2012' },
	{ id => 113, dtmf_name => 'Microsoft Windows 8' },
	{ id => 114, dtmf_name => 'Microsoft Windows 8 64-bit' },
	{ id => 115, dtmf_name => 'Microsoft Windows Server 2012 R2' }
);

sub get_os_by {
	my ($key_match, $id) = @_;
	my $found = 0;
	foreach my $os (@os_types) {
        if ($os->{$key_match} == $id) {
            $found = 1;
        	return $os;
        }
    }
    return undef;
}


if ( defined(my $debian = get_os_by('id', 96)) ) {
	my $pve_type = $debian->{pve_type} || "other os";
	say $pve_type;
}