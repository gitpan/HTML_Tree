/*
**	HTML Tree
**	html.c
**
**	Copyright (C) 1999  Paul J. Lucas
**
**	This program is free software; you can redistribute it and/or modify
**	it under the terms of the GNU General Public License as published by
**	the Free Software Foundation; either version 2 of the License, or
**	(at your option) any later version.
** 
**	This program is distributed in the hope that it will be useful,
**	but WITHOUT ANY WARRANTY; without even the implied warranty of
**	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**	GNU General Public License for more details.
** 
**	You should have received a copy of the GNU General Public License
**	along with this program; if not, write to the Free Software
**	Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

// standard
#include <cctype>
#include <cstring>
#include <string>

// local
#include "Content_Node.h"
#include "Element_Node.h"
#include "fake_ansi.h"
#include "file_vector.h"
#include "html.h"
#include "Parent_Node.h"
#include "Text_Node.h"
#include "util.h"

#ifndef	PJL_NO_NAMESPACES
using namespace std;
#endif

int const	Tag_Name_Max_Size = 10;
//		The maximum size of an HTML tag name, e.g., "BLOCKQUOTE".  You
//		might need to increase this if you are indexing HTML documents
//		that contain non-standard tags and at least one of them is
//		longer than the above.

void		parse_html_tag( char const *&pos, char const *end );
void		skip_html_tag( char const *&pos, char const *end );
bool		tag_cmp( char const *&pos, char const *end, char const *tag );

static HTML_Node *cur_node;

//*****************************************************************************
//
// SYNOPSIS
//
	bool is_html_comment(
		register char const *&c, register char const *end
	)
//
// DESCRIPTION
//
//	Checks to see if the current HTML element is the start of a comment. If
//	so, skip it scanning for the closing "-->" character sequence.  The
//	HTML specification permits whitespace between the "--" and the ">" (for
//	some strange reason).  Unlike skipping an ordinary HTML tag, quotes are
//	not significant and no attempt must be made either to "balance" them or
//	to ignore what is in between them.
//
//	This function is more lenient than the HTML 4.0 specification in that
//	it allows for a string of hyphens within a comment since this is common
//	in practice; the specification considers this to be an error.
//
// PARAMETERS
//
//	c	The iterator to use.  It is presumed to be positioned at the
//		first character after the '<'.  If the tag is the start of a
//		comment, it is repositioned at the first character past the
//		tag, i.e., past the "!--"; otherwise, it is not touched.
//
//	end	The iterator marking the end of the file.
//
// SEE ALSO
//
//	Dave Raggett, Arnaud Le Hors, and Ian Jacobs.  "On SGML and HTML: SGML
//	constructs used in HTML: Comments," HTML 4.0 Specification, section
//	3.2.4, World Wide Web Consortium, April 1998.
//		http://www.w3.org/TR/PR-html40/intro/sgmltut.html#h-3.2.4
//
//*****************************************************************************
{
	if ( tag_cmp( c, end, "!--" ) ) {
		while ( c != end ) {
			if ( *c++ != '-' )
				continue;
			while ( c != end && *c == '-' )
				++c;
			while ( c != end && isspace( *c ) )
				++c;
			if ( c != end && *c++ == '>' )
				break;
		}
		return true;
	}
	return false;
}

//*****************************************************************************
//
// SYNOPSIS
//
	void parse_attributes(
		register char const *c, char const *end,
		Element_Node::attribute_map &attributes
	)
//
// DESCRIPTION
//
//	Parse out all the attributes and their values of an HTML element.  The
//	HTML 4.0 specification is vague in stating whether whitespace is legal
//	around the '=' character separating an attribute's name from its value;
//	hence, this function is lenient in that it will consider:
//
//		NAME = "Author"
//	and:
//		NAME="Author"
//
//	equivalent.
//
// PARAMETERS
//
//	c	The iterator marking the beginning of where to start parsing.
//
//	end	The iterator marking the end of where to stop parsing (usually
//		positioned at the closing '>' character of the HTML tag).
//
// SEE ALSO
//
//	Dave Raggett, Arnaud Le Hors, and Ian Jacobs.  "On SGML and HTML: SGML
//	constructs used in HTML: Attributes," HTML 4.0 Specification, section
//	3.2.2, World Wide Web Consortium, April 1998.
//		http://www.w3.org/TR/PR-html40/intro/sgmltut.html#h-3.2.2
//
//*****************************************************************************
{
	while ( c != end )				// skip element name
		if ( is_space( *c++ ) )
			break;

	while ( c != end ) {
		if ( !isalpha( *c ) ) {
			++c;
			continue;
		}
		//
		// Found the start of a potential attribute name.
		//
		char const *const name_begin = c;
		while ( c != end && ( isalpha( *c ) || *c == '-' ) )
			++c;
		char const *const name_end = c;
		while ( c != end && isspace( *c ) )
			++c;
		string const name( to_lower( name_begin, name_end ) );
		if ( c == end || *c != '=' ) {
			//
			// It's a Boolean attribute: set its value to be its
			// own name (per the HTML 4.0 spec).
			//
			attributes[ name ] = name;
			continue;
		}
		if ( c == end )
			break;
		while ( ++c != end && isspace( *c ) )
			;
		if ( c == end )
			break;
		//
		// Determine the span of the attribute's value: if it started
		// with a quote, it's terminated only by the matching closing
		// quote; if not, it's terminated by a whitespace character (or
		// running into 'end').
		//
		// This is more lenient than the HTML 4.0 specification in that
		// it allows non-quoted values to contain characters other than
		// the set [A-Za-z0-9.-], i.e., any non-whitespace character.
		//
		char const quote = ( *c == '"' || *c == '\'' ) ? *c : 0;
		if ( quote && ++c == end )
			break;
		char const *const b = c;
		for ( ; c != end; ++c )
			if ( quote ) {		// stop at matching quote only
				if ( *c == quote )
					break;
			} else if ( isspace( *c ) )
				break;		// stop at whitespace

		attributes[ name ] = string( b, c );

		if ( c == end )
			break;
		++c;
	}
}

//*****************************************************************************
//
// SYNOPSIS
//
	Parent_Node* parse_html_file( file_vector const &file )
//
// DESCRIPTION
//
//	Parse the HTML file to build a tree.
//
// PARAMETERS
//
//	file	The file to parse.
//
// RETURN VALUE
//
//	Returns a pointer to the root node of the tree.
//
//*****************************************************************************
{
	Parent_Node *const root_node = new Parent_Node();
	cur_node = root_node;

	file_vector::const_iterator c = file.begin();
	while ( c != file.end() ) {
		file_vector::const_iterator const b = c;
		register file_vector::value_type ch = *c++;

		if ( ch == '<' ) {
			//
			// If we encountered an HTML comment, treat it just
			// like a Text_Node.
			//
			if ( is_html_comment( c, file.end() ) )
				goto new_text_node;

			if ( c != file.end() && *c == '!' ) {
				skip_html_tag( c, file.end() );
				goto new_text_node;
			}

			//
			// Encountered an HTML tag: parse it and get a node
			// back.
			//
			parse_html_tag( c, file.end() );
			continue;
		}

		//
		// Collect a run of text into a Text_Node.
		//
		for ( ; c != file.end(); ++c )
			if ( *c == '<' ) {
				//
				// We've encountered the potential beginning of
				// an HTML tag: stop collecting text and create
				// a new Text_Node containing what we've
				// collected so far.
				//
				goto new_text_node;
			}

		continue;
new_text_node:
		new Text_Node( b, c, dynamic_cast<Parent_Node*>( cur_node ) );
	
	}

	if ( root_node->empty() ) {
		delete root_node;
		return 0;
	}
	return root_node;
}

//*****************************************************************************
//
// SYNOPSIS
//
	void parse_html_tag( register char const *&c, register char const *end )
//
// DESCRIPTION
//
//	This function does everything skip_html_tag() does but additionally
//	builds a DOM-like (Document Object Model) tree of nodes.  It does this
//	by knowing when to end elements.
//
// PARAMETERS
//
//	c	The iterator to use.  It must be positioned at the character
//		after the '<'; it is repositioned at the first character after
//		the '>'.
//
//	end	The iterator marking the end of the file.
//
//*****************************************************************************
{
	if ( c == end )
		return;
	char const *const tag_begin = c;
	skip_html_tag( c, end );
	char const *const tag_end = c - 1;
	bool const is_end_tag = *tag_begin == '/';

	char tag[ Tag_Name_Max_Size + 2 ];	// 1 for '/', 1 for null
	{ // local scope
	//
	// Copy only the tag name by stopping at a whitespace character (or
	// running into tag_end); also convert it to lower case.  (We don't
	// call to_lower() in util.c so as not to waste time copying the entire
	// tag with its attributes since we only want the tag name.)
	//
	register char *to = tag;
	register char const *from = tag_begin;
	while ( from != tag_end && !isspace( *from ) ) {
		//
		// Check to see if the tag is too long to be a valid one for an
		// HTML element: if it is, invalidate it by writing "garbage"
		// into the tag so something like "BLOCKQUOTED" (an invalid
		// tag) won't match "BLOCKQUOTE" (a valid tag) when one letter
		// shorter and throw off element closures.
		//
		if ( to - tag >= Tag_Name_Max_Size + is_end_tag ) {
			to = tag;
			*to++ = '\1';
			break;
		}
		*to++ = to_lower( *from++ );
	}
	*to = '\0';
	} // local scope

	////////// Close open element(s) //////////////////////////////////////

	while ( Element_Node const *const
		element_node = dynamic_cast<Element_Node*>( cur_node )
	) {
		if ( !element_node->element_.close_tags.contains( tag ) )
			break;
		//
		// The tag we're parsing closes the currently open element, so
		// "pop" the current node.
		//
		cur_node = cur_node->parent();

		//
		// We have to stop closing elements if we encounter the start
		// tag matching the end tag.
		//
		if ( !::strcmp( tag + 1, element_node->name() ) )
			break;
	}

	if ( is_end_tag ) {
		//
		// The tag is an end tag: stop here.
		//
		return;
	}

	////////// Look up the tag ////////////////////////////////////////////

	static element_map const &elements = element_map::instance();
	element_map::const_iterator const element_found = elements.find( tag );
	if ( element_found == elements.end() ) {
		//
		// We didn't find the element in our internal table: ignore it.
		// We really should do something better because this could
		// potentially mess up the proper closing of elements, but,
		// since we know nothing about this element, there's nothing
		// better that can be done.
		//
		return;
	}

	//
	// Found the element in our internal table: add it to the tree.
	//
	Parent_Node *const parent_node = dynamic_cast<Parent_Node*>( cur_node );
	if ( element_found->second.end_tag == element::forbidden ) {
		//
		// This element has no end tag, so create an Element_Node for
		// it.
		//
		new Element_Node(
			element_found->first, element_found->second,
			tag_begin, tag_end, parent_node
		);
	} else {
		//
		// The element's end tag isn't forbidden, so create a
		// Content_Node for it and make it the new current node.
		//
		cur_node = new Content_Node(
			element_found->first, element_found->second,
			tag_begin, tag_end, parent_node
		);
	}
}

//*****************************************************************************
//
// SYNOPSIS
//
	void skip_html_tag( register char const *&c, register char const *end )
//
// DESCRIPTION
//
//	Scan for the closing '>' of an HTML tag skipping all characters until
//	it's found.  It takes care to ignore any '>' inside either single or
//	double quotation marks.
//
// PARAMETERS
//
//	c	The iterator to use.  It is presumed to start at any position
//		after the '<' and before the '>'; it is left at the first
//		character after the '>'.
//
//	end	The iterator marking the end of the file.
//
//*****************************************************************************
{
	register char quote = '\0';
	while ( c != end ) {
		if ( quote ) {			// ignore everything...
			if ( *c++ == quote )	// ...until matching quote
				quote = '\0';
			continue;
		}
		if ( *c == '\"' || *c == '\'' ) {
			quote = *c++;		// start ignoring stuff
			continue;
		}
		if ( *c++ == '>' )		// found it  :)
			break;
	}
}

//*****************************************************************************
//
// SYNOPSIS
//
	bool tag_cmp(
		char const *&c, register char const *end,
		register char const *tag
	)
//
// DESCRIPTION
//
//	Compares the tag name starting at the given iterator to the given
//	string.
//
// PARAMETERS
//
//	c	The iterator to use.  It is presumed to be positioned at the
//		first character after the '<'.  If the tag name matches, it is
//		repositioned at the first character past the name; otherwise,
//		it is not touched.
//
//	end	The iterator marking the end of the file.
//
//	tag	The string to compare against; case is irrelevant.
//
// RETURN VALUE
//
//	Returns true only if the tag matches.
//
//*****************************************************************************
{
	register char const *d = c;
	while ( *tag && d != end && to_lower( *tag++ ) == to_lower( *d++ ) ) ;
	return *tag ? false : c = d;
}
