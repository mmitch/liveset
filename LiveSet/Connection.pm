package LiveSet::Connection;

use MIDI::ALSA;
use Scalar::Util qw( looks_like_number );

use Moo;
use strictures 2;
use namespace::clean;

use feature 'signatures';
no warnings 'experimental::signatures';
## no critic (ProhibitSubroutinePrototypes)

has target => (
    is => 'ro',
    required => 1,
    isa => sub {
	my $target = $_[0];
	my $type = ref $target;
	die "target $target is no string, but a $type reference" if $type;
    },
    );

has port => (
    is => 'rw',
    isa => sub {
	my $port = $_[0];
	die "port $port is not numeric" unless looks_like_number $port;
    },
    );

1;
