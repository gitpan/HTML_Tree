/*
**	HTML Tree
**	prettyhtml.c
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

// standard
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <unistd.h>				/* for getopt(3) */

// local
#include "file_vector.h"
#include "HTML_Tree.h"
#include "util.h"
#include "version.h"
#include "fake_ansi.h"

extern "C" {
	extern char*	optarg;
	extern int	optind, opterr;
}

#ifndef	PJL_NO_NAMESPACES
using namespace std;
#endif

char const*	me;				// executable name

void		usage();

class pretty_printer : public HTML_Node::visitor {
public:
	virtual bool operator()( HTML_Node*, int depth, bool is_end_tag ) const;
};

//*****************************************************************************
//
// SYNOPSIS
//
	int main( int argc, char *argv[] )
//
// DESCRIPTION
//
//	Parse the command line, initialize, call other functions ... the usual
//	things that are done in main().
//
// PARAMETERS
//
//	argc	The number of arguments.
//
//	argv	A vector of the arguments; argv[argc] is null.  Aside from the
//		options below, the arguments are the names of the files and
//		directories to be indexed.
//
// SEE ALSO
//
//	Bjarne Stroustrup.  "The C++ Programming Language, 3rd ed."
//	Addison-Wesley, Reading, MA.  pp. 116-118.
//
//*****************************************************************************
{
	me = ::strrchr( argv[0], '/' );		// determine base name...
	me = me ? me + 1 : argv[0];		// ...of executable

	/////////// Process command-line options //////////////////////////////

	::opterr = 1;
	char const opts[] = "v";
	for ( int opt; (opt = ::getopt( argc, argv, opts )) != EOF; )
		switch ( opt ) {

			case 'v': // Display version and exit.
				cout << "prettyhtml " << version << endl;
				::exit( 0 );

			case '?': // Bad option.
				usage();
		}
	argc -= ::optind, argv += ::optind;
	if ( argc > 1 )
		usage();

	/////////// Get file file to parse ////////////////////////////////////

	char const *file_name;
	if ( !argc ) {
		//
		// Read file name from standard input.
		//
		static char file_name_buf[ NAME_MAX + 1 ];
		if ( !cin.getline( file_name_buf, NAME_MAX ) )
			::exit( 2 );
		file_name = file_name_buf;
	} else {
		//
		// Read file name from command line.
		//
		file_name = *argv;
	}

	if ( !file_exists( file_name ) ) {
		ERROR << '"' << file_name << "\" does not exist\n";
		::exit( 2 );
	}
	if ( !is_plain_file() ) {
		ERROR << '"' << file_name << "\" is not a plain file\n";
		::exit( 2 );
	}

	file_vector file( file_name );
	if ( !file ) {
		ERROR << "can not open \"" << file_name << "\"\n";
		::exit( 2 );
	}

	/////////// Parse specified file //////////////////////////////////////

	if ( Parent_Node *const root_node = parse_html_file( file ) ) {
		root_node->visit( pretty_printer() );
		delete root_node;
	}
	::exit( 0 );
}

//*****************************************************************************
//
// SYNOPSIS
//
	bool pretty_printer::operator()(
		HTML_Node *node, int depth, bool is_end_tag
	) const
//
// DESCRIPTION
//
//	Pretty-print an HTML document.
//
// PARAMETERS
//
//	node		The HTML_Node to be visited.
//
//	depth		How many nodes "deep" in the tree we are.
//
//	is_end_tag	True when called at the end of a visit.
//
// RETURN VALUE
//
//	Returns false only if the tree is not to be further descended into from
//	the current node.
//
//*****************************************************************************
{
	while ( depth-- > 0 )
		cout << "    ";

	if ( Text_Node *const t = dynamic_cast< Text_Node* >( node ) ) {
		//
		// Since we are emitting our own newlines in order to pretty-
		// print, we have to strip leading and trailing newlines from
		// the HTML.
		//
		string s = t->text;
		if ( s[0] == '\n' )
			s.erase( s.begin() );
		if ( s[ s.size() - 1 ] == '\n' )
			s.erase( s.end() - 1 );
		cout << s << '\n';
		return true;
	}

	Element_Node *const e = dynamic_cast< Element_Node* >( node );
	if ( is_end_tag ) {
		cout << "</" << e->name() << ">\n";
		return false;
	}

	cout << '<' << e->name();

	for ( Element_Node::attribute_map::const_iterator
		att = e->attributes.begin(); att != e->attributes.end(); ++att
	)
		cout << ' ' << att->first << "=\"" << att->second << '"';
	cout << ">\n";
	return true;
}

//*****************************************************************************
//
//	Miscellaneous function(s)
//
//*****************************************************************************

void usage() {
	cerr <<	"usage: " << me << " [options] [file]\n"
	"options:\n"
	"========\n"
	"-v : Print version number and exit\n";
	::exit( 1 );
}
