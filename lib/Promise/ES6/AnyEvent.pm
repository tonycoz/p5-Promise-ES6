package Promise::ES6::AnyEvent;

use strict;
use warnings;

use parent qw(Promise::ES6);

=encoding utf-8

=head1 NAME

Promise::ES6::AnyEvent - L<Promises/A+-compliant|https://github.com/promises-aplus/promises-spec> promises

=head1 DESCRIPTION

This subclass of L<Promise::ES6> incorporates L<AnyEvent> in order to
implement full Promises/A+ compliance. Specifically, this class defers
execution of resolve and reject callbacks to the end of the current event
loop iteration.

=head1 SEE ALSO

L<Promises>, L<AnyEvent::Promises>, and L<AnyEvent::XSPromises> all provide
functionality similar to this class’s.

=cut

#----------------------------------------------------------------------

use AnyEvent ();

#----------------------------------------------------------------------

sub new {
    my ($class, $cr) = @_;

    return $class->SUPER::new( sub {
        my ($res, $rej) = @_;

        local $@;

        my $ok = eval {
            $cr->(
                sub { AnyEvent::postpone( sub { $res->(@_) } ) },
                sub { AnyEvent::postpone( sub { $rej->(@_) } ) },
            );

            1;
        };

        if (!$ok) {
            my $err = $@;
            AnyEvent::postpone( sub { $rej->($err) } );
        }
    } );
}

1;
