/*
**	HTML Tree
**	Content_Node.c
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
#include "Content_Node.h"

//*****************************************************************************
//
// SYNOPSIS
//
	Content_Node::Content_Node(
		char const *name, element const &e, Parent_Node *parent
	)
//
// DESCRIPTION
//
//	Construct (initialize) a Content_Node.
//
//*****************************************************************************
	: Element_Node( name, e ), HTML_Node( parent )
{
	// do nothing else
}

//*****************************************************************************
//
// SYNOPSIS
//
	Content_Node::Content_Node(
		char const *name, element const &e,
		char const *att_begin, char const *att_end,
		Parent_Node *parent
	)
//
// DESCRIPTION
//
//	Construct (initialize) a Content_Node.
//
//*****************************************************************************
	: Element_Node( name, e, att_begin, att_end ), HTML_Node( parent )
{
	// do nothing else
}

//*****************************************************************************
//
// SYNOPSIS
//
	/* virtual */ Content_Node::~Content_Node()
//
// DESCRIPTION
//
//	Destroy a Content_Node.
//
//*****************************************************************************
{
	// no nothing explicitly
}

//*****************************************************************************
//
// SYNOPSIS
//
	/* virtual */ void Content_Node::visit( visitor const &v, int depth )
//
// DESCRIPTION
//
//	Have the visitor visit us, all of our children, and us again.  If the
//	visitor returns false the first time, don't visit our children and
//	don't have the visitor visit us a second time; if the visitor returns
//	true the second time, repeat the entire visit cycle.
//	
// PARAMETERS
//
//	v	A reference to a visitor.
//
//*****************************************************************************
{
	do {
		if ( !v( this, depth, false ) )
			break;
		Parent_Node::visit( v, depth + 1 );
	} while ( v( this, depth, true ) );
}
