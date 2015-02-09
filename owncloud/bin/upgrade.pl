#!/usr/bin/perl
#
# Invoke occ upgrade
#

use strict;
use warnings;

use UBOS::Logging;
use UBOS::Utils;
use POSIX;

my $dir         = $config->getResolve( 'appconfig.apache2.dir' );
my $datadir     = $config->getResolve( 'appconfig.datadir' ) . '/data';
my $apacheUname = $config->getResolve( 'apache2.uname' );

if( 'upgrade' eq $operation ) {

    my $cmd = "cd '$dir';";
    $cmd .= "sudo -u '$apacheUname' php";
    $cmd .= " -d 'open_basedir=$dir:/tmp/:/usr/share/:$datadir'";
    $cmd .= ' -d always_populate_raw_post_data=-1';
    $cmd .= ' -d extension=posix.so';
    $cmd .= ' occ upgrade';

    my $out;
    my $err;
    if( UBOS::Utils::myexec( $cmd, undef, \$out, \$err )) {
        unless( $out =~ m!already latest version! ) {
            # apparently a non-upgrade is an error, with the message on stdout
            error( "occ upgrade failed:\n$out\n$err" );
        }
    }
}

1;
