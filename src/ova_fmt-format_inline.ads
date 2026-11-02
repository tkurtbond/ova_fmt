--  Ova_Fmt.Format_Inline - the inline format (-i/--inline): each entity
--  as one Markdown paragraph, a stat block for an adventure's cast list,
--  per the user (2026-10-23), modeled on the Cast of Lost-Worlds'
--  001-breakout.md:
--
--     **Name** (Secondary). Summary. Background. *Ability +2 (detail),
--     ...; Weakness -1, ...* Attack (Perks; Flaws): Roll 4, DX 3, End
--     0. Defense 3. Health 20, Endurance 20. TV 6.
--
--  Abilities and Weaknesses, a Companion's or Vehicle's and those a
--  Transformation grants too, are "Name Level (detail)", the rulebook's
--  NPC Fragment order (Format_Common.Join_Fragment_Abilities), as the
--  cast has "Attack +2 (Blaster rifle)" (the user, 2026-10-23).
--
--  A count: over 1 makes the lead "**Name** (three Secondaries)." and
--  the end "TV 6 each.": one stat block standing for a group. It is the
--  only format that shows it, as a sheet describes one.
--
--  First written for ova_fmt_po (its OvaInline), whose output this
--  matches byte for byte. A stat block leaves out what a cast list
--  doesn't need: the tagline, character hooks, notes, fluff, options,
--  the player and the portrait. The prose that describes the entity
--  (summary, background, appearance, personality) runs together, as do
--  its combat notes. An NPC Fragment's background names it already, so
--  it leads instead of the bold name. An Ability's linked content (a
--  Transformation's grants, spells, a Companion or Vehicle) follows as
--  a paragraph of its own.
--
--  Each paragraph is filled to 70 columns, counting characters, not
--  bytes, and never breaks a line before a word that would start a
--  Markdown block there. Its own package, like Format_Hmm: it reuses
--  Format_Common's per-item formatters, but none of its bulleted-list
--  scaffolding.

with Ova_Fmt.Entities;

package Ova_Fmt.Format_Inline is

   procedure Process_Entity (E : Entities.Entity; Entity_No : Positive);
   --  Writes E to Ada.Text_IO.Current_Output. Entity_No is accepted
   --  only for signature parity with the other formats' dispatch: a
   --  paragraph has no heading to vary.

end Ova_Fmt.Format_Inline;
