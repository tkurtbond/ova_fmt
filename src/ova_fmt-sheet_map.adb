with Ova_Fmt.Format_Common;

package body Ova_Fmt.Sheet_Map is

   package FC renames Ova_Fmt.Format_Common;

   use type Entities.Sub_Entity_Access;

   --  A parent row and the rows under it, kept together, with the
   --  parent as it is repeated if the block has to be split.
   type Block is record
      Rows      : Row_Vectors.Vector;
      Continued : Row;
   end record;

   package Block_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Block);

   --  One column's rows on each copy of page 1.
   package Column_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Row_Vectors.Vector,
      "="          => Row_Vectors."=");

   function Note_Of (Name : Unbounded_String; Has_Detail : Boolean;
                     Detail : Unbounded_String; Has_Note : Boolean;
                     Note : Unbounded_String) return Unbounded_String is
     (if Has_Note
      then To_Unbounded_String (FC.Name_Detail (Name, Has_Detail, Detail) & ": ") & Note
      else Null_Unbounded_String);

   --  "Name (detail)", then (half TV) with -O, then the bracket.
   function Sub_Item_Text (S : Entities.Sub_Item) return Unbounded_String is
     (To_Unbounded_String
        (FC.Name_Detail (S.Name, S.Has_Detail, S.Detail) &
         FC.Half_TV_Text (S.Has_Threat_Value_Half, S.Threat_Value_Half) &
         FC.Format_Modifiers_Bracket
           (S.Perks, S.Flaws, S.Has_Endurance, S.Endurance,
            S.Overrides (Entities.Endurance), Raw => True)));

   function Sub_Item_Row (S : Entities.Sub_Item; Kind : Row_Kind) return Row is
     ((Kind     => Kind,
       Level    => To_Unbounded_String (FC.Signed_Img (S.Level)),
       Text     => Sub_Item_Text (S),
       Has_Note => S.Has_Note,
       Note     => Note_Of (S.Name, S.Has_Detail, S.Detail, S.Has_Note, S.Note)));

   function Single (R : Row) return Block is
     ((Rows => Row_Vectors.To_Vector (R, 1), Continued => R));

   --  The Ability's own row, then its Transformation's granted
   --  Abilities and Weaknesses, then its spells.
   function Ability_Block (A : Entities.Ability) return Block is
      Name : constant String := FC.Name_Detail (A.Name, A.Has_Detail, A.Detail);
      B    : Block;
   begin
      B.Rows.Append
        ((Kind     => Item,
          Level    => To_Unbounded_String (FC.Signed_Img (A.Level)),
          Text     => To_Unbounded_String
                        (Name & FC.Half_TV_Text (A.Has_Threat_Value_Half, A.Threat_Value_Half) &
                         FC.Format_Modifiers_Bracket
                           (A.Perks, A.Flaws, A.Has_Endurance, A.Endurance,
                            A.Overrides (Entities.Endurance), Raw => True)),
          Has_Note => A.Has_Note,
          Note     => Note_Of (A.Name, A.Has_Detail, A.Detail, A.Has_Note, A.Note)));
      for S of A.Sub_Abilities loop
         B.Rows.Append (Sub_Item_Row (S, Sub));
      end loop;
      for S of A.Sub_Weaknesses loop
         B.Rows.Append (Sub_Item_Row (S, Sub));
      end loop;
      for S of A.Spells loop
         B.Rows.Append
           ((Kind   => Spell,
             Text   => To_Unbounded_String (FC.Format_Short_Spell_Line (S, Raw => True)),
             others => <>));
      end loop;
      B.Continued := (Kind   => Item,
                      Text   => To_Unbounded_String (Name & " (continued)"),
                      others => <>);
      return B;
   end Ability_Block;

   --  Blocks into columns of Slots rows, one column per copy of page
   --  1, keeping each block together when it can.
   function Place (Blocks : Block_Vectors.Vector; Slots : Positive)
     return Column_Vectors.Vector
   is
      Columns : Column_Vectors.Vector;
      Current : Row_Vectors.Vector;

      function Left return Natural is (Slots - Natural (Current.Length));

      procedure Next is
      begin
         Columns.Append (Current);
         Current.Clear;
      end Next;
   begin
      for B of Blocks loop
         if Natural (B.Rows.Length) <= Left then
            Current.Append (B.Rows);
         elsif Natural (B.Rows.Length) <= Slots then
            Next;
            Current.Append (B.Rows);
         else
            --  Taller than the column: split, starting here unless
            --  there isn't room for the parent and one row under it.
            if Left < 2 and then not Current.Is_Empty then
               Next;
            end if;
            for I in B.Rows.First_Index .. B.Rows.Last_Index loop
               if Left = 0 then
                  Next;
                  Current.Append (B.Continued);
               end if;
               Current.Append (B.Rows (I));
            end loop;
         end if;
      end loop;
      if not Current.Is_Empty then
         Next;
      end if;
      return Columns;
   end Place;

   function Attack_Of (A : Entities.Attack) return Attack_Slot is
      Clause : constant String := FC.Format_Attack_Clause (A);
   begin
      return
        (Name            => A.Name,
         --  Without the parentheses: the box is the attack's own.
         Clause          => To_Unbounded_String
                              (if Clause = "" then ""
                               else Clause (Clause'First + 1 .. Clause'Last - 1)),
         Roll            => To_Unbounded_String
                              (FC.Number_Img (A.Roll) &
                               FC.Override_Mark (A.Overrides (Entities.Roll), Raw => True)),
         Dx              => A.Dx &
                            FC.Override_Mark (A.Overrides (Entities.Dx), Raw => True),
         Endurance       => To_Unbounded_String
                              (FC.Trim_Img (A.Endurance) &
                               FC.Override_Mark (A.Overrides (Entities.Endurance), Raw => True)),
         Has_Description => A.Has_Description,
         Description     => A.Description);
   end Attack_Of;

   --  The owner's copies, appended to Pages: the first titled Title,
   --  the rest Title & " (continued)".
   procedure Add_Copies
     (Pages      : in out Page_1_Vectors.Vector;
      Owner      : Unbounded_String;
      Title      : String;
      Has_Player : Boolean;
      Player     : Unbounded_String;
      Abilities  : Block_Vectors.Vector;
      Weaknesses : Block_Vectors.Vector;
      Combat     : Entities.Combat_Stats;
      NPC_Type   : String)
   is
      A_Columns : constant Column_Vectors.Vector := Place (Abilities, Ability_Slots);
      W_Columns : constant Column_Vectors.Vector := Place (Weaknesses, Weakness_Slots);
      Attacks   : constant Natural :=
        (if Combat.Has_Combat then Natural (Combat.Attacks.Length) else 0);
      Copies    : constant Positive :=
        Positive'Max
          (1, Natural'Max
                (Natural'Max (Natural (A_Columns.Length), Natural (W_Columns.Length)),
                 (Attacks + Attack_Slots - 1) / Attack_Slots));
   begin
      for N in 1 .. Copies loop
         declare
            P : Page_1;
         begin
            P.Owner := Owner;
            P.Continued := N > 1;
            P.Title := To_Unbounded_String
                         (if N = 1 then Title else Title & " (continued)");
            if N = 1 then
               P.Has_Player := Has_Player;
               P.Player := Player;
            end if;
            if N <= Natural (A_Columns.Length) then
               P.Abilities := A_Columns (N);
            end if;
            if N <= Natural (W_Columns.Length) then
               P.Weaknesses := W_Columns (N);
            end if;
            for I in (N - 1) * Attack_Slots + 1 .. Natural'Min (N * Attack_Slots, Attacks) loop
               P.Attacks.Append (Attack_Of (Combat.Attacks (I)));
            end loop;
            if N = 1 and then Combat.Has_Combat then
               P.Has_Stats := True;
               P.Defense := To_Unbounded_String (FC.Defense_Text (Combat, Raw => True));
               P.Health := To_Unbounded_String
                 (FC.Trim_Img (Combat.Health) &
                  FC.Override_Mark (Combat.Overrides (Entities.Health), Raw => True));
               P.Endurance := To_Unbounded_String
                 (FC.Trim_Img (Combat.Endurance) &
                  FC.Override_Mark (Combat.Overrides (Entities.Endurance), Raw => True));
               if Combat.Has_Threat_Value then
                  P.Threat_Value := To_Unbounded_String
                    (FC.Trim_Img (Combat.Threat_Value) &
                     FC.Override_Mark (Combat.Overrides (Entities.Threat_Value), Raw => True));
               end if;
               P.Has_Combat_Notes := Combat.Has_Notes;
               P.Combat_Notes := Combat.Notes;
            end if;
            if N = 1 then
               P.NPC_Type := To_Unbounded_String (NPC_Type);
            end if;
            Pages.Append (P);
         end;
      end loop;
   end Add_Copies;

   function Fill (E : Entities.Entity) return Page_1_Vectors.Vector is
      Pages      : Page_1_Vectors.Vector;
      Abilities  : Block_Vectors.Vector;
      Weaknesses : Block_Vectors.Vector;
   begin
      for A of E.Abilities loop
         Abilities.Append (Ability_Block (A));
      end loop;
      for W of E.Weaknesses loop
         Weaknesses.Append
           (Single ((Kind   => Item,
                     Level  => To_Unbounded_String (FC.Signed_Img (W.Level)),
                     Text   => To_Unbounded_String (FC.Name_Detail (W.Name, W.Has_Detail, W.Detail)),
                     others => <>)));
      end loop;
      Add_Copies (Pages, E.Name, To_String (E.Name), E.Has_Player, E.Player,
                  Abilities, Weaknesses, E.Combat, FC.NPC_Type_Text (E));

      for A of E.Abilities loop
         if A.Sub_Entity /= null then
            declare
               SE    : constant Entities.Sub_Entity_Access := A.Sub_Entity;
               S_Abl : Block_Vectors.Vector;
               S_Wk  : Block_Vectors.Vector;
            begin
               for S of SE.Abilities loop
                  S_Abl.Append (Single (Sub_Item_Row (S, Item)));
               end loop;
               for S of SE.Weaknesses loop
                  S_Wk.Append (Single (Sub_Item_Row (S, Item)));
               end loop;
               --  Nothing of its own to show: its parent's row names it.
               if not (S_Abl.Is_Empty and then S_Wk.Is_Empty and then not SE.Combat.Has_Combat) then
                  Add_Copies
                    (Pages, SE.Name,
                     To_String (SE.Name) & " (" & To_String (E.Name) & "'s " &
                     To_String (SE.Label) & ")",
                     False, Null_Unbounded_String, S_Abl, S_Wk, SE.Combat, "");
               end if;
            end;
         end if;
      end loop;
      return Pages;
   end Fill;

end Ova_Fmt.Sheet_Map;
