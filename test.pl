#!/usr/bin/perl
use strict 'vars';
use warnings;

use lib q/./;

use Coro;
use Socket;
use AnyEvent;
use AnyEvent::Handle::UDP;
use Data::Dumper::Perltidy;

my $server = '144.48.37.114';
my $port   = 27015;

sub parse_a2s_info {
    my( $buf ) = @_;
    my( $type, $version, $str ) = unpack 'x4aca*', $buf;
    my( $sname, $map, $dir, $desc, $remains ) = split /\0/, $str, 5;
    my(
        $app_id, $players, $max,    $bots, $dedicated,
        $os,     $pw,      $secure, $remains2
    ) = unpack 'vcccaacca*', $remains;
    my( $gversion, $remains3 ) = split /\0/, $remains2, 2;

    my $result = {
        type      => $type,
        version   => $version,
        sname     => $sname,
        map       => $map,
        dir       => $dir,
        desc      => $desc,
        app_id    => $app_id,
        players   => $players,
        max       => $max,
        bots      => $bots,
        dedicated => $dedicated,
        os        => $os,
        password  => $pw,
        secure    => $secure,
        gversion  => $gversion,
    };
    my( $edf, $opt ) = unpack 'ca*', $remains3;
    if ( $edf & 0x80 ) {
        my $port;
        ( $port, $opt ) = unpack 'va*', $opt;
        $result->{port} = $port;
    }
    if ( $edf & 0x40 ) {
        # print "opt is spectator port\n";
        $result->{spectator} = '';
    }
    if ( $edf & 0x20 ) {
        chop $opt;
        $result->{game_tag} = $opt;
    }
    return $result;
}

sub parse_a2s_player {
    my( $buf ) = @_;
    my( $type, $num_players, $followings ) = unpack 'x4aca*', $buf;
    my $player_info;
    while ($followings) {
        my( $index, $r1 ) = unpack 'ca*', $followings;
        my( $name, $r2 ) = ( split /\0/, $r1, 2 );
        my( $kills, $connected, $r3 ) = unpack 'lfa*', $r2;
        push @{$player_info},
            {
            name      => $name,
            kills     => $kills,
            connected => $connected,
            };
        $followings = $r3;
    }

    my $result = {
        type        => $type,
        num_players => $num_players,
        player_info => $player_info,
    };
    return $result;
}

our $t = AnyEvent::Handle::UDP->new(
    on_recv => unblock_sub {
        my ($data, $ae_handle, $client_addr) = @_;
        # get whether multipart or not
        my $multipack = unpack 'i', $data;
        # get type of response
        my $t = unpack 'x4a', $data;

        my ($port, $addr) = unpack_sockaddr_in($client_addr);
        my $host = inet_ntoa($addr);

        if ($t eq 'A') {
            my( $type, $cnum ) = unpack 'x4aa4', $data;
            $ae_handle->push_send("\xFF\xFF\xFF\xFF\x55".$cnum);
        }
        elsif ($t eq 'I') {
            # server info
            # warn Dumper \parse_a2s_info($data);
        }
        elsif ($t eq 'D') {
            # player info
            # warn Dumper \parse_a2s_player($data);
        }
        elsif ($t eq 'E') {
            # rules
        }
        else {
            warn "got: $data";
        }
    },
    connect => [$server, $port],
    on_connect => unblock_sub {
        my ($ae_handle, $server_addr) = @_;
        $ae_handle->push_send("\xFF\xFF\xFF\xFFTSource Engine Query\0");
        $ae_handle->push_send("\xFF\xFF\xFF\xFF\x57");
    },
    on_error => sub { warn Dumper \@_ },
    on_timeout => sub { warn Dumper \@_ },
);

AE::cv->recv;