#!/usr/bin/env perl

package t::catch_asyncreject;

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
    my $eventer = Eventer->new();

    my @checkers;

    my $p = Promise::ES6->new(sub {
        (undef, my $reject) = @_;

        push @checkers, sub {
            if ($eventer->has_happened('thing')) {
                $reject->('oh my god!');
            }
        };
    })->catch(sub {
        my ($reason) = @_;
        return $reason;
    });

    my $pid = fork or do {
        Time::HiRes::sleep(0.1);
        $eventer->happen('thing');
        exit;
    };

    is PromiseTest::await($p, \@checkers), 'oh my god!';

    waitpid $pid, 0;
}

if (!caller) {
    __PACKAGE__->runtests();
}

1;
