# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-IP-MAPCALC.t'

#########################

use Test::More tests => 5;
use Net::IP::MAPCALC;
BEGIN { use_ok('Net::IP::MAPCALC') };

ok $map = Net::IP::MAPCALC->new({
    'ipv6_prefix'     => '2001:db8::',
    'ipv6_len' => '40',
    'ipv4_prefix'     => '192.0.2.0',
    'ipv4_len' => '24',
    'ea_len'          => 16,
    'psid_offset'     => 6
});

my $ipv6 = $map->ipv4_to_ipv6( '192.0.2.128', '34567' );
diag explain $ipv6;
is ($ipv6,'2001:0db8:0080:c100:0000:c000:0280:00c1','ipv4_to_ipv6 test');
my ($ipv4,$ports)= $map->ipv6_to_ipv4('2001:0db8:0080:c100:0000:c000:0280:00c1');
diag explain $ipv4;
diag explain $ports;
is ($ipv4,'192.0.2.128','ipv6_to_ipv4 test');
my $ratio=$map->get_ratio;
is ($ratio,'256','get_ratio test');

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

