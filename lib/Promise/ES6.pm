package Promise::ES6;

use strict;
use warnings;

our $VERSION = '0.24_02';

=encoding utf-8

=head1 NAME

Promise::ES6 - ES6-style promises in Perl

=head1 SYNOPSIS

    use Promise::ES6;

    # OPTIONAL. And see below for other options.
    Promise::ES6::use_event('IO::Async', $loop);

    my $promise = Promise::ES6->new( sub {
        my ($resolve_cr, $reject_cr) = @_;

        # ..
    } );

    my $promise2 = $promise->then( sub { .. }, sub { .. } );

    my $promise3 = $promise->catch( sub { .. } );

    my $promise4 = $promise->finally( sub { .. } );

    my $resolved = Promise::ES6->resolve(5);
    my $rejected = Promise::ES6->reject('nono');

    my $all_promise = Promise::ES6->all( \@promises );

    my $race_promise = Promise::ES6->race( \@promises );

    my $allsettled_promise = Promise::ES6->allSettled( \@promises );

=head1 DESCRIPTION

=begin html

<a href='https://coveralls.io/github/FGasper/p5-Promise-ES6?branch=master'><img src='https://coveralls.io/repos/github/FGasper/p5-Promise-ES6/badge.svg?branch=master' alt='Coverage Status' /></a>

=end html

This module provides a Perl implementation of L<promises|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_promises>, a useful pattern
for coordinating asynchronous tasks.

Unlike most other promise implementations on CPAN, this module
mimics ECMAScript 6’s L<Promise|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise>
interface. As the SYNOPSIS above shows, you can thus use patterns from
JavaScript in Perl with only minimal changes needed to accommodate language
syntax.

This is a rewrite of an earlier module, L<Promise::Tiny>. It fixes several
bugs and superfluous dependencies in the original.

=head1 STATUS

This module is in use in production and, backed by a pretty extensive
set of regression tests, may be considered stable.

=head1 INTERFACE NOTES

=over

=item * Promise resolutions and rejections accept exactly one argument,
not a list.

=item * Unhandled rejections are reported via C<warn()>. (See below
for details.)

=item * Undefined or empty rejection values trigger a warning.
This provides the same value as Perl’s own warning on C<die(undef)>.

=item * The L<Promises/A+ test suite|https://github.com/promises-aplus/promises-tests> avoids testing the case where an “executor”
function’s resolve callback itself receives another promise, e.g.:

    my $p = Promise::ES6->new( sub ($res) {
        $res->( Promise::ES6->resolve(123) );
    } );

What will $p’s resolution value be? 123, or the promise that wraps it?

This module favors conformity with the ES6 standard, which
L<indicates intent|https://www.ecma-international.org/ecma-262/6.0/#sec-promise-executor> that $p’s resolution value be 123.

=back

=head1 COMPATIBILITY

This module considers any object that has a C<then()> method to be a promise.
Note that, in the case of L<Future>, this will yield a “false-positive”, as
Future is not compatible with promises.

(See L<Promise::ES6::Future> for more tools to interact with L<Future>.)

=head1 B<EXPERIMENTAL:> ASYNC/AWAIT SUPPORT

This module implements L<Future::AsyncAwait::Awaitable>.
Once you load L<Future::AsyncAwait> this lets you do nifty stuff like:

    use Future::AsyncAwait future_class => 'Promise::ES6';

    async sub do_stuff {
        return 1 + await fetch_number_p();
    }

    my $one_plus_number = await do_stuff();

… which roughly equates to:

    sub do_stuff {
        return fetch_number_p()->then( sub { 1 + $foo } );
    }

    do_stuff->then( sub {
        $one_plus_number = shift;
    } );

=head1 UNHANDLED REJECTIONS

This module’s handling of unhandled rejections has changed over time.
The current behavior is: if any rejected promise is DESTROYed without first
having received a catch callback, a warning is thrown.

=head1 SYNCHRONOUS VS. ASYNCHRONOUS OPERATION

In JavaScript, the following …

    Promise.resolve().then( () => console.log(1) );
    console.log(2);

… will log C<2> then C<1> because JavaScript’s C<then()> defers execution
of its callbacks until between iterations through JavaScript’s event loop.

Perl, of course, has no built-in event loop. This module accommodates that by
implementing B<synchronous> promises by default rather than asynchronous ones.
This means that all promise callbacks run I<immediately> rather than between
iterations of an event loop. As a result, this:

    Promise::ES6->resolve(0)->then( sub { print 1 } );
    print 2;

… will print C<12> instead of C<21>.

One effect of this is that Promise::ES6, in its default configuration, is
agnostic regarding event loop interfaces: no special configuration is needed
for any specific event loop. In fact, you don’t even I<need> an event loop
at all, which might be useful for abstracting over whether a given
function works synchronously or asynchronously.

The disadvantage of synchronous promises—besides not being I<quite> the same
promises that we expect from JS—is that recursive promises can exceed
call stack limits. For example, the following (admittedly contrived) code:

    my @nums = 1 .. 1000;

    sub _remove {
        if (@nums) {
            Promise::ES6->resolve(shift @nums)->then(\&_remove);
        }
    }

    _remove();

… will eventually fail because it will reach Perl’s call stack size limit.

That problem probably won’t affect most applications. The best way to
avoid it, though, is to use asynchronous promises, à la JavaScript.

To do that, first choose one of the following event interfaces:

=over

=item * L<IO::Async>

=item * L<AnyEvent>

=item * L<Mojo::IOLoop> (part of L<Mojolicious>)

=back

Then, before you start creating promises, do this:

    Promise::ES6::use_event('AnyEvent');

… or:

    Promise::ES6::use_event('Mojo::IOLoop');

… or:

    Promise::ES6::use_event('IO::Async', $loop);

That’s it! Promise::ES6 instances will now work asynchronously rather than
synchronously.

Note that this changes Promise::ES6 I<globally>. In IO::Async’s case, it
won’t increase the passed-in L<IO::Async::Loop> instance’s reference count,
but if that loop object goes away, Promise::ES6 won’t work until you call
C<use_event()> again.

B<IMPORTANT:> For the best long-term scalability and flexibility,
your code should work with either synchronous or asynchronous promises.

=head1 CANCELLATION

Promises have never provided a standardized solution for cancellation—i.e.,
aborting an in-process operation. If you need this functionality, then, you’ll
have to implement it yourself. Two ways of doing this are:

=over

=item * Subclass Promise::ES6 and provide cancellation logic in that
subclass. See L<DNS::Unbound::AsyncQuery>’s implementation for an
example of this.

=item * Implement the cancellation on a request object that your
“promise-creator” also consumes. This is probably the more straightforward
approach but requires that there
be some object or ID besides the promise that uniquely identifies the action
to be canceled. See L<Net::Curl::Promiser> for an example of this approach.

=back

You’ll need to decide if it makes more sense for your application to leave
a canceled query in the “pending” state or to “settle” (i.e., resolve or
reject) it. All things being equal, I feel the first approach is the most
intuitive, while the latter ends up being “cleaner”.

=head1 MEMORY LEAKS

It’s easy to create inadvertent memory leaks using promises in Perl.
Here are a few “pointers” (heh) to bear in mind:

=over

=item * Any Promise::ES6 instances that are created while
C<$Promise::ES6::DETECT_MEMORY_LEAKS> is set to a truthy value are
“leak-detect-enabled”, which means that if they survive until their original
process’s global destruction, a warning is triggered. You should normally
enable this flag in a development environment.

=item * If your application needs recursive promises (e.g., to poll
iteratively for completion of a task), the C<current_sub> feature (i.e.,
C<__SUB__>) may help you avoid memory leaks. In Perl versions that don’t
support this feature (i.e., anything pre-5.16) you can imitate it thus:

    use constant _has_current_sub => eval "use feature 'current_sub'";

    use if _has_current_sub(), feature => 'current_sub';

    my $cb;
    $cb = sub {
        my $current_sub = do {
            no strict 'subs';
            _has_current_sub() ? __SUB__ : eval '$cb';
        };
    }

Of course, it’s better if you can avoid doing that. :)

=item * Garbage collection before Perl 5.18 seems to have been buggy.
If you work with such versions and end up chasing leaks,
try manually deleting as many references/closures as possible. See
F<t/race_success.t> for a notated example.

You may also (counterintuitively, IMO) find that this:

    my ($resolve, $reject);

    my $promise = Promise::ES6->new( sub { ($resolve, $reject) = @_ } );

    # … etc.

… works better than:

    my $promise = Promise::ES6->new( sub {
        my ($resolve, $reject) = @_;

        # … etc.
    } );

=back

=head1 SEE ALSO

If you’re not sure of what promises are, there are several good
introductions to the topic. You might start with
L<this one|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_promises>.

L<Promise::XS> is my refactor of L<AnyEvent::XSPromises>. It’s a lot like
this library but implemented mostly in XS for speed.

L<Promises> is another pure-Perl Promise implementation.

L<Future> fills a role similar to that of promises. Much of the IO::Async
ecosystem assumes (or strongly encourages) its use.

CPAN contains a number of other modules that implement promises. I think
mine are the nicest :), but YMMV. Enjoy!

=head1 LICENSE & COPYRIGHT

Copyright 2019-2021 Gasper Software Consulting.

This library is licensed under the same terms as Perl itself.

=cut

#----------------------------------------------------------------------

our $DETECT_MEMORY_LEAKS;

sub __default_postpone { die 'NO EVENT' }
*_postpone = \&__default_postpone;

our $_EVENT;

sub use_event {
    my ($name, @args) = @_;

    my $modname = $name;
    $modname =~ tr<:><>d;

    my @saved_errs = ($!, $@);

    require "Promise/ES6/Event/$modname.pm";

    ($!, $@) = @saved_errs;

    $_EVENT = $name;

    # We need to block redefinition and (for AnyEvent)
    # prototype-mismatch warnings.
    no warnings 'all';
    *_postpone = "Promise::ES6::Event::$modname"->can('get_postpone')->(@args);

    return;
}

sub catch { $_[0]->then( undef, $_[1] ) }

sub finally {
    my ($self, $on_end) = @_;

    my $class = ref $self;

    return $self->then(
        sub {
            my $val = $_[0];

            $class->resolve( scalar $on_end->() )->then( sub { $val } );
        },
        sub {
            my @errs = @_;

            $class->resolve( scalar $on_end->() )->then(
                sub { $class->reject(@errs) },
            );
        },
    );
}

sub resolve {
    my ( $class, $value ) = @_;

    $class->new( sub { $_[0]->($value) } );
}

sub reject {
    my ( $class, @reason ) = @_;

    $class->new( sub { $_[1]->(@reason) } );
}

sub all {
    my ( $class, $iterable ) = @_;
    my @promises = map { UNIVERSAL::can( $_, 'then' ) ? $_ : $class->resolve($_) } @$iterable;

    my @values;

    return $class->new(
        sub {
            my ( $resolve, $reject ) = @_;
            my $unresolved_size = scalar(@promises);

            my $settled;

            if ($unresolved_size) {
                my $p = 0;

                my $on_reject_cr = sub {

                    # Needed because we might get multiple failures:
                    return if $settled;

                    $settled = 1;
                    $reject->(@_);
                };

                for my $promise (@promises) {
                    my $p = $p++;

                    $promise->then(
                        $settled ? undef : sub {
                            return if $settled;

                            $values[$p] = $_[0];

                            $unresolved_size--;
                            return if $unresolved_size > 0;

                            $settled = 1;
                            $resolve->( \@values );
                        },
                        $on_reject_cr,
                    );
                }
            }
            else {
                $resolve->( [] );
            }
        }
    );
}

sub race {
    my ( $class, $iterable ) = @_;
    my @promises = map { UNIVERSAL::can( $_, 'then' ) ? $_ : $class->resolve($_) } @$iterable;

    my ( $resolve, $reject );

    # Perl 5.16 and earlier leak memory when the callbacks are handled
    # inside the closure here.
    my $new = $class->new(
        sub {
            ( $resolve, $reject ) = @_;
        }
    );

    my $is_done;

    my $on_resolve_cr = sub {
        return if $is_done;
        $is_done = 1;

        $resolve->( $_[0] );

        # Proactively eliminate references:
        $resolve = $reject = undef;
    };

    my $on_reject_cr = sub {
        return if $is_done;
        $is_done = 1;

        $reject->( $_[0] );

        # Proactively eliminate references:
        $resolve = $reject = undef;
    };

    for my $promise (@promises) {
        $promise->then( $on_resolve_cr, $on_reject_cr );
    }

    return $new;
}

sub _aS_fulfilled {
    return { status => 'fulfilled', value => $_[0] };
}

sub _aS_rejected {
    return { status => 'rejected', reason => $_[0] };
}

sub _aS_map {
    return $_->then( \&_aS_fulfilled, \&_aS_rejected );
}

sub allSettled {
    my ( $class, $iterable ) = @_;

    my @promises = map { UNIVERSAL::can( $_, 'then' ) ? $_ : $class->resolve($_) } @$iterable;

    @promises = map( _aS_map, @promises );

    return $class->all( \@promises );
}

#----------------------------------------------------------------------
# The stuff that’s specific to this specific implementation:

sub new {
    my ($class, $cb) = @_;

    _confess('need callback') if !$cb;

    my $self = bless { _pid => $$, _detect_leak => $Promise::ES6::DETECT_MEMORY_LEAKS }, $class;

    local $@;
    eval { $cb->(
        sub { $self->_resolve($_[0]) },
        sub { $self->_reject(@_) },
    ); 1 } or $self->_reject($@);

    return $self;
}

sub then {
    my ($self, $on_res, $on_rej) = @_;

    $self->{'handled'} = 1;

    my $new = bless { _pid => $$, _detect_leak => $Promise::ES6::DETECT_MEMORY_LEAKS }, ref($self);

    push @{ $self->{'on_res'} }, sub {
        if ($on_res) {
            my $val;

            local $@;

            if ( eval { $val = $on_res->($_[0]); 1 } ) {
                $new->_resolve($val);
            }
            else {
                $new->_reject($@);
            }
        }
        else {
            $new->_resolve($_[0]);
        }
    };

    push @{ $self->{'on_rej'} }, sub {
        my $val;

        if ($on_rej) {
            local $@;

            if ( eval { $val = $on_rej->($_[0]); 1 } ) {
                $new->_resolve($val);
            }
            else {
                $new->_reject($@);
            }
        }
        else {
            $new->_reject(@_);
        }
    };

    $self->_propagate() if exists $self->{'_result'};

    return $new;
}

sub _resolve {
    my ($self, $value) = @_;

    if (UNIVERSAL::can($value, 'then')) {
        $value->then(
            sub { $self->_resolve($_[0]) },
            sub { $self->_reject(@_) },
        );
    }
    else {
        $self->{'_result'} = $value;
        $self->{'_success'} = 1;

        $self->_propagate();
    }

    return;
}

sub _reject {
    my ($self, @values) = @_;

    if (!defined $values[0]) {
        my $class = ref $self;

        my $msg;

        if (@values) {
            $msg = "$class: Uninitialized rejection value given";
        }
        else {
            $msg = "$class: No rejection value given";
        }

        _carp($msg);
    }

    $self->{'_result'} = $values[0];

    $self->_propagate();

    return;
}

sub _propagate {
    my ($self) = @_;

    $self->{'_on_ready'}->() if $self->{'_on_ready'};

    my $cbs_ar = $self->{'_success'} ? $self->{'on_res'} : $self->{'on_rej'};

    @{$self}{'_selfref', 'on_res', 'on_rej'} = (undef, [], []);

    if ($cbs_ar) {
        if ($_EVENT) {
            _postpone( sub {
                $_->( $self->{'_result'} ) for @$cbs_ar;
            } );
        }
        else {
            $_->( $self->{'_result'} ) for @$cbs_ar;
        }
    }

    return;
}

sub DESTROY {
    return if $_[0]{'handled'};

    # The PID should always be there, but this accommodates mocks.
    return unless $_[0]{'_pid'} && $$ == $_[0]{'_pid'};

    if ( $_[0]{_detect_leak} && ${^GLOBAL_PHASE} && ${^GLOBAL_PHASE} eq 'DESTRUCT' ) {
        _carp( ( '=' x 70 ) . "\n" . 'XXXXXX - ' . ref( $_[0] ) . " survived until global destruction; memory leak likely!\n" . ( "=" x 70 ) . "\n" );
    }

    if ( exists $_[0]{'_result'} && !$_[0]{'_success'} ) {
        _carp("$_[0]: Unhandled rejection: $_[0]{'_result'}");
    }
}

#----------------------------------------------------------------------

sub _carp {
    unshift @_, 'carp';
    &_do_carp;
}

sub _confess {
    unshift @_, 'confess';
    &_do_carp;
}

sub _do_carp {
    my ($fn, $msg) = @_;

    local ($@, $!);
    require Carp;

    local $Carp::Internal{ (__PACKAGE__) } = 1;

    Carp->can($fn)->($msg);
}

#----------------------------------------------------------------------

# Future::AsyncAwait::Awaitable interface:

# Future::AsyncAwait doesn’t retain a strong reference to its created
# promises, as a result of which we need to create a self-reference
# inside the promise. We’ll clear that self-reference once the promise
# is finished, which avoids memory leaks.
#
sub _immortalize {
    my $method = $_[0];

    my $new = $_[1]->$method(@_[2 .. $#_]);

    $new->{'_selfref'} = $new;
}

sub AWAIT_NEW_DONE {
    _immortalize('resolve', (ref($_[0]) || $_[0]), $_[1] );
}

sub AWAIT_NEW_FAIL {
    _immortalize('reject', (ref($_[0]) || $_[0]), $_[1] );
}

sub AWAIT_CLONE {
    _immortalize('new', ref $_[0], \&_noop);
}

sub AWAIT_DONE {
    &_resolve;
}
sub AWAIT_FAIL {
    &_reject;
}

sub AWAIT_IS_READY {
    exists $_[0]->{'_result'};
}

sub AWAIT_GET {
    return $_[0]{'_result'} if $_[0]{'_success'};

    die $_[0]{'_result'};
}

sub _noop {}

sub AWAIT_ON_READY {
    $_[0]{'_on_ready'} = $_[1];
}

*AWAIT_CHAIN_CANCEL = *_noop;
*AWAIT_ON_CANCEL = *_noop;
*AWAIT_IS_CANCELLED = *_noop;

1;
