/*
**	HTML Tree
**	Parent_Node.h
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

#ifndef Parent_Node_H
#define Parent_Node_H

// standard
#include <list>

// local
#include "HTML_Node.h"

//*****************************************************************************
//
// SYNOPSIS
//
	class Parent_Node : public virtual HTML_Node
//
// DESCRIPTION
//
//	A Parent_Node is-an HTML_Node for all nodes that have child nodes.
//
//*****************************************************************************
{
public:
	typedef std::list< HTML_Node* > child_list;

	Parent_Node( Parent_Node *parent = 0 ) : HTML_Node( parent ) { }
	virtual ~Parent_Node();

	void		add_child( HTML_Node* );
	child_list&	children()		{ return children_; }
	child_list const& children() const	{ return children_; }
	bool		empty() const		{ return children_.empty(); }
	bool		remove_child( HTML_Node* );
	virtual void	visit( visitor const&, int depth = 0 );
private:
	child_list	children_;
	bool		destructing_;

	//
	// This "friend" declaration is necessary because HTML_Node's
	// destructor needs to test the destructing_ flag.
	//
	friend		HTML_Node::~HTML_Node();
};

#endif	/* Parent_Node_H */
