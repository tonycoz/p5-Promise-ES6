#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

# This test throws unhandled-rejection warnings … do they matter?
#use Test::FailWarnings;

use Promise::ES6;

my $failed_why;

BEGIN {
    eval 'use Test::Future::AsyncAwait::Awaitable; 1' or $failed_why = $@;
}

plan skip_all => "Can’t run test: $failed_why" if $failed_why;

my @usable_backends;

if (eval "require AnyEvent") {
    push @usable_backends, ['AnyEvent'];
}

if (eval "require IO::Async::Loop") {
    push @usable_backends, ['IO::Async', IO::Async::Loop->new()];
}

if (eval 'require Mojo::IOLoop') {
    push @usable_backends, ['Mojo::IOLoop'];
}

if (@usable_backends) {
    for my $backend_ar (@usable_backends) {
        note "Testing: $backend_ar->[0]";

        Promise::ES6::use_event(@$backend_ar);

        Test::Future::AsyncAwait::Awaitable::test_awaitable(
            'Promise::ES6 conforms to Awaitable API',
            class => 'Promise::ES6',
            new => sub { Promise::ES6->new( sub {} ) },
        );
    }
}
else {
    plan skip_all => 'No supported event interfaces are available.';
}

done_testing;
