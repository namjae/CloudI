#-*-Mode:make;coding:utf-8;tab-width:4;c-basic-offset:4-*-
# ex: set ft=make fenc=utf-8 sts=4 ts=4 sw=4 noet nomod:

instdir = "$(cloudi_prefix)/tests/null/priv"
inst_PROGRAMS = null
null_SOURCES = main.c
null_CFLAGS = -fexceptions -I$(top_srcdir)/api/c/
null_LDADD = $(top_builddir)/api/c/libcloudi.la -lstdc++

