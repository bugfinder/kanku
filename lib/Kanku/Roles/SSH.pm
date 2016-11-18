# Copyright (c) 2016 SUSE LLC
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program (see the file COPYING); if not, write to the
# Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA
#
package Kanku::Roles::SSH;

use Moose::Role;

use Data::Dumper;
use Net::SSH2;

use namespace::autoclean;

with 'Kanku::Roles::Logger';
use Kanku::Config;

has [qw/  domain_name     ipaddress   publickey_path
          privatekey_path passphrase  username
    /] => (is=>'rw',isa=>'Str');

has [ qw/job ssh2/ ] => (
  is => 'rw',
  isa => 'Object'
);

has auth_type => (
  is=>'rw',
  isa=>'Str',
  lazy => 1,
  default=>
  sub {
    my $logger = $_[0]->logger;
    my $cfg = Kanku::Config->instance->config();
    $logger->debug(Dumper($cfg));
    my $class = __PACKAGE__;
    $logger->debug("PACKAGE = $class");
    if ( $cfg->{$class}->{auth_type}) {
      return $cfg->{$class}->{auth_type};
    }
    return 'agent'
  }
);

sub get_defaults {
  my $self = shift;

  if (! $self->privatekey_path ) {
    $self->privatekey_path("$ENV{HOME}/.ssh/id_rsa");
    $self->publickey_path($self->privatekey_path.".pub") if (! $self->publickey_path );
  }
  $self->username('root') if (! $self->username );
  $self->ipaddress($self->job()->context()->{ipaddress});

  return 1;
}

sub connect {
  my $self    = shift;
  my $ssh2    = Net::SSH2->new(strict_host_key_checking=>'no');
  $self->ssh2($ssh2);

  my $results = [];
  my $ip      = $self->ipaddress;

  $self->logger->debug("Connecting to $ip");

  $ssh2->connect($ip) or die $!;

  if ( $self->auth_type eq 'publickey' ) {
    $self->logger->debug(" - ssh2: using auth_publickey");
    $ssh2->auth_publickey(
      $self->username,
      $self->publickey_path,
      $self->privatekey_path,
      $self->passphrase
    );
  } elsif ( $self->auth_type eq 'agent' ) {
    $self->logger->debug(" - ssh2: using auth_agent");
    $ssh2->auth_agent($self->username);
  } else {
    die "ssh auth_type not known!\n"
  }

  if ( ! $ssh2->auth_ok()  ) {

    $self->logger->info(
      "Using the following login data:\n" .
          "username   : " . ( $self->username || '' )         . "\n".
          "pubkey     : " . ( $self->publickey_path || '' )   . "\n".
          "privkey    : " . ( $self->privatekey_path || '' )  . "\n".
          "passphrase : " . ( $self->passphrase || '' )       . "\n"
    );
    my @err = $ssh2->error;
    die "Could not authenticate! $err[2]\n";
  }

  return $ssh2
}

sub exec_command {
  my $self = shift;
  my $cmd  = shift;
  my $ssh2 = $self->ssh2;

  my $chan = $ssh2->channel();
  $chan->ext_data('merge');

  $self->logger->info("Executing command: $cmd");
  $chan->exec($cmd);

  my $out = undef;
  my $buf = undef;
  while ($chan->read($buf,1024)) {
    $out .= $buf;
  }

  die "Command '$cmd' failed:\n\n$out\n" if $chan->exit_status;

  return $out;
}

1;
