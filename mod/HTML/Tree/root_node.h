/*
**	HTML::Tree
**	root_node.h
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

#ifndef	root_node_H
#define	root_node_H

// local
#include "HTML_Node.h"

//*****************************************************************************
//
// SYNOPSIS
//
	struct root_node
//
// DESCRIPTION
//
//	A root_node is a simple wrapper around an HTML_Node pointing to the
//	root of an HTML tree.  The only reason this is necessary is to make the
//	behavior for the Perl DESTROY() method different between the root node
//	and non-root nodes.
//
//	When a blessed reference to a non-root node gets destroyed (typically
//	by going out of scope in a Perl script), the underlying non-root node
//	must NOT be destroyed also because it's still part of the tree; only
//	when the blessed reference to the root node gets destroyed can the tree
//	as a whole be destroyed.
//
//	Hence, this class (and a different Perl package) exists so its
//	DESTROY() method can be different.
//
//*****************************************************************************
{
	explicit root_node( HTML_Node *root ) : root_( root ) { }
	~root_node() { delete root_; }

	HTML_Node *const root_;
};

#endif	/* root_node_H */
