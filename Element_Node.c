/*
**	HTML Tree
**	Element_Node.c
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

// local
#include "Element_Node.h"
#include "html.h"
#include "util.h"

#ifndef	PJL_NO_NAMESPACES
using namespace std;
#endif

//*****************************************************************************
//
// SYNOPSIS
//
	Element_Node::Element_Node(
		char const *name, element const &e, Parent_Node *parent
	)
//
// DESCRIPTION
//
//	Construct (initialize) an Element_Node.
//
//*****************************************************************************
	: HTML_Node( parent ), name_( name ), element_( e )
{
	// do nothing else
}

//*****************************************************************************
//
// SYNOPSIS
//
	Element_Node::Element_Node(
		char const *name, element const &e,
		char const *att_begin, char const *att_end,
		Parent_Node *parent
	)
//
// DESCRIPTION
//
//	Construct (initialize) an Element_Node.
//
//*****************************************************************************
	: HTML_Node( parent ), name_( name ), element_( e )
{
	parse_attributes( att_begin, att_end, attributes );
}

//*****************************************************************************
//
// SYNOPSIS
//
	/* virtual */ Element_Node::~Element_Node()
//
// DESCRIPTION
//
//	Destroy an Element_Node.  This is declared out-of-line because (a) it's
//	virtual and (b) the destructor is non-trivial because of implicit data
//	member destructors.
//
//*****************************************************************************
{
	// do nothing explicitly
}
