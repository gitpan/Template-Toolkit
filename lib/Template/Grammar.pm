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
# $Id: Grammar.pm,v 1.35 1999/12/21 14:22:14 abw Exp $
#
#========================================================================

package Template::Grammar;

require 5.004;

use strict;
use vars qw( $VERSION );

use Template::Constants qw( :ops :status );

$VERSION = sprintf("%d.%02d", q$Revision: 1.35 $ =~ /(\d+)\.(\d+)/);

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
    '\\'      => 'REF',
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
			'REF' => 48,
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
			'directive' => 49
		}
	},
	{#State 1
		ACTIONS => {
			"\"" => 38,
			"{" => 30,
			"[" => 12,
			"\$" => 40,
			'IDENT' => 44,
			'REF' => 48,
			'LITERAL' => 51,
			"\${" => 34
		},
		GOTOS => {
			'term' => 52,
			'ident' => 50,
			'item' => 36
		}
	},
	{#State 2
		DEFAULT => -8
	},
	{#State 3
		ACTIONS => {
			"\"" => 57,
			"\$" => 58,
			'IDENT' => 59,
			'LITERAL' => 56,
			"/" => 54
		},
		GOTOS => {
			'file' => 55,
			'textdot' => 53
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
			'LITERAL' => 62
		},
		GOTOS => {
			'setlist' => 60,
			'ident' => 61,
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
			'IDENT' => 64,
			'REF' => 48,
			'LITERAL' => 51,
			"\${" => 34
		},
		GOTOS => {
			'term' => 65,
			'loopvar' => 63,
			'ident' => 50,
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
			'LITERAL' => 62,
			"\${" => 34,
			'COMMA' => 67
		},
		DEFAULT => -25,
		GOTOS => {
			'ident' => 61,
			'assign' => 66,
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
			'REF' => 48,
			'LITERAL' => 51,
			"\${" => 34
		},
		GOTOS => {
			'term' => 70,
			'list' => 69,
			'ident' => 50,
			'range' => 68,
			'item' => 36
		}
	},
	{#State 13
		ACTIONS => {
			";" => 72,
			'IDENT' => 59
		},
		GOTOS => {
			'textdot' => 71
		}
	},
	{#State 14
		ACTIONS => {
			"\$" => 40,
			'IDENT' => 44,
			"\${" => 34,
			'LITERAL' => 62
		},
		GOTOS => {
			'setlist' => 73,
			'ident' => 61,
			'assign' => 26,
			'item' => 36
		}
	},
	{#State 15
		ACTIONS => {
			'IDENT' => 76
		},
		GOTOS => {
			'textdot' => 74,
			'useparam' => 75
		}
	},
	{#State 16
		ACTIONS => {
			'IDENT' => 77
		}
	},
	{#State 17
		ACTIONS => {
			'ASSIGN' => 79,
			'DOT' => 78
		},
		DEFAULT => -55
	},
	{#State 18
		DEFAULT => -4
	},
	{#State 19
		ACTIONS => {
			"\"" => 38,
			'NOT' => 80,
			"\$" => 40,
			'IDENT' => 44,
			"(" => 83,
			"[" => 12,
			"{" => 30,
			'REF' => 48,
			"\${" => 34,
			'LITERAL' => 35
		},
		GOTOS => {
			'term' => 84,
			'ident' => 17,
			'assign' => 82,
			'item' => 36,
			'expr' => 81
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
			"\"" => 57,
			"\$" => 58,
			'IDENT' => 59,
			'LITERAL' => 56,
			"/" => 54
		},
		GOTOS => {
			'file' => 85,
			'textdot' => 53
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
			";" => 87,
			'IDENT' => 59
		},
		GOTOS => {
			'textdot' => 86
		}
	},
	{#State 26
		DEFAULT => -78
	},
	{#State 27
		DEFAULT => -27
	},
	{#State 28
		ACTIONS => {
			'IDENT' => 76
		},
		GOTOS => {
			'textdot' => 74,
			'useparam' => 88
		}
	},
	{#State 29
		ACTIONS => {
			'TEXT' => 89
		}
	},
	{#State 30
		ACTIONS => {
			'IDENT' => 94,
			'LITERAL' => 93
		},
		DEFAULT => -88,
		GOTOS => {
			'param' => 90,
			'params' => 91,
			'paramlist' => 92
		}
	},
	{#State 31
		ACTIONS => {
			"\"" => 38,
			"{" => 30,
			"[" => 12,
			"\$" => 40,
			'IDENT' => 44,
			'REF' => 48,
			'LITERAL' => 51,
			"\${" => 34
		},
		GOTOS => {
			'term' => 95,
			'ident' => 50,
			'item' => 36
		}
	},
	{#State 32
		ACTIONS => {
			'' => 96
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
			'WHILE' => 47,
			'REF' => 48
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
			'chunk' => 97,
			'defblock' => 21,
			'loop' => 20,
			'directive' => 49,
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
			'REF' => 48,
			'LITERAL' => 51,
			"\${" => 34
		},
		GOTOS => {
			'term' => 98,
			'ident' => 50,
			'item' => 36
		}
	},
	{#State 35
		ACTIONS => {
			'ASSIGN' => 99
		},
		DEFAULT => -54
	},
	{#State 36
		DEFAULT => -65
	},
	{#State 37
		ACTIONS => {
			"\"" => 38,
			'NOT' => 80,
			"\$" => 40,
			'IDENT' => 44,
			"(" => 83,
			"[" => 12,
			"{" => 30,
			'REF' => 48,
			"\${" => 34,
			'LITERAL' => 35
		},
		GOTOS => {
			'term' => 84,
			'ident' => 17,
			'assign' => 82,
			'item' => 36,
			'expr' => 100
		}
	},
	{#State 38
		DEFAULT => -119,
		GOTOS => {
			'quoted' => 101
		}
	},
	{#State 39
		ACTIONS => {
			'WHILE' => 106,
			'UNLESS' => 103,
			'FILTER' => 104,
			'IF' => 105,
			'FOR' => 102
		},
		DEFAULT => -7
	},
	{#State 40
		ACTIONS => {
			'IDENT' => 44,
			"\${" => 34
		},
		GOTOS => {
			'item' => 107
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
			";" => 108
		}
	},
	{#State 44
		ACTIONS => {
			"(" => 109
		},
		DEFAULT => -70
	},
	{#State 45
		ACTIONS => {
			'IDENT' => 59
		},
		GOTOS => {
			'textdot' => 110
		}
	},
	{#State 46
		ACTIONS => {
			'BINOP' => 111
		},
		DEFAULT => -26
	},
	{#State 47
		ACTIONS => {
			"\"" => 38,
			'NOT' => 80,
			"\$" => 40,
			'IDENT' => 44,
			"(" => 83,
			"[" => 12,
			"{" => 30,
			'REF' => 48,
			"\${" => 34,
			'LITERAL' => 35
		},
		GOTOS => {
			'term' => 84,
			'ident' => 17,
			'assign' => 82,
			'item' => 36,
			'expr' => 112
		}
	},
	{#State 48
		ACTIONS => {
			"\$" => 40,
			'IDENT' => 44,
			"\${" => 34
		},
		GOTOS => {
			'ident' => 113,
			'item' => 36
		}
	},
	{#State 49
		ACTIONS => {
			";" => 114
		}
	},
	{#State 50
		ACTIONS => {
			'DOT' => 78
		},
		DEFAULT => -55
	},
	{#State 51
		DEFAULT => -54
	},
	{#State 52
		ACTIONS => {
			'BINOP' => 111
		},
		DEFAULT => -16
	},
	{#State 53
		ACTIONS => {
			'DOT' => 115,
			"/" => 116
		},
		DEFAULT => -109
	},
	{#State 54
		ACTIONS => {
			'IDENT' => 59
		},
		GOTOS => {
			'textdot' => 117
		}
	},
	{#State 55
		ACTIONS => {
			"\$" => 40,
			'IDENT' => 44,
			'LITERAL' => 62,
			"\${" => 34
		},
		DEFAULT => -80,
		GOTOS => {
			'setlist' => 118,
			'ident' => 61,
			'assign' => 26,
			'setopt' => 119,
			'item' => 36
		}
	},
	{#State 56
		DEFAULT => -110
	},
	{#State 57
		DEFAULT => -119,
		GOTOS => {
			'quoted' => 120
		}
	},
	{#State 58
		ACTIONS => {
			"\$" => 40,
			'IDENT' => 44,
			"\${" => 34
		},
		GOTOS => {
			'ident' => 121,
			'item' => 36
		}
	},
	{#State 59
		DEFAULT => -113
	},
	{#State 60
		ACTIONS => {
			"\$" => 40,
			'IDENT' => 44,
			'LITERAL' => 62,
			"\${" => 34,
			'COMMA' => 67
		},
		DEFAULT => -18,
		GOTOS => {
			'ident' => 61,
			'assign' => 66,
			'item' => 36
		}
	},
	{#State 61
		ACTIONS => {
			'ASSIGN' => 79,
			'DOT' => 78
		}
	},
	{#State 62
		ACTIONS => {
			'ASSIGN' => 99
		}
	},
	{#State 63
		ACTIONS => {
			";" => 122
		}
	},
	{#State 64
		ACTIONS => {
			'ASSIGN' => 123,
			"(" => 109
		},
		DEFAULT => -70
	},
	{#State 65
		ACTIONS => {
			'BINOP' => 111
		},
		DEFAULT => -45
	},
	{#State 66
		DEFAULT => -76
	},
	{#State 67
		DEFAULT => -77
	},
	{#State 68
		ACTIONS => {
			"]" => 124
		}
	},
	{#State 69
		ACTIONS => {
			"\"" => 38,
			"\$" => 40,
			'IDENT' => 44,
			"[" => 12,
			"{" => 30,
			"]" => 125,
			'REF' => 48,
			"\${" => 34,
			'LITERAL' => 51,
			'COMMA' => 126
		},
		GOTOS => {
			'term' => 127,
			'ident' => 50,
			'item' => 36
		}
	},
	{#State 70
		ACTIONS => {
			'TO' => 128,
			'BINOP' => 111
		},
		DEFAULT => -75
	},
	{#State 71
		ACTIONS => {
			";" => 129,
			"/" => 116,
			'DOT' => 115
		}
	},
	{#State 72
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
			'WHILE' => 47,
			'REF' => 48
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
			'block' => 130,
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
			'directive' => 49
		}
	},
	{#State 73
		ACTIONS => {
			"\$" => 40,
			'IDENT' => 44,
			'LITERAL' => 62,
			"\${" => 34,
			'COMMA' => 67
		},
		DEFAULT => -17,
		GOTOS => {
			'ident' => 61,
			'assign' => 66,
			'item' => 36
		}
	},
	{#State 74
		ACTIONS => {
			"(" => 131,
			'DOT' => 115,
			"/" => 116
		},
		DEFAULT => -117
	},
	{#State 75
		DEFAULT => -19
	},
	{#State 76
		ACTIONS => {
			'ASSIGN' => 132
		},
		DEFAULT => -113
	},
	{#State 77
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
			"(" => 133,
			'WHILE' => 47,
			'UNLESS' => 19,
			'REF' => 48,
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
			'directive' => 134,
			'item' => 36
		}
	},
	{#State 78
		ACTIONS => {
			'IDENT' => 44,
			'LITERAL' => 135,
			"\${" => 34
		},
		GOTOS => {
			'item' => 136
		}
	},
	{#State 79
		ACTIONS => {
			"\"" => 38,
			"{" => 30,
			"[" => 12,
			"\$" => 40,
			'IDENT' => 44,
			'REF' => 48,
			'LITERAL' => 51,
			"\${" => 34
		},
		GOTOS => {
			'term' => 137,
			'ident' => 50,
			'item' => 36
		}
	},
	{#State 80
		ACTIONS => {
			"\"" => 38,
			'NOT' => 80,
			"\$" => 40,
			'IDENT' => 44,
			"(" => 83,
			"[" => 12,
			"{" => 30,
			'REF' => 48,
			"\${" => 34,
			'LITERAL' => 35
		},
		GOTOS => {
			'term' => 84,
			'ident' => 17,
			'assign' => 82,
			'item' => 36,
			'expr' => 138
		}
	},
	{#State 81
		ACTIONS => {
			";" => 141,
			'OR' => 139,
			'AND' => 140,
			'COMPOP' => 142
		}
	},
	{#State 82
		DEFAULT => -104
	},
	{#State 83
		ACTIONS => {
			"\"" => 38,
			'NOT' => 80,
			"\$" => 40,
			'IDENT' => 44,
			"(" => 83,
			"[" => 12,
			"{" => 30,
			'REF' => 48,
			"\${" => 34,
			'LITERAL' => 35
		},
		GOTOS => {
			'term' => 84,
			'ident' => 17,
			'assign' => 82,
			'item' => 36,
			'expr' => 143
		}
	},
	{#State 84
		ACTIONS => {
			'BINOP' => 111
		},
		DEFAULT => -105
	},
	{#State 85
		ACTIONS => {
			"\$" => 40,
			'IDENT' => 44,
			'LITERAL' => 62,
			"\${" => 34
		},
		DEFAULT => -80,
		GOTOS => {
			'setlist' => 118,
			'ident' => 61,
			'assign' => 26,
			'setopt' => 144,
			'item' => 36
		}
	},
	{#State 86
		ACTIONS => {
			";" => 145,
			"/" => 116,
			'DOT' => 115
		}
	},
	{#State 87
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
			'WHILE' => 47,
			'REF' => 48
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
			'block' => 146,
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
			'directive' => 49
		}
	},
	{#State 88
		ACTIONS => {
			";" => 147
		}
	},
	{#State 89
		DEFAULT => -53
	},
	{#State 90
		DEFAULT => -86
	},
	{#State 91
		ACTIONS => {
			"}" => 148
		}
	},
	{#State 92
		ACTIONS => {
			'IDENT' => 94,
			'COMMA' => 150,
			'LITERAL' => 93
		},
		DEFAULT => -87,
		GOTOS => {
			'param' => 149
		}
	},
	{#State 93
		ACTIONS => {
			'ASSIGN' => 151
		}
	},
	{#State 94
		ACTIONS => {
			'ASSIGN' => 152
		}
	},
	{#State 95
		ACTIONS => {
			'BINOP' => 111
		},
		DEFAULT => -23
	},
	{#State 96
		DEFAULT => -0
	},
	{#State 97
		DEFAULT => -3
	},
	{#State 98
		ACTIONS => {
			'BINOP' => 111,
			"}" => 153
		}
	},
	{#State 99
		ACTIONS => {
			"\"" => 38,
			"{" => 30,
			"[" => 12,
			"\$" => 40,
			'IDENT' => 44,
			'REF' => 48,
			'LITERAL' => 51,
			"\${" => 34
		},
		GOTOS => {
			'term' => 154,
			'ident' => 50,
			'item' => 36
		}
	},
	{#State 100
		ACTIONS => {
			";" => 155,
			'OR' => 139,
			'AND' => 140,
			'COMPOP' => 142
		}
	},
	{#State 101
		ACTIONS => {
			"\"" => 159,
			";" => 158,
			"\$" => 40,
			'IDENT' => 44,
			"\${" => 34,
			'TEXT' => 156
		},
		GOTOS => {
			'ident' => 157,
			'quotable' => 160,
			'item' => 36
		}
	},
	{#State 102
		ACTIONS => {
			"\"" => 38,
			"{" => 30,
			"[" => 12,
			"\$" => 40,
			'IDENT' => 64,
			'REF' => 48,
			'LITERAL' => 51,
			"\${" => 34
		},
		GOTOS => {
			'term' => 65,
			'loopvar' => 161,
			'ident' => 50,
			'item' => 36
		}
	},
	{#State 103
		ACTIONS => {
			"\"" => 38,
			'NOT' => 80,
			"\$" => 40,
			'IDENT' => 44,
			"(" => 83,
			"[" => 12,
			"{" => 30,
			'REF' => 48,
			"\${" => 34,
			'LITERAL' => 35
		},
		GOTOS => {
			'term' => 84,
			'ident' => 17,
			'assign' => 82,
			'item' => 36,
			'expr' => 162
		}
	},
	{#State 104
		ACTIONS => {
			'IDENT' => 76
		},
		GOTOS => {
			'textdot' => 74,
			'useparam' => 163
		}
	},
	{#State 105
		ACTIONS => {
			"\"" => 38,
			'NOT' => 80,
			"\$" => 40,
			'IDENT' => 44,
			"(" => 83,
			"[" => 12,
			"{" => 30,
			'REF' => 48,
			"\${" => 34,
			'LITERAL' => 35
		},
		GOTOS => {
			'term' => 84,
			'ident' => 17,
			'assign' => 82,
			'item' => 36,
			'expr' => 164
		}
	},
	{#State 106
		ACTIONS => {
			"\"" => 38,
			'NOT' => 80,
			"\$" => 40,
			'IDENT' => 44,
			"(" => 83,
			"[" => 12,
			"{" => 30,
			'REF' => 48,
			"\${" => 34,
			'LITERAL' => 35
		},
		GOTOS => {
			'term' => 84,
			'ident' => 17,
			'assign' => 82,
			'item' => 36,
			'expr' => 165
		}
	},
	{#State 107
		DEFAULT => -66
	},
	{#State 108
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
			'WHILE' => 47,
			'REF' => 48
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
			'block' => 166,
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
			'directive' => 49
		}
	},
	{#State 109
		ACTIONS => {
			"\"" => 38,
			"\$" => 40,
			'IDENT' => 171,
			"[" => 12,
			"{" => 30,
			'REF' => 48,
			"\${" => 34,
			'LITERAL' => 169
		},
		DEFAULT => -95,
		GOTOS => {
			'term' => 172,
			'param' => 167,
			'arg' => 173,
			'ident' => 50,
			'args' => 170,
			'arglist' => 168,
			'item' => 36
		}
	},
	{#State 110
		ACTIONS => {
			"\"" => 38,
			"\$" => 40,
			'IDENT' => 44,
			'DOT' => 115,
			"[" => 12,
			"{" => 30,
			'REF' => 48,
			"/" => 116,
			"\${" => 34,
			'LITERAL' => 51
		},
		GOTOS => {
			'term' => 174,
			'ident' => 50,
			'item' => 36
		}
	},
	{#State 111
		ACTIONS => {
			"\"" => 38,
			"{" => 30,
			"[" => 12,
			"\$" => 40,
			'IDENT' => 44,
			'REF' => 48,
			'LITERAL' => 51,
			"\${" => 34
		},
		GOTOS => {
			'term' => 175,
			'ident' => 50,
			'item' => 36
		}
	},
	{#State 112
		ACTIONS => {
			";" => 176,
			'OR' => 139,
			'AND' => 140,
			'COMPOP' => 142
		}
	},
	{#State 113
		ACTIONS => {
			'DOT' => 78
		},
		DEFAULT => -56
	},
	{#State 114
		DEFAULT => -6
	},
	{#State 115
		ACTIONS => {
			'IDENT' => 177
		}
	},
	{#State 116
		ACTIONS => {
			'IDENT' => 178
		}
	},
	{#State 117
		ACTIONS => {
			'DOT' => 115,
			"/" => 116
		},
		DEFAULT => -108
	},
	{#State 118
		ACTIONS => {
			"\$" => 40,
			'IDENT' => 44,
			'LITERAL' => 62,
			"\${" => 34,
			'COMMA' => 67
		},
		DEFAULT => -79,
		GOTOS => {
			'ident' => 61,
			'assign' => 66,
			'item' => 36
		}
	},
	{#State 119
		DEFAULT => -20
	},
	{#State 120
		ACTIONS => {
			"\"" => 179,
			";" => 158,
			"\$" => 40,
			'IDENT' => 44,
			"\${" => 34,
			'TEXT' => 156
		},
		GOTOS => {
			'ident' => 157,
			'quotable' => 160,
			'item' => 36
		}
	},
	{#State 121
		ACTIONS => {
			'DOT' => 78
		},
		DEFAULT => -106
	},
	{#State 122
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
			'WHILE' => 47,
			'REF' => 48
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
			'block' => 180,
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
			'directive' => 49
		}
	},
	{#State 123
		ACTIONS => {
			"\"" => 38,
			"{" => 30,
			"[" => 12,
			"\$" => 40,
			'IDENT' => 44,
			'REF' => 48,
			'LITERAL' => 51,
			"\${" => 34
		},
		GOTOS => {
			'term' => 181,
			'ident' => 50,
			'item' => 36
		}
	},
	{#State 124
		DEFAULT => -57
	},
	{#State 125
		ACTIONS => {
			"(" => 182
		},
		DEFAULT => -58
	},
	{#State 126
		DEFAULT => -74
	},
	{#State 127
		ACTIONS => {
			'BINOP' => 111
		},
		DEFAULT => -73
	},
	{#State 128
		ACTIONS => {
			"\"" => 38,
			"{" => 30,
			"[" => 12,
			"\$" => 40,
			'IDENT' => 44,
			'REF' => 48,
			'LITERAL' => 51,
			"\${" => 34
		},
		GOTOS => {
			'term' => 183,
			'ident' => 50,
			'item' => 36
		}
	},
	{#State 129
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
			'WHILE' => 47,
			'REF' => 48
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
			'block' => 184,
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
			'directive' => 49
		}
	},
	{#State 130
		ACTIONS => {
			'END' => 185
		}
	},
	{#State 131
		ACTIONS => {
			"\"" => 38,
			"\$" => 40,
			'IDENT' => 171,
			"[" => 12,
			"{" => 30,
			'REF' => 48,
			"\${" => 34,
			'LITERAL' => 169
		},
		DEFAULT => -95,
		GOTOS => {
			'term' => 172,
			'param' => 167,
			'arg' => 173,
			'ident' => 50,
			'args' => 186,
			'arglist' => 168,
			'item' => 36
		}
	},
	{#State 132
		ACTIONS => {
			'IDENT' => 59
		},
		GOTOS => {
			'textdot' => 187
		}
	},
	{#State 133
		ACTIONS => {
			'IDENT' => 189
		},
		GOTOS => {
			'mlist' => 188
		}
	},
	{#State 134
		DEFAULT => -51
	},
	{#State 135
		DEFAULT => -64
	},
	{#State 136
		DEFAULT => -63
	},
	{#State 137
		ACTIONS => {
			'BINOP' => 111
		},
		DEFAULT => -71
	},
	{#State 138
		ACTIONS => {
			'COMPOP' => 142
		},
		DEFAULT => -102
	},
	{#State 139
		ACTIONS => {
			"\"" => 38,
			'NOT' => 80,
			"\$" => 40,
			'IDENT' => 44,
			"(" => 83,
			"[" => 12,
			"{" => 30,
			'REF' => 48,
			"\${" => 34,
			'LITERAL' => 35
		},
		GOTOS => {
			'term' => 84,
			'ident' => 17,
			'assign' => 82,
			'item' => 36,
			'expr' => 190
		}
	},
	{#State 140
		ACTIONS => {
			"\"" => 38,
			'NOT' => 80,
			"\$" => 40,
			'IDENT' => 44,
			"(" => 83,
			"[" => 12,
			"{" => 30,
			'REF' => 48,
			"\${" => 34,
			'LITERAL' => 35
		},
		GOTOS => {
			'term' => 84,
			'ident' => 17,
			'assign' => 82,
			'item' => 36,
			'expr' => 191
		}
	},
	{#State 141
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
			'WHILE' => 47,
			'REF' => 48
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
			'block' => 192,
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
			'directive' => 49
		}
	},
	{#State 142
		ACTIONS => {
			"\"" => 38,
			'NOT' => 80,
			"\$" => 40,
			'IDENT' => 44,
			"(" => 83,
			"[" => 12,
			"{" => 30,
			'REF' => 48,
			"\${" => 34,
			'LITERAL' => 35
		},
		GOTOS => {
			'term' => 84,
			'ident' => 17,
			'assign' => 82,
			'item' => 36,
			'expr' => 193
		}
	},
	{#State 143
		ACTIONS => {
			'OR' => 139,
			'AND' => 140,
			'COMPOP' => 142,
			")" => 194
		}
	},
	{#State 144
		DEFAULT => -21
	},
	{#State 145
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
			'WHILE' => 47,
			'REF' => 48
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
			'directive' => 49
		}
	},
	{#State 146
		ACTIONS => {
			'END' => 196
		}
	},
	{#State 147
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
			'WHILE' => 47,
			'REF' => 48
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
			'block' => 197,
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
			'directive' => 49
		}
	},
	{#State 148
		DEFAULT => -60
	},
	{#State 149
		DEFAULT => -84
	},
	{#State 150
		DEFAULT => -85
	},
	{#State 151
		ACTIONS => {
			"\"" => 38,
			"{" => 30,
			"[" => 12,
			"\$" => 40,
			'IDENT' => 44,
			'REF' => 48,
			'LITERAL' => 51,
			"\${" => 34
		},
		GOTOS => {
			'term' => 198,
			'ident' => 50,
			'item' => 36
		}
	},
	{#State 152
		ACTIONS => {
			"\"" => 38,
			"{" => 30,
			"[" => 12,
			"\$" => 40,
			'IDENT' => 44,
			'REF' => 48,
			'LITERAL' => 51,
			"\${" => 34
		},
		GOTOS => {
			'term' => 199,
			'ident' => 50,
			'item' => 36
		}
	},
	{#State 153
		ACTIONS => {
			"(" => 200
		},
		DEFAULT => -67
	},
	{#State 154
		ACTIONS => {
			'BINOP' => 111
		},
		DEFAULT => -72
	},
	{#State 155
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
			'WHILE' => 47,
			'REF' => 48
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
			'block' => 201,
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
			'directive' => 49
		}
	},
	{#State 156
		DEFAULT => -121
	},
	{#State 157
		ACTIONS => {
			'DOT' => 78
		},
		DEFAULT => -120
	},
	{#State 158
		DEFAULT => -122
	},
	{#State 159
		DEFAULT => -61
	},
	{#State 160
		DEFAULT => -118
	},
	{#State 161
		DEFAULT => -41
	},
	{#State 162
		ACTIONS => {
			'OR' => 139,
			'AND' => 140,
			'COMPOP' => 142
		},
		DEFAULT => -36
	},
	{#State 163
		DEFAULT => -47
	},
	{#State 164
		ACTIONS => {
			'OR' => 139,
			'AND' => 140,
			'COMPOP' => 142
		},
		DEFAULT => -34
	},
	{#State 165
		ACTIONS => {
			'OR' => 139,
			'AND' => 140,
			'COMPOP' => 142
		},
		DEFAULT => -43
	},
	{#State 166
		ACTIONS => {
			'END' => 202
		}
	},
	{#State 167
		DEFAULT => -89
	},
	{#State 168
		ACTIONS => {
			"\"" => 38,
			"\$" => 40,
			'IDENT' => 171,
			"[" => 12,
			"{" => 30,
			'REF' => 48,
			"\${" => 34,
			'LITERAL' => 169,
			'COMMA' => 203
		},
		DEFAULT => -94,
		GOTOS => {
			'term' => 172,
			'param' => 167,
			'arg' => 204,
			'ident' => 50,
			'item' => 36
		}
	},
	{#State 169
		ACTIONS => {
			'ASSIGN' => 151
		},
		DEFAULT => -54
	},
	{#State 170
		ACTIONS => {
			")" => 205
		}
	},
	{#State 171
		ACTIONS => {
			'ASSIGN' => 152,
			"(" => 109
		},
		DEFAULT => -70
	},
	{#State 172
		ACTIONS => {
			'BINOP' => 111
		},
		DEFAULT => -90
	},
	{#State 173
		DEFAULT => -93
	},
	{#State 174
		ACTIONS => {
			'BINOP' => 111
		},
		DEFAULT => -22
	},
	{#State 175
		DEFAULT => -62
	},
	{#State 176
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
			'WHILE' => 47,
			'REF' => 48
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
			'block' => 206,
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
			'directive' => 49
		}
	},
	{#State 177
		DEFAULT => -111
	},
	{#State 178
		DEFAULT => -112
	},
	{#State 179
		DEFAULT => -107
	},
	{#State 180
		ACTIONS => {
			'END' => 207
		}
	},
	{#State 181
		ACTIONS => {
			'BINOP' => 111
		},
		DEFAULT => -44
	},
	{#State 182
		ACTIONS => {
			"\"" => 38,
			"\$" => 40,
			'IDENT' => 171,
			"[" => 12,
			"{" => 30,
			'REF' => 48,
			"\${" => 34,
			'LITERAL' => 169
		},
		DEFAULT => -95,
		GOTOS => {
			'term' => 172,
			'param' => 167,
			'arg' => 173,
			'ident' => 50,
			'args' => 208,
			'arglist' => 168,
			'item' => 36
		}
	},
	{#State 183
		ACTIONS => {
			'BINOP' => 111
		},
		DEFAULT => -81
	},
	{#State 184
		ACTIONS => {
			'END' => 209
		}
	},
	{#State 185
		DEFAULT => -49
	},
	{#State 186
		ACTIONS => {
			")" => 210
		}
	},
	{#State 187
		ACTIONS => {
			"(" => 211,
			'DOT' => 115,
			"/" => 116
		},
		DEFAULT => -115
	},
	{#State 188
		ACTIONS => {
			'IDENT' => 214,
			'COMMA' => 213,
			")" => 212
		}
	},
	{#State 189
		DEFAULT => -98
	},
	{#State 190
		ACTIONS => {
			'COMPOP' => 142
		},
		DEFAULT => -101
	},
	{#State 191
		ACTIONS => {
			'COMPOP' => 142
		},
		DEFAULT => -100
	},
	{#State 192
		ACTIONS => {
			'ELSE' => 216,
			'ELSIF' => 215
		},
		DEFAULT => -39,
		GOTOS => {
			'else' => 217
		}
	},
	{#State 193
		DEFAULT => -99
	},
	{#State 194
		DEFAULT => -103
	},
	{#State 195
		ACTIONS => {
			'END' => 218
		}
	},
	{#State 196
		DEFAULT => -32
	},
	{#State 197
		ACTIONS => {
			'END' => 219
		}
	},
	{#State 198
		ACTIONS => {
			'BINOP' => 111
		},
		DEFAULT => -82
	},
	{#State 199
		ACTIONS => {
			'BINOP' => 111
		},
		DEFAULT => -83
	},
	{#State 200
		ACTIONS => {
			"\"" => 38,
			"\$" => 40,
			'IDENT' => 171,
			"[" => 12,
			"{" => 30,
			'REF' => 48,
			"\${" => 34,
			'LITERAL' => 169
		},
		DEFAULT => -95,
		GOTOS => {
			'term' => 172,
			'param' => 167,
			'arg' => 173,
			'ident' => 50,
			'args' => 220,
			'arglist' => 168,
			'item' => 36
		}
	},
	{#State 201
		ACTIONS => {
			'ELSE' => 216,
			'ELSIF' => 215
		},
		DEFAULT => -39,
		GOTOS => {
			'else' => 221
		}
	},
	{#State 202
		DEFAULT => -50
	},
	{#State 203
		DEFAULT => -92
	},
	{#State 204
		DEFAULT => -91
	},
	{#State 205
		DEFAULT => -69
	},
	{#State 206
		ACTIONS => {
			'END' => 222
		}
	},
	{#State 207
		DEFAULT => -40
	},
	{#State 208
		ACTIONS => {
			")" => 223
		}
	},
	{#State 209
		DEFAULT => -48
	},
	{#State 210
		DEFAULT => -116
	},
	{#State 211
		ACTIONS => {
			"\"" => 38,
			"\$" => 40,
			'IDENT' => 171,
			"[" => 12,
			"{" => 30,
			'REF' => 48,
			"\${" => 34,
			'LITERAL' => 169
		},
		DEFAULT => -95,
		GOTOS => {
			'term' => 172,
			'param' => 167,
			'arg' => 173,
			'ident' => 50,
			'args' => 224,
			'arglist' => 168,
			'item' => 36
		}
	},
	{#State 212
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
			'REF' => 48,
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
			'directive' => 225,
			'item' => 36
		}
	},
	{#State 213
		DEFAULT => -97
	},
	{#State 214
		DEFAULT => -96
	},
	{#State 215
		ACTIONS => {
			"\"" => 38,
			'NOT' => 80,
			"\$" => 40,
			'IDENT' => 44,
			"(" => 83,
			"[" => 12,
			"{" => 30,
			'REF' => 48,
			"\${" => 34,
			'LITERAL' => 35
		},
		GOTOS => {
			'term' => 84,
			'ident' => 17,
			'assign' => 82,
			'item' => 36,
			'expr' => 226
		}
	},
	{#State 216
		ACTIONS => {
			";" => 227
		}
	},
	{#State 217
		ACTIONS => {
			'END' => 228
		}
	},
	{#State 218
		DEFAULT => -31
	},
	{#State 219
		DEFAULT => -46
	},
	{#State 220
		ACTIONS => {
			")" => 229
		}
	},
	{#State 221
		ACTIONS => {
			'END' => 230
		}
	},
	{#State 222
		DEFAULT => -42
	},
	{#State 223
		DEFAULT => -59
	},
	{#State 224
		ACTIONS => {
			")" => 231
		}
	},
	{#State 225
		DEFAULT => -52
	},
	{#State 226
		ACTIONS => {
			";" => 232,
			'OR' => 139,
			'AND' => 140,
			'COMPOP' => 142
		}
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
			'WHILE' => 47,
			'REF' => 48
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
			'block' => 233,
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
			'directive' => 49
		}
	},
	{#State 228
		DEFAULT => -35
	},
	{#State 229
		DEFAULT => -68
	},
	{#State 230
		DEFAULT => -33
	},
	{#State 231
		DEFAULT => -114
	},
	{#State 232
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
			'WHILE' => 47,
			'REF' => 48
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
			'block' => 234,
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
			'directive' => 49
		}
	},
	{#State 233
		DEFAULT => -37
	},
	{#State 234
		ACTIONS => {
			'ELSE' => 216,
			'ELSIF' => 215
		},
		DEFAULT => -39,
		GOTOS => {
			'else' => 235
		}
	},
	{#State 235
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
		 'term', 2,
sub
#line 131 "Parser.yp"
{ [ OP_REF,     $_[2]    ] }
	],
	[#Rule 57
		 'term', 3,
sub
#line 132 "Parser.yp"
{ [ OP_RANGE,   $_[2]    ] }
	],
	[#Rule 58
		 'term', 3,
sub
#line 133 "Parser.yp"
{ [ OP_LIST,    $_[2]    ] }
	],
	[#Rule 59
		 'term', 6,
sub
#line 134 "Parser.yp"
{ [ OP_ITER,    @_[2, 5] ] }
	],
	[#Rule 60
		 'term', 3,
sub
#line 135 "Parser.yp"
{ [ OP_HASH,    $_[2]    ] }
	],
	[#Rule 61
		 'term', 3,
sub
#line 136 "Parser.yp"
{ [ OP_QUOTE,   $_[2]    ] }
	],
	[#Rule 62
		 'term', 3,
sub
#line 137 "Parser.yp"
{ push(@{$_[1]}, @{$_[3]}, 
						OP_BINOP, $_[2]); $_[1]  }
	],
	[#Rule 63
		 'ident', 3,
sub
#line 142 "Parser.yp"
{ push(@{$_[1]}, $_[3]); $_[1] }
	],
	[#Rule 64
		 'ident', 3,
sub
#line 143 "Parser.yp"
{ push(@{$_[1]}, [ $_[3], 0 ]); $_[1] }
	],
	[#Rule 65
		 'ident', 1,
sub
#line 144 "Parser.yp"
{ [ $_[1] ] }
	],
	[#Rule 66
		 'ident', 2,
sub
#line 145 "Parser.yp"
{ [ $_[2] ] }
	],
	[#Rule 67
		 'item', 3,
sub
#line 148 "Parser.yp"
{ [ $_[2], 0 ] }
	],
	[#Rule 68
		 'item', 6,
sub
#line 149 "Parser.yp"
{ [ @_[2, 5] ] }
	],
	[#Rule 69
		 'item', 4,
sub
#line 150 "Parser.yp"
{ [ @_[1, 3] ] }
	],
	[#Rule 70
		 'item', 1,
sub
#line 151 "Parser.yp"
{ [ $_[1], 0 ] }
	],
	[#Rule 71
		 'assign', 3,
sub
#line 154 "Parser.yp"
{ push(@{$_[3]}, OP_ASSIGN, $_[1]);
					  $_[3] }
	],
	[#Rule 72
		 'assign', 3,
sub
#line 156 "Parser.yp"
{ push(@{$_[3]}, OP_ASSIGN, $_[1]);
					  $_[3] }
	],
	[#Rule 73
		 'list', 2,
sub
#line 160 "Parser.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 74
		 'list', 2,
sub
#line 161 "Parser.yp"
{ $_[1] }
	],
	[#Rule 75
		 'list', 1,
sub
#line 162 "Parser.yp"
{ [ $_[1] ] }
	],
	[#Rule 76
		 'setlist', 2,
sub
#line 165 "Parser.yp"
{ push(@{$_[1]}, @{$_[2]}); $_[1] }
	],
	[#Rule 77
		 'setlist', 2,
sub
#line 166 "Parser.yp"
{ $_[1] }
	],
	[#Rule 78
		 'setlist', 1, undef
	],
	[#Rule 79
		 'setopt', 1, undef
	],
	[#Rule 80
		 'setopt', 0,
sub
#line 171 "Parser.yp"
{ [ ] }
	],
	[#Rule 81
		 'range', 3,
sub
#line 174 "Parser.yp"
{ [ @_[1, 3] ] }
	],
	[#Rule 82
		 'param', 3,
sub
#line 179 "Parser.yp"
{ [ $_[1], $_[3] ] }
	],
	[#Rule 83
		 'param', 3,
sub
#line 180 "Parser.yp"
{ [ $_[1], $_[3] ] }
	],
	[#Rule 84
		 'paramlist', 2,
sub
#line 183 "Parser.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 85
		 'paramlist', 2,
sub
#line 184 "Parser.yp"
{ $_[1] }
	],
	[#Rule 86
		 'paramlist', 1,
sub
#line 185 "Parser.yp"
{ [ $_[1] ] }
	],
	[#Rule 87
		 'params', 1, undef
	],
	[#Rule 88
		 'params', 0,
sub
#line 189 "Parser.yp"
{ [ ] }
	],
	[#Rule 89
		 'arg', 1, undef
	],
	[#Rule 90
		 'arg', 1,
sub
#line 193 "Parser.yp"
{ [ 0, $_[1] ] }
	],
	[#Rule 91
		 'arglist', 2,
sub
#line 196 "Parser.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 92
		 'arglist', 2,
sub
#line 197 "Parser.yp"
{ $_[1] }
	],
	[#Rule 93
		 'arglist', 1,
sub
#line 198 "Parser.yp"
{ [ $_[1] ] }
	],
	[#Rule 94
		 'args', 1,
sub
#line 201 "Parser.yp"
{ [ OP_ARGS, $_[1] ]  }
	],
	[#Rule 95
		 'args', 0,
sub
#line 202 "Parser.yp"
{ [ OP_ARGS, [ ] ] }
	],
	[#Rule 96
		 'mlist', 2,
sub
#line 206 "Parser.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 97
		 'mlist', 2,
sub
#line 207 "Parser.yp"
{ $_[1] }
	],
	[#Rule 98
		 'mlist', 1,
sub
#line 208 "Parser.yp"
{ [ $_[1] ] }
	],
	[#Rule 99
		 'expr', 3,
sub
#line 211 "Parser.yp"
{ push(@{$_[1]}, @{$_[3]}, 
						OP_BINOP, $_[2]); $_[1]  }
	],
	[#Rule 100
		 'expr', 3,
sub
#line 213 "Parser.yp"
{ push(@{$_[1]}, OP_AND, $_[3]); 
					  $_[1]                          }
	],
	[#Rule 101
		 'expr', 3,
sub
#line 215 "Parser.yp"
{ push(@{$_[1]}, OP_OR, $_[3]);
					  $_[1]                          }
	],
	[#Rule 102
		 'expr', 2,
sub
#line 217 "Parser.yp"
{ push(@{$_[2]}, OP_NOT);
					  $_[2]                          }
	],
	[#Rule 103
		 'expr', 3,
sub
#line 219 "Parser.yp"
{ $_[2]                          }
	],
	[#Rule 104
		 'expr', 1, undef
	],
	[#Rule 105
		 'expr', 1, undef
	],
	[#Rule 106
		 'file', 2,
sub
#line 229 "Parser.yp"
{ [ OP_IDENT, $_[2] ] }
	],
	[#Rule 107
		 'file', 3,
sub
#line 230 "Parser.yp"
{ [ OP_QUOTE, $_[2] ] }
	],
	[#Rule 108
		 'file', 2,
sub
#line 231 "Parser.yp"
{ '/' . $_[2]         }
	],
	[#Rule 109
		 'file', 1, undef
	],
	[#Rule 110
		 'file', 1, undef
	],
	[#Rule 111
		 'textdot', 3,
sub
#line 238 "Parser.yp"
{ $_[1] .= "$_[2]$_[3]"; $_[1] }
	],
	[#Rule 112
		 'textdot', 3,
sub
#line 239 "Parser.yp"
{ $_[1] .= "$_[2]$_[3]"; $_[1] }
	],
	[#Rule 113
		 'textdot', 1, undef
	],
	[#Rule 114
		 'useparam', 6,
sub
#line 245 "Parser.yp"
{ [ @_[3, 5, 1]         ] }
	],
	[#Rule 115
		 'useparam', 3,
sub
#line 246 "Parser.yp"
{ [ $_[3], undef, $_[1] ] }
	],
	[#Rule 116
		 'useparam', 4,
sub
#line 247 "Parser.yp"
{ [ $_[1], $_[3], undef ] }
	],
	[#Rule 117
		 'useparam', 1,
sub
#line 248 "Parser.yp"
{ [ $_[1], undef, undef ] }
	],
	[#Rule 118
		 'quoted', 2,
sub
#line 254 "Parser.yp"
{ push(@{$_[1]}, $_[2])
						if defined $_[2]; $_[1] }
	],
	[#Rule 119
		 'quoted', 0,
sub
#line 256 "Parser.yp"
{ [ ] }
	],
	[#Rule 120
		 'quotable', 1,
sub
#line 262 "Parser.yp"
{ [ OP_IDENT,   $_[1] ] }
	],
	[#Rule 121
		 'quotable', 1,
sub
#line 263 "Parser.yp"
{ [ OP_LITERAL, $_[1] ] }
	],
	[#Rule 122
		 'quotable', 1,
sub
#line 264 "Parser.yp"
{ undef }
	]
];



1;












