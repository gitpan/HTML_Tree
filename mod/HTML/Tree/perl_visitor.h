/*
**	HTML::Tree
**	perl_visitor.h
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

#ifndef	perl_visitor_H
#define	perl_visitor_H

// Perl
extern "C" {
#include <EXTERN.h>
#include <perl.h>
}

// local
#include "HTML_Node.h"

//*****************************************************************************
//
// SYNOPSIS
//
	class perl_visitor : public HTML_Node::visitor
//
// DESCRIPTION
//
//	A perl_visitor is-an HTML_Node::visitor that squirrels away a copy of
//	reference to the Perl function that is the real visitor passed to
//	visit().  The HTML Tree library, written in C++, can only use a C++ (or
//	C) function as a callback: this class, via an overridden operator(),
//	calls the Perl function.
//
//*****************************************************************************
{
public:
	perl_visitor( SV* func_ref, SV* hash_ref = 0 );
	virtual ~perl_visitor();

	virtual bool operator()( HTML_Node*, int depth, bool is_end_tag ) const;
private:
	SV* const func_ref_;
	SV* const hash_ref_;
};

#endif	/* perl_visitor_H */
