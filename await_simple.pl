#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Promise::ES6;

use Time::HiRes;

#use blib "$FindBin::Bin/Future-AsyncAwait-0.47";

use Future::AsyncAwait future_class => 'Promise::ES6';

my $resolver_cr;
my $p = Promise::ES6->new( sub { $resolver_cr = shift } );

async sub do_await {
    my $p = shift;
    return await $p;
}

do_await($p)->then( sub { print "got " . shift . $/ } );

Time::HiRes::sleep(0.1);

$resolver_cr->(5);

1;
