/*
**	HTML Tree
**	util.h
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

#ifndef	util_H
#define	util_H

// standard
#include <cctype>
#include <string>
#include <sys/stat.h>

//
// POSIX.1 is, IMHO, brain-damaged in the way it makes you determine the
// maximum file-name length, so we'll simply pick a sufficiently large
// constant.  See also: W. Richard Stevens.  "Advanced Programming in the Unix
// Environment," Addison-Wesley, Reading, MA, 1993.  pp. 34-42.
//
#ifdef	NAME_MAX
#undef	NAME_MAX
#endif
int const	NAME_MAX = 255;

//*****************************************************************************
//
//	File test functions.  Those that do not take an argument operate on the
//	last file stat'ed.
//
//*****************************************************************************

extern struct stat	stat_buf;		// somplace to do a stat(2) in

inline bool	file_exists( char const *path ) {
			return ::stat( path, &stat_buf ) != -1;
		}
inline bool	file_exists( std::string const &path ) {
			return file_exists( path.c_str() );
		}

inline bool	is_plain_file() {
			return S_ISREG( stat_buf.st_mode );
		}
inline bool	is_plain_file( char const *path ) {
			return	file_exists( path ) && is_plain_file();
		}
inline bool	is_plain_file( std::string const &path ) {
			return is_plain_file( path.c_str() );
		}

//*****************************************************************************
//
//	Miscelleneous.
//
//*****************************************************************************

#define ERROR		cerr << me << ": error: "

			// ensure function semantics: 'c' is expanded once
inline bool		is_space( char c )	{ return isspace( c ); }
inline char		to_lower( char c )	{ return tolower( c ); }
extern char*		to_lower( char const *begin, char const *end );

#endif	/* util_H */
