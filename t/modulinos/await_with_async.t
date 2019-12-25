#!/usr/bin/env perl

package t::await_with_async;

use strict;
use warnings;

use parent qw(Test::Class::Tiny);

use Test::More;
use Test::FailWarnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use MemoryCheck;

use Eventer;
use PromiseTest;

use Promise::ES6;

sub T0_tests {
    my $eventer = Eventer->new();

    my $resolve;

    my @checkers;

    my $promise = Promise::ES6->new(sub {
        ($resolve) = @_;

        push @checkers, sub {
            if ($eventer->has_happened('waited') && !$eventer->has_happened('resolved')) {
                $eventer->happen('resolved');
                $resolve->(123);
            }
        };
    });

    my $pid = fork or do {
        Time::HiRes::sleep(0.1);
        $eventer->happen('waited');
        exit;
    };

    isa_ok $promise, 'Promise::ES6';
    is PromiseTest::await($promise, \@checkers), 123, 'get resolved value';

    waitpid $pid, 0;
}

__PACKAGE__->runtests() if !caller;

1;
