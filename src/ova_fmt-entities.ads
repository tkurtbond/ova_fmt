--  Ova_Fmt.Entities - typed domain records for an OVA character, built
--  by walking a Libfyaml.Nodes.Node once via Load_Entity, following
--  the schema settled on in test-data/*.yaml (see Karis.yaml's header
--  comment for the schema's own rationale, and PLAN.md §4/§6/§9 for
--  the design history).
--
--  Modeled on besm2_fmt.Entities' "parse once, every format backend
--  consumes the same typed data" shape -- but the OVA domain has one
--  structural wrinkle BESM doesn't: an Ability can carry *linked*
--  content (Transformation/Companion's nested sub-Abilities/
--  sub-Weaknesses, Magic's spells, Companion's whole sub-entity).
--  That nesting is exactly one level deep in every example transcribed
--  so far (a Transformation-granted sub-Ability, or a Companion, never
--  itself grants a further nested Companion/Transformation) so it's
--  modeled with a separate, non-recursive Sub_Item type rather than
--  Ability containing further Abilities -- see PLAN.md's build-order
--  notes if a deeper-nesting example ever turns up.

with Ada.Containers.Vectors;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Libfyaml.Nodes;

package Ova_Fmt.Entities is

   -----------------------------------------------------------------
   --  Perks and Flaws: a general Ability modifier (PLAN.md §4's
   --  correction -- attachable to any Ability, not just attacks),
   --  each list item one of:
   --    - a plain name ("Ranged")
   --    - name + repeat count ("Effective", counts-as: 2 -> "x2")
   --    - name + detail ("Concentration", detail: "Aiming")
   --    - name + detail + a chosen-magnitude cost ("Cancel",
   --      detail: "Unliving", cost: -5 -- for Perks/Flaws whose
   --      rulebook cost is a range rather than fixed)
   --  Counts_As and Cost are deliberately distinct fields (not one
   --  "the number after the name" field): one means "taken this many
   --  times," the other "this specific chosen magnitude." No
   --  transcribed example has both on one item.
   -----------------------------------------------------------------

   type Perk_Flaw is record
      Name          : Unbounded_String;
      Has_Detail    : Boolean := False;
      Detail        : Unbounded_String;
      Has_Counts_As : Boolean := False;
      Counts_As     : Integer := 0;
      Has_Cost      : Boolean := False;
      Cost          : Integer := 0;
   end record;

   package Perk_Flaw_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Perk_Flaw);

   -----------------------------------------------------------------
   --  Attacks (combat.attacks[]).
   -----------------------------------------------------------------

   type Attack is record
      Name          : Unbounded_String;
      Perks         : Perk_Flaw_Vectors.Vector;
      Flaws         : Perk_Flaw_Vectors.Vector;
      Has_Affinity  : Boolean := False;
      Affinity      : Unbounded_String;
      Has_Description : Boolean := False;
      Description   : Unbounded_String;
      Roll          : Integer;
      --  A string, not Integer: usually a plain number, but Braun's
      --  joke attack has dx: "1/2" (Armored's own rules text: "reduce
      --  [DX] to 1/2"), so this has to allow non-integer text too.
      Dx            : Unbounded_String;
      Endurance     : Integer;
   end record;

   package Attack_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Attack);

   -----------------------------------------------------------------
   --  combat: block, shared shape between a main entity and a
   --  Companion sub-entity that has its own combat stats (Karis's
   --  Arasuni, Yuu's Fenrir) -- Has_Combat is False for a
   --  prose-simple Companion like Fukiko's Azyrus, who has no
   --  combat: block at all.
   -----------------------------------------------------------------

   type Combat_Stats is record
      Has_Combat    : Boolean := False;
      --  A string, not Integer: usually plain, but a Barrier-granting
      --  Ability gives a character a second, paired Defense value
      --  rendered verbatim (PLAN.md §2.2 -- "4/5"), not split/derived.
      Defense       : Unbounded_String;
      Health        : Integer;
      Endurance     : Integer;
      --  Unlike Defense/Health/Endurance, Threat Value is the one
      --  combat stat an author may skip -- render an em dash when
      --  absent, per the user (PLAN.md, optional-vs-required audit).
      Has_Threat_Value : Boolean := False;
      Threat_Value  : Integer;
      Attacks       : Attack_Vectors.Vector;
   end record;

   -----------------------------------------------------------------
   --  A linked sub-Ability or sub-Weakness (Transformation's/
   --  Companion's nested abilities:/weaknesses: lists) -- flat, not
   --  itself further nestable (see the package comment).
   -----------------------------------------------------------------

   type Sub_Item is record
      Name          : Unbounded_String;
      Level         : Integer;
      Has_Detail    : Boolean := False;
      Detail        : Unbounded_String;
      Perks         : Perk_Flaw_Vectors.Vector;
      Flaws         : Perk_Flaw_Vectors.Vector;
      Has_Endurance : Boolean := False;
      Endurance     : Integer := 0;
      Has_Note      : Boolean := False;
      Note          : Unbounded_String;
   end record;

   package Sub_Item_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Sub_Item);

   -----------------------------------------------------------------
   --  A Magic-ability spell (PLAN.md §2.2's resolved understanding:
   --  a spell has no Level of its own -- it grants access, at that
   --  Ability's own Level, to an Ability the caster already has. Not
   --  a copy/imitation ("mimics") of the Ability -- it IS that
   --  Ability, just reached through Magic instead of bought directly,
   --  per the user).
   -----------------------------------------------------------------

   type Spell is record
      Name      : Unbounded_String;
      Ability   : Unbounded_String;
      Level     : Integer;
      --  A string: usually a plain number of Endurance, but Auren's
      --  Mana Shield is "10+" (an apparently open-ended cost).
      Endurance : Unbounded_String;
   end record;

   package Spell_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Spell);

   -----------------------------------------------------------------
   --  A Companion sub-entity (nested under the granting Ability item,
   --  in a `companion:` key -- PLAN.md §2.3's "one shape, optional
   --  depth" finding: every Companion gets Abilities/Weaknesses;
   --  Combat.Has_Combat is only True when the source actually gives
   --  the companion its own attacks/stats).
   -----------------------------------------------------------------

   type Companion_Record is record
      Name       : Unbounded_String;
      Abilities  : Sub_Item_Vectors.Vector;
      Weaknesses : Sub_Item_Vectors.Vector;
      Combat     : Combat_Stats;
   end record;

   type Companion_Access is access Companion_Record;
   --  Never explicitly freed: ova_fmt is a short-lived batch CLI tool
   --  (parse input, print output, exit), so leaking these along with
   --  the rest of the process's memory at exit is fine -- same
   --  tradeoff plenty of simple batch tools make, not an oversight.

   -----------------------------------------------------------------
   --  A top-level Ability (abilities[] list item). Everything below
   --  Endurance is "linked content" -- at most one of Sub_Abilities/
   --  Sub_Weaknesses (Transformation), Spells (Magic), or Companion
   --  (Companion) is populated for any given real Ability, but
   --  nothing stops more than one being present at the type level.
   -----------------------------------------------------------------

   type Ability is record
      Name           : Unbounded_String;
      Level          : Integer;
      Has_Detail     : Boolean := False;
      Detail         : Unbounded_String;
      Perks          : Perk_Flaw_Vectors.Vector;
      Flaws          : Perk_Flaw_Vectors.Vector;
      Has_Endurance  : Boolean := False;
      Endurance      : Integer := 0;
      Has_Note       : Boolean := False;
      Note           : Unbounded_String;
      Sub_Abilities  : Sub_Item_Vectors.Vector;
      Sub_Weaknesses : Sub_Item_Vectors.Vector;
      Spells         : Spell_Vectors.Vector;
      Companion      : Companion_Access := null;
   end record;

   package Ability_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Ability);

   type Weakness is record
      Name       : Unbounded_String;
      Level      : Integer;
      Has_Detail : Boolean := False;
      Detail     : Unbounded_String;
   end record;

   package Weakness_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Weakness);

   type Note_Item is record
      Header : Unbounded_String;
      Text   : Unbounded_String;
   end record;

   package Note_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Note_Item);

   -----------------------------------------------------------------
   --  fluff: block. A fixed field set (the rulebook's own suggested
   --  fluff fields, PLAN.md §2/§4), not a generic key/value list --
   --  every field is optional (Has_*), and no sample character in
   --  test-data/*.yaml uses `eyes` or `love-interests` consistently
   --  enough to assume they're always present.
   -----------------------------------------------------------------

   type Fluff_Block is record
      Has_Concept        : Boolean := False; Concept        : Unbounded_String;
      Has_Birthday       : Boolean := False; Birthday       : Unbounded_String;
      Has_Age            : Boolean := False; Age            : Unbounded_String;
      Has_Gender         : Boolean := False; Gender         : Unbounded_String;
      Has_Height         : Boolean := False; Height         : Unbounded_String;
      Has_Weight         : Boolean := False; Weight         : Unbounded_String;
      Has_Hair           : Boolean := False; Hair           : Unbounded_String;
      Has_Eyes           : Boolean := False; Eyes           : Unbounded_String;
      Has_Association    : Boolean := False; Association    : Unbounded_String;
      Has_Hobbies        : Boolean := False; Hobbies        : Unbounded_String;
      Has_Favorite_Food  : Boolean := False; Favorite_Food  : Unbounded_String;
      Has_Allies         : Boolean := False; Allies         : Unbounded_String;
      Has_Enemies        : Boolean := False; Enemies        : Unbounded_String;
      Has_Love_Interests : Boolean := False; Love_Interests : Unbounded_String;
   end record;

   type Entity is record
      Has_Name        : Boolean := False; Name        : Unbounded_String;
      Has_Tagline     : Boolean := False; Tagline     : Unbounded_String;
      Has_Summary     : Boolean := False; Summary     : Unbounded_String;
      Has_Background  : Boolean := False; Background  : Unbounded_String;
      Has_Personality : Boolean := False; Personality : Unbounded_String;
      Abilities       : Ability_Vectors.Vector;
      Weaknesses      : Weakness_Vectors.Vector;
      Combat          : Combat_Stats;
      Notes           : Note_Vectors.Vector;
      Has_Fluff       : Boolean := False; Fluff : Fluff_Block;
   end record;

   function Load_Entity (N : Libfyaml.Nodes.Node) return Entity
     with Pre => N.Is_Valid and then N.Is_Mapping;

end Ova_Fmt.Entities;
