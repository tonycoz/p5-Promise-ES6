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
        $resolves[1] = sub { $resolve->(1) };
    });
    my $p2 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolves[0] = sub { $resolve->(2) };
    });

    local $SIG{'USR1'} = sub {
        (shift @resolves)->();
    };

    my $pid = fork or do {
        while (1) {
            kill 'USR1', getppid();
            Time::HiRes::sleep(0.1);
        }

        exit;
    };

    my $value = $self->await( Promise::ES6->race([$p1, $p2]) );
    is $value, 2;

    kill 'KILL', $pid;
    waitpid $pid, 0;
}

sub race_with_value : Tests {
    my ($self) = @_;

    my $resolve_cr;

    my $p1 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;

        $resolve_cr = sub { $resolve->(1) };
    });
    my $p2 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->(2);
    });

    local $SIG{'USR1'} = sub {
        $resolve_cr->();
    };

    local $SIG{'CHLD'} = 'IGNORE';
    fork or do {
        kill 'USR1', getppid();

        exit;
    };

    my $value = $self->await( Promise::ES6->race([$p1, $p2]) );
    is $value, 2, 'got raw value instantly';
}

sub race_success : Tests {
    my ($self) = @_;

    my @resolves;

    my $p1 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;

        $resolves[0] = sub { $resolve->(1); }
    });
    my $p2 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;

        $resolves[1] = sub { $reject->({ message => 'fail' }); }
    });

    local $SIG{'USR1'} = sub {
        (shift @resolves)->();
    };

    my $pid = fork or do {
        while (1) {
            kill 'USR1', getppid();
            Time::HiRes::sleep(0.1);
        }

        exit;
    };

    my $value = $self->await( Promise::ES6->race([$p1, $p2]) );
    is $value, 1;

    kill 'KILL', $pid;
    waitpid $pid, 0;
}

sub race_fail : Tests {
    my ($self) = @_;

    my @resolves;

    my $p1 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolves[1] = sub { $resolve->(1); }
    });

    my $p2 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolves[0] = sub { $reject->({ message => 'fail' }); }
    });

    local $SIG{'USR1'} = sub {
        (shift @resolves)->();
    };

    my $pid = fork or do {
        while (1) {
            kill 'USR1', getppid();
            Time::HiRes::sleep(0.1);
        }

        exit;
    };

    is_deeply exception {
        $self->await( Promise::ES6->race([$p1, $p2]) )
    }, { message => 'fail' };

    kill 'KILL', $pid;
    waitpid $pid, 0;
}

__PACKAGE__->runtests;