package PXP;

use 5.008005;
use strict;
use warnings;

our $VERSION = '0.1';

use PXP::I18N;
use PXP::Config;
use PXP::PluginRegistry;

use Log::Log4perl qw(get_logger);
our $logger = get_logger();

sub init {
  my $args = {@_};

  $args->{debug} = 1 if ($ENV{PXP_DEBUG});
  $ENV{PXP_DEBUG} = 1 if ($args->{debug});

  $ENV{PXP_HOME} ||= `pwd`;
  chomp($ENV{PXP_HOME}); # suppress trailing CR

  my $log_file = $args->{log_file} || "pxp.log";
  my $level = $args->{debug} ? "DEBUG, Logfile, Screen" : "INFO, Logfile";
  if ($args->{log_conf} && -e $args->{log_conf}) {
    Log::Log4perl::init('log.conf');
  } else {
    my $log_conf = <<END;
log4perl.rootLogger                = $level
log4perl.appender.Logfile          = Log::Log4perl::Appender::File
log4perl.appender.Logfile.filename = $log_file
log4perl.appender.Loggile.layout   = Log::Log4perl::Layout::SimpleLayout
log4perl.appender.Logfile.layout   = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Logfile.layout.ConversionPattern = %d %p - %m %n
log4perl.appender.Screen           = Log::Log4perl::Appender::Screen
log4perl.appender.Screen.stderr    = 1
log4perl.appender.Screen.layout    = Log::Log4perl::Layout::SimpleLayout
#log4perl.appender.Screen           = Log::Log4perl::Appender::ScreenColoredLevels
#log4perl.appender.Screen.layout    = Log::Log4perl::Layout::PatternLayout
#log4perl.appender.Screen.layout.ConversionPattern = %d %F{1} %L> %m %n
END
    Log::Log4perl::init(\$log_conf);
  }

  $logger->info("PXP init");

  # install Exception reporting
  _installExceptionHandler();

  my $loaderconf = { dir => './plugins',
		     default => 'all' };

  # try to load a configuration file
  if ($args->{configuration_file} && -r $args->{configuration_file}) {
    PXP::Config::init(file => $args->{configuration_file});
    # override default loader configuration
    $loaderconf = PXP::Config::getGlobal()->{pluginloader};
  }

  # PXP::I18N::init();

  # load and startup plugins
  PXP::PluginRegistry::init($loaderconf);
}

sub _installExceptionHandler {
  $SIG{qq{__DIE__}} = sub {

    die @_ if $^S;	    # perldo -f die ... but it doesn't work ..

    local $SIG{qq{__DIE__}};	# next die() will be fatal

    my $msg = shift;

    my $err = "A fatal error occured : \n";
    $err .= $msg . "\n";

    # stack backtrace
    foreach my $i (1..30) {
      my ($package, $filename, $line, $subroutine,
	  $hasargs, $wantarray, $evaltext, $is_require) = caller($i);
      if ($package) {
	$err .= "\tat " . $subroutine;
	$err .= ' (' . $filename. ':' . $line . ")\n";
      }
    }
    $logger->error($err);

    die "stopping program\n";
  }

}

1;

=head1 NAME

PXP - Perl Xtensions & Plugins

=head1 SYNOPSIS

 use PXP;
 PXP::init();

=head1 DESCRIPTION

This modules provides a generic plugin framework, similar to the
Eclipse model.  It has been developed for the IMC project (see
http://www.idealx.org/prj/imc) and is now released as an autonomous
CPAN module.

=head1 AUTHORS

David Barth <dbarth@idealx.com>

Aurélien Degrémont <adegremont@idealx.com>

Gérald Macinenti <gmacinenti@idealx.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 - dbarth@idealx.com

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


