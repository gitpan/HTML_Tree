/*
**	HTML Tree
**	Parent_Node.c
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
#include "Parent_Node.h"

//*****************************************************************************
//
// SYNOPSIS
//
	/* virtual */ Parent_Node::~Parent_Node()
//
// DESCRIPTION
//
//	Destroy a Parent_Node and destroy all of our child nodes recursively.
//	Set our destructing_ flag so our children don't bother removing
//	themselves from our list of children since we're destroying ourselves
//	anyway.
//
//*****************************************************************************
{
	destructing_ = true;
	for ( child_list::iterator
		child = children_.begin(); child != children_.end(); ++child
	)
		delete *child;
}

//*****************************************************************************
//
// SYNOPSIS
//
	void Parent_Node::add_child( HTML_Node *new_child )
//
// DESCRIPTION
//
//	Add a given child node to our list of children taking care to remove it
//	from its current parent's list of children, if any.
//
// PARAMETERS
//
//	new_child	A pointer to the child node to be added.
//
//*****************************************************************************
{
	if ( new_child && new_child->parent_ != this ) {
		if ( new_child->parent_ )
			new_child->parent_->remove_child( new_child );
		new_child->parent_ = this;
		children_.push_back( new_child );
	}
}

//*****************************************************************************
//
// SYNOPSIS
//
	bool Parent_Node::remove_child( HTML_Node *orphan )
//
// DESCRIPTION
//
//	Remove a given child node from our list of children.
//
// PARAMETERS
//
//	orphan	A pointer to the child node to be removed.
//
// RETURN VALUE
//
//	Returns true only if the child was removed.
//
//*****************************************************************************
{
	if ( orphan )
		for ( child_list::iterator
			child  = children_.begin();
			child != children_.end(); ++child
		)
			if ( *child == orphan ) {
				children_.erase( child );
				orphan->parent_ = 0;
				return true;
			}
	return false;
}

//*****************************************************************************
//
// SYNOPSIS
//
	/* virtual */ void Parent_Node::visit( visitor const &v, int depth )
//
// DESCRIPTION
//
//	Have the visitor visit all of our children.  We intentionally do NOT
//	pass "depth + 1" because Parent_Nodes are supposed to be "invisible" in
//	the tree.
//	
// PARAMETERS
//
//	v	A reference to a visitor.
//
//*****************************************************************************
{
	for ( child_list::const_iterator
		child = children_.begin(); child != children_.end(); ++child
	)
		(*child)->visit( v, depth );
}
