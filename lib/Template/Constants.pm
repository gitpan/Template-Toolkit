#============================================================= -*-Perl-*-
#
# Template::Constants.pm
#
# DESCRIPTION
#   Definition of constants for the Template Toolkit.
#
# AUTHOR
#   Andy Wardley   <abw@cre.canon.co.uk>
#
# COPYRIGHT
#   Copyright (C) 1996-1999 Andy Wardley.  All Rights Reserved.
#   Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#----------------------------------------------------------------------------
#
# $Id: Constants.pm,v 1.8 1999/08/01 13:43:11 abw Exp $
#
#============================================================================
 
package Template::Constants;

require 5.004;
require Exporter;

use strict;
use vars qw( $VERSION @ISA @EXPORT_OK %EXPORT_TAGS );

@ISA     = qw( Exporter );
$VERSION = sprintf("%d.%02d", q$Revision: 1.8 $ =~ /(\d+)\.(\d+)/);

# BEGIN { print STDERR "Loading Template::Constants...\n" };


#========================================================================
#                         ----- EXPORTER -----
#========================================================================

# TEMPLATE constants for general use
use constant TEMPLATE_OUTPUT => 'OUTPUT';
use constant TEMPLATE_ERROR  => 'ERROR';
use constant TEMPLATE_DEBUG  => 'DEBUG';

# STATUS constants returned by directives
use constant STATUS_OK       =>   0;      # ok
use constant STATUS_RETURN   =>   1;      # ok, block ended by RETURN
use constant STATUS_STOP     =>   2;      # ok, stoppped by STOP 
use constant STATUS_DONE     =>   3;      # ok, iterator done
use constant STATUS_ERROR    => 255;      # error condition

# ERROR constants for indicating soft errors.
use constant ERROR_FILE      =>  'file';  # file error: I/O, parse, recursion
use constant ERROR_UNDEF     =>  'undef'; # undefined variable value used

use constant OP_ROOT         =>   1;
use constant OP_DOT          =>   2;
use constant OP_LDOT         =>   3;
use constant OP_DUP          =>   4;
use constant OP_CAT          =>   5;
use constant OP_PUSH         =>   6;
use constant OP_POP          =>   7;
use constant OP_NOT          =>   8;
use constant OP_ASSIGN       =>   9;
use constant OP_BINOP        =>  10;
use constant OP_LIST         =>  11;
use constant OP_DEFAULT      =>  12;
use constant OP_AND          =>  13;
use constant OP_OR           =>  14;
use constant OP_ITER         =>  15;
use constant OP_TOLERANT     =>  16;

use vars qw( @OP_NAME );
@OP_NAME       = qw( NULLOP ROOT DOT LDOT DUP CAT PUSH
		     POP NOT ASSIGN BINOP LIST DEFAULT
		     AND OR ITERATOR TOLERANT );

# CACHE constants controlling the Template::Cache
use constant CACHE_NONE      =>   0;	  # don't cache anything
use constant CACHE_ALL       =>   1;      # cache everything

# DEBUG constants
use constant DEBUG_NONE      =>   0;
use constant DEBUG_INFO      =>   1;
use constant DEBUG_DATA      =>   2;
use constant DEBUG_TOKEN     =>   4;
use constant DEBUG_PARSE     =>   8;
use constant DEBUG_PROCESS   =>  16;
use constant DEBUG_ALL       => DEBUG_INFO | DEBUG_DATA | DEBUG_TOKEN | 
                                DEBUG_PARSE | DEBUG_PROCESS;

# Exporter tags
my @TEMPLATE = qw( TEMPLATE_OUTPUT TEMPLATE_ERROR TEMPLATE_DEBUG );
my @STATUS   = qw( STATUS_OK STATUS_RETURN STATUS_STOP STATUS_DONE
		   STATUS_ERROR );
my @ERROR    = qw( ERROR_FILE ERROR_UNDEF );
my @OPS      = qw( OP_ROOT OP_DOT OP_DUP OP_CAT OP_PUSH OP_POP OP_ASSIGN
		   OP_BINOP OP_NOT OP_LDOT OP_LIST OP_DEFAULT OP_AND
		   OP_OR OP_ITER OP_TOLERANT @OP_NAME );
my @CACHE    = qw( CACHE_NONE CACHE_ALL );
my @DEBUG    = qw( DEBUG_NONE DEBUG_INFO DEBUG_DATA DEBUG_TOKEN 
                   DEBUG_PARSE DEBUG_PROCESS DEBUG_ALL );


@EXPORT_OK   = ( @TEMPLATE, @STATUS, @ERROR, @OPS, @CACHE, @DEBUG );
%EXPORT_TAGS = (
    'all'      => [ @EXPORT_OK ],
    'template' => [ @TEMPLATE  ],
    'status'   => [ @STATUS    ],
    'error'    => [ @ERROR     ],
    'ops'      => [ @OPS       ],
    'cache'    => [ @CACHE     ],
    'debug'    => [ @DEBUG     ],
);


1;

__END__



=head1 NAME

Template::Constants - Defines constants for the Template Toolkit

=head1 SYNOPSIS

    use Template::Constants qw( :template :status :error :ops
                                :cache :debug :all );

=head1 DESCRIPTION

The Template::Constants modules defines, and optionally exports into the
caller's namespace, a number of constants used by the Template package.

Constants may be used by specifying the Template::Constants package 
explicitly:

    use Template;
    use Template::Constants;

    my $template = Template->new({ 
	DEBUG => Template::Constants::DEBUG_ALL 
    });

Constants may be imported into the caller's namespace by naming them as 
options to the C<use Template::Constants> statement:

    use Template::Constants qw( DEBUG_ALL );

Alternatively, one of the following tagset identifiers may be specified
(prefixed by ':') to import sets of constants; reset, notify, expand, debug.

    use Template;
    use Template::Constants qw( :debug );

    my $template = Template->new({ 
	DEBUG => DEBUG_ALL 
    });

The Template module uses the Template::Constants module and delegates any
import specifications to it.  Thus, it is sufficient to C<use Template>
without requiring a further C<use Template::Constants>.

    use Template qw( :error :debug );

    my $template = Template->new({ 
	DEBUG => DEBUG_ALL 
    });

See L<Exporter> for more information on exporting variables.

=head1 EXPORTABLE TAG SETS

The following tag sets and associated constants are defined: 

  :template    General purpose Template control parameters.
    TEMPLATE_OUTPUT           # indicates output "stream"
    TEMPLATE_ERROR            # indicates error "stream"

  :status      Status codes, returned by toolkit and user code
    STATUS_OK                 # no problem, continue
    STATUS_RETURN             # ended current block then continue (ok)
    STATUS_STOP               # controlled stop (ok) 
    STATUS_DONE               # iterator is all done (ok)
    STATUS_ERROR              # general error condition (not ok)

  :error       Error (exception) types thrown by toolkit
    ERROR_FILE                # file missing or parse error
    ERROR_UNDEF               # undefined variables

  :ops         Fundamental 'opcodes' of context runtime.
    (see Context::_runop() for details)

  :all         All the above constants.

=head1 AUTHOR

Andy Wardley E<lt>abw@cre.canon.co.ukE<gt>

=head1 REVISION

$Revision: 1.8 $

=head1 COPYRIGHT

Copyright (C) 1996-1999 Andy Wardley.  All Rights Reserved.
Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template>, L<Exporter>

=cut


