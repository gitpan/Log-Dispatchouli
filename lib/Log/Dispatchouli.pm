use strict;
use warnings;
package Log::Dispatchouli;

=head1 NAME

Log::Dispatchouli - a simple wrapper around Log::Dispatch

=cut

use Carp ();
use Log::Dispatch;
use Params::Util qw(_ARRAYLIKE);
use Scalar::Util qw(blessed weaken);
use String::Flogger;

our $VERSION = '1.000';

=head1 METHODS

=head2 new

  my $logger = Log::Dispatchouli->new(\%arg);

This returns a new SvcLogger, which can then be called like a coderef to log
stuff.  You know.  Stuff.  Things, too, we'll log those.

Valid arguments are:

  ident      - the name of the thing logging (mandatory)
  to_self    - log to the logger object for testing; default: false
  to_file    - log to PROGRAM_NAME.YYYYMMDD in the log path; default: false
  to_stdout  - log to STDOUT; default: false
  to_stderr  - log to STDERR; default: false
  facility   - to which syslog facility to send logs; default: none
  fail_fatal - a boolean; if true, failure to log is fatal; default: true
  debug      - a boolean; if true, log_debug method is not a no-op
               defaults to the truth of the ICG_LOG_DEBUG env var

The log path is either F</tmp> or the value of the F<ICG_LOG_PATH> env var.

If the F<ICG_LOG_NOSYSLOG> env var is true, we don't log to syslog.

=cut

sub new {
  my ($class, $arg) = @_;

  my $ident = $arg->{ident}
    or Carp::croak "no ident specified when using $class";

  my $self = bless {} => $class;

  # We make a weak copy so that the object can contain a coderef that
  # references the object without interfering with garbage collection. -- rjbs,
  # 2007-08-08
  my $copy = $self;
  weaken $copy;

  my $log = Log::Dispatch->new(
    callbacks => sub {
      my $prefix = $copy->get_prefix || '';
      length($prefix) && ($prefix = "$prefix: ");
      return "[$$] $prefix" . {@_}->{message}
    },
  );

  if ($arg->{to_file}) {
    require Log::Dispatch::File;
    my $log_file = File::Spec->catfile(
      ($ENV{LOG_DISPATCHOULI} || File::Spec->tempdir),
      sprintf('%s.%04u%02u%02u',
        $ident,
        ((localtime)[5] + 1900),
        sprintf('%02d', (localtime)[4] + 1),
        sprintf('%02d', (localtime)[3]),
      )
    );

    $log->add(
      Log::Dispatch::File->new(
        name      => 'logfile',
        min_level => 'debug',
        filename  => $log_file,
        mode      => 'append',
        callbacks => sub {
          # The time format returned here is subject to change. -- rjbs,
          # 2008-11-21
          return (localtime) . ' ' . {@_}->{message} . "\n"
        }
      )
    );
  }

  if ($arg->{facility} and not $ENV{LOG_DISPATCHOULI_NOSYSLOG}) {
    require Log::Dispatch::Syslog;
    $log->add(
      Log::Dispatch::Syslog->new(
        name      => 'syslog',
        min_level => 'debug',
        facility  => $arg->{facility},
        ident     => $ident,
        logopt    => 'pid',
        socket    => 'native',
        callbacks => sub {
          my %arg = @_;
          my $message = $arg{message};
          $message =~ s/\n/<LF>/g;
          return $message;
        },
      ),
    );
  }

  if ($arg->{to_self}) {
    $self->{events} = [];
    require Log::Dispatch::Array;
    $log->add(
      Log::Dispatch::Array->new(
        name      => 'self',
        min_level => 'debug',
        array     => $self->{events},
      ),
    );
  }

  DEST: for my $dest (qw(err out)) {
    next DEST unless $arg->{"to_std$dest"};
    require Log::Dispatch::Screen;
    $log->add(
      Log::Dispatch::Screen->new(
        name      => "std$dest",
        min_level => 'debug',
        stderr    => ($dest eq 'err' ? 1 : 0),
        callbacks => sub { my %arg = @_; "$arg{message}\n"; }
      ),
    );
  }

  $self->{dispatcher} = $log;
  $self->{prefix} = $arg->{prefix} || $arg->{list_name};
  $self->{debug}  = exists $arg->{debug} ? $arg->{debug} : $ENV{ICG_LOG_DEBUG};
  $self->{fail_fatal} = exists $arg->{fail_fatal} ? $arg->{fail_fatal} : 1;

  return $self;
}

=head2 new_tester

This returns a new logger that doesn't log.  It's useful in testing.  If no
C<ident> arg is provided, one will be generated.

=cut

sub new_tester {
  my ($class, $arg) = @_;
  $arg ||= {};

  return $class->new({
    %$arg,
    ($arg->{ident} ? () : (ident => "$$:$0")),
    to_stderr => 0,
    to_stdout => 0,
    to_file   => 0,
    facility  => undef,
  });
}

=head2 log

  $logger->log($message);

This method uses L<String::Flogger|String::Flogger> on the input, then logs the
result.

=cut

sub _log_at {
  my ($self, $level, $message, $arg) = @_;

  {
    local $@;
    my $ok = eval {
      $message = String::Flogger->flog($message);

      $self->dispatcher->log(
        level   => $level,
        message => $message,
      );

      1;
    };

    die if ! $ok and $self->{fail_fatal};
  }

  $message = "log_fatal && ! fail_fatal; failed to log"
    unless defined $message;

  die $message if $arg and $arg->{fatal};
}

sub log {
  my ($self, $message) = @_;
  $self->_log_at(info => $message);
}

=head2 log_fatal

This behaves like the C<log> method, but will throw the logged string as an
exception after logging.

=cut

sub log_fatal {
  my ($self, $message) = @_;
  $self->_log_at(info => $message, { fatal => 1 });
}

=head2 log_debug

This behaves like the C<log> method, but will only log (at the debug level) if
the SvcLogger object has its debug property set to true.

=cut

sub log_debug {
  my ($self, $message) = @_;
  return unless $self->debug;
  $self->_log_at(debug => $message);
}

=head2 debug

This gets or sets the SvcLogger's debug property, which affects the behavior of
C<log_debug>.

=cut

sub debug {
  my $self = shift;
  $self->{debug} = $_[0] if @_;
  return $self->{debug};
}

=head2 dispatcher

This returns the underlying Log::Dispatch object.  This is not the method
you're looking for.  Move along.

=cut

sub dispatcher   { $_[0]->{dispatcher} }

sub get_prefix   { $_[0]->{prefix} }
sub set_prefix   { $_[0]->{prefix} = $_[1] }
sub unset_prefix { undef $_[0]->{prefix} }

=head2 events

This method returns the arrayref of events logged to an array in memory (in the
logger).  If the logger is not logging C<to_self> this raises an exception.

=cut

sub events {
  Carp::confess "->events called on a logger not logging to self"
    unless $_[0]->{events};

  return $_[0]->{events};
}

use overload
  '&{}'    => sub { my ($self) = @_; sub { $self->log(@_) } },
  fallback => 1,
;


=head1 SEE ALSO

L<Log::Dispatch>

L<String::Flogger>

=head1 AUTHOR

Ricardo SIGNES, C<< <rjbs@cpan.org> >>

=head1 COPYRIGHT

Copyright 2008 Ricardo SIGNES.  This program is free software;  you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
