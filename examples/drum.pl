#!/usr/bin/env perl
use strict;

my $tick = sub {
    my ($track, $tick, $global) = @_;

    # a simple 4-to-the-floor drum track using the sequenced_drums helper funtion
    $track->sequenced_drums($tick, 36, 'X   '); # base
    $track->sequenced_drums($tick, 42, 'Xx  '); # closed hihat
    $track->sequenced_drums($tick, 46, '  X '); # open hihat
    $track->sequenced_drums($tick, 39, '    X       X       X       X  x'); # clap
};

return { 'ON_TICK' => $tick };
