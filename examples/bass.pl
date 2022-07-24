#!/usr/bin/env perl
use strict;

my $init = sub {
    my ($track, $tick) = @_;

    $track->program_change($tick, 38);  # synth bass
    $track->controller($tick, 7, 100); # channel volume
    
    $track->log("init!");
};

# a simple algorithmic baseline
# use prime numbers for longer repetitions
my $tick = sub {
    my ($track, $tick, $global) = @_;

    my $gate = (0.9, 0.7, 0.8)[$tick%3];
    my $vel = (64, 64, 96, 64, 64)[$tick%5];
    
    my $note = $global->{BASE_TONE} + 12;
    if ($tick % 5 == 0) {
        $note += 1;
    }
    if ($tick % 7 == 0) {
        $note += 3;
    }

    $track->play_note($tick, $note, $gate, $vel);
};

return { 'ON_INIT' => $init, 'ON_TICK' => $tick };
