##
package Apache::HTML::ClassParser;
#	ClassParser.pm
#
#	Copyright (C) 1999  Paul J. Lucas
#
#	This program is free software; you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation; either version 2 of the License, or
#	(at your option) any later version.
# 
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
# 
#	You should have received a copy of the GNU General Public License
#	along with this program; if not, write to the Free Software
#	Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
##

use 5.004;
use strict 'vars';
use vars qw( @EXPORT @EXPORT_OK @ISA $VERSION );

use Apache::Constants qw( :common );
use Apache::Request();
use Exporter;
use HTML::Tree;

@EXPORT = qw( handler );
@EXPORT_OK = qw();
@ISA = qw( Exporter );
$VERSION = '1.2.3';

my %cache;

sub visitor;

###############################################################################
#
# SYNOPSIS
#
	sub handler
#
# DESCRIPTION
#
#	This is the entry point for the Apache mod_perl handler.  We find an
#	HTML file's associated code file and parse an HTML file into a tree.
#	We eval that code and cache it for multiple uses.
#
# PARAMETERS
#
#	r	A reference to the Apache request object.
#
# RETURN VALUE
#
#	Returns an Apache HTTP status code.
#
###############################################################################
{
	my $r = Apache::Request->new( shift );

	##
	# We are not interested in non-HTML files nor HEAD requests.
	##
	return DECLINED if $r->content_type ne 'text/html' || $r->header_only;

	##
	# Perform basic file sanity checks.
	##
	unless ( -e $r->finfo ) {
		$r->log_error( "ClassParser: file not found: ", $r->filename );
		return NOT_FOUND;
	}
	unless ( -r _ ) {
		$r->log_error( "ClassParser: access denied: ", $r->filename );
		return FORBIDDEN;
	}

	##
	# Get the code file: if the pm_uri paramater was given, use it as the
	# URI to the code file; otherwise, use the same URI as the HTML file,
	# but replacing the suffix with ".pm".
	##
	my $code_filename;
	if ( $r->param( 'pm_uri' ) ) {
		$code_filename =
			$r->lookup_uri( $r->param( 'pm_uri' ) )->filename;
	} else {
		( $code_filename = $r->filename ) =~ s/\.[a-z]?html?$/.pm/;
	}
	unless ( -r $code_filename && -f _ ) {
		$r->log_error( "ClassParser: can not read $code_filename" );
		return SERVER_ERROR;
	}
	my $mtime = -M _;

	##
	# Look in the cache first: if it's not in there or the source file was
	# modified, read in and eval the code, determine the code's package
	# name, create a new instance of the class that the package defines,
	# and stuff the new object and the source file modification time into
	# the cache.
	##
	my $object;
	unless ( exists $cache{ $code_filename } &&
		$cache{ $code_filename }{ mtime } == $mtime
	) {
		my $fh = Apache->gensym();
		unless ( open( $fh, $code_filename ) ) {
			$r->log_error(
				"ClassParser: can not open $code_filename"
			);
			return SERVER_ERROR;
		}
		my $code = join( '', <$fh> );
		close( $fh );
		eval $code;
		if ( $@ ) {
			$r->log_error( $@ );
			return SERVER_ERROR;
		}
		my $package = ($code =~ /^\s*package\s+([\w:]+);/m)[0];
		unless ( $package ) {
			$r->log_error(
				"ClassParser: no package in $code_filename"
			);
			return SERVER_ERROR;
		}
		$object = $package->new();
		$cache{ $code_filename } = {
			object	=> $object,
			mtime	=> $mtime,
		};
	} else {
		##
		# Just grab the previously cached object.
		##
		$object = $cache{ $code_filename }{ object };
	}

	##
	# Inject a copy of the reference to the Apache::Request into the object
	# so it can have access to it.
	##
	$object->{ r } = $r;

	##
	# Since we're generating dynamic pages, tell Apache to emit the headers
	# that tell browsers not to cache pages.
	##
	$r->no_cache( 1 );

	##
	# If the object implements either a "get" or "post" method, call it.
	# If it returns anything but OK, assume it handled the request and
	# merely return its status.
	##
	my $status = OK;
	if ( $r->method eq 'GET' ) {
		goto clean_up if
			$object->can( 'get' ) &&
			( $status = $object->get() ) != OK;
	} elsif ( $r->method eq 'POST' ) {
		goto clean_up if
			$object->can( 'post' ) &&
			( $status = $object->post() ) != OK;
	}

	##
	# Parse the HTML file into a tree.
	##
	my $html = HTML::Tree->new( $r->filename );
	unless ( $html ) {
		$r->log_error( "ClassParser: can not parse ", $r->filename );
		$status = SERVER_ERROR;
		goto clean_up;
	}

	##
	# If we're at the head of an Apache::Filter chain, call filter_input()
	# as required even though we don't use the returned filehandle since
	# HTML_Tree mmap's the file; and also do NOT emit the HTTP headers
	# since that task must be done by Apache::Filter after the last filter
	# in the chain.  Otherwise, just emit the HTTP headers.
	##
	if ( lc( $r->dir_config( 'Filter' ) ) eq 'on' ) {
		$r->filter_input();
	} else {
		$r->send_http_header();
	}

	##
	# Finally, visit all nodes in the tree.
	##
	$html->visit( $object, \&visitor );

clean_up:
	##
	# Blow away the object's copy of the reference to the Apache::Request
	# so it will be deleted when handler() exits.
	##
	delete $object->{ r };

	return $status;
}

###############################################################################
#
#	Built-in class_map functions
#
###############################################################################

sub escape_text {
	my @a = @_;
	for ( @a ) {
		s/&/&amp;/g;
		s/"/&quot;/g;
		s/</&lt;/g;
		s/>/&gt;/g;
	}
	return @a > 1 ? @a : $a[0];
}

sub append_att {
	my( $this, $node, $class, $is_end_tag ) = @_;
	return 0 if $is_end_tag;
	my( $att, $key ) = $class =~ /^append::(\w+)::(\w+)$/;
	$node->atts->{ $att } .= escape_text( $this->{ $key } );
	return 1;
}

sub check_key {
	my( $this, $node, $class, $is_end_tag ) = @_;
	return 0 if $is_end_tag;
	my( $key ) = $class =~ /^check::(\w+)$/;
	$node->att( 'checked', $this->{ $key } ? 'checked' : undef );
	return 1;
}

sub if_key {
	my( $this, $node, $class, $is_end_tag ) = @_;
	return 0 if $is_end_tag;
	my( $key ) = $class =~ /^if::(\w+)$/;
	return $this->{ $key };
}

sub select_key {
	my( $this, $node, $class, $is_end_tag ) = @_;
	return 0 if $is_end_tag;
	my( $key ) = $class =~ /^select::(\w+)$/;
	$node->att( 'selected',
		$node->att( 'value' ) eq $this->{ $key } ? 'selected' : undef
	);
	return 1;
}

sub sub_att {
	my( $this, $node, $class, $is_end_tag ) = @_;
	return 0 if $is_end_tag;
	my( $att, $key ) = $class =~ /^sub::(\w+)::(\w+)$/;
	$node->att( $att, escape_text( $this->{ $key } ) );
	return 1;
}

sub sub_att_id {
	my( $this, $node, $class, $is_end_tag ) = @_;
	return 0 if $is_end_tag;
	my( $att, $key ) = $class =~ /^sub_id::(\w+)::(\w+)$/;
	$node->atts->{ $att } =~ s/\d+/escape_text( $this->{ $key } )/e;
	return 1;
}

sub sub_href {
	my( $this, $node, $class, $is_end_tag ) = @_;
	return 0 if $is_end_tag;
	my( $key ) = $class =~ /^href::(\w+)$/;
	$node->att( 'href', escape_text( $this->{ $key } ) );
	return 1;
}

sub sub_href_id {
	my( $this, $node, $class, $is_end_tag ) = @_;
	return 0 if $is_end_tag;
	my( $key ) = $class =~ /^href_id::(\w+)$/;
	$node->atts->{ href } =~ s/\d+/escape_text( $this->{ $key } )/e;
	return 1;
}

sub sub_text {
	my( $this, $node, $class, $is_end_tag ) = @_;
	return 0 if $is_end_tag;
	my( $key ) = $class =~ /^text::(\w+)$/;
	($node->children())[0]->text( escape_text( $this->{ $key } ) );
	return 1;
}

sub sub_value {
	my( $this, $node, $class, $is_end_tag ) = @_;
	return 0 if $is_end_tag;
	my( $key ) = $class =~ /^value::(\w+)$/;
	$node->att( 'value', escape_text( $this->{ $key } ) );
	return 1;
}

sub sub_value_id {
	my( $this, $node, $class, $is_end_tag ) = @_;
	return 0 if $is_end_tag;
	my( $key ) = $class =~ /^value_id::(\w+)$/;
	$node->atts->{ value } =~ s/\d+/escape_text( $this->{ $key } )/e;
	return 1;
}

sub unless_key {
	my( $this, $node, $class, $is_end_tag ) = @_;
	return 0 if $is_end_tag;
	my( $key ) = $class =~ /^unless::(\w+)$/;
	return !$this->{ $key };
}

my %function_map = (
	append   => \&append_att,
	check    => \&check_key,
	href     => \&sub_href,
	href_id  => \&sub_href_id,
	if       => \&if_key,
	select   => \&select_key,
	sub      => \&sub_att,
	sub_id   => \&sub_att_id,
	text     => \&sub_text,
	unless   => \&unless_key,
	value    => \&sub_value,
	value_id => \&sub_value_id,
);

###############################################################################
#
# SYNOPSIS
#
	sub visitor
#
# DESCRIPTION
#
#	Visit nodes in the HTML tree and generally emit the HTML for them.  If
#	an HTML element has a CLASS attribute, see if any of the class values
#	are in either the built-in function map or the $object's class_map.  If
#	so, call the functions.
#
# PARAMETERS
#
#	object		A reference to a hash that MUST contain a "class_map"
#			key and whose value MUST be a hash for the object's
#			class map.
#
#	node		A reference to the node we are visiting.
#
#	depth		How "deep" the node is in the tree.
#
#	is_end_tag	True only if we're being called for the end tag of an
#			element.
#
# RETURN VALUE
#
#	If the node is a text node, returns 1; otherwise, if a function was
#	called, returns the value of the function.
#
###############################################################################
{
	my( $object, $node, $depth, $is_end_tag ) = @_;

	if ( $node->is_text() ) {
		##
		# For text nodes, simply emit the text as-is and return.
		##
		print $node->text();
		return 1;
	}

	##
	# Default the result to false so that, unless changed by a function in
	# the class_map, we will return false for end tags (meaning "do not
	# loop").
	##
	my $result = 0;

	##
	# Do all CLASSes given by the value of the CLASS attribute.
	##
	my $class_map = $object->{ class_map };
	for ( split( /\s+/, $node->att( 'class' ) ) ) {
		my $func;

		##
		# See if the function is a built-in one; if not, check in the
		# class map (if it exists).
		##
		if ( /^(\w+)::/ && exists $function_map{ $1 } ) {
			$func = $function_map{ $1 };
		} else {
			$func = $class_map->{ $_ } if $class_map;
		}

		##
		# There is no function having the given class name: silently
		# ignore it...maybe it's a style name.
		##
		next unless $func;

		##
		# Got a function: call it to visit the current HTML node.
		##
		$result = $func->( $object, $node, $_, $is_end_tag );

		##
		# For end tags, we call the function only for the first class
		# since it makes no sense to call more than one.
		##
		last if $is_end_tag;

		##
		# For start tags, we "short-circuit" the calling of multiple
		# classes and return when the first class returns false.
		##
		return 0 unless $result;
	}

	if ( $is_end_tag ) {
		##
		# For end tags, simply emit the end tag and return whatever the
		# result is.
		##
		print '</', $node->name(), '>';
		return $result;
	}

	##
	# For start tags, emit it plus all of its attributes.
	##
	print '<', $node->name();
	my $atts = $node->atts();
	while ( my( $att, $val ) = each %{ $atts } ) {
		print " $att=\"$val\"";
	}
	print '>';

	return 1;
}

1;
__END__

=head1 NAME

C<Apache::HTML::ClassParser> - Apache mod_perl extension for generating dynamic HTML pages based on C<CLASS> attributes

=head1 SYNOPSIS

 # In Apache's httpd.conf file:
 AddType text/html	.chtml
 <Files *.chtml>
   SetHandler		perl-script
   PerlHandler		+Apache::HTML::ClassParser
 </Files>

=head1 DESCRIPTION

C<Apache::HTML::ClassParser> is yet another C<mod_perl> Apache module
for dynamically generating HTML.
Its distinctive feature, unlike existing techniques,
is that it uses I<pure>, standard HTML files:
no print-statement-laden CGI scripts,
no embedded statements from some programming langauge,
and no pseudo-HTML elements.
Code is cleanly separated into a separate file.
What links the two together are C<CLASS> attributes for HTML elements.

=head1 CONFIGURATION

In order to have C<ClassParser> be a handler for HTML files,
configuration directives, such as those shown in the SYNOPSIS,
must be added to Apache's C<httpd.conf> file.
The HTML files to be handled by C<ClassParser>,
as with all Apache handler modules,
can be specified either by location, filename extension, or both.
For more detail on Apache configuration directives,
see [Apache].

=head2 Cooperation with C<Apache::Filter>

C<ClassParser> is C<Apache::Filter>-aware.
However, if used in a filter chain, it B<must> be the first filter.
(This is because it uses the C<HTML::Tree> module
that uses mmap(2) to read an HTML file.)

For example, to configure Apache to have HTML files run through
C<ClassParser> then C<Apache::SSI> (server-side includes), do:

    PerlModule		Apache::Filter
    PerlModule		Apache::HTML::ClassParser
    PerlModule		Apache::SSI

    AddType text/html	.chtml
    <Files *.chtml>
      SetHandler	perl-script
      PerlSetVar	Filter On
      PerlHandler	Apache::HTML::ClassParser Apache::SSI
    </Files>

=head1 TERMINOLOGY AND CONVENTIONS

=head2 Element vs. Tag

It is often the case that the term HTML "tag" is used
when the correct term of "element" should be.
From the HTML 4.0 specification, section 3.2.1, "Elements":

=over 4

=item

I<Elements are not tags.
Some people refer to elements as tags (e.g., "the >C<P>I< tag").
Remember that the element is one thing,
and the tag (be it start or end tag) is another.
For instance, the >C<HEAD>I< element is always present,
even though both start and end >C<HEAD>I< tags may be missing in the markup.>

=back

In this documentation,
the distinction between "element" and "tag" is necessary.

=head2 Class vs. C<CLASS>

In this documentation,
there are unfortunately two meanings of the word "class":

=over 4

=item 1.

A class attribute of an HTML element, e.g.:

    <H1 CLASS="heading_1">Introduction</H1>

where C<CLASS>es are typically used to convey style information.

=item 2.

A Perl class from which objects are created, e.g.:

    package MyClass;
    sub new {
        my $class = shift;
        my $this = {};
        return bless $this, $class;
    }
    $object = MyClass->new();

(See [Wall], pp. 290-292.)

=back

Therefore, throughout this document,
"class" written as "C<CLASS>"
shall mean the class attribute of an HTML element (case 1)
and "class" written simply as "class"
shall mean a Perl class (case 2).

=head1 The HTML File

The file for a web page is in pure HTML.
(It can also contain JavaScript code,
but that's irrelevant for the purpose of this discussion.)
At every location in the HTML file where something is to happen dynamically,
an HTML element must contain a C<CLASS> attribute
(and perhaps some "dummy" content).
(The dummy content allows the web page designer to create a mock-up page.)

For example,
suppose the options in a menu are to be retrieved from a relational database,
say the flavors available on an ice cream shop's web site.
The HTML would look like this:

    <!-- ice_cream.chtml -->
    <SELECT NAME="Flavors" CLASS="query_flavors">
      <OPTION CLASS="next_flavor" VALUE="0">Tooty Fruity
    </SELECT>

The C<CLASS>es C<query_flavors> and C<next_flavor>
will be used to generate HTML dynamically.
The values of the C<CLASS> attributes can be anything
as long as they agree with those in the code file
(specified later).
The text "Tooty Fruity" is dummy content.

The C<query_flavors> C<CLASS> will be used
to perform the query from the database;
C<next_flavor> will be used to
fetch every tuple returned from the query
and to substitute the name and ID number of the flavor.

The value of a C<CLASS> attribute may contain multiple classes
separated by whitespace.
(More on this later.)

=head1 The Code File

For every HTML file that is to be used with this technique,
there B<must> be an associated code file in Perl.
It B<must> have the same name as the HTML file
except that the extension is C<.pm> rather than C<.chtml>.
(There is an exception; see "Using a Different Code File via C<pm_uri>" below.)
That code file B<must> define its own package (a.k.a. module), e.g.:

    # ice_cream.pm
    package IceCream;

to implement a class;
that class B<must> have a constructor.

=head2 The Constructor and C<class_map>

A package requires a constructor method that B<must> be named C<new()>.
A minimal such constructor
(for which most of the code is taken from [Wall], p. 295)
is:

    sub new {
        my $that = shift;
        my $class = ref( $that ) || $that;
        my $this = {
            class_map => {
                query_flavors => \&query_flavors,
                next_flavor   => \&next_flavor,
            },
            # other stuff you want here ...
        };
        return bless $this, $class;
    }

A second requirement is that the object's hash
B<must> contain a C<class_map> key
whose value is a reference to a hash
containing a mapping from C<CLASS> attribute values
from the HTML file to functions
(methods of the class)
in the Perl file.

B<This is the key concept>:
it is the C<class_map> that links the HTML file to the Perl code.

In the above constructor,
the C<CLASS> names C<query_flavors> and C<next_flavor>
both map to methods having the same name.
In practice, this probably will (and should) be the case;
however, there is no requirement that it be so.
This allows more than one C<CLASS> name to map to the same method.
(If there were such a requirement,
there would be no need for the C<class_map>.)

=head2 Class Methods

Class methods are passed the following arguments:

=over 15

=item C<$this>

A reference to an object of a class.

=item C<$node>

A reference to an HTML element node, e.g., C<SELECT>.

=item C<$class>

The value of the C<CLASS> attribute of the HTML element
the method is being called for.
This is useful if more than one class
maps to the same method.

=item C<$is_end_tag>

True only when the method is being called for the end tag of an HTML element.

=back

Class methods B<must> return a Boolean value
(zero or non-zero for false or true, respectively).
There are two meanings for the return value;
they are the same as for I<visitor> functions used by B<HTML::Tree>.
Repeated here for convenience, they are:

=over 4

=item 1.

If the $is_end_tag argument is false,
returning false means:
do not visit any of the current node's child nodes,
i.e., skip them and proceed directly to the current node's next sibling
and also do not call the I<visitor> again for the end tag;
returning true means: do visit all child nodes
and call the I<visitor> again for the end tag.

=item 2.

If the $is_end_tag argument is true,
returning false means:
proceed normally to the next sibling;
returning true means:
loop back and repeat the visit cycle from the beginning
by revisiting the start tag of the current element node
(case 1 above).

=back

The implementation of the C<query_flavors()> and C<next_flavor()> methods
shall be presented in stages.

The C<query_flavors()> method begins by getting its arguments
as described above:

    sub query_flavors {
        my( $this, $node, $class, $is_end_tag ) = @_;

The query must be performed upon encountering the start tag
of the C<SELECT> element;
therefore, the method returns false immediately if $is_end_tag is true.
This tells C<ClassParser> not to proceed with parsing the C<SELECT> element's
child elements again (in this case, the single C<OPTION> element)
and to proceed to its next sibling element
(i.e., the element after the C</SELECT> end tag):

        return 0 if $is_end_tag;

The bulk of the code is standard DBI/SQL.
A copy of the database and statement handles is stored in the object's hash
so the C<next_flavor()> method can access them later:

        $this->{ dbh } = DBI->connect( 'DBI:mysql:ice_cream:localhost' );
        $this->{ sth } = $this->{ dbh }->prepare( '
            SELECT   flavor_id, flavor_name
            FROM     flavors
            ORDER BY flavor_name
        ' );
        $this->{ sth }->execute();

(If the C<Apache::DBI> module was specified ahead of C<ClassParser>
in the Apache C<httpd.conf> file,
database connections will be transparently persistent.
See [Stein], pp. 236-237.)

Finally, the method returns true to tell C<ClassParser>
to proceed with parsing the C<SELECT> element's child elements:

        return 1;
    }

The C<next_flavor()> method begins identically to C<query_flavors()>:

    sub next_flavor {
        my( $this, $node, $class, $is_end_tag ) = @_;

The fetch of the next tuple from the query
must be performed upon encountering the start tag of the C<OPTION> element;
therefore, the method returns true immediately if $is_end_tag is true.
This tells C<ClassParser> to loop back to the beginning of the element,
in this case to do another fetch:

        return 1 if $is_end_tag;

The next portion of code fetches a tuple from the database.
If there are no more tuples,
the method returns false.
This tells C<ClassParser> not to emit the HTML for the C<OPTION> element
and also tells it to stop looping:

        my( $flavor_id, $flavor_name ) = $this->{ sth }->fetchrow();
        unless ( $flavor_id ) {
            $this->{ sth }->finish();
            $this->{ dbh }->disconnect();
            return 0;
        }

The code also disconnects from the database.
(However, if C<Apache::DBI> was specified,
the C<disconnect()> becomes a no-op
and the connection remains persistent.)

The next portion of code substitutes content in the HTML that will be emitted.
The first line sets the value of the C<OPTION> element's C<VALUE> attribute
to be the C<flavor_id> from the tuple:

        $node->att( 'value', $flavor_id );

and the next line substitutes the text of the first child node
(in this case, the text "Tooty Fruity")
for the C<flavor_name> from the tuple:

        ($node->children())[0]->text( $flavor_name );

Finally, the method returns true to tell C<ClassParser>
to emit the HTML for the C<OPTION> element
now containing the dynamically generated content:

        return 1;
    }

=head1 Other Stuff

=head2 Built-in CLASSes

There are several HTML manipulations that are performed routinely;
therefore, CLASSes to perform these manipulations are built-in
without needing to be explicitly listed in a C<class_map>.

All of the built-in CLASSes always return false when called for an end tag;
all but C<if> and C<unless> always return true for a start tag.

=over 4

=item C<append::>I<attribute>C<::>I<key>

Append to the value of an attribute of the current element.
The I<attribute> is the name of the HTML attribute
whose value is to be appended to
and I<key> is the key into $this that contains the value to be appended.
This example appends the value of C<$this-E<gt>S<{ flavor_id }>> to the C<HREF>
attribute:

    <A HREF="flavor_detail.chtml?flavor_id="
     CLASS="append::href::flavor_id">Flavor details</A>

Note that C<append::>I<attribute>C<::>I<key> must not be used inside loops
since it always appends.

=item C<check::>I<key>

Set the C<CHECKED> attribute of the current C<INPUT> element
for checkboxes and radio buttons only if a value is true.
The I<key> is the key into $this that contains the value to test.
This example selects the checkbox
only if C<$this-E<gt>S<{ sprinkles }>> is true.

    <INPUT TYPE=checkbox NAME="Sprinkles"
     CLASS="check::sprinkles">Sprinkles

=item C<href::>I<key>

This is a shorthand for C<sub::href::>I<key> since it occurs frequently.

=item C<href_id::>I<key>

This is a shorthand for C<sub_id::href::>I<key> since it occurs frequently.

=item C<if::>I<key>

Emit the HTML up to and including the end tag for the current element
only if a value is true.
The I<key> is the key into $this that contains the value to be tested.
This example emits a table only if C<$this-E<gt>S<{ results }>> is true:

    <TABLE CLASS="if::results">
      ...
    </TABLE>

=item C<select::>I<key>

Set the C<SELECTED> attribute of the current C<OPTION> element
depending upon the value of the C<VALUE> attribute.
The I<key> is the key into $this that contains the value to compare against.
This example selects the option only where the C<VALUE> is equal to
C<$this-E<gt>S<{ flavor_id }>>:

    <SELECT NAME="Flavor">
      <OPTION CLASS="select::flavor_id" VALUE="0">Chocolate
      <OPTION CLASS="select::flavor_id" VALUE="1">Strawberry
      <OPTION CLASS="select::flavor_id" VALUE="2">Vanilla
    </SELECT>

=item C<sub::>I<attribute>C<::>I<key>

Substitute the value of an attribute of the current element.
The I<attribute> is the name of the HTML attribute
whose old value is to be substituted
and I<key> is the key into $this that contains the new value to be substituted.
This example substitutes the value of the C<TYPE> attribute
with the value of C<$this-E<gt>S<{ form_type }>>:

    <INPUT TYPE="radio" NAME="flavor_id" VALUE="1"
     CLASS="sub::type::form_type">

=item C<sub_id::>I<attribute>C<::>I<key>

Substitute the "ID part" of the value of an attribute of the current element.
The I<attribute> is the name of the HTML attribute
that contains the value whose "ID part" is to be substituted
and I<key> is the key into $this that contains the new ID to be substituted.
The "ID part" matches the pattern C<\d+> within the value,
i.e., a numeric ID.
This example substitutes the "1" in the value of the C<HREF> attribute
with the value of C<$this-E<gt>S<{ flavor_id }>>:

    <A HREF="/cgi-bin/get?id=1"
     CLASS="sub_id::href::flavor_id">Go</A>

=item C<text::>I<key>

Substitute the text of the first child node (which B<must> be a text node).
The I<key> is the key into $this that contains the text to be substituted.
This example substitutes the text "Tooty Fruity"
with the value of C<$this-E<gt>S<{ flavor_name }>>:

    <SPAN CLASS="text::flavor_name">Tooty Fruity</SPAN>

=item C<unless::>I<key>

Emit the HTML up to and including the end tag for the current elemment
only if a value is false.
(This is the opposite of C<if::>I<key>.)
The I<key> is the key into $this that contains the value to be tested.
(See the example for C<if::>I<key>.)

=item C<value::>I<key>

This is a shorthand for C<sub::value::>I<key> since it occurs frequently.

=item C<value_id::>I<key>

This is a shorthand for C<sub_id::value::>I<key> since it occurs frequently.

=back

=head2 Multiple CLASS Values

The value of a C<CLASS> attribute may contain multiple classes
separated by whitespace.
When that is the case,
the function that each maps to is called in turn
and the return result is the logical-and of the functions.
Just as with Perl's C<&&> operator,
the first to return false "short-circuits" the evaluation.

However, that is true only when the functions are being called
for the start tag;
when being called for the end tag,
only the first function is called regardless of its return value.

In light of this, the first example can be rewritten as:

    <SELECT NAME="Flavors" CLASS="query_flavors">
      <OPTION CLASS="next_flavor value::flavor_id text::flavor_name"
       VALUE="0">Tooty Fruity
    </SELECT>

This would call C<next_flavor()> as before, but, if it returns true,
it would also call the remaining functions in turn.

The C<next_flavor()> function would also have to change to:

    sub next_flavor {
        my( $this, $node, $class, $is_end_tag ) = @_;
        return 1 if $is_end_tag;
        ( $this->{ flavor_id }, $this->{ flavor_name } ) =
		$this->{ sth }->fetchrow();
        unless ( $this->{ flavor_name } ) {
            # ... same as before ...
        }
        return 1;
    }

The switch to using
S<C<$this-E<gt>{ flavor_id }>>
and
S<C<$this-E<gt>{ flavor_name }>>
is necessary since all the built-in CLASSes use
S<C<$this-E<gt>{> I<key> C<}>>
for the values they use.

Because the built-in CLASSes are called to do the substitutions, the lines:

        $node->att( 'value', $flavor_id );
        ($node->children())[0]->text( $flavor_name );

that are present in the original version of C<next_flavor()> have been removed.

=head2 Improved Performance via C<bind_values()>

Although the following has more to do with DBI than C<ClassParser>,
it's presented here since it will improve the overall performance
when using the two together.

Generally, the DBI function C<bind_values()> should be used
when retrieving multiple tuples from a database query.
The C<query_flavors()> function can be rewritten to use it as follows:

    sub query_flavors {
        # ... same as before ...
        $this->{ sth }->bind_values(
            \$this->{ flavor_id }, \$this->{ flavor_name }
        );
        return 1;
    }

(See the DBI manual page for details.)
In this case, the result attributes B<must> to be bound to
S<C<$this-E<gt>{> I<key> C<}>>
so the values can be accessed by the C<next_flavor()> function
that can be rewritten as follows:

    sub next_flavor {
        my( $this, $node, $class, $is_end_tag ) = @_;
        return 1 if $is_end_tag;
        unless ( $this->{ sth }->fetch() ) {
            # ... same as before ...
        }
        return 1;
    }

Notice that C<fetchrow()> has been replaced by C<fetch()>
and that there are no assignments.

=head2 Handling GET Requests

Dynamically generated web pages often need parameters
to determine the content.
Such paramaters can be passed via the query string as in:

    http://www.icecream.com/flavor/detail.chtml?flavor_id=4

It's desirable to perform parameter validation
before displaying any part of a web page
because, if you start to display the page and discover an invalid parameter,
it's too late.
For example, the C<flavor_id> should be checked to ensure that it
refers to an existing flavor in the database:
if it doesn't, a redirection can be done to an error page.

For this to work, the code file B<must> define a method named C<get()>.
The implementation for this example shall be presented in stages.
The C<get()> method begins simply as:

    sub get {
        my $this = shift;

The code then prepares an SQL query via DBI:

        my $dbh = DBI->connect( 'DBI:mysql:ice_cream:localhost' );
        my $sth = $dbh->prepare( '
            SELECT 1
            FROM   flavors
            WHERE  flavor_id = ?
        ' );

C<ClassParser> stores a copy of the reference
to the current C<Apache::Request> object
into S<C<$this-E<gt>{ r }>>
from which query parameters can be extracted:

        my $r = $this->{ r };

(The variable name $r is used by convention.)
A check is made to ensure C<flavor_id> was given as a parameter
and, if so, an attempt is made to execute the query and fetch the result row.
If anything fails, the display of the web page is aborted
by returning the standard Apache C<NOT_FOUND> error:

        return NOT_FOUND unless
	    $r->param( 'flavor_id' ) &&
            $sth->execute( $r->param( 'flavor_id' ) ) &&
            $sth->fetchrow();

If all succeeds, then the function simply returns C<OK>:

        return OK;
    }

The return value B<must> be one of the C<Apache::Constants>.
If the value is C<OK>,
then the display of the web page proceeds normally;
if the value is anything other than C<OK>,
then the web page is not displayed.
In either case, that return value is passed back to Apache.

=head2 Handling POST Requests

Ordinarily, the C<ACTION> attribute in an HTML C<FORM> element
contains a URI pointing at a CGI script, e.g.:

    <FORM ACTION="/cgi-bin/process_my_data.cgi" METHOD="post">

After processing form data,
some web page needs to be displayed to the user.
The CGI could either emit the HTML for that page itself
or do a redirect to an existing web page.
A C<ClassParser>-parsed HTML file, however,
can handle C<POST> requests itself, e.g.:

    <FORM ACTION="/my.chtml" METHOD="post">

For this to work, it B<must> define a method named C<post()>
such as:

    sub post {
        my $this = shift;
	# do something yummy with $this->{ r }->param( 'Flavors' ) ...
	return OK;
    }

Similarly to the GET request case,
C<ClassParser> stores a copy of the reference
to the current C<Apache::Request> object
into S<C<$this-E<gt>{ r }>>
from which form parameters can be extracted.
In the example,
C<Flavors> is the value of the C<NAME> attribute of the C<SELECT> element,
so S<C<$this-E<gt>{ r }-E<gt>>C<param('Flavors')>>
is the value of the C<VALUE> attribute of the selected C<OPTION> element,
or the flavor ID.

Identically to the GET request case,
the return value B<must> be one of the C<Apache::Constants>.

=head2 Using a Different Code File via C<pm_uri>

As previously described,
every HTML file B<must> have an associated code file
having the same name as the HTML file
except with an extension of C<.pm> rather than C<.chtml>.
However, if a FORM parameter C<pm_uri> has a value either via a GET or POST
(but most often via a POST),
then B<that> code file will be used instead
to handle either the GET or POST request.
This allows you to consolidate form-processing code into a single code file.
The easiest way to specify a value for C<pm_uri>
is using a hidden C<INPUT> element:

    <INPUT TYPE=hidden NAME="pm_uri" VALUE="other.pm">

=head2 Persistence

A code file is loaded, compiled once, and stored in memory.
Additionally,
a single object is created via the constructor and stored in memory also.
Both the code and the object are used for all subsequent HTTP requests.
The code is reloaded, recompiled, and stored, and a new object is created
only if the modification time of the code file
is later than the last time it was loaded.

This code/object persistence is done for efficiency/performance reasons only.
In particular, although an object is persistent across multiple HTTP requests,
data can not be stored in the object to implement anything like "sessions" for
users.
The reason is because Apache forks multiple child processes
and code and objects are persistent only within a B<single> child process
and not among them.
Hence, it is most likely the case that a given user's HTTP requests
will be handled by multiple Apache child processes.
(There are several techniques for doing "sessions": see [Stein], Chapter 5.)

=head2 Web Page Caching

C<ClassParser> sets the C<no_cache> flag for the Apache request.
Since web pages generated with C<ClassParser> are dynamic,
they should always reflect the latest information.

=head1 SEE ALSO

perl(1),
Apache::DBI(3),
Apache::Filter(3),
DBI(3),
HTML::Tree(3).

Apache Group.
I<Apache HTTPD Server Project>,
C<http://www.apache.org/>

Apache/Perl Integration Project,
I<mod_perl>,
C<http://perl.apache.org/>

Dave Raggett, et al.
"On SGML and HTML: SGML constructs used in HTML: Elements,"
I<HTML 4.0 Specification, section 3.2.1>,
World Wide Web Consortium,
April 1998.
C<http://www.w3.org/TR/PR-html40/intro/sgmltut.html#h-3.2.1>

--.
"The global structure of an HTML document: The document body:
Element identifiers: the C<id> and C<class> attributes,"
I<HTML 4.0 Specification, section 7.5.2>,
World Wide Web Consortium,
April 1998.
C<http://www.w3.org/TR/PR-html40/struct/global.html#h-7.5.2>

Lincoln Stein and Doug MacEachern.
I<Writing Apache Modules with Perl and C>,
O'Reilly & Associates, Inc., Sebastopol, CA,
1999.

Larry Wall, et al.
I<Programming Perl, 2nd ed.>,
O'Reilly & Associates, Inc., Sebastopol, CA,
1996.

=head1 AUTHOR

Paul J. Lucas <I<pjl@best.com>>

=head1 CREDIT

As far as I know,
the technique for using pure HTML to generate dynamic web pages
using only C<CLASS> attributes
was invented by Erik Ostrom.

=cut
