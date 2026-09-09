SHELL=bash

PROGRAM=ova_fmt

TEST_DATA=$(wildcard test-data/*.yaml)

# Terse (reST) output -- the only backend implemented so far (PLAN.md
# §9 step 2: HTML/raw-ms/Lout are steps 3-5, not yet built). Unlike
# besm2_fmt, ova_fmt has no -t/-s/-m/-n flags yet -- terse is simply
# what the program does.
TEST_TERSEOUTPUT=$(foreach f,$(notdir $(TEST_DATA)),build/$(addsuffix .gen.rst,$(basename $(f))))

.PHONY: all rst install clean testclean

all: $(PROGRAM)

$(PROGRAM): $(wildcard src/*.ads src/*.adb) ova_fmt.gpr
	gprbuild -p -P ova_fmt.gpr

# Installs $(PROGRAM) under $HOME/local (ova_fmt.gpr's Install package
# Prefix) via gprinstall.
install:
	gprbuild $(GPROPTS) -p -P ova_fmt.gpr
	gprinstall --mode=usage --install-name=ova_fmt -f $(GPROPTS) -P ova_fmt.gpr

rst: $(PROGRAM) $(TEST_TERSEOUTPUT)

build/%.gen.rst : test-data/%.yaml $(PROGRAM)
	./$(PROGRAM) $< >$@

clean:
	-rm -f $(PROGRAM)

testclean:
	-rm -v build/*.gen.rst

.PRECIOUS: build/%.gen.rst

print-%  : ; @echo $* = $($*)
