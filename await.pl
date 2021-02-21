#!/usr/bin/env perl

use strict;
use warnings;

use experimental 'signatures';

use FindBin;
use lib "$FindBin::Bin/lib";
use Promise::ES6;

#use blib "$FindBin::Bin/Future-AsyncAwait-0.47";

use Future::AsyncAwait future_class => 'Promise::ES6';

use IO::Async::Loop;
use IO::Async::Timer::Countdown;

sub delay ($loop, $secs) {
    return Promise::ES6->new( sub ($res, @) {
        my $timer; $timer = IO::Async::Timer::Countdown->new(
            delay => $secs,
            on_expire => sub {
                undef $timer;
                $res->($secs);
            },
        );

        $timer->start();
        $loop->add($timer);
    } );
}

async sub thethings ($loop) {
    print "waiting …\n";

    my $waited_p = delay($loop, 0.2);

    my $waited = await $waited_p;

    print "waited $waited\n";

    return 5;
}

#sub thethings_plain {
#    print "waiting …\n";
#    return delay(3.2)->then( sub ($val) {
#        print "waited $val\n";
#        5;
#    } );
#}

my $loop = IO::Async::Loop->new();
Promise::ES6::use_event('IO::Async', $loop);

# It works thus:
#my $promise1 = thethings($loop);
#my $promise = $promise1->then( sub ($val) {

my $promise = thethings($loop)->then( sub ($val) {
    print "async gave $val\n";
    $loop->stop();
} );

$loop->run();

1;
