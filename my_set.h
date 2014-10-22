/*
**	HTML Tree
**	my_set.h
**
**	Copyright (C) 1998  Paul J. Lucas
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

#ifndef my_set_H
#define my_set_H

// standard
#include <set>

// local
#include "fake_ansi.h"			/* for std */
#include "less.h"

//*****************************************************************************
//
// SYNOPSIS
//
	template< class T > class my_set : public std::set< T >
//
// DESCRIPTION
//
//	A my_set is-a set but with the addition of a contains() member
//	function, one that returns a simpler bool result indicating whether a
//	given element is in the set.  (This is called a lot and I hate lots of
//	typing.)
//
//*****************************************************************************
{
public:
	bool contains( key_type s ) const { return find( s ) != end(); }
};

typedef my_set< char const* >	char_ptr_set;

#endif	/* my_set_H */
