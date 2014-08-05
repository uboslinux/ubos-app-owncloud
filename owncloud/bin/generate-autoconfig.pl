#!/usr/bin/perl
#
# Generate the autoconfig.php file. This is a perlscript instead of a
# varsubst-d template because OwnCloud will remove this file, and then
# Indie Box undeploy will emit a warning, and we don't want that.
#

use strict;

use IndieBox::Utils;
use POSIX;

if( 'install' eq $operation ) {

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
  "directory"       => "data",
  "trusted_domains" => array( "$hostname" )
);
END
    
    IndieBox::Utils::saveFile( $autoConfigFile, $autoConfigContent, 0640, $apacheUname, $apacheGname );

IndieBox::Utils::saveFile( '/tmp/autoconfig.php', $autoConfigContent, 0640, $apacheUname, $apacheGname );
}
                
1;
