with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Maps;

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
   --  Perks/Flaws.
   -----------------------------------------------------------------

   function Load_Perk_Flaw (N : Nod.Node) return Perk_Flaw is
      Result : Perk_Flaw;
   begin
      if N.Is_Scalar then
         Result.Name := To_Unbounded_String (N.Scalar_Value);
      elsif N.Is_Mapping then
         Result.Name := To_Unbounded_String (N.String_Value ("name"));
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
      Result.Name := To_Unbounded_String (N.String_Value ("name"));
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
      Result.Roll := N.Integer_Value ("roll");
      Result.Dx := To_Unbounded_String (N.String_Value ("dx"));
      Result.Endurance := N.Integer_Value ("endurance");
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
      Result.Defense := To_Unbounded_String (N.String_Value ("defense"));
      Result.Health := N.Integer_Value ("health");
      Result.Endurance := N.Integer_Value ("endurance");
      Result.Threat_Value := N.Integer_Value ("threat-value");
      if Attacks_Node.Is_Valid then
         Attacks_Node.Iterate (Add'Access);
      end if;
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
      Result.Name := To_Unbounded_String (N.String_Value ("name"));
      Result.Level := N.Integer_Value ("level");
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
      return Result;
   end Load_Sub_Item_List;

   function Load_Spell (N : Nod.Node) return Spell is
     (Name      => To_Unbounded_String (N.String_Value ("name")),
      Mimics    => To_Unbounded_String (N.String_Value ("mimics")),
      Level     => N.Integer_Value ("level"),
      Endurance => To_Unbounded_String (N.String_Value ("endurance")));

   function Load_Companion (N : Nod.Node) return Companion_Access is
      Result           : constant Companion_Access := new Companion_Record;
      Abilities_Node   : constant Nod.Node := N.Value ("abilities");
      Weaknesses_Node  : constant Nod.Node := N.Value ("weaknesses");
      Combat_Node      : constant Nod.Node := N.Value ("combat");
   begin
      Result.Name := To_Unbounded_String (N.String_Value ("name"));
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
   end Load_Companion;

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
      procedure Add_Spell (Item : Nod.Node) is
      begin
         Result.Spells.Append (Load_Spell (Item));
      end Add_Spell;
   begin
      Result.Name := To_Unbounded_String (N.String_Value ("name"));
      Result.Level := N.Integer_Value ("level");
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
         Result.Companion := Load_Companion (Companion_Node);
      end if;
      return Result;
   end Load_Ability;

   function Load_Weakness (N : Nod.Node) return Weakness is
      Result : Weakness;
   begin
      Result.Name := To_Unbounded_String (N.String_Value ("name"));
      Result.Level := N.Integer_Value ("level");
      if N.Has_Key ("detail") then
         Result.Has_Detail := True;
         Result.Detail := To_Unbounded_String (N.String_Value ("detail"));
      end if;
      return Result;
   end Load_Weakness;

   function Load_Note (N : Nod.Node) return Note_Item is
     (Header => To_Unbounded_String (N.String_Value ("header")),
      Text   => To_Unbounded_String (Trim_Whitespace (N.String_Value ("text"))));

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
   --  Load_Entity.
   -----------------------------------------------------------------

   function Load_Entity (N : Nod.Node) return Entity is
      Result         : Entity;
      Abilities_Node  : constant Nod.Node := N.Value ("abilities");
      Weaknesses_Node : constant Nod.Node := N.Value ("weaknesses");
      Combat_Node     : constant Nod.Node := N.Value ("combat");
      Notes_Node      : constant Nod.Node := N.Value ("notes");
      Fluff_Node      : constant Nod.Node := N.Value ("fluff");

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
      Result.Has_Name := N.Has_Key ("name");
      if Result.Has_Name then
         Result.Name := To_Unbounded_String (N.String_Value ("name"));
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

      Result.Has_Personality := N.Has_Key ("personality");
      if Result.Has_Personality then
         Result.Personality :=
           To_Unbounded_String (Trim_Whitespace (N.String_Value ("personality")));
      end if;

      if Abilities_Node.Is_Valid then
         Abilities_Node.Iterate (Add_Ability'Access);
      end if;

      if Weaknesses_Node.Is_Valid then
         Weaknesses_Node.Iterate (Add_Weakness'Access);
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

      return Result;
   end Load_Entity;

end Ova_Fmt.Entities;
