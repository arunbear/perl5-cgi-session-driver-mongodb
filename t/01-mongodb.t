use strict;
use warnings;
use CGI::Session;
use MongoDB;
use Test::More;

BEGIN {
    eval "use MongoDB";
    if ($@) {
        plan skip_all => "MongoDB.pm installed is required to run this test";
    }

    eval "MongoDB::Connection->new(host => 'localhost');";
    if ($@) {
        plan skip_all => "MongoDB on localhost is required to run this test";
    }

}

plan tests => 14;

my $sid;
my %Options;
basic_tests();
tests_with_options();

sub basic_tests {
    do_tests();
}

sub tests_with_options {
    %Options = (
        CollectionName => 'my_sessions',
        IdFieldName    => 'my_id',
        DataFieldName  => 'my_data', 
        AddTimeStamp   => 1,
    );
    diag "tests_with_options:"; 
    diag explain \%Options;
    test_create();
    test_load_and_delete();
}

sub do_tests {
    test_create();
    test_load_and_delete();
    test_traverse();
}

sub get_session {
    my $sid = shift;
    return CGI::Session->new(
        "driver:mongodb", 
        $sid, 
        {
            Database => 'test',
            %Options,
        }
    );
}

sub test_create {
    my $session = get_session();
    $sid = $session->id;
    diag "session id is: $sid"; 
    ok($sid, 'got session id');

    $session->param('f_name', 'Sherzod');
}

sub test_load_and_delete {
    {
        my $session = get_session($sid);
        #diag explain $session;
        ok($session, 'load session id');
        is($session->id, $sid, 'check reloaded session id');
        is($session->param('f_name'), 'Sherzod', 'got stored value');

        # delete
        $session->delete();
    }
    {
        my $session = get_session($sid);
        isnt($session->id, $sid, 'check deleted session id');
        is_deeply($session->param('f_name'), undef, 'delete session');
    }
}

sub do_find {
    my $callback = shift;
    CGI::Session->find(
        "driver:mongodb", 
        $callback, 
        {
            Database => 'test',
        }
    );
}

sub test_traverse {
    my $conn = MongoDB::Connection->new;
    my $db = $conn->get_database('test');
    my $sessions = $db->get_collection('sessions');
    $sessions->drop;
    my $count = 0;

    undef $sid;
    for (1 .. 3) {
        my $session = get_session();
        $session->param('number' => $_);
    }
    do_find(sub { ++$count });

    diag "$count sessions found";
    cmp_ok($count, '==', 3, 'found sessions');

    my $sum = 0;

    do_find(sub { 
        my $session = shift;
        $sum += $session->param('number');
    });
    cmp_ok($sum, '==', 6, 'found numbers in sessions');
}

#done_testing();

__END__
