/*
**	HTML Tree
**	Content_Node.h
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

#ifndef Content_Node_H
#define Content_Node_H

// standard
#include <list>

// local
#include "Element_Node.h"
#include "Parent_Node.h"

//*****************************************************************************
//
// SYNOPSIS
//
	class Content_Node : public Element_Node, public Parent_Node
//
// DESCRIPTION
//
//	A Content_Node is-an Element_Node and also is-a Parent_Node, i.e., a
//	node that has a name, possibly attributes, and possibly child nodes,
//	i.e., has content.
//
//*****************************************************************************
{
public:
	Content_Node( char const *name, element const&, Parent_Node* = 0 );
	Content_Node(
		char const *name, element const&,
		char const *att_begin, char const *att_end,
		Parent_Node* = 0
	);
	virtual ~Content_Node();

	virtual void	visit( visitor const&, int depth = 0 );
};

#endif	/* Content_Node_H */
