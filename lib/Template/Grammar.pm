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
# $Id: Grammar.pm,v 1.37 2000/02/07 18:29:57 abw Exp $
#
#========================================================================

package Template::Grammar;

require 5.004;

use strict;
use vars qw( $VERSION );

use Template::Constants qw( :ops :status );

$VERSION = sprintf("%d.%02d", q$Revision: 1.37 $ =~ /(\d+)\.(\d+)/);

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
			'GET' => 2,
			'UBLOCK' => 1,
			'INCLUDE' => 4,
			'TEXT' => 7,
			'DEFAULT' => 6,
			'BREAK' => 5,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 14,
			'SET' => 15,
			'USE' => 16,
			'MACRO' => 17,
			'UNLESS' => 20,
			'PROCESS' => 23,
			'RETURN' => 25,
			'CATCH' => 26,
			'FILTER' => 29,
			'DEBUG' => 30,
			";" => -16,
			"{" => 31,
			'ERROR' => 32,
			"\${" => 35,
			'LITERAL' => 36,
			'IF' => 39,
			"\"" => 40,
			"\$" => 42,
			'PERL' => 45,
			'IDENT' => 46,
			'THROW' => 47,
			'UDIR' => 48,
			'WHILE' => 50,
			'REF' => 51
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 24,
			'catch' => 3,
			'assign' => 27,
			'filter' => 28,
			'condition' => 11,
			'debug' => 10,
			'setlist' => 12,
			'block' => 33,
			'chunks' => 34,
			'userdef' => 37,
			'item' => 38,
			'atomdir' => 41,
			'macro' => 43,
			'perl' => 44,
			'ident' => 18,
			'term' => 49,
			'chunk' => 19,
			'defblock' => 22,
			'loop' => 21,
			'directive' => 52
		}
	},
	{#State 1
		ACTIONS => {
			";" => 53
		}
	},
	{#State 2
		ACTIONS => {
			"\"" => 40,
			"{" => 31,
			"[" => 13,
			"\$" => 42,
			'IDENT' => 46,
			'REF' => 51,
			'LITERAL' => 55,
			"\${" => 35
		},
		GOTOS => {
			'term' => 56,
			'ident' => 54,
			'item' => 38
		}
	},
	{#State 3
		DEFAULT => -8
	},
	{#State 4
		ACTIONS => {
			"\"" => 61,
			"\$" => 62,
			'IDENT' => 63,
			'LITERAL' => 60,
			"/" => 58
		},
		GOTOS => {
			'file' => 59,
			'textdot' => 57
		}
	},
	{#State 5
		DEFAULT => -31
	},
	{#State 6
		ACTIONS => {
			"\$" => 42,
			'IDENT' => 46,
			"\${" => 35,
			'LITERAL' => 66
		},
		GOTOS => {
			'setlist' => 64,
			'ident' => 65,
			'assign' => 27,
			'item' => 38
		}
	},
	{#State 7
		DEFAULT => -5
	},
	{#State 8
		DEFAULT => -30
	},
	{#State 9
		ACTIONS => {
			"\"" => 40,
			"{" => 31,
			"[" => 13,
			"\$" => 42,
			'IDENT' => 68,
			'REF' => 51,
			'LITERAL' => 55,
			"\${" => 35
		},
		GOTOS => {
			'term' => 69,
			'loopvar' => 67,
			'ident' => 54,
			'item' => 38
		}
	},
	{#State 10
		DEFAULT => -15
	},
	{#State 11
		DEFAULT => -9
	},
	{#State 12
		ACTIONS => {
			"\$" => 42,
			'IDENT' => 46,
			'LITERAL' => 66,
			"\${" => 35,
			'COMMA' => 71
		},
		DEFAULT => -26,
		GOTOS => {
			'ident' => 65,
			'assign' => 70,
			'item' => 38
		}
	},
	{#State 13
		ACTIONS => {
			"\"" => 40,
			"{" => 31,
			"[" => 13,
			"\$" => 42,
			'IDENT' => 46,
			'REF' => 51,
			'LITERAL' => 55,
			"\${" => 35
		},
		GOTOS => {
			'term' => 74,
			'list' => 73,
			'ident' => 54,
			'range' => 72,
			'item' => 38
		}
	},
	{#State 14
		ACTIONS => {
			";" => 76,
			'IDENT' => 63
		},
		GOTOS => {
			'textdot' => 75
		}
	},
	{#State 15
		ACTIONS => {
			"\$" => 42,
			'IDENT' => 46,
			"\${" => 35,
			'LITERAL' => 66
		},
		GOTOS => {
			'setlist' => 77,
			'ident' => 65,
			'assign' => 27,
			'item' => 38
		}
	},
	{#State 16
		ACTIONS => {
			'IDENT' => 80
		},
		GOTOS => {
			'textdot' => 78,
			'useparam' => 79
		}
	},
	{#State 17
		ACTIONS => {
			'IDENT' => 81
		}
	},
	{#State 18
		ACTIONS => {
			'ASSIGN' => 83,
			'DOT' => 82
		},
		DEFAULT => -58
	},
	{#State 19
		DEFAULT => -4
	},
	{#State 20
		ACTIONS => {
			"\"" => 40,
			'NOT' => 84,
			"\$" => 42,
			'IDENT' => 46,
			"(" => 87,
			"[" => 13,
			"{" => 31,
			'REF' => 51,
			"\${" => 35,
			'LITERAL' => 36
		},
		GOTOS => {
			'term' => 88,
			'ident' => 18,
			'assign' => 86,
			'item' => 38,
			'expr' => 85
		}
	},
	{#State 21
		DEFAULT => -10
	},
	{#State 22
		DEFAULT => -11
	},
	{#State 23
		ACTIONS => {
			"\"" => 61,
			"\$" => 62,
			'IDENT' => 63,
			'LITERAL' => 60,
			"/" => 58
		},
		GOTOS => {
			'file' => 89,
			'textdot' => 57
		}
	},
	{#State 24
		DEFAULT => -25
	},
	{#State 25
		DEFAULT => -29
	},
	{#State 26
		ACTIONS => {
			";" => 91,
			'IDENT' => 63
		},
		GOTOS => {
			'textdot' => 90
		}
	},
	{#State 27
		DEFAULT => -81
	},
	{#State 28
		DEFAULT => -28
	},
	{#State 29
		ACTIONS => {
			'IDENT' => 80
		},
		GOTOS => {
			'textdot' => 78,
			'useparam' => 92
		}
	},
	{#State 30
		ACTIONS => {
			'TEXT' => 93
		}
	},
	{#State 31
		ACTIONS => {
			'IDENT' => 98,
			'LITERAL' => 97
		},
		DEFAULT => -91,
		GOTOS => {
			'param' => 94,
			'params' => 95,
			'paramlist' => 96
		}
	},
	{#State 32
		ACTIONS => {
			"\"" => 40,
			"{" => 31,
			"[" => 13,
			"\$" => 42,
			'IDENT' => 46,
			'REF' => 51,
			'LITERAL' => 55,
			"\${" => 35
		},
		GOTOS => {
			'term' => 99,
			'ident' => 54,
			'item' => 38
		}
	},
	{#State 33
		ACTIONS => {
			'' => 100
		}
	},
	{#State 34
		ACTIONS => {
			'GET' => 2,
			'UBLOCK' => 1,
			'INCLUDE' => 4,
			'TEXT' => 7,
			'DEFAULT' => 6,
			'BREAK' => 5,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 14,
			'SET' => 15,
			'USE' => 16,
			'MACRO' => 17,
			'UNLESS' => 20,
			'PROCESS' => 23,
			'RETURN' => 25,
			'CATCH' => 26,
			'FILTER' => 29,
			'DEBUG' => 30,
			";" => -16,
			"{" => 31,
			'ERROR' => 32,
			"\${" => 35,
			'LITERAL' => 36,
			'IF' => 39,
			"\"" => 40,
			"\$" => 42,
			'PERL' => 45,
			'IDENT' => 46,
			'UDIR' => 48,
			'THROW' => 47,
			'WHILE' => 50,
			'REF' => 51
		},
		DEFAULT => -1,
		GOTOS => {
			'atomdir' => 41,
			'return' => 24,
			'macro' => 43,
			'perl' => 44,
			'catch' => 3,
			'ident' => 18,
			'assign' => 27,
			'filter' => 28,
			'condition' => 11,
			'debug' => 10,
			'term' => 49,
			'setlist' => 12,
			'chunk' => 101,
			'defblock' => 22,
			'loop' => 21,
			'userdef' => 37,
			'directive' => 52,
			'item' => 38
		}
	},
	{#State 35
		ACTIONS => {
			"\"" => 40,
			"{" => 31,
			"[" => 13,
			"\$" => 42,
			'IDENT' => 46,
			'REF' => 51,
			'LITERAL' => 55,
			"\${" => 35
		},
		GOTOS => {
			'term' => 102,
			'ident' => 54,
			'item' => 38
		}
	},
	{#State 36
		ACTIONS => {
			'ASSIGN' => 103
		},
		DEFAULT => -57
	},
	{#State 37
		DEFAULT => -14
	},
	{#State 38
		DEFAULT => -68
	},
	{#State 39
		ACTIONS => {
			"\"" => 40,
			'NOT' => 84,
			"\$" => 42,
			'IDENT' => 46,
			"(" => 87,
			"[" => 13,
			"{" => 31,
			'REF' => 51,
			"\${" => 35,
			'LITERAL' => 36
		},
		GOTOS => {
			'term' => 88,
			'ident' => 18,
			'assign' => 86,
			'item' => 38,
			'expr' => 104
		}
	},
	{#State 40
		DEFAULT => -122,
		GOTOS => {
			'quoted' => 105
		}
	},
	{#State 41
		ACTIONS => {
			'WHILE' => 110,
			'UNLESS' => 107,
			'FILTER' => 108,
			'IF' => 109,
			'FOR' => 106
		},
		DEFAULT => -7
	},
	{#State 42
		ACTIONS => {
			'IDENT' => 46,
			"\${" => 35
		},
		GOTOS => {
			'item' => 111
		}
	},
	{#State 43
		DEFAULT => -13
	},
	{#State 44
		DEFAULT => -12
	},
	{#State 45
		ACTIONS => {
			";" => 112
		}
	},
	{#State 46
		ACTIONS => {
			"(" => 113
		},
		DEFAULT => -73
	},
	{#State 47
		ACTIONS => {
			'IDENT' => 63
		},
		GOTOS => {
			'textdot' => 114
		}
	},
	{#State 48
		DEFAULT => -54
	},
	{#State 49
		ACTIONS => {
			'BINOP' => 115
		},
		DEFAULT => -27
	},
	{#State 50
		ACTIONS => {
			"\"" => 40,
			'NOT' => 84,
			"\$" => 42,
			'IDENT' => 46,
			"(" => 87,
			"[" => 13,
			"{" => 31,
			'REF' => 51,
			"\${" => 35,
			'LITERAL' => 36
		},
		GOTOS => {
			'term' => 88,
			'ident' => 18,
			'assign' => 86,
			'item' => 38,
			'expr' => 116
		}
	},
	{#State 51
		ACTIONS => {
			"\$" => 42,
			'IDENT' => 46,
			"\${" => 35
		},
		GOTOS => {
			'ident' => 117,
			'item' => 38
		}
	},
	{#State 52
		ACTIONS => {
			";" => 118
		}
	},
	{#State 53
		ACTIONS => {
			'GET' => 2,
			'UBLOCK' => 1,
			'INCLUDE' => 4,
			'TEXT' => 7,
			'DEFAULT' => 6,
			'BREAK' => 5,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 14,
			'SET' => 15,
			'USE' => 16,
			'MACRO' => 17,
			'UNLESS' => 20,
			'PROCESS' => 23,
			'RETURN' => 25,
			'CATCH' => 26,
			'FILTER' => 29,
			'DEBUG' => 30,
			";" => -16,
			"{" => 31,
			'ERROR' => 32,
			"\${" => 35,
			'LITERAL' => 36,
			'IF' => 39,
			"\"" => 40,
			"\$" => 42,
			'PERL' => 45,
			'IDENT' => 46,
			'UDIR' => 48,
			'THROW' => 47,
			'WHILE' => 50,
			'REF' => 51
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 24,
			'catch' => 3,
			'assign' => 27,
			'filter' => 28,
			'condition' => 11,
			'debug' => 10,
			'setlist' => 12,
			'block' => 119,
			'chunks' => 34,
			'userdef' => 37,
			'item' => 38,
			'atomdir' => 41,
			'macro' => 43,
			'perl' => 44,
			'ident' => 18,
			'term' => 49,
			'chunk' => 19,
			'loop' => 21,
			'defblock' => 22,
			'directive' => 52
		}
	},
	{#State 54
		ACTIONS => {
			'DOT' => 82
		},
		DEFAULT => -58
	},
	{#State 55
		DEFAULT => -57
	},
	{#State 56
		ACTIONS => {
			'BINOP' => 115
		},
		DEFAULT => -17
	},
	{#State 57
		ACTIONS => {
			'DOT' => 120,
			"/" => 121
		},
		DEFAULT => -112
	},
	{#State 58
		ACTIONS => {
			'IDENT' => 63
		},
		GOTOS => {
			'textdot' => 122
		}
	},
	{#State 59
		ACTIONS => {
			"\$" => 42,
			'IDENT' => 46,
			'LITERAL' => 66,
			"\${" => 35
		},
		DEFAULT => -83,
		GOTOS => {
			'setlist' => 123,
			'ident' => 65,
			'assign' => 27,
			'setopt' => 124,
			'item' => 38
		}
	},
	{#State 60
		DEFAULT => -113
	},
	{#State 61
		DEFAULT => -122,
		GOTOS => {
			'quoted' => 125
		}
	},
	{#State 62
		ACTIONS => {
			"\$" => 42,
			'IDENT' => 46,
			"\${" => 35
		},
		GOTOS => {
			'ident' => 126,
			'item' => 38
		}
	},
	{#State 63
		DEFAULT => -116
	},
	{#State 64
		ACTIONS => {
			"\$" => 42,
			'IDENT' => 46,
			'LITERAL' => 66,
			"\${" => 35,
			'COMMA' => 71
		},
		DEFAULT => -19,
		GOTOS => {
			'ident' => 65,
			'assign' => 70,
			'item' => 38
		}
	},
	{#State 65
		ACTIONS => {
			'ASSIGN' => 83,
			'DOT' => 82
		}
	},
	{#State 66
		ACTIONS => {
			'ASSIGN' => 103
		}
	},
	{#State 67
		ACTIONS => {
			";" => 127
		}
	},
	{#State 68
		ACTIONS => {
			'ASSIGN' => 128,
			"(" => 113
		},
		DEFAULT => -73
	},
	{#State 69
		ACTIONS => {
			'BINOP' => 115
		},
		DEFAULT => -46
	},
	{#State 70
		DEFAULT => -79
	},
	{#State 71
		DEFAULT => -80
	},
	{#State 72
		ACTIONS => {
			"]" => 129
		}
	},
	{#State 73
		ACTIONS => {
			"\"" => 40,
			"\$" => 42,
			'IDENT' => 46,
			"[" => 13,
			"{" => 31,
			"]" => 130,
			'REF' => 51,
			"\${" => 35,
			'LITERAL' => 55,
			'COMMA' => 131
		},
		GOTOS => {
			'term' => 132,
			'ident' => 54,
			'item' => 38
		}
	},
	{#State 74
		ACTIONS => {
			'TO' => 133,
			'BINOP' => 115
		},
		DEFAULT => -78
	},
	{#State 75
		ACTIONS => {
			";" => 134,
			"/" => 121,
			'DOT' => 120
		}
	},
	{#State 76
		ACTIONS => {
			'GET' => 2,
			'UBLOCK' => 1,
			'INCLUDE' => 4,
			'TEXT' => 7,
			'DEFAULT' => 6,
			'BREAK' => 5,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 14,
			'SET' => 15,
			'USE' => 16,
			'MACRO' => 17,
			'UNLESS' => 20,
			'PROCESS' => 23,
			'RETURN' => 25,
			'CATCH' => 26,
			'FILTER' => 29,
			'DEBUG' => 30,
			";" => -16,
			"{" => 31,
			'ERROR' => 32,
			"\${" => 35,
			'LITERAL' => 36,
			'IF' => 39,
			"\"" => 40,
			"\$" => 42,
			'PERL' => 45,
			'IDENT' => 46,
			'UDIR' => 48,
			'THROW' => 47,
			'WHILE' => 50,
			'REF' => 51
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 24,
			'catch' => 3,
			'assign' => 27,
			'filter' => 28,
			'condition' => 11,
			'debug' => 10,
			'setlist' => 12,
			'block' => 135,
			'chunks' => 34,
			'userdef' => 37,
			'item' => 38,
			'atomdir' => 41,
			'macro' => 43,
			'perl' => 44,
			'ident' => 18,
			'term' => 49,
			'chunk' => 19,
			'loop' => 21,
			'defblock' => 22,
			'directive' => 52
		}
	},
	{#State 77
		ACTIONS => {
			"\$" => 42,
			'IDENT' => 46,
			'LITERAL' => 66,
			"\${" => 35,
			'COMMA' => 71
		},
		DEFAULT => -18,
		GOTOS => {
			'ident' => 65,
			'assign' => 70,
			'item' => 38
		}
	},
	{#State 78
		ACTIONS => {
			"(" => 136,
			'DOT' => 120,
			"/" => 121
		},
		DEFAULT => -120
	},
	{#State 79
		DEFAULT => -20
	},
	{#State 80
		ACTIONS => {
			'ASSIGN' => 137
		},
		DEFAULT => -116
	},
	{#State 81
		ACTIONS => {
			'GET' => 2,
			'UBLOCK' => 1,
			'INCLUDE' => 4,
			'DEFAULT' => 6,
			'BREAK' => 5,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 14,
			'SET' => 15,
			'USE' => 16,
			'MACRO' => 17,
			'UNLESS' => 20,
			'PROCESS' => 23,
			'RETURN' => 25,
			'CATCH' => 26,
			'FILTER' => 29,
			'DEBUG' => 30,
			"{" => 31,
			'ERROR' => 32,
			"\${" => 35,
			'LITERAL' => 36,
			'IF' => 39,
			"\"" => 40,
			"\$" => 42,
			'PERL' => 45,
			'IDENT' => 46,
			'UDIR' => 48,
			'THROW' => 47,
			"(" => 138,
			'WHILE' => 50,
			'REF' => 51
		},
		DEFAULT => -16,
		GOTOS => {
			'atomdir' => 41,
			'return' => 24,
			'macro' => 43,
			'perl' => 44,
			'catch' => 3,
			'ident' => 18,
			'assign' => 27,
			'filter' => 28,
			'condition' => 11,
			'debug' => 10,
			'term' => 49,
			'setlist' => 12,
			'defblock' => 22,
			'loop' => 21,
			'userdef' => 37,
			'directive' => 139,
			'item' => 38
		}
	},
	{#State 82
		ACTIONS => {
			'IDENT' => 46,
			'LITERAL' => 140,
			"\${" => 35
		},
		GOTOS => {
			'item' => 141
		}
	},
	{#State 83
		ACTIONS => {
			"\"" => 40,
			"{" => 31,
			"[" => 13,
			"\$" => 42,
			'IDENT' => 46,
			'REF' => 51,
			'LITERAL' => 55,
			"\${" => 35
		},
		GOTOS => {
			'term' => 142,
			'ident' => 54,
			'item' => 38
		}
	},
	{#State 84
		ACTIONS => {
			"\"" => 40,
			'NOT' => 84,
			"\$" => 42,
			'IDENT' => 46,
			"(" => 87,
			"[" => 13,
			"{" => 31,
			'REF' => 51,
			"\${" => 35,
			'LITERAL' => 36
		},
		GOTOS => {
			'term' => 88,
			'ident' => 18,
			'assign' => 86,
			'item' => 38,
			'expr' => 143
		}
	},
	{#State 85
		ACTIONS => {
			";" => 146,
			'OR' => 144,
			'AND' => 145,
			'COMPOP' => 147
		}
	},
	{#State 86
		DEFAULT => -107
	},
	{#State 87
		ACTIONS => {
			"\"" => 40,
			'NOT' => 84,
			"\$" => 42,
			'IDENT' => 46,
			"(" => 87,
			"[" => 13,
			"{" => 31,
			'REF' => 51,
			"\${" => 35,
			'LITERAL' => 36
		},
		GOTOS => {
			'term' => 88,
			'ident' => 18,
			'assign' => 86,
			'item' => 38,
			'expr' => 148
		}
	},
	{#State 88
		ACTIONS => {
			'BINOP' => 115
		},
		DEFAULT => -108
	},
	{#State 89
		ACTIONS => {
			"\$" => 42,
			'IDENT' => 46,
			'LITERAL' => 66,
			"\${" => 35
		},
		DEFAULT => -83,
		GOTOS => {
			'setlist' => 123,
			'ident' => 65,
			'assign' => 27,
			'setopt' => 149,
			'item' => 38
		}
	},
	{#State 90
		ACTIONS => {
			";" => 150,
			"/" => 121,
			'DOT' => 120
		}
	},
	{#State 91
		ACTIONS => {
			'GET' => 2,
			'UBLOCK' => 1,
			'INCLUDE' => 4,
			'TEXT' => 7,
			'DEFAULT' => 6,
			'BREAK' => 5,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 14,
			'SET' => 15,
			'USE' => 16,
			'MACRO' => 17,
			'UNLESS' => 20,
			'PROCESS' => 23,
			'RETURN' => 25,
			'CATCH' => 26,
			'FILTER' => 29,
			'DEBUG' => 30,
			";" => -16,
			"{" => 31,
			'ERROR' => 32,
			"\${" => 35,
			'LITERAL' => 36,
			'IF' => 39,
			"\"" => 40,
			"\$" => 42,
			'PERL' => 45,
			'IDENT' => 46,
			'UDIR' => 48,
			'THROW' => 47,
			'WHILE' => 50,
			'REF' => 51
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 24,
			'catch' => 3,
			'assign' => 27,
			'filter' => 28,
			'condition' => 11,
			'debug' => 10,
			'setlist' => 12,
			'block' => 151,
			'chunks' => 34,
			'userdef' => 37,
			'item' => 38,
			'atomdir' => 41,
			'macro' => 43,
			'perl' => 44,
			'ident' => 18,
			'term' => 49,
			'chunk' => 19,
			'loop' => 21,
			'defblock' => 22,
			'directive' => 52
		}
	},
	{#State 92
		ACTIONS => {
			";" => 152
		}
	},
	{#State 93
		DEFAULT => -56
	},
	{#State 94
		DEFAULT => -89
	},
	{#State 95
		ACTIONS => {
			"}" => 153
		}
	},
	{#State 96
		ACTIONS => {
			'IDENT' => 98,
			'COMMA' => 155,
			'LITERAL' => 97
		},
		DEFAULT => -90,
		GOTOS => {
			'param' => 154
		}
	},
	{#State 97
		ACTIONS => {
			'ASSIGN' => 156
		}
	},
	{#State 98
		ACTIONS => {
			'ASSIGN' => 157
		}
	},
	{#State 99
		ACTIONS => {
			'BINOP' => 115
		},
		DEFAULT => -24
	},
	{#State 100
		DEFAULT => -0
	},
	{#State 101
		DEFAULT => -3
	},
	{#State 102
		ACTIONS => {
			'BINOP' => 115,
			"}" => 158
		}
	},
	{#State 103
		ACTIONS => {
			"\"" => 40,
			"{" => 31,
			"[" => 13,
			"\$" => 42,
			'IDENT' => 46,
			'REF' => 51,
			'LITERAL' => 55,
			"\${" => 35
		},
		GOTOS => {
			'term' => 159,
			'ident' => 54,
			'item' => 38
		}
	},
	{#State 104
		ACTIONS => {
			";" => 160,
			'OR' => 144,
			'AND' => 145,
			'COMPOP' => 147
		}
	},
	{#State 105
		ACTIONS => {
			"\"" => 164,
			";" => 163,
			"\$" => 42,
			'IDENT' => 46,
			"\${" => 35,
			'TEXT' => 161
		},
		GOTOS => {
			'ident' => 162,
			'quotable' => 165,
			'item' => 38
		}
	},
	{#State 106
		ACTIONS => {
			"\"" => 40,
			"{" => 31,
			"[" => 13,
			"\$" => 42,
			'IDENT' => 68,
			'REF' => 51,
			'LITERAL' => 55,
			"\${" => 35
		},
		GOTOS => {
			'term' => 69,
			'loopvar' => 166,
			'ident' => 54,
			'item' => 38
		}
	},
	{#State 107
		ACTIONS => {
			"\"" => 40,
			'NOT' => 84,
			"\$" => 42,
			'IDENT' => 46,
			"(" => 87,
			"[" => 13,
			"{" => 31,
			'REF' => 51,
			"\${" => 35,
			'LITERAL' => 36
		},
		GOTOS => {
			'term' => 88,
			'ident' => 18,
			'assign' => 86,
			'item' => 38,
			'expr' => 167
		}
	},
	{#State 108
		ACTIONS => {
			'IDENT' => 80
		},
		GOTOS => {
			'textdot' => 78,
			'useparam' => 168
		}
	},
	{#State 109
		ACTIONS => {
			"\"" => 40,
			'NOT' => 84,
			"\$" => 42,
			'IDENT' => 46,
			"(" => 87,
			"[" => 13,
			"{" => 31,
			'REF' => 51,
			"\${" => 35,
			'LITERAL' => 36
		},
		GOTOS => {
			'term' => 88,
			'ident' => 18,
			'assign' => 86,
			'item' => 38,
			'expr' => 169
		}
	},
	{#State 110
		ACTIONS => {
			"\"" => 40,
			'NOT' => 84,
			"\$" => 42,
			'IDENT' => 46,
			"(" => 87,
			"[" => 13,
			"{" => 31,
			'REF' => 51,
			"\${" => 35,
			'LITERAL' => 36
		},
		GOTOS => {
			'term' => 88,
			'ident' => 18,
			'assign' => 86,
			'item' => 38,
			'expr' => 170
		}
	},
	{#State 111
		DEFAULT => -69
	},
	{#State 112
		ACTIONS => {
			'GET' => 2,
			'UBLOCK' => 1,
			'INCLUDE' => 4,
			'TEXT' => 7,
			'DEFAULT' => 6,
			'BREAK' => 5,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 14,
			'SET' => 15,
			'USE' => 16,
			'MACRO' => 17,
			'UNLESS' => 20,
			'PROCESS' => 23,
			'RETURN' => 25,
			'CATCH' => 26,
			'FILTER' => 29,
			'DEBUG' => 30,
			";" => -16,
			"{" => 31,
			'ERROR' => 32,
			"\${" => 35,
			'LITERAL' => 36,
			'IF' => 39,
			"\"" => 40,
			"\$" => 42,
			'PERL' => 45,
			'IDENT' => 46,
			'UDIR' => 48,
			'THROW' => 47,
			'WHILE' => 50,
			'REF' => 51
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 24,
			'catch' => 3,
			'assign' => 27,
			'filter' => 28,
			'condition' => 11,
			'debug' => 10,
			'setlist' => 12,
			'block' => 171,
			'chunks' => 34,
			'userdef' => 37,
			'item' => 38,
			'atomdir' => 41,
			'macro' => 43,
			'perl' => 44,
			'ident' => 18,
			'term' => 49,
			'chunk' => 19,
			'loop' => 21,
			'defblock' => 22,
			'directive' => 52
		}
	},
	{#State 113
		ACTIONS => {
			"\"" => 40,
			"\$" => 42,
			'IDENT' => 176,
			"[" => 13,
			"{" => 31,
			'REF' => 51,
			"\${" => 35,
			'LITERAL' => 174
		},
		DEFAULT => -98,
		GOTOS => {
			'term' => 177,
			'param' => 172,
			'arg' => 178,
			'ident' => 54,
			'args' => 175,
			'arglist' => 173,
			'item' => 38
		}
	},
	{#State 114
		ACTIONS => {
			"\"" => 40,
			"\$" => 42,
			'IDENT' => 46,
			'DOT' => 120,
			"[" => 13,
			"{" => 31,
			'REF' => 51,
			"/" => 121,
			"\${" => 35,
			'LITERAL' => 55
		},
		GOTOS => {
			'term' => 179,
			'ident' => 54,
			'item' => 38
		}
	},
	{#State 115
		ACTIONS => {
			"\"" => 40,
			"{" => 31,
			"[" => 13,
			"\$" => 42,
			'IDENT' => 46,
			'REF' => 51,
			'LITERAL' => 55,
			"\${" => 35
		},
		GOTOS => {
			'term' => 180,
			'ident' => 54,
			'item' => 38
		}
	},
	{#State 116
		ACTIONS => {
			";" => 181,
			'OR' => 144,
			'AND' => 145,
			'COMPOP' => 147
		}
	},
	{#State 117
		ACTIONS => {
			'DOT' => 82
		},
		DEFAULT => -59
	},
	{#State 118
		DEFAULT => -6
	},
	{#State 119
		ACTIONS => {
			'END' => 182
		}
	},
	{#State 120
		ACTIONS => {
			'IDENT' => 183
		}
	},
	{#State 121
		ACTIONS => {
			'IDENT' => 184
		}
	},
	{#State 122
		ACTIONS => {
			'DOT' => 120,
			"/" => 121
		},
		DEFAULT => -111
	},
	{#State 123
		ACTIONS => {
			"\$" => 42,
			'IDENT' => 46,
			'LITERAL' => 66,
			"\${" => 35,
			'COMMA' => 71
		},
		DEFAULT => -82,
		GOTOS => {
			'ident' => 65,
			'assign' => 70,
			'item' => 38
		}
	},
	{#State 124
		DEFAULT => -21
	},
	{#State 125
		ACTIONS => {
			"\"" => 185,
			";" => 163,
			"\$" => 42,
			'IDENT' => 46,
			"\${" => 35,
			'TEXT' => 161
		},
		GOTOS => {
			'ident' => 162,
			'quotable' => 165,
			'item' => 38
		}
	},
	{#State 126
		ACTIONS => {
			'DOT' => 82
		},
		DEFAULT => -109
	},
	{#State 127
		ACTIONS => {
			'GET' => 2,
			'UBLOCK' => 1,
			'INCLUDE' => 4,
			'TEXT' => 7,
			'DEFAULT' => 6,
			'BREAK' => 5,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 14,
			'SET' => 15,
			'USE' => 16,
			'MACRO' => 17,
			'UNLESS' => 20,
			'PROCESS' => 23,
			'RETURN' => 25,
			'CATCH' => 26,
			'FILTER' => 29,
			'DEBUG' => 30,
			";" => -16,
			"{" => 31,
			'ERROR' => 32,
			"\${" => 35,
			'LITERAL' => 36,
			'IF' => 39,
			"\"" => 40,
			"\$" => 42,
			'PERL' => 45,
			'IDENT' => 46,
			'UDIR' => 48,
			'THROW' => 47,
			'WHILE' => 50,
			'REF' => 51
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 24,
			'catch' => 3,
			'assign' => 27,
			'filter' => 28,
			'condition' => 11,
			'debug' => 10,
			'setlist' => 12,
			'block' => 186,
			'chunks' => 34,
			'userdef' => 37,
			'item' => 38,
			'atomdir' => 41,
			'macro' => 43,
			'perl' => 44,
			'ident' => 18,
			'term' => 49,
			'chunk' => 19,
			'loop' => 21,
			'defblock' => 22,
			'directive' => 52
		}
	},
	{#State 128
		ACTIONS => {
			"\"" => 40,
			"{" => 31,
			"[" => 13,
			"\$" => 42,
			'IDENT' => 46,
			'REF' => 51,
			'LITERAL' => 55,
			"\${" => 35
		},
		GOTOS => {
			'term' => 187,
			'ident' => 54,
			'item' => 38
		}
	},
	{#State 129
		DEFAULT => -60
	},
	{#State 130
		ACTIONS => {
			"(" => 188
		},
		DEFAULT => -61
	},
	{#State 131
		DEFAULT => -77
	},
	{#State 132
		ACTIONS => {
			'BINOP' => 115
		},
		DEFAULT => -76
	},
	{#State 133
		ACTIONS => {
			"\"" => 40,
			"{" => 31,
			"[" => 13,
			"\$" => 42,
			'IDENT' => 46,
			'REF' => 51,
			'LITERAL' => 55,
			"\${" => 35
		},
		GOTOS => {
			'term' => 189,
			'ident' => 54,
			'item' => 38
		}
	},
	{#State 134
		ACTIONS => {
			'GET' => 2,
			'UBLOCK' => 1,
			'INCLUDE' => 4,
			'TEXT' => 7,
			'DEFAULT' => 6,
			'BREAK' => 5,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 14,
			'SET' => 15,
			'USE' => 16,
			'MACRO' => 17,
			'UNLESS' => 20,
			'PROCESS' => 23,
			'RETURN' => 25,
			'CATCH' => 26,
			'FILTER' => 29,
			'DEBUG' => 30,
			";" => -16,
			"{" => 31,
			'ERROR' => 32,
			"\${" => 35,
			'LITERAL' => 36,
			'IF' => 39,
			"\"" => 40,
			"\$" => 42,
			'PERL' => 45,
			'IDENT' => 46,
			'UDIR' => 48,
			'THROW' => 47,
			'WHILE' => 50,
			'REF' => 51
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 24,
			'catch' => 3,
			'assign' => 27,
			'filter' => 28,
			'condition' => 11,
			'debug' => 10,
			'setlist' => 12,
			'block' => 190,
			'chunks' => 34,
			'userdef' => 37,
			'item' => 38,
			'atomdir' => 41,
			'macro' => 43,
			'perl' => 44,
			'ident' => 18,
			'term' => 49,
			'chunk' => 19,
			'loop' => 21,
			'defblock' => 22,
			'directive' => 52
		}
	},
	{#State 135
		ACTIONS => {
			'END' => 191
		}
	},
	{#State 136
		ACTIONS => {
			"\"" => 40,
			"\$" => 42,
			'IDENT' => 176,
			"[" => 13,
			"{" => 31,
			'REF' => 51,
			"\${" => 35,
			'LITERAL' => 174
		},
		DEFAULT => -98,
		GOTOS => {
			'term' => 177,
			'param' => 172,
			'arg' => 178,
			'ident' => 54,
			'args' => 192,
			'arglist' => 173,
			'item' => 38
		}
	},
	{#State 137
		ACTIONS => {
			'IDENT' => 63
		},
		GOTOS => {
			'textdot' => 193
		}
	},
	{#State 138
		ACTIONS => {
			'IDENT' => 195
		},
		GOTOS => {
			'mlist' => 194
		}
	},
	{#State 139
		DEFAULT => -52
	},
	{#State 140
		DEFAULT => -67
	},
	{#State 141
		DEFAULT => -66
	},
	{#State 142
		ACTIONS => {
			'BINOP' => 115
		},
		DEFAULT => -74
	},
	{#State 143
		ACTIONS => {
			'COMPOP' => 147
		},
		DEFAULT => -105
	},
	{#State 144
		ACTIONS => {
			"\"" => 40,
			'NOT' => 84,
			"\$" => 42,
			'IDENT' => 46,
			"(" => 87,
			"[" => 13,
			"{" => 31,
			'REF' => 51,
			"\${" => 35,
			'LITERAL' => 36
		},
		GOTOS => {
			'term' => 88,
			'ident' => 18,
			'assign' => 86,
			'item' => 38,
			'expr' => 196
		}
	},
	{#State 145
		ACTIONS => {
			"\"" => 40,
			'NOT' => 84,
			"\$" => 42,
			'IDENT' => 46,
			"(" => 87,
			"[" => 13,
			"{" => 31,
			'REF' => 51,
			"\${" => 35,
			'LITERAL' => 36
		},
		GOTOS => {
			'term' => 88,
			'ident' => 18,
			'assign' => 86,
			'item' => 38,
			'expr' => 197
		}
	},
	{#State 146
		ACTIONS => {
			'GET' => 2,
			'UBLOCK' => 1,
			'INCLUDE' => 4,
			'TEXT' => 7,
			'DEFAULT' => 6,
			'BREAK' => 5,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 14,
			'SET' => 15,
			'USE' => 16,
			'MACRO' => 17,
			'UNLESS' => 20,
			'PROCESS' => 23,
			'RETURN' => 25,
			'CATCH' => 26,
			'FILTER' => 29,
			'DEBUG' => 30,
			";" => -16,
			"{" => 31,
			'ERROR' => 32,
			"\${" => 35,
			'LITERAL' => 36,
			'IF' => 39,
			"\"" => 40,
			"\$" => 42,
			'PERL' => 45,
			'IDENT' => 46,
			'UDIR' => 48,
			'THROW' => 47,
			'WHILE' => 50,
			'REF' => 51
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 24,
			'catch' => 3,
			'assign' => 27,
			'filter' => 28,
			'condition' => 11,
			'debug' => 10,
			'setlist' => 12,
			'block' => 198,
			'chunks' => 34,
			'userdef' => 37,
			'item' => 38,
			'atomdir' => 41,
			'macro' => 43,
			'perl' => 44,
			'ident' => 18,
			'term' => 49,
			'chunk' => 19,
			'loop' => 21,
			'defblock' => 22,
			'directive' => 52
		}
	},
	{#State 147
		ACTIONS => {
			"\"" => 40,
			'NOT' => 84,
			"\$" => 42,
			'IDENT' => 46,
			"(" => 87,
			"[" => 13,
			"{" => 31,
			'REF' => 51,
			"\${" => 35,
			'LITERAL' => 36
		},
		GOTOS => {
			'term' => 88,
			'ident' => 18,
			'assign' => 86,
			'item' => 38,
			'expr' => 199
		}
	},
	{#State 148
		ACTIONS => {
			'OR' => 144,
			'AND' => 145,
			'COMPOP' => 147,
			")" => 200
		}
	},
	{#State 149
		DEFAULT => -22
	},
	{#State 150
		ACTIONS => {
			'GET' => 2,
			'UBLOCK' => 1,
			'INCLUDE' => 4,
			'TEXT' => 7,
			'DEFAULT' => 6,
			'BREAK' => 5,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 14,
			'SET' => 15,
			'USE' => 16,
			'MACRO' => 17,
			'UNLESS' => 20,
			'PROCESS' => 23,
			'RETURN' => 25,
			'CATCH' => 26,
			'FILTER' => 29,
			'DEBUG' => 30,
			";" => -16,
			"{" => 31,
			'ERROR' => 32,
			"\${" => 35,
			'LITERAL' => 36,
			'IF' => 39,
			"\"" => 40,
			"\$" => 42,
			'PERL' => 45,
			'IDENT' => 46,
			'UDIR' => 48,
			'THROW' => 47,
			'WHILE' => 50,
			'REF' => 51
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 24,
			'catch' => 3,
			'assign' => 27,
			'filter' => 28,
			'condition' => 11,
			'debug' => 10,
			'setlist' => 12,
			'block' => 201,
			'chunks' => 34,
			'userdef' => 37,
			'item' => 38,
			'atomdir' => 41,
			'macro' => 43,
			'perl' => 44,
			'ident' => 18,
			'term' => 49,
			'chunk' => 19,
			'loop' => 21,
			'defblock' => 22,
			'directive' => 52
		}
	},
	{#State 151
		ACTIONS => {
			'END' => 202
		}
	},
	{#State 152
		ACTIONS => {
			'GET' => 2,
			'UBLOCK' => 1,
			'INCLUDE' => 4,
			'TEXT' => 7,
			'DEFAULT' => 6,
			'BREAK' => 5,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 14,
			'SET' => 15,
			'USE' => 16,
			'MACRO' => 17,
			'UNLESS' => 20,
			'PROCESS' => 23,
			'RETURN' => 25,
			'CATCH' => 26,
			'FILTER' => 29,
			'DEBUG' => 30,
			";" => -16,
			"{" => 31,
			'ERROR' => 32,
			"\${" => 35,
			'LITERAL' => 36,
			'IF' => 39,
			"\"" => 40,
			"\$" => 42,
			'PERL' => 45,
			'IDENT' => 46,
			'UDIR' => 48,
			'THROW' => 47,
			'WHILE' => 50,
			'REF' => 51
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 24,
			'catch' => 3,
			'assign' => 27,
			'filter' => 28,
			'condition' => 11,
			'debug' => 10,
			'setlist' => 12,
			'block' => 203,
			'chunks' => 34,
			'userdef' => 37,
			'item' => 38,
			'atomdir' => 41,
			'macro' => 43,
			'perl' => 44,
			'ident' => 18,
			'term' => 49,
			'chunk' => 19,
			'loop' => 21,
			'defblock' => 22,
			'directive' => 52
		}
	},
	{#State 153
		DEFAULT => -63
	},
	{#State 154
		DEFAULT => -87
	},
	{#State 155
		DEFAULT => -88
	},
	{#State 156
		ACTIONS => {
			"\"" => 40,
			"{" => 31,
			"[" => 13,
			"\$" => 42,
			'IDENT' => 46,
			'REF' => 51,
			'LITERAL' => 55,
			"\${" => 35
		},
		GOTOS => {
			'term' => 204,
			'ident' => 54,
			'item' => 38
		}
	},
	{#State 157
		ACTIONS => {
			"\"" => 40,
			"{" => 31,
			"[" => 13,
			"\$" => 42,
			'IDENT' => 46,
			'REF' => 51,
			'LITERAL' => 55,
			"\${" => 35
		},
		GOTOS => {
			'term' => 205,
			'ident' => 54,
			'item' => 38
		}
	},
	{#State 158
		ACTIONS => {
			"(" => 206
		},
		DEFAULT => -70
	},
	{#State 159
		ACTIONS => {
			'BINOP' => 115
		},
		DEFAULT => -75
	},
	{#State 160
		ACTIONS => {
			'GET' => 2,
			'UBLOCK' => 1,
			'INCLUDE' => 4,
			'TEXT' => 7,
			'DEFAULT' => 6,
			'BREAK' => 5,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 14,
			'SET' => 15,
			'USE' => 16,
			'MACRO' => 17,
			'UNLESS' => 20,
			'PROCESS' => 23,
			'RETURN' => 25,
			'CATCH' => 26,
			'FILTER' => 29,
			'DEBUG' => 30,
			";" => -16,
			"{" => 31,
			'ERROR' => 32,
			"\${" => 35,
			'LITERAL' => 36,
			'IF' => 39,
			"\"" => 40,
			"\$" => 42,
			'PERL' => 45,
			'IDENT' => 46,
			'UDIR' => 48,
			'THROW' => 47,
			'WHILE' => 50,
			'REF' => 51
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 24,
			'catch' => 3,
			'assign' => 27,
			'filter' => 28,
			'condition' => 11,
			'debug' => 10,
			'setlist' => 12,
			'block' => 207,
			'chunks' => 34,
			'userdef' => 37,
			'item' => 38,
			'atomdir' => 41,
			'macro' => 43,
			'perl' => 44,
			'ident' => 18,
			'term' => 49,
			'chunk' => 19,
			'loop' => 21,
			'defblock' => 22,
			'directive' => 52
		}
	},
	{#State 161
		DEFAULT => -124
	},
	{#State 162
		ACTIONS => {
			'DOT' => 82
		},
		DEFAULT => -123
	},
	{#State 163
		DEFAULT => -125
	},
	{#State 164
		DEFAULT => -64
	},
	{#State 165
		DEFAULT => -121
	},
	{#State 166
		DEFAULT => -42
	},
	{#State 167
		ACTIONS => {
			'OR' => 144,
			'AND' => 145,
			'COMPOP' => 147
		},
		DEFAULT => -37
	},
	{#State 168
		DEFAULT => -48
	},
	{#State 169
		ACTIONS => {
			'OR' => 144,
			'AND' => 145,
			'COMPOP' => 147
		},
		DEFAULT => -35
	},
	{#State 170
		ACTIONS => {
			'OR' => 144,
			'AND' => 145,
			'COMPOP' => 147
		},
		DEFAULT => -44
	},
	{#State 171
		ACTIONS => {
			'END' => 208
		}
	},
	{#State 172
		DEFAULT => -92
	},
	{#State 173
		ACTIONS => {
			"\"" => 40,
			"\$" => 42,
			'IDENT' => 176,
			"[" => 13,
			"{" => 31,
			'REF' => 51,
			"\${" => 35,
			'LITERAL' => 174,
			'COMMA' => 209
		},
		DEFAULT => -97,
		GOTOS => {
			'term' => 177,
			'param' => 172,
			'arg' => 210,
			'ident' => 54,
			'item' => 38
		}
	},
	{#State 174
		ACTIONS => {
			'ASSIGN' => 156
		},
		DEFAULT => -57
	},
	{#State 175
		ACTIONS => {
			")" => 211
		}
	},
	{#State 176
		ACTIONS => {
			'ASSIGN' => 157,
			"(" => 113
		},
		DEFAULT => -73
	},
	{#State 177
		ACTIONS => {
			'BINOP' => 115
		},
		DEFAULT => -93
	},
	{#State 178
		DEFAULT => -96
	},
	{#State 179
		ACTIONS => {
			'BINOP' => 115
		},
		DEFAULT => -23
	},
	{#State 180
		DEFAULT => -65
	},
	{#State 181
		ACTIONS => {
			'GET' => 2,
			'UBLOCK' => 1,
			'INCLUDE' => 4,
			'TEXT' => 7,
			'DEFAULT' => 6,
			'BREAK' => 5,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 14,
			'SET' => 15,
			'USE' => 16,
			'MACRO' => 17,
			'UNLESS' => 20,
			'PROCESS' => 23,
			'RETURN' => 25,
			'CATCH' => 26,
			'FILTER' => 29,
			'DEBUG' => 30,
			";" => -16,
			"{" => 31,
			'ERROR' => 32,
			"\${" => 35,
			'LITERAL' => 36,
			'IF' => 39,
			"\"" => 40,
			"\$" => 42,
			'PERL' => 45,
			'IDENT' => 46,
			'UDIR' => 48,
			'THROW' => 47,
			'WHILE' => 50,
			'REF' => 51
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 24,
			'catch' => 3,
			'assign' => 27,
			'filter' => 28,
			'condition' => 11,
			'debug' => 10,
			'setlist' => 12,
			'block' => 212,
			'chunks' => 34,
			'userdef' => 37,
			'item' => 38,
			'atomdir' => 41,
			'macro' => 43,
			'perl' => 44,
			'ident' => 18,
			'term' => 49,
			'chunk' => 19,
			'loop' => 21,
			'defblock' => 22,
			'directive' => 52
		}
	},
	{#State 182
		DEFAULT => -55
	},
	{#State 183
		DEFAULT => -114
	},
	{#State 184
		DEFAULT => -115
	},
	{#State 185
		DEFAULT => -110
	},
	{#State 186
		ACTIONS => {
			'END' => 213
		}
	},
	{#State 187
		ACTIONS => {
			'BINOP' => 115
		},
		DEFAULT => -45
	},
	{#State 188
		ACTIONS => {
			"\"" => 40,
			"\$" => 42,
			'IDENT' => 176,
			"[" => 13,
			"{" => 31,
			'REF' => 51,
			"\${" => 35,
			'LITERAL' => 174
		},
		DEFAULT => -98,
		GOTOS => {
			'term' => 177,
			'param' => 172,
			'arg' => 178,
			'ident' => 54,
			'args' => 214,
			'arglist' => 173,
			'item' => 38
		}
	},
	{#State 189
		ACTIONS => {
			'BINOP' => 115
		},
		DEFAULT => -84
	},
	{#State 190
		ACTIONS => {
			'END' => 215
		}
	},
	{#State 191
		DEFAULT => -50
	},
	{#State 192
		ACTIONS => {
			")" => 216
		}
	},
	{#State 193
		ACTIONS => {
			"(" => 217,
			'DOT' => 120,
			"/" => 121
		},
		DEFAULT => -118
	},
	{#State 194
		ACTIONS => {
			'IDENT' => 220,
			'COMMA' => 219,
			")" => 218
		}
	},
	{#State 195
		DEFAULT => -101
	},
	{#State 196
		ACTIONS => {
			'COMPOP' => 147
		},
		DEFAULT => -104
	},
	{#State 197
		ACTIONS => {
			'COMPOP' => 147
		},
		DEFAULT => -103
	},
	{#State 198
		ACTIONS => {
			'ELSE' => 222,
			'ELSIF' => 221
		},
		DEFAULT => -40,
		GOTOS => {
			'else' => 223
		}
	},
	{#State 199
		DEFAULT => -102
	},
	{#State 200
		DEFAULT => -106
	},
	{#State 201
		ACTIONS => {
			'END' => 224
		}
	},
	{#State 202
		DEFAULT => -33
	},
	{#State 203
		ACTIONS => {
			'END' => 225
		}
	},
	{#State 204
		ACTIONS => {
			'BINOP' => 115
		},
		DEFAULT => -85
	},
	{#State 205
		ACTIONS => {
			'BINOP' => 115
		},
		DEFAULT => -86
	},
	{#State 206
		ACTIONS => {
			"\"" => 40,
			"\$" => 42,
			'IDENT' => 176,
			"[" => 13,
			"{" => 31,
			'REF' => 51,
			"\${" => 35,
			'LITERAL' => 174
		},
		DEFAULT => -98,
		GOTOS => {
			'term' => 177,
			'param' => 172,
			'arg' => 178,
			'ident' => 54,
			'args' => 226,
			'arglist' => 173,
			'item' => 38
		}
	},
	{#State 207
		ACTIONS => {
			'ELSE' => 222,
			'ELSIF' => 221
		},
		DEFAULT => -40,
		GOTOS => {
			'else' => 227
		}
	},
	{#State 208
		DEFAULT => -51
	},
	{#State 209
		DEFAULT => -95
	},
	{#State 210
		DEFAULT => -94
	},
	{#State 211
		DEFAULT => -72
	},
	{#State 212
		ACTIONS => {
			'END' => 228
		}
	},
	{#State 213
		DEFAULT => -41
	},
	{#State 214
		ACTIONS => {
			")" => 229
		}
	},
	{#State 215
		DEFAULT => -49
	},
	{#State 216
		DEFAULT => -119
	},
	{#State 217
		ACTIONS => {
			"\"" => 40,
			"\$" => 42,
			'IDENT' => 176,
			"[" => 13,
			"{" => 31,
			'REF' => 51,
			"\${" => 35,
			'LITERAL' => 174
		},
		DEFAULT => -98,
		GOTOS => {
			'term' => 177,
			'param' => 172,
			'arg' => 178,
			'ident' => 54,
			'args' => 230,
			'arglist' => 173,
			'item' => 38
		}
	},
	{#State 218
		ACTIONS => {
			'GET' => 2,
			'UBLOCK' => 1,
			'INCLUDE' => 4,
			'DEFAULT' => 6,
			'BREAK' => 5,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 14,
			'SET' => 15,
			'USE' => 16,
			'MACRO' => 17,
			'UNLESS' => 20,
			'PROCESS' => 23,
			'RETURN' => 25,
			'CATCH' => 26,
			'FILTER' => 29,
			'DEBUG' => 30,
			"{" => 31,
			'ERROR' => 32,
			"\${" => 35,
			'LITERAL' => 36,
			'IF' => 39,
			"\"" => 40,
			"\$" => 42,
			'PERL' => 45,
			'IDENT' => 46,
			'UDIR' => 48,
			'THROW' => 47,
			'WHILE' => 50,
			'REF' => 51
		},
		DEFAULT => -16,
		GOTOS => {
			'atomdir' => 41,
			'return' => 24,
			'macro' => 43,
			'perl' => 44,
			'catch' => 3,
			'ident' => 18,
			'assign' => 27,
			'filter' => 28,
			'condition' => 11,
			'debug' => 10,
			'term' => 49,
			'setlist' => 12,
			'defblock' => 22,
			'loop' => 21,
			'userdef' => 37,
			'directive' => 231,
			'item' => 38
		}
	},
	{#State 219
		DEFAULT => -100
	},
	{#State 220
		DEFAULT => -99
	},
	{#State 221
		ACTIONS => {
			"\"" => 40,
			'NOT' => 84,
			"\$" => 42,
			'IDENT' => 46,
			"(" => 87,
			"[" => 13,
			"{" => 31,
			'REF' => 51,
			"\${" => 35,
			'LITERAL' => 36
		},
		GOTOS => {
			'term' => 88,
			'ident' => 18,
			'assign' => 86,
			'item' => 38,
			'expr' => 232
		}
	},
	{#State 222
		ACTIONS => {
			";" => 233
		}
	},
	{#State 223
		ACTIONS => {
			'END' => 234
		}
	},
	{#State 224
		DEFAULT => -32
	},
	{#State 225
		DEFAULT => -47
	},
	{#State 226
		ACTIONS => {
			")" => 235
		}
	},
	{#State 227
		ACTIONS => {
			'END' => 236
		}
	},
	{#State 228
		DEFAULT => -43
	},
	{#State 229
		DEFAULT => -62
	},
	{#State 230
		ACTIONS => {
			")" => 237
		}
	},
	{#State 231
		DEFAULT => -53
	},
	{#State 232
		ACTIONS => {
			";" => 238,
			'OR' => 144,
			'AND' => 145,
			'COMPOP' => 147
		}
	},
	{#State 233
		ACTIONS => {
			'GET' => 2,
			'UBLOCK' => 1,
			'INCLUDE' => 4,
			'TEXT' => 7,
			'DEFAULT' => 6,
			'BREAK' => 5,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 14,
			'SET' => 15,
			'USE' => 16,
			'MACRO' => 17,
			'UNLESS' => 20,
			'PROCESS' => 23,
			'RETURN' => 25,
			'CATCH' => 26,
			'FILTER' => 29,
			'DEBUG' => 30,
			";" => -16,
			"{" => 31,
			'ERROR' => 32,
			"\${" => 35,
			'LITERAL' => 36,
			'IF' => 39,
			"\"" => 40,
			"\$" => 42,
			'PERL' => 45,
			'IDENT' => 46,
			'UDIR' => 48,
			'THROW' => 47,
			'WHILE' => 50,
			'REF' => 51
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 24,
			'catch' => 3,
			'assign' => 27,
			'filter' => 28,
			'condition' => 11,
			'debug' => 10,
			'setlist' => 12,
			'block' => 239,
			'chunks' => 34,
			'userdef' => 37,
			'item' => 38,
			'atomdir' => 41,
			'macro' => 43,
			'perl' => 44,
			'ident' => 18,
			'term' => 49,
			'chunk' => 19,
			'loop' => 21,
			'defblock' => 22,
			'directive' => 52
		}
	},
	{#State 234
		DEFAULT => -36
	},
	{#State 235
		DEFAULT => -71
	},
	{#State 236
		DEFAULT => -34
	},
	{#State 237
		DEFAULT => -117
	},
	{#State 238
		ACTIONS => {
			'GET' => 2,
			'UBLOCK' => 1,
			'INCLUDE' => 4,
			'TEXT' => 7,
			'DEFAULT' => 6,
			'BREAK' => 5,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 14,
			'SET' => 15,
			'USE' => 16,
			'MACRO' => 17,
			'UNLESS' => 20,
			'PROCESS' => 23,
			'RETURN' => 25,
			'CATCH' => 26,
			'FILTER' => 29,
			'DEBUG' => 30,
			";" => -16,
			"{" => 31,
			'ERROR' => 32,
			"\${" => 35,
			'LITERAL' => 36,
			'IF' => 39,
			"\"" => 40,
			"\$" => 42,
			'PERL' => 45,
			'IDENT' => 46,
			'UDIR' => 48,
			'THROW' => 47,
			'WHILE' => 50,
			'REF' => 51
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 24,
			'catch' => 3,
			'assign' => 27,
			'filter' => 28,
			'condition' => 11,
			'debug' => 10,
			'setlist' => 12,
			'block' => 240,
			'chunks' => 34,
			'userdef' => 37,
			'item' => 38,
			'atomdir' => 41,
			'macro' => 43,
			'perl' => 44,
			'ident' => 18,
			'term' => 49,
			'chunk' => 19,
			'loop' => 21,
			'defblock' => 22,
			'directive' => 52
		}
	},
	{#State 239
		DEFAULT => -38
	},
	{#State 240
		ACTIONS => {
			'ELSE' => 222,
			'ELSIF' => 221
		},
		DEFAULT => -40,
		GOTOS => {
			'else' => 241
		}
	},
	{#State 241
		DEFAULT => -39
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
		 'directive', 1, undef
	],
	[#Rule 16
		 'directive', 0, undef
	],
	[#Rule 17
		 'atomdir', 2,
sub
#line 46 "Parser.yp"
{ $factory->create(Get     => $_[2])    }
	],
	[#Rule 18
		 'atomdir', 2,
sub
#line 47 "Parser.yp"
{ $factory->create(Set     => $_[2])    }
	],
	[#Rule 19
		 'atomdir', 2,
sub
#line 48 "Parser.yp"
{ unshift(@{$_[2]}, OP_DEFAULT);
				  $factory->create(Set     => $_[2])    }
	],
	[#Rule 20
		 'atomdir', 2,
sub
#line 50 "Parser.yp"
{ $factory->create(Use     => @{$_[2]}) }
	],
	[#Rule 21
		 'atomdir', 3,
sub
#line 51 "Parser.yp"
{ $factory->create(Include => @_[2,3])  }
	],
	[#Rule 22
		 'atomdir', 3,
sub
#line 52 "Parser.yp"
{ $factory->create(Process => @_[2,3])  }
	],
	[#Rule 23
		 'atomdir', 3,
sub
#line 53 "Parser.yp"
{ $factory->create(Throw   => @_[2,3])  }
	],
	[#Rule 24
		 'atomdir', 2,
sub
#line 54 "Parser.yp"
{ $factory->create(Error   => $_[2])    }
	],
	[#Rule 25
		 'atomdir', 1,
sub
#line 55 "Parser.yp"
{ $factory->create(Return  => $_[1])    }
	],
	[#Rule 26
		 'atomdir', 1,
sub
#line 56 "Parser.yp"
{ $factory->create(Set     => $_[1])    }
	],
	[#Rule 27
		 'atomdir', 1,
sub
#line 57 "Parser.yp"
{ $factory->create(Get     => $_[1])    }
	],
	[#Rule 28
		 'atomdir', 1, undef
	],
	[#Rule 29
		 'return', 1,
sub
#line 61 "Parser.yp"
{ STATUS_RETURN }
	],
	[#Rule 30
		 'return', 1,
sub
#line 62 "Parser.yp"
{ STATUS_STOP   }
	],
	[#Rule 31
		 'return', 1,
sub
#line 63 "Parser.yp"
{ STATUS_DONE   }
	],
	[#Rule 32
		 'catch', 5,
sub
#line 67 "Parser.yp"
{ $factory->create(Catch =>, @_[2, 4])    }
	],
	[#Rule 33
		 'catch', 4,
sub
#line 69 "Parser.yp"
{ $factory->create(Catch => undef, $_[3]) }
	],
	[#Rule 34
		 'condition', 6,
sub
#line 73 "Parser.yp"
{ $factory->create(If => @_[2, 4, 5])   }
	],
	[#Rule 35
		 'condition', 3,
sub
#line 74 "Parser.yp"
{ $factory->create(If => @_[3, 1])      }
	],
	[#Rule 36
		 'condition', 6,
sub
#line 76 "Parser.yp"
{ push(@{$_[2]}, OP_NOT);
				  $factory->create(If => @_[2, 4, 5])   }
	],
	[#Rule 37
		 'condition', 3,
sub
#line 78 "Parser.yp"
{ push(@{$_[3]}, OP_NOT);
				  $factory->create(If => @_[3, 1])      }
	],
	[#Rule 38
		 'else', 3,
sub
#line 82 "Parser.yp"
{ $_[3]                                 }
	],
	[#Rule 39
		 'else', 5,
sub
#line 84 "Parser.yp"
{ $factory->create(If => @_[2, 4, 5])   }
	],
	[#Rule 40
		 'else', 0, undef
	],
	[#Rule 41
		 'loop', 5,
sub
#line 89 "Parser.yp"
{ $factory->create(For => @{$_[2]}, $_[4]) }
	],
	[#Rule 42
		 'loop', 3,
sub
#line 90 "Parser.yp"
{ $factory->create(For => @{$_[3]}, $_[1]) }
	],
	[#Rule 43
		 'loop', 5,
sub
#line 92 "Parser.yp"
{ $factory->create(While  => @_[2, 4])   }
	],
	[#Rule 44
		 'loop', 3,
sub
#line 93 "Parser.yp"
{ $factory->create(While  => @_[3, 1])   }
	],
	[#Rule 45
		 'loopvar', 3,
sub
#line 96 "Parser.yp"
{ [ @_[1, 3] ]     }
	],
	[#Rule 46
		 'loopvar', 1,
sub
#line 97 "Parser.yp"
{ [ undef, $_[1] ] }
	],
	[#Rule 47
		 'filter', 5,
sub
#line 101 "Parser.yp"
{ $factory->create(Filter => @{$_[2]}, $_[4]) }
	],
	[#Rule 48
		 'filter', 3,
sub
#line 103 "Parser.yp"
{ $factory->create(Filter => @{$_[3]}, $_[1]) }
	],
	[#Rule 49
		 'defblock', 5,
sub
#line 107 "Parser.yp"
{ $_[0]->define_block(@_[2, 4]); undef  }
	],
	[#Rule 50
		 'defblock', 4,
sub
#line 109 "Parser.yp"
{ $_[3] }
	],
	[#Rule 51
		 'perl', 4,
sub
#line 113 "Parser.yp"
{ $factory->create(Perl  => $_[3]) }
	],
	[#Rule 52
		 'macro', 3,
sub
#line 117 "Parser.yp"
{ $factory->create(Macro => @_[2, 3])    }
	],
	[#Rule 53
		 'macro', 6,
sub
#line 119 "Parser.yp"
{ $factory->create(Macro => @_[2, 6, 4]) }
	],
	[#Rule 54
		 'userdef', 1,
sub
#line 122 "Parser.yp"
{ $factory->create(Userdef => $_[1])     }
	],
	[#Rule 55
		 'userdef', 4,
sub
#line 124 "Parser.yp"
{ $factory->create(Userdef => @_[1, 3])  }
	],
	[#Rule 56
		 'debug', 2,
sub
#line 127 "Parser.yp"
{ $factory->create(Debug => $_[2])       }
	],
	[#Rule 57
		 'term', 1,
sub
#line 135 "Parser.yp"
{ [ OP_LITERAL, $_[1]    ] }
	],
	[#Rule 58
		 'term', 1,
sub
#line 136 "Parser.yp"
{ [ OP_IDENT,   $_[1]    ] }
	],
	[#Rule 59
		 'term', 2,
sub
#line 137 "Parser.yp"
{ [ OP_REF,     $_[2]    ] }
	],
	[#Rule 60
		 'term', 3,
sub
#line 138 "Parser.yp"
{ [ OP_RANGE,   $_[2]    ] }
	],
	[#Rule 61
		 'term', 3,
sub
#line 139 "Parser.yp"
{ [ OP_LIST,    $_[2]    ] }
	],
	[#Rule 62
		 'term', 6,
sub
#line 140 "Parser.yp"
{ [ OP_ITER,    @_[2, 5] ] }
	],
	[#Rule 63
		 'term', 3,
sub
#line 141 "Parser.yp"
{ [ OP_HASH,    $_[2]    ] }
	],
	[#Rule 64
		 'term', 3,
sub
#line 142 "Parser.yp"
{ [ OP_QUOTE,   $_[2]    ] }
	],
	[#Rule 65
		 'term', 3,
sub
#line 143 "Parser.yp"
{ push(@{$_[1]}, @{$_[3]}, 
						OP_BINOP, $_[2]); $_[1]  }
	],
	[#Rule 66
		 'ident', 3,
sub
#line 148 "Parser.yp"
{ push(@{$_[1]}, $_[3]); $_[1] }
	],
	[#Rule 67
		 'ident', 3,
sub
#line 149 "Parser.yp"
{ push(@{$_[1]}, [ $_[3], 0 ]); $_[1] }
	],
	[#Rule 68
		 'ident', 1,
sub
#line 150 "Parser.yp"
{ [ $_[1] ] }
	],
	[#Rule 69
		 'ident', 2,
sub
#line 151 "Parser.yp"
{ [ $_[2] ] }
	],
	[#Rule 70
		 'item', 3,
sub
#line 154 "Parser.yp"
{ [ $_[2], 0 ] }
	],
	[#Rule 71
		 'item', 6,
sub
#line 155 "Parser.yp"
{ [ @_[2, 5] ] }
	],
	[#Rule 72
		 'item', 4,
sub
#line 156 "Parser.yp"
{ [ @_[1, 3] ] }
	],
	[#Rule 73
		 'item', 1,
sub
#line 157 "Parser.yp"
{ [ $_[1], 0 ] }
	],
	[#Rule 74
		 'assign', 3,
sub
#line 160 "Parser.yp"
{ push(@{$_[3]}, OP_ASSIGN, $_[1]);
					  $_[3] }
	],
	[#Rule 75
		 'assign', 3,
sub
#line 162 "Parser.yp"
{ push(@{$_[3]}, OP_ASSIGN, $_[1]);
					  $_[3] }
	],
	[#Rule 76
		 'list', 2,
sub
#line 166 "Parser.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 77
		 'list', 2,
sub
#line 167 "Parser.yp"
{ $_[1] }
	],
	[#Rule 78
		 'list', 1,
sub
#line 168 "Parser.yp"
{ [ $_[1] ] }
	],
	[#Rule 79
		 'setlist', 2,
sub
#line 171 "Parser.yp"
{ push(@{$_[1]}, @{$_[2]}); $_[1] }
	],
	[#Rule 80
		 'setlist', 2,
sub
#line 172 "Parser.yp"
{ $_[1] }
	],
	[#Rule 81
		 'setlist', 1, undef
	],
	[#Rule 82
		 'setopt', 1, undef
	],
	[#Rule 83
		 'setopt', 0,
sub
#line 177 "Parser.yp"
{ [ ] }
	],
	[#Rule 84
		 'range', 3,
sub
#line 180 "Parser.yp"
{ [ @_[1, 3] ] }
	],
	[#Rule 85
		 'param', 3,
sub
#line 185 "Parser.yp"
{ [ $_[1], $_[3] ] }
	],
	[#Rule 86
		 'param', 3,
sub
#line 186 "Parser.yp"
{ [ $_[1], $_[3] ] }
	],
	[#Rule 87
		 'paramlist', 2,
sub
#line 189 "Parser.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 88
		 'paramlist', 2,
sub
#line 190 "Parser.yp"
{ $_[1] }
	],
	[#Rule 89
		 'paramlist', 1,
sub
#line 191 "Parser.yp"
{ [ $_[1] ] }
	],
	[#Rule 90
		 'params', 1, undef
	],
	[#Rule 91
		 'params', 0,
sub
#line 195 "Parser.yp"
{ [ ] }
	],
	[#Rule 92
		 'arg', 1, undef
	],
	[#Rule 93
		 'arg', 1,
sub
#line 199 "Parser.yp"
{ [ 0, $_[1] ] }
	],
	[#Rule 94
		 'arglist', 2,
sub
#line 202 "Parser.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 95
		 'arglist', 2,
sub
#line 203 "Parser.yp"
{ $_[1] }
	],
	[#Rule 96
		 'arglist', 1,
sub
#line 204 "Parser.yp"
{ [ $_[1] ] }
	],
	[#Rule 97
		 'args', 1,
sub
#line 207 "Parser.yp"
{ [ OP_ARGS, $_[1] ]  }
	],
	[#Rule 98
		 'args', 0,
sub
#line 208 "Parser.yp"
{ [ OP_ARGS, [ ] ] }
	],
	[#Rule 99
		 'mlist', 2,
sub
#line 212 "Parser.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 100
		 'mlist', 2,
sub
#line 213 "Parser.yp"
{ $_[1] }
	],
	[#Rule 101
		 'mlist', 1,
sub
#line 214 "Parser.yp"
{ [ $_[1] ] }
	],
	[#Rule 102
		 'expr', 3,
sub
#line 217 "Parser.yp"
{ push(@{$_[1]}, @{$_[3]}, 
						OP_BINOP, $_[2]); $_[1]  }
	],
	[#Rule 103
		 'expr', 3,
sub
#line 219 "Parser.yp"
{ push(@{$_[1]}, OP_AND, $_[3]); 
					  $_[1]                          }
	],
	[#Rule 104
		 'expr', 3,
sub
#line 221 "Parser.yp"
{ push(@{$_[1]}, OP_OR, $_[3]);
					  $_[1]                          }
	],
	[#Rule 105
		 'expr', 2,
sub
#line 223 "Parser.yp"
{ push(@{$_[2]}, OP_NOT);
					  $_[2]                          }
	],
	[#Rule 106
		 'expr', 3,
sub
#line 225 "Parser.yp"
{ $_[2]                          }
	],
	[#Rule 107
		 'expr', 1, undef
	],
	[#Rule 108
		 'expr', 1, undef
	],
	[#Rule 109
		 'file', 2,
sub
#line 235 "Parser.yp"
{ [ OP_IDENT, $_[2] ] }
	],
	[#Rule 110
		 'file', 3,
sub
#line 236 "Parser.yp"
{ [ OP_QUOTE, $_[2] ] }
	],
	[#Rule 111
		 'file', 2,
sub
#line 237 "Parser.yp"
{ '/' . $_[2]         }
	],
	[#Rule 112
		 'file', 1, undef
	],
	[#Rule 113
		 'file', 1, undef
	],
	[#Rule 114
		 'textdot', 3,
sub
#line 244 "Parser.yp"
{ $_[1] .= "$_[2]$_[3]"; $_[1] }
	],
	[#Rule 115
		 'textdot', 3,
sub
#line 245 "Parser.yp"
{ $_[1] .= "$_[2]$_[3]"; $_[1] }
	],
	[#Rule 116
		 'textdot', 1, undef
	],
	[#Rule 117
		 'useparam', 6,
sub
#line 251 "Parser.yp"
{ [ @_[3, 5, 1]         ] }
	],
	[#Rule 118
		 'useparam', 3,
sub
#line 252 "Parser.yp"
{ [ $_[3], undef, $_[1] ] }
	],
	[#Rule 119
		 'useparam', 4,
sub
#line 253 "Parser.yp"
{ [ $_[1], $_[3], undef ] }
	],
	[#Rule 120
		 'useparam', 1,
sub
#line 254 "Parser.yp"
{ [ $_[1], undef, undef ] }
	],
	[#Rule 121
		 'quoted', 2,
sub
#line 260 "Parser.yp"
{ push(@{$_[1]}, $_[2])
						if defined $_[2]; $_[1] }
	],
	[#Rule 122
		 'quoted', 0,
sub
#line 262 "Parser.yp"
{ [ ] }
	],
	[#Rule 123
		 'quotable', 1,
sub
#line 268 "Parser.yp"
{ [ OP_IDENT,   $_[1] ] }
	],
	[#Rule 124
		 'quotable', 1,
sub
#line 269 "Parser.yp"
{ [ OP_LITERAL, $_[1] ] }
	],
	[#Rule 125
		 'quotable', 1,
sub
#line 270 "Parser.yp"
{ undef }
	]
];



1;












