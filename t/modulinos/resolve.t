package t::resolve;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use MemoryCheck;

use parent qw(Test::Class::Tiny);
use Test::More;
use Test::FailWarnings;

use Promise::ES6;

sub T1_resolve {
    Promise::ES6->resolve(123)->then(sub {
        my ($value) = @_;
        is $value, 123;
    }, sub {
        die;
    });
}

sub T1_resolve_with_promise {
    note "NONSTANDARD: The Promises/A+ test suite purposely avoids flexing this, but we match ES6.";

    my ($y, $n);

    my $p = Promise::ES6->new( sub {
        ($y, $n) = @_;
    } );

    $y->( Promise::ES6->resolve(123) );

    $p->then( sub {
        my $v = shift;

        is($v, 123, 'resolve with promise propagates');
    } );
}

__PACKAGE__->runtests if !caller;

1;
