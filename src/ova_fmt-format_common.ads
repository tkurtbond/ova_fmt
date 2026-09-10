--  Ova_Fmt.Format_Common - content-assembly logic shared by every
--  plain-text-markup backend (Ova_Fmt.Format_Rst's Terse mode, and
--  Ova_Fmt.Format_Gemini) plus the prose/tail scaffolding shared by
--  ALL backends, including Ova_Fmt.Format_Rst's Html_In_Rst mode.
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

   function Format_Modifiers_Bracket
     (Perks, Flaws : Entities.Perk_Flaw_Vectors.Vector) return String;
   --  "[Perks: ...; Flaws: ...]", empty string if neither is present.
   --  Public: Format_Rst's Html_In_Rst table cells need this too.

   function Format_Attack_Clause (A : Entities.Attack) return String;
   --  "(Affinity: ...; Perks: ...; Flaws: ...)", "" if none apply.
   --  Public: Format_Rst's Html_In_Rst Attacks table needs this too.

   procedure Print_Header_And_Prose (E : Entities.Entity; Entity_No : Positive);
   --  Title/tagline/summary/Background/Personality -- byte-identical
   --  across Terse, Gemtext, and Html_In_Rst. Public: Format_Rst's
   --  Html_In_Rst path calls this directly (its own content differs
   --  only in what comes after).

   procedure Print_Tail (E : Entities.Entity);
   --  Notes/Fluff/Creation-Rules -- byte-identical across every
   --  format and every entity kind (Fragment included). Public:
   --  Format_Rst's Html_In_Rst path calls this directly.

   procedure Process_Entity (E : Entities.Entity; Entity_No : Positive);
   --  Full Fragment-or-flat-bulleted-list rendering (header/prose,
   --  Abilities, Weaknesses, Combat/Attacks, linked-content
   --  expansion) plus Print_Tail -- everything Terse and Gemtext need
   --  end to end. Does NOT handle Html_In_Rst's nested-table
   --  rendering; Format_Rst.Process_Entity only calls this for Terse
   --  mode (or for any Fragment, regardless of mode -- a Fragment
   --  renders identically under every format, PLAN.md/this package's
   --  callers).

end Ova_Fmt.Format_Common;
