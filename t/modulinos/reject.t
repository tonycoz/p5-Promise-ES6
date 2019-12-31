package t::reject;
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

sub T1_reject {
    Promise::ES6->reject('oh my god')->then(sub {
        die;
    }, sub {
        my ($reason) = @_;
        is $reason, 'oh my god';
    });
}

if (!caller) {
    __PACKAGE__->runtests();
}

1;
