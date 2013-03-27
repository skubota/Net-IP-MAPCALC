#!/usr/bin/perl

use strict;
use warnings;
use Net::IP::MAPCALC;
use Data::Dumper;

my $map = Net::IP::MAPCALC->new(
    {
        'ipv6_prefix' => '2001:db8::',
        'ipv6_len'    => '40',
        'ipv4_prefix' => '192.0.2.0',
        'ipv4_len'    => '24',
        'ea_len'      => 16,
        'psid_offset' => 6
    }
);

print Dumper $map->ipv4_to_ipv6( '192.0.2.18', '1232' );
print Dumper $map->ipv6_to_ipv4('2001:0db8:0012:3400:0000:c000:0212:0034');

