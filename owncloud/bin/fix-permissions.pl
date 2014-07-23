#!/usr/bin/perl
#
# Fix permissions.
#

use strict;

use IndieBox::Utils;
use POSIX;

my $dir         = $config->getResolve( 'appconfig.apache2.dir' );
my $appsDir     = "$dir/apps";

my $apacheUname = $config->getResolve( 'apache2.uname' );
my $apacheGname = $config->getResolve( 'apache2.gname' );

if( 'install' eq $operation ) {
    IndieBox::Utils::myexec( "chown -R $apacheUname:$apacheGname '$appsDir' '$dir/index.html'" );
}

1;
