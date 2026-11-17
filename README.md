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
characters. `-i`/`--inline` writes each entity instead as one
Markdown paragraph, an inline stat block for an adventure's cast
list. The terse/prose reStructuredText backend is done; HTML,
groff/`hd`, and direct-to-Lout backends (needed for OVA's nested-table
character sheets) are planned next. See `PLAN.md` for the full design
history and open questions.

## OVA and the rulebook

OVA, *OVA: The Anime Role-Playing Game*, is © 2015 Wise Turtle. This
project is not affiliated with or endorsed by Wise Turtle. It formats
characters you write; it holds none of the rulebook's rules text, and
you need the rulebook to play. `PLAN.md` quotes a few of the rules'
sentences where its design discusses them.

The test fixtures in `test-data/` (and the `hd-*experiment` files)
record the rulebook's sample characters so that the formatter's output
can be checked against them; their backgrounds and descriptions are
paraphrased, and only short captions such as attack descriptions
follow the book's wording.
