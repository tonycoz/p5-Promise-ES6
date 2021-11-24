on test => sub {
    require $_ for (
        'autodie',
        'FindBin',
        'Test::Fatal',
        'Test::Class',
        'Test::Deep',
        'Test::FailWarnings',
    );

    require 'Test::More' => 1.302103;  # skip() without test count
};

on develop => sub {
    require 'AnyEvent';
    require 'IO::Async';
    recommend 'Mojolicious';
};

configure_requires 'ExtUtils::MakeMaker::CPANfile';

recommends 'Future::AsyncAwait' => 0.47;
