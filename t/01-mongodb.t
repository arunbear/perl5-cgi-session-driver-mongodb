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

plan tests => 8;

sub get_session {
    my $sid = shift;
    return CGI::Session->new(
        "driver:mongodb", 
        $sid, 
        {
            database => 'test',
        }
    );
}

my $sid;

# create
{
    my $session = get_session();
    $sid = $session->id;
    diag "session id is: $sid"; 
    ok($sid, 'got session id');

    $session->param('f_name', 'Sherzod');
}

# load
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

# traverse
my $conn = MongoDB::Connection->new;
my $db = $conn->get_database('test');
my $sessions = $db->get_collection('sessions');
$sessions->drop;
my $count = 0;

sub do_find {
    my $callback = shift;
    CGI::Session->find(
        "driver:mongodb", 
        $callback, 
        {
            database => 'test',
        }
    );
}

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

#done_testing();

__END__
