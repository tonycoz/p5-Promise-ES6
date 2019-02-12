package t::then;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use parent qw(PromiseTest);

use Time::HiRes;

use Test::More;

use Promise::ES6;

sub then_success : Tests {
    my ($self) = @_;

    my @todo;

    my $test_value = 'first';

    my $p = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;

        push @todo, sub {
            if ($self->has_happened('ready1') && !$self->has_happened('resolved1')) {
                is $test_value, 'first';
                $test_value = 'second';
                $resolve->('first resolve');
                $self->happen('resolved1');
            }
        };
    })->then(sub {
        my ($value) = @_;
        is $value, 'first resolve';
        is $test_value, 'second';
        $test_value = 'third';
        return 'second resolve';
    })->then(sub {
        my ($value) = @_;
        is $value, 'second resolve';

        is $test_value, 'third';
        $test_value = 'fourth';

        return Promise::ES6->new(sub {
            my ($resolve, $reject) = @_;

            push @todo, sub {
                if ($self->has_happened('ready2') && !$self->has_happened('resolved2')) {
                    is $test_value, 'fourth';
                    $test_value = 'fifth';
                    $resolve->('third resolve');
                    $self->happen('resolved2');
                }
            };
        });
    });

    my $pid = fork or do {
        Time::HiRes::sleep(0.2);

        $self->happen('ready1');

        Time::HiRes::sleep(0.2);

        $self->happen('ready2');

        exit;
    };

    is( $self->await($p, \@todo), 'third resolve' );

    waitpid $pid, 0;
}

sub then_success_with_no_handler : Tests {
    my ($self) = @_;

    my $test_value = 'first';

    my @todo;

    my $p = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;

        push @todo, sub {
            if ($self->has_happened('ready1') && !$self->has_happened('resolved1')) {
                is $test_value, 'first';
                $test_value = 'second';
                $resolve->('first resolve');
                $self->happen('resolved1');
            }
        };
    });

    my $pid = fork or do {
        Time::HiRes::sleep(0.2);
        $self->happen('ready1');

        exit;
    };

    is( $self->await($p, \@todo), 'first resolve' );

    waitpid $pid, 0;
}

sub already_resolved : Tests {
    my $called = 0;
    my $p = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->('executed');
    })->then(sub {
        my ($value) = @_;
        $called = 'called';
    });
    is $called, 'called', 'call fulfilled callback if promise already reasolved';
}

__PACKAGE__->runtests;
