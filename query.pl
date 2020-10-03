#!/usr/bin/perl
use strict 'vars';
use warnings;

use Net::SRCDS::Queries;
use JSON::XS;

my $addr     = $ARGV[0];
my $port     = $ARGV[1];
 
my $q = Net::SRCDS::Queries->new(
    timeout  => 0.1,
);
$q->add_server( $addr, $port );

print encode_json($q->get_all);
