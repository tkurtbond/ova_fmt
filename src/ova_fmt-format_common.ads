--  Ova_Fmt.Format_Common - content-assembly logic shared by every
--  plain-text-markup backend (Ova_Fmt.Format_Rst's Terse mode,
--  Ova_Fmt.Format_Gemini, and Ova_Fmt.Format_Markdown) plus the
--  prose/tail scaffolding shared by ALL backends, including
--  Ova_Fmt.Format_Rst's Html_In_Rst mode.
--
--  Split out per the user, discussing the naming/architecture
--  question PLAN.md's Open Questions raised: rather than one package
--  ("Format_Terse") holding Terse/Gemtext/Html_In_Rst together, group
--  by what document syntax actually comes out (Format_Rst: Terse,
--  Html_In_Rst, and eventually groff-in-reST, all of which feed
--  Pandoc's reST reader; Format_Gemini: Gemtext, which isn't reST and
--  isn't run through Pandoc at all). That split would otherwise force
--  either duplicating the bulleted-list/header logic Terse and
--  Gemtext currently share, or leaving Terse and Html_In_Rst
--  (structurally very different -- bulleted list vs. nested
--  `<table>`s) awkwardly bundled together for no code-sharing reason.
--  This package is the third piece that lets the split happen without
--  duplication: it holds everything genuinely shared, and
--  Format_Rst/Format_Gemini each hold only what's actually specific
--  to them.
--
--  `Bold`/`Italic`/`Section_Header`/`Bullet` already gate on
--  `Config.Format = Config.Gemtext` internally (vs. everything else,
--  Terse and Html_In_Rst alike, which want reST-style markup) -- so
--  they need no parameterization to serve both Format_Rst and
--  Format_Gemini correctly; moving them here unchanged is sufficient.

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ova_Fmt.Entities;

package Ova_Fmt.Format_Common is

   function Bold (S : String) return String;
   function Italic (S : String) return String;
   function Section_Header (S : String) return String;
   function Bullet return String;

   function Trim_Img (N : Integer) return String;
   --  Plain non-negative magnitude ("3", "0") -- only for values that
   --  can never actually be negative (Health/Endurance/Threat Value,
   --  a Perk/Flaw's `counts-as`).

   function Number_Img (N : Integer) return String;
   --  A magnitude that might legitimately be negative (an attack's
   --  `roll`, a Perk/Flaw's chosen `cost`), rendered via
   --  Config.Unicode_Minus's glyph choice.

   function Signed_Img (N : Integer) return String;
   --  Ability/Weakness Levels: always an explicit sign.

   function End_With_Period (S : String) return String;
   --  Avoids a doubled "..": free-form author text can legitimately
   --  already end with a period.

   function Name_Detail (Name : Unbounded_String; Has_Detail : Boolean;
                          Detail : Unbounded_String) return String;

   function All_One_Line (S : String) return String;
   --  S with each line feed made a space: for a node of h-m-m's
   --  outline, or a raw table's cell, which hold one line of text.

   function Trim_Blanks (S : String) return String;
   --  S without leading or trailing blanks, tabs, line feeds or
   --  carriage returns.

   function Reflow (S : String) return String;
   function Reflow (S : Unbounded_String) return String;
   --  YAML prose as the sheet formats (-X, -S) hold it: each line
   --  trimmed, a paragraph's lines joined with spaces, paragraphs
   --  (separated by blank lines) with a single LF. They wrap the
   --  lines themselves.

   function Override_Mark (Overridden : Boolean; Raw : Boolean := False) return String;
   --  What follows a number its mapping's `overrides:` lists (PLAN.md
   --  §9 step 9): "" if not Overridden; "*"; or "\*" where the text
   --  is reST or Markdown, so the `*` isn't read as emphasis. Raw:
   --  the number goes in a raw HTML or groff table, so it's "*".

   function Defense_Text (C : Entities.Combat_Stats; Raw : Boolean := False) return String;
   --  C.Defense with an Override_Mark after each overridden value: a
   --  "2/6/5" Defense's are `defense`, `defense-2` and `defense-3`.

   function Half_TV_Text (Has, Half : Boolean) return String;
   --  " (half TV)" after the Level of an Ability or Sub_Item whose
   --  `threat-value-half` is true, with -O/--options; else "".

   function Entity_Title (E : Entities.Entity) return String;
   --  "Name (Concept)", then ", played by Player" with `player:`.

   function Options_Text (O : Entities.Options_Block) return String;
   --  The Creation Rules, comma-joined: "Base Zero (±5), ...", or "".

   function Format_Modifiers_Bracket
     (Perks, Flaws         : Entities.Perk_Flaw_Vectors.Vector;
      Has_Endurance        : Boolean := False;
      Endurance            : Integer := 0;
      Endurance_Overridden : Boolean := False;
      Raw                  : Boolean := False) return String;
   --  " [Perks: ...; Flaws: ...; 5 Endurance]", empty string if none
   --  is present. The Endurance is an Ability's or Sub_Item's own
   --  (Barrier's), worded like a Spell's, per the user, and inside
   --  the bracket because the book puts it in the same parenthetical
   --  as the Perks ("Barrier (no gesture; 5 end)", p. 41). Raw is
   --  Override_Mark's. Public: Format_Rst's Html_In_Rst and
   --  Groff_In_Rst table cells need this too.

   function Format_Perk_Flaw (PF : Entities.Perk_Flaw) return String;
   --  "Name: detail x2 (-1)", with only the parts PF has. Public:
   --  Ova_Fmt.Format_Inline lists an attack's Perks and Flaws itself.

   function Format_Attack_Clause (A : Entities.Attack) return String;
   --  "(Affinity: ...; Perks: ...; Flaws: ...)", "" if none apply.
   --  Public: Format_Rst's Html_In_Rst Attacks table needs this too.

   --  Per-item line formatters ("Name (detail) Level [Perks: ...;
   --  Flaws: ...] (note)" and its Fragment/Sub_Item/Spell variants) --
   --  public so Ova_Fmt.Format_Hmm can reuse the same field
   --  formatting for its own per-node text without duplicating it;
   --  none of these depend on Config.Format (no Bold/Section_Header/
   --  Bullet involved), so they're safe to share as-is.
   function Format_Ability_Line (A : Entities.Ability) return String;
   function Format_Weakness_Line (W : Entities.Weakness) return String;
   function Format_Fragment_Ability_Line (A : Entities.Ability) return String;
   function Format_Fragment_Weakness_Line (W : Entities.Weakness) return String;
   function Format_Sub_Item_Line (S : Entities.Sub_Item) return String;
   function Format_Fragment_Sub_Item_Line (S : Entities.Sub_Item) return String;
   function Format_Spell_Line (S : Entities.Spell) return String;

   function Format_Short_Spell_Line (S : Entities.Spell; Raw : Boolean := False) return String;
   --  The character sheet's shorter "Name (Ability +L, N END)", from
   --  the rulebook's Acacia (p. 134): "Break (Frail -2, 10 END)". It
   --  saves width in the sheet's narrow Abilities column, and is used
   --  there for every spell, per the user. Raw is Override_Mark's.

   function Format_Attack_Line (A : Entities.Attack) return String;
   --  "**Name:** Roll **N dice** | **DX d** | **Endurance Cost: c** " &
   --  "(clause). *Description*" -- the content of one Attack, with no
   --  leading bullet/indent of its own (Print_Attack below adds
   --  Terse/Gemtext's; Ova_Fmt.Format_Hmm adds its own tab indent).

   function Format_Combat_Summary_Line
     (C : Entities.Combat_Stats; NPC_Type : String := "") return String;
   --  "**Health:** H | **Endurance:** E | **Defense:** D | **Threat
   --  Value (TV):** T" -- the content of Combat_Stats' own summary
   --  line, with no leading bullet/indent of its own, same reuse
   --  reason as Format_Attack_Line. A non-empty NPC_Type leads it
   --  ("**NPC Type:** Heroic | **Health:** ..."), beside the totals
   --  the type sets, per the user.

   function NPC_Type_Text (E : Entities.Entity) return String;
   --  E's NPC type ("Heroic"), or "" if it has none.

   function Fragment_Attributes_Label (E : Entities.Entity) return String;
   --  "**Attributes:**", or, with an NPC type, the rulebook's own
   --  "**Attributes (Secondary):**" (Acacia's demons, p. 134).

   --  Comma-joined item lists (no label, no surrounding punctuation) --
   --  public so a caller (Ova_Fmt.Format_Hmm, this package's own
   --  Process_Entity/Print_Linked_Section/Print_Fragment_Attributes)
   --  can build its own labeled line/sentence around the join without
   --  duplicating the loop.
   function Join_Abilities (Vec : Entities.Ability_Vectors.Vector) return String;
   function Join_Weaknesses (Vec : Entities.Weakness_Vectors.Vector) return String;
   function Join_Fragment_Abilities (Vec : Entities.Ability_Vectors.Vector) return String;
   function Join_Fragment_Weaknesses (Vec : Entities.Weakness_Vectors.Vector) return String;
   function Join_Sub_Items (Vec : Entities.Sub_Item_Vectors.Vector) return String;
   function Join_Fragment_Sub_Items (Vec : Entities.Sub_Item_Vectors.Vector) return String;
   function Join_Spells (Vec : Entities.Spell_Vectors.Vector) return String;

   procedure Print_Sub_Entity_Fragment_Style (SE : Entities.Sub_Entity_Access);
   --  A Companion/Vehicle sub-entity with `fragment: true` set --
   --  plain reST/Gemtext text (no raw HTML/ms markup): no separate
   --  section header (the granting Ability's own line already names
   --  it via `detail:`), one compact "Attributes:" line (Join_
   --  Fragment_Sub_Items, matching a top-level Fragment entity's own
   --  Print_Fragment_Attributes shape), then Combat/Attacks via the
   --  same Print_Combat_And_Attacks every other entity uses. Format-
   --  invariant the same way a top-level Entity.Is_Fragment already is
   --  (Ova_Fmt.Format_Rst.Process_Entity's own Fragment branch) --
   --  public so Format_Rst's Groff_In_Rst path can call it directly
   --  after closing its current `.. raw:: ms` block (Groff_In_Rst's
   --  Companion/Vehicle sections are their own top-level content, so
   --  dropping to plain reST there is structurally clean); Html_In_
   --  Rst's own sub-entity content is nested *inside* a `<td>` cell,
   --  where dropping out of raw HTML mid-cell isn't possible, so it
   --  renders its own flatter-but-still-HTML version instead of
   --  calling this. Ova_Fmt.Format_Hmm doesn't call this either --
   --  its indentation-tracked structure needs Header_Depth threaded
   --  through every line, so it has its own mirrored version.

   procedure Print_Header_And_Prose (E : Entities.Entity; Entity_No : Positive);
   --  Title/tagline/summary/Background/Appearance/Personality/
   --  Character Hooks -- byte-identical
   --  across Terse, Gemtext, Markdown, and Html_In_Rst except for the
   --  title line's own heading syntax (underline vs. flat `# `).
   --  Public: Format_Rst's Html_In_Rst path calls this directly (its
   --  own content differs only in what comes after).

   procedure Print_Notes (E : Entities.Entity);
   --  Notes only, extracted out of Print_Tail so Format_Rst's
   --  Groff_In_Rst path can call it directly, sandwiched around its
   --  own boxed "Other Statistics" table instead of Print_Tail's
   --  plain comma-joined Fluff line (PLAN.md's rulebook-layout
   --  design) -- Notes/Creation Rules have no rulebook-box analog, so
   --  they stay exactly as every other format renders them.

   procedure Print_Options_If_Shown (E : Entities.Entity);
   --  Creation Rules (Options), same extraction reason as Print_Notes.

   procedure Print_Tail (E : Entities.Entity);
   --  Notes/Fluff/Creation-Rules -- byte-identical across every
   --  format and every entity kind (Fragment included) except
   --  Groff_In_Rst, which calls Print_Notes/Print_Options_If_Shown
   --  directly instead (its own Fluff rendering). Public: Format_Rst's
   --  Html_In_Rst path calls this directly.

   procedure Process_Entity (E : Entities.Entity; Entity_No : Positive);
   --  Full Fragment-or-flat-bulleted-list rendering (header/prose,
   --  Abilities, Weaknesses, Combat/Attacks, linked-content
   --  expansion) plus Print_Tail -- everything Terse, Gemtext, and
   --  Markdown need end to end. Does NOT handle Html_In_Rst's nested-table
   --  rendering; Format_Rst.Process_Entity only calls this for Terse
   --  mode (or for any Fragment, regardless of mode -- a Fragment
   --  renders identically under every format, PLAN.md/this package's
   --  callers).

end Ova_Fmt.Format_Common;
