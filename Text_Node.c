/*
**	HTML Tree
**	Text_Node.c
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
#include "Text_Node.h"

#ifndef	PJL_NO_NAMESPACES
using namespace std;
#endif

//*****************************************************************************
//
// SYNOPSIS
//
	Text_Node::Text_Node(
		char const *begin, char const *end, Parent_Node *parent
	)
//
// DESCRIPTION
//
//	Construct (initialize) a Text_Node which amounts to little more than
//	simply initializing the text string.
//
//*****************************************************************************
	: HTML_Node( parent ), text( begin, end )
{
	// do nothing else
}
