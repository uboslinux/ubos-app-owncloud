#!/usr/bin/perl
#
# Upon restore, the restored config.php has the old database information in it.
# We need to take the new database info from autoconfig.php, updated config.php.
# and delete autoconfig.php. This script does not have access to the database
# information directly, so that's the best avenue.
#
# We keep the instanceid field from the older config.php, because apparently
# it is used to generate password salt, and we want to keep passwords valid.
# See also this thread: https://mailman.owncloud.org/pipermail/user/2016-April/002382.html
#

use strict;

use UBOS::Logging;
use UBOS::Utils;
use POSIX;

my $dir          = $config->getResolve( 'appconfig.apache2.dir' );
my $configDir    = "$dir/config";
my $autoConfFile = "$configDir/autoconfig.php";
my $confFile     = "$configDir/config.php";

my $apacheUname = $config->getResolve( 'apache2.uname' );
my $apacheGname = $config->getResolve( 'apache2.gname' );
my $hostname    = $config->getResolve( 'site.hostname' );

if( 'upgrade' eq $operation ) {

    if( -r $autoConfFile ) {
        my $autoConf = UBOS::Utils::slurpFile( $autoConfFile );

        my $dbname;
        my $dbuser;
        my $dbpass;
        my $dbhost;
        my $directory;

        if( $autoConf =~ m!['"]dbname['"]\s+=>\s["'](\S*)["']! ) {
            $dbname = $1;
        } else {
            error( 'Cannot find entry dbname in', $autoConfFile, '-- owncloud likely to be flaky' );
        }
        if( $autoConf =~ m!['"]dbuser['"]\s+=>\s["'](\S*)["']! ) {
            $dbuser = $1;
        } else {
            error( 'Cannot find entry dbuser in', $autoConfFile, '-- owncloud likely to be flaky' );
        }
        if( $autoConf =~ m!['"]dbpass['"]\s+=>\s["'](\S*)["']! ) {
            $dbpass = $1;
        } else {
            error( 'Cannot find entry dbpass in', $autoConfFile, '-- owncloud likely to be flaky' );
        }
        if( $autoConf =~ m!['"]dbhost['"]\s+=>\s["'](\S*)["']! ) {
            $dbhost = $1;
        } else {
            error( 'Cannot find entry dbhost in', $autoConfFile, '-- owncloud likely to be flaky' );
        }
        if( $autoConf =~ m!['"]directory['"]\s+=>\s["'](\S*)["']! ) {
            $directory = $1;
        } else {
            error( 'Cannot find entry directory in', $autoConfFile, '-- owncloud likely to be flaky' );
        }

        my $conf = UBOS::Utils::slurpFile( $confFile );
        unless( $conf =~ s!(['"]dbname['"]\s+=>\s["'])\S*(["'],?)!$1$dbname$2! ) {
            error( 'Cannot find entry dbname in', $confFile, '-- owncloud likely to be flaky' );
        }
        unless( $conf =~ s!(['"]dbhost['"]\s+=>\s["'])\S*(["'],?)!$1$dbhost$2! ) {
            error( 'Cannot find entry dbhost in', $confFile, '-- owncloud likely to be flaky' );
        }
        unless( $conf =~ s!(['"]dbuser['"]\s+=>\s["'])\S*(["'],?)!$1$dbuser$2! ) {
            error( 'Cannot find entry dbuser in', $confFile, '-- owncloud likely to be flaky' );
        }
        unless( $conf =~ s!(['"]dbpassword['"]\s+=>\s["'])\S*(["'],?)!$1$dbpass$2! ) {
            error( 'Cannot find entry dbpassword in', $confFile, '-- owncloud likely to be flaky' );
        }
        unless( $conf =~ s!(['"]trusted_domains['"]\s+=>\s*array\s*\(\s*0\s*=>\s*["'])\S*(\s*['"])!$1$hostname$2!m ) {
            error( 'Cannot find entry trusted_domains in', $confFile, '-- owncloud likely to be flaky' );
        }
        unless( $conf =~ s!(['"]datadirectory['"]\s+=>\s["'])\S*(["'],?)!$1$directory$2! ) {
            error( 'Cannot find entry datadirectory in', $confFile, '-- owncloud likely to be flaky' );
        }

        UBOS::Utils::saveFile( $confFile, $conf, 0640, $apacheUname, $apacheGname );

        UBOS::Utils::deleteFile( $autoConfFile );
    } else {
        error( 'Cannot read autoconfig file', $autoConfFile );
    }
}

1;
