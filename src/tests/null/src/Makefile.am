#-*-Mode:make;coding:utf-8;tab-width:4;c-basic-offset:4-*-
# ex: set ft=make fenc=utf-8 sts=4 ts=4 sw=4 noet nomod:

instdir = "$(cloudi_prefix)/tests/null/ebin"
directinstdir = "$(DESTDIR)$(instdir)"
beamdir = "$(instdir)"
buildbeamdir = ../ebin
beam_DATA = cloudi_service_null.beam
CLEANFILES = $(beam_DATA) \
             $(buildbeamdir)/cloudi_service_null.beam

all-local: $(beam_DATA)
	$(MKDIR_P) $(buildbeamdir) || exit 0
	cp -f $(beam_DATA) $(buildbeamdir)

.erl.beam:
	@ERLC@ -b beam \
           -pz $(top_builddir)/lib/cloudi_core/ebin \
           $(ERLC_OPTS) -o $@ $<

install-exec-hook: $(buildbeamdir)/cloudi_service_null.beam
	$(MKDIR_P) $(directinstdir)
	$(INSTALL_DATA) $(buildbeamdir)/cloudi_service_null.beam $(directinstdir)

