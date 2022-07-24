package LiveSet::Track;

use Scalar::Util qw( blessed looks_like_number );
use Linux::Inotify2;

use LiveSet::Midi;

use constant TEMPO => 0.125;  # sec per tick

use Moo;
use strictures 2;
use namespace::clean;

use feature 'signatures';
no warnings 'experimental::signatures';
## no critic (ProhibitSubroutinePrototypes)

has connection => (
    is => 'ro',
    required => 1,
    isa => sub {
	my $connection = $_[0];
	die "connection $connection is no object" unless blessed $connection;
	die "connection $connection is no LiveSet::Connection" unless $connection->isa('LiveSet::Connection');
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

has filename => (
    is => 'ro',
    required => 1,
    isa => sub {
	my $filename = $_[0];
	my $type = ref $filename;
	die "filename $filename is no string, but a $type reference" if $type;
    },
    );

has _initref => (
    is => 'rw',
    );

has _tickref => (
    is => 'rw',
    );

has _inotify => (
    is => 'lazy',
    );

has _midi => (
    is => 'lazy',
    );

has _initialized => (
    is => 'rw',
    );

sub _build__inotify($self) {
    my $inotify = Linux::Inotify2->new or die "can't create inotify object: $!";
    $inotify->blocking(0);
    return $inotify;
}

sub _build__midi($self) {
    return LiveSet::Midi->new( port => $self->connection->port, channel => $self->channel );
}

sub init($self) {
    $self->_inotify->watch($self->filename, IN_MODIFY | IN_CLOSE_WRITE) or die "can't create watch for ".${self}->{filename}.": $!";
    $self->_load_file;
}

sub log($self, @args) {
    printf "%16s: %s\n", $self->filename, join(' ', @args);
}

sub tick($self, $tick) {
    my @events = $self->_inotify->read;
    if (@events) {
	$self->_load_file;
    }
    unless ($self->_initialized) {
	$self->_initref->($self, $tick) if defined $self->_initref;
	$self->_initialized( 1 );
    }
    $self->_tickref->($self, $tick) if defined $self->_tickref;
    
}

sub _load_file($self) {
    my $filename = $self->filename;

    print "loading $filename...\n";

    open my $fh, '<', $filename or do {
	warn "could not open '$filename': $!\n";
	return;
    };

    local $/ = undef;
    my $code = <$fh>;
    
    close $fh or warn "could not close '$filename': $!\n";

    my $hash = eval "$code";

    if ($@) {
	warn "error parsing '$filename': $@\n";
	return;
    }

    my $type = ref $hash;
    if ($type ne 'HASH') {
	warn "parsing '$filename' yielded no hash, but '$type'\n";
	return;
    }
    
    $self->_initref( $hash->{INIT} );
    $self->_tickref( $hash->{TICK} );

    $self->_initialized( 0 );

    print "$filename loaded\n";
}

# TODO: Bogus redirects to containes class -- look at Moo roles for this
sub play_note($self, $tick, $key, $length, $velocity) {
    $self->_midi->play_note($tick, $key, $length, $velocity);
};

# TODO: Bogus redirects to containes class -- look at Moo roles for this
sub controller($self, $tick, $control_num, $value) {
    $self->_midi->controller($tick, $control_num, $value);
}

# TODO: Bogus redirects to containes class -- look at Moo roles for this
sub program_change($self, $tick, $value) {
    $self->_midi->program_change($tick, $value);
}

# TODO: Bogus redirects to containes class -- look at Moo roles for this
sub all_sound_off($self) {
    $self->_midi->all_sound_off();
}

# TODO: Bogus redirects to containes class -- look at Moo roles for this
sub all_notes_off($self) {
    $self->_midi->all_notes_off();
}

sub sequenced_drums($self, $tick, $note_num, $sequence) {
    my $token = _get_sequence_token($tick, $sequence);
    return if $token eq ' ';
    my $velocity = $token eq 'X' ? 127 : 96;
    $self->play_note($tick, $note_num, 1, $velocity);
}

sub sequenced_controller($self, $tick, $control_num, $sequence) {
    my $token = _get_sequence_token($tick, $sequence);
    return unless $token =~ /[0-9a-f]/;
    my $value = int( 8.45 * hex($token) );
    $self->controller($tick, $control_num, $value);
}

sub _get_sequence_token($tick, $sequence) {
    my $pos = $tick % (length $sequence);
    return substr $sequence, $pos, 1;
}

1;
