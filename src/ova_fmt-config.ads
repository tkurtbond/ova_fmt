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
