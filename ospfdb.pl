#!/usr/bin/perl -T
use strict;
use warnings;
$|=1;

use Net::SNMP qw(snmp_dispatcher);

my $community = 'public';
my @routers = qw(
    192.0.2.1
    192.0.2.2
);

my @oids = (
    { oid => '1.3.6.1.2.1.14.2.1.7.0', name => 'ospfAreaLsaCount'      },
    { oid => '1.3.6.1.2.1.14.2.1.8.0', name => 'ospfAreaLsaCksumSum'   },
    { oid => '1.3.6.1.2.1.14.1.6.0',   name => 'ospfExternLsaCount'    },
    { oid => '1.3.6.1.2.1.14.1.7.0',   name => 'ospfExternLsaCksumSum' },
);

for my $oid_ref (@oids) {
    for my $router (@routers) {
        my ($session, $error) = Net::SNMP->session(
                                    -hostname    => $router,
                                    -nonblocking => 0x1,
                                    -community   => $community,
        );
        $session->get_request(
            -varbindlist => [ $oid_ref->{oid} ],
            -callback    => [ \&print_results, $router, $oid_ref ],
        );
    }
    snmp_dispatcher();
}

sub print_results {
    my ( $session, $router, $oid_ref ) = @_;
    my $result = $session->var_bind_list();

    if ( !defined $result) {
        print STDERR "ERROR: get request failed $router/$oid_ref->{oid}\n";
        return;
    } 

    print "$oid_ref->{name}: $result->{$oid_ref->{oid}} ($router)\n";

    return;
}
