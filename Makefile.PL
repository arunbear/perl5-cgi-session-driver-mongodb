use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CGI::Session::Driver::mongodb',
    AUTHOR              => q{Arun Prasaad <arunbear@cpan.org>},
    VERSION_FROM        => 'lib/CGI/Session/Driver/mongodb.pm',
    ABSTRACT_FROM       => 'lib/CGI/Session/Driver/mongodb.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CGI-Session-Driver-mongodb-*' },
);
