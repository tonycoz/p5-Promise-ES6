package t::resolve;
use strict;
use warnings;

BEGIN {
    my @path = File::Spec->splitdir( __FILE__ );
    splice( @path, -2, 2, 'lib' );
    push @INC, File::Spec->catdir(@path);
}
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

if (!caller) {
    __PACKAGE__->runtests();
}

1;
