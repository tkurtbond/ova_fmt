--  Ova_Fmt.Config - CLI-settable global configuration.
--
--  Deliberately small next to besm2_fmt.Config: PLAN.md §7/§9 settled
--  on terse (reST) as the first and, for now, only output format --
--  there's no BESM-style grid/hmm/raw-ms selector yet, so there's
--  nothing to select between. Fields are `aliased` so Ova_Fmt.Cli can
--  point Arg_Parser options at them via `'Access`, same pattern
--  besm2_fmt.Config uses.

with Arg_Parser;

package Ova_Fmt.Config is

   Output_File : aliased Arg_Parser.String_Reference;  -- -o/--output; null = unset (stdout)

   Underliner    : aliased Character := '=';        -- -u/--underliner
   Subunderliner : aliased Character := ASCII.NUL;  -- -U/--subunderliner; NUL = unset

end Ova_Fmt.Config;
