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
# $Id: Grammar.pm,v 1.26 1999/09/14 23:07:01 abw Exp $
#
#========================================================================

package Template::Grammar;

require 5.004;

use strict;
use vars qw( $VERSION );

use Template::Constants qw( :ops :status );

$VERSION = sprintf("%d.%02d", q$Revision: 1.26 $ =~ /(\d+)\.(\d+)/);

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
	THROW CATCH ERROR RETURN STOP BREAK 
	BLOCK END TO STEP AND OR NOT
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
#    ';'       => 'SEPARATOR',
    '='       => 'ASSIGN',
    '=>'      => 'ASSIGN',
#    '/'      => 'END',
    ','       => 'COMMA',
    'and'     => 'AND',		# explicitly specified so that qw( and or
    'or'      => 'OR',		# not ) can always be used in lower case, 
    'not'     => 'NOT'		# regardless of CASE sensitivity flag
};

# localise the temporary variables needed to complete lexer table
{ 
    my @tokens   = qw< ( ) [ ] { } ${ $ / ; >;
    my @compop   = qw( == != < <= >= > );

    # fill lexer table, slice by slice, with reserved words and operators
    @$LEXTABLE{ @RESERVED, @compop, @tokens } 
	= ( @RESERVED, ('COMPOP') x @compop, @tokens );
}


#========================================================================
# States
#========================================================================

$STATES = [
	{#State 0
		ACTIONS => {
			'RETURN' => 23,
			'GET' => 1,
			'CATCH' => 24,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'FILTER' => 27,
			'STOP' => 7,
			'DEBUG' => 28,
			'FOR' => 8,
			";" => -14,
			"{" => 29,
			"[" => 12,
			'ERROR' => 30,
			'BLOCK' => 13,
			'SET' => 14,
			'LITERAL' => 34,
			"\${" => 33,
			'USE' => 15,
			'IF' => 36,
			"\"" => 37,
			"\$" => 39,
			'THROW' => 41,
			'IDENT' => 40,
			'WHILE' => 43,
			'UNLESS' => 18,
			'PROCESS' => 21
		},
		DEFAULT => -2,
		GOTOS => {
			'atomdir' => 38,
			'return' => 22,
			'catch' => 2,
			'ident' => 16,
			'assign' => 25,
			'filter' => 26,
			'condition' => 10,
			'debug' => 9,
			'term' => 42,
			'setlist' => 11,
			'chunk' => 17,
			'loop' => 19,
			'defblock' => 20,
			'block' => 31,
			'chunks' => 32,
			'directive' => 44,
			'item' => 35
		}
	},
	{#State 1
		ACTIONS => {
			"\"" => 37,
			"{" => 29,
			"[" => 12,
			"\$" => 39,
			'IDENT' => 40,
			'LITERAL' => 46,
			"\${" => 33
		},
		GOTOS => {
			'term' => 47,
			'ident' => 45,
			'item' => 35
		}
	},
	{#State 2
		DEFAULT => -8
	},
	{#State 3
		ACTIONS => {
			"\"" => 51,
			"\$" => 52,
			'IDENT' => 53,
			'LITERAL' => 50
		},
		GOTOS => {
			'file' => 49,
			'textdot' => 48
		}
	},
	{#State 4
		DEFAULT => -28
	},
	{#State 5
		ACTIONS => {
			"\$" => 39,
			'IDENT' => 40,
			"\${" => 33,
			'LITERAL' => 56
		},
		GOTOS => {
			'setlist' => 54,
			'ident' => 55,
			'assign' => 25,
			'item' => 35
		}
	},
	{#State 6
		DEFAULT => -5
	},
	{#State 7
		DEFAULT => -27
	},
	{#State 8
		ACTIONS => {
			"\"" => 37,
			"{" => 29,
			"[" => 12,
			"\$" => 39,
			'IDENT' => 58,
			'LITERAL' => 46,
			"\${" => 33
		},
		GOTOS => {
			'term' => 59,
			'loopvar' => 57,
			'ident' => 45,
			'item' => 35
		}
	},
	{#State 9
		DEFAULT => -13
	},
	{#State 10
		DEFAULT => -9
	},
	{#State 11
		ACTIONS => {
			"\$" => 39,
			'IDENT' => 40,
			'LITERAL' => 56,
			"\${" => 33,
			'COMMA' => 61
		},
		DEFAULT => -24,
		GOTOS => {
			'ident' => 55,
			'assign' => 60,
			'item' => 35
		}
	},
	{#State 12
		ACTIONS => {
			"\"" => 37,
			"{" => 29,
			"[" => 12,
			"\$" => 39,
			'IDENT' => 40,
			'LITERAL' => 46,
			"\${" => 33
		},
		GOTOS => {
			'term' => 64,
			'list' => 63,
			'ident' => 45,
			'range' => 62,
			'item' => 35
		}
	},
	{#State 13
		ACTIONS => {
			'IDENT' => 53
		},
		GOTOS => {
			'textdot' => 65
		}
	},
	{#State 14
		ACTIONS => {
			"\$" => 39,
			'IDENT' => 40,
			"\${" => 33,
			'LITERAL' => 56
		},
		GOTOS => {
			'setlist' => 66,
			'ident' => 55,
			'assign' => 25,
			'item' => 35
		}
	},
	{#State 15
		ACTIONS => {
			'IDENT' => 69
		},
		GOTOS => {
			'textdot' => 67,
			'useparam' => 68
		}
	},
	{#State 16
		ACTIONS => {
			'ASSIGN' => 71,
			'DOT' => 70
		},
		DEFAULT => -49
	},
	{#State 17
		DEFAULT => -4
	},
	{#State 18
		ACTIONS => {
			"\"" => 37,
			'NOT' => 72,
			"\$" => 39,
			'IDENT' => 40,
			"(" => 75,
			"[" => 12,
			"{" => 29,
			"\${" => 33,
			'LITERAL' => 34
		},
		GOTOS => {
			'term' => 76,
			'ident' => 16,
			'assign' => 74,
			'item' => 35,
			'expr' => 73
		}
	},
	{#State 19
		DEFAULT => -10
	},
	{#State 20
		DEFAULT => -12
	},
	{#State 21
		ACTIONS => {
			"\"" => 51,
			"\$" => 52,
			'IDENT' => 53,
			'LITERAL' => 50
		},
		GOTOS => {
			'file' => 77,
			'textdot' => 48
		}
	},
	{#State 22
		DEFAULT => -23
	},
	{#State 23
		DEFAULT => -26
	},
	{#State 24
		ACTIONS => {
			";" => 78,
			'IDENT' => 79
		}
	},
	{#State 25
		DEFAULT => -68
	},
	{#State 26
		DEFAULT => -11
	},
	{#State 27
		ACTIONS => {
			'IDENT' => 69
		},
		GOTOS => {
			'textdot' => 67,
			'useparam' => 80
		}
	},
	{#State 28
		ACTIONS => {
			'TEXT' => 81
		}
	},
	{#State 29
		ACTIONS => {
			'IDENT' => 86,
			'LITERAL' => 85
		},
		DEFAULT => -78,
		GOTOS => {
			'param' => 82,
			'params' => 83,
			'paramlist' => 84
		}
	},
	{#State 30
		ACTIONS => {
			"\"" => 37,
			"{" => 29,
			"[" => 12,
			"\$" => 39,
			'IDENT' => 40,
			'LITERAL' => 46,
			"\${" => 33
		},
		GOTOS => {
			'term' => 87,
			'ident' => 45,
			'item' => 35
		}
	},
	{#State 31
		ACTIONS => {
			'' => 88
		}
	},
	{#State 32
		ACTIONS => {
			'RETURN' => 23,
			'GET' => 1,
			'CATCH' => 24,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'FILTER' => 27,
			'STOP' => 7,
			'DEBUG' => 28,
			'FOR' => 8,
			";" => -14,
			"{" => 29,
			"[" => 12,
			'ERROR' => 30,
			'BLOCK' => 13,
			'SET' => 14,
			'LITERAL' => 34,
			"\${" => 33,
			'USE' => 15,
			'IF' => 36,
			"\"" => 37,
			"\$" => 39,
			'THROW' => 41,
			'IDENT' => 40,
			'WHILE' => 43,
			'UNLESS' => 18,
			'PROCESS' => 21
		},
		DEFAULT => -1,
		GOTOS => {
			'atomdir' => 38,
			'return' => 22,
			'catch' => 2,
			'ident' => 16,
			'assign' => 25,
			'filter' => 26,
			'condition' => 10,
			'debug' => 9,
			'term' => 42,
			'setlist' => 11,
			'chunk' => 89,
			'defblock' => 20,
			'loop' => 19,
			'directive' => 44,
			'item' => 35
		}
	},
	{#State 33
		ACTIONS => {
			"\"" => 37,
			"{" => 29,
			"[" => 12,
			"\$" => 39,
			'IDENT' => 40,
			'LITERAL' => 46,
			"\${" => 33
		},
		GOTOS => {
			'term' => 90,
			'ident' => 45,
			'item' => 35
		}
	},
	{#State 34
		ACTIONS => {
			'ASSIGN' => 91
		},
		DEFAULT => -48
	},
	{#State 35
		DEFAULT => -56
	},
	{#State 36
		ACTIONS => {
			"\"" => 37,
			'NOT' => 72,
			"\$" => 39,
			'IDENT' => 40,
			"(" => 75,
			"[" => 12,
			"{" => 29,
			"\${" => 33,
			'LITERAL' => 34
		},
		GOTOS => {
			'term' => 76,
			'ident' => 16,
			'assign' => 74,
			'item' => 35,
			'expr' => 92
		}
	},
	{#State 37
		DEFAULT => -105,
		GOTOS => {
			'quoted' => 93
		}
	},
	{#State 38
		ACTIONS => {
			'WHILE' => 98,
			'UNLESS' => 95,
			'FILTER' => 96,
			'IF' => 97,
			'FOR' => 94
		},
		DEFAULT => -7
	},
	{#State 39
		ACTIONS => {
			'IDENT' => 40,
			"\${" => 33
		},
		GOTOS => {
			'item' => 99
		}
	},
	{#State 40
		ACTIONS => {
			"(" => 100
		},
		DEFAULT => -60
	},
	{#State 41
		ACTIONS => {
			'IDENT' => 101
		}
	},
	{#State 42
		DEFAULT => -25
	},
	{#State 43
		ACTIONS => {
			"\"" => 37,
			'NOT' => 72,
			"\$" => 39,
			'IDENT' => 40,
			"(" => 75,
			"[" => 12,
			"{" => 29,
			"\${" => 33,
			'LITERAL' => 34
		},
		GOTOS => {
			'term' => 76,
			'ident' => 16,
			'assign' => 74,
			'item' => 35,
			'expr' => 102
		}
	},
	{#State 44
		ACTIONS => {
			";" => 103
		}
	},
	{#State 45
		ACTIONS => {
			'DOT' => 70
		},
		DEFAULT => -49
	},
	{#State 46
		DEFAULT => -48
	},
	{#State 47
		DEFAULT => -15
	},
	{#State 48
		ACTIONS => {
			'DOT' => 104,
			"/" => 105
		},
		DEFAULT => -95
	},
	{#State 49
		ACTIONS => {
			"\$" => 39,
			'IDENT' => 40,
			'LITERAL' => 56,
			"\${" => 33
		},
		DEFAULT => -70,
		GOTOS => {
			'setlist' => 106,
			'ident' => 55,
			'assign' => 25,
			'setopt' => 107,
			'item' => 35
		}
	},
	{#State 50
		DEFAULT => -96
	},
	{#State 51
		DEFAULT => -105,
		GOTOS => {
			'quoted' => 108
		}
	},
	{#State 52
		ACTIONS => {
			"\$" => 39,
			'IDENT' => 40,
			"\${" => 33
		},
		GOTOS => {
			'ident' => 109,
			'item' => 35
		}
	},
	{#State 53
		DEFAULT => -99
	},
	{#State 54
		ACTIONS => {
			"\$" => 39,
			'IDENT' => 40,
			'LITERAL' => 56,
			"\${" => 33,
			'COMMA' => 61
		},
		DEFAULT => -17,
		GOTOS => {
			'ident' => 55,
			'assign' => 60,
			'item' => 35
		}
	},
	{#State 55
		ACTIONS => {
			'ASSIGN' => 71,
			'DOT' => 70
		}
	},
	{#State 56
		ACTIONS => {
			'ASSIGN' => 91
		}
	},
	{#State 57
		ACTIONS => {
			";" => 110
		}
	},
	{#State 58
		ACTIONS => {
			'ASSIGN' => 111,
			"(" => 100
		},
		DEFAULT => -60
	},
	{#State 59
		DEFAULT => -43
	},
	{#State 60
		DEFAULT => -66
	},
	{#State 61
		DEFAULT => -67
	},
	{#State 62
		ACTIONS => {
			"]" => 112
		}
	},
	{#State 63
		ACTIONS => {
			"\"" => 37,
			"\$" => 39,
			'IDENT' => 40,
			"[" => 12,
			"{" => 29,
			"]" => 113,
			"\${" => 33,
			'LITERAL' => 46,
			'COMMA' => 114
		},
		GOTOS => {
			'term' => 115,
			'ident' => 45,
			'item' => 35
		}
	},
	{#State 64
		ACTIONS => {
			'TO' => 116
		},
		DEFAULT => -65
	},
	{#State 65
		ACTIONS => {
			";" => 117,
			"/" => 105,
			'DOT' => 104
		}
	},
	{#State 66
		ACTIONS => {
			"\$" => 39,
			'IDENT' => 40,
			'LITERAL' => 56,
			"\${" => 33,
			'COMMA' => 61
		},
		DEFAULT => -16,
		GOTOS => {
			'ident' => 55,
			'assign' => 60,
			'item' => 35
		}
	},
	{#State 67
		ACTIONS => {
			"(" => 118,
			'DOT' => 104,
			"/" => 105
		},
		DEFAULT => -103
	},
	{#State 68
		DEFAULT => -18
	},
	{#State 69
		ACTIONS => {
			'ASSIGN' => 119
		},
		DEFAULT => -99
	},
	{#State 70
		ACTIONS => {
			'IDENT' => 40,
			"\${" => 33
		},
		GOTOS => {
			'item' => 120
		}
	},
	{#State 71
		ACTIONS => {
			"\"" => 37,
			"{" => 29,
			"[" => 12,
			"\$" => 39,
			'IDENT' => 40,
			'LITERAL' => 46,
			"\${" => 33
		},
		GOTOS => {
			'term' => 121,
			'ident' => 45,
			'item' => 35
		}
	},
	{#State 72
		ACTIONS => {
			"\"" => 37,
			'NOT' => 72,
			"\$" => 39,
			'IDENT' => 40,
			"(" => 75,
			"[" => 12,
			"{" => 29,
			"\${" => 33,
			'LITERAL' => 34
		},
		GOTOS => {
			'term' => 76,
			'ident' => 16,
			'assign' => 74,
			'item' => 35,
			'expr' => 122
		}
	},
	{#State 73
		ACTIONS => {
			";" => 125,
			'OR' => 123,
			'AND' => 124,
			'COMPOP' => 126
		}
	},
	{#State 74
		DEFAULT => -91
	},
	{#State 75
		ACTIONS => {
			"\"" => 37,
			'NOT' => 72,
			"\$" => 39,
			'IDENT' => 40,
			"(" => 75,
			"[" => 12,
			"{" => 29,
			"\${" => 33,
			'LITERAL' => 34
		},
		GOTOS => {
			'term' => 76,
			'ident' => 16,
			'assign' => 74,
			'item' => 35,
			'expr' => 127
		}
	},
	{#State 76
		DEFAULT => -92
	},
	{#State 77
		ACTIONS => {
			"\$" => 39,
			'IDENT' => 40,
			'LITERAL' => 56,
			"\${" => 33
		},
		DEFAULT => -70,
		GOTOS => {
			'setlist' => 106,
			'ident' => 55,
			'assign' => 25,
			'setopt' => 128,
			'item' => 35
		}
	},
	{#State 78
		ACTIONS => {
			'RETURN' => 23,
			'GET' => 1,
			'CATCH' => 24,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'FILTER' => 27,
			'STOP' => 7,
			'DEBUG' => 28,
			'FOR' => 8,
			";" => -14,
			"{" => 29,
			"[" => 12,
			'ERROR' => 30,
			'BLOCK' => 13,
			'SET' => 14,
			'LITERAL' => 34,
			"\${" => 33,
			'USE' => 15,
			'IF' => 36,
			"\"" => 37,
			"\$" => 39,
			'THROW' => 41,
			'IDENT' => 40,
			'WHILE' => 43,
			'UNLESS' => 18,
			'PROCESS' => 21
		},
		DEFAULT => -2,
		GOTOS => {
			'atomdir' => 38,
			'return' => 22,
			'catch' => 2,
			'ident' => 16,
			'assign' => 25,
			'filter' => 26,
			'condition' => 10,
			'debug' => 9,
			'term' => 42,
			'setlist' => 11,
			'chunk' => 17,
			'defblock' => 20,
			'loop' => 19,
			'block' => 129,
			'chunks' => 32,
			'directive' => 44,
			'item' => 35
		}
	},
	{#State 79
		ACTIONS => {
			";" => 130
		}
	},
	{#State 80
		ACTIONS => {
			";" => 131
		}
	},
	{#State 81
		DEFAULT => -47
	},
	{#State 82
		DEFAULT => -76
	},
	{#State 83
		ACTIONS => {
			"}" => 132
		}
	},
	{#State 84
		ACTIONS => {
			'IDENT' => 86,
			'COMMA' => 134,
			'LITERAL' => 85
		},
		DEFAULT => -77,
		GOTOS => {
			'param' => 133
		}
	},
	{#State 85
		ACTIONS => {
			'ASSIGN' => 135
		}
	},
	{#State 86
		ACTIONS => {
			'ASSIGN' => 136
		}
	},
	{#State 87
		DEFAULT => -22
	},
	{#State 88
		DEFAULT => -0
	},
	{#State 89
		DEFAULT => -3
	},
	{#State 90
		ACTIONS => {
			"}" => 137
		}
	},
	{#State 91
		ACTIONS => {
			"\"" => 37,
			"{" => 29,
			"[" => 12,
			"\$" => 39,
			'IDENT' => 40,
			'LITERAL' => 46,
			"\${" => 33
		},
		GOTOS => {
			'term' => 138,
			'ident' => 45,
			'item' => 35
		}
	},
	{#State 92
		ACTIONS => {
			";" => 139,
			'OR' => 123,
			'AND' => 124,
			'COMPOP' => 126
		}
	},
	{#State 93
		ACTIONS => {
			"\"" => 143,
			";" => 142,
			"\$" => 39,
			'IDENT' => 40,
			"\${" => 33,
			'TEXT' => 140
		},
		GOTOS => {
			'ident' => 141,
			'quotable' => 144,
			'item' => 35
		}
	},
	{#State 94
		ACTIONS => {
			"\"" => 37,
			"{" => 29,
			"[" => 12,
			"\$" => 39,
			'IDENT' => 58,
			'LITERAL' => 46,
			"\${" => 33
		},
		GOTOS => {
			'term' => 59,
			'loopvar' => 145,
			'ident' => 45,
			'item' => 35
		}
	},
	{#State 95
		ACTIONS => {
			"\"" => 37,
			'NOT' => 72,
			"\$" => 39,
			'IDENT' => 40,
			"(" => 75,
			"[" => 12,
			"{" => 29,
			"\${" => 33,
			'LITERAL' => 34
		},
		GOTOS => {
			'term' => 76,
			'ident' => 16,
			'assign' => 74,
			'item' => 35,
			'expr' => 146
		}
	},
	{#State 96
		ACTIONS => {
			'IDENT' => 69
		},
		GOTOS => {
			'textdot' => 67,
			'useparam' => 147
		}
	},
	{#State 97
		ACTIONS => {
			"\"" => 37,
			'NOT' => 72,
			"\$" => 39,
			'IDENT' => 40,
			"(" => 75,
			"[" => 12,
			"{" => 29,
			"\${" => 33,
			'LITERAL' => 34
		},
		GOTOS => {
			'term' => 76,
			'ident' => 16,
			'assign' => 74,
			'item' => 35,
			'expr' => 148
		}
	},
	{#State 98
		ACTIONS => {
			"\"" => 37,
			'NOT' => 72,
			"\$" => 39,
			'IDENT' => 40,
			"(" => 75,
			"[" => 12,
			"{" => 29,
			"\${" => 33,
			'LITERAL' => 34
		},
		GOTOS => {
			'term' => 76,
			'ident' => 16,
			'assign' => 74,
			'item' => 35,
			'expr' => 149
		}
	},
	{#State 99
		DEFAULT => -57
	},
	{#State 100
		ACTIONS => {
			"\"" => 37,
			"\$" => 39,
			'IDENT' => 154,
			"[" => 12,
			"{" => 29,
			"\${" => 33,
			'LITERAL' => 152
		},
		DEFAULT => -85,
		GOTOS => {
			'term' => 155,
			'param' => 150,
			'arg' => 156,
			'ident' => 45,
			'args' => 153,
			'arglist' => 151,
			'item' => 35
		}
	},
	{#State 101
		ACTIONS => {
			"\"" => 37,
			"{" => 29,
			"[" => 12,
			"\$" => 39,
			'IDENT' => 40,
			'LITERAL' => 46,
			"\${" => 33
		},
		GOTOS => {
			'term' => 157,
			'ident' => 45,
			'item' => 35
		}
	},
	{#State 102
		ACTIONS => {
			";" => 158,
			'OR' => 123,
			'AND' => 124,
			'COMPOP' => 126
		}
	},
	{#State 103
		DEFAULT => -6
	},
	{#State 104
		ACTIONS => {
			'IDENT' => 159
		}
	},
	{#State 105
		ACTIONS => {
			'IDENT' => 160
		}
	},
	{#State 106
		ACTIONS => {
			"\$" => 39,
			'IDENT' => 40,
			'LITERAL' => 56,
			"\${" => 33,
			'COMMA' => 61
		},
		DEFAULT => -69,
		GOTOS => {
			'ident' => 55,
			'assign' => 60,
			'item' => 35
		}
	},
	{#State 107
		DEFAULT => -19
	},
	{#State 108
		ACTIONS => {
			"\"" => 161,
			";" => 142,
			"\$" => 39,
			'IDENT' => 40,
			"\${" => 33,
			'TEXT' => 140
		},
		GOTOS => {
			'ident' => 141,
			'quotable' => 144,
			'item' => 35
		}
	},
	{#State 109
		ACTIONS => {
			'DOT' => 70
		},
		DEFAULT => -93
	},
	{#State 110
		ACTIONS => {
			'RETURN' => 23,
			'GET' => 1,
			'CATCH' => 24,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'FILTER' => 27,
			'STOP' => 7,
			'DEBUG' => 28,
			'FOR' => 8,
			";" => -14,
			"{" => 29,
			"[" => 12,
			'ERROR' => 30,
			'BLOCK' => 13,
			'SET' => 14,
			'LITERAL' => 34,
			"\${" => 33,
			'USE' => 15,
			'IF' => 36,
			"\"" => 37,
			"\$" => 39,
			'THROW' => 41,
			'IDENT' => 40,
			'WHILE' => 43,
			'UNLESS' => 18,
			'PROCESS' => 21
		},
		DEFAULT => -2,
		GOTOS => {
			'atomdir' => 38,
			'return' => 22,
			'catch' => 2,
			'ident' => 16,
			'assign' => 25,
			'filter' => 26,
			'condition' => 10,
			'debug' => 9,
			'term' => 42,
			'setlist' => 11,
			'chunk' => 17,
			'defblock' => 20,
			'loop' => 19,
			'block' => 162,
			'chunks' => 32,
			'directive' => 44,
			'item' => 35
		}
	},
	{#State 111
		ACTIONS => {
			"\"" => 37,
			"{" => 29,
			"[" => 12,
			"\$" => 39,
			'IDENT' => 40,
			'LITERAL' => 46,
			"\${" => 33
		},
		GOTOS => {
			'term' => 163,
			'ident' => 45,
			'item' => 35
		}
	},
	{#State 112
		DEFAULT => -50
	},
	{#State 113
		ACTIONS => {
			"(" => 164
		},
		DEFAULT => -51
	},
	{#State 114
		DEFAULT => -64
	},
	{#State 115
		DEFAULT => -63
	},
	{#State 116
		ACTIONS => {
			"\"" => 37,
			"{" => 29,
			"[" => 12,
			"\$" => 39,
			'IDENT' => 40,
			'LITERAL' => 46,
			"\${" => 33
		},
		GOTOS => {
			'term' => 165,
			'ident' => 45,
			'item' => 35
		}
	},
	{#State 117
		ACTIONS => {
			'RETURN' => 23,
			'GET' => 1,
			'CATCH' => 24,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'FILTER' => 27,
			'STOP' => 7,
			'DEBUG' => 28,
			'FOR' => 8,
			";" => -14,
			"{" => 29,
			"[" => 12,
			'ERROR' => 30,
			'BLOCK' => 13,
			'SET' => 14,
			'LITERAL' => 34,
			"\${" => 33,
			'USE' => 15,
			'IF' => 36,
			"\"" => 37,
			"\$" => 39,
			'THROW' => 41,
			'IDENT' => 40,
			'WHILE' => 43,
			'UNLESS' => 18,
			'PROCESS' => 21
		},
		DEFAULT => -2,
		GOTOS => {
			'atomdir' => 38,
			'return' => 22,
			'catch' => 2,
			'ident' => 16,
			'assign' => 25,
			'filter' => 26,
			'condition' => 10,
			'debug' => 9,
			'term' => 42,
			'setlist' => 11,
			'chunk' => 17,
			'defblock' => 20,
			'loop' => 19,
			'block' => 166,
			'chunks' => 32,
			'directive' => 44,
			'item' => 35
		}
	},
	{#State 118
		ACTIONS => {
			"\"" => 37,
			"\$" => 39,
			'IDENT' => 154,
			"[" => 12,
			"{" => 29,
			"\${" => 33,
			'LITERAL' => 152
		},
		DEFAULT => -85,
		GOTOS => {
			'term' => 155,
			'param' => 150,
			'arg' => 156,
			'ident' => 45,
			'args' => 167,
			'arglist' => 151,
			'item' => 35
		}
	},
	{#State 119
		ACTIONS => {
			'IDENT' => 53
		},
		GOTOS => {
			'textdot' => 168
		}
	},
	{#State 120
		DEFAULT => -55
	},
	{#State 121
		DEFAULT => -61
	},
	{#State 122
		ACTIONS => {
			'COMPOP' => 126
		},
		DEFAULT => -89
	},
	{#State 123
		ACTIONS => {
			"\"" => 37,
			'NOT' => 72,
			"\$" => 39,
			'IDENT' => 40,
			"(" => 75,
			"[" => 12,
			"{" => 29,
			"\${" => 33,
			'LITERAL' => 34
		},
		GOTOS => {
			'term' => 76,
			'ident' => 16,
			'assign' => 74,
			'item' => 35,
			'expr' => 169
		}
	},
	{#State 124
		ACTIONS => {
			"\"" => 37,
			'NOT' => 72,
			"\$" => 39,
			'IDENT' => 40,
			"(" => 75,
			"[" => 12,
			"{" => 29,
			"\${" => 33,
			'LITERAL' => 34
		},
		GOTOS => {
			'term' => 76,
			'ident' => 16,
			'assign' => 74,
			'item' => 35,
			'expr' => 170
		}
	},
	{#State 125
		ACTIONS => {
			'RETURN' => 23,
			'GET' => 1,
			'CATCH' => 24,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'FILTER' => 27,
			'STOP' => 7,
			'DEBUG' => 28,
			'FOR' => 8,
			";" => -14,
			"{" => 29,
			"[" => 12,
			'ERROR' => 30,
			'BLOCK' => 13,
			'SET' => 14,
			'LITERAL' => 34,
			"\${" => 33,
			'USE' => 15,
			'IF' => 36,
			"\"" => 37,
			"\$" => 39,
			'THROW' => 41,
			'IDENT' => 40,
			'WHILE' => 43,
			'UNLESS' => 18,
			'PROCESS' => 21
		},
		DEFAULT => -2,
		GOTOS => {
			'atomdir' => 38,
			'return' => 22,
			'catch' => 2,
			'ident' => 16,
			'assign' => 25,
			'filter' => 26,
			'condition' => 10,
			'debug' => 9,
			'term' => 42,
			'setlist' => 11,
			'chunk' => 17,
			'defblock' => 20,
			'loop' => 19,
			'block' => 171,
			'chunks' => 32,
			'directive' => 44,
			'item' => 35
		}
	},
	{#State 126
		ACTIONS => {
			"\"" => 37,
			'NOT' => 72,
			"\$" => 39,
			'IDENT' => 40,
			"(" => 75,
			"[" => 12,
			"{" => 29,
			"\${" => 33,
			'LITERAL' => 34
		},
		GOTOS => {
			'term' => 76,
			'ident' => 16,
			'assign' => 74,
			'item' => 35,
			'expr' => 172
		}
	},
	{#State 127
		ACTIONS => {
			'OR' => 123,
			'AND' => 124,
			'COMPOP' => 126,
			")" => 173
		}
	},
	{#State 128
		DEFAULT => -20
	},
	{#State 129
		ACTIONS => {
			'END' => 174
		}
	},
	{#State 130
		ACTIONS => {
			'RETURN' => 23,
			'GET' => 1,
			'CATCH' => 24,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'FILTER' => 27,
			'STOP' => 7,
			'DEBUG' => 28,
			'FOR' => 8,
			";" => -14,
			"{" => 29,
			"[" => 12,
			'ERROR' => 30,
			'BLOCK' => 13,
			'SET' => 14,
			'LITERAL' => 34,
			"\${" => 33,
			'USE' => 15,
			'IF' => 36,
			"\"" => 37,
			"\$" => 39,
			'THROW' => 41,
			'IDENT' => 40,
			'WHILE' => 43,
			'UNLESS' => 18,
			'PROCESS' => 21
		},
		DEFAULT => -2,
		GOTOS => {
			'atomdir' => 38,
			'return' => 22,
			'catch' => 2,
			'ident' => 16,
			'assign' => 25,
			'filter' => 26,
			'condition' => 10,
			'debug' => 9,
			'term' => 42,
			'setlist' => 11,
			'chunk' => 17,
			'defblock' => 20,
			'loop' => 19,
			'block' => 175,
			'chunks' => 32,
			'directive' => 44,
			'item' => 35
		}
	},
	{#State 131
		ACTIONS => {
			'RETURN' => 23,
			'GET' => 1,
			'CATCH' => 24,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'FILTER' => 27,
			'STOP' => 7,
			'DEBUG' => 28,
			'FOR' => 8,
			";" => -14,
			"{" => 29,
			"[" => 12,
			'ERROR' => 30,
			'BLOCK' => 13,
			'SET' => 14,
			'LITERAL' => 34,
			"\${" => 33,
			'USE' => 15,
			'IF' => 36,
			"\"" => 37,
			"\$" => 39,
			'THROW' => 41,
			'IDENT' => 40,
			'WHILE' => 43,
			'UNLESS' => 18,
			'PROCESS' => 21
		},
		DEFAULT => -2,
		GOTOS => {
			'atomdir' => 38,
			'return' => 22,
			'catch' => 2,
			'ident' => 16,
			'assign' => 25,
			'filter' => 26,
			'condition' => 10,
			'debug' => 9,
			'term' => 42,
			'setlist' => 11,
			'chunk' => 17,
			'defblock' => 20,
			'loop' => 19,
			'block' => 176,
			'chunks' => 32,
			'directive' => 44,
			'item' => 35
		}
	},
	{#State 132
		DEFAULT => -53
	},
	{#State 133
		DEFAULT => -74
	},
	{#State 134
		DEFAULT => -75
	},
	{#State 135
		ACTIONS => {
			"\"" => 37,
			"{" => 29,
			"[" => 12,
			"\$" => 39,
			'IDENT' => 40,
			'LITERAL' => 46,
			"\${" => 33
		},
		GOTOS => {
			'term' => 177,
			'ident' => 45,
			'item' => 35
		}
	},
	{#State 136
		ACTIONS => {
			"\"" => 37,
			"{" => 29,
			"[" => 12,
			"\$" => 39,
			'IDENT' => 40,
			'LITERAL' => 46,
			"\${" => 33
		},
		GOTOS => {
			'term' => 178,
			'ident' => 45,
			'item' => 35
		}
	},
	{#State 137
		DEFAULT => -58
	},
	{#State 138
		DEFAULT => -62
	},
	{#State 139
		ACTIONS => {
			'RETURN' => 23,
			'GET' => 1,
			'CATCH' => 24,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'FILTER' => 27,
			'STOP' => 7,
			'DEBUG' => 28,
			'FOR' => 8,
			";" => -14,
			"{" => 29,
			"[" => 12,
			'ERROR' => 30,
			'BLOCK' => 13,
			'SET' => 14,
			'LITERAL' => 34,
			"\${" => 33,
			'USE' => 15,
			'IF' => 36,
			"\"" => 37,
			"\$" => 39,
			'THROW' => 41,
			'IDENT' => 40,
			'WHILE' => 43,
			'UNLESS' => 18,
			'PROCESS' => 21
		},
		DEFAULT => -2,
		GOTOS => {
			'atomdir' => 38,
			'return' => 22,
			'catch' => 2,
			'ident' => 16,
			'assign' => 25,
			'filter' => 26,
			'condition' => 10,
			'debug' => 9,
			'term' => 42,
			'setlist' => 11,
			'chunk' => 17,
			'defblock' => 20,
			'loop' => 19,
			'block' => 179,
			'chunks' => 32,
			'directive' => 44,
			'item' => 35
		}
	},
	{#State 140
		DEFAULT => -107
	},
	{#State 141
		ACTIONS => {
			'DOT' => 70
		},
		DEFAULT => -106
	},
	{#State 142
		DEFAULT => -108
	},
	{#State 143
		DEFAULT => -54
	},
	{#State 144
		DEFAULT => -104
	},
	{#State 145
		DEFAULT => -39
	},
	{#State 146
		ACTIONS => {
			'OR' => 123,
			'AND' => 124,
			'COMPOP' => 126
		},
		DEFAULT => -34
	},
	{#State 147
		DEFAULT => -45
	},
	{#State 148
		ACTIONS => {
			'OR' => 123,
			'AND' => 124,
			'COMPOP' => 126
		},
		DEFAULT => -32
	},
	{#State 149
		ACTIONS => {
			'OR' => 123,
			'AND' => 124,
			'COMPOP' => 126
		},
		DEFAULT => -41
	},
	{#State 150
		DEFAULT => -79
	},
	{#State 151
		ACTIONS => {
			"\"" => 37,
			"\$" => 39,
			'IDENT' => 154,
			"[" => 12,
			"{" => 29,
			"\${" => 33,
			'LITERAL' => 152,
			'COMMA' => 180
		},
		DEFAULT => -84,
		GOTOS => {
			'term' => 155,
			'param' => 150,
			'arg' => 181,
			'ident' => 45,
			'item' => 35
		}
	},
	{#State 152
		ACTIONS => {
			'ASSIGN' => 135
		},
		DEFAULT => -48
	},
	{#State 153
		ACTIONS => {
			")" => 182
		}
	},
	{#State 154
		ACTIONS => {
			'ASSIGN' => 136,
			"(" => 100
		},
		DEFAULT => -60
	},
	{#State 155
		DEFAULT => -80
	},
	{#State 156
		DEFAULT => -83
	},
	{#State 157
		DEFAULT => -21
	},
	{#State 158
		ACTIONS => {
			'RETURN' => 23,
			'GET' => 1,
			'CATCH' => 24,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'FILTER' => 27,
			'STOP' => 7,
			'DEBUG' => 28,
			'FOR' => 8,
			";" => -14,
			"{" => 29,
			"[" => 12,
			'ERROR' => 30,
			'BLOCK' => 13,
			'SET' => 14,
			'LITERAL' => 34,
			"\${" => 33,
			'USE' => 15,
			'IF' => 36,
			"\"" => 37,
			"\$" => 39,
			'THROW' => 41,
			'IDENT' => 40,
			'WHILE' => 43,
			'UNLESS' => 18,
			'PROCESS' => 21
		},
		DEFAULT => -2,
		GOTOS => {
			'atomdir' => 38,
			'return' => 22,
			'catch' => 2,
			'ident' => 16,
			'assign' => 25,
			'filter' => 26,
			'condition' => 10,
			'debug' => 9,
			'term' => 42,
			'setlist' => 11,
			'chunk' => 17,
			'defblock' => 20,
			'loop' => 19,
			'block' => 183,
			'chunks' => 32,
			'directive' => 44,
			'item' => 35
		}
	},
	{#State 159
		DEFAULT => -97
	},
	{#State 160
		DEFAULT => -98
	},
	{#State 161
		DEFAULT => -94
	},
	{#State 162
		ACTIONS => {
			'END' => 184
		}
	},
	{#State 163
		DEFAULT => -42
	},
	{#State 164
		ACTIONS => {
			"\"" => 37,
			"\$" => 39,
			'IDENT' => 154,
			"[" => 12,
			"{" => 29,
			"\${" => 33,
			'LITERAL' => 152
		},
		DEFAULT => -85,
		GOTOS => {
			'term' => 155,
			'param' => 150,
			'arg' => 156,
			'ident' => 45,
			'args' => 185,
			'arglist' => 151,
			'item' => 35
		}
	},
	{#State 165
		DEFAULT => -71
	},
	{#State 166
		ACTIONS => {
			'END' => 186
		}
	},
	{#State 167
		ACTIONS => {
			")" => 187
		}
	},
	{#State 168
		ACTIONS => {
			"(" => 188,
			'DOT' => 104,
			"/" => 105
		},
		DEFAULT => -101
	},
	{#State 169
		ACTIONS => {
			'COMPOP' => 126
		},
		DEFAULT => -88
	},
	{#State 170
		ACTIONS => {
			'COMPOP' => 126
		},
		DEFAULT => -87
	},
	{#State 171
		ACTIONS => {
			'ELSE' => 190,
			'ELSIF' => 189
		},
		DEFAULT => -37,
		GOTOS => {
			'else' => 191
		}
	},
	{#State 172
		DEFAULT => -86
	},
	{#State 173
		DEFAULT => -90
	},
	{#State 174
		DEFAULT => -30
	},
	{#State 175
		ACTIONS => {
			'END' => 192
		}
	},
	{#State 176
		ACTIONS => {
			'END' => 193
		}
	},
	{#State 177
		DEFAULT => -72
	},
	{#State 178
		DEFAULT => -73
	},
	{#State 179
		ACTIONS => {
			'ELSE' => 190,
			'ELSIF' => 189
		},
		DEFAULT => -37,
		GOTOS => {
			'else' => 194
		}
	},
	{#State 180
		DEFAULT => -82
	},
	{#State 181
		DEFAULT => -81
	},
	{#State 182
		DEFAULT => -59
	},
	{#State 183
		ACTIONS => {
			'END' => 195
		}
	},
	{#State 184
		DEFAULT => -38
	},
	{#State 185
		ACTIONS => {
			")" => 196
		}
	},
	{#State 186
		DEFAULT => -46
	},
	{#State 187
		DEFAULT => -102
	},
	{#State 188
		ACTIONS => {
			"\"" => 37,
			"\$" => 39,
			'IDENT' => 154,
			"[" => 12,
			"{" => 29,
			"\${" => 33,
			'LITERAL' => 152
		},
		DEFAULT => -85,
		GOTOS => {
			'term' => 155,
			'param' => 150,
			'arg' => 156,
			'ident' => 45,
			'args' => 197,
			'arglist' => 151,
			'item' => 35
		}
	},
	{#State 189
		ACTIONS => {
			"\"" => 37,
			'NOT' => 72,
			"\$" => 39,
			'IDENT' => 40,
			"(" => 75,
			"[" => 12,
			"{" => 29,
			"\${" => 33,
			'LITERAL' => 34
		},
		GOTOS => {
			'term' => 76,
			'ident' => 16,
			'assign' => 74,
			'item' => 35,
			'expr' => 198
		}
	},
	{#State 190
		ACTIONS => {
			";" => 199
		}
	},
	{#State 191
		ACTIONS => {
			'END' => 200
		}
	},
	{#State 192
		DEFAULT => -29
	},
	{#State 193
		DEFAULT => -44
	},
	{#State 194
		ACTIONS => {
			'END' => 201
		}
	},
	{#State 195
		DEFAULT => -40
	},
	{#State 196
		DEFAULT => -52
	},
	{#State 197
		ACTIONS => {
			")" => 202
		}
	},
	{#State 198
		ACTIONS => {
			";" => 203,
			'OR' => 123,
			'AND' => 124,
			'COMPOP' => 126
		}
	},
	{#State 199
		ACTIONS => {
			'RETURN' => 23,
			'GET' => 1,
			'CATCH' => 24,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'FILTER' => 27,
			'STOP' => 7,
			'DEBUG' => 28,
			'FOR' => 8,
			";" => -14,
			"{" => 29,
			"[" => 12,
			'ERROR' => 30,
			'BLOCK' => 13,
			'SET' => 14,
			'LITERAL' => 34,
			"\${" => 33,
			'USE' => 15,
			'IF' => 36,
			"\"" => 37,
			"\$" => 39,
			'THROW' => 41,
			'IDENT' => 40,
			'WHILE' => 43,
			'UNLESS' => 18,
			'PROCESS' => 21
		},
		DEFAULT => -2,
		GOTOS => {
			'atomdir' => 38,
			'return' => 22,
			'catch' => 2,
			'ident' => 16,
			'assign' => 25,
			'filter' => 26,
			'condition' => 10,
			'debug' => 9,
			'term' => 42,
			'setlist' => 11,
			'chunk' => 17,
			'defblock' => 20,
			'loop' => 19,
			'block' => 204,
			'chunks' => 32,
			'directive' => 44,
			'item' => 35
		}
	},
	{#State 200
		DEFAULT => -33
	},
	{#State 201
		DEFAULT => -31
	},
	{#State 202
		DEFAULT => -100
	},
	{#State 203
		ACTIONS => {
			'RETURN' => 23,
			'GET' => 1,
			'CATCH' => 24,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'FILTER' => 27,
			'STOP' => 7,
			'DEBUG' => 28,
			'FOR' => 8,
			";" => -14,
			"{" => 29,
			"[" => 12,
			'ERROR' => 30,
			'BLOCK' => 13,
			'SET' => 14,
			'LITERAL' => 34,
			"\${" => 33,
			'USE' => 15,
			'IF' => 36,
			"\"" => 37,
			"\$" => 39,
			'THROW' => 41,
			'IDENT' => 40,
			'WHILE' => 43,
			'UNLESS' => 18,
			'PROCESS' => 21
		},
		DEFAULT => -2,
		GOTOS => {
			'atomdir' => 38,
			'return' => 22,
			'catch' => 2,
			'ident' => 16,
			'assign' => 25,
			'filter' => 26,
			'condition' => 10,
			'debug' => 9,
			'term' => 42,
			'setlist' => 11,
			'chunk' => 17,
			'defblock' => 20,
			'loop' => 19,
			'block' => 205,
			'chunks' => 32,
			'directive' => 44,
			'item' => 35
		}
	},
	{#State 204
		DEFAULT => -35
	},
	{#State 205
		ACTIONS => {
			'ELSE' => 190,
			'ELSIF' => 189
		},
		DEFAULT => -37,
		GOTOS => {
			'else' => 206
		}
	},
	{#State 206
		DEFAULT => -36
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
#line 15 "Parser.yp"
{ $factory->create(Block => $_[1])      }
	],
	[#Rule 2
		 'block', 0,
sub
#line 16 "Parser.yp"
{ $factory->create(Block => [])         }
	],
	[#Rule 3
		 'chunks', 2,
sub
#line 19 "Parser.yp"
{ push(@{$_[1]}, $_[2]) if defined $_[2];
				   $_[1]                                }
	],
	[#Rule 4
		 'chunks', 1,
sub
#line 21 "Parser.yp"
{ defined $_[1] ? [ $_[1] ] : [ ]       }
	],
	[#Rule 5
		 'chunk', 1,
sub
#line 24 "Parser.yp"
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
		 'directive', 0, undef
	],
	[#Rule 15
		 'atomdir', 2,
sub
#line 43 "Parser.yp"
{ $factory->create(Get     => $_[2])    }
	],
	[#Rule 16
		 'atomdir', 2,
sub
#line 44 "Parser.yp"
{ $factory->create(Set     => $_[2])    }
	],
	[#Rule 17
		 'atomdir', 2,
sub
#line 45 "Parser.yp"
{ unshift(@{$_[2]}, OP_DEFAULT);
				  $factory->create(Set     => $_[2])    }
	],
	[#Rule 18
		 'atomdir', 2,
sub
#line 47 "Parser.yp"
{ $factory->create(Use     => @{$_[2]}) }
	],
	[#Rule 19
		 'atomdir', 3,
sub
#line 48 "Parser.yp"
{ $factory->create(Include => @_[2,3])  }
	],
	[#Rule 20
		 'atomdir', 3,
sub
#line 49 "Parser.yp"
{ $factory->create(Process => @_[2,3])  }
	],
	[#Rule 21
		 'atomdir', 3,
sub
#line 50 "Parser.yp"
{ $factory->create(Throw   => @_[2,3])  }
	],
	[#Rule 22
		 'atomdir', 2,
sub
#line 51 "Parser.yp"
{ $factory->create(Error   => $_[2])    }
	],
	[#Rule 23
		 'atomdir', 1,
sub
#line 52 "Parser.yp"
{ $factory->create(Return  => $_[1])    }
	],
	[#Rule 24
		 'atomdir', 1,
sub
#line 53 "Parser.yp"
{ $factory->create(Set     => $_[1])    }
	],
	[#Rule 25
		 'atomdir', 1,
sub
#line 54 "Parser.yp"
{ $factory->create(Get     => $_[1])    }
	],
	[#Rule 26
		 'return', 1,
sub
#line 57 "Parser.yp"
{ STATUS_RETURN }
	],
	[#Rule 27
		 'return', 1,
sub
#line 58 "Parser.yp"
{ STATUS_STOP   }
	],
	[#Rule 28
		 'return', 1,
sub
#line 59 "Parser.yp"
{ STATUS_DONE   }
	],
	[#Rule 29
		 'catch', 5,
sub
#line 63 "Parser.yp"
{ $factory->create(Catch =>, @_[2, 4])    }
	],
	[#Rule 30
		 'catch', 4,
sub
#line 65 "Parser.yp"
{ $factory->create(Catch => undef, $_[3]) }
	],
	[#Rule 31
		 'condition', 6,
sub
#line 69 "Parser.yp"
{ $factory->create(If => @_[2, 4, 5])   }
	],
	[#Rule 32
		 'condition', 3,
sub
#line 70 "Parser.yp"
{ $factory->create(If => @_[3, 1])      }
	],
	[#Rule 33
		 'condition', 6,
sub
#line 72 "Parser.yp"
{ push(@{$_[2]}, OP_NOT);
				  $factory->create(If => @_[2, 4, 5])   }
	],
	[#Rule 34
		 'condition', 3,
sub
#line 74 "Parser.yp"
{ push(@{$_[3]}, OP_NOT);
				  $factory->create(If => @_[3, 1])      }
	],
	[#Rule 35
		 'else', 3,
sub
#line 78 "Parser.yp"
{ $_[3]                                 }
	],
	[#Rule 36
		 'else', 5,
sub
#line 80 "Parser.yp"
{ $factory->create(If => @_[2, 4, 5])   }
	],
	[#Rule 37
		 'else', 0, undef
	],
	[#Rule 38
		 'loop', 5,
sub
#line 85 "Parser.yp"
{ $factory->create(For => @{$_[2]}, $_[4]) }
	],
	[#Rule 39
		 'loop', 3,
sub
#line 86 "Parser.yp"
{ $factory->create(For => @{$_[3]}, $_[1]) }
	],
	[#Rule 40
		 'loop', 5,
sub
#line 88 "Parser.yp"
{ $factory->create(While  => @_[2, 4])   }
	],
	[#Rule 41
		 'loop', 3,
sub
#line 89 "Parser.yp"
{ $factory->create(While  => @_[3, 1])   }
	],
	[#Rule 42
		 'loopvar', 3,
sub
#line 92 "Parser.yp"
{ [ @_[1, 3] ]     }
	],
	[#Rule 43
		 'loopvar', 1,
sub
#line 93 "Parser.yp"
{ [ undef, $_[1] ] }
	],
	[#Rule 44
		 'filter', 5,
sub
#line 97 "Parser.yp"
{ $factory->create(Filter => @{$_[2]}, $_[4]) }
	],
	[#Rule 45
		 'filter', 3,
sub
#line 99 "Parser.yp"
{ $factory->create(Filter => @{$_[3]}, $_[1]) }
	],
	[#Rule 46
		 'defblock', 5,
sub
#line 103 "Parser.yp"
{ $_[0]->define_block(@_[2, 4]); undef  }
	],
	[#Rule 47
		 'debug', 2,
sub
#line 106 "Parser.yp"
{ $factory->create(Debug => $_[2])      }
	],
	[#Rule 48
		 'term', 1,
sub
#line 114 "Parser.yp"
{ [ OP_LITERAL, $_[1]    ] }
	],
	[#Rule 49
		 'term', 1,
sub
#line 115 "Parser.yp"
{ [ OP_IDENT,   $_[1]    ] }
	],
	[#Rule 50
		 'term', 3,
sub
#line 116 "Parser.yp"
{ [ OP_RANGE,   $_[2]    ] }
	],
	[#Rule 51
		 'term', 3,
sub
#line 117 "Parser.yp"
{ [ OP_LIST,    $_[2]    ] }
	],
	[#Rule 52
		 'term', 6,
sub
#line 118 "Parser.yp"
{ [ OP_ITER,    @_[2, 5] ] }
	],
	[#Rule 53
		 'term', 3,
sub
#line 119 "Parser.yp"
{ [ OP_HASH,    $_[2]    ] }
	],
	[#Rule 54
		 'term', 3,
sub
#line 120 "Parser.yp"
{ [ OP_QUOTE,   $_[2]    ] }
	],
	[#Rule 55
		 'ident', 3,
sub
#line 123 "Parser.yp"
{ push(@{$_[1]}, $_[3]); $_[1] }
	],
	[#Rule 56
		 'ident', 1,
sub
#line 124 "Parser.yp"
{ [ $_[1] ] }
	],
	[#Rule 57
		 'ident', 2,
sub
#line 125 "Parser.yp"
{ [ $_[2] ] }
	],
	[#Rule 58
		 'item', 3,
sub
#line 128 "Parser.yp"
{ [ $_[2], 0     ] }
	],
	[#Rule 59
		 'item', 4,
sub
#line 129 "Parser.yp"
{ [ $_[1], $_[3] ] }
	],
	[#Rule 60
		 'item', 1,
sub
#line 130 "Parser.yp"
{ [ $_[1], 0     ] }
	],
	[#Rule 61
		 'assign', 3,
sub
#line 133 "Parser.yp"
{ push(@{$_[3]}, OP_ASSIGN, $_[1]);
					  $_[3] }
	],
	[#Rule 62
		 'assign', 3,
sub
#line 135 "Parser.yp"
{ push(@{$_[3]}, OP_ASSIGN, $_[1]);
					  $_[3] }
	],
	[#Rule 63
		 'list', 2,
sub
#line 139 "Parser.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 64
		 'list', 2,
sub
#line 140 "Parser.yp"
{ $_[1] }
	],
	[#Rule 65
		 'list', 1,
sub
#line 141 "Parser.yp"
{ [ $_[1] ] }
	],
	[#Rule 66
		 'setlist', 2,
sub
#line 144 "Parser.yp"
{ push(@{$_[1]}, @{$_[2]}); $_[1] }
	],
	[#Rule 67
		 'setlist', 2,
sub
#line 145 "Parser.yp"
{ $_[1] }
	],
	[#Rule 68
		 'setlist', 1, undef
	],
	[#Rule 69
		 'setopt', 1, undef
	],
	[#Rule 70
		 'setopt', 0,
sub
#line 150 "Parser.yp"
{ [ ] }
	],
	[#Rule 71
		 'range', 3,
sub
#line 153 "Parser.yp"
{ [ @_[1, 3] ] }
	],
	[#Rule 72
		 'param', 3,
sub
#line 158 "Parser.yp"
{ [ $_[1], $_[3] ] }
	],
	[#Rule 73
		 'param', 3,
sub
#line 159 "Parser.yp"
{ [ $_[1], $_[3] ] }
	],
	[#Rule 74
		 'paramlist', 2,
sub
#line 162 "Parser.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 75
		 'paramlist', 2,
sub
#line 163 "Parser.yp"
{ $_[1] }
	],
	[#Rule 76
		 'paramlist', 1,
sub
#line 164 "Parser.yp"
{ [ $_[1] ] }
	],
	[#Rule 77
		 'params', 1, undef
	],
	[#Rule 78
		 'params', 0,
sub
#line 168 "Parser.yp"
{ [ ] }
	],
	[#Rule 79
		 'arg', 1, undef
	],
	[#Rule 80
		 'arg', 1,
sub
#line 172 "Parser.yp"
{ [ 0, $_[1] ] }
	],
	[#Rule 81
		 'arglist', 2,
sub
#line 175 "Parser.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 82
		 'arglist', 2,
sub
#line 176 "Parser.yp"
{ $_[1] }
	],
	[#Rule 83
		 'arglist', 1,
sub
#line 177 "Parser.yp"
{ [ $_[1] ] }
	],
	[#Rule 84
		 'args', 1,
sub
#line 180 "Parser.yp"
{ [ OP_ARGS, $_[1] ]  }
	],
	[#Rule 85
		 'args', 0,
sub
#line 181 "Parser.yp"
{ [ OP_LITERAL, [ ] ] }
	],
	[#Rule 86
		 'expr', 3,
sub
#line 184 "Parser.yp"
{ push(@{$_[1]}, @{$_[3]}, 
						OP_BINOP, $_[2]); $_[1]     }
	],
	[#Rule 87
		 'expr', 3,
sub
#line 186 "Parser.yp"
{ push(@{$_[1]}, @{$_[3]}, 
						OP_AND); $_[1]       }
	],
	[#Rule 88
		 'expr', 3,
sub
#line 188 "Parser.yp"
{ push(@{$_[1]}, @{$_[3]}, 
						OP_OR); $_[1]        }
	],
	[#Rule 89
		 'expr', 2,
sub
#line 190 "Parser.yp"
{ push(@{$_[2]}, OP_NOT);
					  $_[2]                             }
	],
	[#Rule 90
		 'expr', 3,
sub
#line 192 "Parser.yp"
{ $_[2]                             }
	],
	[#Rule 91
		 'expr', 1, undef
	],
	[#Rule 92
		 'expr', 1, undef
	],
	[#Rule 93
		 'file', 2,
sub
#line 202 "Parser.yp"
{ [ OP_IDENT, $_[2] ] }
	],
	[#Rule 94
		 'file', 3,
sub
#line 203 "Parser.yp"
{ [ OP_QUOTE, $_[2] ] }
	],
	[#Rule 95
		 'file', 1, undef
	],
	[#Rule 96
		 'file', 1, undef
	],
	[#Rule 97
		 'textdot', 3,
sub
#line 210 "Parser.yp"
{ $_[1] .= "$_[2]$_[3]"; $_[1] }
	],
	[#Rule 98
		 'textdot', 3,
sub
#line 211 "Parser.yp"
{ $_[1] .= "$_[2]$_[3]"; $_[1] }
	],
	[#Rule 99
		 'textdot', 1, undef
	],
	[#Rule 100
		 'useparam', 6,
sub
#line 217 "Parser.yp"
{ [ @_[3, 5, 1]         ] }
	],
	[#Rule 101
		 'useparam', 3,
sub
#line 218 "Parser.yp"
{ [ $_[3], undef, $_[1] ] }
	],
	[#Rule 102
		 'useparam', 4,
sub
#line 219 "Parser.yp"
{ [ $_[1], $_[3], undef ] }
	],
	[#Rule 103
		 'useparam', 1,
sub
#line 220 "Parser.yp"
{ [ $_[1], undef, undef ] }
	],
	[#Rule 104
		 'quoted', 2,
sub
#line 226 "Parser.yp"
{ push(@{$_[1]}, $_[2])
						if defined $_[2]; $_[1] }
	],
	[#Rule 105
		 'quoted', 0,
sub
#line 228 "Parser.yp"
{ [ ] }
	],
	[#Rule 106
		 'quotable', 1,
sub
#line 234 "Parser.yp"
{ [ OP_IDENT,   $_[1] ] }
	],
	[#Rule 107
		 'quotable', 1,
sub
#line 235 "Parser.yp"
{ [ OP_LITERAL, $_[1] ] }
	],
	[#Rule 108
		 'quotable', 1,
sub
#line 236 "Parser.yp"
{ undef }
	]
];



1;












