/*
**	HTML::Tree
**	hash4perl.h
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

#ifndef	hash4perl_H
#define	hash4perl_H

// local
#include "Element_Node.h"

//*****************************************************************************
//
// SYNOPSIS
//
	template< class Container > struct hash4perl
//
// DESCRIPTION
//
//	A hash4perl is a wrapper around an STL container class to be used to
//	implement a tied hash in Perl.  It bundles in a single iterator since
//	each hash in Perl has exactly one iterator for it.
//
// NOTE
//
//	FYI, since this wrapper merely contains a reference to the container,
//	there in fact can be more than one iterator for it; however, this fact
//	is of little use to Perl.
//
// SEE ALSO
//
//	Larry Wall, et al.  "Programming Perl," 2nd ed., O'Reilly and
//	Associates, Inc., Sebastopol, CA, 1996, pp. 159-160.
//
//*****************************************************************************
{
	typedef Container container_type;
	typedef typename container_type::const_iterator const_iterator;

	hash4perl( container_type &c ) : hash_( c ) { }

	container_type	&hash_;
	const_iterator	iter_;
};

//
// In the case of HTML::Tree, we want to wrap an Element_Node's attributes to
// make them accessible via a tied hash.
//
typedef	hash4perl< Element_Node::attribute_map > atts4perl;

#endif	/* hash4perl_H */
