#!/usr/bin/perl
#
# Upon restore, the restored config.php has the old database information in it.
# We need to take the new database info from autoconfig.php, updated config.php.
# and delete autoconfig.php. This script does not have access to the database
# information directly, so that's the best avenue.
#

use strict;

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

    my $autoConf = UBOS::Utils::slurpFile( $autoConfFile );

    my $dbname;
    my $dbuser;
    my $dbpass;
    my $dbhost;

    if( $autoConf =~ m!['"]dbname['"]\s+=>\s["'](\S*)["']! ) {
        $dbname = $1;
    }
    if( $autoConf =~ m!['"]dbuser['"]\s+=>\s["'](\S*)["']! ) {
        $dbuser = $1;
    }
    if( $autoConf =~ m!['"]dbpass['"]\s+=>\s["'](\S*)["']! ) {
        $dbpass = $1;
    }
    if( $autoConf =~ m!['"]dbhost['"]\s+=>\s["'](\S*)["']! ) {
        $dbhost = $1;
    }

    my $conf = UBOS::Utils::slurpFile( $confFile );
    $conf =~ s!(['"]dbname['"]\s+=>\s["'])\S*(["'],?)!$1$dbname$2!;
    $conf =~ s!(['"]dbhost['"]\s+=>\s["'])\S*(["'],?)!$1$dbhost$2!;
    $conf =~ s!(['"]dbuser['"]\s+=>\s["'])\S*(["'],?)!$1$dbuser$2!;
    $conf =~ s!(['"]dbpassword['"]\s+=>\s["'])\S*(["'],?)!$1$dbpass$2!;
    $conf =~ s!(['"]trusted_domains['"]\s+=>\s*array\s*\(\s*0\s*=>\s*["'])\S*(\s*['"]\s*\))!$1$hostname$2!;

    UBOS::Utils::saveFile( $confFile, $conf, 0640, $apacheUname, $apacheGname );

    UBOS::Utils::deleteFile( $autoConfFile );
}

1;
