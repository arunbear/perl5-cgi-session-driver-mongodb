package CGI::Session::Driver::mongodb;

use base 'CGI::Session::Driver';
use Carp qw/cluck croak/;
#use Carp::Assert;
use MongoDB;

sub init {
    my $self = shift;

    my %arg;
    if($self->{host}) {
        $arg{host} = $self->{host};
    }
    my $conn = MongoDB::Connection->new(%arg);
    my $db = $conn->get_database($self->{Database});
    $self->{sessions} = $db->get_collection($self->{CollectionName} || 'sessions');
    $self->{IdFieldName} ||= 'id';
    $self->{DataFieldName} ||= 'datastr';
    $self->{sessions}->ensure_index({ $self->{IdFieldName} => 1 }, { unique => true });
}

sub store {
    my ($self, $sid, $datastr) = @_;
    croak "store(): usage error" unless $sid && $datastr;

    my %timestamp;
    
    if($self->{AddTimeStamp}) {
        $self->{TimeStampFieldName} ||= 'mtime';
        $self->{sessions}->ensure_index({ $self->{TimeStampFieldName} => 1 });
        %timestamp = ($self->{TimeStampFieldName} => time());
    }
    # Store $datastr, which is an already serialized string of data.
    $self->{sessions}->update(
        { $self->{IdFieldName} => $sid }, 
        { '$set' =>  { $self->{DataFieldName} => $datastr, %timestamp } }, 
        { 'upsert' => 1, safe => 1 }
    )
      or return $self->set_error("store(): save() failed " . MongoDB::Database::last_error());
    return 1;
}

sub retrieve {
    my ($self, $sid) = @_;
    # Return $datastr, which was previously stored using above store() method.
    # Return $datastr if $sid was found. Return 0 or "" if $sid doesn't exist
    my $doc = $self->{sessions}->find_one({ $self->{IdFieldName} => $sid });
    return 0 unless $doc;
    return $doc->{$self->{DataFieldName}};
}

sub remove {
    my ($self, $sid) = @_;
    my $ret = $self->{sessions}->remove({ $self->{IdFieldName} => $sid }, { safe => 1 });
    # Remove storage associated with $sid. Return any true value indicating success,
    # or undef on failure.
    return $ret ? $ret : undef;
}

sub traverse {
    my ($self, $coderef) = @_;
    # execute $coderef for each session id passing session id as the first and the only
    # argument
    my $cursor = $self->{sessions}->find();
    while (my $doc = $cursor->next) {
        $coderef->($doc->{$self->{IdFieldName}});
    }
    $cursor->reset;
}

1; # End of CGI::Session::Driver::mongodb

__END__

=head1 NAME

CGI::Session::Driver::mongodb - The great new CGI::Session::Driver::mongodb!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use CGI::Session::Driver::mongodb;

    my $foo = CGI::Session::Driver::mongodb->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Arun Prasaad, C<< <arunbear at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cgi-session-driver-mongodb at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Session-Driver-mongodb>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::Session::Driver::mongodb


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Session-Driver-mongodb>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CGI-Session-Driver-mongodb>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CGI-Session-Driver-mongodb>

=item * Search CPAN

L<http://search.cpan.org/dist/CGI-Session-Driver-mongodb/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Arun Prasaad.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

