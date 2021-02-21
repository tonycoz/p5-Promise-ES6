#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

BEGIN {
    for my $req ( qw( Future::AsyncAwait  AnyEvent ) ) {
        eval "require $req" or plan skip_all => 'No Future::AsyncAwait';
    }
}

use Promise::ES6;

use Future::AsyncAwait future_class => 'Promise::ES6';

sub delay {
    my $secs = shift;

    return Promise::ES6->new( sub {
        my $res = shift;

        my $timer; $timer = AnyEvent->timer(
            after => $secs,
            cb => sub {
                undef $timer;
                $res->($secs);
            },
        );
    } );
}

async sub thethings {
    print "waiting …\n";

    await delay(0.1);

    return 5;
}

my $cv = AnyEvent->condvar();

thethings()->then($cv);

my ($got) = $cv->recv();

is $got, 5, 'expected resolution';

done_testing;
