#!/usr/bin/perl

use strict;
use warnings;
use Net::IP qw(:PROC);
use Net::IP::MAPCALC;
use Data::Dumper;

my $data = '2001:0db8:0012:3400:0000:c000:0212:0034';

my @mapping_rules = (
    {
        'ipv6'        => '2001:db8:0000::/40',
        'ipv4'        => '192.0.2.0/24',
        'ea_len'      => 16,
        'psid_offset' => 6
    },
    {
        'ipv6'        => '2001:db8:1100::/40',
        'ipv4'        => '192.168.0.0/24',
        'ea_len'      => 16,
        'psid_offset' => 6
    }
);

my $rules;
my $data_ip  = new Net::IP($data);
my $data_bin = $data_ip->binip();

foreach my $ref (@mapping_rules) {
    my ( $ref_nw, $ref_len ) = split /\//, $ref->{'ipv6'};
    my $ref_ip  = new Net::IP($ref_nw);
    my $ref_bin = $ref_ip->binip();
    if ( ( substr( $data_bin, 0, $ref_len ) ) eq
        ( substr( $ref_bin, 0, $ref_len ) ) )
    {
        $rules = $ref;
    }
}
if ( !defined $rules ) {
    die "Error: mapping rules not found\n";
}

my $map = Net::IP::MAPCALC->new($rules);
print Dumper $map->ipv6_to_ipv4($data);

