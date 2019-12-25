#!/usr/bin/env perl

package t::memory_leaks;

use strict;
use warnings;

use parent qw(Test::Class::Tiny);

use Test::More;
use Test::FailWarnings;

use Promise::ES6;

use FindBin;
use lib "$FindBin::Bin/lib";
use MemoryCheck;

sub T0_tests {
    ok 1, 'dummy assertion';

    {
        my ($res, $rej);
        my $p = Promise::ES6->new( sub { ($res, $rej) = @_ } )->catch( sub {  } );

        $rej->(123);
    }
}

__PACKAGE__->runtests() if !caller;

1;
