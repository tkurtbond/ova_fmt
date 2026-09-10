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
   --  A full nested sub-entity (nested under the granting Ability
   --  item), one level deep -- PLAN.md §2.3's "one shape, optional
   --  depth" finding: every one of these gets Abilities/Weaknesses;
   --  Combat.Has_Combat is only True when the source actually gives
   --  it its own attacks/stats. Covers both of this shape's two real
   --  cases, per the user: Companion (a `companion:` key) and Vehicle
   --  (a `vehicle:` key, rulebook p. 63-64, "Vehicle (Mecha)") --
   --  confirmed structurally identical (a Vehicle's own Abilities/
   --  Weaknesses aren't necessarily cumulative with the pilot's,
   --  same as Companion; it has its own separate Health/Endurance,
   --  same Combat_Stats shape Companion already uses). Label ("
   --  Companion" or "Vehicle") records which, purely so
   --  Format_Common/Format_Rst can print the right heading -- nothing
   --  else depends on which one it is.
   -----------------------------------------------------------------

   type Sub_Entity_Record is record
      Label      : Unbounded_String;
      Name       : Unbounded_String;
      Abilities  : Sub_Item_Vectors.Vector;
      Weaknesses : Sub_Item_Vectors.Vector;
      Combat     : Combat_Stats;
   end record;

   type Sub_Entity_Access is access Sub_Entity_Record;
   --  Never explicitly freed: ova_fmt is a short-lived batch CLI tool
   --  (parse input, print output, exit), so leaking these along with
   --  the rest of the process's memory at exit is fine -- same
   --  tradeoff plenty of simple batch tools make, not an oversight.

   -----------------------------------------------------------------
   --  A top-level Ability (abilities[] list item). Everything below
   --  Endurance is "linked content" -- at most one of Sub_Abilities/
   --  Sub_Weaknesses (Transformation), Spells (Magic), or Sub_Entity
   --  (Companion/Vehicle) is populated for any given real Ability,
   --  but nothing stops more than one being present at the type
   --  level.
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
      Sub_Entity     : Sub_Entity_Access := null;
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

   -----------------------------------------------------------------
   --  options: block. Character-creation limiting rules (rulebook
   --  p. 20-21, "Limiting the Character") -- GM/author metadata about
   --  how the character was built, not part of its stats. Each of the
   --  four is independently optional; Base_Zero/Power_Ceiling carry a
   --  GM-set number (Base Zero's default tolerance is 5 per the
   --  rulebook, but an author who wants the default doesn't need to
   --  write anything -- the key is simply absent), Scaled_Cost/
   --  Combined_Effectiveness are flags (their mechanics are fixed by
   --  the rules text, nothing to parameterize). Rendered only when
   --  asked for (-O/--options, Config.Show_Options), per the user:
   --  useful to a player updating their character or a GM, but not
   --  something a player-facing write-up needs by default.
   -----------------------------------------------------------------

   type Options_Block is record
      Has_Base_Zero              : Boolean := False; Base_Zero     : Integer;
      Has_Power_Ceiling          : Boolean := False; Power_Ceiling : Integer;
      Scaled_Cost                : Boolean := False;
      Combined_Effectiveness     : Boolean := False;
   end record;

   type Entity is record
      --  Required, unlike every other Entity-level field below --
      --  per the user, an NPC Fragment (Is_Fragment) is otherwise the
      --  same shape as a full character, missing most of these
      --  optional fields, but it has to have a Name regardless.
      Name            : Unbounded_String;
      Has_Tagline     : Boolean := False; Tagline     : Unbounded_String;
      Has_Summary     : Boolean := False; Summary     : Unbounded_String;
      Has_Background  : Boolean := False; Background  : Unbounded_String;
      Has_Personality : Boolean := False; Personality : Unbounded_String;
      Abilities       : Ability_Vectors.Vector;
      Weaknesses      : Weakness_Vectors.Vector;
      Combat          : Combat_Stats;
      Notes           : Note_Vectors.Vector;
      Has_Fluff       : Boolean := False; Fluff : Fluff_Block;
      Has_Options     : Boolean := False; Options : Options_Block;
      --  NPC Fragment (rulebook p. 142, "NPC Fragments"): a minor
      --  NPC's minimal write-up -- the character's name embedded
      --  (and, by rulebook convention, bolded by the author) within
      --  Background's own prose rather than a separate title/header,
      --  and a single comma-joined "Attributes:" line instead of
      --  separate labeled Abilities/Weaknesses sections. An explicit
      --  marker, per the user, rather than inferred from which
      --  optional fields happen to be absent.
      Is_Fragment     : Boolean := False;
   end record;

   function Load_Entity (N : Libfyaml.Nodes.Node) return Entity
     with Pre => N.Is_Valid and then N.Is_Mapping;

   package Entity_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Entity);
   --  Lets a caller (Ova_Fmt_Main) load every entity in a file first,
   --  checking Error_Count only once the whole file's been walked,
   --  before rendering any of it -- so a problem discovered in, say,
   --  the third entity doesn't leave the first two already written to
   --  stdout/the output file. See Reset_Errors/Error_Count/Errors
   --  below.

   -----------------------------------------------------------------
   --  Required-field error collection.
   --
   --  A genuinely required field that's missing or malformed no
   --  longer raises Libfyaml.Missing_Key/Data_Error straight through
   --  Load_Entity (which would abort the whole file on the first
   --  problem found) -- it's recorded here instead, with a
   --  placeholder value substituted so loading keeps going and can
   --  turn up every other problem in the same file, per the user.
   --
   --  Two independent ways to say *where*, both from alibfyaml's
   --  Libfyaml.Nodes: Path (e.g. "/1/abilities/2/level") always
   --  works, since it's purely structural; Location (a source
   --  line/column) is only ever an approximation here, via the
   --  problem's enclosing item's own "name" field, since the missing
   --  key itself has no scalar/token of its own to report a real
   --  position for (see alibfyaml's example_missing_field.adb, the
   --  worked example this mirrors).
   -----------------------------------------------------------------

   type Load_Error is record
      Message      : Unbounded_String;
      Path         : Unbounded_String;
      Has_Location : Boolean := False;
      Line, Column : Positive := 1;
   end record;

   package Load_Error_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Load_Error);

   procedure Reset_Errors;
   --  Clear all recorded errors. Call before loading each new file --
   --  errors accumulate across every Load_Entity call otherwise, per
   --  the user wanting every problem in a file collected together,
   --  not just the first entity's.

   function Error_Count return Natural;

   function Errors return Load_Error_Vectors.Vector;

end Ova_Fmt.Entities;
