#============================================================= -*-perl-*-
#
# Template
#
# DESCRIPTION
#   Module implementing a simple, user-oriented front-end to the Template 
#   Toolkit.
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
#   $Id: Template.pm,v 1.21 1999/08/04 20:37:49 abw Exp $
#
#========================================================================
 
package Template;

require 5.004;

use strict;
use vars qw( $VERSION @ISA @EXPORT_OK %EXPORT_TAGS );
use Exporter;
use Template::Constants qw( :all );
use Template::Context;

## This is the main version number for the Template Toolkit.
## It is extracted by ExtUtils::MakeMaker and inserted in various places.
$VERSION     = '0.22';

@ISA         = qw( Exporter );
*EXPORT_OK   = \@Template::Constants::EXPORT_OK;
*EXPORT_TAGS = \%Template::Constants::EXPORT_TAGS;


#------------------------------------------------------------------------
# new(\%config)
#
# Constructor method.  Returns a reference to a newly created Template 
# object which can be configured by passing a hash reference parameter.
# A Template::Context object is created and stored internally for future
# delegtion.
#------------------------------------------------------------------------

sub new {
    my ($class, $params) = @_;

    $params->{ CONTEXT } ||= Template::Context->new($params);
 
    bless {
	%$params,
	ERROR => '',
    }, $class;
}



#------------------------------------------------------------------------
# process($template, \%params, ...)
#
# Main processing method which delegates to the CONTEXT process() method.  
# The method returns 1 if the template was successfully processed. 
# On error, 0 is returned and error() can be called to return the 
# error message.
#------------------------------------------------------------------------

sub process {
    my $self = shift;

    my $error = $self->{ CONTEXT }->process(@_);

    # store returned error value or exception as string in ERROR
    $self->{ ERROR } = ref($error) ? $error->as_string : $error;

    # return 1 on numerical or 0 status return, 0 on exception (ref)
    return ref($error) ? 0 : 1;
}



#------------------------------------------------------------------------
# redirect()
# 
# Delegates to $self->{ CONTEXT }->redirect();
#------------------------------------------------------------------------

sub redirect {
    my $self = shift;
    $self->{ CONTEXT }->redirect(@_);
}


#------------------------------------------------------------------------
# context()
# 
# Returns a reference to the internal CONTEXT object
#------------------------------------------------------------------------

sub context {
    $_[0]->{ CONTEXT };
}


#------------------------------------------------------------------------
# error()
# 
# Returns the current contents of $self->{ ERROR } which represents 
# the return code from the most recent call to $context->process(),
# made in process() above.  The error will be numerical to indicate
# that the template was processed sucessfully or a string constructed
# from the exception returned which indicates the error.
#------------------------------------------------------------------------

sub error {
    $_[0]->{ ERROR };
}


#------------------------------------------------------------------------
# DESTROY
#
# Called automatically on object destruction to call the context old()
# method to break circular references.
#------------------------------------------------------------------------

sub DESTROY {
    my $self = shift;
    $self->{ CONTEXT }->old();
    undef %$self;
}


1;

__END__

=head1 NAME

Template - Template processing front-end to the Template Toolkit

=head1 SYNOPSIS

  use Template;

  my $template = Template->new(\%config);

  my %params = (
      var1  => $value,
      var2  => \%hash,
      var3  => \@list,
      var4  => \&code,
      var5  => $object,
  );

  $template->process($input, \%params)
      || die $template->error();

=head1 TEMPLATE DIRECTIVES

  COMMENT   - [% # this is a comment  %]

  GET       - [% GET variable %]
              [%     variable %]

  SET       - [% SET variable = value %]
              [%     variable = other_variable
                     variable = 'literal text @ $100'
                     variable = "interpolated text: $var"
                     variable = [ val, val, val, val, ... ]
                     variable = { var = val, var = val, ... }
              %]

  DEFAULT   - [% DEFAULT variable = value %]  # params as above...

  INCLUDE   - [% INCLUDE template %]
	      [% INCLUDE template params %]

  FOREACH   - [% FOREACH variable = [ val, val, val ] %]
              [% FOREACH variable = value %]
              [% FOREACH value %]
                 content
              [% END %]

  IF/UNLESS - [% IF condition %]
                 content
	      [% ELSIF condition %]
		 content
	      [% ELSE %]
		 content
              [% END %]

              [% UNLESS condition %]
                 content
              [% # ELSIF/ELSE as per IF, above %]
	         content
              [% END %]

  BLOCK     - [% BLOCK template %]
                 content
	      [% END %]

  USE       - [% USE plugin %]
              [% USE plugin( params ) %] 
              [% USE variable = plugin( params ) %]
          
  CATCH     - [% CATCH errtype %]
                 content
              [% END %]

  THROW     - [% THROW errtype value %]

  ERROR     - [% ERROR value %]
     
  RETURN    - [% RETURN %]

  STOP      - [% STOP %]

=head1 OVERVIEW 

The Template Toolkit is a collection of Perl modules which collectively
implement a fast and powerful template processing system.  In this
context, a template is a text document which contains embedded
processing "directives".  These directives instruct the template
processor to perform certain actions and collectively constitute the
I<language> that the toolkit implements.  Anything not specially
marked as a template directive is treated as plain text and gets passed
through intact.  You can choose what mark-up tags to use but in the
default case, directives are embedded [% like this %].

The toolkit is designed to be fast, flexible and easy to use, allowing
you to construct entire content systems from a number of small,
reusable components.  It can be customised, modified and extended to
serve in almost any template-based application.  

It is ideally suited for generating web content, but it is by no means
limited or specific to this or any other application area.  Instead,
it supports a simple "plugin" interface for dynamically loading
extension code to satisfy different requirements.  It encourages the
clean separation of user interface elements (sub-templates) and code
(plugin modules or other Perl objects/code), promoting flexibility,
re-use and ease of development and subsequent maintenance.

The toolkit is a direct descendant of, and replacement for the
Text::MetaText module.  It has been designed and rebuilt from
scratch based on several years of experience gained from developing,
supporting and using Text::MetaText and other template processing
applications and tools.  It is an Open Source project in which
contribution and collaboration are strongly encouraged.  

=head1 FEATURES

=over 4

=item - 

Fast, flexible, generic and open template processing system.

=item -

Simple template "micro-language" provides basic functionality to
manipulate variables (GET/SET), process other template component files
(INCLUDE), iterate through various values (FOREACH) and conditional 
branching (IF/ELSIF/ELSE).

=item -

More complex application code can be developed in Perl (or C, C++, etc) and 
maintained separately.  Template processor binds user code to variables 
to provide access to application functionality from templates.

=item - 

This natural extensibility promotes the separation of the application
from the interface.  Template documents remain simple and focussed on 
rendering the interface.  Application code can be made more generic 
by concentrating on what the application does, not what it looks like.

=item -

Ideally suited, but not limited to, web content generation.  
Front-end modules and/or scripts provided for use with static pages, 
CGI scripts, Apache/mod_perl handlers, etc.

=item -

Template documents parsed by a fast LALR(1) parser which is 
generated from a YACC-like grammar.  Parse::Yapp is used to compile the 
grammar.  Parser grammar can be modified and re-compiled to create custom 
template languages.

=item -

Parsed template documents are compiled to an intermediate form and
cache.  They can subsequently be rendered repeatedly in minimal time.

=item -

Stash object manages references to complex external code and data and 
provides a simple template interface via bound variables.

=item -

Variables may be partitioned into nested namespaces.

=item -

Custom error handling and recovery mechanisms implemented as basic 
exception handling.  Users can define template blocks to be processed 
automatically when errors occur and define the subsequent course of
action.

=item -

Iterator objects can be created to handle complex set iteration.  This is 
handled transparently by the FOREACH directive.

=item -

Provides an extensible framework for other template languages, processors
and applications.

=item -

Template language is independent (theoretically at least) of the
implementation language, platform, operating system, etc.

=item -

Extensive documentation, test suite, examples, etc.

=item -

Fully open source code.  Contributions, collaborations, suggestions and
other feedback welcome.

=item - 

Mailing list: send email to majordomo@cre.canon.co.uk containing the 
text "subscribe templates".

=back

=head1 PREREQUISITES

At present, the Template Toolkit requires Perl 5.005.   Efforts will soon
be made to support I<some> earlier versions (e.g. 5.004).

=head1 OBTAINING AND INSTALLING THE TEMPLATE TOOLKIT

The Template Toolkit module bundle is available from CPAN.  As the 'perlmod' 
manual page explains:

    CPAN stands for the Comprehensive Perl Archive Network.
    This is a globally replicated collection of all known Perl
    materials, including hundreds of unbundled modules.  
    [...]
    For an up-to-date listing of CPAN sites, see
    http://www.perl.com/perl/ or ftp://ftp.perl.com/perl/ .

The module is available as:

    /authors/id/ABW/Template-Toolkit-<version>.tar.gz

Unpack the archive to create an installation directory.  Something
like this:

    zcat Template-Toolkit-<version>.tar.gz | tar xvf -

'cd' into that directory, make, test and install the modules:

    cd Template-Toolkit-<version>
    perl Makefile.PL
    make
    make test
    make install

The 't' sub-directory contains a number of test scripts that are run when 
a 'make test' is run.  You may find some of the examples to be enlightening
and others perplexing.

The 'make install' will install the module on your system.  You may need 
administrator privileges to perform this task.  If you install the module 
in a local directory (for example, by executing "perl Makefile.PL
LIB=~/lib" in the above - see C<perldoc MakeMaker> for full details), you
will need to ensure that the PERL5LIB environment variable is set to
include the location, or add a line to your scripts explicitly naming the
library location:

    use lib '/local/path/to/lib';

=head1 DESCRIPTION

The Template module is a simple front-end to the Template Toolkit.  It
implements a generic template processing object which loads and uses
other Template Toolkit modules as required to process template
documents.

  use Template;
  my $tproc = Template->new();

Constants defined in Template::Constants can be imported by using
the module and specifying import tags.  Alternatively, you can simply
add them to the 'use Template' line which will delegate to the 
Template::Constants module.  

  use Template qw( :status );

The object may be configured by passing a hash reference to the new()
constructor.

  my $tproc = Template->new({
      INTERPOLATE => 1,
      PRE_CHOMP   => 1,
  });

Templates are rendered by calling the process() method on the Template
object.  The first parameter specifies the template input and may be a
filename, a reference to a text string (SCALAR) containing template
text or a reference to a GLOB or IO::Handle (or sub-class) from which
the template should be read.  The process returns 1 if the template
was successfully rendered or 0 if an error occureed.  In the latter
case, the relevant error message can be retrieved by calling the
error() method.

  $tproc->process($myfile)
      || die $tproc->error(), "\n";

The second optional parameter may be a hash reference which defines
variables for use in the template.  The entries in this hash may be
simple values, references to hashes, lists, sub-routines or objects
(described in detail below).

  my $data = {
      'name' => 'John Doe'
      'id'   => 'jdoe',
  };

  $tproc->process($myfile, $data) 
      || die $tproc->error(), "\n";



=head1 TEMPLATE SYNTAX AND DIRECTIVES

=head2 DIRECTIVE TAGS

The default syntax for embedding directives in template documents is
to enclosed them within the character sequences '[%' and '%]'.  See the
START_TAG, END_TAG and TAG_STYLE options for details on how to change
these tokens.

  [% INCLUDE header %]

  <h1>Hello World!</h1>
  <a href="[% page.next %]"><img src="[% icon.next %].gif"></a>

  [% INCLUDE footer %]

For backwards compatibility with Text::MetaText, the default TAG_STYLE
also allows the '%%' token to be used as both the start and end of
tags.

  %% INCLUDE header %%    # for backwards compatibility

Directives may be embedded anywhere in a line of text and can be split 
across several lines.  Whitespace is generally ignored within the 
directive, except where used to separate parameters.

  [% INCLUDE header		   
     title  = 'Hello World' 
     bgcol  = '#ffffff' 
  %]

  [%INCLUDE menu align='right'%]

  Name: [% name %]  ([%id%])

Directives that start with a '#' are treated as comments and ignored.
No output is generated.  This is useful for commenting template documents
or temporarily disabling certain directives.
 
  [% # This is a comment and will be ignored %]

=head2 CLEANING UP WHITESPACE

Anything outside a directive tag is considered plain text and is
generally passed through unaltered (but see INTERPOLATE below).  This
includes all the whitespace and newlines characters surrounding
directive tags.  When tags are processed, they may generate no output
but leave a 'gap' in the output document.

Example:
  Foo
  [% a = 10 %]
  Bar

Output:
  Foo

  Bar

The PRE_CHOMP and POST_CHOMP options help to reduce this extraneous
whitespace.  If a directive appears at the start of a line, or on a
line with nothing but whitespace in front of it, then a PRE_CHOMP will
delete any whitespace and the preceding newline character.  This
effectively moves the directive up onto the previous line.  When a
directive appears at the end of a line, or on a line with nothing but
whitespace following it, then a POST_CHOMP will delete any whitespace
and the following newline.  This effectively moves the next line up
onto the current line.  

       Foo <----------.
                      |
   ,---(PRE-CHOMP)----'
   |
   `-- [% a = 10 %] --.
                      |
   ,---(POST-CHOMP)---'
   |
   `-> Bar

The '-' or '+' processing flags may be added immediately inside the 
start/end tags to enable or disable pre/post chomping options on a 
per-directive basis.

  [%  a = b  %]   # default PRE_CHOMP and POST_CHOMP
  [%- a = b  %]   # do PRE_CHOMP  (remove start of line if blank)
  [%  a = b -%]   # do POST_CHOMP (remove rest of line if blank)
  [%+ a = b  %]   # don't PRE_CHOMP  (leave start of line intact)
  [%  a = b +%]   # don't POST_CHOMP (leave rest of line intact)

See the PRE_CHOMP and POST_CHOMP configuration options, described below.

=head2 VARIABLES

Directives generally comprise a keyword such as INCLUDE, FOREACH, IF,
etc., possibly followed by one or more expressions, parameters, etc.

The GET and SET directives are provided to retrieve (print) and update
variable values, respectively.  For the sake of brevity, the GET and
SET keywords can be omitted and a lone variable will be implicitly
treated as a GET directive while an assignment, or sequence of
assignments will be implicitly treated as a SET directive.

  # explicit
  [% GET foo %]
  [% SET bar=baz %]
  [% SET 
     name  = 'Fred'
     email = 'fred@happy.com'
  %]
 
  # implicit (preferred)
  [% foo %]
  [% bar=baz %]
  [% name  = 'Fred'
     email = 'fred@happy.com'
  %]

The DEFAULT directive is similar to SET but only updates variables 
that are currently undefined or have no "true" value (in the Perl
sense).

  [% DEFAULT
     name = 'John Doe'
     id   = 'jdoe'
  %]

The INTERPOLATE option allows you to embed variables directly into text
without requiring the '[%' and '%]' tags.  Instead, the variable name 
should be prefixed by a '$'.  You can use curly braces to explicitly 
delimit the variable name when required:

  # INTERPOLATE => 1
  <a href="$page.next"><img src="${icon.next}.gif"></a>

With INTERPOLATE set on, any other '$' characters in your document should 
be 'escaped' by prefixing them with a '\':

  Cost: \$100

=head2 BLOCK DIRECTIVES

The FOREACH, BLOCK and CATCH directives mark the start of a block which 
may contain text or other directives (including other nested blocks) up
to the next (balanced) END directive.  The IF, UNLESS, ELSIF and ELSE 
directives also define blocks and may be grouped together in the usual 
manner.

  Metavars:
  [% FOREACH item = [ 'foo' 'bar' 'baz' ] %]
     * Item: [% item %]
  [% END %]

  [% BLOCK footer %]
     Copyright 1999 [% me %]
     [% INCLUDE company/logo %]
  [% END %]

  [% CATCH file %]
     <!-- File error: [% e.info %] -->
     [% IF debugging %]
        [% INCLUDE debugtxt  msg = "file: $e.info" %]
     [% END %]
  [% END %]

  [% IF foo %]
     do this...
  [% ELSIF bar %]
     do that...
  [% ELSE %]
     do nothing...
  [% END %]

The IF, ELSIF and UNLESS directives can be used to process or ignore a
block based on some run-time condition.  Multiple conditions may be
joined with ELSIF and/or ELSE blocks.

The following conditional and boolean operators may be used:

    == != < <= > >= ! && || and or not

Conditions may be arbitrarily complex and are evaluated left-to-right
with conditional operators having a higher precedence over boolean ones.  
Parenthesis may be used to explicitly determine evaluation order.

Examples:

    # simple example
    [% IF age < 10 %]
       Hello [% name %], does your mother know you're 
       using her AOL account?
    [% ELSE %]
       Welcome [% name %].
    [% END %]

    # ridiculously contrived complex example
    [% IF (name == 'admin' || uid <= 0) && (mode == 'debug' || debug) %]
       I'm confused.
    [% ELSIF more > less %]
       That's more or less correct.
    [% END %]

=head2 DIRECTIVE SYNTAX AND STRUCTURE

Multiple directives may be included within a single tag by separating 
them with semi-colons.

  [% IF debugging; 
       INCLUDE debugtxt  msg = "file: $e.info;
     END 
  %]

The IF, UNLESS and FOREACH block directives may be specified
immediately after another directive (except other block directives) in
a convenient 'side-effect' notation.

  [% INCLUDE userinfo FOREACH user = userlist %]
  [% INCLUDE debugtxt msg="file: $e.info" IF debugging %] 
  [% "Danger Will Robinson" IF atrisk %]

The directive keyword may be specified in any case but you might find 
that it helps to adopt the convention of always using UPPER CASE to 
make them visually distinctive from variables.  

  [% FOREACH item = biglist %]   # Good.  
  [% foreach item = biglist %]   # OK, but not recommended

Variable names may contain any alphanumeric characters or underscores.
They may be lower, upper or mixed case although the usual convention
is to use lower case.  The case I<is> significant however, and 'foo',
'Foo' and 'FOO' are all different variables.

The fact that a keyword may be expressed in any case, precludes you from
using any variable that has the same name as a reserved word, irrespective
of its case.  Reserved words are currently:

  GET, SET, DEFAULT, INCLUDE, FOR, FOREACH, IF, UNLESS, ELSE, ELSIF, 
  USE, THROW, CATCH, ERROR, RETURN, STOP, BLOCK, END, AND, OR, NOT.

e.g.
  [% include = 10 %]   # error - 'INCLUDE' a reserved word

The CASE option forces all directive keywords to be expressed in UPPER
CASE.  Any word not in UPPER CASE will be treated as a variable.  This
then allows you to use lower, or mixed case variable names that match
reserved words.  The CASE option does not change the case sensitivity
for variable names, only reserved words.  Variable names are always
case sensitive.  The 'and', 'or' and 'not' operators are the only
exceptions to this rule.  They can I<always> be expressed in lower, or
indeed any case, irrespective of the CASE option, and as such,
preclude the use of a variables by any of those names.

  # CASE => 1
  [% include = 10 %]     # OK - 'include' is a variable, 'INCLUDE' 
			 # is the reserved word.
  [% INCLUDE foobar      
       IF foo and bar    # OK - 'and' can always be lower case
  %]

=head2 VARIABLE NAMESPACES (HASHES)

The period character, '.', is used to denote separate "namespaces" for 
variables.  A namespace is simply a variable that contains a reference to 
a hash array of more variables.

  my $data = {
      'home' => 'http://www.myserver.com/homepage.html',
      'user' => {
	  'name' => 'John Doe',
          'id'   => 'jdoe',
      },
      'page' => {
	  'this' => 'mypage.html',
	  'next' => 'nextpage.html',
	  'prev' => 'prevpage.html',
      },
  };

  $tproc->process($myfile, $data) 
      || die $tproc->error(), "\n";

Example:
  <a href="[% home %]">Home</a>
  <a href="[% page.prev %]">Previous Page</a>
  <a href="[% page.next %]">Next Page</a>

Output:
  <a href="http://www.myserver.com/homepage.html"</a>
  <a href="prevpage.html">Previous Page</a>
  <a href="nextpage.html">Next Page</a>
    
Any key in a hash which starts with a '_' or '.' character will be 
considered 'private' and cannot be evaluated or updated from within 
a template.

When you assign to a variable that contains multiple namespace 
elements (i.e. it has one or more '.' characters in the name),
any hashes required to represent intermediate namespaces will be 
created automatically.  In other words, you don't have to explicitly
state that a variable ('product' in the next example) will represent
a namespace (i.e. reference a hash), you can just use it as such
and it will be created automatically.

  [% product.id    = 'XYZ-2000' 
     product.desc  = 'Bogon Generator'
     product.price = 666 
  %]
 
  # INTERPOLATE => 0
  The [% product.id %] [% product.desc %] costs $[% product.price %].00

Output:
  The XYZ-2000 Bogon Generator costs $666.00

If you want to create a new variable namespace (i.e. a hash) en masse,
then you can use Perl's familiar '{' ... '}' construct to create a 
hash and assign it to a variable.

  [% product = {
       id    = 'XYZ-2000' 
       desc  = 'Bogon Generator'
       price = 666 
     }
  %]
 
  # INTERPOLATE => 1 (note escaping of first '$' and braces to scope var)
  The $product.id $product.desc costs \$${product.price}.00

Output:
  The XYZ-2000 Bogon Generator costs $666.00

Note that commas are optional between key/value pairs and the '=>' token
may be used in place of '=' to make things look more familiar to Perl
hackers.  You can even prefix variables with '$' if you really want to 
but it's not necessary.

  [% product = {
       id    => 'XYZ-2000',
       desc  => 'Bogon Generator',
       price => 666,
       foo   => $bar,    # OK to use '$', but not necessary
      $baz   => $qux,    # this is also OK if you _really_ like $'s
     }
  %]

You can copy all the members of a hash into another hash by assigning 
to the magical 'IMPORT' variable (note UPPER CASE).  This has the effect
of "importing" a set of variables into another namespace.

  [% user = {
       name = 'John Doe'
       id   = 'jdoe'
     }
  %]
 
  [% IMPORT=user %] 
  Name: [% name %]   ID: [% id %]

The IMPORT may be specified against any other namespace, or can be 
used as a parameter in an INCLUDE directive, for example.

  [% myuser.age    = 100
     myuser.IMPORT = user
  %]

  [% INCLUDE userinfo 
       title  = 'Some User Record'
       IMPORT = myuser
  %]

userinfo:
  Title: [% title %]
  User: [% name %]   ID: [% id %]   Age: [% age %]

Output
  Title: Some User Record
  User: John Doe   ID: jdoe   Age: 100

The assignment to the IMPORT variable is something of a temporary hack 
and will probably be changed in a future release.  If if proves necessary,
IMPORT may become a first-class directive.  See the TODO file for more info.

=head2 VARIABLE VALUES 

Variables may be assigned the values of other variables, unquoted
numbers (digits), literal text ('single quotes') or quoted text
("double quotes").  In the latter case, any variable references within
the text will be interpolated when the string is evaluated.  Variables
should be prefixed by '$', using curly braces to explicitly scope
variable name where necessary.

  [% foo  = 'Foo'  %]               # literal value 'Foo'
  [% bar  =  foo   %]               # value of variable 'foo'
  [% cost = '$100' %]               # literal value '$100'
  [% item = "$foo: ${price}.00" %]  # value "bar: $100.00"

Multiple variables may be assigned in the same directive and are 
evaluated in the order specified.  Thus, the above could have been 
written:

  [% foo  = 'Foo'
     bar  = foo
     cost = '$100'
     item = "$foo: ${price}.00"
  %]

=head2 VARIABLE LISTS

A list (actually a reference to an anonymous Perl list) can be created
and assigned to a variable by enclosing one or more values in square
brackets, just like in Perl.  The values in the list may be any of
those described above.  Commas between elements are optional.

  [% userlist = [ 'tom' 'dick' 'harry' ] %]

  [% foo    = 'Foo'
     mylist = [ foo, 'Bar', "$foo Baz" ]
  %]

The FOREACH directive will iterate through a list created as above, or
perhaps provided as a pre-defined variable passed to the process() method.

  my $data = {
      'name' => 'John Doe'
      'id'   => 'jdoe',
      'items' => [ 'one', 'two', 'three' ],
  };

  $tproc->process($myfile, $data) 
      || die $tproc->error(), "\n";

Example:

  Things:
  [% foo = 'Foo' %]
  [% FOREACH thing = [ foo 'Bar' "$foo Baz" ] %]
     * [% thing %]
  [% END %]

  Items:
  [% FOREACH i = items %]
     * [% i %]
  [% END %]

  Stuff:
  [% stuff = [ foo "$foo Bar" ] %]
  [% FOREACH s = stuff %]
     * [% s %]
  [% END %]
  
Output:

  Things:
    * Foo
    * Bar
    * Foo Baz

  Items:
    * one
    * two
    * three

  Stuff:
    * Foo
    * Foo Bar

=head2 VARIABLES BOUND TO USER CODE

Template variables may also contain references to Perl sub-routines
(CODE).  When the variable is evaluated, the code is called and the
return value used in the variable's place.  These "bound" variables
can be used just like any other:

  my $data = {
      'magic' => \&do_magic,
  };

  $template->process('myfile', $data)
      || die $template->error();

  sub do_magic {
      # ...whatever...
      return 'Abracadabra!';
  }

myfile:
  He chanted the magic spell, "[% magic %]", and 
  disappeared in a puff of smoke.

Output:
   He chanted the magic spell, "Abracadabra!", and
   disappeared in a puff of smoke

Any additional parameters specified in parenthesis will also be passed
to the code:

    $data = {
	'foo'   => 'Mr. Foo',
	'bar'   => 'Mr. Bar',
	'qux'   => 'Qux',
	'join'  => sub { my $joint = shift; join($joint, @); },
    }

    $template->process('myfile', $data)
	|| die $template->error();

myfile:
    [% join(' + ', foo, bar, 'Mr. Baz', "Mr. $qux") %]

output:
    Mr. Foo + Mr. Bar + Mr. Baz + Mr Qux

Parenthesised parameters may be added to I<any> element of a variable,
not just those that are bound to code or object methods.  At present,
parameters will be ignored if the variable isn't "callable" but are 
supported for future extensions.  Think of them as "hints" to that 
variable, rather than just arguments passed to a function.

  %% r = 'Romeo' %%
  %% r(100, 99, s, t, v) %%     # still just prints "Romeo"

User code should return a value for the 'variable' to which it is bound.
On error, undef can be returned which will trigger an "undef" exception to 
be automatically raised (see below)

   sub do_magic {
       # blah blah blah
       return undef if $something_went_wrong;
       # more stuff..
       return $some_value;
   }

An alternative approach which gives more flexibility is for the code 
to return a second value indicating the status.  A status of 0 (STATUS_OK)
means everything went OK, regardless of whatever value was returned,
defined or not.  In this case an undefined value would simply be converted
to an empty string ''.  In other words, no output or error would be 
generated.

  use Template qw( :status );
  my $DEBUG = 0;

  sub debug {
      return (undef, STATUS_OK) unless $DEBUG;
      # blah blah blah
      return $some_debug_text;
  }

The status code can also be STATUS_STOP (immediate stop) or STATUS_RETURN
(stop the current template only and return to the caller or point of 
INCLUDE).  The final option is for the status to be an exception object.
This is an instance of the Template::Exception class.  The first parameter
defines the 'type' of error and may be any string you care to define.  
The CATCH option and CATCH block directive allow you to define custom
handling, or template blocks to be processed when different kinds of 
exception occur, including any user-defined types such as in this 
example:

  use Template qw( :status );
  use Template::Exception;

  my $tproc = Template->new();
  $tproc->process('example', { sql => \&silly_query_language })
    || die $tproc->error(), "\n";

  sub silly_query_language {
      # some code...

      # stop!
      return (undef, STATUS_STOP) if $some_fatal_error;

      # some more code...

      # raise a 'database' exception that might be caught and handled
      return (undef, Template::Exception->new('database', $DBI::errstr))
	  if $dbi_error_occurred;

      # even more code still..

      # OK, everything's just fine.  Return data
      return $some_data;
  }

example:
  [% # define a CATCH block for 'database' errors that 
     # prints the error, adds the page footer and STOPs  
  %]
  [% CATCH database %]
     <!-- Database error handler -->
     <hr>
     <h1>Database Error</h1>
     An unrecoverable database error has occurred:
     <ul>
       [% e.info %]
     </ul>
     [% INCLUDE footer %]
     [% STOP %]
  [% END %]

  [% # we're prepared for the worst... %]
  [% sql('EXPLODE my_brain INTO a_thousand_pieces') %] 

=head2 VARIABLES BOUND TO OBJECTS

A variable may contain an object reference whose methods will be
called when expressed in the 'object.method' notation.  The object
reference will implicitly be passed to the method as the first parameter.
Any other parameters specified in parenthesis after the method name
will also be passed.

  package MyObj;

  sub new {
      my $class  = shift;
      bless { }, $class;
  }

  sub bar {
    my ($self, @params) = @_;
    # do something...
    return $some_value; 
  }

  package main;

  my $tproc = Template->new();
  my $obj   = MyObj->new();
  $tproc->process('example', { 'foo' => $obj, 'baz' => 'BAZ' } )
    || die $tproc->error(), "\n";

example:

  [% foo.bar(baz) %]	# calls $obj->bar('BAZ')

Methods whose names start with an underscore (e.g. '_mymethod') will not
be called.  Parameter passing and return value expectations are as per
code references, above.

=head2 VARIABLE EVALUATION

A 'dotted' variable may contain any number of separate elements.  Each
element may evaluate to one of the above variable types and the processor
will then correctly use this value to evaluate the rest of the variable.

For example, consider the following variable reference:

  [% myorg.user.abw.name %]

This might equate to the following fundamental steps:

  'myorg'  is an object reference
  'user'   is a method called on the above object returning a tied 
           hash which acts as an interface to a database
  'abw'    is fetched from the above hash, triggering the retrieval 
           of a record from the database.  This is returned as a hash
  'name'   is fetched from this hash, representing the value of the 
           'name' field in the record.

You don't need to worry about any of the above steps because they all
happen automatically. When writing a template, a variable is just a
variable, irrespective of how its value is stored, retrieved or
calculated. 

Intermediate variables may be used and will behave entirely as expected.

  [% userdb = myorg.user %]
  [% user   = userdb.abw %]
  Name: [% user.name %]  EMail: [% user.email %]

An element of a dotted variable can itself be an interpolated value.
The variable should be enclosed within the '${' .., '}' characters.
In the following example, we use a 'uid' variable interpolated into 
a longer variable such as the above to return multiple user records
from the database. 

  [% userdb = myorg.user %]
  [% FOREACH uid = [ 'abw' 'sam' 'hans' ] %]
     [% user = userdb.${uid} %]
     Name: [% user.name %]  EMail: [% user.email %]
  %]

This could be also have been interpolated into the full variable reference:

  [% uid  = 'abw'
     name = myorg.user.${uid}.name
  %]

You can also use single and double quoted strings inside an 
interpolated element:

  # contrived example
  [% letterw = 'w' 
     name = myorg.user.${"ab$letterw"}.name
  %]

SIDE NOTE: In a prototype implementation of a more generic component-based 
programming language I've been playing with, I extended the above syntax
to include lists which were automatically converted into iterators.
e.g.

   # NOTE: this doesn't work in Template Toolkit (yet!)
   [% FOREACH name = myorg.user.['abw' 'sam' 'hans'].name %]
      ...
   [% END %]

Roughly equivalent to:

   # This *DOES* work...
   [% FOREACH uid = [ 'abw' 'sam' 'hans' ] %]
      [% name = myorg.user.${uid}.name %]
      ...
   [% END %]

This is quite cool in a sick and twisted kinda way, but can actually
be very useful.  As a bonus, the implementation is simple and efficient.
There's a good chance this feature might make it in some time soon.
Contact me if you want more info...  (END OF SIDE NOTE)

Any namespace element in a variable may contain parenthesised parameters.
If the item contains a code reference or represents an object method then
the parameters will be passed to that sub-routine/method when called.
Parameters are otherwise ignored, but may be used for future 
extensibility.

A different implementation of the above example might look like this:

  [% myorg.user('abw').name %]

Here, the fictional 'user' method of the 'myorg' object takes a parameter
to indicate the required record.  Thus, it can directly return a hash 
reference representing the record which can then be examined for the 
'name' member.  The method could be written to check for the existence
of a parameter and return a general access facility, such as the tied hash 
in the previous example, if one is not provided.  Thus, the same underlying 
Perl code can easily be used in either manner.

  package myorg;

  sub user {
      my ($self, $uid) = @_;
      return $self->get_record($uid) if $uid;
      return $self->make_tied_hash_to_records();
  }

A sub-routine or method might also return a reference to a list containing
other objects or data.  The FOREACH directive is used to iterate through
such lists.

  [% FOREACH user = myorg.userlist %]
     Name: [% user.name %]  EMail: [% user.email %]
  [% END %]

For more powerful list iteration, a Template::Iterator object can be
defined and/or returned for use in a FOREACH directive.  The following 
pseudo-code example illustrates the principal.  Here, the 'userlist'
method first determines a list of valid user ID's and then creates an
iterator to step through them.  On each iteration, the ACTION for
the iterator is called, which in this case is a closure to retrieve
each record from the database.

  package myorg;

  sub user {
      my ($self, $uid) = @_;
      return $self->query("SELECT * FROM user WHERE (uid='$uid')");
  }

  sub userlist {
      my $self = shift;
      my $user_id_list = $self->query("SELECT id FROM user");
      return Template::Iterator->new($user_id_list, {
	    ORDER  => 'sorted',
	    ACTION => sub { $self->user(shift) },
      });
  }

This process is entirely hidden from the template author.  The use of 
iterators is automatic and nothing needs to change in the template:

  [% FOREACH user = myorg.userlist %]
     Name: [% user.name %]  EMail: [% user.email %]
  [% END %]

Underlying code, algorithms and heuristics may be as simple or as
complex as required to perform the task in hand.  However, the
specific details of the implementation are hidden away in the 
"back-end", providing only a simple, clear and consistent interface 
for use in template documents.

=head2 INCLUDING TEMPLATE FILES AND BLOCKS

The INCLUDE directive is used to process and include the output of another
template file or block.

  [% INCLUDE header %]

The processor will look for files relative to the directories specified in
the INCLUDE_PATH.  Each file is parsed when first loaded and cached 
internally in a "compiled" form.  The contents of the template, including
any directives embedded within it, will then be processed and the output
included into the current document.  Subsequent INCLUDE directives 
requesting the same file can then use the cached version to greatly 
reduce processing time.

The first parameter to the INCLUDE directive is assumed to be the name
of a file or defined block (see BLOCK, below).  The name may contain 
alphanumeric characters, underscores, dots or slashes ([\w\/\.]).  Names
that contain any other characters should be quoted.  Double quoted strings
may be used to interpolate variable values into the name.

  [% INCLUDE misc/menu.atml               %]
  [% INCLUDE 'dos98/Program Files/stupid' %]
  [% INCLUDE "$lang/menu.atml"            %]

Further parameters can be provided to define local variable values for 
the template.  

  [% INCLUDE header
     title = 'Cat in the Hat'
     bgcol = '#aabbcc'
  %]

header:
  [% DEFAULT 
     title='Hello World' 
     bgcol='#ffffff'
  %]
  <html>
  <head><title>[% title %]</title></head>
  <body bgcolor="[% bgcol %]">

Output:
  <html>
  <head><title>Cat in the Hat</title></head>
  <body bgcolor="#aabbcc">

In addition to any parameters explicitly provided, the INCLUDE'd
template will "inherit" all other variables currently defined.  These
variables are 'localised' meaning that any changes made to variable
within the included file will not affect those variables in the
namespace of the enclosing template.

  [% name = 'foo' %] 
  [% INCLUDE change_name %]
  Name is still '[% name %]'

change_name:
  Name is [% name %]
  Changing '[% name %]' to [% name ='bar'; name %]

Output:
  Name is 'foo'
  Changing 'foo' to 'bar'
  Name is still 'foo'

In addition to separate files, template blocks can be defined and 
processed with the INCLUDE directive.  These are defined with the BLOCK
directive and are parsed, compiled and cached as for files.

  [% BLOCK tabrow %]
  <tr><td>[% name %]<td><td>[% email %]</td></tr>
  [% END %]

  <table>
  [% INCLUDE tabrow  name='Fred'  email='fred@nowhere.com' %]
  [% INCLUDE tabrow  name='Alan'  email='alan@nowhere.com' %]
  </table>

A BLOCK definition may be used before it is defined, as long as the 
definition resides in he same file.

  [% INCLUDE tmpblk %]

  [% BLOCK tmpblk %] This is OK [% END %]

=head2 PLUGIN OBJECTS AND LIBRARIES

The USE directive can be used to load and initialise "plugin" extension 
modules.  These are regular Perl modules that may, or may not, be derived
from the Template::Plugin base class.

  [% USE myplugin %]

The plugin name is case-sensitive and will be appended to the
PLUGIN_BASE value (default: 'Template::Plugin') to construct a full
module name.  Any periods, '.', in the name will be converted to '::'.

  [% USE MyPlugin   %]     #  => Template::Plugin::MyPlugin
  [% USE CGI.Params %]     #  => Template::Plugin::CGI::Params

Any additional parameters supplied in parenthesis after the plugin name
will be also be passed to the new() constructor.  A reference to the 
template Context object is always passed as the first parameter.

  [% USE MyPlugin('foo', 123) %]
     ==> Template::Plugin::MyPlugin->new($context, 'foo', 123);

The plugin may represent any data type; a simple variable, hash, list or
code reference, but in the general case it will be an object reference.
Methods can be called on the object (or the relevant members of the
specific data type) in the usual way:

  [% USE MyPlugin %]
  [% MyPlugin.does_this %]
  [% MyPlugin.does_that %]

An alternative name may be provided for the plugin by which it can be 
referenced:

  [% USE magic = MyPlugin %]
  [% magic.supernova('Big Bang') %]

You can use this approach to create multiple plugin objects with
different configurations.  This example shows how the 'format' plugin
is used to create sub-routines bound to variables for formatting text
as per printf().

  [% USE bold = format('<b>%s</b>') %]
  [% USE ital = format('<i>%s</i>') %]

  [% bold('This is bold')   %]
  [% ital('This is italic') %]

Output:
  <b>This is bold</b>
  <i>This is italic</i>

See L<Template::Plugin> for details of the plugin modules available for
the Template::Toolkit.

=head2 ERROR HANDLING AND FLOW CONTROL

There are two kinds of error that may occur within the Template
Toolkit.  The first (which we try to avoid) are 'Perl errors' caused
by incorrect usage, or heaven forbid, bugs in the Template Toolkit.
See the BUGS section or the F<TODO> file for more detail on those.
Thankfully, these are comparatively rare and most problems are simply
due to calling a method incorrectly or passing the wrong parameters.

The Template Toolkit doesn't go out of it's way to check every parameter
you pass it.  On the whole, it is fairly tolerant and will leave it up 
to Perl's far superior error checking to report anything seriously untoward
that occurs.

The other kind of errors that concerns us more are those relating to
the template processing "runtime".  These are the (un)expected things
that happen when a template is being processed that we might be
interested in finding out about.  They don't mean that the Template
Toolkit has failed to do what was asked of it, but rather that what
was asked of it didn't make sense, or didn't work as it should.  These
kind of errors might include a variable being used that isn't defined
('undef'), a file that couldn't be found, or properly parsed for an
INCLUDE directive ('file'), a database query that failed in some user
code, a calculation that contains an illegal value, an invalid value
for some verified data, and so on (any error types can be
user-defined).

These kinds of errors are raised as 'exceptions'.  An exception has a
'type' which is a single word describing the kind of error, and an
'info' field containing any additional information.

These exceptions may be caught (i.e. "handled") by an entry defined in
the hash array passed as the CATCH parameter to the Template
constructor.  The keys in the hash represent the error types and the
values should contain a status code (e.g. STATUS_OK, STATUS_STOP) or a
code reference which will be called when exceptions of that type are
thrown.  Such code references are passed three parameters; a reference
to the template "Context" object, the error type and the error info.
Having performed any processing, it should then return a status code
or an exception object to be propagated back to the user.  Returning a
value of 0 (STATUS_OK) indicates that the exception has been
successfully handled and processing should continue as before.

  my $tproc = Template->new({	
      CATCH => {
	'file'  => sub {
		      my ($context, $type, $info) = @_;
		      $context->output("<!-- $type: ($info) -->");
		      return STATUS_OK;
	           },
	'undef' => STATUS_OK,
      },
  });

A template block may also be defined that will be processed when
certain exception types are raised.  The CATCH directive starts the
block definition and should contain a single word denoting the error
type.  The variable 'e' will be defined in a catch block representing
the error.  The 'type' and 'info' members represent the appropriate
values.

  [% CATCH file %]
    <!-- file error: [% e.info %] -->
  [% END %]

A CATCH block defined without an error type will become a default
handler.  This will be processed when an exception is raised that has
no specific handler of its own defined.

  [% CATCH %]
    An error ([% e.type %]) occured: 
      [% e.info %]
  [% END %]

A default handler can be installed via the CATCH option by defining
the error type as 'default'.

  my $tproc = Template->new({	
      CATCH => {
	  'default' => STATUS_OK,
      },
  });

Any user-defined exception types can be created, returned, thrown and caught 
at will.  User code may return an exception as the status code to indicate
an error.  This exception type can then be caught in the usual way.

  $tproc->process('myexample', { 'go_mad' => \&go_mad })
    || die $tproc->error();

  sub go_mad {
      return (undef, Template::Exception->new('mad', 'Big Fat Error'));
  }

Example:
  [% CATCH mad %]
  Gone mad: [% e.info %]
  [% END %]

  Going insane...
  [% go_mad %]

Output:
  Going insane...
  Gone mad: Big Fat Error

A CATCH block will be installed at the point in the template at which
it is defined and remains available thereafter for the lifetime of the
template processor or until redefined.  This is probably a bug and may
soon be 'fixed' so that handlers defined in templates only persist
until the parent process() method ends.

An exception that is not caught, or one that is caught by a handler that 
then propagates the exception onward, will cause the Template process()
method to stop and return a false status (failed).  A string representing
the exception that occured (in the format "$type: $info") can be returned
by calling the error() method. 

    $tproc->process('myexample')
        || die "PROCESSING ERROR: ", $tproc->error(), "\n";

You can 'throw' an exception using the THROW directive, specifying the 
error type (unquoted) and value to represent the information.

  [% THROW mad '19th Nervous Breakdown' %]

Output:
  PROCESSING ERROR: mad: 19th Nervous Breakdown

The STOP directive can be used to indicate that the processor should
stop gracefully without processing any more of the template document.
This is known as a 'planned stop' and the Template process() method
will return a B<true> value.  This indicates I<'the template was
processed successfully according to the directives within it'> which
hopefully, it was.  If you need to find out if the template ended
'naturally' or via a STOP (or RETURN, as discussed below) directive,
you can call the Template error() method which will return the
numerical value returned from the last directive, represented by the
constants STATUS_OK, STATUS_STOP, STATUS_RETURN, etc.  If the previous
process() did not return a true value then the error() method returns
a string representing the exception that occured.

The STOP directive can be used in conjunction with CATCH blocks to safely
trap and report any fatal errors and then end the template process gracefully.

  [% CATCH fatal_db_error %]
     <p>
     <b>A fatal database error has occured</b>
     <br>
     Error: [% e.info %]
     <br>
     We apologise for the inconvenience.  The cleaning lady has removed 
     the power from the database server so that she can plug in her
     vacuum cleaner.  She's normally done in about 5 minutes... please
     try again later.
     </p>
     [% ERROR "[$e.type] $e.info" %]
     [% INCLUDE footer %]
     [% STOP %]
  [% END %]

The ERROR directive as used in the above example, sends the specified 
value to the current output stream for the template processor.  By 
default, this is STDERR.

The RETURN directive is similar to STOP except that it terminates the
current template file only.  If the file in which the RETURN directive
exists has been INCLUDE'd by another, then processing will continue at
the point immediately after the INCLUDE directive.

  Before
  [% INCLUDE half_wit %]
  After

  [% BLOCK half_wit %]
  This is just half...
  [% RETURN %]
  ...a complete block
  [% END %]

Output:
  Before
  This is just half...
  After

The STOP, RETURN, THROW and ERROR directives can all be used in conjunction
with other 'side-effect' directives.  e.g.

  [% THROW up 'Contents of stomach' IF drunk %]
  [% STOP IF brain_exploded %]
  [% RETURN IF no_input %]
  [% ERROR 'Stupid, stupid, user' IF easy2guess(passwd) %]
  [% THROW badpasswd "$user.id has a dumb password ($user.passwd)"
       FOREACH user = naughty_user_list
  %]




=head1 PUBLIC METHODS

=head2 new(\%config)

The new() constructor is called to create and return a new instance 
of the Template class.  This object acts as a front-end processor 
to the other Template Toolkit modules.

A reference to a hash array may be passed which contains configuration 
parameters.  These may include:

=over

=item INCLUDE_PATH

The INCLUDE_PATH option specifies one or directories in which to look for
template files.  Multiple directories can be delimited by a ':' (or the
value of the PATH_SEPARATOR) or specified as a reference to a list.  
Each item in a list may have additional CACHE parameters associated
with it.

  my $cache = Template::Cache->new({
      INCLUDE_PATH => '/usr/local/templates:/usr/web/templates',
  });

  my $cache = Template::Cache->new({
      INCLUDE_PATH => [ '/tmp/templates', '/usr/web/templates' ],
  });

  my $template = Template->new({
      INCLUDE_PATH => [ 
        '/user/web/templates/src:/usr/web/tmplates/elements'
        '/user/web/templates/toodamnbig' => { CACHE => 0 },
      ],
  });

The PATH_SEPARATOR and DIR_SEPARATOR options can be used to adjust for
different operating system conventions.  See L<Template::Cache> for 
further details.

  # accommodate some inferior file-system...
  # note the need to escape all those backslashes
  my $template = Template->new({ 
      INCLUDE_PATH   => 'D:\\ABW\\TEMPLATES + C:\\TMP',
      PATH_SEPARATOR => ' + ',
      DIR_SEPARATOR  => '\\',
  });


=item PRE_DEFINE

A reference to a hash of variables and values that should be pre-defined
in the stash.  Passed to Template::Stash new() constructor.  These variables
will be pre-defined each time process() is called.

  my $template = Template->new({
      PRE_DEFINE => {
	  'server'    => 'www.myorg.com',
	  'help'      => 'help/helpndx.html',
	  'images'    => '/images'
	  'copyright' => '(C) Copyright 1999',
	  'userlist'  => [ 'tom', 'dick', 'harry'   ],
	  'myorg'     => { 'name' => 'My Org. Inc.', 
                           'tel'  => '555-1234'     },
          'icon'      => { 'prev' => 'prevbutton', 
                           'next' => 'nextbutton'   },
      }
  });

=item START_TAG, END_TAG, TAG_STYLE

The START_TAG and END_TAG options are used to specify character  
sequences or regular expressions that mark the start and end of a template 
directive.  Any Perl regex characters can be used and therefore should be 
escaped (or use the Perl C<quotemeta> function) if they are intended to
represent literal characters.

  my $template->new({ 
      START_TAG => quotemeta('<+'),
      END_TAG   => quotemeta('+>'),
  });

example:

  <+ INCLUDE foobar +>

The TAG_STYLE option can be used to set both according to pre-defined tag
styles.  Available styles are:

  regular   [% ... %]                (recommended)
  percent   %% ... %%                (Text::MetaText compatibility)
  default   [% ... %] or %% ... %%   (both of the above)

The default style (TAG_STYLE => 'default') allows either of the 'regular'
or 'percent' tags to be used (START_TAG = '[\[%]%', END_TAG = '%[\]%]')
Any values specified for START_TAG and/or END_TAG will over-ride
those defined by a TAG_STYLE.  

=item INTERPOLATE

The INTERPOLATE flag, when set to any true value will cause variable 
references in plain text (i.e. not surrounded by START_TAG and END_TAG)
to be recognised and interpolated accordingly.  Variables should be
prefixed by a '$' to identify them.  Curly braces can be used in the 
familiar Perl/shell style to explicitly scope the variable name where
required.

  # INTERPOLATE = 0
  <a href="http://[% server %]/[% help %]">
  <img src="[% images %]/help.gif"></a>
  [% myorg.name %]


  # INTERPOLATE = 1
  <a href="http://$server/$help">
  <img src="$images/help.gif"></a>
  $myorg.name

  # explicit scoping with {  }
  <img src="$images/${icon.next}.gif">

=item PRE_CHOMP, POST_CHOMP

These values set the chomping options for the parser.  With POST_CHOMP
set true, any whitespace after a directive up to and including the newline
will be deleted.  This has the effect of joining a line that ends with 
a directive onto the start of the next line.

With PRE_CHOMP set true, the newline and whitespace preceding a directive
at the start of a line will be deleted.  This has the effect of 
concatenating a line that starts with a directive onto the end of the 
previous line.

PRE_CHOMP and POST_CHOMP can be activated for individual directives by
placing a '-' at the start and/or end of the directive:

  [% FOREACH user = userlist %]
     [%- user -%]
  %% END %%

The '-' characters activate both PRE_CHOMP and POST_CHOMP for the one
directive '[%- name -%]'.  Thus, the template will be processed as if
written:

  [% FOREACH user = userlist %][% user %][% END %]

Similarly, '+' characters can be used to disable PRE- or POST-CHOMP (i.e.
leave the whitespace/newline intact) options on a per-directive basis.

  [% FOREACH user = userlist %]
  User: [% user +%]
  [% END %]

With POST_CHOMP set on, the above example would be parsed as if written:

  [% FOREACH user = userlist %]User: [% user %]
  [% END %]

=item CASE

The Template Toolkit treats all variables with case sensitivity.  Thus, 
the variable 'foo' is different from 'Foo' and 'FOO'.  Reserved words,
by default, may be specified in either case, but are usually UPPER CASE
by convention.

  [% INCLUDE foobar %]
  [% include foobar %]

One side-effect of this is that you cannot use a variable of the same 
name as a reserved word such as 'include', 'error', 'foreach', etc.

Setting the CASE option to any true value will cause the parser to only
consider UPPER CASE words as reserved words.  Thus, 'ERROR' remains a 
reserved word, but 'error', 'Error', 'ERRoR', etc., may all be used as 
variables.  

The only exception to this rule are the 'and', 'or' and 'not' operators
which can I<always> be expressed in lower, or indeed any case.

=item PLUGIN_BASE

This option allows you to define a base package for plugin objects loaded
and used via the USE directive.  The default base is 'Template::Plugin'.
Periods in a plugin name are converted to '::' and the name is appended
to the PLUGIN_BASE.  Thus the following directive:

  %% USE Foobar.Baz %%

Would request and instantiate and object from the plugin module 
'Template::Plugin::Foobar::Baz'.

This option currently only allows one directory to be defined.  This is 
an unnecessary restriction which will soon be rectified.

=item PLUGINS

The PLUGINS option may be specified as a reference to a hash
pre-defining plugin objects for the USE directive.  Each key in the
hash represents a plugin name and the corresponding value, a package
name or object which should be used to construct new instances of the
plugin object.

  use MyOrg::Template::Plugin::Womble;
  use Template::Plugin::DBI;         # available soon...

  my $dbi_factory = Template::Plugin::DBI->new();

  my $template->new({ 
      PLUGINS => {
	'womble' => 'MyOrg::Template::Plugin::Womble',
	'dbi'    =>  $dbi_factory,
      END_TAG   => quotemeta('+>'),
  });

The new() method is called against the PLUGINS value when a plugin is USE'd.
Thus, an entry that specifies a package name will caused instances of that
plugin to be created as follows:

  [% USE womble %] 
     ==> MyOrg::Template::Plugin::Womble->new($context);

A reference to the Template::Context object in which the plugin will run 
is passed as the first parameter.  The plugin object may store this 
reference and subsequently use it to control the template process via 
it's public interface.  This gives plugin objects access to the full
functionality of the Template Toolkit.

Any parameters specified in parenthesis after the plugin name will be 
passed to the new() constructor.  

  [% USE womble('Tomsk') %] 
     ==> MyOrg::Template::Plugin::Womble->new($context, 'Tomsk');

The PLUGINS value may contain an object reference.  In identical
fashion to the above, the new() method is called against the object,
allowing it to act as a constructor object or 'prototype' for other
instances of the same, or other objects.

  [% USE dbi('dbase_xyz') %]
    ==> $dbi_factory->new($context, 'dbase_xyz');

This approach facilitates the easy implementation and use of plugins that 
act as singletons (one instance only) or share some state information, 
such as cached database handles in the DBI example shown here.  

Simon Matthews <sam@knowledgepool.com> is currently working on the DBI
plugin for the Template Toolkit.

When a plugin is requested via the USE directive that is not specified
in the PLUGINS hash, the dynamic loading procedure described under
PLUGIN_BASE above will be used.  If a module is successfully loaded,
the load() sub-routine in that package is called and should return the
package name itself (i.e. simply return the first parameter) or an
object reference which is then stored and used in the PLUGINS hash as
described above.

=item OUTPUT, ERROR

The OUTPUT and ERROR options may be specified to redirect template output
and/or error messages.  The value for these options should be a file GLOB
or IO::Handle to which the output/error is directed, a CODE reference
which is called to handle messages, or a reference to a text string (SCALAR)
to which output or error messages are appended.

  my $output = '';

  my $template = Template->new({
      OUTPUT = \$output,
      ERROR  = sub { print STDERR "Most Bogus Error: ", @_ }
  };

The redirect() method can be subsequently called to define new 
output or error options.

=item CATCH 

The CATCH option may be used to specify a hash array of error handlers
which are used when a run time error condition occurs.  Each key in 
the hash represents an error type.  The Template Toolkit generates the 
following error types which have corresponding ERROR_XXX constants.

   undef    - an variable was undefined or evaluated undef
   file     - file find/open/parse error

User code may generate further errors of any types and custom handlers
may be provided to trap them.  A handler, defined as the related value
in the CATCH configuration hash may be one of the STATUS_XXXX constants
defined in Template::Constants (e.g. STATUS_OK, STATUS_STOP) or a code
reference which is called when an error occurs.  The handler is passed
a reference to the context ($self) and the error type and info.  The 
return value should be one of the aforementioned constants or a 
Template::Exception object.

    use Template qw( :error );

    my $template = Template->new({
	CATCH => {
	    ERROR_UNDEF => STATUS_OK,
	    ERROR_FILE  => sub { 
		my ($context, $type, $info) = @_;
		$context->output("FILE ERROR: $info");
		return STATUS_OK; 
	    },
	}
    });

A 'default' handler may be provided to catch any exceptions not 
explicitly caught by their own handler.  This is equivalent to defining
a CATCH block without specifying an error type:

  [% CATCH %]
  Caught '[% e.type %]' exception:
    [% e.info %]
  [% END %]

=item PARSER, GRAMMAR

The PARSER and GRAMMAR configuration items can be used to specify an 
alternate parser or grammar for the parser.  Otherwise an instance of 
the default Template::Parser/Template::Grammar will be created and used
as required.

See the B<parser> sub-directory of the Template Toolkit distribution
for further information on compiling and using your own grammars (some
parser expertise required).

    use Template;
    use MyTemplate::MyGrammar;

    my $template = Template->new({ 
       	GRAMMAR = MyTemplate::MyGrammar->new();
    });

=item CACHE

The CACHE item can be used to specify an alternate cache object to 
handle loading, compiling and caching of template documents.  A default
Template::Cache object is created otherwise.  See L<Template::Cache> for 
further information.

=back

=head2 process($template, \%vars, ...)

The process() method is called to process a template.  The first 
parameter, $template, indicates the template and may be a simple
SCALAR containing a filename (relative to INCLUDE_PATH), a reference
to a SCALAR which contains the template text or a reference to a GLOB
(e.g. \*MYFILE) or IO::Handle or sub-class from which the template 
is read.

    $file = 'hworld.html'
    $text = "[% INCLUDE header %]\nHello world!\n[% INCLUDE footer %]"

    $template->process($file)
        || die $template->error(), "\n";

    $template->process(\$text)
        || die $template->error(), "\n";

    $template->process(\*DATA)
        || die $template->error(), "\n";

    __END__
    [% INCLUDE header %]    
    Hello World!
    [% INCLUDE footer %]

The optional second parameter may be a reference to a hash array containing
variables and values which should be available in the template.  These are
applied in addition to (and may temporarily modify previous values for)
the PRE_DEFINE variables.

Any output generated by processing the template will be sent to the 
current output stream which is STDOUT by default.  Errors are similarly 
directed to the error stream or STDERR.

The method returns 1 if the template was successfully processed.  This
includes templates that were ended by a STOP or RETURN directive
If an uncaught error occurs, the method returns 0.  A relevant 
error message can then be returned by calling the error() method.


=head2 redirect($what, $where)

The redirect() method can be called to redirect the output or error
stream for the template processing system.  This method simply delegates
to the underlying Template::Context object().

The first parameter should specify 'output' or 'error' (defined as the 
constants TEMPLATE_OUTPUT and TEMPLATE_ERROR in Template::Constants).

The second parameter should contain a file handle (GLOB or IO::handle) 
to which the output or error stream should be written.  Alternatively,
$where may be a reference to a scalar variable to which output is appended
or a code reference which is called to handle output.

    use Template::Context;
    use Template::Constants qw( :template );

    my $context = Template::Context->new();
    my $output  = '';
    $context->redirect(TEMPLATE_OUTPUT, \$output);
    $context->redirect(TEMPLATE_ERROR, \*STDOUT);


=head2 error()

The error() method returns any error message generated by the previous
call to the process() method.

If no error occurred, the method returns a numerical value representing
the return code of the last directive processed.  This will generally 
be STATUS_OK (0), STATUS_STOP or STATUS_RETURN.  Constants representing
the values are defined in Template::Constants. 

=head1 DISTRIBUTION FILES AND DIRECTORIES

The following directories and files comprise the Template Toolkit
distribution.  See the individual README files in each directory
for further information on their contents.

    bin/        Template processing scripts; tpage
    examples/   Example templates and scripts
    lib/        Template Toolkit modules
    parser/     Grammar and compiler scripts for parser
    t/          Test scripts (run via 'make test')
    MANIFEST    Manifest file (ExtUtils::MakeMaker)
    Makefile.PL Makefile construction script (ExtUtils::MakeMaker)
    Changes     History of visible changes between versions.
    TODO        List of bugs, enhancements, planned features, ideas, etc.
    README      README file containing general info

=head1 BUGS

See the separate F<TODO> file for details of known bugs, limitations
and planned features.  The F<Changes> file details visible changes 
in the toolkit between public versions.  The definition of 'visible'
is of course entirely dependent on how hard you're looking.

If you do find something that looks or acts like a bug, then please 
report it along with a I<short> example of what doesn't work as 
advertised and as much I<relevant> detail as you can give about how it
manifested itself.  The best way to report a bug is to send a 
short test file that illustrates the problem.  You can use F<t/skel.t>
as a skeleton test file.

For example:
  use lib qw( . ./t ../lib );
  use Template;
  require 'texpect.pl';

  test_expect(\*DATA);

  __DATA__
  -- test --
  [% a = 10 %]
  [% explode(a) %]
  -- expect --
  Big Bang!

If you are able to find and fix the bug, and feel inclined to do so, 
then patches are most welcome of all, especially when prepared by
C<diff -u>.

The Template Toolkit is an Open Source project and you are encouraged to 
contribute ideas, suggestions and code.  The templates mailing list is 
currently the focal point for discussion on these matters.  Alternatively,
you can email the author directly.

To join the mailing list, send email to E<lt>majordomo@cre.canon.co.ukE<gt>
containing the text "subscribe templates".  

To email the author directly, send email to E<lt>abw@cre.canon.co.ukE<gt>.  
If you don't know how to do that then I'm afraid I can't help you any more.

This is the end of the document and I'm getting tired...  Roll the credits.

=head1 AUTHOR

Andy Wardley E<lt>abw@cre.canon.co.ukE<gt>

  http://www.kfs.org/~abw/
  http://www.cre.canon.co.uk/perl

=head1 VERSION

This is version 0.22 of the Template Toolkit.  

It is a stable beta release version preceding the imminent release 
of version 1.0.

Please consult the F<Changes> file for information about visible changes
in the Template Toolkit between releases.  The F<TODO> file contains 
details of known bugs, planned enhancements, features, fixes, etc.

=head1 COPYRIGHT

Copyright (C) 1996-1999 Andy Wardley.  All Rights Reserved.
Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 ACKNOWLEDGEMENTS

The Template Toolkit was derived in part from ideas and techniques developed
in the Text::MetaText module.  This itself was the public manifestation of
an earlier template processing system I developed while working at Peritas
Ltd.  (now reverted in name to "ICL Training").

The Template Toolkit was developed more recently at Canon Research
Centre Europe Ltd. as part of an ongoing research theme into
Web-related publishing and content generation.  Other tools are in
development to compliment the Template Toolkit.

Many people have contributed ideas, inspiration, bug reports and fixes
to Text::MetaText and the Template Toolkit, but none more so than 
Simon Matthews E<lt>sam@knowledegpool.comE<gt>.  He deserves special mention 
(and wins many beer tokens) for his continued effort and interest 
over a number of years.

=head1 SEE ALSO

A mailing list exists for up-to-date information on the Template Toolkit
and for following and contributing to the development process.  Send 
email to B<majordomo@cre.canon.co.uk> with the following message in the
body:

  subscribe templates

The following modules comprise the Template Toolkit.  Consult the 
individual documentation for further details.

=over 4

=item L<Template::Context|Template::Context>

The Template::Context module defines a class of objects which each represent
a unique run-time environment in which templates are rendered.  The 
context maintains references to the stash of variables currently defined
(L<Template::Stash|Template::Stash>) and to a cache object 
(L<Template::Cache|Template::Cache>) which provides access to template
files.  It also defines the output() method through which template output 
is directed and provides the error() and throw() methods for error 
handling.  The main process() method is called to render a template
within the context.

=item L<Template::Stash|Template::Stash>

The Template::Stash module defines an object class which is used for 
storing, retrieving and evaluating variables and their values for 
run-time access and processing by templates.  

=item L<Template::Cache|Template::Cache>

The Template::Cache module defines an object class which is used to 
find, load, parse, compile and then cache template documents.  The 
cache implements a simple fetch($template) method which will accept 
a wide range of inputs (filename, text ref, GLOB, IO::Handle, etc)
and attempt to read the template and call on a 
L<Template::Parser|Template::Parser> to parse and compile it to an 
internal form.  This is then cached for subsequent fetch() calls 
for the same template.

=item L<Template::Parser|Template::Parser>

The Template::Parser module defines an object class which implements
the template parser and compiler.  The template text is first scanned 
by a Perl regex which breaks the text into chunks and lexes the tokens
within directive tags.  A DFA (Deterministic Finite-State Automation)
then iterates through the tokens using the rules and states defined
in L<Template::Grammar|Template::Grammar> and generates a compiled
template document represented by the root node of a tree of 
L<Template::Directive|Template::Directive> objects.  The rendering 
context may then call the process() method of the root node, passing 
itself as a reference, to render the template.

=item L<Template::Grammar|Template::Grammar>

The Template::Grammar module defines the rules and state tables for 
the L<Template::Parser|Template::Parser> DFA.  These are generated 
by the Parse::Yapp module.  The Template-Toolkit distribution 
contains a B<parser> directory which contains further files and 
information concerning the grammar and compilation thereof.

=item L<Template::Directive|Template::Directive>

The Template::Directive module defines a base class and a number of 
derived specialist classes to represent directives within template 
documents.  These are instantiated by the 
L<Template::Parser|Template::Parser> object from actions defined in 
L<Template::Grammar|Template::Grammar>.

=item L<Template::Exception|Template::Exception>

The Template::Exception module defines a primitive exception type 
for representing error conditions within the Template Toolkit.

=item L<Template::Iterator|Template::Iterator>

The Template::Iterator module defines a data iterator which is used 
by the FOREACH directive.  This may be sub-classed to create more 
specialised iterators for traversing data sets.

=item L<Template::Plugin|Template::Plugin>

The Template::Plugin module defines a base class for Template Toolkit
extension modules that can be loaded via the USE directive.

=item L<Template::Constants|Template::Constants>

Defines various constants used in the Template Toolkit.

=item L<Template::Utils|Template::Utils>

Defines utility functions.

=item L<Template::Debug|Template::Debug>

Defines functions and methods for debugging (incomplete).

=back

=cut








