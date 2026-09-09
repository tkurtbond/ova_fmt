SHELL=bash

PROGRAM=ova_fmt

TEST_DATA=$(wildcard test-data/*.yaml)

# Terse (reST) output -- the only backend implemented so far (PLAN.md
# §9 step 2: HTML/raw-ms/Lout are steps 3-5, not yet built). Unlike
# besm2_fmt, ova_fmt has no -t/-s/-m/-n flags yet -- terse is simply
# what the program does.
TEST_TERSEOUTPUT=$(foreach f,$(notdir $(TEST_DATA)),build/$(addsuffix .gen.rst,$(basename $(f))))

# PDF renderings of the above, via pandoc's ms writer -- same
# pipeline/template besm2_fmt's GNUmakefile uses (reST -> pandoc -r
# rst -w ms --template=tkb -> groff/ms -> PDF), just with one output
# variant instead of besm2_fmt's several.
TEST_PDFOUTPUT=$(foreach f,$(notdir $(TEST_DATA)),build/$(addsuffix .ms.pdf,$(basename $(f))))

.PHONY: all rst pdf install clean testclean

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

build/%.gen.rst : test-data/%.yaml $(PROGRAM)
	./$(PROGRAM) $< >$@

#MS_COLUMNS=-V twocolumns
build/%.ms.pdf : build/%.gen.rst
	pandoc -r rst -w ms --template=tkb $(MS_COLUMNS) -o $@ $<

clean:
	-rm -f $(PROGRAM)

testclean:
	-rm -v build/*.gen.rst build/*.ms.pdf

.PRECIOUS: build/%.gen.rst build/%.ms.pdf

print-%  : ; @echo $* = $($*)
