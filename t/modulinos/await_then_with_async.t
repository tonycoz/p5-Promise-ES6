#!/usr/bin/env perl

package t::await_then_with_async;

use strict;
use warnings;

use parent qw(Test::Class::Tiny);

use Test::More;
use Test::FailWarnings;

BEGIN {
    my @path = File::Spec->splitdir( __FILE__ );
    splice( @path, -2, 2, 'lib' );
    push @INC, File::Spec->catdir(@path);
}


use MemoryCheck;

use Eventer;
use PromiseTest;

use Promise::ES6;

sub T0_tests {
    diag "MASTER PID: $$";

    my $eventer = Eventer->new();

    my @checkers;

    my $promise = Promise::ES6->new(sub {
        my ($resolve) = @_;

        push @checkers, sub {
            if ($eventer->has_happened('ready1') && !$eventer->has_happened('resolve1')) {
                $eventer->happen('resolve1');
                $resolve->(123);
            }
        };
    })->then(sub {
        my ($value) = @_;

        return Promise::ES6->new(sub {
            my ($resolve, $reject) = @_;

            push @checkers, sub {
                if ($eventer->has_happened('ready2') && !$eventer->has_happened('resolve2')) {
                    $eventer->happen('resolve2');
                    $resolve->($value * 2);
                }
            };
        });
    });

    my $pid = fork or do {

        Time::HiRes::sleep(0.1);
        $eventer->happen('ready1');

        Time::HiRes::sleep(0.1);
        $eventer->happen('ready2');

        exit;
    };

    isa_ok $promise, 'Promise::ES6';
    is PromiseTest::await($promise, \@checkers), 123 * 2;

    waitpid $pid, 0;
}

if (!caller) {
    __PACKAGE__->runtests();
}

1;
