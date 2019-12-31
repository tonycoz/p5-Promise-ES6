package t::catch;
use strict;
use warnings;

use File::Spec;

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
use Test::More;
use Test::FailWarnings;

use Promise::ES6;

sub T0_reject_catch {
    my ($self) = @_;

    my $p = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $reject->('oh my god!');
    })->catch(sub {
        my ($reason) = @_;
        return $reason;
    });
    is PromiseTest::await($p), 'oh my god!';
}

sub T1_then_reject_catch {
    my ($self) = @_;

    my $p = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->(123);
    })->then(sub {
        my ($value) = @_;
        my $p = Promise::ES6->new(sub {
            my ($resolve, $reject) = @_;
            # die { message => 'oh my god', value => $value };
            $reject->( { message => 'oh my god', value => $value } );
        });

        return $p;
    })->catch(sub {
        my ($reason) = @_;
        return $reason;
    });

    is_deeply PromiseTest::await($p), { message => 'oh my god', value => 123 };
}

sub T0_exception_catch {
    my ($self) = @_;

    my $p = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        die { message => 'oh my god!!' };
    });
    is_deeply exception {
        PromiseTest::await($p);
    }, { message => 'oh my god!!' };
}

sub T0_then_exception_await {
    my ($self) = @_;

    my $p = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->(123);
    })->then(sub {
        my ($value) = @_;
        die { message => $value };
    });
    is_deeply exception { PromiseTest::await($p) }, { message => 123 };
}

sub T0_exception_then_await {
    my ($self) = @_;

    my $p = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        die { message => 'oh my god!!!' }
    })->then(sub {
        my ($value) = @_;
        #
    }, sub {
        my ($reason) = @_;
        return { reason => $reason };
    });
    is_deeply PromiseTest::await($p), { reason => { message => 'oh my god!!!' } };
}

sub T0_exception_catch_then_await {
    my ($self) = @_;

    my $p = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        die { message => 'oh my god!!!' }
    })->catch(sub {
        my ($reason) = @_;
        return { recover => 1, reason => $reason };
    })->then(sub {
        my ($value) = @_;
        return $value;
    });
    is_deeply PromiseTest::await($p), { recover => 1, reason => { message => 'oh my god!!!' } };
}

if (!caller) {
    __PACKAGE__->runtests();
}

1;
