PREFIX ?= /usr/local
DOCDIR ?= $(PREFIX)/share/bpytop/doc

all:
	@echo Run \'make deps\' to install python dependencies, then \'make install\' to install bpytop.

deps:
	@python3 -m pip install -r requirements.txt

install:
	@mkdir -p $(DESTDIR)$(PREFIX)/bin
	@cp -p bpytop.py $(DESTDIR)$(PREFIX)/bin/bpytop
	@mkdir -p $(DESTDIR)$(DOCDIR)
	@cp -p README.md $(DESTDIR)$(DOCDIR)
	@cp -pr themes $(DESTDIR)$(PREFIX)/share/bpytop
	@chmod 755 $(DESTDIR)$(PREFIX)/bin/bpytop

uninstall:
	@rm -rf $(DESTDIR)$(PREFIX)/bin/bpytop
	@rm -rf $(DESTDIR)$(DOCDIR)
	@rm -rf $(DESTDIR)$(PREFIX)/share/bpytop
