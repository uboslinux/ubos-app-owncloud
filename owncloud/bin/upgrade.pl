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
my $ret         = 1;

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
        if( $out =~ m!already latest version! ) {
            # apparently a non-upgrade is an error, with the message on stdout
            # no op
        } elsif( $out =~ m!Updates between multiple major versions and downgrades are unsupported! ) {
            error( <<MSG );
Unfortunately, ownCloud cannot currently upgrade your installation. This is because you skipped at least
one major ownCloud version since you last upgraded, and the ownCloud upgrader does not know how to handle
this.
We filed a bug with the ownCloud project here: https://github.com/owncloud/core/issues/21859
In the meantime, you will have to do the upgrade work manually, unfortunately.
MSG
            $ret = 0;

        } else {
            # something else happened
            error( "occ upgrade failed:\n$out\n$err" );
            $ret = 0;
        }
    }
}

$ret;
