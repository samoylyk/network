#!/usr/bin/perl
use strict;
use warnings;
$|=1;

use Expect;
use Getopt::Std;
use Net::SSH::Expect;
use Net::Telnet;

use constant USAGE =>
"$0 [ -p password ] [ -u username ] [ -s | -S ] host [ 'command' ]

  -p password
  -u username
  -s enable SSH with password authentication
  -S enable SSH with public key authentication
";

getopts( 'p:u:sS', \my %opts );

if ( $opts{s} && $opts{S} ) {
    die USAGE;
}
if ( scalar @ARGV != 1 ) {
    die USAGE;
}
my $host     = $ARGV[0];
my $cmd      = $ARGV[1] || 'show version';
my $password = $opts{p} || q{};
my $username = $opts{u} || q{};
my $session;

if ( $opts{s} || $opts{S} ) {
    ssh_login();
}
else {
    telnet_login();
}

$session->send("term length 0\n");
$session->expect( 1, '> ' );
$session->log_stdout(1);
$session->send("$cmd\n");
$session->expect( 1, '> ' );
$session->log_stdout(0);

if ( $opts{s} || $opts{S} ) {
    $session->close();
}
else {
    $session->soft_close();
}

print "\n";

sub ssh_login {

    $session = Net::SSH::Expect->new(
        host     => $host,
        user     => $username,
        raw_pty  => 1,
    );
    if ($opts{s}) {
        $session->password = $password,
        $session->login();
    }
    else {
        $session->run_ssh();
    }

    return;
}

sub telnet_login {
    my $telnet = new Net::Telnet($host);
    $session   = Expect->exp_init($telnet);

    $session->expect( 5,
        [
            qr'Username: ',
                sub {
                    $session->send("$username\n"); 
                    exp_continue;
                }
        ],
        [
            qr'Password: ',
                sub {
                    $session->send("$password\n");
                }
        ],
    );

    return;
}
