# ova_fmt — Format an OVA character expressed as a YAML file and output it in multiple formats.

ova_fmt reads a character written for the OVA tabletop RPG (Open
Versatile Anime engine) — Abilities, Weaknesses, combat stats, Attacks,
and linked content like Transformations, Magic spells, and Companions
— from a YAML file and renders it in one of several output formats.

Unlike [besm2_fmt](https://github.com/tkurtbond/besm2_fmt) (a faithful
Ada port of an existing, working Scheme program), this is a
from-scratch design-and-port effort: the earlier `ova-rst.scm` project
never got past an unfinished skeleton, so ova_fmt's YAML schema and
output formats were designed here from the OVA rulebook's own sample
characters. The terse/prose reStructuredText backend is done; HTML,
groff/`hd`, and direct-to-Lout backends (needed for OVA's nested-table
character sheets) are planned next. See `PLAN.md` for the full design
history and open questions.
