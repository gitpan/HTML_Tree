/*
**	HTML::Tree
**	Tree.xs
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

#include "HTML_Tree.h"

// Perl
extern "C" {
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
}

// Define "namespaced" symbols for Perl versions < 5.6
#if	!defined(PERL_REVISION) || !defined(PERL_VERSION) || \
	(PERL_REVISION <= 5 && PERL_VERSION < 6)
#define PL_na		na
#endif

// local
#include "blessed.h"
#include "hash4perl.h"
#include "perl_visitor.h"
#include "root_node.h"

//#############################################################################
#
MODULE = HTML::Tree		PACKAGE = HTML::Tree
#
#	This is the "main" package, the one that the user sees.
#
###############################################################################


###############################################################################
#
# SYNOPSIS
#
void
root_node::DESTROY()
#
# DESCRIPTION
#
#	Destroys the root node (and thereby the entire tree) of an HTML::Tree.
#
# NOTE
#
#	No explicit code is needed since the xsubpp compiler is smart enough to
#	generate the correct code to destroy a C++ object.
#
###############################################################################


###############################################################################
#
# SYNOPSIS
#
root_node*
root_node::new(file_name)
	char const* file_name
#
# DESCRIPTION
#
#	Parse an HTML file into an HTML::Tree and return a blessed reference to
#	an HTML::Tree.  (The blessing occurs via the typemap.)
#
# PARAMETERS
#
#	file_name	The name of the HTML file to parse.
#
# RETURN VALUE
#
#	(As above.)
#
###############################################################################
CODE:
	file_vector const file( file_name );
	RETVAL = file ? new root_node( parse_html_file( file ) ) : 0;
OUTPUT:
	RETVAL

###############################################################################
#
# SYNOPSIS
#
void
root_node::visit(ref1,ref2 = 0)
	SV* ref1
	SV* ref2
#
# DESCRIPTION
#
#	Traverse an HTML::Tree calling a visitor for each node.
#
# PARAMETERS
#
#	With 1 argument, ref1 is a reference to a Perl function to serve as the
#	visitor; with two arguments, ref1 is a reference to a hash and ref2 is
#	a reference to a Perl function to serve as the visitor.
#
###############################################################################
CODE:
	if ( !ref2 && ( !SvROK( ref1 ) || SvTYPE( SvRV( ref1 ) ) != SVt_PVCV ) )
		croak( "Usage: HTML::Tree::visit(func_ref)" );

	if ( ref2 && (
		!SvROK( ref1 ) || SvTYPE( SvRV( ref1 ) ) != SVt_PVHV ||
		!SvROK( ref2 ) || SvTYPE( SvRV( ref2 ) ) != SVt_PVCV
	) )
		croak( "Usage: HTML::Tree::visit(hash_ref,func_ref)" );

	if ( ref2 ) {
		perl_visitor const v( ref2, ref1 );
		THIS->root_->visit( v );
	} else {
		perl_visitor const v( ref1 );
		THIS->root_->visit( v );
	}


###############################################################################
#
MODULE = HTML::Tree		PACKAGE = HTML_Node
#
#	This is an "internal" package not seen by the user.  It's needed to
#	separate its DESTROY() method from the one in root_node.  See the
#	comment in root_node.h for more information.
#
###############################################################################


###############################################################################
#
# SYNOPSIS
#
char const*
HTML_Node::att(key,new_value = 0)
	char const* key
	SV* new_value
#
# DESCRIPTION
#
#	Gets or sets the value of an attribute of an element node.  If the new
#	value is undef, the attribute is deleted.
#
# RETURN VALUE
#
#	Returns the value of an attribute of an element node (after setting
#	it).
#
###############################################################################
CODE:
	if ( Element_Node *const e = dynamic_cast< Element_Node* >( THIS ) )
		if ( new_value )
			if ( !SvOK( new_value ) ) {
				e->attributes.erase( key );
				RETVAL = 0;
			} else
				RETVAL = (
					e->attributes[ key ] =
						SvPV( new_value, PL_na )
				).c_str();
		else {
			Element_Node::attribute_map::iterator const
				i = e->attributes.find( key );
			RETVAL = i != e->attributes.end() ?
				i->second.c_str() : 0;
		}
	else
		croak( "HTML::Tree::att(): object isn't an Element_Node" );
OUTPUT:
	RETVAL

###############################################################################
#
# SYNOPSIS
#
SV*
HTML_Node::atts()
#
# DESCRIPTION
#
#	Returns a reference to a tied hash of all of an element node's
#	attribute key/value pairs.
#
# RETURN VALUE
#
#	(As above.)
#
###############################################################################
CODE:
	if ( Element_Node *const e = dynamic_cast< Element_Node* >( THIS ) ) {
		//
		// Create a new Perl hash, a new atts4perl wrapper wrapped
		// around the current element node's attributes, and tie the
		// Perl hash to a blessed reference to the wrapper.
		//
		HV *const hash = newHV();
		atts4perl *const atts = new atts4perl( e->attributes );
		hv_magic( hash, (GV*)blessed( "atts4perl", atts ), 'P' );
		RETVAL = newRV_noinc( (SV*)hash );
	} else
		croak( "HTML::Tree::atts(): object isn't an Element_Node" );
OUTPUT:
	RETVAL

###############################################################################
#
# SYNOPSIS
#
void
HTML_Node::children()
#
# DESCRIPTION
#
#	Returns a list of all of a Content_Node's child nodes or an empty
#	list if a Content_Node has no children (or the node is an Element_Node).
#
# RETURN VALUE
#
#	(As above.)
#
###############################################################################
PPCODE:
	if ( Content_Node *const c = dynamic_cast< Content_Node* >( THIS ) ) {
		EXTEND( sp, c->children().size() );
		for ( Content_Node::child_list::iterator
			child  = c->children().begin();
			child != c->children().end(); ++child
		)
			PUSHs( blessed( "HTML_Node", *child ) );
	} else if ( !dynamic_cast< Element_Node* >( THIS ) )
		croak( "HTML::Tree::children(): object isn't a Content_Node" );

###############################################################################
#
# SYNOPSIS
#
#void
#HTML_Node::DESTROY()
#
# DESCRIPTION
#
#	We intentionally do not have an HTML_Node::DESTROY() method because
#	nodes must only be destroyed when the entire tree is starting from the
#	root node.
#
###############################################################################


###############################################################################
#
# SYNOPSIS
#
int
HTML_Node::is_text()
#
# DESCRIPTION
#
#	Determines if the current node is-a Text_Node.
#
# RETURN VALUE
#
#	Returns true (1) only if the HTML node is-a Text_Node; false (0)
#	otherwise.
#
###############################################################################
CODE:
	RETVAL = !!dynamic_cast< Text_Node* >( THIS );
OUTPUT:
	RETVAL

###############################################################################
#
# SYNOPSIS
#
char const*
HTML_Node::name()
#
# DESCRIPTION
#
#	Returns the HTML element name of the current node.
#
# RETURN VALUE
#
#	(As above.)
#
###############################################################################
CODE:
	if ( Element_Node *const e = dynamic_cast< Element_Node* >( THIS ) )
		RETVAL = e->name();
	else
		croak( "HTML::Tree::name(): object isn't an Element_Node" );
OUTPUT:
	RETVAL

###############################################################################
#
# SYNOPSIS
#
char const*
HTML_Node::text(new_text = 0)
	char const* new_text
#
# DESCRIPTION
#
#	Gets or sets the text of a text node.
#
# RETURN VALUE
#
#	Returns the text of a text node (after setting it).
#
###############################################################################
CODE:
	if ( Text_Node *const t = dynamic_cast< Text_Node* >( THIS ) ) {
		if ( new_text )
			t->text = new_text;
		RETVAL = t->text.c_str();
	} else
		croak( "HTML::Tree::text(): object isn't a Text_Node" );
OUTPUT:
	RETVAL

###############################################################################
#
MODULE = HTML::Tree		PACKAGE = atts4perl
#
#	This module implements the package for the tied hash for element node
#	attributes.  The package is private in that the user never sees it.
#	The code is fairly straight-forward.
#
###############################################################################

void
atts4perl::CLEAR()
CODE:
	THIS->hash_.clear();

void
atts4perl::DELETE(key)
	char const* key
CODE:
	THIS->hash_.erase( key );

void
atts4perl::DESTROY()

int
atts4perl::EXISTS(key)
	char const* key
CODE:
	RETVAL = THIS->hash_.find( key ) != THIS->hash_.end();
OUTPUT:
	RETVAL

char const*
atts4perl::FETCH(key)
	char const* key
CODE:
	atts4perl::const_iterator const i = THIS->hash_.find( key );
	RETVAL = i != THIS->hash_.end() ? i->second.c_str() : 0;
OUTPUT:
	RETVAL

char const*
atts4perl::FIRSTKEY()
CODE:
	RETVAL = THIS->hash_.empty() ? 0 :
		( THIS->iter_ = THIS->hash_.begin() )->first.c_str();
OUTPUT:
	RETVAL

char const*
atts4perl::NEXTKEY(key)
	char const* key
CODE:
	RETVAL = ++THIS->iter_ != THIS->hash_.end() ?
		THIS->iter_->first.c_str() : 0;
OUTPUT:
	RETVAL

void
atts4perl::STORE(key,value)
	char const* key
	char const* value
CODE:
	THIS->hash_[ key ] = value;
