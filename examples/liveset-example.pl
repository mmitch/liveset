#!/usr/bin/env perl
use strict;
use warnings;

use LiveSet::Scene;
use LiveSet::Track;

### SET UP SCENE
#
my $ls = LiveSet::Scene->new( name => 'liveset-example');

### SET UP MIDI DEVICES
#
my $midi        = $ls->add_connection('TiMidity');
#                                      ^^^^^^^^ change this to your needs!
#                                      - must be an ALSA MIDI output port
#                                      - you can use multiple connections in parallel
#                                      - if you want to use timidity, run it with -iA

### SET UP TRACKS
#
$ls->add_track(              # set globals first!
    LiveSet::Track->new(
        connection => $midi, # bogus, unused
        channel => 0,        # bogus, unused
        filename => 'global.pl',
    ));

$ls->add_track(
    LiveSet::Track->new(
        connection => $midi,
        channel => 0,
        filename => 'bass.pl',
    ));

$ls->add_track(
    LiveSet::Track->new(
        connection => $midi,
        channel => 9,
        filename => 'drum.pl',
    ));

### RUN IT
#
$ls->run();
