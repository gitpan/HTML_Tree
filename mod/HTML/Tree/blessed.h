/*
**	HTML::Tree
**	blessed.h
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

#ifndef	blessed_H
#define	blessed_H

// Perl
extern "C" {
#include <EXTERN.h>
#include <perl.h>
}

//*****************************************************************************
//
// SYNOPSIS
//
	inline SV* blessed( char const *package_name, void *obj )
//
// DESCRIPTION
//
//	Converts a C++ object pointer into a blessed reference in order to be
//	able to call object methods on it.  This does the same thing as the
//	OUTPUT typemap except for things other than function arguments (which
//	is why the typemap doesn't help).
//
// PARAMETERS
//
//	package_name	The name of the package to bless the object into.
//
//	obj		A pointer to a C++ object.
//
// RETURN VALUE
//
//	Returns said blessed reference.
//
// SEE ALSO
//
//	Sriram Srinivasan. "Advanced Perl Programming," O'Reilly and
//	Associates, Inc., Sebastopol, CA, 1997, p. 335.
//
//*****************************************************************************
{
	return sv_setref_pv(
		//
		// The Perl API has, IMHO, a mistake in that sv_setref_pv()
		// takes a "char*" for the second argument rather than a
		// "char const*"; hence the cast below.
		//
		sv_newmortal(), const_cast< char* >( package_name ), obj
	);
}

#endif	/* blessed_H */
