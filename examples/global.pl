#!/usr/bin/env perl
use strict;

my $set_global = sub {
    my ($track, $tick, $global) = @_;

    # just a cheap example for global variables
    # you can set what you want here, you can also change it via ON_TICK
    $global->{BASE_TONE} = 36;
};


return { 'ON_INIT' => $set_global, 'ON_RELOAD' => $set_global };
