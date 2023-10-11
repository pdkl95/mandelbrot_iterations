top_srcdir ?= .
srcdir     ?= $(top_srcdir)/src
builddir   ?= $(srcdir)

#
# config
#

COFFEE ?= coffee
COFFEE_OPTIONS ?= --no-header --compile

M4 ?= m4
M4OPTS = --include=$(builddir) --include=$(srcdir)

RM ?= rm -f

#
# build deps

MAIN_TARGET = $(top_srcdir)/mandel_iter.html
MAIN_TARGET_SRC = $(srcdir)/page.html.m4
MAIN_TARGET_DEPS = $(MAIN_TARGET_SRC) \
        $(builddir)/uioption.js \
        $(builddir)/motion.js \
	$(builddir)/highlight.js \
	$(builddir)/fileio.js \
	$(builddir)/dialog.js \
	$(builddir)/color.js \
	$(builddir)/main.js \
        $(srcdir)/basic.css \
        $(srcdir)/style.css

COFFEE_SRC = $(wildcard $(srcdir)/*.coffee)
JS_TARGETS = $(patsubst $(srcdir)/%.coffee,$(builddir)/%.js,$(COFFEE_SRC))

TARGETS = \
	$(MAIN_TARGET) \
	$(JS_TARGETS)

#
# build instructions
#
all: build
build: $(TARGETS)

$(builddir)/%.js: $(srcdir)/%.coffee
	$(COFFEE) $(COFFEE_OPTIONS) $< > $@

$(MAIN_TARGET): $(MAIN_TARGET_DEPS)
	$(M4) $(M4OPTS) $(MAIN_TARGET_SRC) >$@

clean-builddir:
	$(RM) $(JS_TARGETS)

clean: clean-builddir
	$(RM) $(MAIN_TARGET)

.PHONY: all build clean clean-builddir
