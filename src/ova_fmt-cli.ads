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
   function Do_Gemtext return Boolean;
   function Do_Markdown return Boolean;
   function Do_Html return Boolean;
   function Do_Groff return Boolean;
   function Do_Hmm return Boolean;
   function Do_Subunderliner (Arg : String) return Boolean;
   function Do_Underliner (Arg : String) return Boolean;
   function Do_Argument (Start_With : Positive; Arg : String) return Boolean;

   Options : aliased Arg_Parser.Option_Array :=
     (Arg_Parser.Make_Option
        (Description => "Display this text.",
         Short_Name  => 'h',
         Long_Name   => "help",
         Handler     => Do_Help'Access),
      Arg_Parser.Make_Option
        (Description => "Output gemtext (the Gemini protocol's hypertext " &
                         "markup) instead of reST.",
         Short_Name  => 'g',
         Long_Name   => "gemtext",
         Handler     => Do_Gemtext'Access),
      Arg_Parser.Make_Option
        (Description => "Output plain Markdown prose instead of reST.",
         Short_Name  => 'M',
         Long_Name   => "markdown",
         Handler     => Do_Markdown'Access),
      Arg_Parser.Make_Option
        (Description => "Output reST with nested HTML tables (a `.. raw:: " &
                         "html` block) for Abilities/Weaknesses/Combat/" &
                         "Attacks, instead of terse prose.",
         Short_Name  => 'H',
         Long_Name   => "html",
         Handler     => Do_Html'Access),
      Arg_Parser.Make_Option
        (Description => "Output reST with groff `hd` tables (`.. raw:: " &
                         "ms` blocks) laid out like the rulebook's own " &
                         "Sample Characters spread, instead of terse " &
                         "prose.",
         Short_Name  => 'G',
         Long_Name   => "groff",
         Handler     => Do_Groff'Access),
      Arg_Parser.Make_Set_Boolean_True_Option
        (Description => "With -g/--gemtext, emit *italic*/**bold** markers " &
                         "anyway -- gemtext's spec has no inline emphasis " &
                         "at all, but many authors use them as an " &
                         "unenforced convention. Off (plain text) by " &
                         "default; meaningless without -g/--gemtext.",
         Short_Name  => 'e',
         Long_Name   => "gemtext-emphasis",
         Variable    => Ova_Fmt.Config.Gemtext_Emphasis'Access),
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
         Handler     => Do_Underliner'Access),
      Arg_Parser.Make_Set_Boolean_False_Option
        (Description => "Turns OFF Unicode MINUS SIGN (U+2212) for negative " &
                         "numbers, reverting to ASCII hyphen-minus.",
         Short_Name  => 'n',
         Long_Name   => "no-unicode-minus",
         Variable    => Ova_Fmt.Config.Unicode_Minus'Access),
      Arg_Parser.Make_Set_Boolean_True_Option
        (Description => "Render an entity's options: block (which " &
                         "character-creation limiting rules were used), " &
                         "off by default.",
         Short_Name  => 'O',
         Long_Name   => "options",
         Variable    => Ova_Fmt.Config.Show_Options'Access),
      Arg_Parser.Make_Option
        (Description => "Output a tab-indented h-m-m outline instead of " &
                         "reST.",
         Short_Name  => 'm',
         Long_Name   => "hmm",
         Handler     => Do_Hmm'Access),
      Arg_Parser.Make_Set_Natural_Option
        (Description => "With -m/--hmm, indentation baseline (in tab " &
                         "stops) for the outline, so it can be embedded " &
                         "under an existing outline node elsewhere. " &
                         "Default 0 (left margin).",
         Short_Name  => 'L',
         Long_Name   => "hmm-depth",
         Variable    => Ova_Fmt.Config.Hmm_Depth'Access),
      Arg_Parser.Make_Set_Boolean_True_Option
        (Description => "With -m/--hmm, fold each of Abilities/Weaknesses " &
                         "onto one node (""Abilities: Ability1 +1 [...], " &
                         "..."") instead of a header node with one child " &
                         "node per item. Off by default.",
         Short_Name  => 'c',
         Long_Name   => "hmm-compact-lists",
         Variable    => Ova_Fmt.Config.Hmm_Compact_Lists'Access),
      Arg_Parser.Make_Set_Boolean_True_Option
        (Description => "With -m/--hmm, turn OFF *italic*/**bold**/" &
                         "***bold italic*** emphasis markers entirely. " &
                         "Off by default (emphasis is on).",
         Short_Name  => 'p',
         Long_Name   => "hmm-plain",
         Variable    => Ova_Fmt.Config.Hmm_Plain'Access));

   The_Parser : Arg_Parser.Parser :=
     Arg_Parser.Make_Parser
       ("ova_fmt [options] [files...]", Do_Argument'Access, Options'Access);

end Ova_Fmt.Cli;
