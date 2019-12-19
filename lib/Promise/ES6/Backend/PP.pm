package Promise::ES6;

#----------------------------------------------------------------------
# This module iS NOT a defined interface. Nothing to see here …
#----------------------------------------------------------------------

use strict;
use warnings;

use constant {

    # These aren’t actually defined.
    _RESOLUTION_CLASS => 'Promise::ES6::_RESOLUTION',
    _REJECTION_CLASS  => 'Promise::ES6::_REJECTION',
    _PENDING_CLASS    => 'Promise::ES6::_PENDING',
};

use constant {
    _PID_IDX         => 0,
    _CHILDREN_IDX    => 1,
    _VALUE_SR_IDX    => 2,
    _DETECT_LEAK_IDX => 3,
    _ON_RESOLVE_IDX  => 4,
    _ON_REJECT_IDX   => 5,
};

# "$value_sr" => $value_sr
our %_UNHANDLED_REJECTIONS;

sub new {
    my ( $class, $cr ) = @_;

    die 'Need callback!' if !$cr;

    my $value;
    my $value_sr = bless \$value, _PENDING_CLASS();

    my @children;

    my $self = bless [
        $$,
        \@children,
        $value_sr,
        $Promise::ES6::DETECT_MEMORY_LEAKS,
    ], $class;

    my $suppress_unhandled_rejection_warning = 1;

    # NB: These MUST NOT refer to $self, or else we can get memory leaks
    # depending on how $resolver and $rejector are used.
    my $resolver = sub {
        $$value_sr = $_[0];
        bless $value_sr, _RESOLUTION_CLASS();

        # NB: UNIVERSAL::isa() is used in order to avoid an eval {}.
        # It is acknowledged that many Perl experts strongly discourage
        # use of this technique.
        if ( UNIVERSAL::isa( $$value_sr, __PACKAGE__ ) ) {
            _repromise( $value_sr, \@children, $value_sr );
        }
        elsif (@children) {
            $_->_settle($value_sr) for splice @children;
        }
    };

    my $rejecter = sub {
        $$value_sr = $_[0];
        bless $value_sr, _REJECTION_CLASS();

        if ( !$suppress_unhandled_rejection_warning ) {
            $_UNHANDLED_REJECTIONS{$value_sr} = $value_sr;
        }

        if ( UNIVERSAL::isa( $$value_sr, __PACKAGE__ ) ) {
            _repromise( $value_sr, \@children, $value_sr );
        }
        elsif (@children) {
            $_->_settle($value_sr) for splice @children;
        }
    };

    local $@;
    if ( !eval { $cr->( $resolver, $rejecter ); 1 } ) {
        $$value_sr = $@;
        bless $value_sr, _REJECTION_CLASS();

        $_UNHANDLED_REJECTIONS{$value_sr} = $value_sr;
    }

    $suppress_unhandled_rejection_warning = 0;

    return $self;
}

sub then {
    my ( $self, $on_resolve, $on_reject ) = @_;

    my $value_sr = bless( \do { my $v }, _PENDING_CLASS() );

    my $new = bless [
        $$,
        [],
        $value_sr,
        $Promise::ES6::DETECT_MEMORY_LEAKS,
        $on_resolve,
        $on_reject,
      ],
      ref($self);

    if ( _PENDING_CLASS ne ref $_[0][_VALUE_SR_IDX] ) {
        $new->_settle( $self->[_VALUE_SR_IDX] );
    }
    else {
        push @{ $self->[_CHILDREN_IDX] }, $new;
    }

    return $new;
}

sub _repromise {
    my ( $value_sr, $children_ar, $repromise_value_sr ) = @_;
    $$repromise_value_sr->then(
        sub {
            $$value_sr = $_[0];
            bless $value_sr, _RESOLUTION_CLASS;
            $_->_settle($value_sr) for splice @$children_ar;
        },
        sub {
            $$value_sr = $_[0];
            bless $value_sr, _REJECTION_CLASS;
            $_->_settle($value_sr) for splice @$children_ar;
        },
    );
    return;

}

# It’s gainfully faster to inline this:
#sub _is_completed {
#    return (_PENDING_CLASS ne ref $_[0][ _VALUE_SR_IDX ]);
#}

sub _settle {
    my ( $self, $value_sr ) = @_;

    die "$self already settled!" if _PENDING_CLASS ne ref $_[0][_VALUE_SR_IDX];

    # A promise that new() created won’t have on-settle callbacks,
    # but a promise that came from then/catch/finally will.
    # It’s a good idea to delete the callbacks in order to trigger garbage
    # collection as soon and as reliably as possible. It’s safe to do so
    # because _settle() is only called once.
    my $callback = $self->[ $value_sr->isa( _REJECTION_CLASS() ) ? _ON_REJECT_IDX : _ON_RESOLVE_IDX ];

    @{$self}[ _ON_RESOLVE_IDX, _ON_REJECT_IDX ] = ();

    # Only needed when catching, but the check would be more expensive
    # than just always deleting. So, hey.
    delete $_UNHANDLED_REJECTIONS{$value_sr};

    if ($callback) {
        my ($new_value);

        local $@;

        if ( eval { $new_value = $callback->($$value_sr); 1 } ) {
            bless $self->[_VALUE_SR_IDX], _RESOLUTION_CLASS() if !UNIVERSAL::isa( $new_value, __PACKAGE__ );
        }
        else {
            $new_value = $@;

            bless $self->[_VALUE_SR_IDX], _REJECTION_CLASS();
            $_UNHANDLED_REJECTIONS{ $self->[_VALUE_SR_IDX] } = $self->[_VALUE_SR_IDX];
        }

        ${ $self->[_VALUE_SR_IDX] } = $new_value;
    }
    else {
        bless $self->[_VALUE_SR_IDX], ref($value_sr);
        ${ $self->[_VALUE_SR_IDX] } = $$value_sr;

        if ( $value_sr->isa( _REJECTION_CLASS() ) ) {
            $_UNHANDLED_REJECTIONS{ $self->[_VALUE_SR_IDX] } = $self->[_VALUE_SR_IDX];
        }
    }

    if ( UNIVERSAL::isa( ${ $self->[_VALUE_SR_IDX] }, __PACKAGE__ ) ) {
        _repromise( @{$self}[ _VALUE_SR_IDX, _CHILDREN_IDX, _VALUE_SR_IDX ] );
    }
    elsif ( @{ $self->[_CHILDREN_IDX] } ) {
        $_->_settle( $self->[_VALUE_SR_IDX] ) for splice @{ $self->[_CHILDREN_IDX] };
    }

    return;
}

sub DESTROY {
    return if $$ != $_[0][_PID_IDX];

    if ( $_[0][_DETECT_LEAK_IDX] && ${^GLOBAL_PHASE} && ${^GLOBAL_PHASE} eq 'DESTRUCT' ) {
        warn( ( '=' x 70 ) . "\n" . 'XXXXXX - ' . ref( $_[0] ) . " survived until global destruction; memory leak likely!\n" . ( "=" x 70 ) . "\n" );
    }

    if ( my $promise_value_sr = $_[0][_VALUE_SR_IDX] ) {
        if ( my $value_sr = delete $_UNHANDLED_REJECTIONS{$promise_value_sr} ) {
            my $ref = ref $_[0];
            warn "$ref: Unhandled rejection: $$value_sr";
        }
    }
}

1;
