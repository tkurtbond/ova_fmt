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

# Same, with -e/--gemtext-emphasis on -- *italic*/**bold** markers
# included, for comparison against the plain .gmi output above.
TEST_GEMTEXT_EMPHASIS_OUTPUT=$(foreach f,$(notdir $(TEST_DATA)),build/$(addsuffix .emp.gmi,$(basename $(f))))

# HTML-in-reST output (-H/--html, PLAN.md §9 step 4) -- a reST document
# with one raw <table>-nesting HTML block, `.html.gen.rst`, still run
# through Pandoc to a real standalone `.html` file (unlike Gemtext,
# this genuinely does need Pandoc: the deliverable is HTML, not the
# intermediate reST).
TEST_HTMLOUTPUT=$(foreach f,$(notdir $(TEST_DATA)),build/$(addsuffix .html.gen.rst,$(basename $(f))))
TEST_HTMLRENDEROUTPUT=$(foreach f,$(notdir $(TEST_DATA)),build/$(addsuffix .html,$(basename $(f))))

# h-m-m output (-m/--hmm, PLAN.md §9 step 5) -- a tab-indented outline,
# .hmm files. No PDF rendering, same reason as Gemtext: not a Pandoc
# reader, meant to be read (or loaded into an outline viewer) as-is.
TEST_HMMOUTPUT=$(foreach f,$(notdir $(TEST_DATA)),build/$(addsuffix .hmm,$(basename $(f))))

# Same, with -c/--hmm-compact-lists on -- Abilities/Weaknesses folded
# onto one node each, for comparison against the plain .hmm output
# above.
TEST_HMM_COMPACT_OUTPUT=$(foreach f,$(notdir $(TEST_DATA)),build/$(addsuffix .compact.hmm,$(basename $(f))))

.PHONY: all rst pdf gemtext html hmm install clean testclean

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

gemtext: $(PROGRAM) $(TEST_GEMTEXTOUTPUT) $(TEST_GEMTEXT_EMPHASIS_OUTPUT)

html: $(PROGRAM) $(TEST_HTMLOUTPUT) $(TEST_HTMLRENDEROUTPUT)

hmm: $(PROGRAM) $(TEST_HMMOUTPUT) $(TEST_HMM_COMPACT_OUTPUT)

build/%.gen.rst : test-data/%.yaml $(PROGRAM)
	./$(PROGRAM) $< >$@

build/%.gmi : test-data/%.yaml $(PROGRAM)
	./$(PROGRAM) -g $< >$@

build/%.emp.gmi : test-data/%.yaml $(PROGRAM)
	./$(PROGRAM) -g -e $< >$@

build/%.html.gen.rst : test-data/%.yaml $(PROGRAM)
	./$(PROGRAM) -H $< >$@

build/%.html : build/%.html.gen.rst
	pandoc -r rst -w html --standalone -o $@ $<

build/%.hmm : test-data/%.yaml $(PROGRAM)
	./$(PROGRAM) -m $< >$@

build/%.compact.hmm : test-data/%.yaml $(PROGRAM)
	./$(PROGRAM) -m -c $< >$@

#MS_COLUMNS=-V twocolumns
build/%.ms.pdf : build/%.gen.rst
	pandoc -r rst -w ms --template=tkb $(MS_COLUMNS) -o $@ $<

clean:
	-rm -f $(PROGRAM)

testclean:
	-rm -v build/*.gen.rst build/*.ms.pdf build/*.gmi build/*.html build/*.hmm

.PRECIOUS: build/%.gen.rst build/%.ms.pdf build/%.gmi build/%.emp.gmi build/%.html.gen.rst build/%.html build/%.hmm build/%.compact.hmm

print-%  : ; @echo $* = $($*)
