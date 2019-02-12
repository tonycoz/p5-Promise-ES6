package t::await;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use parent qw(PromiseTest);

use Time::HiRes;

use Test::Fatal qw(exception);
use Test::More;

use Promise::ES6;

sub await_func : Tests {
    my ($self) = @_;

    my $promise = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->(123);
    });

    isa_ok $promise, 'Promise::ES6';
    is $self->await($promise), 123, 'get resolved value';
}

sub reject_await : Tests {
    my ($self) = @_;

    my $promise = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $reject->({ message => 'oh my god' });
    });

    isa_ok $promise, 'Promise::ES6';
    is_deeply exception { $self->await($promise) }, { message => 'oh my god' };
}

sub exception_await : Tests {
    my ($self) = @_;

    my $promise = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        die { message => 'oh my god' };
    });

    isa_ok $promise, 'Promise::ES6';
    is_deeply exception { $self->await($promise) }, { message => 'oh my god' };
}

sub then_await : Tests {
    my ($self) = @_;

    my $promise = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->(123);
    })->then(sub {
        my ($value) = @_;
        return $value * 2;
    });

    isa_ok $promise, 'Promise::ES6';
    is $self->await($promise), 123 * 2, 'get resolved value';
}

sub await_with_async : Tests {
    my ($self) = @_;

    my $resolve;

    my @checkers;

    my $promise = Promise::ES6->new(sub {
        ($resolve) = @_;

        push @checkers, sub {
            if ($self->has_happened('waited') && !$self->has_happened('resolved')) {
                $self->happen('resolved');
                $resolve->(123);
            }
        };
    });

    my $pid = fork or do {
        Time::HiRes::sleep(0.1);
        $self->happen('waited');
        exit;
    };

    isa_ok $promise, 'Promise::ES6';
    is $self->await($promise, \@checkers), 123, 'get resolved value';

    waitpid $pid, 0;
}

sub then_await_with_async : Tests {
    my ($self) = @_;

    my @checkers;

    my $promise = Promise::ES6->new(sub {
        my ($resolve) = @_;

        push @checkers, sub {
            if ($self->has_happened('ready1') && !$self->has_happened('resolve1')) {
                $self->happen('resolve1');
                $resolve->(123);
            }
        };
    })->then(sub {
        my ($value) = @_;

        return Promise::ES6->new(sub {
            my ($resolve, $reject) = @_;

            push @checkers, sub {
                if ($self->has_happened('ready2') && !$self->has_happened('resolve2')) {
                    $self->happen('resolve2');
                    $resolve->($value * 2);
                }
            };
        });
    });

    my $pid = fork or do {

        Time::HiRes::sleep(0.1);
        $self->happen('ready1');

        Time::HiRes::sleep(0.1);
        $self->happen('ready2');

        exit;
    };

    isa_ok $promise, 'Promise::ES6';
    is $self->await($promise, \@checkers), 123 * 2;

    waitpid $pid, 0;
}

__PACKAGE__->new()->runtests;
