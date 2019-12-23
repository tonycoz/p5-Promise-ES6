package Promise::ES6;

use Promise::XS ();

#BEGIN {
#    *DETECT_MEMORY_LEAKS = \$Promise::ES6::XS::DETECT_MEMORY_LEAKS;
#
#    no strict 'refs';
#    for my $fn ( qw( new then catch finally resolve reject all race DESTROY ) ) {
#        if (Promise::ES6::XS->can($fn)) {
#            *{$fn} = Promise::ES6::XS->can($fn);
#        }
#    }
#}

sub _new {
    my ($class, $cr) = @_;

    my $deferred = Promise::XS::deferred();

    # 2nd el = warn on unhandled rejection
    my $self = [ $deferred->promise() ];

    my $soft_reject;

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
                $soft_reject = 1;
            },
        );

        1;
    };

    $self->[1] = 1 if $soft_reject;

    if (!$ok) {
        $deferred->reject(my $err = $@);
    }

    return bless $self, $class;
}

sub then {
    my ($self, $on_res, $on_rej) = @_;

    return bless [ $self->[0]->then( $on_res, $on_rej ) ], ref($self);
}

sub DESTROY {
    my ($self) = @_;

    if (!$self->[1]) {
        my $unhandled_rejection_sr = $self->[0]->_unhandled_rejection_sr();

        if ($unhandled_rejection_sr) {
            warn "$self: Unhandled rejection: $$unhandled_rejection_sr";
        }
    }

    return;
}

1;
