/*
**	HTML Tree
**	HTML_Node.c
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

// local
#include "HTML_Node.h"
#include "Parent_Node.h"

#ifndef	PJL_NO_NAMESPACES
using namespace std;
#endif

//*****************************************************************************
//
// SYNOPSIS
//
	HTML_Node::HTML_Node( Parent_Node *parent )
//
// DESCRIPTION
//
//	Construct (initialize) an HTML_Node by adding ourselves to our parent's
//	list of children.
//
//*****************************************************************************
	//
	// We do NOT set our parent here; rather, we let our parent set it.
	//
	: parent_( 0 )
{
	if ( parent )
		parent->add_child( this );
}

//*****************************************************************************
//
// SYNOPSIS
//
	/* virtual */ HTML_Node::~HTML_Node()
//
// DESCRIPTION
//
//	Destroy an HTML_Node.  If we have a parent node and it isn't already in
//	the process of destroying itself (its destructor isn't executing),
//	remove ourselves from our parent's list of children.
//
//*****************************************************************************
{
	if ( parent_ && !parent_->destructing_ )
		parent_->remove_child( this );
}

//*****************************************************************************
//
// SYNOPSIS
//
	void HTML_Node::parent( Parent_Node *new_parent )
//
// DESCRIPTION
//
//	Set the current node's parent to a new parent removing it from the old
//	parent, if any.
//
// PARAMETERS
//
//	new_parent	A pointer to a new parent.
//	
//*****************************************************************************
{
	if ( new_parent != parent_ ) {
		if ( parent_ )
			parent_->remove_child( this );
		if ( new_parent )
			new_parent->add_child( this );
	}
}

//*****************************************************************************
//
// SYNOPSIS
//
	/* virtual */ void HTML_Node::visit( visitor const &v, int depth )
//
// DESCRIPTION
//
//	Call the visitor function passing ourselves as the node to visit.
//
// PARAMETERS
//
//	v	A reference to a visitor.
//	
//*****************************************************************************
{
	v( this, depth, false );
}
