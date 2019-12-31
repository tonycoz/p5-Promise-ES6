#!/usr/bin/env perl

package t::unhandled_rejection;

use strict;
use warnings;

use parent qw(Test::Class::Tiny);

use File::Spec;

BEGIN {
    my @path = File::Spec->splitdir( __FILE__ );
    splice( @path, -2, 2, 'lib' );
    push @INC, File::Spec->catdir(@path);
}

use MemoryCheck;

use Test::More;
use Test::Deep;
use Test::FailWarnings;

use Promise::ES6;

sub T0_tests {
    my @warnings;
    local $SIG{'__WARN__'} = sub { push @warnings, @_ };

    #----------------------------------------------------------------------

    my @tests = (
        sub {
            Promise::ES6->new( sub { die 123 } );

            cmp_deeply(
                \@warnings,
                [ re( qr<123> ) ],
                'warn() as expected when constructor callback die()s',
            );
        },
        sub {
            {
                my ($res, $rej);
                my $p = Promise::ES6->new( sub { ($res, $rej) = @_ } );

                $rej->(123);
            }

            cmp_deeply(
                \@warnings,
                [ re( qr<123> ) ],
                'warn() as expected when rejection after constructor',
            );
        },
        sub {
            my ($res, $rej);
            my $p = Promise::ES6->new( sub { ($res, $rej) = @_ } )->catch( sub {  } );

            $rej->(123);

            cmp_deeply(
                \@warnings,
                [],
                'don’t warn() if there is a rejection handler',
            ) or diag explain \@warnings;
        },
        sub {
            Promise::ES6->new( sub { my ($res, $rej) = @_; $rej->(123) } );

            cmp_deeply(
                \@warnings,
                [],
                'do NOT warn() when constructor callback rejects “peacefully”',
            ) or diag explain \@warnings;
        },
        sub {
            Promise::ES6->new( sub { die 123 } )->then( sub { 234 } );

            cmp_deeply(
                \@warnings,
                [ re( qr<123> ) ],
                'warn() only once',
            ) or diag explain \@warnings;
        },

        sub {
            my $p = Promise::ES6->new( sub { die 123 } );

            $p->catch( sub { 234 } )->then( sub { die 345 } );

            cmp_deeply(
                \@warnings,
                [ re( qr<345> ) ],
                'warn() again when a promise is caught after initial failure but then rejects later (uncaught)',
            ) or diag explain \@warnings;
        },
    );

    for my $t (@tests) {
        $t->();
        @warnings = ();
    }
}

__PACKAGE__->runtests() if !caller;

1;
