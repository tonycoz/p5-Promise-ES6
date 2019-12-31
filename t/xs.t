#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More;

use BackendTest;

SKIP: {
    require Promise::ES6;

    eval { Promise::ES6->import( backend => 'XS' ); 1 } or do {
        skip "Failed to load XS backend: $@";
    };

    BackendTest::run_modulinos();
}

done_testing();

1;
