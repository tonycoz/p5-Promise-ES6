package t::all;
use strict;
use warnings;

BEGIN {
    my @path = File::Spec->splitdir( __FILE__ );
    splice( @path, -2, 2, 'lib' );
    push @INC, File::Spec->catdir(@path);
}

use MemoryCheck;

use PromiseTest;

use parent qw(Test::Class::Tiny);

use Time::HiRes;

use Test::Fatal qw(exception);
use Test::FailWarnings;
use Test::More;
use Test::Deep;

use Promise::ES6;

sub T0_test_all {
    my $self = shift;

    my $p1 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->(1);
    });
    my $p2 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->(2);
    });
    my $all = Promise::ES6->all([$p1, $p2, 3]);

    is_deeply( PromiseTest::await( $all ), [1, 2, 3] );
}

sub T0_all_values {
    my ($self) = @_;

    my $all = Promise::ES6->all([1, 2]);
    is_deeply( PromiseTest::await($all), [1,2] );
}

sub T0_all_fail {
    my ($self) = @_;

    my $p1 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->(1);
    });
    my $p2 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $reject->({ message => 'oh my god' });
    });

    my $all = Promise::ES6->all([$p1, $p2]);

    is_deeply(
        exception { PromiseTest::await($all) },
        { message => 'oh my god' },
    );
}

sub T0_all_fail_then_succeed {
    my ($self) = @_;

    my $p1 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $reject->({ message => 'oh my god' });
    });
    my $p2 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->(1);
    });

    my $all = Promise::ES6->all([$p1, $p2]);

    is_deeply(
        exception { PromiseTest::await($all) },
        { message => 'oh my god' },
    );
}

sub T0_all_multiple_fails {
    my ($self) = @_;

    my $p1 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $reject->(42);
    });
    my $p2 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $reject->({ message => 'oh my god' });
    });

    my $all = Promise::ES6->all([$p1, $p2]);

    my $err = exception { PromiseTest::await($all) };

    cmp_deeply(
        $err,
        re( qr<\A42 > ),
    );
}

sub T0_all_exception {
    my ($self) = @_;

    my $p1 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->(1);
    });
    my $p2 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        die { message => 'oh my god' };
    });

    my $all = Promise::ES6->all([$p1, $p2]);

    is_deeply(
        exception { PromiseTest::await($all) },
        { message => 'oh my god' },
    );
}

sub T0_all_empty {
    my $foo;

    Promise::ES6->all([])->then( sub { $foo = 42 } );

    is( $foo, 42, 'all() resolves immediately when given an empty list' );
}

if (!caller) {
    __PACKAGE__->runtests();
}

1;
