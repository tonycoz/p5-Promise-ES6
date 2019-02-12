package PromiseTest;

use strict;
use warnings;
use autodie;

use parent qw(Test::Class);

use File::Path;
use File::Temp;

use Time::HiRes;

sub _clear_path : Tests(setup) {
    my ($self) = @_;

    $self->{'_tempdir'} = File::Temp::tempdir( CLEANUP => 1 );
}

sub wait_until {
    my ($self, $evt) = @_;

    Time::HiRes::sleep(0.01) while !$self->has_happened($evt);

    return;
}

sub has_happened {
    my ($self, $evt) = @_;

    return -l "$self->{'_tempdir'}/event_$evt";
}

sub happen {
    my ($self, $evt) = @_;

    symlink $evt, "$self->{'_tempdir'}/event_$evt";

    return;
}

sub await {
    my ($self, $promise, $checks_ar) = @_;

    my %result;

    $promise->then(
        sub { $result{'resolved'} = $_[0] },
        sub { $result{'rejected'} = $_[0] },
    );

    while (!keys %result) {
        Time::HiRes::sleep(0.01);

        $_->() for @$checks_ar;
    }

    return $result{'resolved'} if exists $result{'resolved'};

    die $result{'rejected'};
}

1;
