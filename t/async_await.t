#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

# This test throws unhandled-rejection warnings … do they matter?
#use Test::FailWarnings;

my $failed_why;

BEGIN {
    eval 'use Test::Future::AsyncAwait::Awaitable; 1' or $failed_why = $@;
}

if (!$failed_why) {
    my $backend;

    my @backends = ('AnyEvent', 'IO::Async', 'Mojolicious');

    for my $try (@backends) {
        if (eval "require $try") {
            $backend = $try;
            last;
        }
    }

    if ($backend) {
        Promise::ES6::use_event($backend);
    }
    else {
        $failed_why = "No event interface (@backends) is available.";
    }
}

plan skip_all => "Can’t run test: $failed_why" if $failed_why;

use Promise::ES6;

Test::Future::AsyncAwait::Awaitable::test_awaitable(
    'Promise::ES6 conforms to Awaitable API',
    class => 'Promise::ES6',
    new => sub { Promise::ES6->new( sub {} ) },
);

done_testing;
