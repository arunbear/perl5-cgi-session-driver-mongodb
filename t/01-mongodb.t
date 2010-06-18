use strict;
use warnings;
use CGI::Session;
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

plan tests => 6;

my $sid;

# create
{
    my $session = CGI::Session->new(
        "driver:mongodb", 
        undef, 
        {
            database => 'test',
        }
    );
    $sid = $session->id;
    diag "session id is: $sid"; 
    ok($sid, 'got session id');

    $session->param('f_name', 'Sherzod');
}

# load
{
    my $session = CGI::Session->new(
        "driver:mongodb", 
        $sid, 
        {
            database => 'test',
        }
    );
    ok($session, 'load session id');
    is($session->id, $sid, 'check reloaded session id');
    is($session->param('f_name'), 'Sherzod', 'got stored value');

    # delete
    $session->delete();
}
{
    my $session = CGI::Session->new(
        "driver:mongodb", 
        $sid, 
        {
            database => 'test',
        }
    );
    isnt($session->id, $sid, 'check deleted session id');
    is_deeply($session->param('f_name'), undef, 'delete session');
}
__END__
