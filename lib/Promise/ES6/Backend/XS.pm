package Promise::ES6;

# This backend uses Promise::XS to implement most functionality.

use Promise::XS ();

*DETECT_MEMORY_LEAKS = *Promise::XS::DETECT_MEMORY_LEAKS;

sub _new {
    my ($class, $cr) = @_;

    my $deferred = Promise::XS::deferred();

    my $self = \( $deferred->promise() );

    my $soft_reject = 1;

    my $ok = eval {
        $cr->(
            sub {

                # As of now, the backend doesn’t check whether the value
                # given to resolve() is a promise. ES6 handles that case,
                # though, so we do, too.
                if (UNIVERSAL::isa($_[0], __PACKAGE__)) {
                    $_[0]->then( sub { $deferred->resolve($_[0]) } );
                }
                else {
                    $deferred->resolve($_[0]);
                }
            },
            sub {
                $deferred->reject($_[0]);
                $deferred->clear_unhandled_rejection() if $soft_reject;
            },
        );

        1;
    };

    $soft_reject = 0;

    if (!$ok) {
        $deferred->reject(my $err = $@);
    }

    return bless $self, $class;
}

sub then {
    my ($self, $on_res, $on_rej) = @_;

    return bless \( $$self->then( $on_res, $on_rej ) ), ref($self);
}

1;
