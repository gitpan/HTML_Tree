/*
**	HTML Tree
**	util.c
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
#include "fake_ansi.h"
#include "util.h"

#ifndef	PJL_NO_NAMESPACES
using namespace std;
#endif

struct stat	stat_buf;			// someplace to do a stat(2) in

//*****************************************************************************
//
// SYNOPSIS
//
	template< int Size, int N > class char_buffer_pool
//
// DESCRIPTION
//
//	A char_buffer_pool maintains a small set ("pool") of size N of
//	available character buffers, each of size Size, and issues them in a
//	round-robin manner.
//
//	This is used by functions to return a character string without having
//	to allocate memory dynamically nor have previously returned strings
//	overwritten.
//
//*****************************************************************************
{
public:
	char_buffer_pool() : next_buf_index_( 0 ), cur_buf_( buf_[ 0 ] ) { }

	char*	current() const { return cur_buf_; }
	char*	next() {
			cur_buf_ = buf_[ next_buf_index_ ];
			next_buf_index_ = (next_buf_index_ + 1) % N;
			return cur_buf_;
		}
private:
	char	buf_[ N ][ Size ];
	int	next_buf_index_;
	char	*cur_buf_;
};

//*****************************************************************************
//
// SYNOPSIS
//
	char *to_lower(
		register char const *begin, register char const *end
	)
//
// DESCRIPTION
//
//	Return a pointer to a string converted to lower case; the original
//	string is untouched.  The string returned is from an internal pool of
//	string buffers.  The time you get into trouble is if you hang on to
//	more then Num_Buffers strings.  This doesn't normally happen in
//	practice, however.
//
// PARAMETERS
//
//	begin	The iterator positioned at the first character of the string.
//
//	end	The iterator postitioned one past the last character of the
//		string.
//
// RETURN VALUE
//
//	A pointer to the lower-case string.
//
//*****************************************************************************
{
	static char_buffer_pool<128,5> buf;
	register char *p = buf.next();

	while ( begin != end )
		*p++ = to_lower( *begin++ );
	*p = '\0';

	return buf.current();
}
