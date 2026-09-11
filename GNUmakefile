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
# variant instead of besm2_fmt's several. Named `.rst.ms.pdf`, not just
# `.ms.pdf`, so the source format (reST) and the intermediate pandoc
# writer (`ms`) are both visible in the filename -- needed now that
# Markdown's own PDF pipeline below produces a same-writer `.md.ms.pdf`
# alongside it.
TEST_PDFOUTPUT=$(foreach f,$(notdir $(TEST_DATA)),build/$(addsuffix .rst.ms.pdf,$(basename $(f))))

# Gemtext output (-g/--gemtext, PLAN.md §9 step 3) -- .gmi files, the
# Gemini protocol's own convention. No PDF rendering: gemtext isn't a
# Pandoc reader, and it's meant to be read as gemtext, not typeset.
TEST_GEMTEXTOUTPUT=$(foreach f,$(notdir $(TEST_DATA)),build/$(addsuffix .gmi,$(basename $(f))))

# Same, with -e/--gemtext-emphasis on -- *italic*/**bold** markers
# included, for comparison against the plain .gmi output above.
TEST_GEMTEXT_EMPHASIS_OUTPUT=$(foreach f,$(notdir $(TEST_DATA)),build/$(addsuffix .emp.gmi,$(basename $(f))))

# Markdown output (-M/--markdown) -- .md files, plain Markdown prose,
# the same terse content Terse's own reST renders.
TEST_MARKDOWNOUTPUT=$(foreach f,$(notdir $(TEST_DATA)),build/$(addsuffix .md,$(basename $(f))))

# PDF renderings of the above, via pandoc's ms writer -- same
# `pandoc -r <format> -w ms --template=tkb` pipeline Terse's own PDF
# uses (just with `markdown` instead of `rst` as the reader), so per
# the user, both PDF pipelines are built by default and both carry
# their source format in the filename (`.rst.ms.pdf`/`.md.ms.pdf`) to
# tell them apart.
TEST_MARKDOWN_PDFOUTPUT=$(foreach f,$(notdir $(TEST_DATA)),build/$(addsuffix .md.ms.pdf,$(basename $(f))))

# HTML-in-reST output (-H/--html, PLAN.md §9 step 4) -- a reST document
# with one raw <table>-nesting HTML block, `.html.gen.rst`, still run
# through Pandoc to a real standalone `.html` file (unlike Gemtext,
# this genuinely does need Pandoc: the deliverable is HTML, not the
# intermediate reST).
TEST_HTMLOUTPUT=$(foreach f,$(notdir $(TEST_DATA)),build/$(addsuffix .html.gen.rst,$(basename $(f))))
TEST_HTMLRENDEROUTPUT=$(foreach f,$(notdir $(TEST_DATA)),build/$(addsuffix .html,$(basename $(f))))

# groff-in-reST output (-G/--groff, PLAN.md §9 step 6) -- a reST
# document with `.. raw:: ms` blocks using groff's `hd` table macros
# (hdtbl.tmac), laid out like the rulebook's own Sample Characters
# spread rather than Html_In_Rst's sequential one-table-per-section
# shape. Rendered the same way Terse's own PDF is (reST -> pandoc -r
# rst -w ms --template=tkb -> groff/ms -> PDF): the deliverable here
# is a PDF, same as Terse, not a standalone document format the way
# Gemtext/h-m-m/HTML-in-reST's own .html are.
TEST_GROFFOUTPUT=$(foreach f,$(notdir $(TEST_DATA)),build/$(addsuffix .groff.gen.rst,$(basename $(f))))
TEST_GROFFRENDEROUTPUT=$(foreach f,$(notdir $(TEST_DATA)),build/$(addsuffix .groff.pdf,$(basename $(f))))

# h-m-m output (-m/--hmm, PLAN.md §9 step 5) -- a tab-indented outline,
# .hmm files. No PDF rendering, same reason as Gemtext: not a Pandoc
# reader, meant to be read (or loaded into an outline viewer) as-is.
TEST_HMMOUTPUT=$(foreach f,$(notdir $(TEST_DATA)),build/$(addsuffix .hmm,$(basename $(f))))

# Same, with -c/--hmm-compact-lists on -- Abilities/Weaknesses folded
# onto one node each, for comparison against the plain .hmm output
# above.
TEST_HMM_COMPACT_OUTPUT=$(foreach f,$(notdir $(TEST_DATA)),build/$(addsuffix .compact.hmm,$(basename $(f))))

# Same, with -p/--hmm-plain on -- no *italic*/**bold** emphasis markers
# at all, for comparison against the (default, emphasized) .hmm output
# above.
TEST_HMM_PLAIN_OUTPUT=$(foreach f,$(notdir $(TEST_DATA)),build/$(addsuffix .plain.hmm,$(basename $(f))))

.PHONY: all rst pdf gemtext markdown html groff hmm install clean testclean

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

markdown: $(PROGRAM) $(TEST_MARKDOWNOUTPUT) $(TEST_MARKDOWN_PDFOUTPUT)

html: $(PROGRAM) $(TEST_HTMLOUTPUT) $(TEST_HTMLRENDEROUTPUT)

groff: $(PROGRAM) $(TEST_GROFFOUTPUT) $(TEST_GROFFRENDEROUTPUT)

hmm: $(PROGRAM) $(TEST_HMMOUTPUT) $(TEST_HMM_COMPACT_OUTPUT) $(TEST_HMM_PLAIN_OUTPUT)

build/%.gen.rst : test-data/%.yaml $(PROGRAM)
	./$(PROGRAM) $< >$@

build/%.gmi : test-data/%.yaml $(PROGRAM)
	./$(PROGRAM) -g $< >$@

build/%.emp.gmi : test-data/%.yaml $(PROGRAM)
	./$(PROGRAM) -g -e $< >$@

build/%.md : test-data/%.yaml $(PROGRAM)
	./$(PROGRAM) -M $< >$@

build/%.html.gen.rst : test-data/%.yaml $(PROGRAM)
	./$(PROGRAM) -H $< >$@

build/%.html : build/%.html.gen.rst
	pandoc -r rst -w html --standalone -o $@ $<

build/%.groff.gen.rst : test-data/%.yaml $(PROGRAM)
	./$(PROGRAM) -G $< >$@

build/%.groff.pdf : build/%.groff.gen.rst
	pandoc -r rst -w ms --template=tkb -o $@ $<

build/%.hmm : test-data/%.yaml $(PROGRAM)
	./$(PROGRAM) -m $< >$@

build/%.compact.hmm : test-data/%.yaml $(PROGRAM)
	./$(PROGRAM) -m -c $< >$@

build/%.plain.hmm : test-data/%.yaml $(PROGRAM)
	./$(PROGRAM) -m -p $< >$@

#MS_COLUMNS=-V twocolumns
build/%.rst.ms.pdf : build/%.gen.rst
	pandoc -r rst -w ms --template=tkb $(MS_COLUMNS) -o $@ $<

build/%.md.ms.pdf : build/%.md
	pandoc -r markdown -w ms --template=tkb $(MS_COLUMNS) -o $@ $<

clean:
	-rm -f $(PROGRAM)

testclean:
	-rm -v build/*.gen.rst build/*.rst.ms.pdf build/*.gmi build/*.md build/*.md.ms.pdf build/*.html build/*.hmm build/*.groff.gen.rst build/*.groff.pdf

.PRECIOUS: build/%.gen.rst build/%.rst.ms.pdf build/%.gmi build/%.emp.gmi build/%.md build/%.md.ms.pdf build/%.html.gen.rst build/%.html build/%.hmm build/%.compact.hmm build/%.plain.hmm build/%.groff.gen.rst build/%.groff.pdf

print-%  : ; @echo $* = $($*)
