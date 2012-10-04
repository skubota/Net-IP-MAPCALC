package Net::IP::MAPCALC;

use vars qw($VERSION);
our $VERSION = '0.01';
use Net::IP qw(:PROC);

sub new {
    my ( $class, $conf ) = @_;
    my $self = {};
    bless( $self, $class );
    unless ( $self->check($conf) ) {
        return $self->error();
    }
    return $self;
}

sub check {
    my ( $self, $data ) = @_;

    for (
        qw(ipv6_prefix ipv4_prefix ipv6_len ipv4_len ea_len psid_offset min_port )
      )
    {
        delete( $self->{$_} );
    }
    if( !$data->{ipv4_prefix} && !$data->{ipv4_len} && $data->{ipv4}){
       ($data->{ipv4_prefix},$data->{ipv4_len})=split /\//,$data->{ipv4};
    }
    if( !$data->{ipv6_prefix} && !$data->{ipv6_len} && $data->{ipv6}){
       ($data->{ipv6_prefix},$data->{ipv6_len})=split /\//,$data->{ipv6};
    }
    if ( $data->{ipv6_prefix} && new Net::IP( $data->{ipv6_prefix} ) ) {
        $self->{ipv6_prefix} = $data->{ipv6_prefix};
    }
    else {
        $self->{error} = Net::IP::Error();
        return;
    }
    if ( $data->{ipv4_prefix} && new Net::IP( $data->{ipv4_prefix} ) ) {
        $self->{ipv4_prefix} = $data->{ipv4_prefix};
    }
    else {
        $self->{error} = Net::IP::Error();
        return;
    }

    if (   !$data->{ipv6_len}
        || 3 > $data->{ipv6_len}
        || 128 < $data->{ipv6_len} )
    {
        $self->{error} = "Error: IPv6 length is wrong.";
        return;
    }
    else {
        $self->{ipv6_len} = $data->{ipv6_len};
    }
    if ( !$data->{ipv4_len} || 3 > $data->{ipv4_len} || 32 < $data->{ipv4_len} )
    {
        $self->{error} = "Error: IPv4 length is wrong.";
        return;
    }
    else {
        $self->{ipv4_len} = $data->{ipv4_len};
    }
    if (   0 > $data->{ea_len}
        || 48 <= $data->{ea_len}
        || 128 - $self->{ipv6_len} < $data->{ea_len}
        || 32 - $self->{ipv4_len} > $data->{ea_len} )
    {
        $self->{error} = "Error: EA langth is wrong.";
        return;
    }
    else {
        $self->{ea_len} = $data->{ea_len};
    }
    if ( 0 > $data->{psid_offset} || 16 < $data->{psid_offset} ) {
        $self->{error} = "Error: PSID offset is wrong.";
        return;
    }
    else {
        $self->{psid_offset} = $data->{psid_offset};
    }

    $self->{min_port} = 2**( 16 - $self->{'psid_offset'} );

    return $self;
}

sub error {
    my $self = shift;
    return $self->{error};
}

sub ipv4_to_ipv6 {
    my ( $self, $addr, $port ) = @_;

    my $addr_v4 = new Net::IP($addr);
    my $bin_v4  = $addr_v4->binip();

    if ( $port < $self->{min_port} || $port > 65535 ) {
        $self->{error} = "Error: port range.";
        return;
    }

    my $addr_v6_prefix = new Net::IP( $self->{ipv6_prefix} );
    my $addr_v4_prefix = new Net::IP( $self->{ipv4_prefix} );
    my $bin_ip6        = substr $addr_v6_prefix->binip(), 0, $self->{ipv6_len};
    my $bin_ip4  = substr $bin_v4, $self->{ipv4_len}, 32 - $self->{ipv4_len};
    my $bin_port = $self->dec2bin($port);
    my $bin_port_pad = '0' x ( 16 - length($bin_port) );
    my $bin_psid = substr $bin_port_pad . $bin_port, $self->{psid_offset},
      ( $self->{ea_len} - ( 32 - $self->{ipv4_len} ) );
    my $bin_psid2 = ('0' x ( 16 - length($bin_psid) )) . $bin_psid;
    my $prefix_pad = '0' x ( 64 - ( $self->{ipv6_len} + $self->{ea_len} ) );
    my $suffix_pad = '0' x 8;
    my $last_pad   = '0' x 8;

    return ip_bintoip(
        $bin_ip6 
          . $bin_ip4
          . $bin_psid
          . $prefix_pad
          . $suffix_pad
          . $bin_v4
          . $bin_psid2
          . $last_pad,
        6
    );

}

sub ipv6_to_ipv4 {
    my ( $self, $addr ) = @_;

    my $addr_v6 = new Net::IP($addr);
    my $bin_v6  = $addr_v6->binip();

    my $ipv4_prefix      = new Net::IP( $self->{ipv4_prefix} );
    my $bin_ipv4_prefix  = substr $ipv4_prefix->binip(), 0, $self->{ipv4_len};
    my $bin_ipv6_in_ipv4 = substr $bin_v6, $self->{ipv6_len},
      32 - $self->{ipv4_len};
    my $bin_psid = substr $bin_v6,
      $self->{ipv6_len} + ( 32 - $self->{ipv4_len} ),
      $self->{ea_len} - ( 32 - $self->{ipv4_len} );

    my $port_range;
    for ( my $offset = 1 ; $offset < ( 2**$self->{psid_offset} ) ; $offset++ ) {
        my $bin_offset = $self->dec2bin($offset);
        my $pad = '0b' . '0' x ( $self->{psid_offset} - length($bin_offset) );
        my $bin_minport =
            $pad
          . $bin_offset
          . $bin_psid
          . '0' x ( 16 - $self->{psid_offset} - length($bin_psid) );
        my $bin_maxport =
            $pad
          . $bin_offset
          . $bin_psid
          . '1' x ( 16 - $self->{psid_offset} - length($bin_psid) );
        push @$port_range, sprintf "%s-%s", oct $bin_minport, oct $bin_maxport;
    }
    return ip_bintoip( $bin_ipv4_prefix . $bin_ipv6_in_ipv4, 4 ), $port_range;
}

sub get_ratio {
    my ( $self ) = @_;
    return 2**($self->{ea_len} - ( 32 - $self->{ipv4_len} ));
}

sub get_psidlen {
    my ( $self ) = @_;
    return $self->{ea_len} - ( 32 - $self->{ipv4_len}) ;
}

sub dec2bin {
    my ( $self, $dec ) = @_;
    $str = unpack( "B32", pack( "N", $dec ) );
    $str =~ s/^0+(?=\d)//;
    return $str;
}

__END__

=head1 NAME

Net::IP::MAPCALC - Perl extension for calculation MAP address

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

  use Net::IP::MAPCALC;

  my $map = Net::IP::MAPCALC->new({
    'ipv6_prefix'     => '2001:db8::',
    'ipv6_len'        => 40,
    'ipv4_prefix'     => '192.0.2.0',
    'ipv4_len'        => 24,
    'ea_len'          => 16,
    'psid_offset'     => 4
  });

  my $ipv6_addr = $map->ipv4_to_ipv6( '192.0.2.128', '34567' );
  my ($ipv4_addr,$ports) = $map->ipv6_to_ipv4('2001:0db8:0080:7000:00c0:0002:8070:0000');
  my $shareing_ratio = $map->get_ratio;

=head1 DESCRIPTION

Calculation IPv6 address from IPv4 address + port,
or IPv4 address + port range from IPv6 address.

MAP: http://tools.ietf.org/html/draft-ietf-softwire-map-02

=head1 METHODS
=head2 new

You should not need to call this method directory. Instead:
  my $config = Bot::Net->config;
will call the constructor as needed.


=head1 AUTHOR

Satoshi KUBOTA, skubota at cpan.org


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::IP::MAPCALC


You can also look for information at:

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

COPYRIGHT AND LICENCE

Copyright (C) 2012 by skubota

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
