use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use MemoryCheck;

use Eventer;
use PromiseTest;

use Promise::ES6;

sub _bind {
    my ($sub, @args) = @_;

    return sub {
        $sub->(@args, @_);
    };
}

{
    my $eventer = Eventer->new();

    my @resolves;

    my $p1 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;

        push @resolves,
          _bind(sub {
                    my ($eventer, $resolve) = @_;

                    if ($eventer->has_happened('ready1') && !$eventer->has_happened('resolved1')) {
                        $resolve->(1);
                        $eventer->happen('resolved1');
                    }
                }, $eventer, $resolve);
    });

    my $p2 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;

        push @resolves,
          _bind(sub {
                    my ($eventer, $resolve) = @_;

                    if ($eventer->has_happened('ready2') && !$eventer->has_happened('resolved2')) {
                        $resolve->(2);
                        $eventer->happen('resolved2');
                    }
                }, $eventer, $resolve);
    });

    my $pid = fork or do {
        $eventer->happen('ready2');

        $eventer->wait_until('resolved2');

        $eventer->happen('ready1');

        exit;
    };

    my $race = Promise::ES6->race([$p1, $p2]);

    my $value = PromiseTest::await( $race, \@resolves );
    is $value, 2;

    waitpid $pid, 0;

    # This appears to be needed to solve a garbage-collection problem
    # that Perl 5.18 fixed but that persists with Devel::Cover.
    splice @resolves if $^V lt 5.18.0 || $INC{'Devel/Cover.pm'};
}

done_testing();
