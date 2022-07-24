package LiveSet::Midi;

use Scalar::Util qw( looks_like_number );

use constant TEMPO => 0.125;  # sec per tick

use Moo;
use strictures 2;
use namespace::clean;

use feature 'signatures';
no warnings 'experimental::signatures';
## no critic (ProhibitSubroutinePrototypes)

# TODO: there are also MIDI::ALSA calls in Client.pm - consolidate this!
# unrefined thoughts:
#   - Alsa.pm for $port
#   - Midi.pm for $channel

has port => (
    is => 'ro',
    required => 1,
    isa => sub {
	my $port = $_[0];
	die "port $port is not numeric" unless looks_like_number $port;
    },
    );

has channel => (
    is => 'ro',
    required => 1,
    isa => sub {
	my $channel = $_[0];
	die "channel $channel is not numeric" unless looks_like_number $channel;
    },
    );


sub _output($self, @event) {
    $event[5]->[1] = $self->port;
    MIDI::ALSA::output(@event) or die 'WAT';
}

sub play_note($self, $tick, $key, $length, $velocity) {
    my $channel  = $self->channel;
    my @note = MIDI::ALSA::noteevent( $channel, $key, $velocity, ($tick+1) * TEMPO, $length * TEMPO );
    $self->_output(@note);
#    my $start = ($tick+1) * 0.2;
#    my $end = ($tick+1+$length) * 0.2;
#    my @noteon = MIDI::ALSA::noteonevent( $channel, $key, 100, $start );
#    $self->_output(@noteon);
#    my @noteoff = MIDI::ALSA::noteoffevent( $channel, $key, 0, $end );
#    $self->_output(@noteoff);
};

sub controller($self, $tick, $control_num, $value) {
    my $channel = $self->channel;
    my @control = MIDI::ALSA::controllerevent( $channel, $control_num, $value, ($tick+1) * TEMPO );
    $self->_output(@control);
}

sub program_change($self, $tick, $value) {
    my $channel = $self->channel;
    my @control = MIDI::ALSA::pgmchangeevent( $channel, $value );
    $self->_output(@control);
}

sub all_sound_off($self) {
    my $channel = $self->channel;
    my @control = MIDI::ALSA::controllerevent( $channel, 120, 0, 0);
    $self->_output(@control);
}

sub all_notes_off($self) {
    my $channel = $self->channel;
    my @control = MIDI::ALSA::controllerevent( $channel, 123, 0, 0);
    $self->_output(@control);
}

sub queue_callback($self, $tick) {
    my $channel = $self->channel;
    # basically any event does the job; sadly EVENT_ECHO is not mapped in MIDI::ALSA
    my @echo = MIDI::ALSA::pgmchangeevent( $channel, 0, ($tick+0.9) * TEMPO);
    $self->_output(@echo);
}

1;
