package LiveSet::Scene;

use strict;
use warnings;

use LiveSet::Client;
use LiveSet::Connection;

use IO::Select;

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
	die "scene name $name is no string, but a $type reference" if $type;
    },
    );

has _connections => ( is => 'lazy' );
has _tracks =>      ( is => 'lazy' );

sub _build__connections($self) { return [] }
sub _build__tracks($self)      { return [] }

sub add_connection($self, $target) {
    use Data::Dumper; print Dumper($self);
    my $connection = new LiveSet::Connection( target => $target );
    push @{$self->_connections}, $connection;
    return $connection;
}

# TODO: don't expose Track class to the caller
sub add_track($self, $track) {
    push @{$self->_tracks}, $track;
    return $track;
}

sub run($self) {
    my $client = LiveSet::Client->new(
	name => $self->name,
	outputs => $self->_connections,
	);

    my $global = {};
    $_->init() foreach @{$self->_tracks};

    my $ios = IO::Select->new;
    $ios->add(\*STDIN);

    $client->start_queue();

    $self->_quiet();

    my $tick = 0;
    while (! $ios->can_read(0.01)) {
	$_->tick($tick, $global) foreach @{$self->_tracks};
	$client->queue_callback($tick);
    
	$tick++;
	$client->wait_callback();
    }

    $self->_quiet();
    sleep 0.1;
    $self->_quiet();
}

# TODO: NOTE OFF on all devices on disconnect/exit
# TODO: global tempo (used here and in Track.pm)
# TODO: FIX reload file / eval fail
# TODO: simplify play note again (just noteevent)

sub _quiet($self) {
    for my $track (@{$self->_tracks}) {
	$track->all_notes_off;
	$track->all_sound_off;
    }
}

1;
