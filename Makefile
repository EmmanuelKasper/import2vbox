# https://www.debian.org/doc/manuals/debmake-doc/ch04.en.html#step-upstream

# prefix support
# https://www.gnu.org/prep/standards/html_node/Directory-Variables.html
prefix = /usr/local

all:

install:
	@# DESTDIR staged install support
	@# https://www.gnu.org/prep/standards/html_node/DESTDIR.html
	install -D import2vbox.pl $(DESTDIR)/$(prefix)/bin/import2vbox

uninstall:
	@# - ignores error in recipes, see
	@# https://www.gnu.org/software/make/manual/html_node/Errors.html
	-rm $(DESTDIR)/$(prefix)/bin/import2vbox

test:
	perl test.pl

.PHONY: all install uninstall test
