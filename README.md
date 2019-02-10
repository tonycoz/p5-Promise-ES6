# NAME

Promise::ES6 - ES6-style promises in Perl

# SYNOPSIS

    my $promise = Promise::ES6->new( sub {
        my ($resolve_cr, $reject_cr) = @_;

        # ..
    } );

    my $promise2 = $promise->then( sub { .. }, sub { .. } );

    my $promise3 = $promise->catch( sub { .. } );

    my $promise4 = $promise->finally( sub { .. } );

    my $resolved = Promise->resolve(5);
    my $rejected = Promise->reject('nono');

    my $all_promise = Promise->all( \@promises );

    my $race_promise = Promise->race( \@promises );

# DESCRIPTION

This is a rewrite of [Promise::Tiny](https://metacpan.org/pod/Promise::Tiny) that implements fixes for
certain bugs that proved hard to fix in the original code. This module
also removes superfluous dependencies on [AnyEvent](https://metacpan.org/pod/AnyEvent) and [Scalar::Util](https://metacpan.org/pod/Scalar::Util).

The interface is the same, except:

- Promise resolutions and rejections take exactly one argument,
not a list. (This accords with the standard.)
- A `finally()` method is defined.
