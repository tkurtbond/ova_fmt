--  Ova_Fmt.Entities - typed domain records for an OVA character, built
--  by walking a Libfyaml.Nodes.Node once via Load_Entity, following
--  the schema settled on in test-data/sample-pcs/*.yaml (see
--  Karis.yaml's header comment for the schema's own rationale, and
--  PLAN.md §4/§6/§9 for the design history).
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
   --  `overrides:` (PLAN.md §9 step 9): the numbers in a mapping that
   --  the character generator (po_ova_cg) computes but the user set
   --  by hand -- a sequence of those numbers' key names, e.g.
   --  `overrides: [roll, dx]` on an attack. Each mapping accepts only
   --  the keys it has a computed number for (Allowed in
   --  Load_Overrides): an attack roll/dx/endurance; combat:
   --  defense/barrier/health/endurance/threat-value, barrier being
   --  the second half of a paired "4/5" Defense; an Ability, Sub_Item
   --  or Spell endurance. Anything else is a load error. The
   --  formatters print an overridden number with a `*` after it.
   -----------------------------------------------------------------

   type Override_Key is (Roll, Dx, Endurance, Defense, Barrier, Health, Threat_Value);
   type Override_Set is array (Override_Key) of Boolean;
   No_Overrides : constant Override_Set := (others => False);

   function Key_Name (K : Override_Key) return String;
   --  The key's YAML spelling ("threat-value").

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
      --  Inputs to the generator's calculation (PLAN.md §9 step 9),
      --  not printed: the numbers above already include them.
      --  Telekinesis: made with Telekinesis, which adds to its DX
      --  (rulebook p. 62). Transformed: made in the transformed form
      --  (p. 63), so it counts toward TV only when the combat block
      --  is the transformed form's too.
      Telekinesis   : Boolean := False;
      Transformed   : Boolean := False;
      Overrides     : Override_Set := No_Overrides;
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
      --  The character sheet's Combat Notes ("Damage, Complications,
      --  Etc.", PLAN.md §5), text printed after the attacks.
      Has_Notes     : Boolean := False;
      Notes         : Unbounded_String;
      --  The block is the transformed form's (Fukiko's sheet shows
      --  her as Myu Myu): an input to the generator's calculation,
      --  not printed, like Attack.Transformed.
      Transformed   : Boolean := False;
      Overrides     : Override_Set := No_Overrides;
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
      --  `threat-value-half`: whether half the Ability's Level counts
      --  toward TV (rulebook p. 124). Absent, the generator decides
      --  from its rules tables; printed only when true, under -O.
      Has_Threat_Value_Half : Boolean := False;
      Threat_Value_Half     : Boolean := False;
      Overrides     : Override_Set := No_Overrides;
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
      Overrides : Override_Set := No_Overrides;
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
   --
   --  Is_Fragment (`fragment: true` on the `companion:`/`vehicle:`
   --  block itself, mirroring Entity.Is_Fragment's own key): per the
   --  user, a simple sub-entity (Azyrus-scale -- a short Abilities/
   --  Weaknesses list, no combat: block, nothing worth a full separate
   --  section for) can opt into the same flat NPC-Fragment-style
   --  rendering a standalone Fragment entity gets, instead of every
   --  backend's normal full treatment (a bulleted sub-section in
   --  Terse/Gemtext/h-m-m; nested <table>s in Html_In_Rst; its own
   --  separate side-by-side-tables-plus-Combat-box section in
   --  Groff_In_Rst). False by default -- opt-in, same polarity as
   --  every other rendering-shape choice in this codebase.
   -----------------------------------------------------------------

   type Sub_Entity_Record is record
      Label       : Unbounded_String;
      Name        : Unbounded_String;
      Is_Fragment : Boolean := False;
      Abilities   : Sub_Item_Vectors.Vector;
      Weaknesses  : Sub_Item_Vectors.Vector;
      Combat      : Combat_Stats;
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
      --  As Sub_Item's.
      Has_Threat_Value_Half : Boolean := False;
      Threat_Value_Half     : Boolean := False;
      Overrides      : Override_Set := No_Overrides;
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
   --  test-data/sample-pcs/*.yaml uses `eyes` or `love-interests`
   --  consistently enough to assume they're always present.
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
   --
   --  Two more (PLAN.md §9 step 9): Starting_Levels, Power Ceiling's
   --  starting levels (p. 21), and Half_Cost_Knowledge, Knowledge and
   --  Ineptitude at half cost.
   -----------------------------------------------------------------

   type Options_Block is record
      Has_Base_Zero              : Boolean := False; Base_Zero     : Integer;
      Has_Power_Ceiling          : Boolean := False; Power_Ceiling : Integer;
      Has_Starting_Levels        : Boolean := False; Starting_Levels : Integer;
      Scaled_Cost                : Boolean := False;
      Half_Cost_Knowledge        : Boolean := False;
      Combined_Effectiveness     : Boolean := False;
   end record;

   -----------------------------------------------------------------
   --  `npc-type:` (rulebook p. 133, "Using NPC Type"): an NPC's
   --  importance to the story, which sets its Health and Endurance
   --  totals. The Sample NPCs print it after "Attacks & Combat
   --  Stats", e.g. "(HEROIC)"; a minion's "Attributes (Secondary):".
   --  Matched case-insensitively; anything else is a load error.
   -----------------------------------------------------------------

   type NPC_Kind is (Heroic, Secondary, Extra);

   function NPC_Kind_Name (K : NPC_Kind) return String;
   --  The rulebook's capitalization ("Heroic").

   type Entity is record
      --  Required, unlike every other Entity-level field below --
      --  per the user, an NPC Fragment (Is_Fragment) is otherwise the
      --  same shape as a full character, missing most of these
      --  optional fields, but it has to have a Name regardless.
      Name            : Unbounded_String;
      --  The rest of the character sheet's fields (PLAN.md §5, §9
      --  step 9): the Player Name, printed beside the name; the
      --  Appearance and Other Notes text; and the portrait image's
      --  path, relative to the YAML file, printed only by Html_In_Rst.
      Has_Player      : Boolean := False; Player      : Unbounded_String;
      Has_Tagline     : Boolean := False; Tagline     : Unbounded_String;
      Has_Summary     : Boolean := False; Summary     : Unbounded_String;
      Has_Background  : Boolean := False; Background  : Unbounded_String;
      Has_Appearance  : Boolean := False; Appearance  : Unbounded_String;
      Has_Personality : Boolean := False; Personality : Unbounded_String;
      --  The Sample NPCs' "Character Hooks" paragraph (p. 134-141):
      --  ways to bring the character into a story.
      Has_Character_Hooks : Boolean := False; Character_Hooks : Unbounded_String;
      Has_NPC_Type    : Boolean := False; NPC_Type    : NPC_Kind := Heroic;
      Has_Other_Notes : Boolean := False; Other_Notes : Unbounded_String;
      Has_Portrait    : Boolean := False; Portrait    : Unbounded_String;
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
