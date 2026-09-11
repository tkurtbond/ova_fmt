# pdf-experiment / ova_pdf — PLAN

## Purpose

A standalone, hand-written experiment (same role as `Fukiko-experiment.lout`
played for the Lout backend) to find out whether the `apdf` Alire crate
(`PDF_Out` package, v9.0.0) is a viable way to produce OVA character-sheet
PDFs *directly*, without going through groff/Lout/Pandoc. This lives in its
own Alire project (`pdf-experiment/ova_pdf/`) on branch `pdf-experiment`, and
is **not** wired into `ova_fmt` itself. Nothing here is committed to
`Ova_Fmt` sources until the design is proven — per the established
project workflow (experiment → real pipeline → surface tradeoffs → only then
touch the real backend).

The target is the "Fukiko" sample character spread from the OVA rulebook:
rulebook pp. 36-37, PDF pages 38-39 of
`~/Reference/RPG/OVA/OVA_The_Anime_Role-Playing_Game.pdf`.

## Explicit non-goals (per instructions)

Do **not** reproduce:
- The `OVA` logo header strip at the top of each page.
- The vertical "SAMPLE CHARACTERS" sidebar tab (and the page number that
  rides along with it — it's structurally part of that tab).
- The character artwork (Fukiko / Azyrus illustrations).

Everything else about the two pages' *look* — the name banner, rules,
boxes, tables, column layout, typography — is in scope.

## Reference material gathered so far

Page images rendered at 150dpi to
`/tmp/claude-1010/.../scratchpad/fukiko-038.png` / `-039.png`
(875×1241 px; page size confirmed via `pdfinfo` as 419.528 × 595.276 pt,
i.e. very close to ISO A5). These are scratch files, not committed.

Color-sampled (via Python/Pillow, dominant-color histograms) from crops of
both pages:

| Swatch | Hex | Used for |
|---|---|---|
| Maroon | `#731D20` | Name-banner fill, box header bars (Attacks & Combat Stats), section-heading text, ability/weakness value numbers, TV cell fill, big rule accents |
| Bright maroon | `#A11E22` | The small rounded "tab" behind the character name text, slightly more saturated than the main banner — a secondary accent, may just approximate with the same maroon if it's not worth a second constant |
| Panel background | `#EBE1E1` | Abilities/Weaknesses box background, "Other Statistics" area background |
| White | `#FFFFFF` | Attacks & Combat Stats box body background, page background, banner tagline text, header-bar text |
| Black | `#000000` | Body/trait/description text |

These are close approximations (anti-aliased edges/gradients exist, e.g. the
banner has a subtle lighter blend near the top-right) — good enough for a
"recreate the look" exercise, not pixel-forensics.

### Page 36 (left) — elements in scope

1. Name banner: a wide rounded-rect bar in maroon spanning most of the page
   width, with a slightly-brighter rounded "tab" at the left end sitting
   behind the character's name.
2. A dotted horizontal rule below the banner (the OVA books use a dotted
   rule as a section-break motif — reuse it under the banner and between
   sections).
3. "Background" heading (bold, maroon, small-caps-ish) with a thin rule
   underneath.
4. Body paragraph (originally wraps irregularly around the character art;
   we have no art, see *Design decisions* below).
5. "Personality" heading + rule + paragraph.
6. "Lovely Savior Myu Myu" heading (smaller than Background/Personality,
   italic-leaning) + paragraph.

### Page 37 (right) — elements in scope

1. "ABILITIES" / "WEAKNESSES" headings side by side, each with a thin rule.
2. A single rounded-rect panel (bg `#EBE1E1`) containing both columns, with
   a thin vertical divider between them.
3. Ability rows: bold maroon value (`+2`, `+4`, …) in a narrow left gutter,
   italic trait name to its right; the `Transformation` entry has an
   indented sub-list of the same shape (some entries wrap to a hanging
   second line, e.g. `Barrier`, and the `Focus` weakness).
4. "OTHER STATISTICS" heading + a label:value list (small-caps bold labels,
   plain values), positioned below the Abilities column, partly underneath/
   beside the Attacks box (the two boxes visually overlap in the original —
   Other Statistics sits behind/left of the Attacks panel).
5. "Attacks & Combat Stats" panel: maroon header bar (rounded top corners,
   white bold title) over a white body; 4 attack rows, each with:
   - Bold maroon attack name.
   - A small-caps tag line (e.g. `RANGED, AFFINITY: LOVE`).
   - An italic description sentence (replaced with lorem ipsum, phase 3).
   - Three right-hand sub-columns `ROLL` / `DX` / `END`, bold maroon
     caption over a large bold black number, separated by thin vertical
     rules; thin horizontal rules between rows.
   - A closing stat bar: `DEFENSE` / `HEALTH` / `ENDURANCE` / `TV`, same
     caption-over-big-number style, except the `TV` cell is inverted
     (maroon fill, white text).
6. Continuation body paragraph below-left of the two panels (flows from
   page 36's "Lovely Savior Myu Myu" section).
7. "Azyrus" heading + paragraph + a bold `Attributes:` lead-in line with
   the attribute list.

## Design decisions

- **Page size**: reproduce the original's own page size (≈ A5,
  419.5 × 595.3 pt via `PDF_Out.Rectangle`), not US Letter or A4. Matching
  proportions matters more than matching a "standard" size here.
- **No-image reflow**: keep the *original* column geometry (i.e. the
  Background/Personality text column stays at its original, narrower width
  where the artwork used to sit, leaving that area blank) rather than
  reflowing the paragraph to the full page width. This preserves the
  visual proportions/whitespace balance of the real page. *(Flagged here
  in case this reads as the wrong call once rendered — reflowing to full
  width is the obvious alternative and is a one-constant change if so.)*
- **Lorem ipsum scope**: per copyright policy ([[user-profile]] /
  `ova_fmt` convention — narrative prose isn't committed verbatim), lorem
  ipsum replaces only *prose*: the banner tagline quote, the Background /
  Personality / Lovely Savior Myu Myu / Azyrus paragraphs, and the four
  italic attack-description sentences, and the page-37 continuation
  paragraph. Game-mechanical data — ability/weakness names & values, stat
  block numbers, Other Statistics field values, the Attributes line — are
  short structural/mechanical data (not creative prose) and are
  transcribed faithfully, same as the rest of `ova_fmt`'s golden data.
  These count as **labels** (phase 2), not **text** (phase 3).
- **Dashed/dotted rules**: `PDF_Out` has no native dashed-line primitive
  exposed at the high level, but PDF itself does (`d` operator, dash
  array). Use `Insert_Graphics_PDF_Code (pdf, "[1 2] 0 d")` before a
  `Single_Line`/`Draw` call, then `"[] 0 d"` to restore a solid line
  afterward. Confirm this round-trips through `PDF_Out_File` in phase 1's
  first render.
- **Rounded rectangles**: no native primitive either. Build with
  `Move`/`Line` for the straight edges and `Arc` (or `Cubic_Bezier`) for
  the four corners, then `Finish_Path (close_path => True, rendering =>
  fill, rule => nonzero_winding_number)`. Verify corner radius looks right
  at panel scale before reusing the helper everywhere.
- **Fonts**: stick to the 14 standard PDF fonts (no embedding) —
  `Helvetica_Bold` for headings/labels/captions, `Times_Roman` for body
  prose, `Times_Italic` for descriptions/trait names, `Times_Bold` or
  `Helvetica_Bold` for big stat numbers. Exact typeface match to the
  rulebook isn't the goal; the *shape* of the layout is.
- **Program structure**: one Alire executable (`ova_pdf`), organized as it
  grows — likely `src/fukiko_style.ads` (color/coordinate/font constants +
  a rounded-rect/dashed-rule helper package) plus per-page drawing
  procedures in `ova_pdf.adb`, split into three call-sites per page
  (`*_Graphics`, `*_Labels`, `*_Text`) so each phase below is additive and
  independently reviewable/renderable. Exact split TBD once phase 1 code
  exists — don't over-design this up front.
- **Output**: `pdf-experiment/ova_pdf/Fukiko-experiment.pdf`, built via
  `alr build && alr run` (or `./bin/ova_pdf`), mirroring the
  `Fukiko-experiment.lout` naming convention.

## Build order (do not skip ahead)

### Phase 1 — Graphical elements only, zero text

Recreate every shape, fill, rule, and box border listed above for *both*
pages, with no labels, no numbers, no lorem ipsum — just the skeleton.
This proves out the rounded-rect helper, the dashed-rule trick, color
handling, and the two-panel overlap on page 37, before any text-layout
complexity gets mixed in.

**Definition of done**: `alr build`, run, open
`Fukiko-experiment.pdf`, and visually compare side-by-side against
`fukiko-038.png`/`fukiko-039.png` — silhouette should already read as
"the Fukiko spread" with everything unlabeled.

### Phase 2 — Labels

Add every heading, box title, column caption, ability/weakness name+value,
attack name+tag-line, stat number, and Other-Statistics field — i.e.
everything classified as "label"/game-data above, using `Font`/`Font_Size`/
`Put_XY`/`Bounding_Box` for placement. No prose paragraphs yet (leave those
areas blank, or place a placeholder rule showing where they'll go).

**Definition of done**: re-render and compare; every non-prose piece of
text on the two reference pages has a counterpart, correctly styled
(weight/color/case) and correctly positioned relative to its box.

### Phase 3 — Text (lorem ipsum, real formatting)

Fill in the prose regions identified in *Design decisions* with lorem
ipsum, but wrapped/justified/styled exactly as the original prose is:
same column width, same font/size/leading, same italic/bold treatment,
similar paragraph count and rough line count per paragraph (not necessarily
exact word-for-word length).

**Definition of done**: final re-render; the two pages should read, at a
glance, as a faithful *layout* recreation of rulebook pp. 36-37 with
placeholder prose — which is exactly the deliverable.

## Open questions / risks to watch for

- Whether `Bounding_Box`/manual line-wrapping is precise enough to justify
  the attack-description column width without a proper text-layout helper
  (may need something `Text_Layout`-like, borrowed in spirit from
  `besm2_fmt`, just for word-wrapping to a fixed pixel width — `PDF_Out`
  has no auto-wrap).
- Whether the page-37 panel overlap (Other Statistics behind/left of the
  Attacks box) is worth reproducing exactly, or safe to simplify to
  non-overlapping panels if it turns out fiddly — flag and ask rather than
  quietly simplifying.
- This experiment says nothing yet about whether `apdf` should *replace*
  or *supplement* the planned Lout backend (build-order step 7 in the main
  `ova_fmt/PLAN.md`) — that's a question for after this experiment, not
  during it.
