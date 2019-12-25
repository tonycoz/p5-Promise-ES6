package t::race;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use MemoryCheck;
use PromiseTest;

use parent qw(Test::Class::Tiny);

use Time::HiRes;

use Test::Fatal qw(exception);
use Test::More;
use Test::FailWarnings;

use Promise::ES6;

sub T0_race_with_value {
    my ($self) = @_;

    my $resolve_cr;

    # This will never resolve.
    my $p1 = Promise::ES6->new(sub {});

    my $p2 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->(2);
    });

    my $value = PromiseTest::await( Promise::ES6->race([$p1, $p2]) );

    is $value, 2, 'got raw value instantly';
}

__PACKAGE__->new()->runtests if !caller;

1;
