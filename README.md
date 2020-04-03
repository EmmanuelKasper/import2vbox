This script lets you import a virtual machine disk image to VirtualBox
Based on import-to-ovirt.pl by Richard W.M. Jones

IMPORTANT NOTES:

(1) This script *requires* a 64 bit host.  Perl will cause silent
overflows on 32 bit hosts.

Requirements:

- perl
- perl-Pod-Usage* (on debian/ubuntu: perl-doc)
- perl-Getopt-Long*
- perl-File-Temp*
- perl-POSIX*
- perl-XML-Writer (on debian/ubuntu: libxml-writer-perl)
- perl-Sys-Guestfs (on debian/ubuntu: libguestfs-perl)
- uuid-runtime

\* usually provided as part of base Perl package

For instructions, read the script or do:

    ./import2vbox.pl --help
    ./import2vbox.pl --man

For running the tests, you need ovftool from VMware, available at
https://code.vmware.com/web/tool/4.3.0/ovf is necessary


Copyright (C) 2015 Richard W.M. Jones <rjones   at redhat.com> 
Copyright (C) 2015 Red Hat Inc. 
Copyright (C) 2016 Emmanuel Kasper <emmanuel  at libera.cc>


Send pull requests to https://github.com/EmmanuelKasper/import2vbox
