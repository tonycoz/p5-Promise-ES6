package t::then;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use MemoryCheck;
use parent qw(Test::Class::Tiny);

use Time::HiRes;

use Test::More;
use Test::FailWarnings;

use Promise::ES6;

sub T0_already_resolved {
    my $called = 0;
    my $p = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->('executed');
    });

    $p->then(sub {
        $called = 'called';
    });
    is $called, 'called', 'call fulfilled callback if promise already resolved';
}

__PACKAGE__->runtests if !caller;

1;
