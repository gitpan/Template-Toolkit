#============================================================= -*-Perl-*-
#
# Template::Debug
#
# DESCRIPTION
#   Module defining various debug functions and methods to extend other 
#   Template::* modules.
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
# $Id: Debug.pm,v 1.2 1999/07/28 11:33:01 abw Exp $
#
#============================================================================
 
package Template::Debug;

require 5.004;

use strict;
use vars qw( $VERSION $DEBUG );
use Template::Constants qw( :debug );

$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);
$DEBUG = 0;



#========================================================================
#                      -----  CONFIGURATION -----
#========================================================================



#========================================================================
#                  -----  Template::Directive  -----
#========================================================================
 
package Template::Directive;

use vars qw( $PAD @TYPENAME );
$PAD = '    ';
@TYPENAME = qw( LITERAL IDENT VARREF VARLIST VARHASH QUOTED DIR );



#------------------------------------------------------------------------
# _inspect()
#
# Dumps the directive tree starting from the $self node.
#------------------------------------------------------------------------   

{
    local $^W = 0;
    eval 'sub _inspect { print STDERR $_[0]->_inspect_node(); }'
}


sub _inspect_node {
    my $self   = shift;
    my $indent = shift || 0;
    my $pad    = ' ' x $indent;
    my $type   = $self->{ TYPE };
    
    return "$pad$type\n";
}


sub _inspect_value {
    my $self   = shift;
    my $value  = shift;
    my $indent = shift || 0;
    my $pad    = ' ' x $indent;

    unless (ref($value) eq 'ARRAY') {
	my ($file, $pack, $line) = caller;
	use Carp;
	confess("_inspect_value() called with non-array ref from ",
	      "$file ($pack) line $line\n");
    }
    my ($data, $type, $params) = @$value;

    my $output = "$data ($TYPENAME[ $type ])";

    $output .= "  (\n"
	    .  $self->_inspect_list($params, $indent + 4) 
	    .  $pad
	    . ")"
	if defined $params;

    if ($type == Template::Constants::EXPAND_VARHASH) {
	$output .= "  {\n"
	    .  $self->_inspect_params($data, $indent + 4) 
	    .  $pad
	    . "}";
    }
    elsif ($type == Template::Constants::EXPAND_VARLIST) {
	$output .= "  [\n"
	    .  $self->_inspect_list($data, $indent + 4) 
	    .  $pad
	    . "]";
    }
 
    $output .= "\n";
    $output;
}
    

sub _inspect_params {
    my $self   = shift;
    my $params = shift;
    my $indent = shift || 0;
    my $pad    = ' ' x $indent;
    my $output = '';
    my ($prm, $key, $value, $line);

    foreach $prm (@$params) {
	($key, $value) = @$prm;
	$line = $pad . $key . ' => ';
	$indent = length $line;
	$output .= $line . $self->_inspect_value($value, $indent);
    }
    $output;
}


sub _inspect_list {
    my $self   = shift;
    my $list   = shift;
    my $indent = shift || 0;
    my $pad    = ' ' x $indent;

    return $pad . 
	join($pad, 
	     map { $self->_inspect_value($_, $indent) } 
		@$list
	     );
	
}



#========================================================================
#                -----  Template::Directive::*  -----
#========================================================================

package Template::Directive::Get;

sub _inspect_node {
    my $self   = shift;
    my $indent = shift || 0;
    my $pad    = ' ' x $indent;
    return "${pad}GET     " 
	. $self->_inspect_value($self->{ IDENT }, $indent + 8);
}


package Template::Directive::Set;

sub _inspect_node {
    my $self   = shift;
    my $indent = shift || 0;
    my $pad    = ' ' x $indent;
    return "${pad}SET\n" 
	. $self->_inspect_params($self->{ PARAMS }, $indent + 8);
}

package Template::Directive::Include;

sub _inspect_node {
    my $self   = shift;
    my $indent = shift || 0;
    my $pad    = ' ' x $indent;
    return "${pad}INCLUDE "
	. $self->_inspect_value($self->{ IDENT }, $indent + 8)
	. $self->_inspect_params($self->{ PARAMS }, $indent + 8);
}

package Template::Directive::For;

sub _inspect_node {
    my $self    = shift;
    my $indent  = shift || 0;
    my $pad     = ' ' x $indent;
    my $varname = $self->{ VARNAME } || '<none>';
    my $list    = $self->{ LIST };

    return "${pad}FOR     $varname in "
	. $self->_inspect_value($list, $indent + 8)
	. $self->{ BLOCK }->_inspect_node($indent + 8);
}

package Template::Directive::If;

sub _inspect_node {
    my $self    = shift;
    my $indent  = shift || 0;
    my $pad     = ' ' x $indent;
    my $block   = $self->{ BLOCK };
    my $else    = $self->{ ELSE  };

    my $text = "${pad}IF      (expr)\n"
	. $block->_inspect_node($indent + 8);

    $text .= "${pad}ELSE\n"
	  . $else->_inspect_node($indent + 8)
	      if $else;

    $text;
}


package Template::Directive::Text;

sub _inspect_node {
    my $self   = shift;
    my $indent = shift || 0;
    my $pad    = ' ' x $indent;
    my $text   = $self->{ TEXT };
    $text      = "" unless defined $text;

    foreach ($text) {
	s/\n/\\n/g;
    }

    substr($text, 24) = '...' . substr($text, -5)
	if length($text) > 32;

    return "${pad}TEXT    \"$text\"\n" 
}



package Template::Directive::Block;

sub _inspect_node {
    my $self   = shift;
    my $indent = shift || 0;
    my $pad    = ' ' x $indent;
    return "${pad}BLOCK\n" .
	join('', 
	     map { $_->_inspect_node($indent + 8) } 
		@{ $self->{ CONTENT } } 
	); 
}





1;
