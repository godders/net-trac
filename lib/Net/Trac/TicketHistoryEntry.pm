package Net::Trac::TicketHistoryEntry;
use Moose;
use Net::Trac::TicketPropChange;

has connection => (
    isa => 'Net::Trac::Connection',
    is  => 'ro'
);

has prop_changes => ( isa => 'HashRef', is => 'rw' );

has author   => ( isa => 'Str',      is => 'rw' );
has date     => ( isa => 'DateTime', is => 'rw' );
has category => ( isa => 'Str',      is => 'rw' );
has content  => ( isa => 'Str',      is => 'rw' );

sub parse_feed_entry {
    my $self = shift;
    my $e    = shift;    # XML::Feed::Entry

    $self->author( $e->author );
    $self->date( $e->issued );
    $self->category( $e->category );

    my $desc = $e->content->body;

    if ( $desc =~ s/^\s*<ul>\s*?<li>(.*?)<\/li>\s*?<\/ul>//gism ) {

        my $props = $1;
        $self->prop_changes( $self->_parse_props($props) );

    }

    $self->content($desc);
    return 1;
}

sub _parse_props {
    my $self       = shift;
    my $raw        = shift;
    my @prop_lines = split( m#</li>\s*<li>#, $raw );
    my $props      = {};
    foreach my $line (@prop_lines) {
        my $prop = '';
        my $new  = '';
        my $old  = '';
        if ( $line
            =~ /<strong>(.*?)<\/strong> changed from <em>(.*)<\/em> to <em>(.*)<\/em>/
            )
        {
            $prop = $1;
            $old  = $2;
            $new  = $3;
        } elsif ( $line =~ /<strong>(.*?)<\/strong> set to <em>(.*)<\/em>/ ) {
            $prop = $1;
            $old  = '';
            $new  = $2;
        } elsif ( $line =~ /<strong>(.*?)<\/strong> deleted/ ) {
            $prop = $1;
            $new  = '';
        }

        my $pc = Net::Trac::TicketPropChange->new(
            property  => $prop,
            new_value => $new,
            old_value => $old
        );
        $props->{$prop} = $pc;
    }
    return $props;
}

1;
