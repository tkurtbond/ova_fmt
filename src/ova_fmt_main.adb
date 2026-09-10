--  ova_fmt - convert a YAML OVA character file into reST/Gemtext/
--  HTML-in-reST/h-m-m. Dispatches to Ova_Fmt.Format_Rst (Terse,
--  Html_In_Rst), Ova_Fmt.Format_Gemini (Gemtext), or Ova_Fmt.Format_Hmm
--  (Hmm) by Config.Format -- see Ova_Fmt.Format_Common's header
--  comment for why those are split this way. groff-in-reST/Lout are
--  still unimplemented (PLAN.md §9 steps 6-7). Structure mirrors
--  besm2_fmt_main.adb.

with Ada.Command_Line;
with Ada.Exceptions;
with Ada.Text_IO;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Arg_Parser;
with Libfyaml;
with Libfyaml.Documents;
with Libfyaml.Documents.Streams;
with Libfyaml.Nodes;
with Ova_Fmt.Cli;
with Ova_Fmt.Config;
with Ova_Fmt.Entities;
with Ova_Fmt.Format_Gemini;
with Ova_Fmt.Format_Hmm;
with Ova_Fmt.Format_Rst;

procedure Ova_Fmt_Main is

   package Doc renames Libfyaml.Documents;
   package Streams renames Libfyaml.Documents.Streams;
   package Nod renames Libfyaml.Nodes;

   use type Arg_Parser.String_Reference;
   use type Ova_Fmt.Config.Output_Format;

   --  Set once, for the whole run, the first time any input source
   --  turns out to have a required-field problem or a hard parse
   --  error -- read at the very end to pick the process exit status.
   Had_Errors : Boolean := False;

   function Read_All_Standard_Input return String is
      Buffer : Unbounded_String;
   begin
      while not Ada.Text_IO.End_Of_File loop
         Append (Buffer, Ada.Text_IO.Get_Line);
         Append (Buffer, ASCII.LF);
      end loop;
      return To_String (Buffer);
   end Read_All_Standard_Input;

   function Trimmed (N : Positive) return String is
     (Ada.Strings.Fixed.Trim (N'Image, Ada.Strings.Left));

   --  Prints every error collected for Source (Ova_Fmt.Entities.
   --  Errors) plus a summary line, all to standard error -- gcc-style
   --  "source:line:column: error: message" when an error has an
   --  (approximate) Location, "source: error: message" when it only
   --  has a Path (Ova_Fmt.Entities.Load_Error's own doc comment
   --  explains why a Location isn't always available). Per the user:
   --  this replaces raising Libfyaml.Missing_Key/Data_Error straight
   --  through and aborting on the first problem found -- every
   --  problem in the file is reported together, and (since the
   --  caller only calls this after loading finishes, before rendering
   --  anything) no partial output is produced for a file with any.
   procedure Report_Errors (Source : String) is
      use Ova_Fmt.Entities;
   begin
      for Err of Errors loop
         if Err.Has_Location then
            Ada.Text_IO.Put_Line
              (Ada.Text_IO.Standard_Error,
               Source & ":" & Trimmed (Err.Line) & ":" & Trimmed (Err.Column) &
               ": error: " & To_String (Err.Path) & ": " & To_String (Err.Message));
         else
            Ada.Text_IO.Put_Line
              (Ada.Text_IO.Standard_Error,
               Source & ": error: " & To_String (Err.Path) & ": " &
               To_String (Err.Message));
         end if;
      end loop;
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "ova_fmt: " & Trimmed (Error_Count) & " error(s) in " & Source &
         "; no output produced");
   end Report_Errors;

   --  Count is threaded across every document in the file: Entity_No
   --  is 1 for the first entity in a *file*, 2 for the second, etc.,
   --  regardless of how many "---"-separated YAML documents that file
   --  is split into (same convention as besm2_fmt_main.adb).
   --
   --  Loaded, not rendered, here: Load_Entity now records a required-
   --  field problem instead of raising through it (Ova_Fmt.Entities'
   --  Require_String/Require_Integer), so Process_One below needs
   --  every entity in the file loaded and Error_Count checked once,
   --  before rendering any of them -- see Report_Errors' own comment.
   procedure Process_Entities
     (D      : Doc.Document; Source : String; Count : in out Natural;
      Loaded : in out Ova_Fmt.Entities.Entity_Vectors.Vector)
   is
      Root : constant Nod.Node := D.Root;

      procedure Visit (Item : Nod.Node) is
      begin
         Count := Count + 1;
         Loaded.Append (Ova_Fmt.Entities.Load_Entity (Item));
      end Visit;
   begin
      if not Root.Is_Valid or else not Root.Is_Sequence then
         raise Program_Error with
           "expected a top-level YAML sequence of entities in " & Source;
      end if;
      Root.Iterate (Visit'Access);
   end Process_Entities;

   procedure Process_One (Filename : String; Use_Stdin : Boolean) is
      Source : constant String := (if Use_Stdin then "(stdin)" else Filename);
      Count  : Natural := 0;
      Loaded : Ova_Fmt.Entities.Entity_Vectors.Vector;
   begin
      Ova_Fmt.Entities.Reset_Errors;
      declare
         Stream : Streams.Document_Stream :=
           (if Use_Stdin
            then Streams.Open_String (Read_All_Standard_Input)
            else Streams.Open_File (Filename));
      begin
         while Streams.Has_Next (Stream) loop
            Process_Entities (Streams.Next (Stream), Source, Count, Loaded);
         end loop;
      end;

      if Ova_Fmt.Entities.Error_Count > 0 then
         Report_Errors (Source);
         Had_Errors := True;
      else
         for I in Loaded.First_Index .. Loaded.Last_Index loop
            case Ova_Fmt.Config.Format is
               when Ova_Fmt.Config.Gemtext =>
                  Ova_Fmt.Format_Gemini.Process_Entity (Loaded (I), I);
               when Ova_Fmt.Config.Hmm =>
                  Ova_Fmt.Format_Hmm.Process_Entity (Loaded (I), I);
               when Ova_Fmt.Config.Terse | Ova_Fmt.Config.Html_In_Rst =>
                  Ova_Fmt.Format_Rst.Process_Entity (Loaded (I), I);
            end case;
         end loop;
      end if;
   exception
      when E : Libfyaml.Parse_Error | Libfyaml.Missing_Key | Libfyaml.Data_Error |
               Program_Error =>
         Ada.Text_IO.Put_Line
           (Ada.Text_IO.Standard_Error,
            "ova_fmt: error processing " & Source & ": " &
            Ada.Exceptions.Exception_Message (E));
         Had_Errors := True;
   end Process_One;

   procedure Process_All is
   begin
      if Ova_Fmt.Cli.Filenames.Is_Empty then
         Process_One ("", True);
      else
         for F of Ova_Fmt.Cli.Filenames loop
            Process_One (To_String (F), False);
         end loop;
      end if;
   end Process_All;

begin
   Ova_Fmt.Cli.Parse;

   if Ova_Fmt.Config.Output_File /= null then
      declare
         Output_File : Ada.Text_IO.File_Type;
      begin
         Ada.Text_IO.Create
           (Output_File, Ada.Text_IO.Out_File, Ova_Fmt.Config.Output_File.all);
         Ada.Text_IO.Set_Output (Output_File);
         Process_All;
         Ada.Text_IO.Set_Output (Ada.Text_IO.Standard_Output);
         Ada.Text_IO.Close (Output_File);
      end;
   else
      Process_All;
   end if;

   if Had_Errors then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;

exception
   when Ova_Fmt.Cli.Help_Requested =>
      Ada.Command_Line.Set_Exit_Status (1);

   when E : Arg_Parser.Unknown_Option | Arg_Parser.Unknown_Argument |
            Arg_Parser.Argument_Required | Arg_Parser.Invalid_Option_Argument =>
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error, "ova_fmt: " & Ada.Exceptions.Exception_Message (E));
      Ada.Command_Line.Set_Exit_Status (2);

   when Constraint_Error =>
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error, "ova_fmt: invalid numeric option argument");
      Ada.Command_Line.Set_Exit_Status (2);
end Ova_Fmt_Main;
