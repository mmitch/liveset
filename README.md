# LiveSet

MIDI performance via live edited Perl scripts

Not much documentation here, everything is still being written.

A minimal working example is something like this:

1. Create a main executable file, eg `liveset-example.pl`:

```perl
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
my $midi        = $ls->add_connection('Timidity:0');
#                                      ^^^^^^^^^^^^ change this to your needs!
#                                      - must be an ALSA MIDI output port
#                                      - you can use multiple connections in parallel

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

```

2. Set up global configuration `global.pl`:

```perl
#!/usr/bin/env perl
use strict;

my $set_global = sub {
    my ($track, $tick, $global) = @_;

    # just a cheap example for global variables
    # you can set what you want here, you can also change it via ON_TICK
    $global->{BASE_TONE} = 36;
};


return { 'ON_INIT' => $set_global, 'ON_RELOAD' => $set_global };
```

3. Create a bass track `bass.pl`:

```perl
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

```

4. Create a drum track `drum.pl`:

```perl
#!/usr/bin/env perl
use strict;

my $tick = sub {
    my ($track, $tick, $global) = @_;

    $track->sequenced_drums($tick, 36, 'X   '); # base
    $track->sequenced_drums($tick, 42, 'Xx  '); # closed hihat
    $track->sequenced_drums($tick, 46, '  X '); # open hihat
    $track->sequenced_drums($tick, 39, '    X       X       X       X  x'); # clap
};

return { 'ON_TICK' => $tick };

```

5. Start the player:

```shell
perl -I<<PATH_TO_LIVESET_REPO>> liveset-example.pl
```

6. Now edit `global.pl`, `bass.pl` or `drum.pl` with a text editor.
   Both files will reload after saving and you will hear the changes
   immediately.
