##
#	HTML Tree
#	GNUmakefile
#
#	Copyright (C) 2000  Paul J. Lucas
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

########## You shouldn't have to change anything below this line. #############

ROOT=		.
include		$(ROOT)/config/config.mk

LIB_NAME=	htmltree
TARGET=		lib$(LIB_NAME).a prettyhtml
CFLAGS=		$(CCFLAGS)

LIB_SRCS=	HTML_Node.c \
		elements.c \
		Element_Node.c \
		Parent_Node.c \
		Content_Node.c \
		file_vector.c \
		html.c \
		Text_Node.c \
		util.c
LIB_OBJS=	$(LIB_SRCS:.c=.o)

TEST_SRCS=	prettyhtml.c
TEST_OBJS=	$(TEST_SRCS:.c=.o)

##
# Build rules
##

all: $(TARGET)

lib$(LIB_NAME).a: $(LIB_OBJS)
	$(RM) $@
	$(AR) rv $@ $(LIB_OBJS)

prettyhtml: lib$(LIB_NAME).a $(TEST_OBJS)
	$(CC) $(CFLAGS) $(LPATHS) -L. -o $@ $(TEST_OBJS) -l$(LIB_NAME)

test: prettyhtml
	./prettyhtml test.html

platform.h:
	@$(MAKE) -C config

.%.d : %.c platform.h
	$(SHELL) -ec '$(CC) -MM $(CPPFLAGS) $< | sed "s/\([^:]*\):/\1 $@ : /g" > $@; [ -s $@ ] || $(RM) $@'

ifneq ($(findstring clean,$(MAKECMDGOALS)),clean)
ifneq ($(MAKECMDGOALS),dist)
include  $(LIB_SRCS:%.c=.%.d) $(TEST_SRCS:%.c=.%.d)
endif
endif

ps pdf txt:
	@$(MAKE) -C man $@

##
# Install rules
##

install: install_lib install_man

install_lib: $(TARGET) $(I_LIB)
	$(INSTALL) $(I_OWNER) $(I_GROUP) $(I_MODE) $(TARGET) $(I_LIB)

install_man:
	@$(MAKE) -C man install

$(I_LIB):
	$(MKDIR) $@

uninstall:
	cd $(I_LIB) && $(RM) $(TARGET)
	@$(MAKE) -C man $@

##
# Utility rules
##

clean:
	$(RM) *.o *.d core
	@$(MAKE) -C man $@
	-$(MAKE) -C mod/Apache $@
	-$(MAKE) -C mod/HTML $@
	find mod -name Makefile.old -exec $(RM) {} \;

dist distclean: clean
	$(RM) $(TARGET) platform.h
	@$(MAKE) -C man $@
