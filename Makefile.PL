
use strict;
use warnings;



use ExtUtils::MakeMaker 6.11;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Log::Dispatchouli',
                       'DISTNAME' => 'Log-Dispatchouli',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.11'
                                               },
                       'AUTHOR' => 'Ricardo SIGNES <rjbs@cpan.org>',
                       'BUILD_REQUIRES' => {},
                       'ABSTRACT' => 'a simple wrapper around Log::Dispatch',
                       'EXE_FILES' => [],
                       'VERSION' => '1.100690',
                       'PREREQ_PM' => {
                                        'Try::Tiny' => '0.04',
                                        'Scalar::Util' => '0',
                                        'Log::Dispatch::Array' => '0',
                                        'overload' => '0',
                                        'Sys::Syslog' => '0.16',
                                        'Carp' => '0',
                                        'Test::More' => '0.88',
                                        'Log::Dispatch::File' => '0',
                                        'Params::Util' => '0',
                                        'Log::Dispatch::Screen' => '0',
                                        'Log::Dispatch' => '0',
                                        'Log::Dispatch::Syslog' => '0',
                                        'Test::Deep' => '0',
                                        'String::Flogger' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(%WriteMakefileArgs);



