#============================================================= -*-perl-*-
#
# Template::Config
#
# DESCRIPTION
#   Template Toolkit configuration module.
#
# AUTHOR
#   Andy Wardley   <abw@kfs.org>
#
# COPYRIGHT
#   Copyright (C) 1996-2000 Andy Wardley.  All Rights Reserved.
#   Copyright (C) 1998-2000 Canon Research Centre Europe Ltd.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#------------------------------------------------------------------------
#
#   $Id: Config.pm,v 2.47 2002/04/17 14:04:37 abw Exp $
#
#========================================================================
 
package Template::Config;

require 5.004;

use strict;
use base qw( Template::Base );
use vars qw( $VERSION $DEBUG $ERROR $INSTDIR
	     $PARSER $PROVIDER $PLUGINS $FILTERS $ITERATOR 
             $LATEX_PATH $PDFLATEX_PATH $DVIPS_PATH
	     $STASH $SERVICE $CONTEXT );

$VERSION  = sprintf("%d.%02d", q$Revision: 2.47 $ =~ /(\d+)\.(\d+)/);
$DEBUG    = 0 unless defined $DEBUG;
$ERROR    = '';
$CONTEXT  = 'Template::Context';
$FILTERS  = 'Template::Filters';
$ITERATOR = 'Template::Iterator';
$PARSER   = 'Template::Parser';
$PLUGINS  = 'Template::Plugins';
$PROVIDER = 'Template::Provider';
$SERVICE  = 'Template::Service';
$STASH    = 'Template::Stash';

# the following is set at installation time by the Makefile.PL 
$INSTDIR  = '';

# LaTeX executable paths set at installation time by the Makefile.PL
# Empty strings cause the latex(pdf|dvi|ps) filters to throw an error.
$LATEX_PATH    = '';
$PDFLATEX_PATH = '';
$DVIPS_PATH    = '';

#========================================================================
#                       --- CLASS METHODS ---
#========================================================================

#------------------------------------------------------------------------
# load($module)
#
# Load a module via require().  Any occurences of '::' in the module name
# are be converted to '/' and '.pm' is appended.  Returns 1 on success
# or undef on error.  Use $class->error() to examine the error string.
#------------------------------------------------------------------------

sub load {
    my ($class, $module) = @_;
    $module =~ s[::][/]g;
    $module .= '.pm';
#    print STDERR "loading $module\n"
#	if $DEBUG;
    eval {
	require $module;
    };
    return $@ ? $class->error("failed to load $module: $@") : 1;
}


#------------------------------------------------------------------------
# parser(\%params)
#
# Instantiate a new parser object of the class whose name is denoted by
# the package variable $PARSER (default: Template::Parser).  Returns
# a reference to a newly instantiated parser object or undef on error.
# The class error() method can be called without arguments to examine
# the error message generated by this failure.
#------------------------------------------------------------------------

sub parser {
    my $class  = shift;
    my $params = defined($_[0]) && UNIVERSAL::isa($_[0], 'HASH')
	       ? shift : { @_ };

    return undef unless $class->load($PARSER);
    return $PARSER->new($params) 
	|| $class->error("failed to create parser: ", $PARSER->error);
}


#------------------------------------------------------------------------
# provider(\%params)
#
# Instantiate a new template provider object (default: Template::Provider).
# Returns an object reference or undef on error, as above.
#------------------------------------------------------------------------

sub provider {
    my $class  = shift;
    my $params = defined($_[0]) && UNIVERSAL::isa($_[0], 'HASH') 
	       ? shift : { @_ };

    return undef unless $class->load($PROVIDER);
    return $PROVIDER->new($params) 
	|| $class->error("failed to create template provider: ",
			 $PROVIDER->error);
}


#------------------------------------------------------------------------
# plugins(\%params)
#
# Instantiate a new plugins provider object (default: Template::Plugins).
# Returns an object reference or undef on error, as above.
#------------------------------------------------------------------------

sub plugins {
    my $class  = shift;
    my $params = defined($_[0]) && UNIVERSAL::isa($_[0], 'HASH') 
	       ? shift : { @_ };

    return undef unless $class->load($PLUGINS);
    return $PLUGINS->new($params)
	|| $class->error("failed to create plugin provider: ",
			 $PLUGINS->error);
}


#------------------------------------------------------------------------
# filters(\%params)
#
# Instantiate a new filters provider object (default: Template::Filters).
# Returns an object reference or undef on error, as above.
#------------------------------------------------------------------------

sub filters {
    my $class  = shift;
    my $params = defined($_[0]) && UNIVERSAL::isa($_[0], 'HASH') 
	       ? shift : { @_ };

    return undef unless $class->load($FILTERS);
    return $FILTERS->new($params)
	|| $class->error("failed to create filter provider: ",
			 $FILTERS->error);
}


#------------------------------------------------------------------------
# iterator(\@list)
#
# Instantiate a new Template::Iterator object (default: Template::Iterator).
# Returns an object reference or undef on error, as above.
#------------------------------------------------------------------------

sub iterator {
    my $class = shift;
    my $list  = shift;

    return undef unless $class->load($ITERATOR);
    return $ITERATOR->new($list, @_)
	|| $class->error("failed to create iterator: ", $ITERATOR->error);
}


#------------------------------------------------------------------------
# stash(\%vars)
#
# Instantiate a new template variable stash object (default: 
# Template::Stash). Returns object or undef, as above.
#------------------------------------------------------------------------

sub stash {
    my $class  = shift;
    my $params = defined($_[0]) && UNIVERSAL::isa($_[0], 'HASH') 
	       ? shift : { @_ };

    return undef unless $class->load($STASH);
    return $STASH->new($params) 
	|| $class->error("failed to create stash: ", $STASH->error);
}


#------------------------------------------------------------------------
# context(\%params)
#
# Instantiate a new template context object (default: Template::Context). 
# Returns object or undef, as above.
#------------------------------------------------------------------------

sub context {
    my $class  = shift;
    my $params = defined($_[0]) && UNIVERSAL::isa($_[0], 'HASH') 
	       ? shift : { @_ };

    return undef unless $class->load($CONTEXT);
    return $CONTEXT->new($params) 
	|| $class->error("failed to create context: ", $CONTEXT->error);
}

#------------------------------------------------------------------------
# service(\%params)
#
# Instantiate a new template context object (default: Template::Service). 
# Returns object or undef, as above.
#------------------------------------------------------------------------

sub service {
    my $class  = shift;
    my $params = defined($_[0]) && UNIVERSAL::isa($_[0], 'HASH') 
	       ? shift : { @_ };

    return undef unless $class->load($SERVICE);
    return $SERVICE->new($params) 
	|| $class->error("failed to create context: ", $SERVICE->error);
}


#------------------------------------------------------------------------
# instdir($dir)
#
# Returns the root installation directory appended with any local 
# component directory passed as an argument.
#------------------------------------------------------------------------

sub instdir {
    my ($class, $dir) = @_;
    my $inst = $INSTDIR 
	|| return $class->error("no installation directory");
    $inst =~ s[/$][]g;
    $inst .= "/$dir" if $dir;
    return $inst;
}

#------------------------------------------------------------------------
# latexpaths()
#
# Returns a reference to a three element array:
#    [latex_path,  pdf2latex_path, dvips_path]
# These values are determined by Makefile.PL at installation time
# and are used by the latex(pdf|dvi|ps) filters.
#------------------------------------------------------------------------

sub latexpaths {
    return [$LATEX_PATH, $PDFLATEX_PATH, $DVIPS_PATH];
}

#========================================================================
# This should probably be moved somewhere else in the long term, but for
# now it ensures that Template::TieString is available even if the 
# Template::Directive module hasn't been loaded, as is the case when 
# using compiled templates and Template::Parser hasn't yet been loaded
# on demand.
#========================================================================

#------------------------------------------------------------------------
# simple package for tying $output variable to STDOUT, used by perl()
#------------------------------------------------------------------------

package Template::TieString;

sub TIEHANDLE {
    my ($class, $textref) = @_;
    bless $textref, $class;
}
sub PRINT {
    my $self = shift;
    $$self .= join('', @_);
}



1;

__END__


#------------------------------------------------------------------------
# IMPORTANT NOTE
#   This documentation is generated automatically from source
#   templates.  Any changes you make here may be lost.
# 
#   The 'docsrc' documentation source bundle is available for download
#   from http://www.template-toolkit.org/docs.html and contains all
#   the source templates, XML files, scripts, etc., from which the
#   documentation for the Template Toolkit is built.
#------------------------------------------------------------------------

=head1 NAME

Template::Config - Factory module for instantiating other TT2 modules

=head1 SYNOPSIS

    use Template::Config;

=head1 DESCRIPTION

This module implements various methods for loading and instantiating
other modules that comprise the Template Toolkit.  It provides a consistent
way to create toolkit components and allows custom modules to be used in 
place of the regular ones.

Package variables such as $STASH, $SERVICE, $CONTEXT, etc., contain
the default module/package name for each component (Template::Stash,
Template::Service and Template::Context, respectively) and are used by
the various factory methods (stash(), service() and context()) to load
the appropriate module.  Changing these package variables will cause
subsequent calls to the relevant factory method to load and instantiate
an object from the new class.

=head1 PUBLIC METHODS

=head2 load($module)

Load a module via require().  Any occurences of '::' in the module name
are be converted to '/' and '.pm' is appended.  Returns 1 on success
or undef on error.  Use $class-E<gt>error() to examine the error string.

=head2 parser(\%config)

Instantiate a new parser object of the class whose name is denoted by
the package variable $PARSER (default: Template::Parser).  Returns
a reference to a newly instantiated parser object or undef on error.

=head2 provider(\%config)

Instantiate a new template provider object (default: Template::Provider).
Returns an object reference or undef on error, as above.

=head2 plugins(\%config)

Instantiate a new plugins provider object (default: Template::Plugins).
Returns an object reference or undef on error, as above.

=head2 filters(\%config)

Instantiate a new filter provider object (default: Template::Filters).
Returns an object reference or undef on error, as above.

=head2 stash(\%vars)

Instantiate a new stash object (default: Template::Templates) using the 
contents of the optional hash array passed by parameter as initial variable
definitions.  Returns an object reference or undef on error, as above.

=head2 context(\%config)

Instantiate a new template context object (default: Template::Context).
Returns an object reference or undef on error, as above.

=head2 service(\%config)

Instantiate a new template service object (default: Template::Service).
Returns an object reference or undef on error, as above.

=head2 instdir($dir)

Returns the root directory of the Template Toolkit installation under
which optional components are installed.  Any relative directory specified
as an argument will be appended to the returned directory.

    # e.g. returns '/usr/local/tt2'
    my $ttroot = Template::Config->instdir()
	|| die "$Template::Config::ERROR\n";

    # e.g. returns '/usr/local/tt2/templates'
    my $template = Template::Config->instdir('templates')
	|| die "$Template::Config::ERROR\n";

Returns undef and sets $Template::Config::ERROR appropriately if the 
optional components of the Template Toolkit have not been installed.

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

L<http://www.andywardley.com/|http://www.andywardley.com/>




=head1 VERSION

2.47, distributed as part of the
Template Toolkit version 2.07, released on 17 April 2002.

=head1 COPYRIGHT

  Copyright (C) 1996-2002 Andy Wardley.  All Rights Reserved.
  Copyright (C) 1998-2002 Canon Research Centre Europe Ltd.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template|Template>