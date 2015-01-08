#!/usr/bin/perl
#
# Create the .ocdata file in the data directory. This needs to be managed by
# a script, as it is contained in a directory that has a retention policy and
# thus might be moved away by backup/restore.
#

use strict;

use UBOS::Utils;
use POSIX;

my $ocData = $config->getResolve( 'appconfig.datadir' ) . '/data/.ocdata';

if( 'install' eq $operation ) {
    UBOS::Utils::saveFile( $ocData, '' );
}
if( 'uninstall' eq $operation ) {
    if( -e $ocData ) {
        UBOS::Utils::deleteFile( $ocData );
    }
}

1;
