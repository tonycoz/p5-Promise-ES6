package t::then_catch;

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use MemoryCheck;

use Test::More;
use Test::FailWarnings;

use parent qw(Test::Class::Tiny);

use Promise::ES6;

sub T0_then_catch {
    my $caught;

    my $p = Promise::ES6->new( sub {
        my ($y, $n) = @_;

        $n->('oops');
    } );

    my $p2 = $p->then( sub { does_not_matter() } );

    my $p3 = $p2->catch( sub {
        $caught = $_[0];
    } );

    is( $caught, 'oops', 'caught as expected' );
}

__PACKAGE__->runtests() if !caller;

1;
