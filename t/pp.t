#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Promise::ES6 (backend => 'PP');

use BackendTest;

use Test::More;

BackendTest::run_modulinos();

done_testing();

1;
