#!/usr/bin/perl
#
# Simple test for owncloud
#
# Copyright (C) 2012-2014 Indie Computing Corp.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

use strict;
use warnings;

package OwnCloud1Test;

use File::Basename;
use UBOS::Logging;
use UBOS::WebAppTest;

my $filesAppRelativeUrl = '/index.php/apps/files';
my $testFile            = 'foo-testfile';
my $fullTestFile        = dirname( $fileName ) . '/' . $testFile; # variable inherited from invocation

unless( -r $fullTestFile ) {
    fatal( 'Cannot read test file', $fullTestFile, '.' );
}

## We need to test file uploading, and webapptest doesn't really have
## any easy methods for that yet. So first, here is a utility routine
## for uploading files. The actual test follows.

##
# Perform an HTTP POST request uploading a file on the host on which the
# application is being tested.
# $c: TestContext
# $relativeUrl: appended to the host's URL
# $file: name of the file to be uploaded after it has arrived in ownCloud
# $fullFile: the name of the file to be uploaded in the filesystem
# $dir: the directory parameter
# $requestToken: the form's request token
# return: hash containing content and headers of the HTTP response
sub upload {
    my $c            = shift;
    my $relativeUrl  = shift;
    my $file         = shift;
    my $fullFile     = shift;
    my $dir          = shift;
    my $requestToken = shift;

    my $url = 'http://' . $c->hostName . $c->context() . $relativeUrl;

    debug( 'Posting to url', $url );

    my $cmd = $c->{curl};
    $cmd .= " -F 'files[]=\@$fullFile;filename=$file;type=text/plain'";
    $cmd .= " -F 'requesttoken=$requestToken'";
    $cmd .= " -F 'dir=$dir'";
    $cmd .= " -F 'file_directory='"; # whatever that is
    $cmd .= " '$url'";

    my $stdout;
    my $stderr;
    if( UBOS::Utils::myexec( $cmd, undef, \$stdout, \$stderr )) {
        $c->error( 'HTTP request failed:', $stderr );
    }
    my $response = {
        'content'     => $stdout,
        'headers'     => $stderr,
        'url'         => $url,
        'file'        => $file };
        
    $c->mustStatus( $response, 200, 'Upload failed' );

    return $response;
}


##


my $TEST = new UBOS::WebAppTest(
    name                     => 'OwnCloud1Test',
    description              => 'Tests admin account and single-file upload.',
    appToTest                => 'owncloud',
    testContext              => '/foobar',
    hostname                 => 'owncloud-test',

    checks => [
            new UBOS::WebAppTest::StateCheck(
                    name  => 'virgin',
                    check => sub {
                        my $c = shift;
                        
                        # Accessing the front page for the first time will cause a redirect to /index.php/post-setup-check,
                        # which will redirect back to the front if everything is okay. When accessed the second time, however,
                        # the redirect may not occur.
                        my $response = $c->get( '/' );
                        if( $c->redirects( $response, '/index.php/post-setup-check' )) {
                            $c->getMustRedirect( '/index.php/post-setup-check', '/' );
                        }

                        $response = $c->getMustContain( '/', '<label for="user" class="infield">Username</label>', 200, 'Wrong (before log-on) front page' );
                        my $requestToken;
                        if( $response->{content} =~ m!<input.*name="requesttoken" value="([^"]+)" />! ) {
                            $requestToken = $1;

                            my $adminData = $c->getTest()->getAdminData();
                            
                            my $postData = {
                                'user'            => $adminData->{userid},
                                'password'        => $adminData->{credential},
                                'timezone-offset' => 0,
                                'requesttoken'    => $requestToken
                            };

                            $response = $c->post( '/', $postData );
                            $c->mustRedirect( $response, $filesAppRelativeUrl, 302, 'Not redirected to files app' );
                            
                            $c->getMustContain( $filesAppRelativeUrl, '<span id="expandDisplayName">' . $adminData->{userid} . '</span>', 200, 'Wrong (logged-on) front page (display name)' );
                            $c->getMustContain( $filesAppRelativeUrl, '/index.php/settings/admin', 200, 'Wrong (logged-on) front page (admin)' );

                            # uploaded file must not be there
                            $response = $c->get( $filesAppRelativeUrl . '/ajax/download.php?dir=%2F&files=' . $testFile );
                            $c->mustStatus( $response, 404, 'Test file found but should not' );

                        } else {
                            $c->error( 'Cannot find request token', $response->{content} );
                        }

                        return 1;
                    }
            ),
            new UBOS::WebAppTest::StateTransition(
                    name       => 'upload-file',
                    transition => sub {
                        my $c = shift;

                        # need to login first, and find requesttoken. we tested that earlier
                        my $response = $c->get( '/' );

                        my $requestToken;
                        if( $response->{content} =~ m!<input.*name="requesttoken" value="([^"]+)" />! ) {
                            $requestToken = $1;
                        } else {
                            $c->error( 'Cannot find request token', $response->{content} );
                        }

                        my $adminData = $c->getTest()->getAdminData();
                        my $postData = {
                            'user'            => $adminData->{userid},
                            'password'        => $adminData->{credential},
                            'timezone-offset' => 0,
                            'requesttoken'    => $requestToken
                        };
                        $c->post( '/', $postData );
                        
                        $response = $c->get( $filesAppRelativeUrl );

                        my $dataRequestToken;
                        if( $response->{content} =~ m!<head.*data-requesttoken="([0-9a-f]+)"! ) {
                            $dataRequestToken = $1;
                        } else {
                            $c->error( 'Cannot find request token', $response->{content} );
                        }

                        $response = upload( $c, '/index.php/apps/files/ajax/upload.php', $testFile, $fullTestFile, '/', $dataRequestToken );
                        $c->mustStatus( $response, 200, 'Upload failed' );

                        return 1;
                    }
            ),
            new UBOS::WebAppTest::StateCheck(
                    name  => 'file-uploaded',
                    check => sub {
                        my $c = shift;

                        # need to login first, and find requesttoken. we tested that earlier
                        my $response = $c->get( '/' );

                        my $requestToken;
                        if( $response->{content} =~ m!<input.*name="requesttoken" value="([^"]+)" />! ) {
                            $requestToken = $1;
                        } else {
                            $c->error( 'Cannot find request token', $response->{content} );
                        }

                        my $adminData = $c->getTest()->getAdminData();
                        my $postData = {
                            'user'            => $adminData->{userid},
                            'password'        => $adminData->{credential},
                            'timezone-offset' => 0,
                            'requesttoken'    => $requestToken
                        };
                        $c->post( '/', $postData );

                        $response = $c->get( $filesAppRelativeUrl . '/ajax/download.php?dir=%2F&files=' . $testFile );
                        $c->mustStatus( $response, 200, 'Test file not found' );

                        return 1;
                    }
            )
    ]
);

$TEST;
