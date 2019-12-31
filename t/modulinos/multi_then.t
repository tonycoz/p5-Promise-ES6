package t::multi_then;

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use parent qw(Test::Class::Tiny);

BEGIN {
    my @path = File::Spec->splitdir( __FILE__ );
    splice( @path, -2, 2, 'lib' );
    push @INC, File::Spec->catdir(@path);
}
use MemoryCheck;

use Promise::ES6;

sub T0_multi_then {
    my $caught;

    my ($resolve, $reject);

    my $p = Promise::ES6->new( sub {
        ($resolve, $reject) = @_;
    } );

    my $then1_ok;
    my $then1 = $p->then( sub { $then1_ok = 1 } );

    my $then2_ok;
    my $then2 = $p->then( sub { $then2_ok = 1 } );

    $resolve->(123);

    ok( $then1_ok, 'first then() called' );
    ok( $then2_ok, 'second then() called' );
}

if (!caller) {
    __PACKAGE__->runtests();
}

1;
