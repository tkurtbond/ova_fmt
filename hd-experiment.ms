.\" hd-experiment.ms -- proof that groff's hdtbl macros (loaded as
.\" hdtbl.tmac; PLAN.md section 7 calls the package "hd" after the
.\" `hd` table macros it once shipped under) genuinely nest a complete
.\" sub-table inside a table cell, in groff 1.23.0 (the installed
.\" version, confirmed via `groff -v`). Plays the same role for the
.\" groff-in-reST backend (PLAN.md section 9, build order step 6) that
.\" Fukiko-experiment.lout plays for the Lout backend: a small,
.\" hand-written worked example to build the real backend's markup
.\" against, rather than reinventing the macro calls from scratch while
.\" also debugging Ova_Fmt.
.\"
.\" Modeled on Fukiko's Abilities table (compare
.\" ~/current/RPG/Tools/OVA/Fukiko-experiment.lout): a top-level
.\" two-column (Level | Name) table where the Transformation row's Name
.\" cell contains a second, complete Level|Name table for
.\" Transformation's own granted sub-abilities.
.\"
.\" Render directly with groff (bypassing Pandoc, to isolate hdtbl
.\" itself from the reST/raw-ms pipeline):
.\"   groff -ms hd-experiment.ms -T ps | ps2pdf - hd-experiment.ms.pdf
.\"
.\" Findings (this session):
.\" - hdtbl.tmac is present at
.\"   /usr/share/groff/1.23.0/tmac/hdtbl.tmac ("Heidelberger table
.\"   macros"), loaded with `.mso hdtbl.tmac` (no special `-m` flag
.\"   needed). It auto-loads hdmisc.tmac and 62bit.tmac itself.
.\" - Nesting is a first-class, designed-in feature, not a side effect:
.\"   hdtbl.tmac's own header comment (line 77) tracks a "table nesting
.\"   level" register (`t*#`), incremented by .TBL and decremented by
.\"   .ETB. groff's own packaged examples confirm this is intentional:
.\"   /usr/share/doc/groff/examples/hdtbl/color_nested_tables.roff ships
.\"   with groff itself.
.\" - A data cell's horizontal alignment keyword is `hal` (b/c/r/l), NOT
.\"   `ad` -- an early draft of this experiment used `ad=r` by mistake
.\"   (a plain adjustment-mode guess, not an hdtbl keyword) and it was
.\"   silently treated as literal cell text instead of erroring, which
.\"   is worth remembering when debugging Ova_Fmt's eventual output:
.\"   hdtbl does not validate unknown keyword=value tokens against a
.\"   fixed keyword list, it just fails to recognize them and leaves
.\"   them as content.
.\" - Verified end-to-end through the actual planned pipeline too (see
.\" hd-experiment.rst / hd-experiment.ms.pdf in this same directory):
.\"   a `.. raw:: ms` block containing this exact hdtbl markup, run
.\"   through `pandoc -r rst -w ms --template=tkb -o out.ms.pdf in.rst`
.\"   (the same command GNUmakefile's `build/%.ms.pdf` rule already
.\"   uses), passes the raw block through byte-for-byte into the
.\"   intermediate .ms text and renders correctly in the final PDF via
.\"   pandoc's default ms pdf-engine (pdfroff) -- no extra flags or
.\"   template changes needed. The rendered table floats to the top of
.\"   the page ahead of surrounding prose in that pipeline, which is
.\"   standard groff `-ms` floating-table behavior (tables float by
.\"   default), not a nesting problem -- worth remembering as a layout
.\"   detail to address (or accept) once the real backend emits prose
.\"   around its tables, not a blocker for this proof of concept.
.\" - Column widths are controlled with `.TBL`'s `width` argument: a
.\"   quoted, space-separated list, one value per column, each either an
.\"   absolute groff length (e.g. `0.75i`) or a percentage of the current
.\"   line length ending in `%` (e.g. `10%`). Values must be quoted with
.\"   *single* quotes (`width='10% 90%'`), per hdmisc.tmac's `getarg`
.\"   convention for keyword values containing spaces -- double quotes
.\"   are not recognized and produce a confusing "Invalid cell width
.\"   'width'" diagnostic instead (the whole `width "10% 90%"` token gets
.\"   misparsed as the bare keyword `width` followed by unrelated cell
.\"   widths). Applied below to narrow the Level column to 10% of the
.\"   table width, leaving 90% for Name; a nested .TBL's own width= is
.\"   relative to that cell's (already-narrowed) available width, and
.\"   the two levels don't need matching splits.
.mso hdtbl.tmac
.
Text before the table.
.LP
.TBL cols=2 border=.5p bc=black csp=2p cpd=2p width='10% 90%'
.CPTN val=b Abilities
.TR
.TH Level
.TH Name
.TR
.TD hal=r +2
.TD Companion (Azyrus)
.TR
.TD hal=r +2
.TD Cute!
.TR
.TD hal=r +1
.TD Iron-Willed
.TR
.TD hal=r +2
.TD Knowledge (Shoujo Manga)
.TR
.TD hal=r +2
.TD Quick
.TR
.TD hal=r +2
.TD Shape-Shifter
.TR
.TD hal=r +4
.TD
Transformation
.TBL cols=2 border=.5p bc=black csp=2p cpd=2p width='10% 90%'
.TR
.TD hal=r +2
.TD Attack
.TR
.TD hal=r +3
.TD Barrier (Area Effect; Elaborate Gestures; 5 End)
.TR
.TD hal=r +2
.TD Combat Expert
.TR
.TD hal=r +2
.TD Healer
.TR
.TD hal=r \-1
.TD Bizarre Appearance (Cat Features)
.ETB
.TR
.TD hal=r +15
.TD \fBTotal Ability Levels\fP
.ETB
.LP
Text after the table.
