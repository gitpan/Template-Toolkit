#=========================================================================
#
# Template::Grammar
#
# DESCRIPTION
#   Perl 5 module defining the default grammar for Template::Parser.
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
#------------------------------------------------------------------------
#
# NOTE: this module is constructed from the parser/Grammar.pm.skel
# file by running the parser/yc script.  You only need to do this if 
# you have modified the grammar in the parser/Parser.yp file and need
# to-recompile it.  See the README in the 'parser' directory for more
# information (sub-directory of the Template distribution).
#
#------------------------------------------------------------------------
#
# $Id: Grammar.pm,v 1.33 1999/11/26 07:53:30 abw Exp $
#
#========================================================================

package Template::Grammar;

require 5.004;

use strict;
use vars qw( $VERSION );

use Template::Constants qw( :ops :status );

$VERSION = sprintf("%d.%02d", q$Revision: 1.33 $ =~ /(\d+)\.(\d+)/);

my (@RESERVED, $LEXTABLE, $RULES, $STATES);
my $factory;

sub new {
    my $class = shift;
    bless {
	LEXTABLE => $LEXTABLE,
	STATES   => $STATES,
	RULES    => $RULES,
    };
}

# update method to set package-scoped $factory lexical 
sub install_factory {
    my ($self, $new_factory) = @_;
    $factory = $new_factory;
}



#========================================================================
# Reserved Words
#========================================================================

@RESERVED = qw( 
	GET SET DEFAULT INCLUDE PROCESS 
	IF UNLESS ELSE ELSIF FOR WHILE USE FILTER 
	THROW CATCH ERROR RETURN STOP BREAK MACRO
	PERL BLOCK END TO STEP AND OR NOT
    );


#========================================================================
# Lexer Token Table
#========================================================================

# lookup table used by lexer is initialised with special-cases
$LEXTABLE = {
    'FOREACH' => 'FOR',
    '&&'      => 'AND',
    '||'      => 'OR',
    '!'       => 'NOT',
    '.'       => 'DOT',
    '..'      => 'TO',
    '='       => 'ASSIGN',
    '=>'      => 'ASSIGN',
    ','       => 'COMMA',
    'and'     => 'AND',		# explicitly specified so that qw( and or
    'or'      => 'OR',		# not ) can always be used in lower case, 
    'not'     => 'NOT'		# regardless of CASE sensitivity flag
};

# localise the temporary variables needed to complete lexer table
{ 
    my @tokens   = qw< ( ) [ ] { } ${ $ / ; >;
    my @compop   = qw( == != < <= >= > );
    my @binop    = qw( + - * DIV MOD );

    # fill lexer table, slice by slice, with reserved words and operators
    @$LEXTABLE{ @RESERVED, @compop, @binop, @tokens } 
	= ( @RESERVED, ('COMPOP') x @compop, ('BINOP') x @binop, @tokens );
}


#========================================================================
# States
#========================================================================

$STATES = [
	{#State 0
		ACTIONS => {
			'RETURN' => 24,
			'GET' => 1,
			'CATCH' => 25,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'FILTER' => 28,
			'STOP' => 7,
			'DEBUG' => 29,
			'FOR' => 8,
			";" => -15,
			"{" => 30,
			"[" => 12,
			'ERROR' => 31,
			'BLOCK' => 13,
			'SET' => 14,
			'LITERAL' => 35,
			"\${" => 34,
			'USE' => 15,
			'IF' => 37,
			"\"" => 38,
			"\$" => 40,
			'MACRO' => 16,
			'PERL' => 43,
			'THROW' => 45,
			'IDENT' => 44,
			'WHILE' => 47,
			'UNLESS' => 19,
			'PROCESS' => 22
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 23,
			'catch' => 2,
			'assign' => 26,
			'filter' => 27,
			'condition' => 10,
			'debug' => 9,
			'setlist' => 11,
			'block' => 32,
			'chunks' => 33,
			'item' => 36,
			'atomdir' => 39,
			'macro' => 41,
			'perl' => 42,
			'ident' => 17,
			'term' => 46,
			'chunk' => 18,
			'defblock' => 21,
			'loop' => 20,
			'directive' => 48
		}
	},
	{#State 1
		ACTIONS => {
			"\"" => 38,
			"{" => 30,
			"[" => 12,
			"\$" => 40,
			'IDENT' => 44,
			'LITERAL' => 50,
			"\${" => 34
		},
		GOTOS => {
			'term' => 51,
			'ident' => 49,
			'item' => 36
		}
	},
	{#State 2
		DEFAULT => -8
	},
	{#State 3
		ACTIONS => {
			"\"" => 56,
			"\$" => 57,
			'IDENT' => 58,
			'LITERAL' => 55,
			"/" => 53
		},
		GOTOS => {
			'file' => 54,
			'textdot' => 52
		}
	},
	{#State 4
		DEFAULT => -30
	},
	{#State 5
		ACTIONS => {
			"\$" => 40,
			'IDENT' => 44,
			"\${" => 34,
			'LITERAL' => 61
		},
		GOTOS => {
			'setlist' => 59,
			'ident' => 60,
			'assign' => 26,
			'item' => 36
		}
	},
	{#State 6
		DEFAULT => -5
	},
	{#State 7
		DEFAULT => -29
	},
	{#State 8
		ACTIONS => {
			"\"" => 38,
			"{" => 30,
			"[" => 12,
			"\$" => 40,
			'IDENT' => 63,
			'LITERAL' => 50,
			"\${" => 34
		},
		GOTOS => {
			'term' => 64,
			'loopvar' => 62,
			'ident' => 49,
			'item' => 36
		}
	},
	{#State 9
		DEFAULT => -14
	},
	{#State 10
		DEFAULT => -9
	},
	{#State 11
		ACTIONS => {
			"\$" => 40,
			'IDENT' => 44,
			'LITERAL' => 61,
			"\${" => 34,
			'COMMA' => 66
		},
		DEFAULT => -25,
		GOTOS => {
			'ident' => 60,
			'assign' => 65,
			'item' => 36
		}
	},
	{#State 12
		ACTIONS => {
			"\"" => 38,
			"{" => 30,
			"[" => 12,
			"\$" => 40,
			'IDENT' => 44,
			'LITERAL' => 50,
			"\${" => 34
		},
		GOTOS => {
			'term' => 69,
			'list' => 68,
			'ident' => 49,
			'range' => 67,
			'item' => 36
		}
	},
	{#State 13
		ACTIONS => {
			";" => 71,
			'IDENT' => 58
		},
		GOTOS => {
			'textdot' => 70
		}
	},
	{#State 14
		ACTIONS => {
			"\$" => 40,
			'IDENT' => 44,
			"\${" => 34,
			'LITERAL' => 61
		},
		GOTOS => {
			'setlist' => 72,
			'ident' => 60,
			'assign' => 26,
			'item' => 36
		}
	},
	{#State 15
		ACTIONS => {
			'IDENT' => 75
		},
		GOTOS => {
			'textdot' => 73,
			'useparam' => 74
		}
	},
	{#State 16
		ACTIONS => {
			'IDENT' => 76
		}
	},
	{#State 17
		ACTIONS => {
			'ASSIGN' => 78,
			'DOT' => 77
		},
		DEFAULT => -55
	},
	{#State 18
		DEFAULT => -4
	},
	{#State 19
		ACTIONS => {
			"\"" => 38,
			'NOT' => 79,
			"\$" => 40,
			'IDENT' => 44,
			"(" => 82,
			"[" => 12,
			"{" => 30,
			"\${" => 34,
			'LITERAL' => 35
		},
		GOTOS => {
			'term' => 83,
			'ident' => 17,
			'assign' => 81,
			'item' => 36,
			'expr' => 80
		}
	},
	{#State 20
		DEFAULT => -10
	},
	{#State 21
		DEFAULT => -11
	},
	{#State 22
		ACTIONS => {
			"\"" => 56,
			"\$" => 57,
			'IDENT' => 58,
			'LITERAL' => 55,
			"/" => 53
		},
		GOTOS => {
			'file' => 84,
			'textdot' => 52
		}
	},
	{#State 23
		DEFAULT => -24
	},
	{#State 24
		DEFAULT => -28
	},
	{#State 25
		ACTIONS => {
			";" => 86,
			'IDENT' => 58
		},
		GOTOS => {
			'textdot' => 85
		}
	},
	{#State 26
		DEFAULT => -76
	},
	{#State 27
		DEFAULT => -27
	},
	{#State 28
		ACTIONS => {
			'IDENT' => 75
		},
		GOTOS => {
			'textdot' => 73,
			'useparam' => 87
		}
	},
	{#State 29
		ACTIONS => {
			'TEXT' => 88
		}
	},
	{#State 30
		ACTIONS => {
			'IDENT' => 93,
			'LITERAL' => 92
		},
		DEFAULT => -86,
		GOTOS => {
			'param' => 89,
			'params' => 90,
			'paramlist' => 91
		}
	},
	{#State 31
		ACTIONS => {
			"\"" => 38,
			"{" => 30,
			"[" => 12,
			"\$" => 40,
			'IDENT' => 44,
			'LITERAL' => 50,
			"\${" => 34
		},
		GOTOS => {
			'term' => 94,
			'ident' => 49,
			'item' => 36
		}
	},
	{#State 32
		ACTIONS => {
			'' => 95
		}
	},
	{#State 33
		ACTIONS => {
			'GET' => 1,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'STOP' => 7,
			'FOR' => 8,
			"[" => 12,
			'BLOCK' => 13,
			'SET' => 14,
			'USE' => 15,
			'MACRO' => 16,
			'UNLESS' => 19,
			'PROCESS' => 22,
			'RETURN' => 24,
			'CATCH' => 25,
			'FILTER' => 28,
			'DEBUG' => 29,
			";" => -15,
			"{" => 30,
			'ERROR' => 31,
			"\${" => 34,
			'LITERAL' => 35,
			'IF' => 37,
			"\"" => 38,
			"\$" => 40,
			'PERL' => 43,
			'IDENT' => 44,
			'THROW' => 45,
			'WHILE' => 47
		},
		DEFAULT => -1,
		GOTOS => {
			'atomdir' => 39,
			'return' => 23,
			'macro' => 41,
			'perl' => 42,
			'catch' => 2,
			'ident' => 17,
			'assign' => 26,
			'filter' => 27,
			'condition' => 10,
			'debug' => 9,
			'term' => 46,
			'setlist' => 11,
			'chunk' => 96,
			'defblock' => 21,
			'loop' => 20,
			'directive' => 48,
			'item' => 36
		}
	},
	{#State 34
		ACTIONS => {
			"\"" => 38,
			"{" => 30,
			"[" => 12,
			"\$" => 40,
			'IDENT' => 44,
			'LITERAL' => 50,
			"\${" => 34
		},
		GOTOS => {
			'term' => 97,
			'ident' => 49,
			'item' => 36
		}
	},
	{#State 35
		ACTIONS => {
			'ASSIGN' => 98
		},
		DEFAULT => -54
	},
	{#State 36
		DEFAULT => -64
	},
	{#State 37
		ACTIONS => {
			"\"" => 38,
			'NOT' => 79,
			"\$" => 40,
			'IDENT' => 44,
			"(" => 82,
			"[" => 12,
			"{" => 30,
			"\${" => 34,
			'LITERAL' => 35
		},
		GOTOS => {
			'term' => 83,
			'ident' => 17,
			'assign' => 81,
			'item' => 36,
			'expr' => 99
		}
	},
	{#State 38
		DEFAULT => -117,
		GOTOS => {
			'quoted' => 100
		}
	},
	{#State 39
		ACTIONS => {
			'WHILE' => 105,
			'UNLESS' => 102,
			'FILTER' => 103,
			'IF' => 104,
			'FOR' => 101
		},
		DEFAULT => -7
	},
	{#State 40
		ACTIONS => {
			'IDENT' => 44,
			"\${" => 34
		},
		GOTOS => {
			'item' => 106
		}
	},
	{#State 41
		DEFAULT => -13
	},
	{#State 42
		DEFAULT => -12
	},
	{#State 43
		ACTIONS => {
			";" => 107
		}
	},
	{#State 44
		ACTIONS => {
			"(" => 108
		},
		DEFAULT => -68
	},
	{#State 45
		ACTIONS => {
			'IDENT' => 58
		},
		GOTOS => {
			'textdot' => 109
		}
	},
	{#State 46
		ACTIONS => {
			'BINOP' => 110
		},
		DEFAULT => -26
	},
	{#State 47
		ACTIONS => {
			"\"" => 38,
			'NOT' => 79,
			"\$" => 40,
			'IDENT' => 44,
			"(" => 82,
			"[" => 12,
			"{" => 30,
			"\${" => 34,
			'LITERAL' => 35
		},
		GOTOS => {
			'term' => 83,
			'ident' => 17,
			'assign' => 81,
			'item' => 36,
			'expr' => 111
		}
	},
	{#State 48
		ACTIONS => {
			";" => 112
		}
	},
	{#State 49
		ACTIONS => {
			'DOT' => 77
		},
		DEFAULT => -55
	},
	{#State 50
		DEFAULT => -54
	},
	{#State 51
		ACTIONS => {
			'BINOP' => 110
		},
		DEFAULT => -16
	},
	{#State 52
		ACTIONS => {
			'DOT' => 113,
			"/" => 114
		},
		DEFAULT => -107
	},
	{#State 53
		ACTIONS => {
			'IDENT' => 58
		},
		GOTOS => {
			'textdot' => 115
		}
	},
	{#State 54
		ACTIONS => {
			"\$" => 40,
			'IDENT' => 44,
			'LITERAL' => 61,
			"\${" => 34
		},
		DEFAULT => -78,
		GOTOS => {
			'setlist' => 116,
			'ident' => 60,
			'assign' => 26,
			'setopt' => 117,
			'item' => 36
		}
	},
	{#State 55
		DEFAULT => -108
	},
	{#State 56
		DEFAULT => -117,
		GOTOS => {
			'quoted' => 118
		}
	},
	{#State 57
		ACTIONS => {
			"\$" => 40,
			'IDENT' => 44,
			"\${" => 34
		},
		GOTOS => {
			'ident' => 119,
			'item' => 36
		}
	},
	{#State 58
		DEFAULT => -111
	},
	{#State 59
		ACTIONS => {
			"\$" => 40,
			'IDENT' => 44,
			'LITERAL' => 61,
			"\${" => 34,
			'COMMA' => 66
		},
		DEFAULT => -18,
		GOTOS => {
			'ident' => 60,
			'assign' => 65,
			'item' => 36
		}
	},
	{#State 60
		ACTIONS => {
			'ASSIGN' => 78,
			'DOT' => 77
		}
	},
	{#State 61
		ACTIONS => {
			'ASSIGN' => 98
		}
	},
	{#State 62
		ACTIONS => {
			";" => 120
		}
	},
	{#State 63
		ACTIONS => {
			'ASSIGN' => 121,
			"(" => 108
		},
		DEFAULT => -68
	},
	{#State 64
		ACTIONS => {
			'BINOP' => 110
		},
		DEFAULT => -45
	},
	{#State 65
		DEFAULT => -74
	},
	{#State 66
		DEFAULT => -75
	},
	{#State 67
		ACTIONS => {
			"]" => 122
		}
	},
	{#State 68
		ACTIONS => {
			"\"" => 38,
			"\$" => 40,
			'IDENT' => 44,
			"[" => 12,
			"{" => 30,
			"]" => 123,
			"\${" => 34,
			'LITERAL' => 50,
			'COMMA' => 124
		},
		GOTOS => {
			'term' => 125,
			'ident' => 49,
			'item' => 36
		}
	},
	{#State 69
		ACTIONS => {
			'TO' => 126,
			'BINOP' => 110
		},
		DEFAULT => -73
	},
	{#State 70
		ACTIONS => {
			";" => 127,
			"/" => 114,
			'DOT' => 113
		}
	},
	{#State 71
		ACTIONS => {
			'RETURN' => 24,
			'GET' => 1,
			'CATCH' => 25,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'FILTER' => 28,
			'STOP' => 7,
			'DEBUG' => 29,
			'FOR' => 8,
			";" => -15,
			"{" => 30,
			"[" => 12,
			'ERROR' => 31,
			'BLOCK' => 13,
			'SET' => 14,
			'LITERAL' => 35,
			"\${" => 34,
			'USE' => 15,
			'IF' => 37,
			"\"" => 38,
			"\$" => 40,
			'MACRO' => 16,
			'PERL' => 43,
			'THROW' => 45,
			'IDENT' => 44,
			'WHILE' => 47,
			'UNLESS' => 19,
			'PROCESS' => 22
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 23,
			'catch' => 2,
			'assign' => 26,
			'filter' => 27,
			'condition' => 10,
			'debug' => 9,
			'setlist' => 11,
			'block' => 128,
			'chunks' => 33,
			'item' => 36,
			'atomdir' => 39,
			'macro' => 41,
			'perl' => 42,
			'ident' => 17,
			'term' => 46,
			'chunk' => 18,
			'loop' => 20,
			'defblock' => 21,
			'directive' => 48
		}
	},
	{#State 72
		ACTIONS => {
			"\$" => 40,
			'IDENT' => 44,
			'LITERAL' => 61,
			"\${" => 34,
			'COMMA' => 66
		},
		DEFAULT => -17,
		GOTOS => {
			'ident' => 60,
			'assign' => 65,
			'item' => 36
		}
	},
	{#State 73
		ACTIONS => {
			"(" => 129,
			'DOT' => 113,
			"/" => 114
		},
		DEFAULT => -115
	},
	{#State 74
		DEFAULT => -19
	},
	{#State 75
		ACTIONS => {
			'ASSIGN' => 130
		},
		DEFAULT => -111
	},
	{#State 76
		ACTIONS => {
			'RETURN' => 24,
			'GET' => 1,
			'CATCH' => 25,
			'INCLUDE' => 3,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'FILTER' => 28,
			'STOP' => 7,
			'DEBUG' => 29,
			'FOR' => 8,
			"{" => 30,
			"[" => 12,
			'ERROR' => 31,
			'BLOCK' => 13,
			'SET' => 14,
			'LITERAL' => 35,
			"\${" => 34,
			'USE' => 15,
			'IF' => 37,
			"\"" => 38,
			"\$" => 40,
			'MACRO' => 16,
			'PERL' => 43,
			'THROW' => 45,
			'IDENT' => 44,
			"(" => 131,
			'WHILE' => 47,
			'UNLESS' => 19,
			'PROCESS' => 22
		},
		DEFAULT => -15,
		GOTOS => {
			'atomdir' => 39,
			'return' => 23,
			'macro' => 41,
			'perl' => 42,
			'catch' => 2,
			'ident' => 17,
			'assign' => 26,
			'filter' => 27,
			'condition' => 10,
			'debug' => 9,
			'term' => 46,
			'setlist' => 11,
			'defblock' => 21,
			'loop' => 20,
			'directive' => 132,
			'item' => 36
		}
	},
	{#State 77
		ACTIONS => {
			'IDENT' => 44,
			'LITERAL' => 133,
			"\${" => 34
		},
		GOTOS => {
			'item' => 134
		}
	},
	{#State 78
		ACTIONS => {
			"\"" => 38,
			"{" => 30,
			"[" => 12,
			"\$" => 40,
			'IDENT' => 44,
			'LITERAL' => 50,
			"\${" => 34
		},
		GOTOS => {
			'term' => 135,
			'ident' => 49,
			'item' => 36
		}
	},
	{#State 79
		ACTIONS => {
			"\"" => 38,
			'NOT' => 79,
			"\$" => 40,
			'IDENT' => 44,
			"(" => 82,
			"[" => 12,
			"{" => 30,
			"\${" => 34,
			'LITERAL' => 35
		},
		GOTOS => {
			'term' => 83,
			'ident' => 17,
			'assign' => 81,
			'item' => 36,
			'expr' => 136
		}
	},
	{#State 80
		ACTIONS => {
			";" => 139,
			'OR' => 137,
			'AND' => 138,
			'COMPOP' => 140
		}
	},
	{#State 81
		DEFAULT => -102
	},
	{#State 82
		ACTIONS => {
			"\"" => 38,
			'NOT' => 79,
			"\$" => 40,
			'IDENT' => 44,
			"(" => 82,
			"[" => 12,
			"{" => 30,
			"\${" => 34,
			'LITERAL' => 35
		},
		GOTOS => {
			'term' => 83,
			'ident' => 17,
			'assign' => 81,
			'item' => 36,
			'expr' => 141
		}
	},
	{#State 83
		ACTIONS => {
			'BINOP' => 110
		},
		DEFAULT => -103
	},
	{#State 84
		ACTIONS => {
			"\$" => 40,
			'IDENT' => 44,
			'LITERAL' => 61,
			"\${" => 34
		},
		DEFAULT => -78,
		GOTOS => {
			'setlist' => 116,
			'ident' => 60,
			'assign' => 26,
			'setopt' => 142,
			'item' => 36
		}
	},
	{#State 85
		ACTIONS => {
			";" => 143,
			"/" => 114,
			'DOT' => 113
		}
	},
	{#State 86
		ACTIONS => {
			'RETURN' => 24,
			'GET' => 1,
			'CATCH' => 25,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'FILTER' => 28,
			'STOP' => 7,
			'DEBUG' => 29,
			'FOR' => 8,
			";" => -15,
			"{" => 30,
			"[" => 12,
			'ERROR' => 31,
			'BLOCK' => 13,
			'SET' => 14,
			'LITERAL' => 35,
			"\${" => 34,
			'USE' => 15,
			'IF' => 37,
			"\"" => 38,
			"\$" => 40,
			'MACRO' => 16,
			'PERL' => 43,
			'THROW' => 45,
			'IDENT' => 44,
			'WHILE' => 47,
			'UNLESS' => 19,
			'PROCESS' => 22
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 23,
			'catch' => 2,
			'assign' => 26,
			'filter' => 27,
			'condition' => 10,
			'debug' => 9,
			'setlist' => 11,
			'block' => 144,
			'chunks' => 33,
			'item' => 36,
			'atomdir' => 39,
			'macro' => 41,
			'perl' => 42,
			'ident' => 17,
			'term' => 46,
			'chunk' => 18,
			'loop' => 20,
			'defblock' => 21,
			'directive' => 48
		}
	},
	{#State 87
		ACTIONS => {
			";" => 145
		}
	},
	{#State 88
		DEFAULT => -53
	},
	{#State 89
		DEFAULT => -84
	},
	{#State 90
		ACTIONS => {
			"}" => 146
		}
	},
	{#State 91
		ACTIONS => {
			'IDENT' => 93,
			'COMMA' => 148,
			'LITERAL' => 92
		},
		DEFAULT => -85,
		GOTOS => {
			'param' => 147
		}
	},
	{#State 92
		ACTIONS => {
			'ASSIGN' => 149
		}
	},
	{#State 93
		ACTIONS => {
			'ASSIGN' => 150
		}
	},
	{#State 94
		ACTIONS => {
			'BINOP' => 110
		},
		DEFAULT => -23
	},
	{#State 95
		DEFAULT => -0
	},
	{#State 96
		DEFAULT => -3
	},
	{#State 97
		ACTIONS => {
			'BINOP' => 110,
			"}" => 151
		}
	},
	{#State 98
		ACTIONS => {
			"\"" => 38,
			"{" => 30,
			"[" => 12,
			"\$" => 40,
			'IDENT' => 44,
			'LITERAL' => 50,
			"\${" => 34
		},
		GOTOS => {
			'term' => 152,
			'ident' => 49,
			'item' => 36
		}
	},
	{#State 99
		ACTIONS => {
			";" => 153,
			'OR' => 137,
			'AND' => 138,
			'COMPOP' => 140
		}
	},
	{#State 100
		ACTIONS => {
			"\"" => 157,
			";" => 156,
			"\$" => 40,
			'IDENT' => 44,
			"\${" => 34,
			'TEXT' => 154
		},
		GOTOS => {
			'ident' => 155,
			'quotable' => 158,
			'item' => 36
		}
	},
	{#State 101
		ACTIONS => {
			"\"" => 38,
			"{" => 30,
			"[" => 12,
			"\$" => 40,
			'IDENT' => 63,
			'LITERAL' => 50,
			"\${" => 34
		},
		GOTOS => {
			'term' => 64,
			'loopvar' => 159,
			'ident' => 49,
			'item' => 36
		}
	},
	{#State 102
		ACTIONS => {
			"\"" => 38,
			'NOT' => 79,
			"\$" => 40,
			'IDENT' => 44,
			"(" => 82,
			"[" => 12,
			"{" => 30,
			"\${" => 34,
			'LITERAL' => 35
		},
		GOTOS => {
			'term' => 83,
			'ident' => 17,
			'assign' => 81,
			'item' => 36,
			'expr' => 160
		}
	},
	{#State 103
		ACTIONS => {
			'IDENT' => 75
		},
		GOTOS => {
			'textdot' => 73,
			'useparam' => 161
		}
	},
	{#State 104
		ACTIONS => {
			"\"" => 38,
			'NOT' => 79,
			"\$" => 40,
			'IDENT' => 44,
			"(" => 82,
			"[" => 12,
			"{" => 30,
			"\${" => 34,
			'LITERAL' => 35
		},
		GOTOS => {
			'term' => 83,
			'ident' => 17,
			'assign' => 81,
			'item' => 36,
			'expr' => 162
		}
	},
	{#State 105
		ACTIONS => {
			"\"" => 38,
			'NOT' => 79,
			"\$" => 40,
			'IDENT' => 44,
			"(" => 82,
			"[" => 12,
			"{" => 30,
			"\${" => 34,
			'LITERAL' => 35
		},
		GOTOS => {
			'term' => 83,
			'ident' => 17,
			'assign' => 81,
			'item' => 36,
			'expr' => 163
		}
	},
	{#State 106
		DEFAULT => -65
	},
	{#State 107
		ACTIONS => {
			'RETURN' => 24,
			'GET' => 1,
			'CATCH' => 25,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'FILTER' => 28,
			'STOP' => 7,
			'DEBUG' => 29,
			'FOR' => 8,
			";" => -15,
			"{" => 30,
			"[" => 12,
			'ERROR' => 31,
			'BLOCK' => 13,
			'SET' => 14,
			'LITERAL' => 35,
			"\${" => 34,
			'USE' => 15,
			'IF' => 37,
			"\"" => 38,
			"\$" => 40,
			'MACRO' => 16,
			'PERL' => 43,
			'THROW' => 45,
			'IDENT' => 44,
			'WHILE' => 47,
			'UNLESS' => 19,
			'PROCESS' => 22
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 23,
			'catch' => 2,
			'assign' => 26,
			'filter' => 27,
			'condition' => 10,
			'debug' => 9,
			'setlist' => 11,
			'block' => 164,
			'chunks' => 33,
			'item' => 36,
			'atomdir' => 39,
			'macro' => 41,
			'perl' => 42,
			'ident' => 17,
			'term' => 46,
			'chunk' => 18,
			'loop' => 20,
			'defblock' => 21,
			'directive' => 48
		}
	},
	{#State 108
		ACTIONS => {
			"\"" => 38,
			"\$" => 40,
			'IDENT' => 169,
			"[" => 12,
			"{" => 30,
			"\${" => 34,
			'LITERAL' => 167
		},
		DEFAULT => -93,
		GOTOS => {
			'term' => 170,
			'param' => 165,
			'arg' => 171,
			'ident' => 49,
			'args' => 168,
			'arglist' => 166,
			'item' => 36
		}
	},
	{#State 109
		ACTIONS => {
			"\"" => 38,
			"\$" => 40,
			'IDENT' => 44,
			'DOT' => 113,
			"[" => 12,
			"{" => 30,
			"/" => 114,
			"\${" => 34,
			'LITERAL' => 50
		},
		GOTOS => {
			'term' => 172,
			'ident' => 49,
			'item' => 36
		}
	},
	{#State 110
		ACTIONS => {
			"\"" => 38,
			"{" => 30,
			"[" => 12,
			"\$" => 40,
			'IDENT' => 44,
			'LITERAL' => 50,
			"\${" => 34
		},
		GOTOS => {
			'term' => 173,
			'ident' => 49,
			'item' => 36
		}
	},
	{#State 111
		ACTIONS => {
			";" => 174,
			'OR' => 137,
			'AND' => 138,
			'COMPOP' => 140
		}
	},
	{#State 112
		DEFAULT => -6
	},
	{#State 113
		ACTIONS => {
			'IDENT' => 175
		}
	},
	{#State 114
		ACTIONS => {
			'IDENT' => 176
		}
	},
	{#State 115
		ACTIONS => {
			'DOT' => 113,
			"/" => 114
		},
		DEFAULT => -106
	},
	{#State 116
		ACTIONS => {
			"\$" => 40,
			'IDENT' => 44,
			'LITERAL' => 61,
			"\${" => 34,
			'COMMA' => 66
		},
		DEFAULT => -77,
		GOTOS => {
			'ident' => 60,
			'assign' => 65,
			'item' => 36
		}
	},
	{#State 117
		DEFAULT => -20
	},
	{#State 118
		ACTIONS => {
			"\"" => 177,
			";" => 156,
			"\$" => 40,
			'IDENT' => 44,
			"\${" => 34,
			'TEXT' => 154
		},
		GOTOS => {
			'ident' => 155,
			'quotable' => 158,
			'item' => 36
		}
	},
	{#State 119
		ACTIONS => {
			'DOT' => 77
		},
		DEFAULT => -104
	},
	{#State 120
		ACTIONS => {
			'RETURN' => 24,
			'GET' => 1,
			'CATCH' => 25,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'FILTER' => 28,
			'STOP' => 7,
			'DEBUG' => 29,
			'FOR' => 8,
			";" => -15,
			"{" => 30,
			"[" => 12,
			'ERROR' => 31,
			'BLOCK' => 13,
			'SET' => 14,
			'LITERAL' => 35,
			"\${" => 34,
			'USE' => 15,
			'IF' => 37,
			"\"" => 38,
			"\$" => 40,
			'MACRO' => 16,
			'PERL' => 43,
			'THROW' => 45,
			'IDENT' => 44,
			'WHILE' => 47,
			'UNLESS' => 19,
			'PROCESS' => 22
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 23,
			'catch' => 2,
			'assign' => 26,
			'filter' => 27,
			'condition' => 10,
			'debug' => 9,
			'setlist' => 11,
			'block' => 178,
			'chunks' => 33,
			'item' => 36,
			'atomdir' => 39,
			'macro' => 41,
			'perl' => 42,
			'ident' => 17,
			'term' => 46,
			'chunk' => 18,
			'loop' => 20,
			'defblock' => 21,
			'directive' => 48
		}
	},
	{#State 121
		ACTIONS => {
			"\"" => 38,
			"{" => 30,
			"[" => 12,
			"\$" => 40,
			'IDENT' => 44,
			'LITERAL' => 50,
			"\${" => 34
		},
		GOTOS => {
			'term' => 179,
			'ident' => 49,
			'item' => 36
		}
	},
	{#State 122
		DEFAULT => -56
	},
	{#State 123
		ACTIONS => {
			"(" => 180
		},
		DEFAULT => -57
	},
	{#State 124
		DEFAULT => -72
	},
	{#State 125
		ACTIONS => {
			'BINOP' => 110
		},
		DEFAULT => -71
	},
	{#State 126
		ACTIONS => {
			"\"" => 38,
			"{" => 30,
			"[" => 12,
			"\$" => 40,
			'IDENT' => 44,
			'LITERAL' => 50,
			"\${" => 34
		},
		GOTOS => {
			'term' => 181,
			'ident' => 49,
			'item' => 36
		}
	},
	{#State 127
		ACTIONS => {
			'RETURN' => 24,
			'GET' => 1,
			'CATCH' => 25,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'FILTER' => 28,
			'STOP' => 7,
			'DEBUG' => 29,
			'FOR' => 8,
			";" => -15,
			"{" => 30,
			"[" => 12,
			'ERROR' => 31,
			'BLOCK' => 13,
			'SET' => 14,
			'LITERAL' => 35,
			"\${" => 34,
			'USE' => 15,
			'IF' => 37,
			"\"" => 38,
			"\$" => 40,
			'MACRO' => 16,
			'PERL' => 43,
			'THROW' => 45,
			'IDENT' => 44,
			'WHILE' => 47,
			'UNLESS' => 19,
			'PROCESS' => 22
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 23,
			'catch' => 2,
			'assign' => 26,
			'filter' => 27,
			'condition' => 10,
			'debug' => 9,
			'setlist' => 11,
			'block' => 182,
			'chunks' => 33,
			'item' => 36,
			'atomdir' => 39,
			'macro' => 41,
			'perl' => 42,
			'ident' => 17,
			'term' => 46,
			'chunk' => 18,
			'loop' => 20,
			'defblock' => 21,
			'directive' => 48
		}
	},
	{#State 128
		ACTIONS => {
			'END' => 183
		}
	},
	{#State 129
		ACTIONS => {
			"\"" => 38,
			"\$" => 40,
			'IDENT' => 169,
			"[" => 12,
			"{" => 30,
			"\${" => 34,
			'LITERAL' => 167
		},
		DEFAULT => -93,
		GOTOS => {
			'term' => 170,
			'param' => 165,
			'arg' => 171,
			'ident' => 49,
			'args' => 184,
			'arglist' => 166,
			'item' => 36
		}
	},
	{#State 130
		ACTIONS => {
			'IDENT' => 58
		},
		GOTOS => {
			'textdot' => 185
		}
	},
	{#State 131
		ACTIONS => {
			'IDENT' => 187
		},
		GOTOS => {
			'mlist' => 186
		}
	},
	{#State 132
		DEFAULT => -51
	},
	{#State 133
		DEFAULT => -63
	},
	{#State 134
		DEFAULT => -62
	},
	{#State 135
		ACTIONS => {
			'BINOP' => 110
		},
		DEFAULT => -69
	},
	{#State 136
		ACTIONS => {
			'COMPOP' => 140
		},
		DEFAULT => -100
	},
	{#State 137
		ACTIONS => {
			"\"" => 38,
			'NOT' => 79,
			"\$" => 40,
			'IDENT' => 44,
			"(" => 82,
			"[" => 12,
			"{" => 30,
			"\${" => 34,
			'LITERAL' => 35
		},
		GOTOS => {
			'term' => 83,
			'ident' => 17,
			'assign' => 81,
			'item' => 36,
			'expr' => 188
		}
	},
	{#State 138
		ACTIONS => {
			"\"" => 38,
			'NOT' => 79,
			"\$" => 40,
			'IDENT' => 44,
			"(" => 82,
			"[" => 12,
			"{" => 30,
			"\${" => 34,
			'LITERAL' => 35
		},
		GOTOS => {
			'term' => 83,
			'ident' => 17,
			'assign' => 81,
			'item' => 36,
			'expr' => 189
		}
	},
	{#State 139
		ACTIONS => {
			'GET' => 1,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'STOP' => 7,
			'FOR' => 8,
			"[" => 12,
			'BLOCK' => 13,
			'SET' => 14,
			'USE' => 15,
			'MACRO' => 16,
			'UNLESS' => 19,
			'PROCESS' => 22,
			'RETURN' => 24,
			'CATCH' => 25,
			'FILTER' => 28,
			'DEBUG' => 29,
			";" => -15,
			"{" => 30,
			'ERROR' => 31,
			"\${" => 34,
			'LITERAL' => 35,
			'IF' => 37,
			"\"" => 38,
			"\$" => 40,
			'PERL' => 43,
			'IDENT' => 44,
			'THROW' => 45,
			'WHILE' => 47
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 23,
			'catch' => 2,
			'assign' => 26,
			'filter' => 27,
			'condition' => 10,
			'debug' => 9,
			'setlist' => 11,
			'block' => 190,
			'chunks' => 33,
			'item' => 36,
			'atomdir' => 39,
			'macro' => 41,
			'perl' => 42,
			'ident' => 17,
			'term' => 46,
			'chunk' => 18,
			'loop' => 20,
			'defblock' => 21,
			'directive' => 48
		}
	},
	{#State 140
		ACTIONS => {
			"\"" => 38,
			'NOT' => 79,
			"\$" => 40,
			'IDENT' => 44,
			"(" => 82,
			"[" => 12,
			"{" => 30,
			"\${" => 34,
			'LITERAL' => 35
		},
		GOTOS => {
			'term' => 83,
			'ident' => 17,
			'assign' => 81,
			'item' => 36,
			'expr' => 191
		}
	},
	{#State 141
		ACTIONS => {
			'OR' => 137,
			'AND' => 138,
			'COMPOP' => 140,
			")" => 192
		}
	},
	{#State 142
		DEFAULT => -21
	},
	{#State 143
		ACTIONS => {
			'RETURN' => 24,
			'GET' => 1,
			'CATCH' => 25,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'FILTER' => 28,
			'STOP' => 7,
			'DEBUG' => 29,
			'FOR' => 8,
			";" => -15,
			"{" => 30,
			"[" => 12,
			'ERROR' => 31,
			'BLOCK' => 13,
			'SET' => 14,
			'LITERAL' => 35,
			"\${" => 34,
			'USE' => 15,
			'IF' => 37,
			"\"" => 38,
			"\$" => 40,
			'MACRO' => 16,
			'PERL' => 43,
			'THROW' => 45,
			'IDENT' => 44,
			'WHILE' => 47,
			'UNLESS' => 19,
			'PROCESS' => 22
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 23,
			'catch' => 2,
			'assign' => 26,
			'filter' => 27,
			'condition' => 10,
			'debug' => 9,
			'setlist' => 11,
			'block' => 193,
			'chunks' => 33,
			'item' => 36,
			'atomdir' => 39,
			'macro' => 41,
			'perl' => 42,
			'ident' => 17,
			'term' => 46,
			'chunk' => 18,
			'loop' => 20,
			'defblock' => 21,
			'directive' => 48
		}
	},
	{#State 144
		ACTIONS => {
			'END' => 194
		}
	},
	{#State 145
		ACTIONS => {
			'RETURN' => 24,
			'GET' => 1,
			'CATCH' => 25,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'FILTER' => 28,
			'STOP' => 7,
			'DEBUG' => 29,
			'FOR' => 8,
			";" => -15,
			"{" => 30,
			"[" => 12,
			'ERROR' => 31,
			'BLOCK' => 13,
			'SET' => 14,
			'LITERAL' => 35,
			"\${" => 34,
			'USE' => 15,
			'IF' => 37,
			"\"" => 38,
			"\$" => 40,
			'MACRO' => 16,
			'PERL' => 43,
			'THROW' => 45,
			'IDENT' => 44,
			'WHILE' => 47,
			'UNLESS' => 19,
			'PROCESS' => 22
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 23,
			'catch' => 2,
			'assign' => 26,
			'filter' => 27,
			'condition' => 10,
			'debug' => 9,
			'setlist' => 11,
			'block' => 195,
			'chunks' => 33,
			'item' => 36,
			'atomdir' => 39,
			'macro' => 41,
			'perl' => 42,
			'ident' => 17,
			'term' => 46,
			'chunk' => 18,
			'loop' => 20,
			'defblock' => 21,
			'directive' => 48
		}
	},
	{#State 146
		DEFAULT => -59
	},
	{#State 147
		DEFAULT => -82
	},
	{#State 148
		DEFAULT => -83
	},
	{#State 149
		ACTIONS => {
			"\"" => 38,
			"{" => 30,
			"[" => 12,
			"\$" => 40,
			'IDENT' => 44,
			'LITERAL' => 50,
			"\${" => 34
		},
		GOTOS => {
			'term' => 196,
			'ident' => 49,
			'item' => 36
		}
	},
	{#State 150
		ACTIONS => {
			"\"" => 38,
			"{" => 30,
			"[" => 12,
			"\$" => 40,
			'IDENT' => 44,
			'LITERAL' => 50,
			"\${" => 34
		},
		GOTOS => {
			'term' => 197,
			'ident' => 49,
			'item' => 36
		}
	},
	{#State 151
		DEFAULT => -66
	},
	{#State 152
		ACTIONS => {
			'BINOP' => 110
		},
		DEFAULT => -70
	},
	{#State 153
		ACTIONS => {
			'GET' => 1,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'STOP' => 7,
			'FOR' => 8,
			"[" => 12,
			'BLOCK' => 13,
			'SET' => 14,
			'USE' => 15,
			'MACRO' => 16,
			'UNLESS' => 19,
			'PROCESS' => 22,
			'RETURN' => 24,
			'CATCH' => 25,
			'FILTER' => 28,
			'DEBUG' => 29,
			";" => -15,
			"{" => 30,
			'ERROR' => 31,
			"\${" => 34,
			'LITERAL' => 35,
			'IF' => 37,
			"\"" => 38,
			"\$" => 40,
			'PERL' => 43,
			'IDENT' => 44,
			'THROW' => 45,
			'WHILE' => 47
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 23,
			'catch' => 2,
			'assign' => 26,
			'filter' => 27,
			'condition' => 10,
			'debug' => 9,
			'setlist' => 11,
			'block' => 198,
			'chunks' => 33,
			'item' => 36,
			'atomdir' => 39,
			'macro' => 41,
			'perl' => 42,
			'ident' => 17,
			'term' => 46,
			'chunk' => 18,
			'loop' => 20,
			'defblock' => 21,
			'directive' => 48
		}
	},
	{#State 154
		DEFAULT => -119
	},
	{#State 155
		ACTIONS => {
			'DOT' => 77
		},
		DEFAULT => -118
	},
	{#State 156
		DEFAULT => -120
	},
	{#State 157
		DEFAULT => -60
	},
	{#State 158
		DEFAULT => -116
	},
	{#State 159
		DEFAULT => -41
	},
	{#State 160
		ACTIONS => {
			'OR' => 137,
			'AND' => 138,
			'COMPOP' => 140
		},
		DEFAULT => -36
	},
	{#State 161
		DEFAULT => -47
	},
	{#State 162
		ACTIONS => {
			'OR' => 137,
			'AND' => 138,
			'COMPOP' => 140
		},
		DEFAULT => -34
	},
	{#State 163
		ACTIONS => {
			'OR' => 137,
			'AND' => 138,
			'COMPOP' => 140
		},
		DEFAULT => -43
	},
	{#State 164
		ACTIONS => {
			'END' => 199
		}
	},
	{#State 165
		DEFAULT => -87
	},
	{#State 166
		ACTIONS => {
			"\"" => 38,
			"\$" => 40,
			'IDENT' => 169,
			"[" => 12,
			"{" => 30,
			"\${" => 34,
			'LITERAL' => 167,
			'COMMA' => 200
		},
		DEFAULT => -92,
		GOTOS => {
			'term' => 170,
			'param' => 165,
			'arg' => 201,
			'ident' => 49,
			'item' => 36
		}
	},
	{#State 167
		ACTIONS => {
			'ASSIGN' => 149
		},
		DEFAULT => -54
	},
	{#State 168
		ACTIONS => {
			")" => 202
		}
	},
	{#State 169
		ACTIONS => {
			'ASSIGN' => 150,
			"(" => 108
		},
		DEFAULT => -68
	},
	{#State 170
		ACTIONS => {
			'BINOP' => 110
		},
		DEFAULT => -88
	},
	{#State 171
		DEFAULT => -91
	},
	{#State 172
		ACTIONS => {
			'BINOP' => 110
		},
		DEFAULT => -22
	},
	{#State 173
		DEFAULT => -61
	},
	{#State 174
		ACTIONS => {
			'RETURN' => 24,
			'GET' => 1,
			'CATCH' => 25,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'FILTER' => 28,
			'STOP' => 7,
			'DEBUG' => 29,
			'FOR' => 8,
			";" => -15,
			"{" => 30,
			"[" => 12,
			'ERROR' => 31,
			'BLOCK' => 13,
			'SET' => 14,
			'LITERAL' => 35,
			"\${" => 34,
			'USE' => 15,
			'IF' => 37,
			"\"" => 38,
			"\$" => 40,
			'MACRO' => 16,
			'PERL' => 43,
			'THROW' => 45,
			'IDENT' => 44,
			'WHILE' => 47,
			'UNLESS' => 19,
			'PROCESS' => 22
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 23,
			'catch' => 2,
			'assign' => 26,
			'filter' => 27,
			'condition' => 10,
			'debug' => 9,
			'setlist' => 11,
			'block' => 203,
			'chunks' => 33,
			'item' => 36,
			'atomdir' => 39,
			'macro' => 41,
			'perl' => 42,
			'ident' => 17,
			'term' => 46,
			'chunk' => 18,
			'loop' => 20,
			'defblock' => 21,
			'directive' => 48
		}
	},
	{#State 175
		DEFAULT => -109
	},
	{#State 176
		DEFAULT => -110
	},
	{#State 177
		DEFAULT => -105
	},
	{#State 178
		ACTIONS => {
			'END' => 204
		}
	},
	{#State 179
		ACTIONS => {
			'BINOP' => 110
		},
		DEFAULT => -44
	},
	{#State 180
		ACTIONS => {
			"\"" => 38,
			"\$" => 40,
			'IDENT' => 169,
			"[" => 12,
			"{" => 30,
			"\${" => 34,
			'LITERAL' => 167
		},
		DEFAULT => -93,
		GOTOS => {
			'term' => 170,
			'param' => 165,
			'arg' => 171,
			'ident' => 49,
			'args' => 205,
			'arglist' => 166,
			'item' => 36
		}
	},
	{#State 181
		ACTIONS => {
			'BINOP' => 110
		},
		DEFAULT => -79
	},
	{#State 182
		ACTIONS => {
			'END' => 206
		}
	},
	{#State 183
		DEFAULT => -49
	},
	{#State 184
		ACTIONS => {
			")" => 207
		}
	},
	{#State 185
		ACTIONS => {
			"(" => 208,
			'DOT' => 113,
			"/" => 114
		},
		DEFAULT => -113
	},
	{#State 186
		ACTIONS => {
			'IDENT' => 211,
			'COMMA' => 210,
			")" => 209
		}
	},
	{#State 187
		DEFAULT => -96
	},
	{#State 188
		ACTIONS => {
			'COMPOP' => 140
		},
		DEFAULT => -99
	},
	{#State 189
		ACTIONS => {
			'COMPOP' => 140
		},
		DEFAULT => -98
	},
	{#State 190
		ACTIONS => {
			'ELSE' => 213,
			'ELSIF' => 212
		},
		DEFAULT => -39,
		GOTOS => {
			'else' => 214
		}
	},
	{#State 191
		DEFAULT => -97
	},
	{#State 192
		DEFAULT => -101
	},
	{#State 193
		ACTIONS => {
			'END' => 215
		}
	},
	{#State 194
		DEFAULT => -32
	},
	{#State 195
		ACTIONS => {
			'END' => 216
		}
	},
	{#State 196
		ACTIONS => {
			'BINOP' => 110
		},
		DEFAULT => -80
	},
	{#State 197
		ACTIONS => {
			'BINOP' => 110
		},
		DEFAULT => -81
	},
	{#State 198
		ACTIONS => {
			'ELSE' => 213,
			'ELSIF' => 212
		},
		DEFAULT => -39,
		GOTOS => {
			'else' => 217
		}
	},
	{#State 199
		DEFAULT => -50
	},
	{#State 200
		DEFAULT => -90
	},
	{#State 201
		DEFAULT => -89
	},
	{#State 202
		DEFAULT => -67
	},
	{#State 203
		ACTIONS => {
			'END' => 218
		}
	},
	{#State 204
		DEFAULT => -40
	},
	{#State 205
		ACTIONS => {
			")" => 219
		}
	},
	{#State 206
		DEFAULT => -48
	},
	{#State 207
		DEFAULT => -114
	},
	{#State 208
		ACTIONS => {
			"\"" => 38,
			"\$" => 40,
			'IDENT' => 169,
			"[" => 12,
			"{" => 30,
			"\${" => 34,
			'LITERAL' => 167
		},
		DEFAULT => -93,
		GOTOS => {
			'term' => 170,
			'param' => 165,
			'arg' => 171,
			'ident' => 49,
			'args' => 220,
			'arglist' => 166,
			'item' => 36
		}
	},
	{#State 209
		ACTIONS => {
			'RETURN' => 24,
			'GET' => 1,
			'CATCH' => 25,
			'INCLUDE' => 3,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'FILTER' => 28,
			'STOP' => 7,
			'DEBUG' => 29,
			'FOR' => 8,
			"{" => 30,
			"[" => 12,
			'ERROR' => 31,
			'BLOCK' => 13,
			'SET' => 14,
			'LITERAL' => 35,
			"\${" => 34,
			'USE' => 15,
			'IF' => 37,
			"\"" => 38,
			"\$" => 40,
			'MACRO' => 16,
			'PERL' => 43,
			'THROW' => 45,
			'IDENT' => 44,
			'WHILE' => 47,
			'UNLESS' => 19,
			'PROCESS' => 22
		},
		DEFAULT => -15,
		GOTOS => {
			'atomdir' => 39,
			'return' => 23,
			'macro' => 41,
			'perl' => 42,
			'catch' => 2,
			'ident' => 17,
			'assign' => 26,
			'filter' => 27,
			'condition' => 10,
			'debug' => 9,
			'term' => 46,
			'setlist' => 11,
			'defblock' => 21,
			'loop' => 20,
			'directive' => 221,
			'item' => 36
		}
	},
	{#State 210
		DEFAULT => -95
	},
	{#State 211
		DEFAULT => -94
	},
	{#State 212
		ACTIONS => {
			"\"" => 38,
			'NOT' => 79,
			"\$" => 40,
			'IDENT' => 44,
			"(" => 82,
			"[" => 12,
			"{" => 30,
			"\${" => 34,
			'LITERAL' => 35
		},
		GOTOS => {
			'term' => 83,
			'ident' => 17,
			'assign' => 81,
			'item' => 36,
			'expr' => 222
		}
	},
	{#State 213
		ACTIONS => {
			";" => 223
		}
	},
	{#State 214
		ACTIONS => {
			'END' => 224
		}
	},
	{#State 215
		DEFAULT => -31
	},
	{#State 216
		DEFAULT => -46
	},
	{#State 217
		ACTIONS => {
			'END' => 225
		}
	},
	{#State 218
		DEFAULT => -42
	},
	{#State 219
		DEFAULT => -58
	},
	{#State 220
		ACTIONS => {
			")" => 226
		}
	},
	{#State 221
		DEFAULT => -52
	},
	{#State 222
		ACTIONS => {
			";" => 227,
			'OR' => 137,
			'AND' => 138,
			'COMPOP' => 140
		}
	},
	{#State 223
		ACTIONS => {
			'RETURN' => 24,
			'GET' => 1,
			'CATCH' => 25,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'FILTER' => 28,
			'STOP' => 7,
			'DEBUG' => 29,
			'FOR' => 8,
			";" => -15,
			"{" => 30,
			"[" => 12,
			'ERROR' => 31,
			'BLOCK' => 13,
			'SET' => 14,
			'LITERAL' => 35,
			"\${" => 34,
			'USE' => 15,
			'IF' => 37,
			"\"" => 38,
			"\$" => 40,
			'MACRO' => 16,
			'PERL' => 43,
			'THROW' => 45,
			'IDENT' => 44,
			'WHILE' => 47,
			'UNLESS' => 19,
			'PROCESS' => 22
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 23,
			'catch' => 2,
			'assign' => 26,
			'filter' => 27,
			'condition' => 10,
			'debug' => 9,
			'setlist' => 11,
			'block' => 228,
			'chunks' => 33,
			'item' => 36,
			'atomdir' => 39,
			'macro' => 41,
			'perl' => 42,
			'ident' => 17,
			'term' => 46,
			'chunk' => 18,
			'loop' => 20,
			'defblock' => 21,
			'directive' => 48
		}
	},
	{#State 224
		DEFAULT => -35
	},
	{#State 225
		DEFAULT => -33
	},
	{#State 226
		DEFAULT => -112
	},
	{#State 227
		ACTIONS => {
			'GET' => 1,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'STOP' => 7,
			'FOR' => 8,
			"[" => 12,
			'BLOCK' => 13,
			'SET' => 14,
			'USE' => 15,
			'MACRO' => 16,
			'UNLESS' => 19,
			'PROCESS' => 22,
			'RETURN' => 24,
			'CATCH' => 25,
			'FILTER' => 28,
			'DEBUG' => 29,
			";" => -15,
			"{" => 30,
			'ERROR' => 31,
			"\${" => 34,
			'LITERAL' => 35,
			'IF' => 37,
			"\"" => 38,
			"\$" => 40,
			'PERL' => 43,
			'IDENT' => 44,
			'THROW' => 45,
			'WHILE' => 47
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 23,
			'catch' => 2,
			'assign' => 26,
			'filter' => 27,
			'condition' => 10,
			'debug' => 9,
			'setlist' => 11,
			'block' => 229,
			'chunks' => 33,
			'item' => 36,
			'atomdir' => 39,
			'macro' => 41,
			'perl' => 42,
			'ident' => 17,
			'term' => 46,
			'chunk' => 18,
			'loop' => 20,
			'defblock' => 21,
			'directive' => 48
		}
	},
	{#State 228
		DEFAULT => -37
	},
	{#State 229
		ACTIONS => {
			'ELSE' => 213,
			'ELSIF' => 212
		},
		DEFAULT => -39,
		GOTOS => {
			'else' => 230
		}
	},
	{#State 230
		DEFAULT => -38
	}
]; 


#========================================================================
# Rules
#========================================================================

$RULES = [
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'block', 1,
sub
#line 16 "Parser.yp"
{ $factory->create(Block => $_[1])      }
	],
	[#Rule 2
		 'block', 0,
sub
#line 17 "Parser.yp"
{ $factory->create(Block => [])         }
	],
	[#Rule 3
		 'chunks', 2,
sub
#line 20 "Parser.yp"
{ push(@{$_[1]}, $_[2]) if defined $_[2];
				   $_[1]                                }
	],
	[#Rule 4
		 'chunks', 1,
sub
#line 22 "Parser.yp"
{ defined $_[1] ? [ $_[1] ] : [ ]       }
	],
	[#Rule 5
		 'chunk', 1,
sub
#line 25 "Parser.yp"
{ $factory->create(Text => $_[1])       }
	],
	[#Rule 6
		 'chunk', 2, undef
	],
	[#Rule 7
		 'directive', 1, undef
	],
	[#Rule 8
		 'directive', 1, undef
	],
	[#Rule 9
		 'directive', 1, undef
	],
	[#Rule 10
		 'directive', 1, undef
	],
	[#Rule 11
		 'directive', 1, undef
	],
	[#Rule 12
		 'directive', 1, undef
	],
	[#Rule 13
		 'directive', 1, undef
	],
	[#Rule 14
		 'directive', 1, undef
	],
	[#Rule 15
		 'directive', 0, undef
	],
	[#Rule 16
		 'atomdir', 2,
sub
#line 45 "Parser.yp"
{ $factory->create(Get     => $_[2])    }
	],
	[#Rule 17
		 'atomdir', 2,
sub
#line 46 "Parser.yp"
{ $factory->create(Set     => $_[2])    }
	],
	[#Rule 18
		 'atomdir', 2,
sub
#line 47 "Parser.yp"
{ unshift(@{$_[2]}, OP_DEFAULT);
				  $factory->create(Set     => $_[2])    }
	],
	[#Rule 19
		 'atomdir', 2,
sub
#line 49 "Parser.yp"
{ $factory->create(Use     => @{$_[2]}) }
	],
	[#Rule 20
		 'atomdir', 3,
sub
#line 50 "Parser.yp"
{ $factory->create(Include => @_[2,3])  }
	],
	[#Rule 21
		 'atomdir', 3,
sub
#line 51 "Parser.yp"
{ $factory->create(Process => @_[2,3])  }
	],
	[#Rule 22
		 'atomdir', 3,
sub
#line 52 "Parser.yp"
{ $factory->create(Throw   => @_[2,3])  }
	],
	[#Rule 23
		 'atomdir', 2,
sub
#line 53 "Parser.yp"
{ $factory->create(Error   => $_[2])    }
	],
	[#Rule 24
		 'atomdir', 1,
sub
#line 54 "Parser.yp"
{ $factory->create(Return  => $_[1])    }
	],
	[#Rule 25
		 'atomdir', 1,
sub
#line 55 "Parser.yp"
{ $factory->create(Set     => $_[1])    }
	],
	[#Rule 26
		 'atomdir', 1,
sub
#line 56 "Parser.yp"
{ $factory->create(Get     => $_[1])    }
	],
	[#Rule 27
		 'atomdir', 1, undef
	],
	[#Rule 28
		 'return', 1,
sub
#line 60 "Parser.yp"
{ STATUS_RETURN }
	],
	[#Rule 29
		 'return', 1,
sub
#line 61 "Parser.yp"
{ STATUS_STOP   }
	],
	[#Rule 30
		 'return', 1,
sub
#line 62 "Parser.yp"
{ STATUS_DONE   }
	],
	[#Rule 31
		 'catch', 5,
sub
#line 66 "Parser.yp"
{ $factory->create(Catch =>, @_[2, 4])    }
	],
	[#Rule 32
		 'catch', 4,
sub
#line 68 "Parser.yp"
{ $factory->create(Catch => undef, $_[3]) }
	],
	[#Rule 33
		 'condition', 6,
sub
#line 72 "Parser.yp"
{ $factory->create(If => @_[2, 4, 5])   }
	],
	[#Rule 34
		 'condition', 3,
sub
#line 73 "Parser.yp"
{ $factory->create(If => @_[3, 1])      }
	],
	[#Rule 35
		 'condition', 6,
sub
#line 75 "Parser.yp"
{ push(@{$_[2]}, OP_NOT);
				  $factory->create(If => @_[2, 4, 5])   }
	],
	[#Rule 36
		 'condition', 3,
sub
#line 77 "Parser.yp"
{ push(@{$_[3]}, OP_NOT);
				  $factory->create(If => @_[3, 1])      }
	],
	[#Rule 37
		 'else', 3,
sub
#line 81 "Parser.yp"
{ $_[3]                                 }
	],
	[#Rule 38
		 'else', 5,
sub
#line 83 "Parser.yp"
{ $factory->create(If => @_[2, 4, 5])   }
	],
	[#Rule 39
		 'else', 0, undef
	],
	[#Rule 40
		 'loop', 5,
sub
#line 88 "Parser.yp"
{ $factory->create(For => @{$_[2]}, $_[4]) }
	],
	[#Rule 41
		 'loop', 3,
sub
#line 89 "Parser.yp"
{ $factory->create(For => @{$_[3]}, $_[1]) }
	],
	[#Rule 42
		 'loop', 5,
sub
#line 91 "Parser.yp"
{ $factory->create(While  => @_[2, 4])   }
	],
	[#Rule 43
		 'loop', 3,
sub
#line 92 "Parser.yp"
{ $factory->create(While  => @_[3, 1])   }
	],
	[#Rule 44
		 'loopvar', 3,
sub
#line 95 "Parser.yp"
{ [ @_[1, 3] ]     }
	],
	[#Rule 45
		 'loopvar', 1,
sub
#line 96 "Parser.yp"
{ [ undef, $_[1] ] }
	],
	[#Rule 46
		 'filter', 5,
sub
#line 100 "Parser.yp"
{ $factory->create(Filter => @{$_[2]}, $_[4]) }
	],
	[#Rule 47
		 'filter', 3,
sub
#line 102 "Parser.yp"
{ $factory->create(Filter => @{$_[3]}, $_[1]) }
	],
	[#Rule 48
		 'defblock', 5,
sub
#line 106 "Parser.yp"
{ $_[0]->define_block(@_[2, 4]); undef  }
	],
	[#Rule 49
		 'defblock', 4,
sub
#line 108 "Parser.yp"
{ $_[3] }
	],
	[#Rule 50
		 'perl', 4,
sub
#line 112 "Parser.yp"
{ $factory->create(Perl  => $_[3]) }
	],
	[#Rule 51
		 'macro', 3,
sub
#line 116 "Parser.yp"
{ $factory->create(Macro => @_[2, 3]) }
	],
	[#Rule 52
		 'macro', 6,
sub
#line 118 "Parser.yp"
{ $factory->create(Macro => @_[2, 6, 4]) }
	],
	[#Rule 53
		 'debug', 2,
sub
#line 121 "Parser.yp"
{ $factory->create(Debug => $_[2]) }
	],
	[#Rule 54
		 'term', 1,
sub
#line 129 "Parser.yp"
{ [ OP_LITERAL, $_[1]    ] }
	],
	[#Rule 55
		 'term', 1,
sub
#line 130 "Parser.yp"
{ [ OP_IDENT,   $_[1]    ] }
	],
	[#Rule 56
		 'term', 3,
sub
#line 131 "Parser.yp"
{ [ OP_RANGE,   $_[2]    ] }
	],
	[#Rule 57
		 'term', 3,
sub
#line 132 "Parser.yp"
{ [ OP_LIST,    $_[2]    ] }
	],
	[#Rule 58
		 'term', 6,
sub
#line 133 "Parser.yp"
{ [ OP_ITER,    @_[2, 5] ] }
	],
	[#Rule 59
		 'term', 3,
sub
#line 134 "Parser.yp"
{ [ OP_HASH,    $_[2]    ] }
	],
	[#Rule 60
		 'term', 3,
sub
#line 135 "Parser.yp"
{ [ OP_QUOTE,   $_[2]    ] }
	],
	[#Rule 61
		 'term', 3,
sub
#line 136 "Parser.yp"
{ push(@{$_[1]}, @{$_[3]}, 
						OP_BINOP, $_[2]); $_[1]  }
	],
	[#Rule 62
		 'ident', 3,
sub
#line 141 "Parser.yp"
{ push(@{$_[1]}, $_[3]); $_[1] }
	],
	[#Rule 63
		 'ident', 3,
sub
#line 142 "Parser.yp"
{ push(@{$_[1]}, [ $_[3], 0 ]); $_[1] }
	],
	[#Rule 64
		 'ident', 1,
sub
#line 143 "Parser.yp"
{ [ $_[1] ] }
	],
	[#Rule 65
		 'ident', 2,
sub
#line 144 "Parser.yp"
{ [ $_[2] ] }
	],
	[#Rule 66
		 'item', 3,
sub
#line 147 "Parser.yp"
{ [ $_[2], 0     ] }
	],
	[#Rule 67
		 'item', 4,
sub
#line 148 "Parser.yp"
{ [ $_[1], $_[3] ] }
	],
	[#Rule 68
		 'item', 1,
sub
#line 149 "Parser.yp"
{ [ $_[1], 0     ] }
	],
	[#Rule 69
		 'assign', 3,
sub
#line 152 "Parser.yp"
{ push(@{$_[3]}, OP_ASSIGN, $_[1]);
					  $_[3] }
	],
	[#Rule 70
		 'assign', 3,
sub
#line 154 "Parser.yp"
{ push(@{$_[3]}, OP_ASSIGN, $_[1]);
					  $_[3] }
	],
	[#Rule 71
		 'list', 2,
sub
#line 158 "Parser.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 72
		 'list', 2,
sub
#line 159 "Parser.yp"
{ $_[1] }
	],
	[#Rule 73
		 'list', 1,
sub
#line 160 "Parser.yp"
{ [ $_[1] ] }
	],
	[#Rule 74
		 'setlist', 2,
sub
#line 163 "Parser.yp"
{ push(@{$_[1]}, @{$_[2]}); $_[1] }
	],
	[#Rule 75
		 'setlist', 2,
sub
#line 164 "Parser.yp"
{ $_[1] }
	],
	[#Rule 76
		 'setlist', 1, undef
	],
	[#Rule 77
		 'setopt', 1, undef
	],
	[#Rule 78
		 'setopt', 0,
sub
#line 169 "Parser.yp"
{ [ ] }
	],
	[#Rule 79
		 'range', 3,
sub
#line 172 "Parser.yp"
{ [ @_[1, 3] ] }
	],
	[#Rule 80
		 'param', 3,
sub
#line 177 "Parser.yp"
{ [ $_[1], $_[3] ] }
	],
	[#Rule 81
		 'param', 3,
sub
#line 178 "Parser.yp"
{ [ $_[1], $_[3] ] }
	],
	[#Rule 82
		 'paramlist', 2,
sub
#line 181 "Parser.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 83
		 'paramlist', 2,
sub
#line 182 "Parser.yp"
{ $_[1] }
	],
	[#Rule 84
		 'paramlist', 1,
sub
#line 183 "Parser.yp"
{ [ $_[1] ] }
	],
	[#Rule 85
		 'params', 1, undef
	],
	[#Rule 86
		 'params', 0,
sub
#line 187 "Parser.yp"
{ [ ] }
	],
	[#Rule 87
		 'arg', 1, undef
	],
	[#Rule 88
		 'arg', 1,
sub
#line 191 "Parser.yp"
{ [ 0, $_[1] ] }
	],
	[#Rule 89
		 'arglist', 2,
sub
#line 194 "Parser.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 90
		 'arglist', 2,
sub
#line 195 "Parser.yp"
{ $_[1] }
	],
	[#Rule 91
		 'arglist', 1,
sub
#line 196 "Parser.yp"
{ [ $_[1] ] }
	],
	[#Rule 92
		 'args', 1,
sub
#line 199 "Parser.yp"
{ [ OP_ARGS, $_[1] ]  }
	],
	[#Rule 93
		 'args', 0,
sub
#line 200 "Parser.yp"
{ [ OP_LITERAL, [ ] ] }
	],
	[#Rule 94
		 'mlist', 2,
sub
#line 204 "Parser.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 95
		 'mlist', 2,
sub
#line 205 "Parser.yp"
{ $_[1] }
	],
	[#Rule 96
		 'mlist', 1,
sub
#line 206 "Parser.yp"
{ [ $_[1] ] }
	],
	[#Rule 97
		 'expr', 3,
sub
#line 209 "Parser.yp"
{ push(@{$_[1]}, @{$_[3]}, 
						OP_BINOP, $_[2]); $_[1]  }
	],
	[#Rule 98
		 'expr', 3,
sub
#line 211 "Parser.yp"
{ push(@{$_[1]}, OP_AND, $_[3]); 
					  $_[1]                          }
	],
	[#Rule 99
		 'expr', 3,
sub
#line 213 "Parser.yp"
{ push(@{$_[1]}, OP_OR, $_[3]);
					  $_[1]                          }
	],
	[#Rule 100
		 'expr', 2,
sub
#line 215 "Parser.yp"
{ push(@{$_[2]}, OP_NOT);
					  $_[2]                          }
	],
	[#Rule 101
		 'expr', 3,
sub
#line 217 "Parser.yp"
{ $_[2]                          }
	],
	[#Rule 102
		 'expr', 1, undef
	],
	[#Rule 103
		 'expr', 1, undef
	],
	[#Rule 104
		 'file', 2,
sub
#line 227 "Parser.yp"
{ [ OP_IDENT, $_[2] ] }
	],
	[#Rule 105
		 'file', 3,
sub
#line 228 "Parser.yp"
{ [ OP_QUOTE, $_[2] ] }
	],
	[#Rule 106
		 'file', 2,
sub
#line 229 "Parser.yp"
{ '/' . $_[2]         }
	],
	[#Rule 107
		 'file', 1, undef
	],
	[#Rule 108
		 'file', 1, undef
	],
	[#Rule 109
		 'textdot', 3,
sub
#line 236 "Parser.yp"
{ $_[1] .= "$_[2]$_[3]"; $_[1] }
	],
	[#Rule 110
		 'textdot', 3,
sub
#line 237 "Parser.yp"
{ $_[1] .= "$_[2]$_[3]"; $_[1] }
	],
	[#Rule 111
		 'textdot', 1, undef
	],
	[#Rule 112
		 'useparam', 6,
sub
#line 243 "Parser.yp"
{ [ @_[3, 5, 1]         ] }
	],
	[#Rule 113
		 'useparam', 3,
sub
#line 244 "Parser.yp"
{ [ $_[3], undef, $_[1] ] }
	],
	[#Rule 114
		 'useparam', 4,
sub
#line 245 "Parser.yp"
{ [ $_[1], $_[3], undef ] }
	],
	[#Rule 115
		 'useparam', 1,
sub
#line 246 "Parser.yp"
{ [ $_[1], undef, undef ] }
	],
	[#Rule 116
		 'quoted', 2,
sub
#line 252 "Parser.yp"
{ push(@{$_[1]}, $_[2])
						if defined $_[2]; $_[1] }
	],
	[#Rule 117
		 'quoted', 0,
sub
#line 254 "Parser.yp"
{ [ ] }
	],
	[#Rule 118
		 'quotable', 1,
sub
#line 260 "Parser.yp"
{ [ OP_IDENT,   $_[1] ] }
	],
	[#Rule 119
		 'quotable', 1,
sub
#line 261 "Parser.yp"
{ [ OP_LITERAL, $_[1] ] }
	],
	[#Rule 120
		 'quotable', 1,
sub
#line 262 "Parser.yp"
{ undef }
	]
];



1;












