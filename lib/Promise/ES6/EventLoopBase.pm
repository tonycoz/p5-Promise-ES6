package Promise::ES6::EventLoopBase;

use strict;
use warnings;

use parent qw(Promise::ES6);

sub new {
    my ($class, $cr) = @_;

    return $class->SUPER::new( sub {
        my ($res, $rej) = @_;

        local $@;

        my $ok = eval {
            $cr->(
                sub { $class->_postpone( sub { $res->(@_) } ) },
                sub { $class->_postpone( sub { $rej->(@_) } ) },
            );

            1;
        };

        if (!$ok) {
            my $err = $@;
            $class->_postpone( sub { $rej->($err) } );
        }
    } );
}

1;
