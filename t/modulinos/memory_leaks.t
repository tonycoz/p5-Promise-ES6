#!/usr/bin/env perl

package t::memory_leaks;

use strict;
use warnings;

use parent qw(Test::Class::Tiny);

use Test::More;
use Test::FailWarnings;

use Promise::ES6;

BEGIN {
    my @path = File::Spec->splitdir( __FILE__ );
    splice( @path, -2, 2, 'lib' );
    push @INC, File::Spec->catdir(@path);
}
use MemoryCheck;

sub T0_tests {
    ok 1, 'dummy assertion';

    {
        my ($res, $rej);
        my $p = Promise::ES6->new( sub { ($res, $rej) = @_ } )->catch( sub {  } );

        $rej->(123);
    }
}

if (!caller) {
    __PACKAGE__->runtests();
}

1;
