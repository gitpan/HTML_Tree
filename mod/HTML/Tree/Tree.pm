##
package HTML::Tree;
#	mod/HTML/Tree/Tree.pm
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

use strict;
use vars qw( @EXPORT @EXPORT_OK @ISA $VERSION );

require Exporter;
require DynaLoader;
require AutoLoader;

@EXPORT = qw();
@EXPORT_OK = qw();
@ISA = qw( Exporter DynaLoader );
$VERSION = '1.2.3';

bootstrap HTML::Tree $VERSION;
1;
__END__

########## End of Perl Part -- The rest is documentation ######################

=head1 NAME

C<HTML::Tree> - Perl extension for quickly parsing HTML files into trees

=head1 SYNOPSIS

 use HTML::Tree;
 $html = HTML::Tree->new( 'file.html' );

 sub visitor {
	my( $node, $depth, $is_end_tag ) = @_;
	# ...
 }
 $html->visit( \&visitor );

or:

 sub visitor {
	my( $hash_ref, $node, $depth, $is_end_tag ) = @_;
	# ...
 }
 %my_hash;
 # ...
 $html->visit( \%my_hash, \&visitor );

=head1 DESCRIPTION

C<HTML::Tree> is a fast parser that parses an HTML file
into a tree structure like the HTML DOM (Document Object Model).
Once built, the nodes of the tree (elements and text from the HTML file)
can be traversed by a user-defined I<visitor> function.

C<HTML::Tree> is very similar to
the C<HTML::Parser> and C<HTML::TreeBuilder> modules by Gisle Aas,
except that it:

=over 4

=item 1.

Is several times faster.
C<HTML::Tree> owes its speed to two things:
using mmap(2) to read the HTML file bypassing conventional I/O and buffering,
and being written entirely in C++ as opposed to Perl.

=item 2.

Isn't a strict DTD (Document Type Definition) parser.
The goal is to parse HTML files fast,
not check for validity.
(You should check the validity of your HTML files with other tools I<before>
you put them on your web site anyway.)
For example,
C<HTML::Tree> couldn't care less what attributes a given HTML element has
just so long as the syntax is correct.
This is actually similar to browsers in that both are very permissive
in what they accept.

=item 3.

Offers simple conditional and looping mechanisms
assisting in the generation of dynamic HTML content.

=back

=head1 Methods

For the methods below,
the kind of node a method may be called on is indicated;
C<$node> means "any kind of node."
Calling a method for a node of the wrong kind is a fatal error.

=over 4

=item C<$root_node = HTML::Tree-E<gt>new(> I<file_name>C< )>

Parse the given HTML file
and return a reference to a new C<HTML::Tree> object.
If, for any reason, the file can not be parsed
(file does not exist, insufficient permissions, etc.),
C<undef> is returned.

=item C<$element_node-E<gt>att(> I<name>C< )>

Returns the value of the element node's I<name> attribute
or C<undef> if said node does not have one.
Attribute names B<must> be specified in lower case
(regardless of how they are in the HTML file).

=item C<$element_node-E<gt>att(> I<name>C<, >I<new_value>C< )>

Sets the value of the element node's I<name> attribute to I<new_value>.
If I<new_value> is C<undef>, then the attribute is deleted.
Attribute names B<must> be specified in lower case
(regardless of how they are in the HTML file).
If no I<name> attribute existed, it is added.

=item C<$element_node-E<gt>atts()>

Returns a reference to a tied hash of all of an element node's
attribute/value pairs
or a reference to an empty hash if said node does not have any.
Attribute names are returned in lower case
(regardless of how they are in the HTML file).
Because the hash is tied,
assigning to a hash element changes that attribute's value;
similarly, deleting an element deletes the attribute.

=item C<$element_node-E<gt>children()>

Returns all of an element node's child nodes
or an empty list if said node does not have any.

=item C<$node-E<gt>is_text()>

Returns true (1) only if the current node is a text node; false (0), otherwise.
(If a node isn't a text node, it must be an element node.)
HTML comments are treated as text nodes.

=item C<$element_node-E<gt>name()>

Returns the HTML element name of an element node, e.g., C<title>.
All names are returned in lower case
(regardless of how they are in the HTML file).

=item C<$text_node-E<gt>text()>

Returns the text of a text node.

=item C<$text_node-E<gt>text(> I<new_value>C< )>

Sets the text of a text node to I<new_value>;
returns the new text.

=item C<$root_node-E<gt>visit( \&>I<visitor>C< )>

Traverse the HTML tree
by calling the I<visitor> function for every node
starting at the root node
previously returned by the constructor.

=item C<$root_node-E<gt>visit( \%>I<hash>C<, \&>I<visitor>C< )>

Same as the previous method
except that a hash reference is passed along
(see B<Arguments> below).

=back

=head1 The Visitor Function

The user supplies a I<visitor> function:
a Perl function that is called when every node is visited
(i.e., a "call-back")
during an in-order tree traversal.

For HTML elements that have end tags,
the I<visitor> function may be called more than once for a given node
based on the function's return value.
(See B<Return Value> below.)

Note that this occurs for such HTML elements
even if said element's end tag is optional
and was not present in the HTML file.

=head2 Arguments

=over 15

=item C<$hash_ref>

A reference to a hash that is passed only if the two-argument form
of the C<visit()> method is used.
This provides a mechanism for additional data
(or a blessed object)
to be passed to and among the calls to the I<visitor> function.
The argument is not used at all by C<HTML::Tree>.

=item C<$node>

A reference to the current node.

=item C<$depth>

An integer specifying how "deep" the node is in the tree.
(Depths start at zero.)

=item C<$is_end_tag>

True (1) only if the tag is an end tag of an HTML element;
false (0), otherwise.

=back

=head2 Return Value

The I<visitor> function is expected to return a Boolean value
(zero or non-zero for false or true, respectively).
There are two meanings for the return value:

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

=head1 EXAMPLE

Here is a sample visitor function that "pretty prints" an HTML file:

	sub visitor {
		my( $node, $depth, $is_end_tag ) = @_;
		print "    " x $depth;
		if ( $node->is_text() ) {
			my $text = $node->text();
			$text =~ s/(?:^\n|\n$)//g;
			print "$text\n";
			return 1;
		}
		if ( $is_end_tag ) {
			print "</", $node->name(), ">\n";
			return 0;
		}
		print '<', $node->name();
		my $atts = $node->atts();
		while ( my( $att, $val ) = each %{ $atts } ) {
			print " $att=\"$val\"";
		}
		print ">\n";
		return 1;
	}

=head1 NOTES

In order for an HTML file to be properly parsed,
scripting languages B<must> be "comment hidden" as in:

	<SCRIPT LANGUAGE="JavaScript">
	<!--
		... script goes here ...
	// -->
	</SCRIPT>

=head1 SEE ALSO

perl(1),
mmap(2),
HTML::Parser(3),
HTML::TreeBuilder(3).

World Wide Web Consortium Document Object Model Working Group.
I<Document Object Model>,
December 1998.
C<http://www.w3.org/DOM/>

=head1 AUTHOR

Paul J. Lucas <I<pjl@best.com>>

=head1 HISTORY

The HTML parser of the C++ part of the module is derived from code in SWISH++,
a really fast file indexing and searching engine (also by the author).

=cut
