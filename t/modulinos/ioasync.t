#!/usr/bin/env perl

package t::ioasync;

use strict;
use warnings;
use autodie;

BEGIN {
    my @path = File::Spec->splitdir( __FILE__ );
    splice( @path, -2, 2, 'lib' );
    push @INC, File::Spec->catdir(@path);
}

use parent qw( EventTest );

my ($LOOP, $LOOP_GUARD);

use Test::More;

if (!caller) {
    __PACKAGE__->runtests();
}

use constant _BACKEND => 'IOAsync';

use Promise::ES6::IOAsync;

sub _REQUIRE {
    require IO::Async::Loop;
    require Promise::ES6::IOAsync;

    $LOOP = IO::Async::Loop->new();
    $LOOP_GUARD = Promise::ES6::IOAsync::SET_LOOP($LOOP);

    1;
}

sub _RESOLVE {
    my ($class, $promise) = @_;

    $promise->finally( sub { $LOOP->stop() } );

    $LOOP->run();
}

1;
