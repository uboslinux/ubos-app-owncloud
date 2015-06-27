#!/usr/bin/perl
#
# Fix permissions.
#

use strict;

use UBOS::Utils;
use POSIX;

my $dir         = $config->getResolve( 'appconfig.apache2.dir' );
my $appsDir     = "$dir/apps";

my $apacheUname = $config->getResolve( 'apache2.uname' );
my $apacheGname = $config->getResolve( 'apache2.gname' );

if( 'deploy' eq $operation ) {
    UBOS::Utils::myexec( "chown -R $apacheUname:$apacheGname '$appsDir' '$dir/index.html'" );
}

1;
