#============================================================= -*-perl-*-
#
# t/tag.t
#
# Template script testing the START_TAG and END_TAG configuration 
# options.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use strict;
use vars qw($loaded $ntests);
$^W = 1;

BEGIN { 
    $ntests = 16;
    $| = 1; 
    print "1..$ntests\n"; 
}

END {
    ok(0) unless $loaded;
}

my $ok_count = 1;
sub ok {
    shift or print "not ";
    print "ok $ok_count\n";
    ++$ok_count;
}

use Template;
$loaded = 1;
ok(1);

# sample data
my ($a, $b, $c) = qw( alpha bravo charlie );
my $params = {
    'a' => $a,
    'b' => $b,
    'c' => $c,
};
my ($out1, $out2, $out3, $out4, $out5, $error);
my $text = '<+ a +> %% b %% [= c =] [% a %]';

#------------------------------------------------------------------------

#2-4 - create template processors
my $tproc1 = Template->new({
    OUTPUT    => \$out1,
});
my $tproc2 = Template->new({ 
    START_TAG => '\<\+',
    END_TAG   => quotemeta('+>'),
    OUTPUT    => \$out2,
});
my $tproc3 = Template->new({ 
    START_TAG => '\[=',
    END_TAG   => '=\]',
    OUTPUT    => \$out3,
});
my $tproc4 = Template->new({ 
    TAG_STYLE => 'regular',
    OUTPUT    => \$out4,
});
my $tproc5 = Template->new({ 
    TAG_STYLE => 'percent',
    OUTPUT    => \$out5,
});

ok( $tproc1 );
ok( $tproc2 );
ok( $tproc3 );
ok( $tproc4 );
ok( $tproc5 );

#7-11 - run processors
ok( $tproc1->process(\$text, $params) );
ok( $tproc2->process(\$text, $params) );
ok( $tproc3->process(\$text, $params) );
ok( $tproc4->process(\$text, $params) );
ok( $tproc5->process(\$text, $params) );


#12-16 - test output
ok( $out1 eq "<+ a +> $b [= c =] $a" );
ok( $out2 eq "$a %% b %% [= c =] [% a %]" );
ok( $out3 eq "<+ a +> %% b %% $c [% a %]" );
ok( $out4 eq "<+ a +> %% b %% [= c =] $a" );
ok( $out5 eq "<+ a +> $b [= c =] [% a %]" );




