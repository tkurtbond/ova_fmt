--  ova_fmt - convert a YAML OVA character file into reStructuredText.
--
--  Only the terse backend exists so far (PLAN.md §9 step 2); HTML/
--  raw-ms/Lout are steps 3-5. Structure mirrors besm2_fmt_main.adb.

with Ada.Command_Line;
with Ada.Exceptions;
with Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Arg_Parser;
with Libfyaml;
with Libfyaml.Documents;
with Libfyaml.Documents.Streams;
with Libfyaml.Nodes;
with Ova_Fmt.Cli;
with Ova_Fmt.Config;
with Ova_Fmt.Entities;
with Ova_Fmt.Format_Terse;

procedure Ova_Fmt_Main is

   package Doc renames Libfyaml.Documents;
   package Streams renames Libfyaml.Documents.Streams;
   package Nod renames Libfyaml.Nodes;

   use type Arg_Parser.String_Reference;

   function Read_All_Standard_Input return String is
      Buffer : Unbounded_String;
   begin
      while not Ada.Text_IO.End_Of_File loop
         Append (Buffer, Ada.Text_IO.Get_Line);
         Append (Buffer, ASCII.LF);
      end loop;
      return To_String (Buffer);
   end Read_All_Standard_Input;

   --  Count is threaded across every document in the file: Entity_No
   --  is 1 for the first entity in a *file*, 2 for the second, etc.,
   --  regardless of how many "---"-separated YAML documents that file
   --  is split into (same convention as besm2_fmt_main.adb).
   procedure Process_Entities
     (D : Doc.Document; Source : String; Count : in out Natural)
   is
      Root : constant Nod.Node := D.Root;

      procedure Visit (Item : Nod.Node) is
         E : constant Ova_Fmt.Entities.Entity :=
           Ova_Fmt.Entities.Load_Entity (Item);
      begin
         Count := Count + 1;
         Ova_Fmt.Format_Terse.Process_Entity (E, Count);
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
   begin
      declare
         Stream : Streams.Document_Stream :=
           (if Use_Stdin
            then Streams.Open_String (Read_All_Standard_Input)
            else Streams.Open_File (Filename));
      begin
         while Streams.Has_Next (Stream) loop
            Process_Entities (Streams.Next (Stream), Source, Count);
         end loop;
      end;
   exception
      when E : Libfyaml.Parse_Error | Libfyaml.Missing_Key | Libfyaml.Data_Error |
               Program_Error =>
         Ada.Text_IO.Put_Line
           (Ada.Text_IO.Standard_Error,
            "ova_fmt: error processing " & Source & ": " &
            Ada.Exceptions.Exception_Message (E));
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
