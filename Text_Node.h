/*
**	HTML Tree
**	Text_Node.h
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

#ifndef Text_Node_H
#define Text_Node_H

// standard
#include <string>

// local
#include "HTML_Node.h"

class Parent_Node;

//*****************************************************************************
//
// SYNOPSIS
//
	class Text_Node : public virtual HTML_Node
//
// DESCRIPTION
//
//	A Text_Node is-an HTML_Node that simply contains plain text.
//
//*****************************************************************************
{
public:
	Text_Node( char const *begin, char const *end, Parent_Node* = 0 );

	std::string text;
};

#endif	/* Text_Node_H */
