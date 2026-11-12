with Ada.Characters.Latin_1;
with Ada.Containers.Vectors;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;
with Ova_Fmt.Format_Common;
with Ova_Fmt.Sheet_Map;

package body Ova_Fmt.Format_Form is

   package IO renames Ada.Text_IO;
   package SM renames Ova_Fmt.Sheet_Map;

   function Reflow (S : Unbounded_String) return String renames Ova_Fmt.Format_Common.Reflow;

   use type SM.Row_Kind;

   LF : constant Character := Ada.Characters.Latin_1.LF;

   First_Entity : Boolean := True;

   ---------------------------------------------------------------------
   --  Measuring. Widths are Helvetica's, in 1/1000 em, from groff's
   --  devpdf font files HR (Helvetica; Helvetica-Oblique has the same
   --  widths) and HB (Helvetica-Bold), for ASCII 32 .. 126. The fields
   --  are measured in tenths of a point, inside a 2 pt padding on each
   --  side, so a text of width W at Size points fits a field Width
   --  tenths wide when W * Size <= Width * 100: all integers, so the
   --  poc port agrees to the byte.
   ---------------------------------------------------------------------

   type Width_Table is array (Character range ' ' .. '~') of Natural;

   Helvetica : constant Width_Table :=
     (278, 278, 355, 556, 556, 889, 667, 222, 333, 333, 389, 584, 278, 333, 278, 278,
      556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 278, 278, 584, 584, 584, 556,
      1015, 667, 667, 722, 722, 667, 611, 778, 722, 278, 500, 667, 556, 833, 722, 778,
      667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 278, 278, 278, 333, 556,
      222, 556, 556, 500, 556, 556, 278, 556, 556, 222, 222, 500, 222, 833, 556, 556,
      556, 556, 333, 500, 278, 556, 500, 722, 500, 500, 500, 334, 260, 334, 333);

   Helvetica_Bold : constant Width_Table :=
     (278, 333, 474, 556, 556, 889, 722, 278, 333, 333, 389, 584, 278, 333, 278, 278,
      556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 333, 333, 584, 584, 584, 611,
      975, 722, 722, 722, 722, 667, 611, 778, 722, 278, 556, 722, 611, 833, 722, 778,
      667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 333, 278, 333, 333, 556,
      278, 556, 611, 556, 611, 556, 333, 611, 611, 278, 278, 556, 278, 889, 611, 611,
      611, 611, 389, 556, 333, 611, 556, 778, 556, 556, 500, 389, 280, 389, 333);

   --  A UTF-8 continuation byte adds nothing; any other non-ASCII byte
   --  starts a character, counted as wide as a digit. Control
   --  characters count nothing.
   function Char_Width (C : Character; Bold : Boolean) return Natural is
     (if C in Width_Table'Range
      then (if Bold then Helvetica_Bold (C) else Helvetica (C))
      elsif Character'Pos (C) in 16#80# .. 16#BF# then 0
      elsif Character'Pos (C) > 16#BF# then 556
      else 0);

   --  Where a width stops counting, whether a text's (in thousandths
   --  of an em) or a word's times its size: wider than any field, by
   --  more lines than any field holds, and small enough that times a
   --  size, or added to a line's width, it is still a Natural. A word
   --  of a million characters would otherwise overflow it.
   Too_Wide : constant := 100_000_000;

   function Text_Width (S : String; Bold : Boolean) return Natural is
      W : Natural := 0;
   begin
      for C of S loop
         W := Natural'Min (W + Char_Width (C, Bold), Too_Wide);
      end loop;
      return W;
   end Text_Width;

   --  Whether S fits on one line of a field Width tenths wide.
   function Fits_Line (S : String; Size : Positive; Bold : Boolean;
                       Width : Positive) return Boolean is
     (Text_Width (S, Bold) * Size <= Width * 100);

   --  The words of Text that fit in Max_Lines lines of a field Width
   --  tenths wide, wrapped greedily at spaces, each LF starting a new
   --  line: the index of the last character of the last word that
   --  fits, Text'Last if all of it does, 0 if not even the first word
   --  does. A word wider than the field takes as many lines as it
   --  needs, and the line after it is a new one. Text'First is 1.
   function Fit_Cut (Text : String; Size : Positive; Bold : Boolean;
                     Width, Max_Lines : Positive) return Natural
   is
      Limit : constant Natural := Width * 100;
      Space : constant Natural := Char_Width (' ', Bold) * Size;
      Lines : Positive := 1;
      Fresh : Boolean := True;
      Cur   : Natural := 0;
      Cut   : Natural := 0;
      I     : Positive := Text'First;
      J     : Positive;
      W     : Natural;
   begin
      while I <= Text'Last loop
         if Text (I) = LF then
            Lines := Lines + 1;
            Fresh := True;
            if Lines > Max_Lines then
               return Cut;
            end if;
            I := I + 1;
         elsif Text (I) = ' ' then
            I := I + 1;
         else
            J := I;
            W := 0;
            while J <= Text'Last and then Text (J) /= ' ' and then Text (J) /= LF loop
               W := Natural'Min (W + Char_Width (Text (J), Bold) * Size, Too_Wide);
               J := J + 1;
            end loop;
            if not Fresh then
               if Cur + Space + W <= Limit then
                  Cur := Cur + Space + W;
               else
                  Lines := Lines + 1;
                  Fresh := True;
               end if;
            end if;
            if Fresh then
               if W <= Limit then
                  Cur := W;
               else
                  Lines := Lines + (W + Limit - 1) / Limit - 1;
                  Cur := Limit;
               end if;
               Fresh := False;
            end if;
            if Lines > Max_Lines then
               return Cut;
            end if;
            Cut := J - 1;
            I := J;
         end if;
      end loop;
      return Text'Last;
   end Fit_Cut;

   --  The index of the last character of the first word of Text at or
   --  after From; Text'Last if there is none.
   function First_Word_End (Text : String; From : Positive) return Natural is
      I : Positive := From;
   begin
      while I <= Text'Last and then (Text (I) = ' ' or else Text (I) = LF) loop
         I := I + 1;
      end loop;
      while I <= Text'Last and then Text (I) /= ' ' and then Text (I) /= LF loop
         I := I + 1;
      end loop;
      return I - 1;
   end First_Word_End;

   function Trim_Trailing (S : String) return String is
      Last : Natural := S'Last;
   begin
      while Last >= S'First and then (S (Last) = ' ' or else S (Last) = LF) loop
         Last := Last - 1;
      end loop;
      return S (S'First .. Last);
   end Trim_Trailing;

   function Trim_Leading (S : String) return String is
      First : Positive := S'First;
   begin
      while First <= S'Last and then (S (First) = ' ' or else S (First) = LF) loop
         First := First + 1;
      end loop;
      return S (First .. S'Last);
   end Trim_Leading;

   --  Text split into what fits a field and the rest, the field
   --  taking at least one word.
   procedure Fit (Text : String; Size : Positive; Bold : Boolean;
                  Width, Max_Lines : Positive;
                  Fitted, Rest : out Unbounded_String)
   is
      Cut : Natural := Fit_Cut (Text, Size, Bold, Width, Max_Lines);
   begin
      if Cut = 0 then
         Cut := First_Word_End (Text, Text'First);
      end if;
      Fitted := To_Unbounded_String (Trim_Trailing (Text (Text'First .. Cut)));
      Rest := To_Unbounded_String (Trim_Leading (Text (Cut + 1 .. Text'Last)));
   end Fit;

   ---------------------------------------------------------------------
   --  Text.
   ---------------------------------------------------------------------

   --  S as a JSON string's contents.
   function Escape (S : String) return String is
      Hex    : constant String := "0123456789abcdef";
      Result : Unbounded_String;
   begin
      for C of S loop
         case C is
            when '"' => Append (Result, "\""");
            when '\' => Append (Result, "\\");
            when Ada.Characters.Latin_1.LF => Append (Result, "\n");
            when Ada.Characters.Latin_1.CR => Append (Result, "\r");
            when Ada.Characters.Latin_1.HT => Append (Result, "\t");
            when Ada.Characters.Latin_1.BS => Append (Result, "\b");
            when Ada.Characters.Latin_1.FF => Append (Result, "\f");
            when others =>
               if Character'Pos (C) < 16#20# then
                  Append (Result, "\u00");
                  Append (Result, Hex (Character'Pos (C) / 16 + 1));
                  Append (Result, Hex (Character'Pos (C) mod 16 + 1));
               else
                  Append (Result, C);
               end if;
         end case;
      end loop;
      return To_String (Result);
   end Escape;

   function Img (N : Natural) return String is
      S : constant String := Natural'Image (N);
   begin
      return S (S'First + 1 .. S'Last);
   end Img;

   ---------------------------------------------------------------------
   --  Fills and the fields' geometry.
   ---------------------------------------------------------------------

   type Field is record
      Name, Value : Unbounded_String;
   end record;

   package Field_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Field);

   package String_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Unbounded_String);

   type Fill is record
      Pages  : Unbounded_String;  --  "1, 2", "1" or "2"
      Sub    : String_Vectors.Vector;
      Fields : Field_Vectors.Vector;
   end record;

   package Fill_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Fill);

   procedure Set (F : in out Fill; Name : String; Value : String) is
   begin
      F.Fields.Append ((To_Unbounded_String (Name), To_Unbounded_String (Value)));
   end Set;

   --  Inner widths and heights, in tenths of a point; leading is 1.2
   --  times the size, so a field of Height at Size takes
   --  Height / (Size * 12) lines.
   Row_Width     : constant := 1485;  --  Ability N, Weakness N
   Attack_Width  : constant := 1332;  --  Attack N, Attack Description N
   Clause_Height : constant := 224;
   Combat_Width  : constant := 1085;
   Combat_Height : constant := 1557;

   Item_Size   : constant := 8;
   Sub_Size    : constant := 7;
   Attack_Size : constant := 8;
   Clause_Size : constant := 7;
   Combat_Size : constant := 6;
   Prose_Size  : constant := 8;

   function Max_Lines (Height, Size : Positive) return Positive is
     (Positive'Max (1, Height / (Size * 12)));

   --  The fields of page 2, in the order sections are laid into them.
   type Prose_Field is (Background, Appearance, Personality, Other_Notes);

   function Prose_Name (P : Prose_Field) return String is
     (case P is
         when Background  => "Background",
         when Appearance  => "Appearance",
         when Personality => "Personality",
         when Other_Notes => "Other Notes");

   Prose_Width : constant array (Prose_Field) of Positive :=
     (Background => 2023, Appearance => 1683, Personality => 1682, Other_Notes => 3480);

   Prose_Height : constant array (Prose_Field) of Positive :=
     (Background => 2834, Appearance => 1414, Personality => 1414, Other_Notes => 357);

   type Prose_Values is array (Prose_Field) of Unbounded_String;

   procedure Set_Prose (F : in out Fill; V : Prose_Values) is
   begin
      for P in Prose_Field loop
         if Length (V (P)) > 0 then
            Set (F, Prose_Name (P), To_String (V (P)));
         end if;
      end loop;
   end Set_Prose;

   --  A part of a page-2 copy: Label opens it, as a line of its own.
   type Section is record
      Label, Content : Unbounded_String;
   end record;

   package Section_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Section);

   procedure Add_Section (Sections : in out Section_Vectors.Vector;
                          Label : String; Content : String) is
   begin
      if Content /= "" then
         Sections.Append ((To_Unbounded_String (Label), To_Unbounded_String (Content)));
      end if;
   end Add_Section;

   --  Line added to Lines, LF-separated.
   procedure Add_Line (Lines : in out Unbounded_String; Line : String) is
   begin
      if Length (Lines) > 0 then
         Append (Lines, LF);
      end if;
      Append (Lines, Line);
   end Add_Line;

   ---------------------------------------------------------------------
   --  Page 1.
   ---------------------------------------------------------------------

   --  An owner's parts of page-2 copies, gathered over its copies.
   type Owner_Parts is record
      Lines_In_Full, Ability_Notes, Attacks, Combat_Notes : Unbounded_String;
   end record;

   --  The text of a row's name field, and whether it is a built-under
   --  row (smaller, in the fill's `sub`).
   function Row_Text (R : SM.Row) return String is
     (case R.Kind is
         when SM.Item  => To_String (R.Text),
         when SM.Sub   => "    " & To_String (R.Level) & " " & To_String (R.Text),
         when SM.Spell => "    " & To_String (R.Text));

   function Row_Fits (R : SM.Row) return Boolean is
     (Fits_Line (Row_Text (R), (if R.Kind = SM.Item then Item_Size else Sub_Size),
                 False, Row_Width));

   --  A row as "Lines in Full" gives it: its level and text.
   function Row_In_Full (R : SM.Row) return String is
     (if R.Kind = SM.Item and then Length (R.Level) > 0
      then To_String (R.Level) & " " & To_String (R.Text)
      else Trim_Leading (Row_Text (R)));

   procedure Set_Rows (F : in out Fill; Parts : in out Owner_Parts;
                       Rows : SM.Row_Vectors.Vector;
                       Dice_Prefix, Name_Prefix : String) is
   begin
      for N in Rows.First_Index .. Rows.Last_Index loop
         declare
            R    : constant SM.Row := Rows (N);
            Name : constant String := Name_Prefix & Img (N);
         begin
            if R.Kind = SM.Item and then Length (R.Level) > 0 then
               Set (F, Dice_Prefix & Img (N), To_String (R.Level));
            end if;
            Set (F, Name, Row_Text (R));
            if R.Kind /= SM.Item then
               F.Sub.Append (To_Unbounded_String (Name));
            end if;
            if not Row_Fits (R) then
               Add_Line (Parts.Lines_In_Full, Row_In_Full (R));
            end if;
            if R.Has_Note then
               Add_Line (Parts.Ability_Notes, Reflow (R.Note));
            end if;
         end;
      end loop;
   end Set_Rows;

   procedure Set_Attacks (F : in out Fill; Parts : in out Owner_Parts;
                          Attacks : SM.Attack_Slot_Vectors.Vector) is
   begin
      for N in Attacks.First_Index .. Attacks.Last_Index loop
         declare
            A       : constant SM.Attack_Slot := Attacks (N);
            Name    : constant String := To_String (A.Name);
            Clause  : constant String := To_String (A.Clause);
            Suffix  : constant String := (if N = 1 then "" else "_" & Img (N));
            Clipped : constant Boolean :=
              Clause /= "" and then
              Fit_Cut (Clause, Clause_Size, True, Attack_Width,
                       Max_Lines (Clause_Height, Clause_Size)) /= Clause'Last;
            Entry_Text : Unbounded_String;
         begin
            Set (F, "Attack " & Img (N), Name);
            if Clause /= "" then
               Set (F, "Attack Description " & Img (N), Clause);
            end if;
            Set (F, "roll" & Suffix, To_String (A.Roll));
            Set (F, "dx" & Suffix, To_String (A.Dx));
            Set (F, "end" & Suffix, To_String (A.Endurance));
            if A.Has_Description or else Clipped
              or else not Fits_Line (Name, Attack_Size, True, Attack_Width)
            then
               Entry_Text := A.Name;
               if Clipped then
                  Append (Entry_Text, " (" & Clause & ")");
               end if;
               if A.Has_Description then
                  Append (Entry_Text, ": " & Reflow (A.Description));
               end if;
               Add_Line (Parts.Attacks, To_String (Entry_Text));
            end if;
         end;
      end loop;
   end Set_Attacks;

   function Page_1_Fill (P : SM.Page_1; Parts : in out Owner_Parts) return Fill is
      F : Fill;
   begin
      F.Pages := To_Unbounded_String ("1");
      Set (F, "Character Name", To_String (P.Title));
      if P.Has_Player then
         Set (F, "Player Name", To_String (P.Player));
      end if;
      Set_Rows (F, Parts, P.Abilities, "Abilities Dice", "Ability ");
      Set_Rows (F, Parts, P.Weaknesses, "Weakness Dice ", "Weakness ");
      Set_Attacks (F, Parts, P.Attacks);
      declare
         Notes : Unbounded_String;
      begin
         if Length (P.NPC_Type) > 0 then
            Notes := "NPC Type: " & P.NPC_Type;
         end if;
         if P.Has_Combat_Notes then
            Add_Line (Notes, Reflow (P.Combat_Notes));
         end if;
         if Length (Notes) > 0 then
            declare
               Fitted, Rest : Unbounded_String;
            begin
               Fit (To_String (Notes), Combat_Size, False, Combat_Width,
                    Max_Lines (Combat_Height, Combat_Size), Fitted, Rest);
               Set (F, "Combat Notes", To_String (Fitted));
               Parts.Combat_Notes := Rest;
            end;
         end if;
      end;
      if P.Has_Stats then
         Set (F, "Defense", To_String (P.Defense));
         Set (F, "Health", To_String (P.Health));
         Set (F, "Endurance", To_String (P.Endurance));
         if Length (P.Threat_Value) > 0 then
            Set (F, "TV", To_String (P.Threat_Value));
         end if;
      end if;
      return F;
   end Page_1_Fill;

   procedure Add_Owner_Sections (Sections : in out Section_Vectors.Vector;
                                 Owner : String; Parts : Owner_Parts) is
   begin
      Add_Section (Sections, Owner & ": Lines in Full", To_String (Parts.Lines_In_Full));
      Add_Section (Sections, Owner & ": Ability Notes", To_String (Parts.Ability_Notes));
      Add_Section (Sections, Owner & ": Attacks", To_String (Parts.Attacks));
      Add_Section (Sections, Owner & ": Combat Notes (continued)",
                   To_String (Parts.Combat_Notes));
   end Add_Owner_Sections;

   ---------------------------------------------------------------------
   --  Page 2.
   ---------------------------------------------------------------------

   --  The sections laid into page-2 copies' fields in order, each
   --  section after the one before it in the same field, a field
   --  taking what fits and the rest going on to the next field or
   --  copy, the label repeated there with " (continued)".
   procedure Lay_Out (Sections : Section_Vectors.Vector;
                      Fills : in out Fill_Vectors.Vector)
   is
      Values : Prose_Values;
      Used   : Boolean := False;
      P      : Prose_Field := Prose_Field'First;
      Full   : Boolean := False;  --  past the last field of the copy

      procedure Next_Field is
      begin
         if P = Prose_Field'Last then
            Full := True;
         else
            P := Prose_Field'Succ (P);
         end if;
      end Next_Field;

      procedure Emit is
         F : Fill;
      begin
         F.Pages := To_Unbounded_String ("2");
         Set_Prose (F, Values);
         Fills.Append (F);
         Values := (others => Null_Unbounded_String);
         Used := False;
         P := Prose_Field'First;
         Full := False;
      end Emit;
   begin
      for S of Sections loop
         declare
            Remaining : Unbounded_String := S.Content;
            First     : Boolean := True;
         begin
            loop
               if Full then
                  Emit;
               end if;
               declare
                  Existing  : constant String := To_String (Values (P));
                  Label     : constant String :=
                    (if First then To_String (S.Label)
                     else To_String (S.Label) & " (continued)");
                  Prefix    : constant String :=
                    (if Existing = "" then "" else Existing & LF & LF) & Label & LF;
                  Candidate : constant String := Prefix & To_String (Remaining);
                  Cut       : Natural :=
                    Fit_Cut (Candidate, Prose_Size, False, Prose_Width (P),
                             Max_Lines (Prose_Height (P), Prose_Size));
               begin
                  if Cut = Candidate'Last then
                     Values (P) := To_Unbounded_String (Candidate);
                     Used := True;
                     exit;
                  end if;
                  if Cut <= Prefix'Length and then Existing = "" then
                     Cut := First_Word_End (Candidate, Prefix'Length + 1);
                  end if;
                  if Cut > Prefix'Length then
                     Values (P) := To_Unbounded_String
                       (Trim_Trailing (Candidate (1 .. Cut)));
                     Used := True;
                     Remaining := To_Unbounded_String
                       (Trim_Leading (Candidate (Cut + 1 .. Candidate'Last)));
                     First := False;
                     if Length (Remaining) = 0 then
                        exit;
                     end if;
                  end if;
                  Next_Field;
               end;
            end loop;
         end;
      end loop;
      if Used then
         Emit;
      end if;
   end Lay_Out;

   ---------------------------------------------------------------------
   --  Output.
   ---------------------------------------------------------------------

   procedure Put_Fill (F : Fill) is
   begin
      IO.Put_Line ("    {");
      IO.Put_Line ("      ""pages"": [" & To_String (F.Pages) & "],");
      IO.Put ("      ""sub"": [");
      for I in F.Sub.First_Index .. F.Sub.Last_Index loop
         if I > F.Sub.First_Index then
            IO.Put (", ");
         end if;
         IO.Put ('"' & Escape (To_String (F.Sub (I))) & '"');
      end loop;
      IO.Put_Line ("],");
      IO.Put_Line ("      ""fields"": {");
      for I in F.Fields.First_Index .. F.Fields.Last_Index loop
         IO.Put ("        """ & Escape (To_String (F.Fields (I).Name)) & """: """ &
                 Escape (To_String (F.Fields (I).Value)) & '"');
         if I < F.Fields.Last_Index then
            IO.Put (",");
         end if;
         IO.New_Line;
      end loop;
      IO.Put_Line ("      }");
      IO.Put ("    }");
   end Put_Fill;

   procedure Process_Entity (E : Entities.Entity) is
      Pages    : constant SM.Page_1_Vectors.Vector := SM.Fill (E);
      Name     : constant String := To_String (E.Name);
      Fills    : Fill_Vectors.Vector;
      Sections : Section_Vectors.Vector;
      Main_2   : Prose_Values;
      Parts    : Owner_Parts;

      procedure Main_Prose (P : Prose_Field; Has : Boolean; Text : Unbounded_String) is
         Content : constant String := (if Has then Reflow (Text) else "");
         Rest : Unbounded_String;
      begin
         if Content /= "" then
            Fit (Content, Prose_Size, False, Prose_Width (P),
                 Max_Lines (Prose_Height (P), Prose_Size), Main_2 (P), Rest);
            Add_Section (Sections, Name & ": " & Prose_Name (P) & " (continued)",
                         To_String (Rest));
         end if;
      end Main_Prose;
   begin
      Main_Prose (Background, E.Has_Background, E.Background);
      Main_Prose (Appearance, E.Has_Appearance, E.Appearance);
      Main_Prose (Personality, E.Has_Personality, E.Personality);
      Main_Prose (Other_Notes, E.Has_Other_Notes, E.Other_Notes);

      for I in Pages.First_Index .. Pages.Last_Index loop
         if I > Pages.First_Index and then not Pages (I).Continued then
            Add_Owner_Sections (Sections, To_String (Pages (I - 1).Owner), Parts);
            Parts := (others => Null_Unbounded_String);
         end if;
         Fills.Append (Page_1_Fill (Pages (I), Parts));
      end loop;
      Add_Owner_Sections (Sections, To_String (Pages.Last_Element.Owner), Parts);

      for N of E.Notes loop
         Add_Section (Sections, Name & ": " & To_String (N.Header), Reflow (N.Text));
      end loop;
      if E.Has_Character_Hooks then
         Add_Section (Sections, Name & ": Character Hooks", Reflow (E.Character_Hooks));
      end if;

      --  The main sheet is both pages.
      declare
         Main : Fill renames Fills (Fills.First_Index);
      begin
         Main.Pages := To_Unbounded_String ("1, 2");
         Set_Prose (Main, Main_2);
      end;

      Lay_Out (Sections, Fills);

      IO.Put (if First_Entity then "[" & LF else "," & LF);
      First_Entity := False;
      IO.Put_Line ("  [");
      for I in Fills.First_Index .. Fills.Last_Index loop
         Put_Fill (Fills (I));
         IO.Put (if I < Fills.Last_Index then "," & LF else "" & LF);
      end loop;
      IO.Put ("  ]");
   end Process_Entity;

   procedure Finish is
   begin
      if First_Entity then
         IO.Put_Line ("[]");
      else
         IO.New_Line;
         IO.Put_Line ("]");
      end if;
   end Finish;

end Ova_Fmt.Format_Form;
