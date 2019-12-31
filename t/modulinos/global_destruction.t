#!/usr/bin/env perl

package t::global_destruction;

use strict;
use warnings;

use parent qw(Test::Class::Tiny);

use Test::More;

use Promise::ES6;

sub T1_tests {

    my $out = `$^X -MPromise::ES6 -e'\$Promise::ES6::DETECT_MEMORY_LEAKS = 1; my \$prm = Promise::ES6->new( sub { die "abc"; } );'`;
    warn "Nonzero exit: $?" if $?;

    ok 1;
}

if (!caller) {
    __PACKAGE__->runtests();
}

1;
