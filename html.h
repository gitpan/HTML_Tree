/*
**	HTML Tree
**	html.h
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

#ifndef	html_H
#define	html_H

// local
#include "Element_Node.h"
#include "file_vector.h"
#include "Parent_Node.h"

void		parse_attributes(
			char const *pos, char const *end,
			Element_Node::attribute_map&
		);
Parent_Node*	parse_html_file( file_vector const& );

#endif	/* html_H */
