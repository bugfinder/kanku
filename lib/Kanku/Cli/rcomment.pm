package Kanku::Cli::rcomment;

use MooseX::App::Command;
extends qw(Kanku::Cli);

with 'Kanku::Cli::Roles::Remote';
with 'Kanku::Cli::Roles::RemoteCommand';
with 'Kanku::Cli::Roles::View';

use Term::ReadKey;
use Log::Log4perl;
use POSIX;
use Try::Tiny;

command_short_description "list job history on your remote kanku instance";

command_long_description
  "list/create/show/modify/delete comments in the job history on your remote kanku instance

" . $_[0]->description_footer;

option 'job_id' => (
  isa           => 'Int',
  is            => 'rw',
  cmd_aliases   => 'j',
  documentation => 'job id',
);

option 'comment_id' => (
  isa           => 'Int',
  is            => 'rw',
  cmd_aliases   => 'C',
  documentation => 'comment id',
);

option 'message' => (
  isa           => 'Str',
  is            => 'rw',
  cmd_aliases   => 'm',
  documentation => 'message',
);

option 'create' => (
  isa           => 'Bool',
  is            => 'rw',
  cmd_aliases   => 'c',
  documentation => '(*) create comment with "message"',
);

option 'show' => (
  isa           => 'Bool',
  is            => 'rw',
  cmd_aliases   => 's',
  documentation => '(*) show comment',
);

option 'modify' => (
  isa           => 'Bool',
  is            => 'rw',
  cmd_aliases   => 'M',
  documentation => '(*) Modify comment',
);

option 'delete' => (
  isa           => 'Bool',
  is            => 'rw',
  cmd_aliases   => 'D',
  documentation => '(*) Delete comment',
);

sub run {
  my $self  = shift;
  Kanku::Config->initialize;
  my $logger  =	Log::Log4perl->get_logger;

  if ($self->list) {
    $self->_list();
  } elsif ($self->create) {
    $self->_create();
  } elsif ($self->modify) {
    $self->_modify();
  } elsif ($self->delete) {
    $self->_delete();
  } else {
	$logger->warn("Please specify a command. Run 'kanku rcomment --help' for further information.");
  }
}

sub _list {
  my $self = shift;
  my $logger  =	Log::Log4perl->get_logger;

  if (! $self->job_id ) {
    $logger->warn("Please specify a job_id");
    exit 1;
  }

  my $kr;
  try {
	$kr = $self->connect_restapi();
  } catch {
	exit 1;
  };

  my %params = (
    job_id => $self->job_id,
  );

  my $data = $kr->get_json( path => "job/comments/".$self->job_id );
};

sub _create {
  my $self = shift;
  my $logger  =	Log::Log4perl->get_logger;

  if (! $self->job_id ) {
    $logger->warn("Please specify a job_id (-j <job_id>)");
    exit 1;
  }

  if (! $self->message ) {
    $logger->warn("Please specify a comment message (-m 'my message')");
    exit 1;
  }

  my $kr;
  try {
	$kr = $self->connect_restapi();
  } catch {
	exit 1;
  };

  my %params = (message => $self->message);

  my $data = $kr->post_json( path => "job/comment/".$self->job_id, data => \%params );
};

sub _modify {
  my $self = shift;
  my $logger  =	Log::Log4perl->get_logger;

  if (! $self->comment_id ) {
    $logger->warn("Please specify a comment_id (-C <comment_id>)");
    exit 1;
  }

  if (! $self->message ) {
    $logger->warn("Please specify a comment message (-m 'my message')");
    exit 1;
  }

  my $kr;
  try {
	$kr = $self->connect_restapi();
  } catch {
	exit 1;
  };

  my %params = (message => $self->message);

  my $data = $kr->put_json( path => "job/comment/".$self->comment_id, data => \%params );
};

sub _delete {
  my $self = shift;
  my $logger  =	Log::Log4perl->get_logger;

  if (! $self->comment_id ) {
    $logger->warn("Please specify a comment_id (-C <comment_id>)");
    exit 1;
  }

  my $kr;
  try {
	$kr = $self->connect_restapi();
  } catch {
	exit 1;
  };

  my $data = $kr->delete_json( path => "job/comment/".$self->comment_id);
};

__PACKAGE__->meta->make_immutable;

1;