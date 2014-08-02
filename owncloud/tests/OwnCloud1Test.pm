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

use IndieBox::WebAppTest;

# Admin user for this test
my $adminlogin = 'specialuser';
my $adminpass  = 'specialpass';

my $filesAppRelativeUrl = '/index.php/apps/files';
my $testFile            = 'foo-testfile';

## We need to test file uploading, and webapptest doesn't really have
## any easy methods for that yet. So first, here is a utility routine
## for uploading files. The actual test follows.

##
# Perform an HTTP POST request uploading a file on the host on which the
# application is being tested.
# $c: TestContext
# $relativeUrl: appended to the host's URL
# $file: name of the file to be uploaded
# $dir: the directory parameter
# $requestToken: the form's request token
# return: hash containing content and headers of the HTTP response
sub upload {
    my $c            = shift;
    my $relativeUrl  = shift;
    my $file         = shift;
    my $dir          = shift;
    my $requestToken = shift;

    my $url = 'http://' . $c->hostName . $c->context() . $relativeUrl;
    my $response;

    debug( 'Posting to url', $url );

    my $cmd = $c->{curl};
    $cmd .= " -F 'files[]=\@$file;filename=$file;type=text/plain'";
    $cmd .= " -F 'requesttoken=$requestToken'";
    $cmd .= " -F 'dir=$dir'";
    $cmd .= " '$url'";

    my $stdout;
    my $stderr;
    if( IndieBox::Utils::myexec( $cmd, undef, \$stdout, \$stderr )) {
        $c->reportError( 'HTTP request failed:', $stderr );
    }
    return { 'content'     => $stdout,
             'headers'     => $stderr,
             'url'         => $url,
             'file'        => $file };
}


##


my $TEST = new IndieBox::WebAppTest(
    name                     => 'OwnCloud1Test',
    description              => 'Tests admin account and single-file upload.',
    appToTest                => 'owncloud',
    testContext              => '/foobar',
    hostname                 => 'owncloud-test',
    customizationPointValues => { 'adminlogin' => $adminlogin, 'adminpass' => $adminpass },

    checks => [
            new IndieBox::WebAppTest::StateCheck(
                    name  => 'virgin',
                    check => sub {
                        my $c = shift;

                        $c->getMustContain( '/', '<label for="user" class="infield">Username</label>', 200, 'Wrong (before log-on) front page' );

                        my $postData = {
                            'user'            => $adminlogin,
                            'password'        => $adminpass,
                            'timezone-offset' => 0
                        };
                        
                        my $response = $c->post( '/', $postData );
                        $c->mustRedirect( $response, $filesAppRelativeUrl, 302, 'Not redirected to files app' );
                        
                        $c->getMustContain( $filesAppRelativeUrl, '<label for="user" class="infield">Username</label>', 200, 'Wrong (logged-on) front page (content)' );

                        $c->getMustContain( $filesAppRelativeUrl, '<span id="expandDisplayName">' . $adminlogin . '</span>', 200, 'Wrong (logged-on) front page (user)' );

                        # uploaded file must not be there
                        $response = $c->get( $filesAppRelativeUrl . '/download/' . $testFile );
                        $c->mustStatus( $response, 404, 'Test file found but should not' );

                        return 1;
                    }
            ),
            new IndieBox::WebAppTest::StateTransition(
                    name       => 'upload-file',
                    transition => sub {
                        my $c = shift;

                        # need to login first, and find requesttoken
                        my $postData = {
                            'user'            => $adminlogin,
                            'password'        => $adminpass,
                            'timezone-offset' => 0
                        };
                        $c->post( '/', $postData ); # tested that earlier
                        
                        my $response = $c->get( $filesAppRelativeUrl );

                        my $requestToken;
                        if( $response->{content} =~ m!<head.*data-requesttoken="([0-9a-f]+)"! ) {
                            $requestToken = $1;
                        } else {
                            $c->reportError( 'Cannot find request token', $response->{content} );
                        }

                        $response = upload( $c, '/index.php/apps/files/ajax/upload.php', $testFile, '/', $requestToken );
                        $c->mustStatus( $response, 200, 'Upload failed' );

                        return 1;
                    }
            ),
            new IndieBox::WebAppTest::StateCheck(
                    name  => 'file-uploaded',
                    check => sub {
                        my $c = shift;

                        # need to login first
                        my $postData = {
                            'user'            => $adminlogin,
                            'password'        => $adminpass,
                            'timezone-offset' => 0
                        };
                        
                        $c->post( '/', $postData ); # tested that earlier

                        my $response = $c->get( $filesAppRelativeUrl . '/download/' . $testFile );
                        $c->mustStatus( $response, 200, 'Test file not found' );

                        return 1;
                    }
            )
    ]
);

$TEST;
