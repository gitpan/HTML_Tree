/*
**	HTML Tree
**	Element_Node.h
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

#ifndef Element_Node_H
#define Element_Node_H

// standard
#include <map>
#include <string>

// local
#include "elements.h"
#include "HTML_Node.h"

//*****************************************************************************
//
// SYNOPSIS
//
	class Element_Node : public virtual HTML_Node
//
// DESCRIPTION
//
//	An Element_Node is-an HTML_Node for HTML elements that possibly have
//	attributes.
//
//*****************************************************************************
{
public:
	typedef std::map< std::string, std::string > attribute_map;

	Element_Node( char const *name, element const&, Parent_Node* = 0 );
	Element_Node(
		char const *name, element const&,
		char const *att_begin, char const *att_end,
		Parent_Node* = 0
	);
	virtual ~Element_Node();

	attribute_map	attributes;

	char const*	name() const { return name_; }
private:
	// It's OK for name_ to be just a pointer rather than a string since it
	// points to the key in the element_map.
	//
	char const	*const name_;
	element const	&element_;

	friend void	parse_html_tag( char const*&, char const* );
};

#endif	/* Element_Node_H */
