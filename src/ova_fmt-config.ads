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

   --  Terse (reST) and Gemtext (gemtext.gmi, the Gemini protocol's
   --  hypertext markup -- PLAN.md's build order §9) share almost all
   --  of Ova_Fmt.Format_Terse's content-assembly logic, differing
   --  only in a handful of low-level primitives (inline emphasis,
   --  heading syntax, list-item prefix) -- per the user, parameterized
   --  in that one package rather than duplicated into a second one.
   --  Html_In_Rst: a reST document (same header/tagline/summary/
   --  background/personality/Notes/Fluff/Creation-Rules rendering as
   --  Terse -- unaffected by this value) with one `.. raw:: html`
   --  block for the genuinely tabular/nestable content (Abilities/
   --  Weaknesses/Combat/Attacks), still run through Pandoc -- not a
   --  standalone HTML document generated directly (PLAN.md's Open
   --  Questions has the full "HTML-in-reST, not just HTML" naming
   --  rationale).
   type Output_Format is (Terse, Gemtext, Html_In_Rst);

   Format : aliased Output_Format := Terse;  -- -g/--gemtext or -H/--html

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
