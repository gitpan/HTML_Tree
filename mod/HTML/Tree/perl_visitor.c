/*
**	HTML::Tree
**	perl_visitor.c
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
#include "blessed.h"
#include "perl_visitor.h"

//*****************************************************************************
//
// SYNOPSIS
//
	perl_visitor::perl_visitor( SV* func_ref, SV* hash_ref )
//
// DESCRIPTION
//
//	Construct (initialize) a perl_visitor.
//
// PARAMETERS
//
//	func_ref	A reference to ther Perl function that is the real
//			visitor function.
//
//	hash_ref	A reference to a hash that the visitor may optionally
//			use for its own purposes.
//
//*****************************************************************************
	: func_ref_( newSVsv( func_ref ) ),
	  hash_ref_( hash_ref ? newSVsv( hash_ref ) : 0 )
{
	// do nothing else
}

//*****************************************************************************
//
// SYNOPSIS
//
	/* virtual */ perl_visitor::~perl_visitor()
//
// DESCRIPTION
//
//	Destroy a perl_visitor.
//
//*****************************************************************************
{
	SvREFCNT_dec( func_ref_ );
	if ( hash_ref_ )
		SvREFCNT_dec( hash_ref_ );
}

//*****************************************************************************
//
// SYNOPSIS
//
	bool perl_visitor::operator()(
		HTML_Node *node, int depth, bool is_end_tag
	) const
//
// DESCRIPTION
//
//	This function serves as the "glue code" between the called visitor
//	function in C++ and the real visitor function in Perl.
//
// PARAMETERS
//
//	node		The HTML node we're currently visiting.
//
//	depth		How far down into the HTML tree we are (depth starts at
//			zero).
//
//	is_end_tag	This is set to true only after visiting all of an HTML
//			node's child nodes, if any.
//
// RETURN VALUE
//
//	Returns the value of the Perl function.
//
// SEE ALSO
//
//	Sriram Srinivasan. "Advanced Perl Programming," O'Reilly and
//	Associates, Inc., Sebastopol, CA, 1997, pp. 352-353.
//
//*****************************************************************************
{
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK( sp );
	if ( hash_ref_ )
		XPUSHs( sv_mortalcopy( hash_ref_ ) );
	XPUSHs( blessed( "HTML_Node", node ) );
	XPUSHs( sv_2mortal( newSViv( depth ) ) );
	XPUSHs( sv_2mortal( newSViv( is_end_tag ) ) );
	PUTBACK;
	int const result_count = perl_call_sv( func_ref_, G_SCALAR );
	SPAGAIN;
	if ( result_count != 1 )
		croak(	"HTML::Tree: "
			"visitor function didn't return a single scalar value "
			"(it returned %d)", result_count
		);
	bool const result = POPi;
	PUTBACK;
	FREETMPS;
	LEAVE;
	return result;
}
