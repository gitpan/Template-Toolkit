#============================================================= -*-Perl-*-
#
# Template::OS
#
# DESCRIPTION
#   Simple module encapsulating various operating system dependant 
#   variables.   
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
# $Id: OS.pm,v 1.1 1999/08/09 11:47:35 abw Exp $
#
#============================================================================

package Template::OS;

require 5.004;

use strict;
use vars qw( $VERSION $OS $ERROR $AUTOLOAD );

$VERSION  = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);
$OS       = autodetect();
$ERROR    = '';

my @OS_FIELDS = qw( name pathsep pathsplit );
my $OS_LUT = {
    'unix' => [ 'Unix',  '/',  ':'  ],
    'win'  => [ 'Win32', '\\', ', ' ],
    'mac'  => [ 'Mac',   ':',  ', ' ],
    'os2'  => [ 'OS/2',  '\\', ', ' ],
    'vms'  => [ 'VMS',   '/',  ', ' ],
};


#------------------------------------------------------------------------
# new($osname)
#
# Constructor method which creates on OS object specific to the operating
# system specified by name as the first parameter.  Auto-detects if the name 
# is undefined.
#------------------------------------------------------------------------

sub new {
    my ($class, $osname) = @_;
    my ($self, $osinfo);

    $osname ||= $OS || autodetect();
    $osinfo = $OS_LUT->{ $osname } || do {
	$ERROR = "Invalid operating system: $osname";
	return undef;
    };

    $self = { 
	os => $osname,
    };
    @$self{ @OS_FIELDS } = @$osinfo;

    bless $self, $class;
}



#------------------------------------------------------------------------
# autodetect()
#
# Detects the operating system we're currently running under.  Returns an 
# identifier, e.g. 'unix', 'vms', 'win', etc.  This code was borrowed 
# from Lincoln Stein's CGI module and was the original inspiration for
# the OS module.
#------------------------------------------------------------------------

sub autodetect {
    my $os;

    unless ($os = $^O) {
	require Config;
	$os = $Config::Config{'osname'};
    }

    if ($os=~/Win/i) {
	$os = 'win';
    } elsif ($os=~/vms/i) {
	$os = 'vms';
    } elsif ($os=~/^MacOS$/i) {
	$os = 'mac';
    } elsif ($os=~/os2/i) {
	$os = 'os2';
    } else {
	$os = 'unix';
    }

    return $os;
}


#------------------------------------------------------------------------
# AUTOLOAD
#
# Simple autoload method to return $self members when called as methods.
#------------------------------------------------------------------------

sub AUTOLOAD {
    my $self = shift;
    my $method;

    ($method = $AUTOLOAD) =~ s/.*:://;
    return if $method eq 'DESTROY';

    $self->{ $method };
}
    

1;

__END__

=head1 NAME

Template::OS - Operating System specific values

=head1 SYNOPSIS

    use Template::OS;
    
    $os   = Template::OS->new();        # autodetect
    $unix = Template::OS-new('unix');   # or 'mac', 'vms', 'win', 'os2'
    $Template::OS::OS = 'win';          # define $OS to override autodetect
    $win = Template::OS->new();         
    
    # member items
    $os->{'id'};              # 'unix', 'mac', 'win', etc.
    $os->{'name'};            # 'Unix', 'MacOS', 'Win32', etc.
    $os->{'pathsep'};         #  '/', ':', '\\', etc.
    
    # OO interface
    $os->id();		    # as above...
    $os->name()
    $os->pathsep()

=head1 DESCRIPTION

The Template::OS module defines a few convenient operating-system
specific values.

    use OS;

The new() constructor is called to create a Template::OS object (hash)
which contains this information.  By default, the operating system
will be automatically detected unless a specific O/S identifier is
passed as a parameter.  Operating system identifiers may be: 'unix',
'mac', 'win', 'vms' or 'os2'.

    my $os = OS->new;
    my $os   = OS->new('win');

The object returned is a hash array blessed into the OS class.  The 
following items are defined in this hash:

    id       => short identifier, e.g. 'unix', 'win', 'mac'
    name     => name: 'Unix,', 'Win32', 'MacOS'
    pathsep  => path (directory) separator e.g. '/', '\\', ':'

Items in the OS object may therefore be accessed directly.

    print "Running on ", $os->{'name'}, "\n";

Public methods are also provided for accessing such members. 

    print "Running on ", $os->name(), "\n";
    print "Running on ", $os->name, "\n";

=head1 AUTHOR

Andy Wardley E<lt>cre.canon.co.ukE<gt>

=head1 REVISION

$Revision: 1.1 $

=head1 COPYRIGHT

Copyright (C) 1996-1999 Andy Wardley.  All Rights Reserved.
Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template-Toolkit|Template-Toolkit>

=cut


