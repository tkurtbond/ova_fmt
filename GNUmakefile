SHELL=bash

PROGRAM=ova_fmt

#  Broken.yaml is deliberately invalid (missing required fields, to
#  exercise Ova_Fmt.Entities' error-collection -- see its own header
#  comment), so it's excluded from the normal golden-output targets:
#  ova_fmt correctly exits non-zero on it, which would otherwise abort
#  `make rst`/`make pdf` before every other, well-formed fixture gets
#  (re)built.
TEST_DATA=$(filter-out test-data/Broken.yaml,$(wildcard test-data/*.yaml))

# Terse (reST) output -- the default backend (PLAN.md §9 step 2).
# Plain `ova_fmt`, no format-selecting flag needed.
TEST_TERSEOUTPUT=$(foreach f,$(notdir $(TEST_DATA)),build/$(addsuffix .gen.rst,$(basename $(f))))

# PDF renderings of the above, via pandoc's ms writer -- same
# pipeline/template besm2_fmt's GNUmakefile uses (reST -> pandoc -r
# rst -w ms --template=tkb -> groff/ms -> PDF), just with one output
# variant instead of besm2_fmt's several.
TEST_PDFOUTPUT=$(foreach f,$(notdir $(TEST_DATA)),build/$(addsuffix .ms.pdf,$(basename $(f))))

# Gemtext output (-g/--gemtext, PLAN.md §9 step 3) -- .gmi files, the
# Gemini protocol's own convention. No PDF rendering: gemtext isn't a
# Pandoc reader, and it's meant to be read as gemtext, not typeset.
TEST_GEMTEXTOUTPUT=$(foreach f,$(notdir $(TEST_DATA)),build/$(addsuffix .gmi,$(basename $(f))))

.PHONY: all rst pdf gemtext install clean testclean

all: $(PROGRAM)

$(PROGRAM): $(wildcard src/*.ads src/*.adb) ova_fmt.gpr
	gprbuild -p -P ova_fmt.gpr

# Installs $(PROGRAM) under $HOME/local (ova_fmt.gpr's Install package
# Prefix) via gprinstall.
install:
	gprbuild $(GPROPTS) -p -P ova_fmt.gpr
	gprinstall --mode=usage --install-name=ova_fmt -f $(GPROPTS) -P ova_fmt.gpr

rst: $(PROGRAM) $(TEST_TERSEOUTPUT)

pdf: rst $(TEST_PDFOUTPUT)

gemtext: $(PROGRAM) $(TEST_GEMTEXTOUTPUT)

build/%.gen.rst : test-data/%.yaml $(PROGRAM)
	./$(PROGRAM) $< >$@

build/%.gmi : test-data/%.yaml $(PROGRAM)
	./$(PROGRAM) -g $< >$@

#MS_COLUMNS=-V twocolumns
build/%.ms.pdf : build/%.gen.rst
	pandoc -r rst -w ms --template=tkb $(MS_COLUMNS) -o $@ $<

clean:
	-rm -f $(PROGRAM)

testclean:
	-rm -v build/*.gen.rst build/*.ms.pdf build/*.gmi

.PRECIOUS: build/%.gen.rst build/%.ms.pdf build/%.gmi

print-%  : ; @echo $* = $($*)
