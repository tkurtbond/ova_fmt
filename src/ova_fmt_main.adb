--  ova_fmt - convert a YAML OVA character file into reST/Gemtext/
--  Markdown/HTML-in-reST/groff-in-reST/h-m-m/inline Markdown.
--  Dispatches to Ova_Fmt.Format_Rst (Terse, Html_In_Rst,
--  Groff_In_Rst), Ova_Fmt.Format_Gemini (Gemtext),
--  Ova_Fmt.Format_Markdown (Markdown), Ova_Fmt.Format_Hmm (Hmm),
--  Ova_Fmt.Format_Inline (Inline), Ova_Fmt.Format_Form (Form), or
--  Ova_Fmt.Format_Sheet (Sheet) by
--  Config.Format -- see
--  Ova_Fmt.Format_Common's header comment for why those are split this
--  way. Direct-to-Lout is still unimplemented (PLAN.md §9 step 7).
--  Structure mirrors besm2_fmt_main.adb.

with Ada.Command_Line;
with Ada.Exceptions;
with Ada.IO_Exceptions;
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
with Ova_Fmt.Format_Form;
with Ova_Fmt.Format_Gemini;
with Ova_Fmt.Format_Hmm;
with Ova_Fmt.Format_Inline;
with Ova_Fmt.Format_Markdown;
with Ova_Fmt.Format_Rst;
with Ova_Fmt.Format_Sheet;

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

   --  Config.Source_Dir: Filename up to its last "/".
   procedure Set_Source_Dir (Filename : String) is
      Last : Natural := Filename'First - 1;
   begin
      for I in Filename'Range loop
         if Filename (I) = '/' then
            Last := I;
         end if;
      end loop;
      Ova_Fmt.Config.Source_Dir := new String'(Filename (Filename'First .. Last));
   end Set_Source_Dir;

   procedure Process_One (Filename : String; Use_Stdin : Boolean) is
      Source : constant String := (if Use_Stdin then "(stdin)" else Filename);
      Count  : Natural := 0;
      Loaded : Ova_Fmt.Entities.Entity_Vectors.Vector;
   begin
      Ova_Fmt.Entities.Reset_Errors;
      Set_Source_Dir (if Use_Stdin then "" else Filename);
      declare
         Stream : Streams.Document_Stream :=
           (if Use_Stdin
            then Streams.Open_String (Read_All_Standard_Input, Name => Source)
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
               when Ova_Fmt.Config.Markdown =>
                  Ova_Fmt.Format_Markdown.Process_Entity (Loaded (I), I);
               when Ova_Fmt.Config.Hmm =>
                  Ova_Fmt.Format_Hmm.Process_Entity (Loaded (I), I);
               when Ova_Fmt.Config.Inline =>
                  Ova_Fmt.Format_Inline.Process_Entity (Loaded (I), I);
               when Ova_Fmt.Config.Form =>
                  Ova_Fmt.Format_Form.Process_Entity (Loaded (I));
               when Ova_Fmt.Config.Sheet =>
                  Ova_Fmt.Format_Sheet.Process_Entity (Loaded (I));
               when Ova_Fmt.Config.Terse | Ova_Fmt.Config.Html_In_Rst |
                    Ova_Fmt.Config.Groff_In_Rst =>
                  Ova_Fmt.Format_Rst.Process_Entity (Loaded (I), I);
            end case;
         end loop;
      end if;
   exception
      --  None of these ends the run: the next file is still processed.
      --
      --  A value of the wrong kind: alibfyaml's message is
      --  "[LINE:COLUMN: ]PATH: TEXT", put as a required field's error
      --  is (Report_Errors), gcc style:
      --  "FILE:3:13: error: /0/fragment: not a valid boolean: ...".
      when E : Libfyaml.Missing_Key | Libfyaml.Data_Error =>
         declare
            Message : constant String := Ada.Exceptions.Exception_Message (E);
            Rest    : constant String := Libfyaml.Without_Location (Message);
            --  "LINE:COLUMN: ", or "".
            Where   : constant String :=
              Message (Message'First .. Message'Last - Rest'Length);
         begin
            Ada.Text_IO.Put_Line
              (Ada.Text_IO.Standard_Error,
               Source & (if Where = "" then ": " else ":" & Where) & "error: " & Rest);
         end;
         Had_Errors := True;
      --  libfyaml's own diagnostics are gcc style already, a line for
      --  each: "FILE:4:1: error: TEXT".  The last ends in two line
      --  feeds (libfyaml's and alibfyaml's), and one is enough.
      --  Anything else (a parser that couldn't be made) has no file
      --  name in it.
      when E : Libfyaml.Parse_Error =>
         declare
            Message : constant String := Ada.Exceptions.Exception_Message (E);
            Prefix  : constant String := Source & ":";
            Last    : Natural := Message'Last;
         begin
            if Message'Length > Prefix'Length
              and then Message (Message'First .. Message'First + Prefix'Length - 1) = Prefix
            then
               while Last >= Message'First and then Message (Last) = ASCII.LF loop
                  Last := Last - 1;
               end loop;
               Ada.Text_IO.Put_Line
                 (Ada.Text_IO.Standard_Error, Message (Message'First .. Last));
            else
               Ada.Text_IO.Put_Line
                 (Ada.Text_IO.Standard_Error,
                  "ova_fmt: error processing " & Source & ": " & Message);
            end if;
         end;
         Had_Errors := True;
      --  Name_Error/Use_Error: an input file that can't be opened.
      when E : Program_Error | Ova_Fmt.Entities.Shape_Error |
               Ada.IO_Exceptions.Name_Error | Ada.IO_Exceptions.Use_Error =>
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
      --  -X's output is one JSON array across every file.
      if Ova_Fmt.Config.Format = Ova_Fmt.Config.Form then
         Ova_Fmt.Format_Form.Finish;
      end if;
   end Process_All;

begin
   Ova_Fmt.Cli.Parse;

   --  -C lays out a page the blank sheet doesn't have, so it is only
   --  for the sheet drawn by -R. A command-line mistake: status 2.
   if Ova_Fmt.Config.One_Column
     and then not (Ova_Fmt.Config.Format = Ova_Fmt.Config.Sheet
                   and then Ova_Fmt.Config.Redraw)
   then
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "ova_fmt: -C/--one-column needs -S/--sheet and -R/--redraw");
      Ada.Command_Line.Set_Exit_Status (2);
      return;
   end if;

   if Ova_Fmt.Config.Output_File /= null then
      declare
         Output_File : Ada.Text_IO.File_Type;
      begin
         begin
            Ada.Text_IO.Create
              (Output_File, Ada.Text_IO.Out_File, Ova_Fmt.Config.Output_File.all);
         exception
            --  The message is GNAT's "PATH: REASON".
            when E : Ada.IO_Exceptions.Name_Error | Ada.IO_Exceptions.Use_Error =>
               Ada.Text_IO.Put_Line
                 (Ada.Text_IO.Standard_Error,
                  "ova_fmt: can't create " & Ada.Exceptions.Exception_Message (E));
               Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
               return;
         end;
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

   --  Arg_Parser has already reported these, so they aren't printed
   --  again here.
   when Arg_Parser.Unknown_Option | Arg_Parser.Unknown_Argument |
        Arg_Parser.Argument_Required | Arg_Parser.Invalid_Option_Argument =>
      Ada.Command_Line.Set_Exit_Status (2);

   --  Writing the output failed (-o /dev/full, say): the message is
   --  GNAT's reason.
   when E : Ada.IO_Exceptions.Device_Error | Ada.IO_Exceptions.Use_Error =>
      Ada.Text_IO.Set_Output (Ada.Text_IO.Standard_Output);
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "ova_fmt: error writing output: " & Ada.Exceptions.Exception_Message (E));
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);

   when Constraint_Error =>
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error, "ova_fmt: invalid numeric option argument");
      Ada.Command_Line.Set_Exit_Status (2);
end Ova_Fmt_Main;
