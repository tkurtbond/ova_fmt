with Ada.Characters.Handling;
with Ada.Exceptions;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Maps;
with Libfyaml;

package body Ova_Fmt.Entities is

   package Nod renames Libfyaml.Nodes;

   --  Same reasoning as besm2_fmt.Entities: Ada.Strings.Fixed.Trim's
   --  2-argument form only strips spaces, not the trailing newline a
   --  YAML literal block scalar ("background: |") leaves on the
   --  decoded text.
   Whitespace : constant Ada.Strings.Maps.Character_Set :=
     Ada.Strings.Maps.To_Set (" " & ASCII.HT & ASCII.LF & ASCII.CR);

   function Trim_Whitespace (S : String) return String is
     (Ada.Strings.Fixed.Trim (S, Whitespace, Whitespace));

   -----------------------------------------------------------------
   --  Required-field error collection (Ova_Fmt.Entities.Load_Error,
   --  Reset_Errors/Error_Count/Errors). See the .ads for the design
   --  rationale; this is the accumulator and the two typed accessors
   --  (Require_String/Require_Integer) every required-field call
   --  site below goes through instead of a bare String_Value/
   --  Integer_Value.
   -----------------------------------------------------------------

   Recorded_Errors : Load_Error_Vectors.Vector;

   procedure Reset_Errors is
   begin
      Recorded_Errors.Clear;
   end Reset_Errors;

   function Error_Count return Natural is (Natural (Recorded_Errors.Length));

   function Errors return Load_Error_Vectors.Vector is (Recorded_Errors);

   --  Approximates a source position for N -- a mapping node, which
   --  never has a Location of its own (Libfyaml.Nodes.Location is
   --  scalar-only) -- via its own "name" field, when that exists and
   --  is itself a plain scalar with a real position. Every schema
   --  mapping Require_String/Require_Integer are called against has a
   --  "name" field in practice (Ability/Weakness/Attack/Sub_Item/
   --  Spell/Companion/Perk_Flaw all do), so this covers every real
   --  case; a mapping with no "name" of its own just gets no
   --  approximate Location, only a Path (still always exact).
   function Approximate_Location
     (N : Nod.Node; Loc : out Nod.Node_Location) return Boolean
   is
      Sibling : constant Nod.Node := N.Value ("name");
   begin
      if Sibling.Is_Valid and then Sibling.Is_Scalar
        and then Sibling.Has_Location
      then
         Loc := Sibling.Location;
         return True;
      end if;
      return False;
   end Approximate_Location;

   procedure Record_Error (N : Nod.Node; Key : String; Message : String) is
      Err : Load_Error;
      Loc : Nod.Node_Location;
   begin
      Err.Message := To_Unbounded_String (Message);
      Err.Path := To_Unbounded_String (N.Path & "/" & Key);
      if Approximate_Location (N, Loc) then
         Err.Has_Location := True;
         Err.Line := Loc.Line;
         Err.Column := Loc.Column;
      end if;
      Recorded_Errors.Append (Err);
   end Record_Error;

   function Require_String (N : Nod.Node; Key : String) return Unbounded_String is
   begin
      if not N.Has_Key (Key) then
         Record_Error (N, Key, "missing required key """ & Key & """");
         return Null_Unbounded_String;
      end if;
      return To_Unbounded_String (N.String_Value (Key));
   exception
      when E : Libfyaml.Data_Error =>
         Record_Error (N, Key, Ada.Exceptions.Exception_Message (E));
         return Null_Unbounded_String;
   end Require_String;

   function Require_Integer (N : Nod.Node; Key : String) return Integer is
   begin
      if not N.Has_Key (Key) then
         Record_Error (N, Key, "missing required key """ & Key & """");
         return 0;
      end if;
      return N.Integer_Value (Key);
   exception
      when E : Libfyaml.Data_Error =>
         Record_Error (N, Key, Ada.Exceptions.Exception_Message (E));
         return 0;
   end Require_Integer;

   --  Abilities, Weaknesses, Perks, and Flaws are each independently
   --  alphabetized in the rulebook's own presentation (full character
   --  write-ups and NPC Fragments alike, PLAN.md's optional-vs-required
   --  audit) -- same shape as besm2_fmt.Entities' Attribute/Defect/
   --  Skill sorting, and for the same reason: every test-data/**/*.yaml
   --  fixture happens to already be transcribed in alphabetical
   --  order, so this was invisible until checked against a
   --  deliberately out-of-order case (test-data/Unsorted.yaml).
   --  Attacks and Spells are deliberately NOT sorted -- confirmed
   --  from existing test data (Karis's Attacks, Auren's spells) that
   --  those preserve their given order rather than alphabetizing.
   function CI_Less (L, R : Unbounded_String) return Boolean is
     (Ada.Characters.Handling.To_Lower (To_String (L)) <
      Ada.Characters.Handling.To_Lower (To_String (R)));

   function CI_Equal (L, R : Unbounded_String) return Boolean is
     (Ada.Characters.Handling.To_Lower (To_String (L)) =
      Ada.Characters.Handling.To_Lower (To_String (R)));

   --  Ada.Containers.Vectors.Generic_Sorting.Sort is not guaranteed
   --  stable, so a Name-only comparator leaves same-named items (e.g.
   --  Braun's three "Knowledge" Abilities, distinguished only by
   --  Detail: Computer Whiz/Cosplay/Games, Anime, & Manga; Auren's two
   --  "Quirk" Weaknesses) in whatever order the sort algorithm happens
   --  to produce -- confirmed by this session's Braun/Natsuki/Raine/Yuu
   --  regression check, where adding the plain-Name sort reshuffled
   --  those ties unpredictably. Breaking ties by Detail, per the user,
   --  keeps the result deterministic and reproducible. An item with no
   --  Detail sorts as if Detail were "" (Unbounded_String's default),
   --  which is fine: no transcribed example mixes a bare and a
   --  detailed item under the same Name.
   function Ability_CI_Less (L, R : Ability) return Boolean is
     (if CI_Equal (L.Name, R.Name) then CI_Less (L.Detail, R.Detail)
      else CI_Less (L.Name, R.Name));
   package Ability_Sorting is new Ability_Vectors.Generic_Sorting
     ("<" => Ability_CI_Less);

   function Weakness_CI_Less (L, R : Weakness) return Boolean is
     (if CI_Equal (L.Name, R.Name) then CI_Less (L.Detail, R.Detail)
      else CI_Less (L.Name, R.Name));
   package Weakness_Sorting is new Weakness_Vectors.Generic_Sorting
     ("<" => Weakness_CI_Less);

   function Perk_Flaw_CI_Less (L, R : Perk_Flaw) return Boolean is
     (if CI_Equal (L.Name, R.Name) then CI_Less (L.Detail, R.Detail)
      else CI_Less (L.Name, R.Name));
   package Perk_Flaw_Sorting is new Perk_Flaw_Vectors.Generic_Sorting
     ("<" => Perk_Flaw_CI_Less);

   --  Covers both of Sub_Item's two roles (Companion's own
   --  Abilities/Weaknesses, and a Transformation-granting Ability's
   --  linked sub-Abilities/sub-Weaknesses) -- same field, same rule.
   function Sub_Item_CI_Less (L, R : Sub_Item) return Boolean is
     (if CI_Equal (L.Name, R.Name) then CI_Less (L.Detail, R.Detail)
      else CI_Less (L.Name, R.Name));
   package Sub_Item_Sorting is new Sub_Item_Vectors.Generic_Sorting
     ("<" => Sub_Item_CI_Less);

   -----------------------------------------------------------------
   --  overrides: (the .ads's Override_Key).
   -----------------------------------------------------------------

   function Key_Name (K : Override_Key) return String is
     (case K is
         when Roll => "roll", when Dx => "dx", when Endurance => "endurance",
         when Defense => "defense", when Barrier => "barrier",
         when Health => "health", when Threat_Value => "threat-value");

   --  N's `overrides:` list, if any. A list that isn't a sequence, or
   --  an item that isn't one of the Allowed key names, is a recorded
   --  error, like a missing required key: a misspelled name would
   --  otherwise silently drop the `*` from a number.
   function Load_Overrides (N : Nod.Node; Allowed : Override_Set) return Override_Set is
      Result : Override_Set := No_Overrides;
      List   : constant Nod.Node := N.Value ("overrides");

      function Allowed_Names return String is
         Names : Unbounded_String;
      begin
         for K in Override_Key loop
            if Allowed (K) then
               if Length (Names) > 0 then
                  Names := Names & ", ";
               end if;
               Names := Names & Key_Name (K);
            end if;
         end loop;
         return To_String (Names);
      end Allowed_Names;

      procedure Add (Item : Nod.Node) is
      begin
         if Item.Is_Scalar then
            for K in Override_Key loop
               if Allowed (K) and then Item.Scalar_Value = Key_Name (K) then
                  Result (K) := True;
                  return;
               end if;
            end loop;
            Record_Error
              (N, "overrides",
               """" & Item.Scalar_Value & """ is not one of " & Allowed_Names);
         else
            Record_Error (N, "overrides", "an item is not a key name");
         end if;
      end Add;
   begin
      if List.Is_Valid then
         if List.Is_Sequence then
            List.Iterate (Add'Access);
         else
            Record_Error (N, "overrides", "not a sequence of key names");
         end if;
      end if;
      return Result;
   end Load_Overrides;

   function NPC_Kind_Name (K : NPC_Kind) return String is
     (case K is
         when Heroic => "Heroic", when Secondary => "Secondary", when Extra => "Extra");

   --  N's `npc-type:`, which N is known to have. Anything but one of
   --  the three names is a recorded error, like an `overrides:` name:
   --  silently dropping it would lose the type from the output.
   procedure Load_NPC_Type (N : Nod.Node; Has : out Boolean; Kind : out NPC_Kind) is
      use Ada.Characters.Handling;
      Value : constant String := To_Lower (Trim_Whitespace (N.String_Value ("npc-type")));
   begin
      for K in NPC_Kind loop
         if Value = To_Lower (NPC_Kind_Name (K)) then
            Has := True;
            Kind := K;
            return;
         end if;
      end loop;
      Has := False;
      Kind := Heroic;
      Record_Error
        (N, "npc-type",
         """" & N.String_Value ("npc-type") & """ is not one of Heroic, Secondary, Extra");
   exception
      when E : Libfyaml.Data_Error =>
         Has := False;
         Kind := Heroic;
         Record_Error (N, "npc-type", Ada.Exceptions.Exception_Message (E));
   end Load_NPC_Type;

   -----------------------------------------------------------------
   --  Perks/Flaws.
   -----------------------------------------------------------------

   function Load_Perk_Flaw (N : Nod.Node) return Perk_Flaw is
      Result : Perk_Flaw;
   begin
      if N.Is_Scalar then
         Result.Name := To_Unbounded_String (N.Scalar_Value);
      elsif N.Is_Mapping then
         Result.Name := Require_String (N, "name");
         if N.Has_Key ("detail") then
            Result.Has_Detail := True;
            Result.Detail := To_Unbounded_String (N.String_Value ("detail"));
         end if;
         if N.Has_Key ("counts-as") then
            Result.Has_Counts_As := True;
            Result.Counts_As := N.Integer_Value ("counts-as");
         end if;
         if N.Has_Key ("cost") then
            Result.Has_Cost := True;
            Result.Cost := N.Integer_Value ("cost");
         end if;
      else
         raise Program_Error with "unrecognized Perk/Flaw shape";
      end if;
      return Result;
   end Load_Perk_Flaw;

   function Load_Perk_Flaw_List (N : Nod.Node) return Perk_Flaw_Vectors.Vector is
      Result : Perk_Flaw_Vectors.Vector;
      procedure Add (Item : Nod.Node) is
      begin
         Result.Append (Load_Perk_Flaw (Item));
      end Add;
   begin
      N.Iterate (Add'Access);
      Perk_Flaw_Sorting.Sort (Result);
      return Result;
   end Load_Perk_Flaw_List;

   -----------------------------------------------------------------
   --  Attacks / combat: blocks.
   -----------------------------------------------------------------

   function Load_Attack (N : Nod.Node) return Attack is
      Result       : Attack;
      Perks_Node   : constant Nod.Node := N.Value ("perks");
      Flaws_Node   : constant Nod.Node := N.Value ("flaws");
   begin
      Result.Name := Require_String (N, "name");
      if Perks_Node.Is_Valid then
         Result.Perks := Load_Perk_Flaw_List (Perks_Node);
      end if;
      if Flaws_Node.Is_Valid then
         Result.Flaws := Load_Perk_Flaw_List (Flaws_Node);
      end if;
      if N.Has_Key ("affinity") then
         Result.Has_Affinity := True;
         Result.Affinity := To_Unbounded_String (N.String_Value ("affinity"));
      end if;
      if N.Has_Key ("description") then
         Result.Has_Description := True;
         Result.Description :=
           To_Unbounded_String (Trim_Whitespace (N.String_Value ("description")));
      end if;
      Result.Roll := Require_Integer (N, "roll");
      Result.Dx := Require_String (N, "dx");
      Result.Endurance := Require_Integer (N, "endurance");
      if N.Has_Key ("telekinesis") then
         Result.Telekinesis := N.Boolean_Value ("telekinesis");
      end if;
      if N.Has_Key ("transformed") then
         Result.Transformed := N.Boolean_Value ("transformed");
      end if;
      Result.Overrides :=
        Load_Overrides (N, (Roll | Dx | Endurance => True, others => False));
      return Result;
   end Load_Attack;

   function Load_Combat (N : Nod.Node) return Combat_Stats is
      Result       : Combat_Stats;
      Attacks_Node : constant Nod.Node := N.Value ("attacks");
      procedure Add (Item : Nod.Node) is
      begin
         Result.Attacks.Append (Load_Attack (Item));
      end Add;
   begin
      Result.Has_Combat := True;
      --  N (a combat: block) has no "name" field of its own to
      --  approximate a Location from -- these three errors, if any,
      --  get Path only (e.g. "/2/combat/health"), still exact.
      Result.Defense := Require_String (N, "defense");
      Result.Health := Require_Integer (N, "health");
      Result.Endurance := Require_Integer (N, "endurance");
      if N.Has_Key ("threat-value") then
         Result.Has_Threat_Value := True;
         Result.Threat_Value := N.Integer_Value ("threat-value");
      end if;
      if Attacks_Node.Is_Valid then
         Attacks_Node.Iterate (Add'Access);
      end if;
      if N.Has_Key ("notes") then
         Result.Has_Notes := True;
         Result.Notes := To_Unbounded_String (Trim_Whitespace (N.String_Value ("notes")));
      end if;
      if N.Has_Key ("transformed") then
         Result.Transformed := N.Boolean_Value ("transformed");
      end if;
      Result.Overrides :=
        Load_Overrides (N, (Roll | Dx => False, others => True));
      return Result;
   end Load_Combat;

   -----------------------------------------------------------------
   --  Sub_Item (a Transformation/Companion nested ability or
   --  weakness), Spell (a Magic ability's spell), Companion.
   -----------------------------------------------------------------

   function Load_Sub_Item (N : Nod.Node) return Sub_Item is
      Result     : Sub_Item;
      Perks_Node : constant Nod.Node := N.Value ("perks");
      Flaws_Node : constant Nod.Node := N.Value ("flaws");
   begin
      Result.Name := Require_String (N, "name");
      Result.Level := Require_Integer (N, "level");
      if N.Has_Key ("detail") then
         Result.Has_Detail := True;
         Result.Detail := To_Unbounded_String (N.String_Value ("detail"));
      end if;
      if Perks_Node.Is_Valid then
         Result.Perks := Load_Perk_Flaw_List (Perks_Node);
      end if;
      if Flaws_Node.Is_Valid then
         Result.Flaws := Load_Perk_Flaw_List (Flaws_Node);
      end if;
      if N.Has_Key ("endurance") then
         Result.Has_Endurance := True;
         Result.Endurance := N.Integer_Value ("endurance");
      end if;
      if N.Has_Key ("note") then
         Result.Has_Note := True;
         Result.Note := To_Unbounded_String (N.String_Value ("note"));
      end if;
      if N.Has_Key ("threat-value-half") then
         Result.Has_Threat_Value_Half := True;
         Result.Threat_Value_Half := N.Boolean_Value ("threat-value-half");
      end if;
      Result.Overrides := Load_Overrides (N, (Endurance => True, others => False));
      return Result;
   end Load_Sub_Item;

   function Load_Sub_Item_List (N : Nod.Node) return Sub_Item_Vectors.Vector is
      Result : Sub_Item_Vectors.Vector;
      procedure Add (Item : Nod.Node) is
      begin
         Result.Append (Load_Sub_Item (Item));
      end Add;
   begin
      N.Iterate (Add'Access);
      Sub_Item_Sorting.Sort (Result);
      return Result;
   end Load_Sub_Item_List;

   function Load_Spell (N : Nod.Node) return Spell is
      --  A sequential function body, not an aggregate expression:
      --  Ada doesn't guarantee left-to-right evaluation of a record
      --  aggregate's components, and these calls have the side effect
      --  of recording errors in field-declaration order.
      Result : Spell;
   begin
      Result.Name := Require_String (N, "name");
      Result.Ability := Require_String (N, "ability");
      Result.Level := Require_Integer (N, "level");
      Result.Endurance := Require_String (N, "endurance");
      Result.Overrides := Load_Overrides (N, (Endurance => True, others => False));
      return Result;
   end Load_Spell;

   function Load_Sub_Entity (N : Nod.Node; Label : String) return Sub_Entity_Access is
      Result           : constant Sub_Entity_Access := new Sub_Entity_Record;
      Abilities_Node   : constant Nod.Node := N.Value ("abilities");
      Weaknesses_Node  : constant Nod.Node := N.Value ("weaknesses");
      Combat_Node      : constant Nod.Node := N.Value ("combat");
   begin
      Result.Label := To_Unbounded_String (Label);
      Result.Name := Require_String (N, "name");
      if N.Has_Key ("fragment") then
         Result.Is_Fragment := N.Boolean_Value ("fragment");
      end if;
      if Abilities_Node.Is_Valid then
         Result.Abilities := Load_Sub_Item_List (Abilities_Node);
      end if;
      if Weaknesses_Node.Is_Valid then
         Result.Weaknesses := Load_Sub_Item_List (Weaknesses_Node);
      end if;
      if Combat_Node.Is_Valid then
         Result.Combat := Load_Combat (Combat_Node);
      end if;
      return Result;
   end Load_Sub_Entity;

   -----------------------------------------------------------------
   --  Top-level Ability / Weakness / Note.
   -----------------------------------------------------------------

   function Load_Ability (N : Nod.Node) return Ability is
      Result              : Ability;
      Perks_Node          : constant Nod.Node := N.Value ("perks");
      Flaws_Node          : constant Nod.Node := N.Value ("flaws");
      Sub_Abilities_Node  : constant Nod.Node := N.Value ("abilities");
      Sub_Weaknesses_Node : constant Nod.Node := N.Value ("weaknesses");
      Spells_Node         : constant Nod.Node := N.Value ("spells");
      Companion_Node      : constant Nod.Node := N.Value ("companion");
      Vehicle_Node        : constant Nod.Node := N.Value ("vehicle");
      procedure Add_Spell (Item : Nod.Node) is
      begin
         Result.Spells.Append (Load_Spell (Item));
      end Add_Spell;
   begin
      Result.Name := Require_String (N, "name");
      Result.Level := Require_Integer (N, "level");
      if N.Has_Key ("detail") then
         Result.Has_Detail := True;
         Result.Detail := To_Unbounded_String (N.String_Value ("detail"));
      end if;
      if Perks_Node.Is_Valid then
         Result.Perks := Load_Perk_Flaw_List (Perks_Node);
      end if;
      if Flaws_Node.Is_Valid then
         Result.Flaws := Load_Perk_Flaw_List (Flaws_Node);
      end if;
      if N.Has_Key ("endurance") then
         Result.Has_Endurance := True;
         Result.Endurance := N.Integer_Value ("endurance");
      end if;
      if N.Has_Key ("note") then
         Result.Has_Note := True;
         Result.Note := To_Unbounded_String (N.String_Value ("note"));
      end if;
      if N.Has_Key ("threat-value-half") then
         Result.Has_Threat_Value_Half := True;
         Result.Threat_Value_Half := N.Boolean_Value ("threat-value-half");
      end if;
      Result.Overrides := Load_Overrides (N, (Endurance => True, others => False));
      if Sub_Abilities_Node.Is_Valid then
         Result.Sub_Abilities := Load_Sub_Item_List (Sub_Abilities_Node);
      end if;
      if Sub_Weaknesses_Node.Is_Valid then
         Result.Sub_Weaknesses := Load_Sub_Item_List (Sub_Weaknesses_Node);
      end if;
      if Spells_Node.Is_Valid then
         Spells_Node.Iterate (Add_Spell'Access);
      end if;
      if Companion_Node.Is_Valid then
         Result.Sub_Entity := Load_Sub_Entity (Companion_Node, "Companion");
      elsif Vehicle_Node.Is_Valid then
         Result.Sub_Entity := Load_Sub_Entity (Vehicle_Node, "Vehicle");
      end if;
      return Result;
   end Load_Ability;

   function Load_Weakness (N : Nod.Node) return Weakness is
      Result : Weakness;
   begin
      Result.Name := Require_String (N, "name");
      Result.Level := Require_Integer (N, "level");
      if N.Has_Key ("detail") then
         Result.Has_Detail := True;
         Result.Detail := To_Unbounded_String (N.String_Value ("detail"));
      end if;
      return Result;
   end Load_Weakness;

   function Load_Note (N : Nod.Node) return Note_Item is
      --  Sequential body, not an aggregate (same reasoning as
      --  Load_Spell). A Note has no "name" field of its own, so
      --  Approximate_Location never finds a sibling to anchor a
      --  Location to here -- Path only, still exact.
      Result : Note_Item;
   begin
      Result.Header := Require_String (N, "header");
      Result.Text :=
        To_Unbounded_String (Trim_Whitespace (To_String (Require_String (N, "text"))));
      return Result;
   end Load_Note;

   -----------------------------------------------------------------
   --  fluff:
   -----------------------------------------------------------------

   function Load_Fluff (N : Nod.Node) return Fluff_Block is
      Result : Fluff_Block;

      procedure Set
        (Has : in out Boolean; Val : in out Unbounded_String; Key : String)
      is
      begin
         if N.Has_Key (Key) then
            Has := True;
            Val := To_Unbounded_String (N.String_Value (Key));
         end if;
      end Set;
   begin
      Set (Result.Has_Concept, Result.Concept, "concept");
      Set (Result.Has_Birthday, Result.Birthday, "birthday");
      Set (Result.Has_Age, Result.Age, "age");
      Set (Result.Has_Gender, Result.Gender, "gender");
      Set (Result.Has_Height, Result.Height, "height");
      Set (Result.Has_Weight, Result.Weight, "weight");
      Set (Result.Has_Hair, Result.Hair, "hair");
      Set (Result.Has_Eyes, Result.Eyes, "eyes");
      Set (Result.Has_Association, Result.Association, "association");
      Set (Result.Has_Hobbies, Result.Hobbies, "hobbies");
      Set (Result.Has_Favorite_Food, Result.Favorite_Food, "favorite-food");
      Set (Result.Has_Allies, Result.Allies, "allies");
      Set (Result.Has_Enemies, Result.Enemies, "enemies");
      Set (Result.Has_Love_Interests, Result.Love_Interests, "love-interests");
      return Result;
   end Load_Fluff;

   -----------------------------------------------------------------
   --  options:
   -----------------------------------------------------------------

   function Load_Options (N : Nod.Node) return Options_Block is
      Result : Options_Block;
   begin
      if N.Has_Key ("base-zero") then
         Result.Has_Base_Zero := True;
         Result.Base_Zero := N.Integer_Value ("base-zero");
      end if;
      if N.Has_Key ("power-ceiling") then
         Result.Has_Power_Ceiling := True;
         Result.Power_Ceiling := N.Integer_Value ("power-ceiling");
      end if;
      if N.Has_Key ("starting-levels") then
         Result.Has_Starting_Levels := True;
         Result.Starting_Levels := N.Integer_Value ("starting-levels");
      end if;
      if N.Has_Key ("scaled-cost") then
         Result.Scaled_Cost := N.Boolean_Value ("scaled-cost");
      end if;
      if N.Has_Key ("half-cost-knowledge") then
         Result.Half_Cost_Knowledge := N.Boolean_Value ("half-cost-knowledge");
      end if;
      if N.Has_Key ("combined-effectiveness") then
         Result.Combined_Effectiveness := N.Boolean_Value ("combined-effectiveness");
      end if;
      return Result;
   end Load_Options;

   -----------------------------------------------------------------
   --  Load_Entity.
   -----------------------------------------------------------------

   function Load_Entity (N : Nod.Node) return Entity is
      Result         : Entity;
      Abilities_Node  : constant Nod.Node := N.Value ("abilities");
      Weaknesses_Node : constant Nod.Node := N.Value ("weaknesses");
      Combat_Node     : constant Nod.Node := N.Value ("combat");
      Notes_Node      : constant Nod.Node := N.Value ("notes");
      Fluff_Node      : constant Nod.Node := N.Value ("fluff");
      Options_Node    : constant Nod.Node := N.Value ("options");

      procedure Add_Ability (Item : Nod.Node) is
      begin
         Result.Abilities.Append (Load_Ability (Item));
      end Add_Ability;

      procedure Add_Weakness (Item : Nod.Node) is
      begin
         Result.Weaknesses.Append (Load_Weakness (Item));
      end Add_Weakness;

      procedure Add_Note (Item : Nod.Node) is
      begin
         Result.Notes.Append (Load_Note (Item));
      end Add_Note;
   begin
      Result.Name := Require_String (N, "name");

      if N.Has_Key ("fragment") then
         Result.Is_Fragment := N.Boolean_Value ("fragment");
      end if;

      Result.Has_Player := N.Has_Key ("player");
      if Result.Has_Player then
         Result.Player := To_Unbounded_String (N.String_Value ("player"));
      end if;

      Result.Has_Tagline := N.Has_Key ("tagline");
      if Result.Has_Tagline then
         Result.Tagline :=
           To_Unbounded_String (Trim_Whitespace (N.String_Value ("tagline")));
      end if;

      Result.Has_Summary := N.Has_Key ("summary");
      if Result.Has_Summary then
         Result.Summary :=
           To_Unbounded_String (Trim_Whitespace (N.String_Value ("summary")));
      end if;

      Result.Has_Background := N.Has_Key ("background");
      if Result.Has_Background then
         Result.Background :=
           To_Unbounded_String (Trim_Whitespace (N.String_Value ("background")));
      end if;

      Result.Has_Appearance := N.Has_Key ("appearance");
      if Result.Has_Appearance then
         Result.Appearance :=
           To_Unbounded_String (Trim_Whitespace (N.String_Value ("appearance")));
      end if;

      Result.Has_Personality := N.Has_Key ("personality");
      if Result.Has_Personality then
         Result.Personality :=
           To_Unbounded_String (Trim_Whitespace (N.String_Value ("personality")));
      end if;

      Result.Has_Character_Hooks := N.Has_Key ("character-hooks");
      if Result.Has_Character_Hooks then
         Result.Character_Hooks :=
           To_Unbounded_String (Trim_Whitespace (N.String_Value ("character-hooks")));
      end if;

      if N.Has_Key ("npc-type") then
         Load_NPC_Type (N, Result.Has_NPC_Type, Result.NPC_Type);
      end if;

      Result.Has_Other_Notes := N.Has_Key ("other-notes");
      if Result.Has_Other_Notes then
         Result.Other_Notes :=
           To_Unbounded_String (Trim_Whitespace (N.String_Value ("other-notes")));
      end if;

      Result.Has_Portrait := N.Has_Key ("portrait");
      if Result.Has_Portrait then
         Result.Portrait := To_Unbounded_String (N.String_Value ("portrait"));
      end if;

      if Abilities_Node.Is_Valid then
         Abilities_Node.Iterate (Add_Ability'Access);
         Ability_Sorting.Sort (Result.Abilities);
      end if;

      if Weaknesses_Node.Is_Valid then
         Weaknesses_Node.Iterate (Add_Weakness'Access);
         Weakness_Sorting.Sort (Result.Weaknesses);
      end if;

      if Combat_Node.Is_Valid then
         Result.Combat := Load_Combat (Combat_Node);
      end if;

      if Notes_Node.Is_Valid then
         Notes_Node.Iterate (Add_Note'Access);
      end if;

      if Fluff_Node.Is_Valid then
         Result.Has_Fluff := True;
         Result.Fluff := Load_Fluff (Fluff_Node);
      end if;

      if Options_Node.Is_Valid then
         Result.Has_Options := True;
         Result.Options := Load_Options (Options_Node);
      end if;

      return Result;
   end Load_Entity;

end Ova_Fmt.Entities;
