#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use lib '../lib';
use Promise::ES6;
use Mojo::Promise;

#my $promise_class = 'Mojo::Promise';
my $promise_class = 'Promise::ES6';

use Data::Dumper;
$Data::Dumper::Deparse = 1;
my $destroyed = 0;

my $p = do {
    my $d = OnDestroy->new( sub {
        $destroyed++;
    } );

    my $p = $promise_class->new( sub { } );

    my $p2 = $p->finally( sub { undef $d; print "===== in finally\n" } );

    #diag explain $p;

    $p2;
};

diag '=================';
diag explain $p;

is( $destroyed, 0, 'promise is alive: reference isn’t reaped' );

undef $p;

is( $destroyed, 1, 'promise is gone: reference is reaped' );

done_testing;

#----------------------------------------------------------------------

package OnDestroy;

sub new { return bless [ $_[1] ], $_[0] }

sub DESTROY {
    $_[0][0]->();
}

1;
