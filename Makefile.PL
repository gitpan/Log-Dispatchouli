
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'a simple wrapper around Log::Dispatch',
  'AUTHOR' => 'Ricardo SIGNES <rjbs@cpan.org>',
  'BUILD_REQUIRES' => {
    'Test::Deep' => '0',
    'Test::Fatal' => '0',
    'Test::More' => '0.96'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Log-Dispatchouli',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Log::Dispatchouli',
  'PREREQ_PM' => {
    'Carp' => '0',
    'File::Spec' => '0',
    'Log::Dispatch' => '0',
    'Log::Dispatch::Array' => '0',
    'Log::Dispatch::File' => '0',
    'Log::Dispatch::Screen' => '0',
    'Log::Dispatch::Syslog' => '0',
    'Params::Util' => '0',
    'Scalar::Util' => '0',
    'String::Flogger' => '0',
    'Sub::Exporter' => '0',
    'Sub::Exporter::GlobExporter' => '0.002',
    'Sys::Syslog' => '0.16',
    'Try::Tiny' => '0.04',
    'overload' => '0'
  },
  'VERSION' => '2.005',
  'test' => {
    'TESTS' => 't/*.t'
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



