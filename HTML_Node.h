/*
**	HTML Tree
**	HTML_Node.h
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

#ifndef HTML_Node_H
#define HTML_Node_H

class Parent_Node;

//*****************************************************************************
//
// SYNOPSIS
//
	class HTML_Node
//
// DESCRIPTION
//
//	An HTML_Node is an abstract base class for all nodes in a tree.
//
//*****************************************************************************
{
public:
	class visitor {
		//
		// A visitor is an abstract base class for objects that "visit"
		// nodes in the tree during a traversal.
		//
	public:
		virtual ~visitor() { }
		virtual bool operator()(
			HTML_Node*, int depth, bool is_end_tag
		) const = 0;
	};

	virtual ~HTML_Node();

	Parent_Node*	parent() const { return parent_; }
	void		parent( Parent_Node *new_parent );
	virtual void	visit( visitor const&, int depth = 0 );
protected:
	HTML_Node( Parent_Node* = 0 );
private:
	Parent_Node	*parent_;

	friend class	Parent_Node;
};

#endif	/* HTML_Node_H */
