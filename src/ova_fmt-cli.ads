--  Ova_Fmt.Cli - command-line argument parsing, built on Arg_Parser
--  (https://github.com/tkurtbond/arg_parser), same as besm2_fmt.Cli.

with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Arg_Parser;
with Ova_Fmt.Config;

package Ova_Fmt.Cli is

   package Filename_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Ada.Strings.Unbounded.Unbounded_String,
      "="          => Ada.Strings.Unbounded."=");

   Filenames : Filename_Vectors.Vector;
   --  Populated by Parse below, in command-line order. Empty means
   --  "read from stdin".

   Help_Requested : exception;
   --  Raised by Parse after printing the usage message; callers
   --  should exit with status 1, matching besm2_fmt.Cli's convention.

   procedure Parse;

private

   function Do_Help return Boolean;
   function Do_Subunderliner (Arg : String) return Boolean;
   function Do_Underliner (Arg : String) return Boolean;
   function Do_Argument (Start_With : Positive; Arg : String) return Boolean;

   Options : aliased Arg_Parser.Option_Array :=
     (Arg_Parser.Make_Option
        (Description => "Display this text.",
         Short_Name  => 'h',
         Long_Name   => "help",
         Handler     => Do_Help'Access),
      Arg_Parser.Make_Set_String_Option
        (Description => "Output file.",
         Short_Name  => 'o',
         Long_Name   => "output",
         Variable    => Ova_Fmt.Config.Output_File'Access),
      Arg_Parser.Make_String_Option
        (Description => "Entities after the first are subentities, and " &
                         "use a different character for underlining the " &
                         "subheader.",
         Short_Name  => 'U',
         Long_Name   => "subunderliner",
         Handler     => Do_Subunderliner'Access),
      Arg_Parser.Make_String_Option
        (Description => "Character to use for underlining the header.",
         Short_Name  => 'u',
         Long_Name   => "underliner",
         Handler     => Do_Underliner'Access));

   The_Parser : Arg_Parser.Parser :=
     Arg_Parser.Make_Parser
       ("ova_fmt [options] [files...]", Do_Argument'Access, Options'Access);

end Ova_Fmt.Cli;
