#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'CGI::Session::Driver::mongodb' );
}

diag( "Testing CGI::Session::Driver::mongodb $CGI::Session::Driver::mongodb::VERSION, Perl $], $^X" );
