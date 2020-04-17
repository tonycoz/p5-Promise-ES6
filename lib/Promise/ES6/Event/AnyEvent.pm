package Promise::ES6::Event::AnyEvent;

use strict;
use warnings;

#----------------------------------------------------------------------

use AnyEvent ();

#----------------------------------------------------------------------

sub postpone {

    # postpone()’s prototype needlessly rejects a plain scalar.
    return &AnyEvent::postpone( $_[0] );
}

1;
