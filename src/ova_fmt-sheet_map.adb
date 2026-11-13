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

   --  A row of Kind with Level, its text Plain and Bracket (" [...]"
   --  from Format_Modifiers_Bracket, or "").
   function Make_Row (Kind : Row_Kind; Level, Plain, Bracket : String;
                      Has_Note : Boolean := False;
                      Note : Unbounded_String := Null_Unbounded_String) return Row is
     ((Kind     => Kind,
       Level    => To_Unbounded_String (Level),
       Text     => To_Unbounded_String (Plain & Bracket),
       Plain    => To_Unbounded_String (Plain),
       Mods     => To_Unbounded_String
                     (if Bracket = "" then ""
                      else Bracket (Bracket'First + 2 .. Bracket'Last - 1)),
       Has_Note => Has_Note,
       Note     => Note));

   --  "Name (detail)", then (half TV) with -O, then the bracket.
   function Sub_Item_Row (S : Entities.Sub_Item; Kind : Row_Kind) return Row is
     (Make_Row
        (Kind, FC.Signed_Img (S.Level),
         FC.Name_Detail (S.Name, S.Has_Detail, S.Detail) &
           FC.Half_TV_Text (S.Has_Threat_Value_Half, S.Threat_Value_Half),
         FC.Format_Modifiers_Bracket
           (S.Perks, S.Flaws, S.Has_Endurance, S.Endurance,
            S.Overrides (Entities.Endurance), Raw => True),
         S.Has_Note, Note_Of (S.Name, S.Has_Detail, S.Detail, S.Has_Note, S.Note)));

   function Single (R : Row) return Block is
     ((Rows => Row_Vectors.To_Vector (R, 1), Continued => R));

   --  The Ability's own row, then its Transformation's granted
   --  Abilities and Weaknesses, then its spells.
   function Ability_Block (A : Entities.Ability) return Block is
      Name : constant String := FC.Name_Detail (A.Name, A.Has_Detail, A.Detail);
      B    : Block;
   begin
      B.Rows.Append
        (Make_Row
           (Item, FC.Signed_Img (A.Level),
            Name & FC.Half_TV_Text (A.Has_Threat_Value_Half, A.Threat_Value_Half),
            FC.Format_Modifiers_Bracket
              (A.Perks, A.Flaws, A.Has_Endurance, A.Endurance,
               A.Overrides (Entities.Endurance), Raw => True),
            A.Has_Note, Note_Of (A.Name, A.Has_Detail, A.Detail, A.Has_Note, A.Note)));
      for S of A.Sub_Abilities loop
         B.Rows.Append (Sub_Item_Row (S, Sub));
      end loop;
      for S of A.Sub_Weaknesses loop
         B.Rows.Append (Sub_Item_Row (S, Sub));
      end loop;
      for S of A.Spells loop
         B.Rows.Append (Make_Row (Spell, "", FC.Format_Short_Spell_Line (S, Raw => True), ""));
      end loop;
      B.Continued := Make_Row (Item, "", Name & " (continued)", "");
      return B;
   end Ability_Block;

   function Height (R : Row; Lines : Row_Lines) return Positive is
     (if Lines = null then 1 else Lines (R));

   function Height (Rows : Row_Vectors.Vector; Lines : Row_Lines) return Natural is
      H : Natural := 0;
   begin
      for R of Rows loop
         H := H + Height (R, Lines);
      end loop;
      return H;
   end Height;

   --  Blocks into columns of Slots lines, one column per copy of page
   --  1, keeping each block together when it can. The first column
   --  has its first First_Used lines taken already (-C's Weaknesses,
   --  under the Abilities); if its first block doesn't fit what is
   --  left, that column is empty.
   function Place (Blocks : Block_Vectors.Vector; Slots : Positive;
                   Lines : Row_Lines; First_Used : Natural := 0)
     return Column_Vectors.Vector
   is
      Columns : Column_Vectors.Vector;
      Current : Row_Vectors.Vector;
      Used    : Natural := First_Used;  --  Current's lines

      function Height (R : Row) return Positive is (Height (R, Lines));

      function Height (Rows : Row_Vectors.Vector) return Natural is (Height (Rows, Lines));

      --  What is left of the column, never negative: a row taller
      --  than the column overfills one.
      function Left return Natural is (if Used >= Slots then 0 else Slots - Used);

      procedure Add (R : Row) is
      begin
         Current.Append (R);
         Used := Used + Height (R);
      end Add;

      procedure Next is
      begin
         Columns.Append (Current);
         Current.Clear;
         Used := 0;
      end Next;
   begin
      for B of Blocks loop
         if Height (B.Rows) <= Left then
            for R of B.Rows loop
               Add (R);
            end loop;
         elsif Height (B.Rows) <= Slots then
            Next;
            for R of B.Rows loop
               Add (R);
            end loop;
         else
            --  Taller than the column: split, starting here unless
            --  there isn't room for the parent and one row under it.
            if Left < Height (B.Rows (1)) +
                       (if Natural (B.Rows.Length) > 1 then Height (B.Rows (2)) else 0)
              and then Used > 0
            then
               Next;
            end if;
            for I in B.Rows.First_Index .. B.Rows.Last_Index loop
               if Height (B.Rows (I)) > Left and then not Current.Is_Empty then
                  Next;
                  Add (B.Continued);
               end if;
               Add (B.Rows (I));
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
      NPC_Type   : String;
      Lines      : Row_Lines;
      One_Column : Boolean)
   is
      A_Columns : constant Column_Vectors.Vector :=
        Place (Abilities, (if One_Column then One_Column_Slots else Ability_Slots), Lines);
      --  With One_Column, the Weaknesses go on from the last copy with
      --  Abilities, a line below them.
      W_First   : constant Natural :=
        (if One_Column and then not A_Columns.Is_Empty then Natural (A_Columns.Length) - 1
         else 0);
      W_Columns : constant Column_Vectors.Vector :=
        (if One_Column
         then Place (Weaknesses, One_Column_Slots, Lines,
                     (if A_Columns.Is_Empty then 0
                      else Height (A_Columns.Last_Element, Lines) + 1))
         else Place (Weaknesses, Weakness_Slots, Lines));
      Slots     : constant Positive :=
        (if One_Column then One_Column_Attack_Slots else Attack_Slots);
      Attacks   : constant Natural :=
        (if Combat.Has_Combat then Natural (Combat.Attacks.Length) else 0);
      Copies    : constant Positive :=
        Positive'Max
          (1, Natural'Max
                (Natural'Max (Natural (A_Columns.Length),
                              W_First + Natural (W_Columns.Length)),
                 (Attacks + Slots - 1) / Slots));
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
            if N > W_First and then N - W_First <= Natural (W_Columns.Length) then
               P.Weaknesses := W_Columns (N - W_First);
            end if;
            for I in (N - 1) * Slots + 1 .. Natural'Min (N * Slots, Attacks) loop
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

   function Fill (E : Entities.Entity; Lines : Row_Lines := null;
                  One_Column : Boolean := False)
     return Page_1_Vectors.Vector
   is
      Pages      : Page_1_Vectors.Vector;
      Abilities  : Block_Vectors.Vector;
      Weaknesses : Block_Vectors.Vector;
   begin
      for A of E.Abilities loop
         Abilities.Append (Ability_Block (A));
      end loop;
      for W of E.Weaknesses loop
         Weaknesses.Append
           (Single (Make_Row (Item, FC.Signed_Img (W.Level),
                              FC.Name_Detail (W.Name, W.Has_Detail, W.Detail), "")));
      end loop;
      Add_Copies (Pages, E.Name, To_String (E.Name), E.Has_Player, E.Player,
                  Abilities, Weaknesses, E.Combat, FC.NPC_Type_Text (E), Lines,
                  One_Column);

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
                     False, Null_Unbounded_String, S_Abl, S_Wk, SE.Combat, "", Lines,
                     One_Column);
               end if;
            end;
         end if;
      end loop;
      return Pages;
   end Fill;

end Ova_Fmt.Sheet_Map;
