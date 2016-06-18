#!/usr/bin/perl
#
# Generate the autoconfig.php file. This is a perlscript instead of a
# varsubst-d template because OwnCloud will remove this file, and then
# ubos-admin undeploy will emit a warning, and we don't want that.
#

use strict;

use UBOS::Utils;
use POSIX;

if( 'deploy' eq $operation ) {

    my $dir            = $config->getResolve( 'appconfig.apache2.dir' );
    my $autoConfigFile = "$dir/config/autoconfig.php";

    my $apacheUname = $config->getResolve( 'apache2.uname' );
    my $apacheGname = $config->getResolve( 'apache2.gname' );

    my $dbname = $config->getResolve( 'appconfig.mysql.dbname.maindb' );
    my $dbuser = $config->getResolve( 'appconfig.mysql.dbuser.maindb' );
    my $dbpass = $config->getResolve( 'appconfig.mysql.dbusercredential.maindb' );
    my $dbhost = $config->getResolve( 'appconfig.mysql.dbhost.maindb' );

    my $hostname   = $config->getResolve( 'site.hostname' );
    my $adminlogin = $config->getResolve( 'site.admin.userid' );
    my $adminpass  = $config->getResolve( 'site.admin.credential' );

    my $datadir = $config->getResolve( 'appconfig.datadir' ) . '/data';

    my $cliUrl = $config->getResolve( 'site.protocol' ) .  '://' . $hostname . $config->getResolve( 'appconfig.context' );

    my $autoConfigContent = <<END;
<?php
\$AUTOCONFIG = array(
  "dbtype"          => "mysql",
  "dbname"          => "$dbname",
  "dbuser"          => "$dbuser",
  "dbpass"          => "$dbpass",
  "dbhost"          => "$dbhost",
  "dbtableprefix"   => "",
  "adminlogin"      => "$adminlogin",
  "adminpass"       => "$adminpass",
  "directory"       => "$datadir",
  "trusted_domains" => array( "$hostname" ),
  "memcache.local"  => "\\OC\\Memcache\\APCu",
// Testing these
  "appstoreenabled" => true,
  "updatechecker"   => false,
  "log_type"        => "errorlog",
  "overwrite.cli.url" => "$cliUrl",
  "mail_domain"       => "$hostname",
  "mail_from_address" => "$adminlogin",
  "mail_smtpmode"     => "smtp"
);
END
    
    UBOS::Utils::saveFile( $autoConfigFile, $autoConfigContent, 0640, $apacheUname, $apacheGname );
}
1;
