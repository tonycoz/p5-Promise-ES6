package t::race;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use parent qw(PromiseTest);

use Time::HiRes;

use Test::Fatal qw(exception);
use Test::More;

use Promise::ES6;

sub race : Tests {
    my ($self) = @_;

    my @resolves;

    my $p1 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;

        push @resolves, sub {
            if ($self->has_happened('ready1') && !$self->has_happened('resolved1')) {
                $resolve->(1);
                $self->happen('resolved1');
            }
        };
    });

    my $p2 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;

        push @resolves, sub {
            if ($self->has_happened('ready2') && !$self->has_happened('resolved2')) {
                $resolve->(2);
                $self->happen('resolved2');
            }
        };
    });

    my $pid = fork or do {
        $self->happen('ready2');

        $self->wait_until('resolved2');

        $self->happen('ready1');

        exit;
    };

    my $race = Promise::ES6->race([$p1, $p2]);

    my $value = $self->await( $race, \@resolves );
    is $value, 2;

    waitpid $pid, 0;
}

sub race_with_value : Tests {
    my ($self) = @_;

    my $resolve_cr;

    # This will never resolve.
    my $p1 = Promise::ES6->new(sub {});

    my $p2 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->(2);
    });

    my $value = $self->await( Promise::ES6->race([$p1, $p2]) );

    is $value, 2, 'got raw value instantly';
}

sub race_success : Tests {
    my ($self) = @_;

    my @resolves;

    my $p1 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;

        push @resolves, sub {
            if ($self->has_happened('ready1') && !$self->has_happened('resolved1')) {
                $resolve->(1);
                $self->happen('resolved1');
            }
        };
    });
    my $p2 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;

        push @resolves, sub {
            if ($self->has_happened('ready2') && !$self->has_happened('resolved2')) {
                $reject->({ message => 'fail' });
                $self->happen('resolved2');
            }
        };
    });

    my $pid = fork or do {
        $self->happen('ready1');

        $self->wait_until('resolved1');

        $self->happen('ready2');

        exit;
    };

    my $race = Promise::ES6->race([$p1, $p2]);

    my $value = $self->await( $race, \@resolves );
    is $value, 1;

    waitpid $pid, 0;
}

sub race_fail : Tests {
    my ($self) = @_;

    my @resolves;

    my $p1 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;

        push @resolves, sub {
            if ($self->has_happened('ready1') && !$self->has_happened('resolved1')) {
                $resolve->(1);
                $self->happen('resolved1');
            }
        };
    });

    my $p2 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;

        push @resolves, sub {
            if ($self->has_happened('ready2') && !$self->has_happened('resolved2')) {
                $reject->({ message => 'fail' });
                $self->happen('resolved2');
            }
        };
    });

    my $pid = fork or do {
        $self->happen('ready2');

        $self->wait_until('resolved2');

        $self->happen('ready1');

        exit;
    };

    my $race = Promise::ES6->race([$p1, $p2]);

    is_deeply exception {
        diag $self->await( $race, \@resolves )
    }, { message => 'fail' };

    waitpid $pid, 0;
}

__PACKAGE__->new()->runtests;
