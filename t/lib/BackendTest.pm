package BackendTest;

use strict;
use warnings;

use FindBin;

use Test::More;

sub run_modulinos {
    my @path = File::Spec->splitdir(__FILE__);
    pop @path;  # filename
    pop @path;  # up one dir
    push @path, 'modulinos';

    my $wildcard_path = File::Spec->catdir(@path, '*.t');

    my @modulino_nss;

    for my $path ( glob $wildcard_path ) {
        my @test_path = File::Spec->splitpath($path);
        my $filename = $test_path[-1];

        my $module_name_leaf = $filename;
        $module_name_leaf =~ s<\.t\z><> or die "weird modulino name: $module_name_leaf";

        my $ns = "t::$module_name_leaf";

        subtest $ns => sub {
            require $path;
            $ns->runtests();
        }
    }
}

1;
