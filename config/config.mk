##
#	HTML Tree
#	config/config.mk
#
#	Copyright (C) 1998  Paul J. Lucas
#
#	This program is free software; you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation; either version 2 of the License, or
#	(at your option) any later version.
# 
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
# 
#	You should have received a copy of the GNU General Public License
#	along with this program; if not, write to the Free Software
#	Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
##

##
#	Note: If you later redefine any of these variables, you *MUST* first
#	do a "make distclean" before you do another "make".
##

###############################################################################
#
#	General stuff
#
###############################################################################

MAKE=		make
#		The 'make' software you are using; usually "make".

RM=		rm -fr
#		The command to remove files recursively and ignore errors;
#		usually "rm -fr".

SHELL=		/bin/sh
#		The shell to spawn for subshells; usually "/bin/sh".

STRIP=		strip
#		The command to strip symbolic information from executables;
#		usually "strip".  You can leave this defined even if your OS
#		doesn't have it or any equivalent since any errors from this
#		command are ignored in the Makefiles.

###############################################################################
#
#	C++ compiler
#
###############################################################################

CC=		g++
#		The C++ compiler you are using; usually "CC" or "g++".

#GCC_WARNINGS=	-W -Wcast-align -Wcast-qual -Winline -Wpointer-arith -Wshadow -Wswitch -Wtraditional -Wuninitialized -Wunused
#		Warning flags specific to gcc/g++.  Unless you are modifying
#		the source code, you should leave this commented out.

CCFLAGS=	$(GCC_WARNINGS) -O3
#		Additional flags for the C++ compiler:
#
#		-g	Include symbol-table information in object file.  (You
#			normally wouldn't want to do this unless you are
#			either helping me to debug a problem found on your
#			system or you are changing SWISH++ yourself.)
#
#		-O	Turn optimization on.  Some compilers allow a digit
#			after the O for optimization level; if so, set yours
#			to the highest number your compiler allows (without
#			eliciting bugs in its optimizer).  If SWISH++ doesn't
#			work correctly with optimization on, but it works just
#			fine with it off, then there is a bug in your
#			compiler's optimizer.
#
#		-pg	Turn profiling on.  (You normally wouldn't want to do
#			this unless you are changing SWISH++ and want to try
#			to performance-tune your changes.)  This option may be
#			g++-specific.  If you are not using g++, consult your
#			C++ compiler's documentation.

###############################################################################
#
#	Installation
#
###############################################################################

INSTALL=	$(ROOT)/install-sh
#		Install command; usually "$(ROOT)/install-sh".

I_ROOT=		/usr/local
#		The top-level directory of where HTML Tree will be installed.

I_LIB=		$(I_ROOT)/lib
#		Where libraries are installed; "$(I_ROOT)/lib".

I_MAN=		$(I_ROOT)/man
#		Where manual pages are installed; "$(I_ROOT)/man".

I_OWNER=	-o bin
#		The owner of the installed files.

I_GROUP=	-g bin
#		The group of the installed files.

I_MODE=		-m 644
#		File permissions for regular files (non executables).

MKDIR=		$(INSTALL) $(I_OWNER) $(I_GROUP) $(I_XMODE) -d
#		Command used to create a directory.

##
# The end.
##
