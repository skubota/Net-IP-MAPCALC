# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-IP-MAPCALC.t'

#########################

use Test::More tests => 4;
BEGIN { use_ok('Net::IP::MAPCALC') };

#!/usr/bin/perl

use Net::IP::MAPCALC;
ok $map = Net::IP::MAPCALC->new({
    'ipv6_prefix'     => '2001:db8::',
    'ipv6_len' => '40',
    'ipv4_prefix'     => '192.0.2.0',
    'ipv4_len' => '24',
    'ea_len'          => 16,
    'psid_offset'     => 4
});
isnt $map->error();
ok $map->ipv4_to_ipv6( '192.0.2.128', '34567' );
isnt $map->error();
ok $map->ipv6_to_ipv4('2001:0db8:0080:7000:00c0:0002:8070:0000');
isnt $map->error();

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

