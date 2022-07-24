package LiveSet::Client;

use MIDI::ALSA;
use Scalar::Util qw( blessed );

use LiveSet::Midi;

use Moo;
use strictures 2;
use namespace::clean;

use feature 'signatures';
no warnings 'experimental::signatures';
## no critic (ProhibitSubroutinePrototypes)

has name => (
    is => 'ro',
    required => 1,
    isa => sub {
	my $name = $_[0];
	my $type = ref $name;
	die "name $name is no string, but a $type reference" if $type;
    },
    );

has outputs => (
    is => 'ro',
    required => 1,
    isa => sub {
	my $outputs = $_[0];
	die "outputs $outputs is no ARRAYREF" unless ref $outputs eq 'ARRAY';

	my $output_count = scalar @{$outputs};
	die "no outputs given" unless $output_count;

	for my $i (0 .. $output_count - 1) {
	    my $output = $outputs->[$i];
	    # TODO: naming: LiveSet::Connection <-> $output
	    die "output #$i $output is no object" unless blessed $output;
	    die "output #$i $output is no LiveSet::Connection" unless $output->isa('LiveSet::Connection');
	}
    },
    );

has _midi => (
    is => 'lazy',
    );
   
sub _build__midi($self) {
    return LiveSet::Midi->new( port => 1, channel => 1 );
}

sub start_queue($self) {
    $self->_init_connections;
    MIDI::ALSA::start() or die "can't start ALSA queue: $!";
};

sub queue_callback($self, $tick) {
    $self->_midi->queue_callback($tick);
};

sub wait_callback($self) {
    my @event = MIDI::ALSA::input();
}

sub _init_connections($self) {
    my $outputs = $self->outputs;
    my $output_count = scalar @{$outputs};

    MIDI::ALSA::client( $self->name, 1, $output_count + 1, 1 ) or die "can't create MIDI::ALSA::client: $!";

    # listen to ourself to send us a message when the buffer runs low and the next measure should be precalculated
    MIDI::ALSA::connectfrom( 0, $self->name . ':1' );

    my $port = 2;
    for my $connection (@{$outputs}) {
	MIDI::ALSA::connectto( $port, $connection->target ) ; # TODO: or die
	$connection->port( $port++ );
    };
};

1;
