#!/usr/bin/env perl

package t::then_success_with_no_handler;

use strict;
use warnings;

use parent qw(Test::Class::Tiny);

use Test::More;
use Test::Fatal;
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
    my $eventer = Eventer->new();

    my $test_value = 'first';

    my @todo;

    my $p = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;

        push @todo, sub {
            if ($eventer->has_happened('ready1') && !$eventer->has_happened('resolved1')) {
                is $test_value, 'first';
                $test_value = 'second';
                $resolve->('first resolve');
                $eventer->happen('resolved1');
            }
        };
    });

    my $pid = fork or do {
        Time::HiRes::sleep(0.2);
        $eventer->happen('ready1');

        exit;
    };

    is( PromiseTest::await($p, \@todo), 'first resolve' );

    waitpid $pid, 0;
}

if (!caller) {
    __PACKAGE__->runtests();
}

1;
