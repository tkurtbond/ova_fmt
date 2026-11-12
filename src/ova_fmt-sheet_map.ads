--  Ova_Fmt.Sheet_Map - an entity mapped onto the official OVA
--  character sheet's fixed slots: 17 Ability lines, 17 Weakness lines
--  and 4 attack boxes on page 1 (the poc port's PLAN.md, "The
--  official character sheet as PDF").
--
--  Shared by the sheet formats: Ova_Fmt.Format_Form (-X) now, and
--  the typeset sheet (-S) later. This package decides what goes on
--  which copy of page 1 and in what order; it measures nothing. A
--  format that wraps a row onto more than one line (-S) will need
--  Fill to count rows by height instead of one per line.
--
--  The rows follow the rulebook's Sample Characters ("Sub-Abilities,
--  as the rulebook prints them" in that PLAN.md):
--    - an Ability's Transformation rows (its granted Abilities, then
--      its granted Weaknesses) and its spells go under it, in the
--      Abilities column, as Miho's, Fukiko's and Auren's do;
--    - a parent and its rows are one block, kept together: a block
--      that doesn't fit in what is left of the column moves whole to
--      the next copy, and only one taller than the column is split,
--      the next copy repeating the parent as "Name (continued)";
--    - a Companion or Vehicle is one row in its parent's column, and
--      its own boxes go on copies of page 1 of their own, titled
--      "Arasuni (Karis's Companion)" -- a Fragment one too, so that
--      every sub-entity is handled alike.
--  What isn't a slot (the prose, an item's note, an attack's
--  description) is left to the format.

with Ada.Containers.Vectors;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ova_Fmt.Entities;

package Ova_Fmt.Sheet_Map is

   Ability_Slots  : constant := 17;
   Weakness_Slots : constant := 17;
   Attack_Slots   : constant := 4;

   --  Item: an Ability or Weakness of the sheet's owner, its Level in
   --  the Dice column. Sub: an Ability or Weakness granted by the
   --  Item above it (a Transformation's), its Level in the name
   --  column. Spell: a spell of the Item above it, with no Level.
   type Row_Kind is (Item, Sub, Spell);

   type Row is record
      Kind     : Row_Kind := Item;
      Level    : Unbounded_String;  --  "+2"; "" for a Spell, or a repeated parent
      Text     : Unbounded_String;  --  "Barrier [Perks: ...; 5 Endurance]"
      --  The item's `note:`, as "Barrier: note text", for the format
      --  to place off the row: the rulebook doesn't print it there.
      Has_Note : Boolean := False;
      Note     : Unbounded_String;
   end record;

   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Row);

   type Attack_Slot is record
      Name            : Unbounded_String;
      Clause          : Unbounded_String;  --  "Affinity: Love; Perks: Ranged", or ""
      Roll, Dx        : Unbounded_String;
      Endurance       : Unbounded_String;
      Has_Description : Boolean := False;
      Description     : Unbounded_String;
   end record;

   package Attack_Slot_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Attack_Slot);

   --  One copy of page 1.
   type Page_1 is record
      Owner      : Unbounded_String;  --  "Fukiko", "Arasuni": whose boxes these are
      Title      : Unbounded_String;  --  the Character Name field
      Continued  : Boolean := False;  --  not the owner's first copy
      Has_Player : Boolean := False;
      Player     : Unbounded_String;
      Abilities  : Row_Vectors.Vector;  --  at most Ability_Slots
      Weaknesses : Row_Vectors.Vector;  --  at most Weakness_Slots
      Attacks    : Attack_Slot_Vectors.Vector;  --  at most Attack_Slots
      --  The Combat Stats boxes, on the owner's first copy only.
      Has_Stats  : Boolean := False;
      Defense, Health, Endurance, Threat_Value : Unbounded_String;  --  TV "" if none
      NPC_Type   : Unbounded_String;  --  "Heroic", or ""
      Has_Combat_Notes : Boolean := False;
      Combat_Notes     : Unbounded_String;
   end record;

   package Page_1_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Page_1);

   function Fill (E : Entities.Entity) return Page_1_Vectors.Vector;
   --  E's copies of page 1: its own first (at least one, titled with
   --  its name; any more "Name (continued)"), then each Companion's
   --  or Vehicle's, in the order of the Abilities granting them. The
   --  numbers are as in Raw tables: ASCII `*` for an override.

end Ova_Fmt.Sheet_Map;
