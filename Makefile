# see https://www.debian.org/doc/manuals/debmake-doc/ch04.en.html#step-upstream
# for expected make variables
prefix = /usr/local

all:

install:
	install -D import2vbox.pl $(DESTDIR)/$(prefix)/bin/import2vbox

uninstall:
	# https://www.gnu.org/software/make/manual/html_node/Errors.html
	-rm $(DESTDIR)/$(prefix)/bin/import2vbox
