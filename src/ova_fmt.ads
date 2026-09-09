--  Ova_Fmt - root package of the ova_fmt program, an Ada tool
--  converting a YAML OVA character/template file into reStructuredText
--  (and, eventually, HTML/groff-ms/Lout output -- see PLAN.md). Design
--  notes, decisions, and open questions live in PLAN.md, not here.
--
--  Exists to anchor the Ova_Fmt.* child packages (Ova_Fmt.Entities,
--  Ova_Fmt.Cli, ...) -- a child unit's parent must itself be a real
--  library unit. The executable entry point is the separately-named
--  procedure Ova_Fmt_Main (src/ova_fmt_main.adb): a library unit can't
--  be both this package (for its children) and a procedure -- same
--  wrinkle besm2_fmt has, see its besm2_fmt.ads.

package Ova_Fmt is

end Ova_Fmt;
