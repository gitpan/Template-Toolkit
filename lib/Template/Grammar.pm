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
# $Id: Grammar.pm,v 1.30 1999/11/03 01:20:32 abw Exp $
#
#========================================================================

package Template::Grammar;

require 5.004;

use strict;
use vars qw( $VERSION );

use Template::Constants qw( :ops :status );

$VERSION = sprintf("%d.%02d", q$Revision: 1.30 $ =~ /(\d+)\.(\d+)/);

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
			'PERL' => 41,
			'THROW' => 43,
			'IDENT' => 42,
			'WHILE' => 45,
			'UNLESS' => 18,
			'PROCESS' => 21
		},
		DEFAULT => -2,
		GOTOS => {
			'atomdir' => 38,
			'return' => 22,
			'perl' => 40,
			'catch' => 2,
			'ident' => 16,
			'assign' => 25,
			'filter' => 26,
			'condition' => 10,
			'debug' => 9,
			'term' => 44,
			'setlist' => 11,
			'chunk' => 17,
			'loop' => 19,
			'defblock' => 20,
			'block' => 31,
			'chunks' => 32,
			'directive' => 46,
			'item' => 35
		}
	},
	{#State 1
		ACTIONS => {
			"\"" => 37,
			"{" => 29,
			"[" => 12,
			"\$" => 39,
			'IDENT' => 42,
			'LITERAL' => 48,
			"\${" => 33
		},
		GOTOS => {
			'term' => 49,
			'ident' => 47,
			'item' => 35
		}
	},
	{#State 2
		DEFAULT => -8
	},
	{#State 3
		ACTIONS => {
			"\"" => 54,
			"\$" => 55,
			'IDENT' => 56,
			'LITERAL' => 53,
			"/" => 51
		},
		GOTOS => {
			'file' => 52,
			'textdot' => 50
		}
	},
	{#State 4
		DEFAULT => -29
	},
	{#State 5
		ACTIONS => {
			"\$" => 39,
			'IDENT' => 42,
			"\${" => 33,
			'LITERAL' => 59
		},
		GOTOS => {
			'setlist' => 57,
			'ident' => 58,
			'assign' => 25,
			'item' => 35
		}
	},
	{#State 6
		DEFAULT => -5
	},
	{#State 7
		DEFAULT => -28
	},
	{#State 8
		ACTIONS => {
			"\"" => 37,
			"{" => 29,
			"[" => 12,
			"\$" => 39,
			'IDENT' => 61,
			'LITERAL' => 48,
			"\${" => 33
		},
		GOTOS => {
			'term' => 62,
			'loopvar' => 60,
			'ident' => 47,
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
			'IDENT' => 42,
			'LITERAL' => 59,
			"\${" => 33,
			'COMMA' => 64
		},
		DEFAULT => -24,
		GOTOS => {
			'ident' => 58,
			'assign' => 63,
			'item' => 35
		}
	},
	{#State 12
		ACTIONS => {
			"\"" => 37,
			"{" => 29,
			"[" => 12,
			"\$" => 39,
			'IDENT' => 42,
			'LITERAL' => 48,
			"\${" => 33
		},
		GOTOS => {
			'term' => 67,
			'list' => 66,
			'ident' => 47,
			'range' => 65,
			'item' => 35
		}
	},
	{#State 13
		ACTIONS => {
			'IDENT' => 56
		},
		GOTOS => {
			'textdot' => 68
		}
	},
	{#State 14
		ACTIONS => {
			"\$" => 39,
			'IDENT' => 42,
			"\${" => 33,
			'LITERAL' => 59
		},
		GOTOS => {
			'setlist' => 69,
			'ident' => 58,
			'assign' => 25,
			'item' => 35
		}
	},
	{#State 15
		ACTIONS => {
			'IDENT' => 72
		},
		GOTOS => {
			'textdot' => 70,
			'useparam' => 71
		}
	},
	{#State 16
		ACTIONS => {
			'ASSIGN' => 74,
			'DOT' => 73
		},
		DEFAULT => -51
	},
	{#State 17
		DEFAULT => -4
	},
	{#State 18
		ACTIONS => {
			"\"" => 37,
			'NOT' => 75,
			"\$" => 39,
			'IDENT' => 42,
			"(" => 78,
			"[" => 12,
			"{" => 29,
			"\${" => 33,
			'LITERAL' => 34
		},
		GOTOS => {
			'term' => 79,
			'ident' => 16,
			'assign' => 77,
			'item' => 35,
			'expr' => 76
		}
	},
	{#State 19
		DEFAULT => -10
	},
	{#State 20
		DEFAULT => -11
	},
	{#State 21
		ACTIONS => {
			"\"" => 54,
			"\$" => 55,
			'IDENT' => 56,
			'LITERAL' => 53,
			"/" => 51
		},
		GOTOS => {
			'file' => 80,
			'textdot' => 50
		}
	},
	{#State 22
		DEFAULT => -23
	},
	{#State 23
		DEFAULT => -27
	},
	{#State 24
		ACTIONS => {
			";" => 81,
			'IDENT' => 82
		}
	},
	{#State 25
		DEFAULT => -71
	},
	{#State 26
		DEFAULT => -26
	},
	{#State 27
		ACTIONS => {
			'IDENT' => 72
		},
		GOTOS => {
			'textdot' => 70,
			'useparam' => 83
		}
	},
	{#State 28
		ACTIONS => {
			'TEXT' => 84
		}
	},
	{#State 29
		ACTIONS => {
			'IDENT' => 89,
			'LITERAL' => 88
		},
		DEFAULT => -81,
		GOTOS => {
			'param' => 85,
			'params' => 86,
			'paramlist' => 87
		}
	},
	{#State 30
		ACTIONS => {
			"\"" => 37,
			"{" => 29,
			"[" => 12,
			"\$" => 39,
			'IDENT' => 42,
			'LITERAL' => 48,
			"\${" => 33
		},
		GOTOS => {
			'term' => 90,
			'ident' => 47,
			'item' => 35
		}
	},
	{#State 31
		ACTIONS => {
			'' => 91
		}
	},
	{#State 32
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
			'UNLESS' => 18,
			'PROCESS' => 21,
			'RETURN' => 23,
			'CATCH' => 24,
			'FILTER' => 27,
			'DEBUG' => 28,
			";" => -14,
			"{" => 29,
			'ERROR' => 30,
			"\${" => 33,
			'LITERAL' => 34,
			'IF' => 36,
			"\"" => 37,
			"\$" => 39,
			'PERL' => 41,
			'IDENT' => 42,
			'THROW' => 43,
			'WHILE' => 45
		},
		DEFAULT => -1,
		GOTOS => {
			'atomdir' => 38,
			'return' => 22,
			'perl' => 40,
			'catch' => 2,
			'ident' => 16,
			'assign' => 25,
			'filter' => 26,
			'condition' => 10,
			'debug' => 9,
			'term' => 44,
			'setlist' => 11,
			'chunk' => 92,
			'defblock' => 20,
			'loop' => 19,
			'directive' => 46,
			'item' => 35
		}
	},
	{#State 33
		ACTIONS => {
			"\"" => 37,
			"{" => 29,
			"[" => 12,
			"\$" => 39,
			'IDENT' => 42,
			'LITERAL' => 48,
			"\${" => 33
		},
		GOTOS => {
			'term' => 93,
			'ident' => 47,
			'item' => 35
		}
	},
	{#State 34
		ACTIONS => {
			'ASSIGN' => 94
		},
		DEFAULT => -50
	},
	{#State 35
		DEFAULT => -59
	},
	{#State 36
		ACTIONS => {
			"\"" => 37,
			'NOT' => 75,
			"\$" => 39,
			'IDENT' => 42,
			"(" => 78,
			"[" => 12,
			"{" => 29,
			"\${" => 33,
			'LITERAL' => 34
		},
		GOTOS => {
			'term' => 79,
			'ident' => 16,
			'assign' => 77,
			'item' => 35,
			'expr' => 95
		}
	},
	{#State 37
		DEFAULT => -109,
		GOTOS => {
			'quoted' => 96
		}
	},
	{#State 38
		ACTIONS => {
			'WHILE' => 101,
			'UNLESS' => 98,
			'FILTER' => 99,
			'IF' => 100,
			'FOR' => 97
		},
		DEFAULT => -7
	},
	{#State 39
		ACTIONS => {
			'IDENT' => 42,
			"\${" => 33
		},
		GOTOS => {
			'item' => 102
		}
	},
	{#State 40
		DEFAULT => -12
	},
	{#State 41
		ACTIONS => {
			";" => 103
		}
	},
	{#State 42
		ACTIONS => {
			"(" => 104
		},
		DEFAULT => -63
	},
	{#State 43
		ACTIONS => {
			'IDENT' => 105
		}
	},
	{#State 44
		DEFAULT => -25
	},
	{#State 45
		ACTIONS => {
			"\"" => 37,
			'NOT' => 75,
			"\$" => 39,
			'IDENT' => 42,
			"(" => 78,
			"[" => 12,
			"{" => 29,
			"\${" => 33,
			'LITERAL' => 34
		},
		GOTOS => {
			'term' => 79,
			'ident' => 16,
			'assign' => 77,
			'item' => 35,
			'expr' => 106
		}
	},
	{#State 46
		ACTIONS => {
			";" => 107
		}
	},
	{#State 47
		ACTIONS => {
			'DOT' => 73
		},
		DEFAULT => -51
	},
	{#State 48
		DEFAULT => -50
	},
	{#State 49
		DEFAULT => -15
	},
	{#State 50
		ACTIONS => {
			'DOT' => 108,
			"/" => 109
		},
		DEFAULT => -99
	},
	{#State 51
		ACTIONS => {
			'IDENT' => 56
		},
		GOTOS => {
			'textdot' => 110
		}
	},
	{#State 52
		ACTIONS => {
			"\$" => 39,
			'IDENT' => 42,
			'LITERAL' => 59,
			"\${" => 33
		},
		DEFAULT => -73,
		GOTOS => {
			'setlist' => 111,
			'ident' => 58,
			'assign' => 25,
			'setopt' => 112,
			'item' => 35
		}
	},
	{#State 53
		DEFAULT => -100
	},
	{#State 54
		DEFAULT => -109,
		GOTOS => {
			'quoted' => 113
		}
	},
	{#State 55
		ACTIONS => {
			"\$" => 39,
			'IDENT' => 42,
			"\${" => 33
		},
		GOTOS => {
			'ident' => 114,
			'item' => 35
		}
	},
	{#State 56
		DEFAULT => -103
	},
	{#State 57
		ACTIONS => {
			"\$" => 39,
			'IDENT' => 42,
			'LITERAL' => 59,
			"\${" => 33,
			'COMMA' => 64
		},
		DEFAULT => -17,
		GOTOS => {
			'ident' => 58,
			'assign' => 63,
			'item' => 35
		}
	},
	{#State 58
		ACTIONS => {
			'ASSIGN' => 74,
			'DOT' => 73
		}
	},
	{#State 59
		ACTIONS => {
			'ASSIGN' => 94
		}
	},
	{#State 60
		ACTIONS => {
			";" => 115
		}
	},
	{#State 61
		ACTIONS => {
			'ASSIGN' => 116,
			"(" => 104
		},
		DEFAULT => -63
	},
	{#State 62
		DEFAULT => -44
	},
	{#State 63
		DEFAULT => -69
	},
	{#State 64
		DEFAULT => -70
	},
	{#State 65
		ACTIONS => {
			"]" => 117
		}
	},
	{#State 66
		ACTIONS => {
			"\"" => 37,
			"\$" => 39,
			'IDENT' => 42,
			"[" => 12,
			"{" => 29,
			"]" => 118,
			"\${" => 33,
			'LITERAL' => 48,
			'COMMA' => 119
		},
		GOTOS => {
			'term' => 120,
			'ident' => 47,
			'item' => 35
		}
	},
	{#State 67
		ACTIONS => {
			'TO' => 121
		},
		DEFAULT => -68
	},
	{#State 68
		ACTIONS => {
			";" => 122,
			"/" => 109,
			'DOT' => 108
		}
	},
	{#State 69
		ACTIONS => {
			"\$" => 39,
			'IDENT' => 42,
			'LITERAL' => 59,
			"\${" => 33,
			'COMMA' => 64
		},
		DEFAULT => -16,
		GOTOS => {
			'ident' => 58,
			'assign' => 63,
			'item' => 35
		}
	},
	{#State 70
		ACTIONS => {
			"(" => 123,
			'DOT' => 108,
			"/" => 109
		},
		DEFAULT => -107
	},
	{#State 71
		DEFAULT => -18
	},
	{#State 72
		ACTIONS => {
			'ASSIGN' => 124
		},
		DEFAULT => -103
	},
	{#State 73
		ACTIONS => {
			'IDENT' => 42,
			'LITERAL' => 125,
			"\${" => 33
		},
		GOTOS => {
			'item' => 126
		}
	},
	{#State 74
		ACTIONS => {
			"\"" => 37,
			"{" => 29,
			"[" => 12,
			"\$" => 39,
			'IDENT' => 42,
			'LITERAL' => 48,
			"\${" => 33
		},
		GOTOS => {
			'term' => 127,
			'ident' => 47,
			'item' => 35
		}
	},
	{#State 75
		ACTIONS => {
			"\"" => 37,
			'NOT' => 75,
			"\$" => 39,
			'IDENT' => 42,
			"(" => 78,
			"[" => 12,
			"{" => 29,
			"\${" => 33,
			'LITERAL' => 34
		},
		GOTOS => {
			'term' => 79,
			'ident' => 16,
			'assign' => 77,
			'item' => 35,
			'expr' => 128
		}
	},
	{#State 76
		ACTIONS => {
			";" => 131,
			'OR' => 129,
			'AND' => 130,
			'COMPOP' => 132
		}
	},
	{#State 77
		DEFAULT => -94
	},
	{#State 78
		ACTIONS => {
			"\"" => 37,
			'NOT' => 75,
			"\$" => 39,
			'IDENT' => 42,
			"(" => 78,
			"[" => 12,
			"{" => 29,
			"\${" => 33,
			'LITERAL' => 34
		},
		GOTOS => {
			'term' => 79,
			'ident' => 16,
			'assign' => 77,
			'item' => 35,
			'expr' => 133
		}
	},
	{#State 79
		DEFAULT => -95
	},
	{#State 80
		ACTIONS => {
			"\$" => 39,
			'IDENT' => 42,
			'LITERAL' => 59,
			"\${" => 33
		},
		DEFAULT => -73,
		GOTOS => {
			'setlist' => 111,
			'ident' => 58,
			'assign' => 25,
			'setopt' => 134,
			'item' => 35
		}
	},
	{#State 81
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
			'PERL' => 41,
			'THROW' => 43,
			'IDENT' => 42,
			'WHILE' => 45,
			'UNLESS' => 18,
			'PROCESS' => 21
		},
		DEFAULT => -2,
		GOTOS => {
			'atomdir' => 38,
			'return' => 22,
			'perl' => 40,
			'catch' => 2,
			'ident' => 16,
			'assign' => 25,
			'filter' => 26,
			'condition' => 10,
			'debug' => 9,
			'term' => 44,
			'setlist' => 11,
			'chunk' => 17,
			'defblock' => 20,
			'loop' => 19,
			'block' => 135,
			'chunks' => 32,
			'directive' => 46,
			'item' => 35
		}
	},
	{#State 82
		ACTIONS => {
			";" => 136
		}
	},
	{#State 83
		ACTIONS => {
			";" => 137
		}
	},
	{#State 84
		DEFAULT => -49
	},
	{#State 85
		DEFAULT => -79
	},
	{#State 86
		ACTIONS => {
			"}" => 138
		}
	},
	{#State 87
		ACTIONS => {
			'IDENT' => 89,
			'COMMA' => 140,
			'LITERAL' => 88
		},
		DEFAULT => -80,
		GOTOS => {
			'param' => 139
		}
	},
	{#State 88
		ACTIONS => {
			'ASSIGN' => 141
		}
	},
	{#State 89
		ACTIONS => {
			'ASSIGN' => 142
		}
	},
	{#State 90
		DEFAULT => -22
	},
	{#State 91
		DEFAULT => -0
	},
	{#State 92
		DEFAULT => -3
	},
	{#State 93
		ACTIONS => {
			"}" => 143
		}
	},
	{#State 94
		ACTIONS => {
			"\"" => 37,
			"{" => 29,
			"[" => 12,
			"\$" => 39,
			'IDENT' => 42,
			'LITERAL' => 48,
			"\${" => 33
		},
		GOTOS => {
			'term' => 144,
			'ident' => 47,
			'item' => 35
		}
	},
	{#State 95
		ACTIONS => {
			";" => 145,
			'OR' => 129,
			'AND' => 130,
			'COMPOP' => 132
		}
	},
	{#State 96
		ACTIONS => {
			"\"" => 149,
			";" => 148,
			"\$" => 39,
			'IDENT' => 42,
			"\${" => 33,
			'TEXT' => 146
		},
		GOTOS => {
			'ident' => 147,
			'quotable' => 150,
			'item' => 35
		}
	},
	{#State 97
		ACTIONS => {
			"\"" => 37,
			"{" => 29,
			"[" => 12,
			"\$" => 39,
			'IDENT' => 61,
			'LITERAL' => 48,
			"\${" => 33
		},
		GOTOS => {
			'term' => 62,
			'loopvar' => 151,
			'ident' => 47,
			'item' => 35
		}
	},
	{#State 98
		ACTIONS => {
			"\"" => 37,
			'NOT' => 75,
			"\$" => 39,
			'IDENT' => 42,
			"(" => 78,
			"[" => 12,
			"{" => 29,
			"\${" => 33,
			'LITERAL' => 34
		},
		GOTOS => {
			'term' => 79,
			'ident' => 16,
			'assign' => 77,
			'item' => 35,
			'expr' => 152
		}
	},
	{#State 99
		ACTIONS => {
			'IDENT' => 72
		},
		GOTOS => {
			'textdot' => 70,
			'useparam' => 153
		}
	},
	{#State 100
		ACTIONS => {
			"\"" => 37,
			'NOT' => 75,
			"\$" => 39,
			'IDENT' => 42,
			"(" => 78,
			"[" => 12,
			"{" => 29,
			"\${" => 33,
			'LITERAL' => 34
		},
		GOTOS => {
			'term' => 79,
			'ident' => 16,
			'assign' => 77,
			'item' => 35,
			'expr' => 154
		}
	},
	{#State 101
		ACTIONS => {
			"\"" => 37,
			'NOT' => 75,
			"\$" => 39,
			'IDENT' => 42,
			"(" => 78,
			"[" => 12,
			"{" => 29,
			"\${" => 33,
			'LITERAL' => 34
		},
		GOTOS => {
			'term' => 79,
			'ident' => 16,
			'assign' => 77,
			'item' => 35,
			'expr' => 155
		}
	},
	{#State 102
		DEFAULT => -60
	},
	{#State 103
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
			'PERL' => 41,
			'THROW' => 43,
			'IDENT' => 42,
			'WHILE' => 45,
			'UNLESS' => 18,
			'PROCESS' => 21
		},
		DEFAULT => -2,
		GOTOS => {
			'atomdir' => 38,
			'return' => 22,
			'perl' => 40,
			'catch' => 2,
			'ident' => 16,
			'assign' => 25,
			'filter' => 26,
			'condition' => 10,
			'debug' => 9,
			'term' => 44,
			'setlist' => 11,
			'chunk' => 17,
			'defblock' => 20,
			'loop' => 19,
			'block' => 156,
			'chunks' => 32,
			'directive' => 46,
			'item' => 35
		}
	},
	{#State 104
		ACTIONS => {
			"\"" => 37,
			"\$" => 39,
			'IDENT' => 161,
			"[" => 12,
			"{" => 29,
			"\${" => 33,
			'LITERAL' => 159
		},
		DEFAULT => -88,
		GOTOS => {
			'term' => 162,
			'param' => 157,
			'arg' => 163,
			'ident' => 47,
			'args' => 160,
			'arglist' => 158,
			'item' => 35
		}
	},
	{#State 105
		ACTIONS => {
			"\"" => 37,
			"{" => 29,
			"[" => 12,
			"\$" => 39,
			'IDENT' => 42,
			'LITERAL' => 48,
			"\${" => 33
		},
		GOTOS => {
			'term' => 164,
			'ident' => 47,
			'item' => 35
		}
	},
	{#State 106
		ACTIONS => {
			";" => 165,
			'OR' => 129,
			'AND' => 130,
			'COMPOP' => 132
		}
	},
	{#State 107
		DEFAULT => -6
	},
	{#State 108
		ACTIONS => {
			'IDENT' => 166
		}
	},
	{#State 109
		ACTIONS => {
			'IDENT' => 167
		}
	},
	{#State 110
		ACTIONS => {
			'DOT' => 108,
			"/" => 109
		},
		DEFAULT => -98
	},
	{#State 111
		ACTIONS => {
			"\$" => 39,
			'IDENT' => 42,
			'LITERAL' => 59,
			"\${" => 33,
			'COMMA' => 64
		},
		DEFAULT => -72,
		GOTOS => {
			'ident' => 58,
			'assign' => 63,
			'item' => 35
		}
	},
	{#State 112
		DEFAULT => -19
	},
	{#State 113
		ACTIONS => {
			"\"" => 168,
			";" => 148,
			"\$" => 39,
			'IDENT' => 42,
			"\${" => 33,
			'TEXT' => 146
		},
		GOTOS => {
			'ident' => 147,
			'quotable' => 150,
			'item' => 35
		}
	},
	{#State 114
		ACTIONS => {
			'DOT' => 73
		},
		DEFAULT => -96
	},
	{#State 115
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
			'PERL' => 41,
			'THROW' => 43,
			'IDENT' => 42,
			'WHILE' => 45,
			'UNLESS' => 18,
			'PROCESS' => 21
		},
		DEFAULT => -2,
		GOTOS => {
			'atomdir' => 38,
			'return' => 22,
			'perl' => 40,
			'catch' => 2,
			'ident' => 16,
			'assign' => 25,
			'filter' => 26,
			'condition' => 10,
			'debug' => 9,
			'term' => 44,
			'setlist' => 11,
			'chunk' => 17,
			'defblock' => 20,
			'loop' => 19,
			'block' => 169,
			'chunks' => 32,
			'directive' => 46,
			'item' => 35
		}
	},
	{#State 116
		ACTIONS => {
			"\"" => 37,
			"{" => 29,
			"[" => 12,
			"\$" => 39,
			'IDENT' => 42,
			'LITERAL' => 48,
			"\${" => 33
		},
		GOTOS => {
			'term' => 170,
			'ident' => 47,
			'item' => 35
		}
	},
	{#State 117
		DEFAULT => -52
	},
	{#State 118
		ACTIONS => {
			"(" => 171
		},
		DEFAULT => -53
	},
	{#State 119
		DEFAULT => -67
	},
	{#State 120
		DEFAULT => -66
	},
	{#State 121
		ACTIONS => {
			"\"" => 37,
			"{" => 29,
			"[" => 12,
			"\$" => 39,
			'IDENT' => 42,
			'LITERAL' => 48,
			"\${" => 33
		},
		GOTOS => {
			'term' => 172,
			'ident' => 47,
			'item' => 35
		}
	},
	{#State 122
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
			'PERL' => 41,
			'THROW' => 43,
			'IDENT' => 42,
			'WHILE' => 45,
			'UNLESS' => 18,
			'PROCESS' => 21
		},
		DEFAULT => -2,
		GOTOS => {
			'atomdir' => 38,
			'return' => 22,
			'perl' => 40,
			'catch' => 2,
			'ident' => 16,
			'assign' => 25,
			'filter' => 26,
			'condition' => 10,
			'debug' => 9,
			'term' => 44,
			'setlist' => 11,
			'chunk' => 17,
			'defblock' => 20,
			'loop' => 19,
			'block' => 173,
			'chunks' => 32,
			'directive' => 46,
			'item' => 35
		}
	},
	{#State 123
		ACTIONS => {
			"\"" => 37,
			"\$" => 39,
			'IDENT' => 161,
			"[" => 12,
			"{" => 29,
			"\${" => 33,
			'LITERAL' => 159
		},
		DEFAULT => -88,
		GOTOS => {
			'term' => 162,
			'param' => 157,
			'arg' => 163,
			'ident' => 47,
			'args' => 174,
			'arglist' => 158,
			'item' => 35
		}
	},
	{#State 124
		ACTIONS => {
			'IDENT' => 56
		},
		GOTOS => {
			'textdot' => 175
		}
	},
	{#State 125
		DEFAULT => -58
	},
	{#State 126
		DEFAULT => -57
	},
	{#State 127
		DEFAULT => -64
	},
	{#State 128
		ACTIONS => {
			'COMPOP' => 132
		},
		DEFAULT => -92
	},
	{#State 129
		ACTIONS => {
			"\"" => 37,
			'NOT' => 75,
			"\$" => 39,
			'IDENT' => 42,
			"(" => 78,
			"[" => 12,
			"{" => 29,
			"\${" => 33,
			'LITERAL' => 34
		},
		GOTOS => {
			'term' => 79,
			'ident' => 16,
			'assign' => 77,
			'item' => 35,
			'expr' => 176
		}
	},
	{#State 130
		ACTIONS => {
			"\"" => 37,
			'NOT' => 75,
			"\$" => 39,
			'IDENT' => 42,
			"(" => 78,
			"[" => 12,
			"{" => 29,
			"\${" => 33,
			'LITERAL' => 34
		},
		GOTOS => {
			'term' => 79,
			'ident' => 16,
			'assign' => 77,
			'item' => 35,
			'expr' => 177
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
			'PERL' => 41,
			'THROW' => 43,
			'IDENT' => 42,
			'WHILE' => 45,
			'UNLESS' => 18,
			'PROCESS' => 21
		},
		DEFAULT => -2,
		GOTOS => {
			'atomdir' => 38,
			'return' => 22,
			'perl' => 40,
			'catch' => 2,
			'ident' => 16,
			'assign' => 25,
			'filter' => 26,
			'condition' => 10,
			'debug' => 9,
			'term' => 44,
			'setlist' => 11,
			'chunk' => 17,
			'defblock' => 20,
			'loop' => 19,
			'block' => 178,
			'chunks' => 32,
			'directive' => 46,
			'item' => 35
		}
	},
	{#State 132
		ACTIONS => {
			"\"" => 37,
			'NOT' => 75,
			"\$" => 39,
			'IDENT' => 42,
			"(" => 78,
			"[" => 12,
			"{" => 29,
			"\${" => 33,
			'LITERAL' => 34
		},
		GOTOS => {
			'term' => 79,
			'ident' => 16,
			'assign' => 77,
			'item' => 35,
			'expr' => 179
		}
	},
	{#State 133
		ACTIONS => {
			'OR' => 129,
			'AND' => 130,
			'COMPOP' => 132,
			")" => 180
		}
	},
	{#State 134
		DEFAULT => -20
	},
	{#State 135
		ACTIONS => {
			'END' => 181
		}
	},
	{#State 136
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
			'PERL' => 41,
			'THROW' => 43,
			'IDENT' => 42,
			'WHILE' => 45,
			'UNLESS' => 18,
			'PROCESS' => 21
		},
		DEFAULT => -2,
		GOTOS => {
			'atomdir' => 38,
			'return' => 22,
			'perl' => 40,
			'catch' => 2,
			'ident' => 16,
			'assign' => 25,
			'filter' => 26,
			'condition' => 10,
			'debug' => 9,
			'term' => 44,
			'setlist' => 11,
			'chunk' => 17,
			'defblock' => 20,
			'loop' => 19,
			'block' => 182,
			'chunks' => 32,
			'directive' => 46,
			'item' => 35
		}
	},
	{#State 137
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
			'PERL' => 41,
			'THROW' => 43,
			'IDENT' => 42,
			'WHILE' => 45,
			'UNLESS' => 18,
			'PROCESS' => 21
		},
		DEFAULT => -2,
		GOTOS => {
			'atomdir' => 38,
			'return' => 22,
			'perl' => 40,
			'catch' => 2,
			'ident' => 16,
			'assign' => 25,
			'filter' => 26,
			'condition' => 10,
			'debug' => 9,
			'term' => 44,
			'setlist' => 11,
			'chunk' => 17,
			'defblock' => 20,
			'loop' => 19,
			'block' => 183,
			'chunks' => 32,
			'directive' => 46,
			'item' => 35
		}
	},
	{#State 138
		DEFAULT => -55
	},
	{#State 139
		DEFAULT => -77
	},
	{#State 140
		DEFAULT => -78
	},
	{#State 141
		ACTIONS => {
			"\"" => 37,
			"{" => 29,
			"[" => 12,
			"\$" => 39,
			'IDENT' => 42,
			'LITERAL' => 48,
			"\${" => 33
		},
		GOTOS => {
			'term' => 184,
			'ident' => 47,
			'item' => 35
		}
	},
	{#State 142
		ACTIONS => {
			"\"" => 37,
			"{" => 29,
			"[" => 12,
			"\$" => 39,
			'IDENT' => 42,
			'LITERAL' => 48,
			"\${" => 33
		},
		GOTOS => {
			'term' => 185,
			'ident' => 47,
			'item' => 35
		}
	},
	{#State 143
		DEFAULT => -61
	},
	{#State 144
		DEFAULT => -65
	},
	{#State 145
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
			'PERL' => 41,
			'THROW' => 43,
			'IDENT' => 42,
			'WHILE' => 45,
			'UNLESS' => 18,
			'PROCESS' => 21
		},
		DEFAULT => -2,
		GOTOS => {
			'atomdir' => 38,
			'return' => 22,
			'perl' => 40,
			'catch' => 2,
			'ident' => 16,
			'assign' => 25,
			'filter' => 26,
			'condition' => 10,
			'debug' => 9,
			'term' => 44,
			'setlist' => 11,
			'chunk' => 17,
			'defblock' => 20,
			'loop' => 19,
			'block' => 186,
			'chunks' => 32,
			'directive' => 46,
			'item' => 35
		}
	},
	{#State 146
		DEFAULT => -111
	},
	{#State 147
		ACTIONS => {
			'DOT' => 73
		},
		DEFAULT => -110
	},
	{#State 148
		DEFAULT => -112
	},
	{#State 149
		DEFAULT => -56
	},
	{#State 150
		DEFAULT => -108
	},
	{#State 151
		DEFAULT => -40
	},
	{#State 152
		ACTIONS => {
			'OR' => 129,
			'AND' => 130,
			'COMPOP' => 132
		},
		DEFAULT => -35
	},
	{#State 153
		DEFAULT => -46
	},
	{#State 154
		ACTIONS => {
			'OR' => 129,
			'AND' => 130,
			'COMPOP' => 132
		},
		DEFAULT => -33
	},
	{#State 155
		ACTIONS => {
			'OR' => 129,
			'AND' => 130,
			'COMPOP' => 132
		},
		DEFAULT => -42
	},
	{#State 156
		ACTIONS => {
			'END' => 187
		}
	},
	{#State 157
		DEFAULT => -82
	},
	{#State 158
		ACTIONS => {
			"\"" => 37,
			"\$" => 39,
			'IDENT' => 161,
			"[" => 12,
			"{" => 29,
			"\${" => 33,
			'LITERAL' => 159,
			'COMMA' => 188
		},
		DEFAULT => -87,
		GOTOS => {
			'term' => 162,
			'param' => 157,
			'arg' => 189,
			'ident' => 47,
			'item' => 35
		}
	},
	{#State 159
		ACTIONS => {
			'ASSIGN' => 141
		},
		DEFAULT => -50
	},
	{#State 160
		ACTIONS => {
			")" => 190
		}
	},
	{#State 161
		ACTIONS => {
			'ASSIGN' => 142,
			"(" => 104
		},
		DEFAULT => -63
	},
	{#State 162
		DEFAULT => -83
	},
	{#State 163
		DEFAULT => -86
	},
	{#State 164
		DEFAULT => -21
	},
	{#State 165
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
			'PERL' => 41,
			'THROW' => 43,
			'IDENT' => 42,
			'WHILE' => 45,
			'UNLESS' => 18,
			'PROCESS' => 21
		},
		DEFAULT => -2,
		GOTOS => {
			'atomdir' => 38,
			'return' => 22,
			'perl' => 40,
			'catch' => 2,
			'ident' => 16,
			'assign' => 25,
			'filter' => 26,
			'condition' => 10,
			'debug' => 9,
			'term' => 44,
			'setlist' => 11,
			'chunk' => 17,
			'defblock' => 20,
			'loop' => 19,
			'block' => 191,
			'chunks' => 32,
			'directive' => 46,
			'item' => 35
		}
	},
	{#State 166
		DEFAULT => -101
	},
	{#State 167
		DEFAULT => -102
	},
	{#State 168
		DEFAULT => -97
	},
	{#State 169
		ACTIONS => {
			'END' => 192
		}
	},
	{#State 170
		DEFAULT => -43
	},
	{#State 171
		ACTIONS => {
			"\"" => 37,
			"\$" => 39,
			'IDENT' => 161,
			"[" => 12,
			"{" => 29,
			"\${" => 33,
			'LITERAL' => 159
		},
		DEFAULT => -88,
		GOTOS => {
			'term' => 162,
			'param' => 157,
			'arg' => 163,
			'ident' => 47,
			'args' => 193,
			'arglist' => 158,
			'item' => 35
		}
	},
	{#State 172
		DEFAULT => -74
	},
	{#State 173
		ACTIONS => {
			'END' => 194
		}
	},
	{#State 174
		ACTIONS => {
			")" => 195
		}
	},
	{#State 175
		ACTIONS => {
			"(" => 196,
			'DOT' => 108,
			"/" => 109
		},
		DEFAULT => -105
	},
	{#State 176
		ACTIONS => {
			'COMPOP' => 132
		},
		DEFAULT => -91
	},
	{#State 177
		ACTIONS => {
			'COMPOP' => 132
		},
		DEFAULT => -90
	},
	{#State 178
		ACTIONS => {
			'ELSE' => 198,
			'ELSIF' => 197
		},
		DEFAULT => -38,
		GOTOS => {
			'else' => 199
		}
	},
	{#State 179
		DEFAULT => -89
	},
	{#State 180
		DEFAULT => -93
	},
	{#State 181
		DEFAULT => -31
	},
	{#State 182
		ACTIONS => {
			'END' => 200
		}
	},
	{#State 183
		ACTIONS => {
			'END' => 201
		}
	},
	{#State 184
		DEFAULT => -75
	},
	{#State 185
		DEFAULT => -76
	},
	{#State 186
		ACTIONS => {
			'ELSE' => 198,
			'ELSIF' => 197
		},
		DEFAULT => -38,
		GOTOS => {
			'else' => 202
		}
	},
	{#State 187
		DEFAULT => -48
	},
	{#State 188
		DEFAULT => -85
	},
	{#State 189
		DEFAULT => -84
	},
	{#State 190
		DEFAULT => -62
	},
	{#State 191
		ACTIONS => {
			'END' => 203
		}
	},
	{#State 192
		DEFAULT => -39
	},
	{#State 193
		ACTIONS => {
			")" => 204
		}
	},
	{#State 194
		DEFAULT => -47
	},
	{#State 195
		DEFAULT => -106
	},
	{#State 196
		ACTIONS => {
			"\"" => 37,
			"\$" => 39,
			'IDENT' => 161,
			"[" => 12,
			"{" => 29,
			"\${" => 33,
			'LITERAL' => 159
		},
		DEFAULT => -88,
		GOTOS => {
			'term' => 162,
			'param' => 157,
			'arg' => 163,
			'ident' => 47,
			'args' => 205,
			'arglist' => 158,
			'item' => 35
		}
	},
	{#State 197
		ACTIONS => {
			"\"" => 37,
			'NOT' => 75,
			"\$" => 39,
			'IDENT' => 42,
			"(" => 78,
			"[" => 12,
			"{" => 29,
			"\${" => 33,
			'LITERAL' => 34
		},
		GOTOS => {
			'term' => 79,
			'ident' => 16,
			'assign' => 77,
			'item' => 35,
			'expr' => 206
		}
	},
	{#State 198
		ACTIONS => {
			";" => 207
		}
	},
	{#State 199
		ACTIONS => {
			'END' => 208
		}
	},
	{#State 200
		DEFAULT => -30
	},
	{#State 201
		DEFAULT => -45
	},
	{#State 202
		ACTIONS => {
			'END' => 209
		}
	},
	{#State 203
		DEFAULT => -41
	},
	{#State 204
		DEFAULT => -54
	},
	{#State 205
		ACTIONS => {
			")" => 210
		}
	},
	{#State 206
		ACTIONS => {
			";" => 211,
			'OR' => 129,
			'AND' => 130,
			'COMPOP' => 132
		}
	},
	{#State 207
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
			'PERL' => 41,
			'THROW' => 43,
			'IDENT' => 42,
			'WHILE' => 45,
			'UNLESS' => 18,
			'PROCESS' => 21
		},
		DEFAULT => -2,
		GOTOS => {
			'atomdir' => 38,
			'return' => 22,
			'perl' => 40,
			'catch' => 2,
			'ident' => 16,
			'assign' => 25,
			'filter' => 26,
			'condition' => 10,
			'debug' => 9,
			'term' => 44,
			'setlist' => 11,
			'chunk' => 17,
			'defblock' => 20,
			'loop' => 19,
			'block' => 212,
			'chunks' => 32,
			'directive' => 46,
			'item' => 35
		}
	},
	{#State 208
		DEFAULT => -34
	},
	{#State 209
		DEFAULT => -32
	},
	{#State 210
		DEFAULT => -104
	},
	{#State 211
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
			'PERL' => 41,
			'THROW' => 43,
			'IDENT' => 42,
			'WHILE' => 45,
			'UNLESS' => 18,
			'PROCESS' => 21
		},
		DEFAULT => -2,
		GOTOS => {
			'atomdir' => 38,
			'return' => 22,
			'perl' => 40,
			'catch' => 2,
			'ident' => 16,
			'assign' => 25,
			'filter' => 26,
			'condition' => 10,
			'debug' => 9,
			'term' => 44,
			'setlist' => 11,
			'chunk' => 17,
			'defblock' => 20,
			'loop' => 19,
			'block' => 213,
			'chunks' => 32,
			'directive' => 46,
			'item' => 35
		}
	},
	{#State 212
		DEFAULT => -36
	},
	{#State 213
		ACTIONS => {
			'ELSE' => 198,
			'ELSIF' => 197
		},
		DEFAULT => -38,
		GOTOS => {
			'else' => 214
		}
	},
	{#State 214
		DEFAULT => -37
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
		 'atomdir', 1, undef
	],
	[#Rule 27
		 'return', 1,
sub
#line 58 "Parser.yp"
{ STATUS_RETURN }
	],
	[#Rule 28
		 'return', 1,
sub
#line 59 "Parser.yp"
{ STATUS_STOP   }
	],
	[#Rule 29
		 'return', 1,
sub
#line 60 "Parser.yp"
{ STATUS_DONE   }
	],
	[#Rule 30
		 'catch', 5,
sub
#line 64 "Parser.yp"
{ $factory->create(Catch =>, @_[2, 4])    }
	],
	[#Rule 31
		 'catch', 4,
sub
#line 66 "Parser.yp"
{ $factory->create(Catch => undef, $_[3]) }
	],
	[#Rule 32
		 'condition', 6,
sub
#line 70 "Parser.yp"
{ $factory->create(If => @_[2, 4, 5])   }
	],
	[#Rule 33
		 'condition', 3,
sub
#line 71 "Parser.yp"
{ $factory->create(If => @_[3, 1])      }
	],
	[#Rule 34
		 'condition', 6,
sub
#line 73 "Parser.yp"
{ push(@{$_[2]}, OP_NOT);
				  $factory->create(If => @_[2, 4, 5])   }
	],
	[#Rule 35
		 'condition', 3,
sub
#line 75 "Parser.yp"
{ push(@{$_[3]}, OP_NOT);
				  $factory->create(If => @_[3, 1])      }
	],
	[#Rule 36
		 'else', 3,
sub
#line 79 "Parser.yp"
{ $_[3]                                 }
	],
	[#Rule 37
		 'else', 5,
sub
#line 81 "Parser.yp"
{ $factory->create(If => @_[2, 4, 5])   }
	],
	[#Rule 38
		 'else', 0, undef
	],
	[#Rule 39
		 'loop', 5,
sub
#line 86 "Parser.yp"
{ $factory->create(For => @{$_[2]}, $_[4]) }
	],
	[#Rule 40
		 'loop', 3,
sub
#line 87 "Parser.yp"
{ $factory->create(For => @{$_[3]}, $_[1]) }
	],
	[#Rule 41
		 'loop', 5,
sub
#line 89 "Parser.yp"
{ $factory->create(While  => @_[2, 4])   }
	],
	[#Rule 42
		 'loop', 3,
sub
#line 90 "Parser.yp"
{ $factory->create(While  => @_[3, 1])   }
	],
	[#Rule 43
		 'loopvar', 3,
sub
#line 93 "Parser.yp"
{ [ @_[1, 3] ]     }
	],
	[#Rule 44
		 'loopvar', 1,
sub
#line 94 "Parser.yp"
{ [ undef, $_[1] ] }
	],
	[#Rule 45
		 'filter', 5,
sub
#line 98 "Parser.yp"
{ $factory->create(Filter => @{$_[2]}, $_[4]) }
	],
	[#Rule 46
		 'filter', 3,
sub
#line 100 "Parser.yp"
{ $factory->create(Filter => @{$_[3]}, $_[1]) }
	],
	[#Rule 47
		 'defblock', 5,
sub
#line 104 "Parser.yp"
{ $_[0]->define_block(@_[2, 4]); undef  }
	],
	[#Rule 48
		 'perl', 4,
sub
#line 108 "Parser.yp"
{ $factory->create(Perl  => $_[3]) }
	],
	[#Rule 49
		 'debug', 2,
sub
#line 111 "Parser.yp"
{ $factory->create(Debug => $_[2]) }
	],
	[#Rule 50
		 'term', 1,
sub
#line 119 "Parser.yp"
{ [ OP_LITERAL, $_[1]    ] }
	],
	[#Rule 51
		 'term', 1,
sub
#line 120 "Parser.yp"
{ [ OP_IDENT,   $_[1]    ] }
	],
	[#Rule 52
		 'term', 3,
sub
#line 121 "Parser.yp"
{ [ OP_RANGE,   $_[2]    ] }
	],
	[#Rule 53
		 'term', 3,
sub
#line 122 "Parser.yp"
{ [ OP_LIST,    $_[2]    ] }
	],
	[#Rule 54
		 'term', 6,
sub
#line 123 "Parser.yp"
{ [ OP_ITER,    @_[2, 5] ] }
	],
	[#Rule 55
		 'term', 3,
sub
#line 124 "Parser.yp"
{ [ OP_HASH,    $_[2]    ] }
	],
	[#Rule 56
		 'term', 3,
sub
#line 125 "Parser.yp"
{ [ OP_QUOTE,   $_[2]    ] }
	],
	[#Rule 57
		 'ident', 3,
sub
#line 128 "Parser.yp"
{ push(@{$_[1]}, $_[3]); $_[1] }
	],
	[#Rule 58
		 'ident', 3,
sub
#line 129 "Parser.yp"
{ push(@{$_[1]}, [ $_[3], 0 ]); $_[1] }
	],
	[#Rule 59
		 'ident', 1,
sub
#line 130 "Parser.yp"
{ [ $_[1] ] }
	],
	[#Rule 60
		 'ident', 2,
sub
#line 131 "Parser.yp"
{ [ $_[2] ] }
	],
	[#Rule 61
		 'item', 3,
sub
#line 134 "Parser.yp"
{ [ $_[2], 0     ] }
	],
	[#Rule 62
		 'item', 4,
sub
#line 135 "Parser.yp"
{ [ $_[1], $_[3] ] }
	],
	[#Rule 63
		 'item', 1,
sub
#line 136 "Parser.yp"
{ [ $_[1], 0     ] }
	],
	[#Rule 64
		 'assign', 3,
sub
#line 139 "Parser.yp"
{ push(@{$_[3]}, OP_ASSIGN, $_[1]);
					  $_[3] }
	],
	[#Rule 65
		 'assign', 3,
sub
#line 141 "Parser.yp"
{ push(@{$_[3]}, OP_ASSIGN, $_[1]);
					  $_[3] }
	],
	[#Rule 66
		 'list', 2,
sub
#line 145 "Parser.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 67
		 'list', 2,
sub
#line 146 "Parser.yp"
{ $_[1] }
	],
	[#Rule 68
		 'list', 1,
sub
#line 147 "Parser.yp"
{ [ $_[1] ] }
	],
	[#Rule 69
		 'setlist', 2,
sub
#line 150 "Parser.yp"
{ push(@{$_[1]}, @{$_[2]}); $_[1] }
	],
	[#Rule 70
		 'setlist', 2,
sub
#line 151 "Parser.yp"
{ $_[1] }
	],
	[#Rule 71
		 'setlist', 1, undef
	],
	[#Rule 72
		 'setopt', 1, undef
	],
	[#Rule 73
		 'setopt', 0,
sub
#line 156 "Parser.yp"
{ [ ] }
	],
	[#Rule 74
		 'range', 3,
sub
#line 159 "Parser.yp"
{ [ @_[1, 3] ] }
	],
	[#Rule 75
		 'param', 3,
sub
#line 164 "Parser.yp"
{ [ $_[1], $_[3] ] }
	],
	[#Rule 76
		 'param', 3,
sub
#line 165 "Parser.yp"
{ [ $_[1], $_[3] ] }
	],
	[#Rule 77
		 'paramlist', 2,
sub
#line 168 "Parser.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 78
		 'paramlist', 2,
sub
#line 169 "Parser.yp"
{ $_[1] }
	],
	[#Rule 79
		 'paramlist', 1,
sub
#line 170 "Parser.yp"
{ [ $_[1] ] }
	],
	[#Rule 80
		 'params', 1, undef
	],
	[#Rule 81
		 'params', 0,
sub
#line 174 "Parser.yp"
{ [ ] }
	],
	[#Rule 82
		 'arg', 1, undef
	],
	[#Rule 83
		 'arg', 1,
sub
#line 178 "Parser.yp"
{ [ 0, $_[1] ] }
	],
	[#Rule 84
		 'arglist', 2,
sub
#line 181 "Parser.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 85
		 'arglist', 2,
sub
#line 182 "Parser.yp"
{ $_[1] }
	],
	[#Rule 86
		 'arglist', 1,
sub
#line 183 "Parser.yp"
{ [ $_[1] ] }
	],
	[#Rule 87
		 'args', 1,
sub
#line 186 "Parser.yp"
{ [ OP_ARGS, $_[1] ]  }
	],
	[#Rule 88
		 'args', 0,
sub
#line 187 "Parser.yp"
{ [ OP_LITERAL, [ ] ] }
	],
	[#Rule 89
		 'expr', 3,
sub
#line 190 "Parser.yp"
{ push(@{$_[1]}, @{$_[3]}, 
						OP_BINOP, $_[2]); $_[1]  }
	],
	[#Rule 90
		 'expr', 3,
sub
#line 192 "Parser.yp"
{ push(@{$_[1]}, OP_AND, $_[3]); 
					  $_[1]                          }
	],
	[#Rule 91
		 'expr', 3,
sub
#line 194 "Parser.yp"
{ push(@{$_[1]}, OP_OR, $_[3]);
					  $_[1]                          }
	],
	[#Rule 92
		 'expr', 2,
sub
#line 196 "Parser.yp"
{ push(@{$_[2]}, OP_NOT);
					  $_[2]                          }
	],
	[#Rule 93
		 'expr', 3,
sub
#line 198 "Parser.yp"
{ $_[2]                          }
	],
	[#Rule 94
		 'expr', 1, undef
	],
	[#Rule 95
		 'expr', 1, undef
	],
	[#Rule 96
		 'file', 2,
sub
#line 208 "Parser.yp"
{ [ OP_IDENT, $_[2] ] }
	],
	[#Rule 97
		 'file', 3,
sub
#line 209 "Parser.yp"
{ [ OP_QUOTE, $_[2] ] }
	],
	[#Rule 98
		 'file', 2,
sub
#line 210 "Parser.yp"
{ '/' . $_[2]         }
	],
	[#Rule 99
		 'file', 1, undef
	],
	[#Rule 100
		 'file', 1, undef
	],
	[#Rule 101
		 'textdot', 3,
sub
#line 217 "Parser.yp"
{ $_[1] .= "$_[2]$_[3]"; $_[1] }
	],
	[#Rule 102
		 'textdot', 3,
sub
#line 218 "Parser.yp"
{ $_[1] .= "$_[2]$_[3]"; $_[1] }
	],
	[#Rule 103
		 'textdot', 1, undef
	],
	[#Rule 104
		 'useparam', 6,
sub
#line 224 "Parser.yp"
{ [ @_[3, 5, 1]         ] }
	],
	[#Rule 105
		 'useparam', 3,
sub
#line 225 "Parser.yp"
{ [ $_[3], undef, $_[1] ] }
	],
	[#Rule 106
		 'useparam', 4,
sub
#line 226 "Parser.yp"
{ [ $_[1], $_[3], undef ] }
	],
	[#Rule 107
		 'useparam', 1,
sub
#line 227 "Parser.yp"
{ [ $_[1], undef, undef ] }
	],
	[#Rule 108
		 'quoted', 2,
sub
#line 233 "Parser.yp"
{ push(@{$_[1]}, $_[2])
						if defined $_[2]; $_[1] }
	],
	[#Rule 109
		 'quoted', 0,
sub
#line 235 "Parser.yp"
{ [ ] }
	],
	[#Rule 110
		 'quotable', 1,
sub
#line 241 "Parser.yp"
{ [ OP_IDENT,   $_[1] ] }
	],
	[#Rule 111
		 'quotable', 1,
sub
#line 242 "Parser.yp"
{ [ OP_LITERAL, $_[1] ] }
	],
	[#Rule 112
		 'quotable', 1,
sub
#line 243 "Parser.yp"
{ undef }
	]
];



1;












