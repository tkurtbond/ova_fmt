--  Ova_Fmt.Config - CLI-settable global configuration.
--
--  Deliberately small next to besm2_fmt.Config: PLAN.md §7/§9 settled
--  on terse (reST) as the first and, for now, only output format --
--  there's no BESM-style grid/hmm/raw-ms selector yet, so there's
--  nothing to select between. Fields are `aliased` so Ova_Fmt.Cli can
--  point Arg_Parser options at them via `'Access`, same pattern
--  besm2_fmt.Config uses.

with Arg_Parser;

package Ova_Fmt.Config is

   --  Terse (reST), Gemtext (gemtext.gmi, the Gemini protocol's
   --  hypertext markup -- PLAN.md's build order §9), and Markdown
   --  share almost all of their content-assembly logic
   --  (Ova_Fmt.Format_Common), differing only in a handful of
   --  low-level primitives (inline emphasis, heading syntax, list-item
   --  prefix). Markdown: plain Markdown prose -- same bulleted-list
   --  shape and `**bold**`/`*italic*` inline markup as Terse (only
   --  reST/Markdown's heading *syntax* differs, not the inline markup
   --  -- PLAN.md's already-settled "Terse output is reST, not
   --  Markdown" rationale), rendered by Ova_Fmt.Format_Markdown, a
   --  thin entry point into Ova_Fmt.Format_Common the same way
   --  Ova_Fmt.Format_Gemini is. Per the user: entity titles always use
   --  a flat `# Title` ATX heading, the same one Gemtext already uses
   --  and for the same reason -- no equivalent to -U/--subunderliner's
   --  "distinguish entities after the first via a different underline
   --  character" (Markdown's ATX headings have no character to swap,
   --  only a depth, and flat was chosen over nesting subsequent
   --  entities to `##` instead). This is Format_Markdown's first-pass
   --  design (PLAN.md's build order): a nested-table mode analogous to
   --  Html_In_Rst/Groff_In_Rst, if OVA's tabular content ever needs one
   --  in Markdown, is not yet designed. Html_In_Rst: a
   --  reST document (same header/tagline/summary/background/
   --  personality/Notes/Fluff/Creation-Rules rendering as Terse --
   --  unaffected by this value) with one `.. raw:: html` block for
   --  the genuinely tabular/nestable content (Abilities/Weaknesses/
   --  Combat/Attacks), still run through Pandoc -- not a standalone
   --  HTML document generated directly (PLAN.md's Open Questions has
   --  the full "HTML-in-reST, not just HTML" naming rationale). Terse
   --  and Html_In_Rst are both handled by Ova_Fmt.Format_Rst; Gemtext
   --  by Ova_Fmt.Format_Gemini -- see Ova_Fmt.Format_Common's header
   --  comment for why the split runs this way (by output pipeline,
   --  not by how much code happens to be shared). Hmm: a tab-indented
   --  outline (Ova_Fmt.Format_Hmm, modeled on besm2_fmt.Format_Hmm's
   --  shape, PLAN.md §9 item 5) -- its own package, since it's neither
   --  reST nor Gemtext and shares no content-assembly code with either
   --  (Ova_Fmt.Format_Common is specifically the reST/Gemtext
   --  bulleted-list family).
   --  Groff_In_Rst: a reST document (same shared header/tagline/
   --  summary/background/personality rendering as Terse/Html_In_Rst)
   --  with `.. raw:: ms` blocks using groff's `hd` table macros
   --  (`hdtbl.tmac`) instead of classic `tbl` -- PLAN.md §7's
   --  settled per-format strategy, since `tbl` can't nest a table
   --  inside a cell at all. Laid out to match the rulebook's own
   --  Sample Characters spread (PLAN.md §2.1/§2.2/§9 step 6's
   --  progress notes) rather than Html_In_Rst's simpler sequential
   --  one-table-per-section layout: Abilities/Weaknesses side by
   --  side, a combined "Attacks & Combat Stats" box, an "Other
   --  Statistics" box built from `fluff:` instead of Print_Tail's
   --  plain comma-joined line. Companion/Vehicle sub-entities print
   --  as their own separate section *after* the main character,
   --  structurally self-similar to a top-level entity, rather than
   --  nested inside the granting Ability's table cell -- per the
   --  user, and confirmed against the rulebook's own Karis/Arasuni
   --  spread (§2.3: Arasuni gets his own separately-boxed "Attacks &
   --  Combat Stats (ARASUNI)"), not just a workaround for `hd`'s own
   --  undocumented per-table pagination ceiling (found this session)
   --  that this move happens to also fix.
   type Output_Format is (Terse, Gemtext, Markdown, Html_In_Rst, Groff_In_Rst, Hmm);

   Format : aliased Output_Format := Terse;
   --  -g/--gemtext, -M/--markdown, -H/--html, -G/--groff, or -m/--hmm

   --  Indentation baseline for -m/--hmm output, in tab stops -- lets
   --  the output be embedded under an existing outline node elsewhere
   --  rather than always starting at the left margin, same purpose as
   --  besm2_fmt.Config.Hmm_Depth/-L/--hmm-depth. Resets to this value
   --  for every entity (does not accumulate across entities in one
   --  file), same as besm2_fmt's.
   Hmm_Depth : aliased Natural := 0;  -- -L/--hmm-depth

   --  Per the user: an alternative Abilities/Weaknesses shape for
   --  -m/--hmm output -- instead of an "Abilities"/"Weaknesses" header
   --  node with each item as its own child node (the default), fold
   --  the label and the whole comma-joined item list onto one node,
   --  "Abilities: Ability1 +1 [...], Ability2 ...", matching how Terse
   --  mode already presents the same content on one line. Applies
   --  wherever an Abilities/Weaknesses section is printed, including a
   --  Companion/Vehicle sub-entity's own -- it's the same section
   --  printer, called recursively. Off by default (matches every
   --  other opt-in rendering choice: -e/--gemtext-emphasis,
   --  -O/--options).
   Hmm_Compact_Lists : aliased Boolean := False;  -- -c/--hmm-compact-lists

   --  Per the user: -m/--hmm output can turn OFF *italic*/**bold**/
   --  ***bold italic*** emphasis entirely -- unlike Gemtext (whose
   --  spec has no emphasis syntax at all, so it's opt-in to add it),
   --  Hmm's underlying reST-style emphasis markup is on by default
   --  (Ova_Fmt.Format_Common.Bold/Italic's own doc comment), so this
   --  is opt-in to remove it, off by default like every other opt-in
   --  rendering choice.
   Hmm_Plain : aliased Boolean := False;  -- -p/--hmm-plain

   --  Gemtext's spec has no inline emphasis at all (no bold/italic) --
   --  confirmed against <https://geminiprotocol.net/docs/gemtext.gmi>
   --  -- but per the user, many gemtext authors use `*`/`**` anyway,
   --  unenforced convention rather than real markup, so this is an
   --  opt-in rather than something Gemtext output does by default.
   --  Meaningless when Format = Terse (reST always wants its own
   --  emphasis markup).
   Gemtext_Emphasis : aliased Boolean := False;  -- -e/--gemtext-emphasis

   Output_File : aliased Arg_Parser.String_Reference;  -- -o/--output; null = unset (stdout)

   Underliner    : aliased Character := '=';        -- -u/--underliner
   Subunderliner : aliased Character := ASCII.NUL;  -- -U/--subunderliner; NUL = unset

   --  Same besm2_fmt.Config field (and, per user request, the same
   --  default-on polarity besm2_fmt was flipped to, see its PLAN.md):
   --  negative numbers this program builds itself (Weakness/Ability
   --  Levels, a Perk/Flaw's negative `cost`, an attack's `roll` when
   --  negative) use Unicode MINUS SIGN (U+2212) by default;
   --  -n/--no-unicode-minus reverts to ASCII hyphen-minus. Content the
   --  program doesn't interpret (YAML string fields like `detail`)
   --  is unaffected either way -- only computed negative-number
   --  rendering is gated on this.
   Unicode_Minus : aliased Boolean := True;  -- -n/--no-unicode-minus clears this

   --  Per the user: an entity's options: block (which character-
   --  creation limiting rules -- Base Zero/Power Ceiling/Scaled Cost/
   --  Combined Effectiveness, rulebook p. 20-21 -- were used to build
   --  it) is GM/author metadata, useful when updating a character but
   --  not something every player-facing render should show, so it's
   --  off unless asked for.
   Show_Options : aliased Boolean := False;  -- -O/--options sets this

end Ova_Fmt.Config;
