#!/usr/bin/perl -T
use strict;
use warnings;
$|=1;

use Net::DNS;
use Net::IP;

for my $addr (@ARGV) {
    my $ip      = new Net::IP ($addr);
    my $ptr     = $ip->reverse_ip();
    my $rev_ref = get_rdata( $ptr, 'PTR' );
    my $type    = $ip->version() == 4 ? 'A' : 'AAAA';

    for my $rev ( keys %$rev_ref ) {
        my $fwd_ref = get_rdata( $rev, $type );
        if ( exists $fwd_ref->{$addr} ) {
            print "$addr rev/fwd match with $rev\n";
        }
    }
}

sub get_rdata {
    my $qname = shift || return;
    my $type  = shift || return;
    my $res   = Net::DNS::Resolver->new;
    my $query   = $res->send( $qname, $type );
    my %rdata;

    return if !$query;
    return if $query->header->ancount < 1;

ANSWER:
    for my $answer ( $query->answer ) {
        next ANSWER if $answer->type ne $type;
        $rdata{$answer->rdatastr}++;
     }

    return \%rdata;
}
