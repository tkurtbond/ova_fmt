# ova_fmt: porting `ova-rst.scm` (and finishing the design) to Ada

**Status:** planning / not started. This repo
(`~/Repos/RPG/Tools/ova_fmt`) currently contains only `.git` (no
commits yet). This file exists so a future session has everything
needed to pick the work up without re-gathering context.

## 1. Relationship to `besm2_fmt`

This is the second port in the same family as
[`besm2_fmt`](https://github.com/tkurtbond/besm2_fmt)
(`~/Repos/RPG/Tools/besm2_fmt`, `PLAN.md` there), which converts a
YAML BESM 2nd Edition character into reST/terse/h-m-m/raw-ms output
and is **complete** (all four backends, byte-for-byte verified
against the original Chicken Scheme `besm2-rst.scm`). `besm2_fmt` is
the model to follow for tooling, package layout, and lessons already
learned — but **unlike `besm2_fmt`, this is not a straightforward
port of a working, finished Scheme program.** The OVA source and its
test data are both unfinished, and the OVA domain model has real
structural differences from BESM's that need actual design work, not
just translation. See §4 and §5.

## 2. Source materials

All of the following are copyrighted works (Dyskami Publishing's
*OVA: The Anime Role-Playing Game* and its ancillary products); the
user has the normal personal-use rights to their own purchased/created
copies, not redistribution rights. Treat text extracted from them as
private local reference material — don't paste large verbatim excerpts
into files that get committed to `ova_fmt`'s git repo (which may end
up with a public remote, as `besm2_fmt` did at
`github.com/tkurtbond/besm2_fmt`).

Location: `~/Reference/RPG/OVA/`

- `OVA_The_Anime_Role-Playing_Game.pdf` — the full rulebook (170 pages).
- `ova-rulebook.txt`, `ova-rulebook-not-layout.txt` — text extractions
  of the rulebook (`ova-rulebook.txt` preserves the original two-column
  page layout with page numbers/running headers, so it's slower to
  read start-to-end but its line numbers correspond to physical pages;
  `-not-layout` reflows to single-column and is easier to `grep`). Both
  have now been read/searched for the sections relevant to this plan
  (see §2.2 for what that turned up). Table of contents (from
  `ova-rulebook.txt`'s first page), useful for further navigation by
  either file's page markers: Introduction (9), Creating a Character
  (17), Sample Characters (23), Abilities & Weaknesses (49), Taking
  Action (93), Combat, Health, & Endurance (103), Growth & Experience
  (115), Game Master's Section (119), Sample NPCs (133), Appendix:
  Telling Anime Stories (148), Index (158), Character sheet (164).
  Useful section anchors found so far (line numbers in
  `ova-rulebook-not-layout.txt` unless noted):
  - Character creation "fluff" fields: ~line 700.
  - Limiting-the-character rules (Scaled Cost, Base Zero, Combined
    Effectiveness, Power Ceiling): ~line 735–805, and again with fuller
    treatment at "Base Zero" (11141), "Combined Effectiveness" (11190),
    "Power Ceiling" (11652), "Scaled Cost" (11745).
  - Sample Characters chapter starts ~line 857 (Raine first; see §2.2
    for the full chapter's significance for this project).
  - Magic, Arcane / Magic, Witchcraft rules: `ova-rulebook.txt` lines
    ~2461–2530 (Spell Endurance Cost table, spell-casting DN formula,
    the "a spell mimics another Ability's Level" mechanic — see §2.2).
  - Transformation: `ova-rulebook.txt` lines ~2786–2810. Vehicle
    (Mecha) and Companion (via `abilities.md`): `ova-rulebook.txt`
    lines ~2820–2832 for Vehicle — see §2.2 for the separate-Health/
    Endurance and non-cumulative-Abilities wrinkle.
  - Threat Value (GM-facing balancing number, `combat.tv`'s
    derivation): `ova-rulebook.txt` lines ~5684–5736.
- `OVA-Blank-Character-Sheet-Form-Fillable.pdf` — the official blank
  character sheet. Confirms the canonical field set (see §5).
- `OVAPlayerBook-Auren-2015-01-29.pdf`,
  `OVAPlayerBook-Miho-2015-01-29.pdf`,
  `OVAPlayerBook-Raine-2015-01-29.pdf` — 14-page pregenerated-character
  booklets (one of the sample characters each). The character-sheet
  spread (physical pages 4–5 of each PDF — labeled "2"/"3" in-page,
  offset by front/back cover pages) has been read for all three and is
  now the best available reference for what a *finished, laid-out*
  character write-up looks like — see §2.1. Good candidates for
  additional golden/test fixtures once the YAML schema is settled,
  since they're full worked characters with combat suites, background,
  etc. (Auren already has a partial test-data file, see §6.)
- `ova-ref.pdf` (16KB, 2 pages) — a reference sheet the user made
  themselves (not a Dyskami product, so no third-party copyright
  concern on this one specifically). Already read in full. Contents:
  Abilities index with page numbers and a `(A)`/`(D)`/`(DX)`/`(I)`
  legend for which roll type each Ability affects; Weaknesses index;
  Perks and Flaws tables with Endurance cost and page numbers (Perks
  positive-Endurance-cost, Flaws negative, some marked `/M` = "can be
  taken multiple times" or `/n` = "can be taken n times"); Affinities
  page pointer; core mechanics summary (Taking Action, Difficulty
  Numbers, Initiative, Attack/Defend, Damage, Combat Complications,
  Drama Dice, Damaging Other Things, Other Combat Actions, Spell
  Endurance Cost table, Spell Casting Roll formula, NPC tiers). This is
  the best single condensed source for the game's numeric rules and is
  worth re-reading closely once designing the "derived stats" /
  validation side of the tool (if any — see open questions).
- `abilities.md` (98 lines), `weaknesses.md` (220 lines) — apparently
  hand-transcribed (or extracted) full-text Markdown of every Ability's
  and Weakness's rules description, keyed by **bold name** headers.
  Useful as a name/canonical-spelling reference and for any
  "look up this ability's description" feature, but not yet cross
  checked against the ref sheet's page-number index for completeness.
- `~/Reference/Document-Tools/lout/` — Basser Lout documentation, not
  OVA-specific: `design.pdf` (design rationale), `expert.pdf`
  (advanced/extension-level reference), `slides.pdf` (overview slide
  deck), `user.pdf` (the main user guide). Not yet read; earmarked for
  step 5 of §9's build order (the direct-to-Lout backend) —
  `user.pdf` is the likely primary reference for `@Doc`/`@Tbl` usage,
  `expert.pdf` for anything `Fukiko-experiment.lout` (§3) does that
  needs deeper explanation than the user guide covers.
- `OVA-Combat.odt`/`.pdf`, `OVA-ConversionGuide.pdf`,
  `OVA-Character-Sheet.ods`/`.pdf`,
  `OVA-Charsheet-Template-Google-Sheets.pdf`,
  `OVA-CharacterRecord-A4.pdf`/`-Letter.pdf`, `OVA-CharacterSheet.zip`,
  `ovasheet-new.pdf` — present in the directory but not yet reviewed;
  likely more character-sheet variants and a combat-rules cheat sheet.
  Check these before assuming the blank fillable sheet (§5) is the only
  layout reference.

### 2.1. Player-book character-sheet layout (read in full)

Physical pages 4–5 of each of the three player-book PDFs (Auren,
Miho, Raine) show a name/tagline header, two-column
Background/Personality prose (page 4), then a full character-sheet
spread (page 5): Abilities/Weaknesses two-column list, an "OTHER
STATISTICS" fluff block, and an "Attacks & Combat Stats" box. This is
real, professionally laid-out output for the exact data shape
`ova_fmt` needs to produce, so it's worth documenting precisely —
paraphrased/structural notes below, not verbatim prose (per §2's
copyright note):

- **Header**: character name (large), then a short italicized
  first-person tagline/catchphrase next to it — an in-character quote,
  now formalized as the `tagline` schema field (decided, §4); the
  current test data doesn't have a `tagline` key yet, but should once
  test data is generalized (§9 step 1).
- **Background / Personality**: prose sections with bold section
  headers, laid out in two newspaper columns across the page. Maps
  directly onto `background`/`personality` in the existing test-data
  shape.
- **Abilities / Weaknesses** (two side-by-side columns, one heading
  each): each entry is a signed Level number in a narrow left column,
  then the Ability/Weakness name in italics, with a parenthetical
  detail where relevant (`Attack (Sword & Sorcery)`,
  `Code of Conduct (Protecting Women... Begrudgingly)`). **Nested
  items render two different ways depending on the parent ability**,
  a real finding not obvious from the test data alone:
  - Miho's `Transformation` ability (+1) has its own sub-abilities
    indented beneath it, and **each sub-item keeps its own leading
    signed Level** (`+2 Combat Expert`, `+2 Endurance Reserve`, `−3
    Unique Weakness (Loss of Control)` — note a Weakness nested inside
    an Ability's sub-list, not segregated into a separate
    sub-weaknesses column). This matches `Fukiko.yaml`'s
    `Transformation.abilities`/`.weaknesses` shape (each sub-item has
    its own `name`/`level`).
  - Auren's `Magic, Arcane` ability (+3) has its spells indented
    beneath it too, but **spells render with no separate leading
    Level at all** — just the spell name followed by a parenthetical
    summary folding in its Perks and Endurance cost as plain text
    (`Mana Shield (Barrier +2; 10+ Endurance)`, `Hasten (Quick +3; 20
    Endurance)`). This is a genuinely different rendering rule from
    Transformation's sub-abilities, not just a formatting accident —
    worth confirming against the rulebook's Magic section (p. 57–58)
    whether spells even *have* a Level of their own the way
    Transformation's sub-abilities do, or whether "Ability Level"
    there is more like a Perk grade. **Design consequence:** the Ada
    domain model likely needs to distinguish at least two kinds of
    "linked ability" content (Transformation/Companion/Vehicle-style
    sub-abilities-with-levels vs. Magic-style spells-with-perks-and-
    no-own-level), not treat all nesting uniformly — matches
    `Auren.yaml`'s existing `spell:`/`perks:` shape already looking
    different from `Fukiko.yaml`'s `Transformation.abilities` shape
    (§6), so this may not have been an accident/typo after all, but
    early recognition of this exact distinction.
- **"OTHER STATISTICS"** (the rendered fluff block): a bold-label
  colon-value list, one per line — `CONCEPT`, `BIRTHDAY`, `AGE` (Miho's
  shows a narrative aside: `1 (Appears 18)`, Auren's similarly `44
  (Appears 16)` — the character sheet's `age` field can carry
  prose, not just a bare number), `GENDER`, `HEIGHT`, `WEIGHT`,
  `HAIR`, `EYES` is *omitted* in all three samples (present in the
  rulebook's suggested field list and `fluff.yaml-partial`, but every
  finished sample here skips it), `ASSOCIATION`, `HOBBIES`, `FAVE
  FOOD` (label abbreviated from "Favorite Food" — cross-check against
  `Fukiko.yaml`'s `favorite-food` key, which spells it out fully;
  likely just a display-label abbreviation, not a schema difference),
  `ALLIES` (Auren/Raine: `None`), `ENEMIES`. **None of the three shows
  a Love Interest(s) line** even though it's in the rulebook's
  suggested fields and `fluff.yaml-partial` — apparently an
  omit-if-blank field, consistent with `ALLIES: None` showing rather
  than being omitted (i.e., the field is shown with an explicit "None"
  when applicable/known, but dropped entirely rather than shown blank
  when simply not used for that character — a distinction the schema
  and formatter should probably support: an explicit "None" value vs.
  an absent key are different things to render differently).
- **"Attacks & Combat Stats"** box: each attack is its own row/block,
  in this shape — bold attack **name**; a line of perks/flaws in
  small caps, **comma-separated Perks first, then a semicolon, then
  comma-separated Flaws** (e.g. `AREA EFFECT, ARMOR PIERCING,
  OVERWHELMING, RANGED, AFFINITY: ICE; FEATHER BLOW, INEFFECTIVE` —
  Perks before the `;`, Flaws after), with **`AFFINITY: <name>`
  embedded directly in the Perks list** rather than shown as its own
  field, and a repeatable perk/flaw's count rendered as a suffix on
  the name (`EFFECTIVE X2`, `INACCURATE X3`, `ACCURATE X2`) rather
  than as a separate number — confirms `ova-ref.pdf`'s `/M`
  ("multiple") perks/flaws use this `Name X<n>` convention in finished
  prose, not `Name (n)` or `Name: n`; then three large numbers under
  `ROLL` / `DX` / `END` headers; then one italicized sentence of
  flavor description. `Weapon` itself shows up as a **Flaw** tag on
  melee attacks (Raine's `Kaze Satsujinsha`: `ARMOR PIERCING; WEAPON`)
  — matches `ova-ref.pdf`'s Flaws table (`Weapon −5`) rather than
  being a separate attack property. After all attacks, one final
  summary row: `DEFENSE` / `HEALTH` / `ENDURANCE` / `TV`, each as one
  large number — all three player-book samples show a single plain
  Defense integer (Auren 4, Miho 5, Raine 5), unlike `Fukiko.yaml`'s
  paired `defense: "4/5"`; §2.2 (reading the primary rulebook, which
  includes all 12 sample characters rather than just these 3) confirms
  the pairing is real and not unique to Fukiko, just apparently
  optional per-character — see §2.2 and the open questions for what's
  now confirmed vs. still unexplained about it. Attacks render in
  table order *before* the Defense/Health/
  Endurance/TV summary — i.e. opposite of the field order
  `Fukiko.yaml`'s `combat:` mapping currently uses
  (`defense`/`health`/`endurance`/`threat-value` first, `attacks:`
  last); purely a presentation-order choice for a formatter to make,
  not something the YAML's own field order needs to match.
- **No worked example of Companion or Vehicle (Mecha) nesting** was
  seen in these three (none of Auren/Miho/Raine's sample sheets uses
  those two linked-ability types) — Transformation and Magic are the
  only two nesting shapes confirmed from primary sources so far.

### 2.2. Rulebook findings: the Sample Characters chapter, and three resolved modeling questions

Reading `ova-rulebook.txt` directly (rather than only the player books
and `ova-ref.pdf`) turned up one major resource and resolved several
of §2.1's/earlier open questions:

- **The rulebook's own "Sample Characters" chapter (p. 23–48) contains
  all twelve pregenerated characters' full write-ups**, in the exact
  same layout style documented in §2.1 (name/tagline header,
  Background/Personality prose, Abilities/Weaknesses columns, Other
  Statistics, Attacks & Combat Stats box) — the three player books
  (Auren, Miho, Raine) are just standalone excerpts of three of these
  twelve. **This is a substantially better golden-data source than
  either the player books or the hand-authored `test-data/*.yaml`
  files**: it's the original, primary presentation (confirmed
  byte-identical in content to what the Auren player book excerpts,
  so the player books are a reliable secondary check, not an
  independent source), and it covers 12 characters' worth of variety
  in one place — different combinations of nesting (or none),
  attack-suite sizes, fluff completeness, etc. — rather than 3. Found
  by locating each character's `Background` heading
  (`ova-rulebook.txt` lines 655, 772, 877, 1016, 1139, 1252, 1365,
  1478 [Fukiko], 1600 [Auren], 1693, 1822, 1922); Fukiko's full spread
  is at lines 1415–1471, Auren's at 1528–1554+. **Recommend
  transcribing test/golden fixtures from this chapter directly**
  (respecting §2's copyright note — transcribe the structured
  game-mechanical data, i.e. the actual YAML-shaped facts, not the
  prose Background/Personality paragraphs verbatim beyond what's
  needed for a realistic fixture) rather than relying solely on the
  incomplete/inconsistent `test-data/*.yaml` files (§6) or the 3
  player-book excerpts.
- **Resolved: why Magic's nested "spells" don't show their own
  Level** (§2.1's open question). The Magic, Arcane rules text
  (`ova-rulebook.txt` ~2461–2530) spells this out directly: a "spell"
  isn't a distinct thing with its own Level at all — casting one means
  *mimicking another Ability's effect*, at some Level of that mimicked
  Ability, by spending Endurance looked up from a two-axis "Spell
  Endurance Cost" table (mimicked Ability's Level across, caster's own
  Arcane-Magic-or-Witchcraft Level down; e.g. Level-2 Ability × Level-3
  caster = 10 Endurance). So Auren's `Mana Shield (Barrier +2; 10+
  Endurance)` reads as: a spell named "Mana Shield," which mimics the
  Barrier Ability at Level 2, costing 10+ Endurance to cast. **The
  Level shown belongs to the mimicked Ability field, not to an
  independent "spell level."** This means `Auren.yaml`'s existing
  `spell:`/`perks:` shape (§6) was closer to correct than
  `Fukiko.yaml`'s uniform `abilities:`/`level:` nesting suggests — a
  Magic-linked "spell" item's schema needs fields for (at least) the
  spell's own flavor name, the mimicked Ability's name + Level, and
  the Endurance cost, which is a genuinely different shape from a
  Transformation-linked sub-ability's plain `{name, level}}`.
- **New finding: Vehicle (Mecha) doesn't just nest — it can need a
  wholly separate combat sub-block.** `ova-rulebook.txt` ~2820–2832
  (Vehicle) states its granted Abilities/Weaknesses are **not
  necessarily cumulative** with the pilot's own (unlike Transformation
  and Companion, which explicitly are/imply are), and, more
  structurally significant: **"Health and Endurance are no longer
  linked"** — a Vehicle has its own separate Health and Endurance
  totals, damaged/depleted independently of the pilot's. This means a
  Vehicle-type linked ability may need to carry its own nested
  `combat`-shaped sub-block (at least health/endurance, possibly its
  own Defense/attacks too, if built "with specific attributes much as
  you would a character" per that same passage), not just a nested
  abilities/weaknesses list the way Transformation/Magic do. No
  worked Vehicle example was found in any of the 12 sample characters
  or 3 player books to confirm the exact YAML shape this implies —
  still an open item, but now a sharper one (§ open questions).
- **Resolved: `combat.defense: "4/5"` is real, and the split is the
  Barrier Ability's alternate Defense Roll, not a main-form/
  transformed-form split.** The rulebook's own printed Fukiko sheet
  (`ova-rulebook.txt` line 1461: `4/5 30   40 12` under `defense /
  health / endurance / tv`) matches `Fukiko.yaml`'s `defense: 4/5`/
  `health: 30`/`endurance: 40`/`threat-value: 12` exactly — an
  accurate transcription from the source, not test-data corruption.
  The user's first hypothesis was that the pair represents Defense in
  a character's normal form vs. their Transformation-driven form; the
  rulebook's Barrier Ability entry (`ova-rulebook.txt` ~2129–2152)
  gives the actual mechanism instead: *"Instead of making a normal
  Defense Roll in combat, you may roll your Barrier dice"* — i.e. any
  character with Barrier has **two independent Defense options**
  available simultaneously (their normal Defense Roll, or their
  Barrier dice as an alternative), and a paired Defense on a sample
  sheet is presenting both at once. Confirmed against a second,
  cleanly separating example: **Ai** (`ova-rulebook.txt` line
  ~1654, another of the 12 sample characters) has `+3 Barrier (no
  gesture; 5 end)` as a **plain top-level Ability with no
  Transformation at all**, and her Defense is *also* printed paired
  (`4/5`, `ova-rulebook.txt` line ~1691) — so the pairing tracks
  "has Barrier," not "has a transformed alternate form." Fukiko's
  case happens to acquire Barrier *through* Transformation (so her
  two numbers are only both meaningful while transformed), which is
  presumably what suggested the main-form/transformed-form reading,
  but Ai's case shows that's a coincidence of how she got Barrier, not
  the general rule.

  **Decided (user, following this finding):** still render Defense
  as printed on the source sheet — `4/5` etc. — verbatim; don't try to
  relabel it as two separate named fields or derive it purely from
  "has Barrier" at render time (a character sheet's Defense field
  stays a simple int-or-slash-pair value in the schema, closer to
  `Fukiko.yaml`'s existing `defense: "4/5"` than to the
  Consequence-for-the-schema idea floated in the first draft of this
  finding). Instead, **the Barrier Ability's own list entry should
  carry a short explanatory note** when it grants an alternate
  Defense Roll — e.g. rendering Fukiko's Transformation-nested
  `Barrier +3` as `Barrier +3 (area effect; elaborate gestures; 5
  end; alternate Defense Roll)` or similar terse parenthetical, so a
  reader can connect the sheet's paired Defense number back to the
  Ability that produces it without the formatter having to compute
  or explain the relationship structurally. Exact wording/placement
  of the note (baked into `Text_Layout`'s Barrier-specific rendering
  vs. a `note`/`detail` field on the ability data itself) is still to
  be designed once `Ova_Fmt.Entities`/format backends are underway —
  but the direction is: keep Defense simple and literal, put the
  explanation on Barrier instead.

### 2.3. Karis/Arasuni: a full nested-Companion example, and the terse-format target

**Karis** (`ova-rulebook.txt` lines 874–1012, another of the twelve
sample characters, p. 28–29) settles the "how does a Companion
write-up actually appear" question left open in §9's original step 1
— and the user separately supplied a concrete terse-format mockup for
this same character, so both are captured together here.

- **Companion can get a full nested character sub-block, not just a
  prose summary.** Unlike Fukiko's Azyrus (§2.1 — a one-line
  `Attributes: Flight +2, Quick +1, Smart +2; ...` prose summary with
  no combat stats of its own), Karis's Companion **Arasuni gets his
  own complete second Abilities/Weaknesses column pair, his own
  "Attacks & Combat Stats" box, and his own Defense/Health/Endurance/
  TV row**, laid out right alongside Karis's own on the same spread
  (explicitly headed "Attacks & Combat Stats (KARIS)" and "Attacks &
  Combat Stats (ARASUNI)" in the source). Arasuni: Abilities `+2
  Armored, +1 Attack, +1 Combat Expert, +1 Evasive, +3 Life Support,
  +3 Strong, +2 Tough, +1 Unique Ability (Computerized Brain)`;
  Weaknesses `−1 Awkward Size (Large), −2 Bizarre Appearance, −2
  Emotionless, −1 Quirk (Quoting Earth), −3 Servitude (Karis), −1
  Slow, −2 Vulnerability (Electricity)`; two attacks (`Iron Knuckle`,
  `Stun Pulse Rifle`); `defense 2, health 40, endurance 20, tv 10`.
  Note Arasuni's own `Servitude (Karis)` Weakness — the two entities
  cross-reference each other by name. **Consequence:** a Companion
  (and by extension, per §2.2, presumably Vehicle too) needs to
  support being represented as a **complete embedded sub-entity**
  (its own abilities/weaknesses/combat, i.e. structurally
  self-similar to a top-level entity) when it has real
  game-mechanical presence — not *only* the simpler prose-summary
  shape `Fukiko.yaml`'s `notes[]` currently models. Both shapes are
  now confirmed real (Azyrus is prose-only; Arasuni is a full
  sub-entity), so the schema likely needs to support both, probably
  as the author's choice depending on how mechanically detailed a
  given companion needs to be.

  **Refined** (while fixing up `test-data/sample-pcs/Fukiko.yaml` to match the
  settled schema, §9): this isn't really two unrelated shapes — it's
  **one shape with optional depth**. Every Companion now gets a
  `companion:` sub-block with `abilities:`/`weaknesses:` (Azyrus's
  book sheet does give him exact Levels — `Flight +2, Quick +1, Smart
  +2; Awkward Size (Small) −1, Frail −1, Short-Tempered −1` — even
  though the old `Fukiko.yaml` only stored them as prose); a
  `combat:` block is added only when the source actually gives the
  companion its own attacks/Defense/Health/Endurance/TV (Arasuni,
  Fenrir), which Azyrus's sheet doesn't. So there's no "prose-only
  vs. full sub-entity" branch in the schema after all — just whether
  `combat:` is present, same as how a main entity's own `combat:`
  presumably isn't strictly mandatory either.
- **The user's terse-format mockup for Karis** — given directly, as
  "one example of how Karis might appear in terse form," then
  clarified after review: **it was originally written in Markdown for
  a different purpose (an actual game session) and customized for
  that session, so it is not the book's Karis and its specific values
  (names, numbers) are not to be treated as accurate/canonical — use
  it only for organization and structure.** Two follow-up decisions
  from that clarification:
  - **Terse output is reST, not Markdown** — decided, resolving the
    format-choice open question below. Only the heading/list syntax
    changes from the mockup as given; the inline `**bold**`/`*italic*`
    markup is identical in both and needs no translation.
  - **The italicized one-line summary under the name is a new,
    author-written schema field**, not derived from `background` —
    tentatively named `summary` (§ schema below).

  Structure only (not the specific names/numbers, per the
  clarification above), translated to reST:

  ```rst
  Karis (Hotheaded Space-Trekking Bounty Hunter)
  ================================================

  *<summary — one author-written sentence>*

  - **Abilities:** Name (detail) Level, Name Level, ... .
  - **Weaknesses:** Name (detail) Level, Name Level, ... .
  - **Health:** N | **Endurance:** N | **Defense:** N | **Threat Value (TV):** N
  - **Attacks:**

    - **Attack Name:** Roll **N dice** | **DX N** | **Endurance Cost: N** (Perks: ...; Flaws: ...). *Optional flavor sentence.*
    - **Attack Name:** Roll **N dice** | **DX N** | **Endurance Cost: N** (Perks: ...; Flaws: ...). *Optional flavor sentence.*
  ```

  Conventions worth carrying forward from the mockup's *structure*
  (independent of its unreliable specific values):
  - Header: `Name (concept)` as a reST title (underlined, matching
    `besm2_fmt`/`ova-rst.scm`'s terse-mode convention of an
    underlined entity header) — the parenthetical is `fluff.concept`,
    not a quoted `tagline` (contrast the player books' quoted
    catchphrase under the name, §2.1) — followed by the new `summary`
    field, italicized.
  - Abilities/Weaknesses: one comma-separated sentence each, `Name
    (detail) Level` order (detail immediately after name, level last
    — differs from the character-sheet convention of `Level Name
    (detail)`, §2.1/§2.2), ended with a period.
  - Combat summary: one line/list-item, `**Health:** N | **Endurance:**
    N | **Defense:** N | **Threat Value (TV):** N` pipe-separated.
    (The mockup's trailing `(-5)` after TV was part of the
    session-specific customization the user flagged as unreliable —
    dropped from the structural template above; no longer treated as
    a feature to explain or implement.)
  - Attacks: nested list, one per attack: `**Name:** Roll **N dice** |
    **DX N** | **Endurance Cost: N** (Perks: ...; Flaws: ...).`
    followed by an optional italicized flavor sentence. Perks/Flaws
    are **explicitly labeled** (`Perks: ...; Flaws: ...`) — clearer
    than the character sheet's unlabeled `PERKS...; FLAWS...`
    convention (§2.1), worth keeping since it removes the reader's
    need to already know the Perks-before-semicolon/Flaws-after
    convention. "Roll **N dice**" spells out "dice" explicitly —
    matches the confirmed mechanic (§2.2/§2.3: `Roll` is a dice
    *count*, `2` base dice + applicable Ability Levels).

## 3. Existing (unfinished) OVA tooling

Location: `~/current/RPG/Tools/OVA/` (Chicken Scheme, same toolchain
family as `besm2-rst.scm`: `args`, `bindings`, `(schemepunk show)`,
`loop`, `matchable`, SRFI 1/152, the `yaml` egg over `libyaml`).

- `ova-rst.scm` (204 lines) — the stub. `README.rst` states outright:
  *"Right now nothing in this repository works. I'm still hashing over
  ideas for how to represent OVA characters in YAML... The current
  `ova-rst.scm` is merely a skeleton."* Structurally it already has the
  CLI/dispatch skeleton (`process-file`/`process-filename`/`main`,
  `+command-line-options+` for `-h`, `-m`/raw-ms, `-o`/output,
  `-t`/terse, `-U`/`-u` underline chars) mirroring `besm2-rst.scm`'s
  shape, but the actual per-entity formatters are stubs:
  - `process-entity` — returns `#f` immediately, no output at all.
  - `process-entity-raw-ms` — same, returns `#f` immediately.
  - `process-entity-terse` — the only one with real logic. It computes
    `abilities-total`/`weaknesses-total`/`attributes-total` (flat sum of
    each list's `level` field) and renders `**Attributes:**` /
    `*Abilities:*` / `*Weaknesses:*` lines. Its own header comment block
    sketches the intended terse output shape modeled on Azyrus (OVA
    p. 37, a companion character write-up) — see the comment at
    `ova-rst.scm:73-91` for the target prose format. **This does not
    handle nested/linked abilities at all** (e.g. Transformation's own
    sub-abilities/sub-weaknesses in `Fukiko.yaml`) — it just does
    `(must-exist "level" ability)` on every top-level item.
  - No h-m-m backend exists for OVA (unlike besm2-rst.scm's four
    backends) — not yet decided whether one is wanted.
- `GNUmakefile` — mirrors `besm2_fmt`'s predecessor pattern: builds
  `build/ova-rst` via `csc`, generates `.gen.rst`/`-terse.gen.rst`/
  `-ms.gen.rst` per test-data file, then `pandoc`-based downstream
  targets (`.ms`/`.ms.pdf` via a custom `tkb` template with
  `-V twocolumns`, `.stmt.ms`/`.stmt.ms.pdf` via a `statement`
  template, `.native`, `.html`), plus `yamllint -f parsable` targets
  and a `lout`-based experiment (`Fukiko-experiment.lout` →
  `build/Fukiko-experiment.lout.pdf`, via `lout`+`ps2pdf`) that appears
  to be a parallel, non-Scheme typesetting experiment for the same
  Fukiko data — worth looking at once layout for nested attributes
  needs solving (§4), since it may contain earlier attempts at exactly
  that problem. `RPBHENTITIES` (`FV2021-Coleopteran enyon-boase
  pawl-cardynham nessa-kitto`) is leftover from `besm2-rst`'s makefile
  and doesn't correspond to any OVA test-data file — dead/copy-paste
  cruft, not a hint about OVA content.
- `columns.scm` (208 lines) — a **scratch/experiment file, not part of
  the program**, but it records a real, already-discovered design
  problem (see its own header comment, kept verbatim since it's the
  clearest statement of the issue):

  > I think this has proved that monadic formatting can't generate the
  > correct HTML tables... Specifically, for HTML, its columns divide
  > things into characters and lines, but recursive OVA things like
  > Magic (Arcane and Witchcraft), Transformation, and so forth need
  > cells that can contain tables. What I got, rather than one `<tr>`
  > that contains a table, is one `<tr>` for each line in the subtable.
  > ... For text output, it has no way to handle subtables, and if you
  > try to wrap things, the costs get out of sync with the
  > descriptions, since the wrapping adds extra lines to the
  > descriptions.

  **Correction (from the user, since this was initially
  misread):** HTML tables themselves handle nesting fine — a `<td>`
  can contain a whole `<table>` with no problem. The failure
  `columns.scm` actually demonstrates is that `(schemepunk show)`'s
  monadic column combinators (`columnar`/`tabular`/`wrapped`) have no
  way to *build* a nested table — they only know how to lay out flat
  rows of already-linearized text, so a sub-table gets flattened to
  one row per line instead of staying a nested element. The problem is
  in the formatting library used, not in HTML as a target. This
  matters for the design: it means **hand-emitting real nested
  `<table>` markup directly (not through any row/column layout
  abstraction) is a fully workable answer for HTML** — see §8 for the
  resulting output-format-by-output-format strategy, which settles
  this rather than leaving it as an open modeling question.

  For plain fixed-width text output (terse, reST's own table syntax),
  the underlying problem is real regardless of library: a monospace
  grid genuinely cannot represent a nested table without breaking
  either row alignment or the sub-table's own structure. §8 avoids
  the problem there too, by not using tabular layout for OVA's default
  text output at all.
- `x.scm` (71 lines) — scratch REPL exploration of what the `yaml` egg
  produces for `Fukiko.yaml` and for a couple of hand-written
  multi-document YAML strings (`yaml<-` vs `yaml-load`, `-1` for "all
  documents"). Confirms `yaml-load` on a single-document file gives a
  list of alists as expected; the multi-document exploration is
  relevant background for the same "does the loader silently collapse
  multiple documents" question `besm2_fmt`'s `PLAN.md` §"Open
  questions" already answered for BESM (yes, Chicken's `yaml-load`
  keeps only the last document — `alibfyaml`'s `Document_Stream`
  fixes this properly in Ada). No OVA-specific finding beyond
  confirming the same loader is in play.
- `interactive.scm` (10 lines) — trivial REPL scratch (loads
  `Fukiko.yaml`, one `wrapped` call). Nothing to carry forward.
- `Fukiko-experiment.lout`/`.lout.ld` — a Basser Lout typesetting
  source, not Scheme; the makefile builds it straight to PDF
  (`lout -a ... | ps2pdf`), independent of `ova-rst.scm`. **Read in
  full — it is exactly the worked nested-table example the design
  needs.** It hand-codes a curved-box character sheet fragment for
  Fukiko using Lout's `@Tbl` (the `tbl` package), two side-by-side
  top-level tables (Abilities, Weaknesses, each `aformat`/`bformat`
  two-column: level-with-trailing-caret `A` | name/description `B`),
  and — the important part — the Transformation row's `B` cell
  contains a **complete second `@Tbl { ... }` block** for its four
  sub-abilities (Attack, Barrier, Combat Expert, Healer) plus the
  linked Bizarre Appearance sub-weakness, using `{@Sym minus}` for a
  real minus sign glyph rather than ASCII hyphen. This is a genuine,
  already-functioning proof that Lout's table model nests cleanly
  (unlike groff `tbl`, §8), and is the reference to build
  `ova_fmt`'s eventual Lout emitter's Abilities/Weaknesses table
  against, rather than reinventing the markup shape from scratch.

## 4. Domain model differences from BESM (why this isn't a 1:1 port)

Reading `Fukiko.yaml`/`Auren.yaml`/`Acacia.yaml`/`template.yaml`
against the rulebook and `ova-ref.pdf` surfaces these structural
differences from `besm2_fmt`'s BESM model:

- **Two top-level lists, not three.** OVA has just Abilities and
  Weaknesses (both just "Attributes" with a signed Level — Abilities
  positive, Weaknesses negative, per `ova-ref.pdf`'s "Taking Action is
  Two Dice + Abilities & Bonuses − Weaknesses & Penalties"). No
  separate Stats list, no separate Skills list, no BESM-style
  points/CP bookkeeping — OVA "spends" Levels directly (Base
  Zero/Power Ceiling/Scaled Cost, §2's rulebook pointers), not an
  abstract point-buy currency the way BESM's `points` field is.
- **Nesting.** Abilities like Transformation, Magic (Arcane/
  Witchcraft), Companion, and Vehicle (Mecha) contain their own
  sub-abilities and sub-weaknesses (see `Fukiko.yaml`'s
  `Transformation.abilities`/`.weaknesses`, `Auren.yaml`'s `Magic,
  Arcane.spells`). This is the load-bearing design problem — see §3's
  `columns.scm` discussion. Not present in BESM's model at all
  (BESM's enhancements/limiters are flat string/tuple modifiers, never
  a recursive attribute list).
- **Perks and Flaws customize *any* Ability, not just attacks —
  corrected from an earlier draft of this plan.** The rulebook is
  explicit (`ova-rulebook-not-layout.txt` ~5792–5824): *"Ability Perks
  and Flaws ... provide additional ways to customize your Abilities
  and are listed as a subset of them. It's sort of like applying
  Abilities and Weaknesses to the Ability itself... For any Ability
  you feel can be further individualized through Perks and Flaws,
  simply go through the list and assign those that fit your mental
  image. Some Abilities mention the use of Perks and Flaws right in
  their text, but they can be applied to others as well."* So this is
  a **general Ability-modifier mechanic** — structurally exactly like
  BESM's enhancements/limiters (a name plus a signed Endurance-cost
  effect, `besm2_fmt`'s `format-customizers` dispatch shape is a
  reasonable starting point), attachable to any Ability whatsoever:
  a plain top-level Ability (Ai's `Barrier (no gesture; 5 end)`, §2.2,
  is a top-level Ability with a Flaw on it, not an attack), a
  Transformation/Magic-linked sub-ability (`Fukiko.yaml`'s Barrier
  sub-ability), *or* an Attack-Ability-based attack entry in
  `combat.attacks[]`. Attacks just happen to be where Perks/Flaws are
  most visible and most often used, since — per the same passage —
  *"Perks and Flaws that specifically mention attacks are usually best
  used with the Attack Ability"* (a usage tendency, not a structural
  restriction). **Design consequence:** `perks`/`flaws` shouldn't be
  modeled as an attack-specific or nesting-specific field; it belongs
  on whatever the common "Ability item" record type ends up being
  (top-level Ability, linked sub-ability, and Attack-typed combat
  entries should all share the same Perks/Flaws representation),
  parallel to how `besm2_fmt.Entities`' attribute record carries
  `Enhancements`/`Limiters` uniformly rather than per attribute kind.
  **Endurance-cost arithmetic, confirmed against the rulebook and
  `ova-ref.pdf`'s Perk/Flaw tables (user check-in, this session):**
  Perks *add* to an Ability's Endurance cost (*"you must spend the
  total of Endurance from any Perks it has"*); Flaws *offset*
  (subtract from) that cost, floored at zero (*"may be reduced to
  zero, [but] can never become a negative amount"*); per-Perk/Flaw
  costs vary widely (`ova-ref.pdf`: Perks from `+0`, e.g. Ranged/Will
  Attack/Fatiguing, up to `+20`, Blinding; Flaws from `−5` up to
  `−25`, Open to Attack the largest single offset, `−20` No
  Damage/Concentration close behind); and some Perks/Flaws are
  explicitly repeatable (`/M` = any number of times, `/n` = up to `n`
  times, e.g. `Paralyzing/2`, `Ammunition/3`), rendered in finished
  prose as a `Name X<n>` suffix rather than a separate number — see
  `Karis.yaml`'s `Paralyzing`/`counts-as: 2` and
  `Ineffective`/`counts-as: 3` on Flex-Steel Cable, already
  transcribed this way. This is the arithmetic `Ova_Fmt.Entities`
  would need if it ever computes/validates an attack's Endurance cost
  from its Perks/Flaws rather than just displaying the YAML's own
  `endurance:` field verbatim (not yet decided whether the formatter
  should do that computation at all, §5's `combat.attacks[].endurance`
  is currently treated as authored data, not derived).
- **Combat block is its own structured section**, matching the
  official character sheet's "Combat Stats" box exactly (§5): Defense,
  Health, Endurance, Threat Value (`tv`), and up to several named
  Attacks each with Roll, DX (Damage Multiplier), Endurance cost, plus
  Perks/Flaws/Affinity/Description. BESM has no equivalent — BESM
  folds combat-relevant numbers into its generic Derived Values list.
- **A `fluff` block** (concept, birthday, age, gender, height, weight,
  hair, eyes, association, hobbies, favorite-food, allies, enemies,
  love-interests) — matches the rulebook's suggested fluff fields
  (§2, ~line 700) and `fluff.yaml-partial`'s outline exactly. No BESM
  equivalent (BESM has no fluff section at all).
- **An `options` block** (`base-zero`, `power-ceiling`, `scaled-cost`,
  `combined-effectiveness`, `max-abilities-level`) recording which
  character-creation limiting rule(s) were used and their parameters —
  metadata about how the character was built, not data to be rendered
  as part of the character write-up necessarily (open question: does
  any output format display this at all, or is it purely informational
  for whoever maintains the YAML?).
- **Background/Appearance/Personality/Notes** — `Fukiko.yaml` has
  these as prose blocks plus a `notes` list of `{header, text,
  attributes}` entries (the `attributes` sub-field holds pre-rendered
  prose like `"Flight +2, Quick +1, Smart +2..."` for an NPC companion
  described within a note, not a structured list — see Azyrus in
  `Fukiko.yaml`'s `notes`). Roughly parallels BESM's
  `description`/`tagline`, but richer.
- **`summary`** (decided, §2.3) — a new field, not present in
  `Fukiko.yaml`/`Auren.yaml`/the physical character sheet at all: one
  short, author-written sentence distinct from `background` (a
  condensed synopsis rather than the full prose), rendered italicized
  under the header in terse output. Not derived/auto-generated —
  the author writes it directly, same as `tagline`/`concept`.
- **`tagline`** (decided) — also a new field, formalizing what §2.1
  already observed but `Fukiko.yaml`/`Auren.yaml` don't yet have a key
  for: an *optional, in-character/diegetic quote or saying* — "a
  saying from the character in game" — usually short and pithy (the
  player books' quoted catchphrases under each name, §2.1, e.g.
  Auren's "IT IS MY DUTY TO PROTECT THIS WORLD, EVEN IF ITS FUTURE
  MAKES ME DOUBT WHY I SHOULD BOTHER…", are exactly this field). Can
  run much longer occasionally (the user's illustrative example: the
  Dirty Harry "Do I feel lucky?" speech), so the schema/formatter
  shouldn't assume a one-line length the way `summary`'s "one
  sentence" framing does. **Distinct from `summary`**: `tagline` is
  the character speaking in-world (diegetic, quoted), `summary` is
  the author describing the character from outside the fiction
  (non-diegetic, not a quote) — different voice, different purpose,
  both optional, both can coexist on the same character.

## 5. Canonical field set (from the official character sheet)

`OVA-Blank-Character-Sheet-Form-Fillable.pdf` (2 pages) confirms the
fields any output format should be able to round-trip:

- Header: Character Name, Player Name.
- Abilities (name + level list), Weaknesses (name + level list) —
  side by side.
- Combat Stats: up to 4 named attack rows (Roll / DX / END columns
  each), then a Defense / Health / Endurance / TV row.
- Combat Notes / "Damage, Complications, Etc." (free text).
- Page 2: Background, Appearance, Personality, Other Notes (free
  text), Character Portrait (image — out of scope for a text
  formatter).

Since §9 step 9, every one of these has a key: `player`,
`appearance`, `other-notes`, combat `notes`, and `portrait` (a path,
shown only by `-H`).

This matches `Fukiko.yaml`'s shape closely and is a good sanity check
for whatever YAML schema gets settled on (§6): every one of these
fields should map onto something in the schema, and nothing essential
should be sheet-only/YAML-only without a reason.

## 6. Test data assessment — the schema is not settled

`~/current/RPG/Tools/OVA/test-data/` (5 files) does **not** use one
consistent schema. This is the other major open item before any real
port work, since `besm2_fmt`'s port strategy (§7 there: diff Ada
output byte-for-byte against real Scheme-generated golden output)
depends on having working, schema-valid input and a working reference
implementation — neither exists yet for OVA.

- `Fukiko.yaml` (177 lines, the most complete) — top-level YAML
  **mapping** (not a sequence like BESM's/Auren's files): `name`,
  `abilities`/`weaknesses` (each a list of `{name, level, [detail(s)],
  [abilities], [weaknesses], [perks], [flaws]}` — nested recursively
  for Transformation), `combat` (`defense` as a slashed
  string `"4/5"` — confirmed accurate against the primary rulebook's
  own printed Fukiko sheet, §2.2, not a transcription error — `health`,
  `endurance`,
  `threat-value`, `attacks[]` with `name`/`perks`/`flaws`/`affinity`
  (note: misspelled `afinity` on the first attack, `affinity`
  correctly on the rest — a typo to notice, not a schema variant)/
  `description`/`roll`/`dx`/`endurance`), `background`, `appearance`
  (empty), `personality`, `notes[]` (`header`/`text`/optional
  `attributes` prose), `fluff` (mapping of the §4 fields). Uses
  `details`/`detail` inconsistently (`detail:` singular on the
  Knowledge ability, `details:` plural on Bizarre Appearance/Focus) —
  another thing to normalize when settling the schema, not necessarily
  a meaningful distinction.
- `Auren.yaml` (98 lines) — top-level YAML **sequence** of one entity
  (`- name: Auren`, matching BESM's file shape), with an `options`
  block (§4) not present in `Fukiko.yaml` at all. Abilities/weaknesses
  use a **different item shape**: each list item's own key names the
  attribute (`ability: Combat Expert` / `weakness: Ageism`) instead of
  a fixed `name:` key, and several entries misspell the key itself
  (`abilty:` ×3, `abiltiy:` ×1) — these items likely fail to parse as
  intended under either schema as a result (a YAML mapping key typo
  like `abilty` just becomes a differently-named field, silently, not
  a YAML syntax error) and would need cleanup regardless of which
  schema direction is chosen. `label:` appears where `Fukiko.yaml`
  uses `detail:`/`details:` (also once misspelled `lebel:`). Nested
  `spells:` under `Magic, Arcane` uses `spell:`/`perks: - perk: ...`
  (again keying by value-as-key rather than a fixed `name:`), with one
  outlier (`Breath`'s perk uses `name: Life Support` instead of
  `perk:`) — so even within this one file the "key names the thing"
  convention isn't applied consistently. `combat.attacks:` is present
  but empty (no attacks filled in), and `background`/`appearance`/
  `personality`/`notes` are all empty.
- `Acacia.yaml` (12 lines) — top-level sequence, one entity, every
  field present as a key with no value (`abilities:`, `weaknesses:`,
  `combat:`, `background:`, `appearance:`, `personality:`, `notes:`).
  Effectively just a "here are the top-level section names" skeleton;
  no schema information beyond that.
- `template.yaml` (36 lines) — **not valid YAML as written**: it mixes
  a sequence item's mapping with stray `- perks:`/`- flaws:`/
  `- affinity:` list markers at the wrong indentation inside a
  mapping value, and uses placeholder tokens (`Ability X`, `Perk Y`,
  `level: N`, `cost: M`) rather than real data. Read as an aspirational
  sketch of intended structure (options block fully commented with
  rulebook page references, a perk/flaw shape with `name`/`level`/
  `cost`/`description`), not as a working fixture. Its `cost:` field
  (with a `# Total` comment) hints at wanting per-perk/flaw Endurance
  cost tracked explicitly, matching `ova-ref.pdf`'s Perk/Flaw End
  columns.
- `fluff.yaml-partial` (18 lines, note the `.yaml-partial` extension —
  deliberately not a complete/loadable file) — just the `fluff:`
  mapping with every OVA-rulebook-suggested field present as a
  commented-out-description placeholder. A clean reference for the
  fluff field list and field order, nothing more.

**Bottom line:** before any Ada work starts, the YAML schema needs to
be decided and `Fukiko.yaml`/`Auren.yaml`/`Acacia.yaml` brought into
conformance with it (fixing the `abilty`/`abiltiy`/`lebel` typos along
the way), the same way `besm2_fmt`'s port could lean on already-valid,
already-consistent `besm-tools` test-data. Recommend picking
`Fukiko.yaml`'s style (fixed `name:`/`level:` keys, nesting via
`abilities:`/`weaknesses:` under a parent item) as the base, since it's
both the most complete example and the one the stub's own
`process-entity-terse` already assumes (`must-exist "level" ability}`
expects a fixed key name, not `Auren.yaml`'s "key names the thing"
convention).

## 7. Output-format strategy for nested tables (settled by the user)

This resolves what was previously the top open question (§3/§4's
nested-table problem) with a concrete per-format plan, given directly
by the user rather than left for later design:

- **reST's own table syntax (grid or simple) is not usable for OVA at
  all.** Unlike BESM, where a flat attributes/defects/skills list maps
  fine onto one reST table per section, OVA's nested
  abilities-within-abilities has no representation in reST tables —
  reST doesn't support nested tables, and `besm2_fmt`'s grid-table
  backend (`process-entity`'s STAT/ATTRIBUTE/DEFECT/SKILL tables) is
  therefore **not** a shape to reuse for OVA's default output.
- **Default/primary text output should look like BESM's *terse*
  format instead** — paragraphs of prose (`**Attributes:**` etc.,
  matching `ova-rst.scm`'s existing `process-entity-terse` sketch,
  §3), not a tabular grid. This is the one format where nesting is
  natural: a nested ability's sub-abilities/sub-weaknesses just read
  as a parenthetical or nested clause within the parent's sentence,
  the same way `columns.scm`'s Azyrus example in `ova-rst.scm`'s
  header comment already reads Companion/Attributes/Weaknesses as
  flowing text. This sidesteps the nested-table problem entirely
  rather than solving it — there's no grid to keep aligned.
- **HTML output**: generate a raw HTML block embedded in the generated
  reST (`.. raw:: html`), the same technique `besm2-rst.scm`/
  `besm2_fmt` use for groff `tbl` via `.. raw:: ms` (`process-entity-
  raw-ms`/`Format_Raw_Ms`) — i.e. `ova_fmt` hand-emits literal
  `<table>`/`<tr>`/`<td>` markup itself (nesting a full `<table>`
  inside a `<td>` where an ability has sub-abilities), rather than
  trying to express the table through reST syntax and letting Pandoc
  render it. This is exactly what `columns.scm`'s correction (§3)
  establishes as workable: HTML nests tables fine, so hand-written
  markup is the right level to emit at, bypassing both reST's
  limitation and `(schemepunk show)`'s inability to build nested
  layouts.
- **groff/troff output**: `besm2_fmt`'s raw-ms backend uses classic
  `tbl` macros (`.TS`/`.TE`, `T{...T}` text blocks) — confirmed **not
  suitable for OVA**, since `tbl` has no construct for a table nested
  inside a cell (column/row spanning could maybe fake something
  visually, but isn't real nesting and wasn't pursued). Instead use
  groff's **`hd` table macros**, which do support nested tables (and
  color) — the same `.. raw:: ms` raw-block technique as
  `besm2_fmt`'s `tbl` approach, just with `hd` macro calls instead of
  `.TS`/`tbl` syntax, still processed through Pandoc's `ms` writer
  like the rest of the raw-ms pipeline. **Caveat, and worth flagging
  early:** `hd` is reportedly not well supported in the groff version
  the user expects to be current (~1.24) but *is* supported in groff
  1.23, which is the version actually installed/in use here — check
  the installed groff version before committing to this path, and
  re-verify `hd`'s nested-table support against whatever version is
  actually available when this gets built, since relying on it and
  then hitting a groff upgrade that dropped/changed `hd` support would
  be a real regression risk.
- **Lout/PDF output**: Pandoc has **no Lout backend**, so unlike the
  reST→(HTML|ms) pipeline, this output can't go through Pandoc at
  all — `ova_fmt` would need to emit complete, directly-renderable
  Lout source itself (`lout -a ... | ps2pdf`, matching the existing
  `GNUmakefile`'s `build/%.lout.pdf` pattern), the same role
  `Fukiko-experiment.lout` already plays as a hand-written example
  (§3) — i.e. this becomes a fifth, structurally different output
  mode, not just another `.. raw::` block inside reST. Lout's `@Tbl`
  package genuinely nests (proven by `Fukiko-experiment.lout`), so
  this is the one path with a working existing proof of concept
  already in the repo.

Net effect on `Ova_Fmt.Text_Layout`/format-backend design: the
fixed-width pad/wrap/columnar-row machinery `besm2_fmt` built
(§8-old/now-§9's "reuse directly" bullet) is useful for the
**terse-prose** format's word-wrapping, but the *tabular row/column
renderer* part of `besm2_fmt.Text_Layout` (`Put_Row`/`Separator_Line`,
the reST grid-table specific piece) has **no OVA consumer at all** —
OVA's tables live only inside HTML-in-reST/groff-in-reST/Lout blocks,
each with its own native table model, not through a shared Ada-side
grid renderer.

## 8. Proposed approach, following `besm2_fmt`'s playbook

Not yet decided/committed — for discussion before starting real work:

- **Toolchain:** same as `besm2_fmt` — Ada 2012, `alibfyaml`
  (`~/Repos/Ada/alibfyaml` / installed under
  `/usr/local/sw/versions/ada/`, resolved via `GPR_PROJECT_PATH`) for
  YAML, `arg_parser` for CLI parsing, same `Executable`-renaming
  `.gpr` trick if the root package ends up needing to be named
  `Ova_Fmt` (check whether that specific collision even applies here —
  `besm2_fmt`'s workaround was needed because `BESM2_Fmt` had to be
  both a procedure name and a parent package name; confirm the same
  shape before copying the workaround unnecessarily).
- **Package layout**, mirrored from `besm2_fmt/src/`:
  `ova_fmt.ads` (root anchor), `ova_fmt-config.ads`,
  `ova_fmt-text_layout.ads/.adb` (start from `besm2_fmt`'s, but budget
  real design time for the nested-table problem, §3/§4 — this is
  **not** a drop-in reuse), `ova_fmt-entities.ads/.adb` (parse each
  YAML entity into typed Ability/Weakness/Attack/Combat/Fluff records
  once, matching `besm2_fmt`'s "parse once, four backends consume it"
  rationale), one package per output format, `ova_fmt-cli.ads/.adb`,
  `ova_fmt_main.adb`.
- **Reuse `besm2_fmt`'s already-learned lessons directly**, since
  they're about YAML/Ada mechanics, not BESM-specific: libfyaml core
  hands back scalar text needing explicit `Integer_Value`/etc.
  conversion (already solved generically in `alibfyaml`'s
  `Libfyaml.Nodes` — no OVA-specific work needed there);
  `Display_Length`/UTF-8-aware width counting for any fixed-width
  column layout; `Word_Wrap` needing to treat embedded YAML
  literal-block newlines as word breaks, not literal content;
  `Document_Stream` for correct multi-document handling (OVA files so
  far are single-document, but no reason to special-case that).
- **Output formats**, per §7's settled per-format strategy: terse-prose
  as the default/primary text format (no BESM-style reST grid-table
  default at all — reST tables are off the table, so to speak, for
  OVA); an HTML-in-reST backend that emits raw `.. raw:: html` blocks
  with hand-written (potentially nested) `<table>` markup; a
  groff-in-reST backend using `hd` macros instead of `tbl` (version
  caveat noted in §7); and a Lout backend that's a genuinely separate,
  non-Pandoc output mode producing directly-renderable Lout source. Not yet
  decided whether an h-m-m outline backend (no OVA attempt exists at
  all) is also wanted. No golden reference output exists for *any* OVA
  format yet (unlike BESM, where `besm-tools`' compiled binary and
  `GNUmakefile` targets served as the oracle) — acceptance testing
  will have to be built up from scratch (hand-verify the terse format
  against the rulebook's own Fukiko/Azyrus write-up on p. 36–37, and
  the Lout backend against `Fukiko-experiment.lout` specifically,
  since that's now a confirmed real worked example, §3) rather than
  diffed against a pre-existing working program.
- **Test data and build order**: see §9 — now a decided sequence
  rather than an open item.
- **Shared library question**: `besm2_fmt`'s `PLAN.md` already flags
  "factor `Text_Layout`/customizer logic into a shared library" as an
  open question for a hypothetical `besm4_fmt`. Worth reconsidering
  once OVA's `Text_Layout` needs diverge from BESM's (§3/§4) — may turn
  out OVA's nested-table requirement means less is actually shareable
  than the BESM4 case would have had, or it may clarify what the truly
  generic core (`Pad`, plain `Word_Wrap`, `Bold`/`Italics`/emphasis
  gating) versus per-game layout logic split should be.

## 9. Build order (decided)

Given directly by the user, superseding §8's "not yet decided" framing
for test data and output-format sequencing:

1. **YAML test data for all twelve sample characters** (§2.2), not
   just the existing `Fukiko.yaml`/`Auren.yaml`/`Acacia.yaml`/
   `template.yaml`. Base the schema on `Fukiko.yaml`'s existing
   structure wherever it already fits (§6's recommendation — fixed
   `name:`/`level:` keys, nesting via `abilities:`/`weaknesses:` under
   a parent item), but it needs to generalize to cover what the other
   eleven write-ups actually contain, not just Fukiko's shape:
   - `background`, `personality` — already present in `Fukiko.yaml`.
   - **NPC companion callouts — now confirmed to need two different
     shapes, not one** (§2.3): a simple prose-only companion (Fukiko's
     Azyrus: one `Attributes: Flight +2, Quick +1, Smart +2; ...`
     summary line, still fine as `notes[]`) *and* a fully-detailed
     companion with its own Abilities/Weaknesses/Attacks/Combat-stats
     sub-block (Karis's Arasuni, §2.3) — structurally a nested
     sub-entity, not a note. Schema needs to support both; probably
     the character's own choice depending on how mechanically
     detailed the companion needs to be for play.
   - **Transformation-description callouts**: Fukiko's sheet has a
     separate named box ("Lovely Savior Myu Myu") describing the
     transformation itself — trigger phrase, visual/narrative
     description — distinct from the Transformation Ability's own
     numeric list entry. Also currently folded into `notes[]`; check
     the other Transformation-using sample characters for the same
     convention.
   - Any further headed callout types turned up while transcribing the
     remaining eight characters not yet read closely (only Fukiko,
     Auren, Ai, and one other paired-Defense character have had their
     full spreads read so far, §2.2/§2.1).
   Deliberately use this pass to get schema coverage for every
   nesting/modifier shape already identified from primary sources:
   Ai's plain-Ability Perk/Flaw (§ Perks/Flaws correction above), a
   Magic-using character's spell-mimics-another-Ability shape (§2.2),
   and whichever sample characters (if any) use Companion or Vehicle,
   still unconfirmed as worked examples (§ open questions).

   **Progress: `test-data/sample-pcs/Karis.yaml` done** (first of the twelve,
   transcribed from `ova-rulebook.txt` lines 874–1012 — Karis herself,
   plus Arasuni as a full nested Companion sub-entity per §2.3).
   Lives in `ova_fmt/test-data/sample-pcs/` (a new directory in *this* repo, not
   the old Scheme project's `~/current/RPG/Tools/OVA/test-data/`).
   Established, and needing to be followed consistently in the
   remaining eleven transcriptions:
   - **Top-level document is a YAML sequence**, not a bare mapping —
     `Karis.yaml` uses `- name: Karis ...` even though it's a single
     entity, matching `Auren.yaml`/`Acacia.yaml`/`besm2_fmt`'s
     convention and the loader's `for entity in entities` iteration
     model, *not* `Fukiko.yaml`'s existing bare-mapping style (§6's
     already-noted inconsistency — `Fukiko.yaml` itself should
     probably be converted to match at some point, tracked as its own
     small cleanup rather than done as a side effect here).
   - **A linked sub-entity nests under the ability list item that
     grants it**, in a key named after the ability kind (`companion:`
     under the `Companion` ability item) — the same location
     Transformation's granted sub-abilities/sub-weaknesses already
     nest at (`Fukiko.yaml`), so every "this Ability grants linked
     content" case (Transformation, Magic, Companion, and presumably
     Vehicle once an example turns up) stays in one consistent place
     regardless of which Ability it is, rather than each kind
     inventing its own top-level sibling field.
   - **Copyright-conscious transcription policy**: game-mechanical
     data (ability/weakness names and Levels, combat stats, attack
     Roll/DX/Endurance/Perks/Flaws, fluff fields, `tagline`) is
     transcribed faithfully; short one-sentence attack flavor
     descriptions are kept close to the source text (brief captions,
     low risk); but `background`/`personality` — the substantial
     narrative prose, the clearest copyrightable creative-expression
     content in the book — are **short original paraphrases, not
     verbatim reproductions**, since this repo has a public remote
     (`git@github.com:tkurtbond/ova_fmt.git`) and §2's copyright note
     already flagged verbatim narrative as something not to commit
     there. `summary` (the new author-written field, §4) is original
     text written for this purpose, not from the book at all.
     **Confirmed by the user** (not just this session's judgment call)
     — the repo is believed public right now, so verbatim prose stays
     out of it; this is now settled policy for all remaining
     transcriptions, not a to-revisit item.

   **Progress: `test-data/sample-pcs/Ai.yaml` done** (second of the twelve,
   `ova-rulebook.txt` ~lines 1596–1691, p. 40–41). Chosen specifically
   to exercise two things `Karis.yaml` didn't: a Perk directly on a
   plain top-level Ability (Barrier's `No Gesture`) — the concrete
   real-data case behind this session's "Perks/Flaws customize any
   Ability, not just attacks" correction (§4) — and a second
   Barrier-driven paired Defense (`4/5`), which is also the first
   place the decided design for that pairing (§2.2: render the pair
   verbatim, add a short explanatory `note:` on the Barrier ability
   entry) actually gets implemented in test data (`Fukiko.yaml`'s
   pre-existing Barrier-via-Transformation still lacks this note —
   small follow-up cleanup, not done as part of this file). Also
   introduces one new per-item field: a Perk/Flaw list entry can carry
   `cost` (a chosen Endurance magnitude, for Perks/Flaws whose
   rulebook cost is a *range* rather than fixed — Cancel is "`-0 to
   -20`" per `ova-ref.pdf`) alongside or instead of `detail` — kept
   deliberately distinct from `counts-as` (Karis.yaml's
   `Paralyzing`/`Ineffective` `x2`/`x3`, meaning "taken this many
   times"): Ai's Mind Break attack's `Cancel` Flaw (detail `Unliving`,
   cost `-5`) is a single take at a chosen magnitude, not a repeat.

   **Progress: `test-data/sample-pcs/Raine.yaml` done** (third of the twelve,
   `ova-rulebook.txt` lines 652–765, p. 23–25). Chosen to confirm two
   things: a second `detail`+`cost` Flaw example (Electrical Storm's
   `Requirement` — also a variable-range Flaw per `ova-ref.pdf`, "`-5
   to -20`" — with `detail: Must Be Outside`, `cost: -10`), and a new
   `notes[]` attachment point — Raine's "Nightmares" callout box is
   keyed to his `Unique Weakness (Nightmares)` entry, so headed
   callouts attach to notable *Weaknesses* too, not just Abilities
   (Fukiko's Transformation and Azyrus's Companion, both Abilities,
   were the only examples before this). `affinity:` kept as its own
   field rather than folded into `perks:` as display prose, matching
   `Fukiko.yaml`'s existing convention.

   **Progress: step 1 done — all twelve `ova-rulebook.txt` sample
   characters now have `test-data/sample-pcs/*.yaml`.** The remaining eight,
   transcribed in one pass after Raine: `Shou.yaml` (p. 26–27, lines
   769–869 — plain, no new schema wrinkles); `Miho.yaml` (p. 30–31,
   lines 1013–1132, cross-checked against the player-book excerpt —
   Transformation stacking an *extra* Level onto an Ability the
   character already has at top level, Combat Expert +3 base / +2
   more via Transformation, not previously seen since Fukiko's
   Transformation only grants wholly new Abilities); `Braun.yaml`
   (p. 31–33, lines 1136–1246 — a joke attack with a negative `roll`
   (`-2`) and a fractional `dx` (`"1/2"`, stored as a string like
   `combat.defense`'s non-integer values; matches Armored's own rules
   text on reducing DX to ½), and the first Threat Value of `0`; two
   `notes[]` entries on one character, confirming that's fine);
   `Natsuki.yaml` (p. 33–35, lines 1249–1358 — a `notes[]` entry
   ("Malicron Corporation") that describes summonable NPC minion
   stats in prose rather than structured data, left as prose, no
   schema for that yet); `Auren.yaml` (p. 38–39, lines ~1475–1591,
   cross-checked against the player-book excerpt — a **from-scratch**
   transcription for *this* repo, not a fix of the old Scheme
   project's inconsistent `Auren.yaml`; introduces the Magic-spell
   shape resolved in §2.2 — a `spells:` list under the Magic ability,
   each entry `{name, mimics, level, endurance}`, deliberately
   different from Transformation/Companion's `abilities:`/
   `weaknesses:` nesting since a spell isn't itself an Ability);
   `Yuu.yaml` (p. 42–43, lines 1690–1815 — a second full
   nested-Companion example, Fenrir, confirming Karis/Arasuni's
   pattern generalizes; a richer `detail`+`cost` Flaw where `detail`
   names a specific Level of another Ability as a precondition,
   `Requirement: Trust +1/+2/+3` at escalating cost; one uncertain
   transcribed value flagged in-file, Fenrir's Endurance, where the
   source text has a likely column-extraction artifact);
   `Daisuke.yaml` (p. 43–45, lines 1819–1911 — an alternate-form
   stat-delta callout, "Black Bunny!", left as prose since there's no
   schema yet for "what changes while transformed" as structured
   data); `Cora.yaml` (p. 45–47, lines 1919–2021, the twelfth and
   last — confirms `spells:` is specific to Magic, Arcane-style
   casting: her Magic, *Witchcraft* has no nested spells list at all,
   consistent with Witchcraft casting Weaknesses onto a target rather
   than the caster mimicking an Ability). All eight validated with a
   Python YAML parse and `yamllint`, same as the first three.

   **Progress: `test-data/sample-pcs/Fukiko.yaml` fixed up to match the settled
   schema** (its own transcription, superseding the old Scheme
   project's original — left untouched there — with a full header
   comment listing every change). Closes the last open cleanup item
   from §6/earlier in this section. Notable: gave Azyrus a real
   `companion:` sub-block instead of prose-only `attributes:` text,
   which prompted the "one shape with optional depth" refinement to
   the Companion finding (§2.3, "Refined" paragraph); finally applied
   the decided Barrier `note:` (§2.2) to the original character whose
   paired Defense motivated that design in the first place, closing
   the loop `Ai.yaml`'s header comment had flagged as outstanding.
   **All twelve `test-data/sample-pcs/*.yaml` files now follow one consistent
   schema.**
2. **Terse backend first.** Mirrors `besm2_fmt`'s own build order
   (its `PLAN.md` §8: terse validates CLI + data access + domain
   formatting before touching harder layout code) — and per §7, terse
   is the one OVA format that needs no table-layout code at all, so
   it's both the natural first target and the one with a ready-made
   reference to hand-verify against (the rulebook's own printed
   write-ups from step 1, not a pre-existing working binary the way
   BESM had — §8's note on acceptance-testing from scratch still
   applies).

   **Progress: done — a working `ova_fmt` binary exists.** Project
   skeleton mirrors `besm2_fmt` exactly (`ova_fmt.gpr`, `ova_fmt.ads`
   root anchor, `Ova_Fmt.Config`/`Ova_Fmt.Cli`/`Ova_Fmt_Main`, the
   same `Executable ("ova_fmt_main.adb") use "ova_fmt"` renaming
   trick for the same reason). `Ova_Fmt.Entities` implements the full
   settled schema in one pass — Perk_Flaw (scalar / detail / repeat
   count / chosen-cost shapes), Attack, Combat_Stats (shared between
   a main entity and a Companion sub-entity), Sub_Item (Transformation/
   Companion nested abilities/weaknesses), Spell (Magic), a
   Companion_Access (an access type, deliberately never freed — see
   its doc comment: a short-lived batch CLI leaking at exit is fine),
   Ability, Weakness, Note_Item, Fluff_Block (fixed known fields, not
   a generic key/value list), Entity. `Ova_Fmt.Format_Terse` renders
   all of it: header (name + `fluff.concept`, underlined; `tagline`
   quoted-italic; `summary` italic), Background/Personality as bold-
   labeled paragraphs, Abilities/Weaknesses/Combat-summary/Attacks as
   one bulleted list matching the Karis mockup's translated-to-reST
   structure (§2.3) for the parts it covered, plus this session's own
   first-pass design (flagged as such in the package's header comment,
   not yet user-reviewed) for what it didn't: a "linked content"
   expansion section per Ability with nested Sub_Abilities/
   Sub_Weaknesses/Spells/a Companion, printed after the main Attacks
   block (`**Transformation**` / `**Magic, Arcane**` / `**Companion:
   Name**`, the last recursing through `Print_Combat_And_Attacks` when
   the companion has its own `combat:` block); Notes as bold-header-
   em-dash-text pairs; Fluff as one labeled line. Built clean (no
   warnings) against `alibfyaml`/`arg_parser` via `GPR_PROJECT_PATH`,
   same as `besm2_fmt`. Ran against all twelve `test-data/sample-pcs/*.yaml`
   files with no crashes; spot-checked Karis, Fukiko, Auren, Ai,
   Braun, and Cora by eye against their source data and the general
   rulebook conventions (§2.1/§2.2/§2.3) — output reads correctly for
   every nesting/modifier shape transcribed so far (paired Defense
   with the Barrier note both nested and top-level, Magic spells,
   both Companion shapes, negative `roll`/fractional `dx`, `detail`+
   `cost` Perks/Flaws). One real bug found and fixed this way: the
   `fluff:` line's forced trailing period doubled up when a value
   already ended in one (`enemies: Malicron Corp..`, Braun/Miho) —
   fixed with an `End_With_Period` helper that checks first, and
   verified clean across all twelve outputs afterward. `-h`/`-o`/
   stdin all confirmed working. **Not yet done:** no golden reference
   exists to diff against (§8's note — there never was one for OVA),
   so this has only been eyeball-verified, not the byte-for-byte
   standard `besm2_fmt` held itself to; the linked-content section
   design in particular is this session's own invention and should be
   reviewed against what's actually wanted before treating it as
   settled, the way the Karis-mockup-covered parts already are.

   **`-n`/`--no-unicode-minus` added**, same mechanism as
   `besm2_fmt.Config.Unicode_Minus`/`Text_Layout.Minus_Glyph`, applied
   to every site that actually renders a negative number —
   Ability/Weakness/Sub_Item/Spell `Signed_Img` (the common case,
   Weakness Levels), a Perk/Flaw's `cost` when negative (Ai's
   `Cancel`, Raine's/Yuu's `Requirement`), and an attack's `roll` when
   negative (Braun's joke attack) — via a `Number_Img` helper distinct
   from the existing `Trim_Img` (kept for values that are genuinely
   never negative: Health/Endurance/Threat Value, a Perk/Flaw's
   `counts-as`). **Default flipped to Unicode MINUS SIGN (U+2212), per
   later user request** — matches `besm2_fmt`'s own default-polarity
   flip (its `PLAN.md`): `Config.Unicode_Minus` now defaults to
   `True`, and the flag is `-n`/`--no-unicode-minus`
   (`Make_Set_Boolean_False_Option`) reverting to ASCII hyphen-minus,
   the same "default-on, `-X`/`--no-X` opts out" shape `besm2_fmt`'s
   `-B`/`--no-bold-head` already uses. Verified:
   plain `./ova_fmt` now renders `−` by default (Weakness Levels,
   Braun's negative `roll`), `-n` reverts to ASCII `-`; all twelve
   `test-data/sample-pcs/*.yaml` files process cleanly both with and without
   `-n`; `build/*.gen.rst`/`build/*.ms.pdf` regenerated.

   **`GNUmakefile` added**, mirroring `besm2_fmt`'s (`build/.gitignore`
   trick to keep `build/` in git without committing generated
   output): `make`/`make all` builds the `ova_fmt` binary via
   `gprbuild`, `make rst` additionally runs it over every
   `test-data/**/*.yaml` into `build/*.gen.rst`, `make install` installs
   via `gprinstall` (same `$HOME/local` prefix as `besm2_fmt.gpr`),
   `make testclean` removes the generated `.gen.rst` files. Simpler
   than `besm2_fmt`'s (`TEST_OUTPUT`/`TEST_TBLOUTPUT`/unicode-minus/
   pdf variants, `-s`/`-t`/`-m`/`-n` flag combinations): `ova_fmt` has
   only one backend and no flags yet that change its output, so
   there's only one `.gen.rst` target per character, generated with
   no flags at all (not even `-t`, since `Ova_Fmt.Cli` has no format
   selector — terse is simply what the program does). Verified: all
   twelve build, `make rst` is a no-op on a second run, `make
   testclean` then `make rst` regenerates cleanly.

   **`make pdf` added**, same reST→pandoc→`ms`→PDF pipeline as
   `besm2_fmt`'s `build/%.ms.pdf` rule (`pandoc -r rst -w ms
   --template=tkb -o $@ $<`, the `tkb` template already installed at
   `~/.pandoc/templates/tkb.ms`) — `make pdf` depends on `rst` and
   builds one `build/*.ms.pdf` per character. Verified: all twelve
   render (one page each, ~495KB), and a direct look at
   `build/Karis.ms.pdf` confirms the whole pipeline round-trips
   correctly — bold/italic, the Abilities/Weaknesses/Combat/Attacks
   bulleted list with its nested per-attack sub-bullets, and the
   `Companion: Arasuni` section all typeset as intended, not silently
   flattened by pandoc's reST reader (a real risk worth checking,
   since the nested-bullet structure is whitespace-sensitive).
   `testclean` now also removes `build/*.ms.pdf`.
3. ~~**TODO: Gemtext backend**~~ Done. Sequenced right after terse,
   before HTML: no table-layout work needed (like terse), and it's
   structurally the closest thing to terse of any planned backend.
   Grounded in the actual spec before implementing, not assumed
   (<https://geminiprotocol.net/docs/gemtext.gmi>,
   <https://geminiprotocol.net/docs/>, cross-checked live over the
   Gemini protocol itself via `gemget` too, per the user) — confirmed
   line types: plain text lines (long lines, client-wrapped); `#`/`##`/
   `###` headings (one mandatory space after the hashes, three levels
   only, no underline syntax); `* item` list items (a literal `*`, one
   space, no nesting — `-` "will not do anything"); `> quoted text`
   blockquotes; `` ``` `` toggles preformatted/fixed-width mode; and
   `=> URL [label]` links, which must be on their own line. **No inline
   emphasis (bold/italic) exists in the spec at all.**

   Implemented as `Ova_Fmt.Config.Output_Format` (`Terse`/`Gemtext`,
   `-g`/`--gemtext` selects `Gemtext`) and `Config.Gemtext_Emphasis`
   (`-e`/`--gemtext-emphasis`, off by default) — per the user: many
   gemtext authors use `*`/`**` anyway as an unenforced convention, so
   it's opt-in, not default behavior. Per the user's explicit
   architecture call: **parameterized `Ova_Fmt.Format_Terse` itself**
   rather than duplicating it into a new package — `Bold`/`Italic` wrap
   only for Terse or (Gemtext AND `Gemtext_Emphasis`); a new
   `Section_Header` helper prints a real `##` heading for Gemtext
   (headings are a distinct always-available line type, so this does
   *not* gate on `Gemtext_Emphasis` the way `Bold`/`Italic` do) or falls
   back to `Bold` for Terse, used for every standalone section title
   ("Background", "Personality", "Notes", "Fluff", the Companion/
   Vehicle/linked-Ability heading) — but *not* inline labels within a
   sentence ("Creation Rules:", a Fluff item's own label, a Note's own
   header), which stay `Bold` either way since turning those into
   headings would mix heading semantics with actual data on one line; a
   new `Bullet` helper returns `* ` for Gemtext, `- ` for Terse
   (gemtext has no nesting, so `Print_Attack`'s indented `"  - "`
   sub-bullet becomes a plain top-level `Bullet` too); the top-level
   entity title becomes `"# " & Title` for Gemtext (no underline
   concept exists there, so `-U`/`--subunderliner` has no Gemtext
   equivalent and is simply inert in that mode) instead of the
   underlined reST title. An NPC Fragment's own bare-Name fallback
   header (`Print_Fragment_Header`, when there's no `Background` prose
   to carry the name) deliberately stays `Bold`, not `Section_Header`,
   matching the rulebook's own convention of never giving a Fragment
   its own structural heading in any format.

   `GNUmakefile` gained `TEST_GEMTEXTOUTPUT`/`gemtext` target
   (`build/%.gmi`, `-g`, no PDF rendering — gemtext isn't a Pandoc
   reader and isn't meant to be typeset), following the same wildcard-
   derived-from-`TEST_DATA` convention as `TEST_TERSEOUTPUT`/
   `TEST_PDFOUTPUT` (§9's own convention note, updated to mention it).

   Verified: a pre-change/post-change binary diff of plain (Terse-mode)
   output across every `test-data/**/*.yaml` fixture is byte-identical —
   the parameterization is fully transparent when `Config.Format` stays
   `Terse`. `-g` on every fixture produces valid, spec-conforming
   gemtext (headings, `* ` bullets, no stray reST syntax); `-g -e`
   correctly adds `*`/`**` markers back; `Fragment.yaml`'s literal
   author-written `**Shady Teacher**` inside its `background:` prose
   renders unchanged either way, since that's raw author text passed
   through verbatim, not something `Bold`/`Italic` generate.
4. ~~**HTML-in-reST backend**~~ Done. Raw `.. raw:: html` blocks
   containing hand-written, potentially-nested `<table>` markup (§7),
   through the same reST→Pandoc pipeline `besm2_fmt`'s raw-ms backend
   already demonstrates the shape of (reST→Pandoc→`ms` there;
   reST→Pandoc→HTML here). Named "HTML-in-reST," not just "HTML," per
   the user — it's a reST document with one raw HTML block spliced in
   for nested tables, still run through Pandoc, not a standalone HTML
   document generated directly (§ open questions has the full
   reasoning for this naming).

   Table structure confirmed with the user *before* implementing (a
   full worked Karis/Arasuni example, since — unlike Terse — there's
   no rulebook layout to match; this is a genuinely new design):
   header/tagline/summary/background/personality/Notes/Fluff/Creation
   Rules stay plain reST, byte-identical to Terse (factored into a
   shared `Print_Header_And_Prose`, called by both); one `<table>` per
   section (Abilities, Weaknesses, Combat, Combat's own Attacks); an
   Ability row that grants linked content (Companion/Vehicle via
   `Sub_Entity`, Transformation's `Sub_Abilities`/`Sub_Weaknesses`, or
   Magic's `Spells`) gets one extra `<td>` holding a full nested set of
   `<table>`s for that content — genuine `<table>`-inside-`<td>`
   nesting, the entire reason this backend exists over reST's own
   table syntax. NPC Fragments render identically to Terse regardless
   of `-H` — a Fragment's whole point is being flat/minimal, so there's
   nothing to nest.

   Implemented as a third `Config.Output_Format` value (`Html_In_Rst`,
   `-H`/`--html`) inside `Ova_Fmt.Format_Terse` — no reorganization
   needed, confirming this session's earlier naming-question analysis
   was right that these Pandoc-embedded backends are extensions of the
   same family, not a reason to split `Format_Terse` apart.
   `Html_Escape` (`&`/`<`/`>`) is applied to every piece of free-form
   text placed in a table cell — the one genuinely new correctness
   concern Terse/Gemtext never had, since plain text needs no escaping
   there. Added `test-data/Escaping.yaml` (synthetic, since none of
   the other fixtures happen to contain `&`/`<`/`>`) as the only
   regression coverage for `Html_Escape` actually firing.

   Verified: a pre-change/post-change binary diff of Terse and Gemtext
   output across every `test-data/**/*.yaml` fixture is byte-identical
   (the new format value touches nothing else); `-H` on every fixture
   (`Vehicle.yaml`'s nested Vehicle content, `Fragment.yaml`'s
   unaffected flat rendering, `Escaping.yaml`'s special characters,
   Karis/Arasuni's full nested example included) produces output that
   parses as valid HTML with Python's `html.parser` after a real
   `pandoc -r rst -w html` pass, and the nested `<table>`s survive
   Pandoc's raw-HTML passthrough genuinely nested, not flattened or
   escaped — confirmed by inspecting the actual rendered HTML, not
   just the intermediate reST. `GNUmakefile` gained `TEST_HTMLOUTPUT`/
   `TEST_HTMLRENDEROUTPUT`/`html` (`build/%.html.gen.rst` via `-H`,
   `build/%.html` via Pandoc), following the same wildcard-derived-
   from-`TEST_DATA` convention as every other output-list variable.
5. ~~**h-m-m outline backend** (`Ova_Fmt.Format_Hmm`)~~ Done —
   sequenced here, right after HTML-in-reST: needs no table-layout
   work at all (like terse, unlike HTML-in-reST/groff-in-reST).
   Modeled on `besm2_fmt.Format_Hmm`'s tab-indented-outline shape/
   mechanics (`Indent`/`All_One_Line`, depth bands) but a genuine new
   design pass for OVA's own nesting, not a port — confirmed with the
   user before implementing (a full worked shape, same as
   HTML-in-reST's table structure was): D1 the entity's own line
   (`Name (Concept)`), D2 section headers (Background/Personality/
   Abilities/Weaknesses/Combat/each linked-Ability's own
   header/Notes/Fluff), D3 that section's content (prose, Combat's
   stats-summary line and "Attacks" header, a linked Ability's
   "Grants:"/"Spells:" line, each Note). OVA's Transformation/Magic/
   Companion/Vehicle linked content maps onto h-m-m's recursion more
   naturally than Terse's flat "Abilities: ..." line ever could: a
   Companion/Vehicle's own Abilities/Weaknesses/Combat/Attacks simply
   nest one level deeper than its own header node, via the same
   `Print_Sub_Item_Section`/`Print_Combat` procedures called
   recursively with `Header_Depth + 1` — besm2 (flat Attributes/
   Defects/Skills, nothing nested) never needed this.

   **`-c`/`--hmm-compact-lists`**, per the user, requested specifically
   during this session's design discussion (not from the besm2_fmt
   model, which has no equivalent): instead of an "Abilities"/
   "Weaknesses" header node with one child node per item (the
   default), fold the label and the whole comma-joined item list onto
   one node — `**Abilities:** Ability1 +1 [...], Ability2 ...` — the
   same content Terse's own `Abilities:` line already builds, just as
   an h-m-m node instead of a bullet. Applies wherever an Abilities/
   Weaknesses section prints, including a Companion/Vehicle's own
   (same section-printer, called recursively) — confirmed with the
   user rather than assumed. Off by default, matching every other
   opt-in rendering choice (`-e`/`--gemtext-emphasis`, `-O`/
   `--options`).

   Deliberately its own package, not built on `Ova_Fmt.Format_Common`'s
   `Print_Header_And_Prose`/`Print_Tail`/`Process_Entity` — those are
   structurally reST/Gemtext-specific (bullets, section headers with
   no depth parameter) and don't fit an indentation-tracked outline,
   matching how `besm2_fmt.Format_Hmm` is independent of
   `besm2_fmt.Format_Terse` too. It does reuse `Format_Common`'s
   per-item line formatters (`Format_Ability_Line`/`Format_Weakness_Line`/
   `Format_Sub_Item_Line`/`Format_Spell_Line`/`Format_Attack_Line`/
   `Format_Combat_Summary_Line`, the last two newly extracted from
   `Print_Attack`/`Print_Combat_And_Attacks` for this reuse) and the
   comma-join helpers (`Join_Abilities`/`Join_Weaknesses`/
   `Join_Fragment_Abilities`/`Join_Fragment_Weaknesses`/`Join_Sub_Items`/
   `Join_Spells`, also newly added — `Format_Common`'s own
   `Process_Entity`/`Print_Linked_Section`/`Print_Fragment_Attributes`
   were refactored to call them too, removing several near-duplicate
   inline loops there in the process) — none of these depend on
   `Config.Format`, so they're safe to share as-is. `Bold`/`Italic`/
   `Section_Header` are reused directly too (`Section_Header` degrades
   to `Bold` for any non-Gemtext `Config.Format`, which Hmm always is).

   `-L`/`--hmm-depth` (indentation baseline, `Config.Hmm_Depth`, resets
   per entity — doesn't accumulate across entities in one file, same
   as `besm2_fmt.Config.Hmm_Depth`) is included for parity with
   `besm2_fmt`'s own flag, since it needed no new design (a mechanical
   offset); `-R`/`--hmm-root`/`-S`/`--hmm-separate` (besm2_fmt's other
   two hmm-specific flags) are deliberately NOT ported — neither was
   discussed for OVA, and porting them without a design pass would be
   assuming rather than confirming, the opposite of how this backend's
   other choices were made.

   Fragments render the same minimal way as every other backend
   (`Is_Fragment`, deliberately untouched by `Config.Format`): one
   `Background`-or-bold-`Name` D1 line, one `Attributes: ...` D2 line
   (always compact, regardless of `-c`/`--hmm-compact-lists` — a
   Fragment's whole point is being flat/minimal), Combat/linked
   sections as normal.

   `GNUmakefile` gained `TEST_HMMOUTPUT`/`TEST_HMM_COMPACT_OUTPUT`/
   `hmm` (`build/%.hmm` via `-m`, `build/%.compact.hmm` via `-m -c`),
   following the established wildcard-derived-from-`TEST_DATA`
   convention. No PDF rendering, same reason as Gemtext: not a Pandoc
   reader, meant to be read/loaded into an outline viewer as-is.

   **`-p`/`--hmm-plain` added**, per the user, requested right after
   this backend first landed: turns OFF `*italic*`/`**bold**`/`***bold
   italic***` emphasis entirely for `-m`/`--hmm` output, off by default
   (emphasis stays on, matching the shape already confirmed). Unlike
   Gemtext's `-e`/`--gemtext-emphasis` (opt-in to *add* emphasis a spec
   with none at all doesn't have), this is opt-in to *remove* emphasis
   that's on by default -- the inverse polarity, since Hmm's underlying
   markup is reST-style and on by default like Terse's. Implemented in
   `Ova_Fmt.Format_Common.Bold`/`Italic` themselves (a new `No_Emphasis`
   check, `(Gemtext and not Gemtext_Emphasis) or (Hmm and Hmm_Plain)`),
   not as a wrapper in `Ova_Fmt.Format_Hmm` -- necessary, not just
   tidier: `Format_Attack_Line`/`Format_Combat_Summary_Line`'s own
   internal `Bold`/`Italic` calls (Health/Endurance/Defense/TV,
   Roll/DX/Endurance Cost, attack Description) aren't reachable from
   outside `Format_Common`, so a `Format_Hmm`-local wrapper around
   calls it makes *itself* would have missed those. No changes needed
   to `Ova_Fmt.Format_Hmm.adb` at all as a result -- it already called
   `Format_Common.Bold`/`Italic`/`Section_Header` throughout, so they
   all pick up `Config.Hmm_Plain` automatically.

   `GNUmakefile` gained `TEST_HMM_PLAIN_OUTPUT`/`build/%.plain.hmm`
   (via `-m -p`), same convention.

   Verified: a pre-change/post-change binary diff of Terse/Gemtext/
   Html_In_Rst output across every `test-data/**/*.yaml` fixture is
   byte-identical throughout this whole item (the `Format_Common`
   extraction/reuse refactor, and then the `No_Emphasis` change, touch
   only Hmm-reachable code paths); `-m`/`-m -c` on every fixture
   (Karis/Yuu's nested Companion, Fukiko's Transformation, Auren's
   Magic spells, Fragment.yaml, Vehicle.yaml) produce correctly nested,
   valid tab-indented outlines with no crashes; `-L`/`-n`/`-O` all
   confirmed working in `-m` mode too; `-p` (alone and combined with
   `-c`) confirmed to leave zero `*`/`**` characters in the output
   across every fixture, including the Attack/Combat-summary lines.
   `make rst pdf gemtext html hmm` all rebuild clean with no warnings.
6. ~~**groff-in-reST backend**~~ Done (`hd` table macros, not `tbl` — §7), in a
   `.. raw:: ms` block, through Pandoc's `ms` writer — same "reST
   document with one raw block spliced in for nested tables" shape as
   HTML-in-reST, groff/`ms` instead of HTML. Sequenced after
   HTML-in-reST deliberately — `hd`'s actual nested-table support
   still needs hands-on confirmation against the installed groff
   version (§ open questions), and having a working HTML-in-reST
   nested-table reference in hand first gives something concrete to
   compare `hd`'s real rendered output against while sorting that out.

   **Progress: `hd`'s nested-table support confirmed working, via a
   standalone experiment before touching `Ova_Fmt` at all** — same role
   `Fukiko-experiment.lout` played for the Lout backend (§3): a small
   hand-written worked example to build the real backend against,
   rather than debugging macro syntax and Ada code at the same time.
   `hd-experiment.ms`/`hd-experiment.rst` (repo root; rendered PDFs at
   `build/hd-experiment.ms.pdf`/`build/hd-experiment.rst.pdf`) record
   the findings in full via their own header comments; summary:
   - The installed groff is 1.23.0 (`groff -v`) — the version the plan
     already flagged as the one where `hd` should work, confirmed
     rather than assumed.
   - The actual macro file is `hdtbl.tmac` ("Heidelberger table
     macros," `/usr/share/groff/1.23.0/tmac/hdtbl.tmac`), loaded with
     `.mso hdtbl.tmac` — not a `-m` command-line flag. It auto-loads
     `hdmisc.tmac`/`62bit.tmac` itself.
   - Nesting is a designed-in feature, not incidental: the package
     tracks its own "table nesting level" register (`t*#`), and groff
     ships its own worked nested-table example
     (`/usr/share/doc/groff/examples/hdtbl/color_nested_tables.roff`).
     A hand-written Fukiko-style Abilities table with a nested
     Transformation sub-table rendered correctly (real borders/shading
     on both levels, right-aligned Level column, bold total row) via
     plain `groff -ms hd-experiment.ms -T ps | ps2pdf`, no warnings.
   - Cell horizontal alignment is the `hal` keyword (`b`/`c`/`r`/`l`),
     not `ad` — a first draft guessed `ad=r` and it was silently
     absorbed as literal cell content rather than erroring (hdtbl
     doesn't validate unknown `keyword=value` tokens against a fixed
     list). Worth remembering when debugging `Ova_Fmt`'s eventual
     output: a bad keyword there won't raise an error, it'll just show
     up as stray text in the cell.
   - The full intended pipeline was also verified end-to-end, not just
     bare groff: the same `hd` markup inside a `.. raw:: ms` block,
     run through `pandoc -r rst -w ms --template=tkb -o out.ms.pdf
     in.rst` (the exact command `GNUmakefile`'s `build/%.ms.pdf` rule
     already uses), passes through byte-for-byte into the intermediate
     `.ms` text and renders correctly via pandoc's default `ms`
     pdf-engine (`pdfroff`) — no extra flags, no template changes.
     One layout detail noted for later: the table floats to the top of
     the page ahead of surrounding prose in this pipeline, which is
     standard groff `-ms` floating-table behavior, not a nesting
     failure — something to address (or accept) once the real backend
     emits prose around its tables, not a blocker to this proof of
     concept.
   - Column widths are controlled with `.TBL`'s `width` argument: a
     quoted, space-separated per-column list, each value an absolute
     groff length (`0.75i`) or a `%`-suffixed percentage of the current
     line length. Values must be single-quoted (`width='10% 90%'`) —
     double quotes are not recognized by hdtbl's argument parser and
     produce a misleading "Invalid cell width 'width'" error instead
     (the whole token gets misparsed as the bare keyword `width`
     followed by unrelated cell widths). Used to narrow Fukiko's Level
     column to 10% (Name gets the remaining 90%); a nested table's own
     `width=` is relative to its cell's already-narrowed width, so
     nesting levels don't need matching splits. Confirmed both via
     plain groff and through the full Pandoc pipeline.

   **Major finding (this session, before any layout was confirmed with
   the user): `hd` tables have no pagination support at all, and
   overflow is silent, not an error.** Investigated because the user
   asked to organize the groff-in-reST output like the rulebook's own
   Sample Characters spread (§2.1/§2.2) — name/tagline header,
   Abilities/Weaknesses **side by side**, then a combined "Attacks &
   Combat Stats" box, then an "Other Statistics" box — rather than
   HTML-in-reST's sequential one-`<table>`-per-section layout.
   - The side-by-side placement itself works, using the same nesting
     hd already proved: an outer, borderless 2-column `.TBL` whose
     left/right cells each hold one complete bordered table (confirmed
     with Karis's real Abilities/Weaknesses, and with a 3-levels-deep
     version — Companion row nesting Arasuni's own Abilities,
     Weaknesses, *and* Combat-with-attacks tables all inside one
     cell).
   - But a full worked Karis/Arasuni version of that side-by-side
     layout — real data, real nesting depth — rendered with **the
     entire outer container silently missing**: no error, no warning,
     just absent from the output, while a separate, shorter "Attacks &
     Combat Stats" table on the same page rendered fine.
   - Bisected the cause with a plain, non-nested `hd` table (no
     nesting at all): at this document's font/margin/`cpd`/`csp`
     settings, a flat table with 28 body rows renders correctly; one
     row more (29) **vanishes completely**, with zero diagnostic
     output, regardless of how much room is left on the page (even
     starting fresh atop an otherwise-empty page). `hd` has no
     mechanism to break a table across a page boundary — a table
     taller than one page doesn't get truncated or pushed to the next
     page, it's simply dropped in its entirety.
   - Confirmed this isn't a bare-`groff`-only artifact: the same
     silent, total loss happens through the real intended pipeline too
     (`.. raw:: ms` → `pandoc -r rst -w ms --template=tkb -o out.pdf`,
     `pdfroff` under the hood) — an earlier "it worked!" reading of
     that test was a false positive from `grep`ing for text that also
     happened to appear in the document's own title, not the table;
     rechecked by counting actual row content and it fails identically
     to bare groff.
   - **Consequence for the side-by-side design specifically:** wrapping
     Abilities and Weaknesses together in one outer container roughly
     doubles the height that has to fit in one page budget compared to
     printing them separately, and genuine nesting (a Companion's own
     Abilities/Weaknesses/Combat tables-inside-a-cell, the entire
     reason `hd` was chosen over classic `tbl`) adds still more height
     to whichever table contains it. Karis/Arasuni — already the
     repo's best-established nested-Companion example — is enough on
     its own to trip this: the outer Abilities/Weaknesses container
     that includes Arasuni's full nested write-up exceeds the ~28-row
     ceiling and silently disappears.
   - This directly bears out §7's own pre-flagged caution about `hd`
     being a fragility risk, just discovered by testing rather than by
     a version upgrade: it's not merely "less well supported on some
     groff versions," it has a hard structural limitation (no
     pagination) that risks **silent data loss** — the worst failure
     mode, since nothing in the pipeline flags that anything went
     wrong.
   - **Resolved, per the user:** Companion/Vehicle sub-entities move
     out of the granting Ability's table cell entirely and print as
     their own separate section *after* the main character's whole
     write-up, structurally self-similar to a top-level character (own
     side-by-side Abilities/Weaknesses, own "Attacks & Combat Stats"
     box) — the Ability's own row in the main table just carries a
     short "— see below" pointer instead of a nested table. This isn't
     a compromise invented to dodge the pagination bug — it's what the
     rulebook's own Karis spread actually does (§2.3: Arasuni gets his
     own separately-boxed "Attacks & Combat Stats (ARASUNI)," laid out
     alongside Karis's own, not folded into her Abilities table), so
     the fix is *more* faithful to the primary source, not less.
     Transformation's sub-abilities/sub-weaknesses and Magic's spells
     are unaffected — they're short flat lists with no `combat:` block
     of their own, never came close to the row ceiling, and keep
     nesting directly in the granting row's cell as before. Rebuilt
     the full Karis/Arasuni worked example this way
     (`hd-layout-experiment.ms`/`.rst`, repo root, replacing the
     earlier abandoned all-nested attempt; rendered PDFs at
     `build/hd-layout-experiment.ms.pdf`/`.rst.pdf`): every individual
     table now stays well under 28 rows, and the previously-vanishing
     content all renders correctly.
   - **Second finding while re-testing:** even with every table safely
     undersized on its own, one more thing can still make a table
     disappear: **hd tables don't just fail past a one-page height
     ceiling, they fail to fit in whatever space happens to be left on
     the *current* page and do not automatically flow to a fresh page
     on their own** — a table with plenty of room to spare on a blank
     page still vanished silently when placed a little too close to
     the bottom of a page that was already partly full (Arasuni's
     Combat table, page 2 of the rebuilt example, immediately after
     his side-by-side Abilities/Weaknesses tables). **Fix: precede
     each top-level `.TBL` with a plain troff `.ne <estimated height>`
     request** (unrelated to hd itself — this is core troff's ordinary
     "need this much vertical space or start a new page" primitive) —
     confirmed this forces the table onto a fresh page instead of
     disappearing, with no downside beyond an intentional page break.
     **Design consequence for the real backend:** `Format_Groff` (or
     wherever this lands) needs to emit a `.ne` sized to each table's
     own estimated height immediately before emitting it — a
     mechanical row-counting exercise (header + one line per row +
     caption, times each table's own line height), not a layout
     judgment call, but a real piece of bookkeeping every table-
     emitting procedure needs, on top of just not exceeding the ~28-row
     per-table ceiling in the first place (still a real, if now much
     rarer, residual risk — e.g. a single attack-heavy character's own
     "Attacks & Combat Stats" box, which isn't split up by this
     Companion/Vehicle fix at all).
   **Progress: implemented, as a fourth `Config.Output_Format` value
   (`Groff_In_Rst`, `-G`/--groff`) inside `Ova_Fmt.Format_Rst`, same
   home as Html_In_Rst and for the same reason (§ Open Questions'
   naming analysis: these Pandoc-embedded backends are extensions of
   one family, not a reason to split `Format_Rst` apart).**
   Header/tagline/summary/background/personality stay byte-identical
   to Terse/Html_In_Rst via the shared `Print_Header_And_Prose`. The
   "Other Statistics" box is built straight from `fluff:` rather than
   reusing `Print_Tail`'s plain comma-joined Fluff line — which meant
   splitting `Print_Tail` into `Print_Notes`/`Print_Fluff` (inline)/
   `Print_Options_If_Shown`, now all public on `Format_Common`, so
   Groff_In_Rst can call Notes/Options directly and substitute its own
   Fluff rendering; verified behavior-preserving for every existing
   caller with a pre/post binary diff across every format before
   writing a line of the new backend.

   One correctness bug found and fixed during implementation, not
   caught by either hand-written experiment above: **`hd`'s `.TD`/
   `.CPTN` scan every trailing argument for a `keyword=value` match by
   comparing each token's own leading characters against hd's fixed
   keyword list (hal, val, fst, bc, bgc, fgc, csp, cpd, cols, border,
   height, tal, width, rowspan, colspan) — not by requiring a literal
   `=` first.** Real free-form Ability/Weakness detail text tripped
   this for the first time on Fukiko's Barrier ("...the second Defense
   **value** in Combat...") — `hd` read the plain English word "value"
   as an attempted `val=` cell-alignment keyword and choked with
   "Invalid vertical alignment 'e'". Fix, confirmed against both the
   original failure and a deliberately adversarial line combining every
   reserved keyword name: put any free-form/user-authored text (a
   Name/Detail/Note/Description — never this package's own fixed
   column-header or caption-template strings) on its own line
   following a bare (or keyword-args-only) `.TD`, never as a same-line
   trailing argument — hd's keyword scan only inspects the request
   line's own arguments, never text that follows. Two small helpers
   (`Put_Cell`/`Put_Caption`) centralize this so it can't quietly
   regress. `.CPTN` specifically keeps its caption as a quoted
   same-line argument rather than the same two-line treatment, though —
   found while testing this fix through the *real* Pandoc/pdfroff
   pipeline (not just bare groff) that `.CPTN`'s own next-line-caption
   support doesn't survive that pipeline (the caption leaks out as
   plain body text above the table instead, leaving the caption blank);
   a quoted single argument is grouped into one token by troff's own
   parsing before hd's scan runs, so it only re-opens the original bug
   if a caption's own leading text is a lowercase match — every caption
   here starts with either a fixed string or a user-authored name, and
   OVA names are conventionally capitalized throughout every fixture
   transcribed so far, so this narrower residual risk was accepted
   rather than chased further.

   A second, smaller issue found during the same testing pass: an
   Ability row pointing at its Companion/Vehicle section ("— see
   below") was hand-written using the troff `\(em` escape, which the
   new backslash-escaping step (needed for arbitrary user text, see
   above) silently mangled into literal `\e(em`. Fixed by using the
   literal em dash character directly, matching the convention
   `Format_Common`/`Format_Rst`'s own `Print_Sub_Entity_Tables`-style
   captions already used.

   A third issue, cosmetic rather than a correctness bug: an earlier
   version gave each Companion/Vehicle section its own plain `.B`
   heading line before its tables. Since `hd` tables don't stay in the
   surrounding document's normal text flow (the pre-existing "floats
   ahead of prose" quirk noted below and in the first experiment),
   that heading could drift away from the tables it was meant to
   label — confirmed happening for Karis: "Companion: Arasuni" rendered
   a full page *after* Arasuni's own Combat table instead of before his
   Abilities/Weaknesses. Fixed by folding "<Label>: <Name>" into each
   of the section's own table captions instead of separate running
   prose, which stays glued to its content no matter how the tables
   themselves get placed — and matches the rulebook's own convention
   more closely anyway (§2.3: Arasuni's own box is headed "Attacks &
   Combat Stats (ARASUNI)," not introduced by separate prose).

   Verified: a pre-change/post-change binary diff of Terse/Gemtext/
   Html_In_Rst output across every `test-data/**/*.yaml` fixture is
   byte-identical (both after the `Print_Tail` refactor and after the
   full backend landed) — the new format value and the `Print_Common`
   split together touch nothing else. `-G` on every fixture (Karis/
   Arasuni's full nested-Companion example, Fukiko/Miho's Transformation
   sub-abilities, Auren/Unsorted's Magic spells, Vehicle.yaml's Vehicle
   sub-entity, Fragment.yaml's unaffected flat rendering, Escaping.yaml's
   special characters) produces reST that Pandoc's real `-w ms`
   pipeline (`pandoc -r rst -w ms --template=tkb`, the same command
   `GNUmakefile`'s new `build/%.groff.pdf` rule uses) renders with no
   errors and no dropped tables — confirmed by grepping every expected
   table caption out of the rendered PDF's extracted text, not just
   eyeballing the intermediate reST. `GNUmakefile` gained
   `TEST_GROFFOUTPUT`/`TEST_GROFFRENDEROUTPUT`/`groff` (`build/%.groff.
   gen.rst` via `-G`, `build/%.groff.pdf` via Pandoc, the same `.ms.pdf`
   pipeline Terse's own PDF uses, since the deliverable here is a PDF
   like Terse, not a standalone format the way Gemtext/h-m-m/
   HTML-in-reST's `.html` are), following the same wildcard-derived-
   from-`TEST_DATA` convention as every other output-list variable.

   Two residual, accepted limitations, not fixed: (1) the per-table
   ~28-row silent-overflow ceiling and the need for a `.ne` before every
   top-level table (both above) still apply — an unusually attack-heavy
   character's own Combat box is the sharpest remaining edge, not
   addressed by the Companion/Vehicle-section fix; (2) `hd` tables float
   ahead of surrounding prose within a page rather than interleaving
   with it (first noted in `hd-experiment.ms`) — visible now with real
   prose alongside real tables, e.g. Other Statistics landing above a
   trailing line of Personality prose that logically precedes it. Both
   are `hd`/`-ms` limitations, not bugs introduced by this backend.
7. **Direct-to-Lout backend last.** No Pandoc involvement (§7) — a
   structurally separate output mode from the other three (genuinely
   direct, unlike HTML-in-reST/groff-in-reST), modeled on the existing
   `Fukiko-experiment.lout` worked example (§3), using
   `~/Reference/Document-Tools/lout/`'s `user.pdf`/`expert.pdf` (§2)
   as needed for anything beyond what that one example already shows.
   Still unimplemented.
8. **Markdown backend, added out of the original build order** (the
   user asked for it directly, after step 6/groff-in-reST landed, not
   at the point §9 originally scheduled it): `-M/--markdown`,
   `Ova_Fmt.Format_Markdown` — a thin entry point into
   `Ova_Fmt.Format_Common`, same shape as `Ova_Fmt.Format_Gemini`, since
   Markdown Terse-equivalent content is byte-for-byte the same
   bulleted-list/prose shape as Terse (reST) and Gemtext (§2.3's
   already-settled "only heading/list syntax differs, inline
   `**bold**`/`*italic*` markup is unchanged" finding, now cashed out a
   second time). The only new code is the entity title's own heading
   line: per the user (asked directly, since reST's `Underliner`/
   `Subunderliner`-by-character convention has no clean Markdown
   equivalent), a flat `# Title` ATX heading for every entity
   regardless of `Entity_No`, matching Gemtext's own choice and for the
   same reason (no character to swap, only a `#`-count depth, and flat
   was picked over nesting subsequent entities to `##`). No nested-
   table Markdown mode (an eventual Html_In_Rst/Groff_In_Rst analog)
   designed yet — this is Terse-equivalent only.

   Verified: a pre-change/post-change binary diff of Terse/Gemtext/
   Html_In_Rst/Groff_In_Rst/Hmm output (plain, and every existing flag
   combination — `-e`, `-c`, `-p`) across every `test-data/**/*.yaml`
   fixture (`Broken.yaml` excluded, same as every other such diff) is
   byte-identical — the new `Output_Format` value and the
   `Print_Header_And_Prose` branch touch nothing else. `-M` on every
   fixture produces Markdown that Pandoc's real `-r markdown -w html`
   reader parses with no errors, confirmed by grepping the rendered
   HTML for Karis's own `<h1>` title and a plausible `<strong>`/`<em>`
   count, not just eyeballing the `.md` output. `GNUmakefile` gained
   `TEST_MARKDOWNOUTPUT`/`markdown` (`build/%.md` via `-M`), following
   the same wildcard-derived-from-`TEST_DATA` convention as every other
   output-list variable.

   **Update, per the user:** Markdown *does* get a PDF pipeline after
   all (unlike Gemtext/h-m-m) — `pandoc -r markdown -w ms
   --template=tkb`, the same writer/template Terse's own PDF uses, just
   with `markdown` instead of `rst` as the reader — built automatically
   by `make markdown` alongside the plain `.md` files, not left as a
   separate opt-in step. Since Terse's reST-sourced PDF and Markdown's
   own now sit in the same `build/` directory through the same `ms`
   writer, both filenames were changed to carry their *source* format
   ahead of `.ms.pdf` so they can't collide or be confused: Terse's own
   `build/%.ms.pdf` became `build/%.rst.ms.pdf` (`TEST_PDFOUTPUT`,
   `make pdf`), and Markdown's new one is `build/%.md.ms.pdf`
   (`TEST_MARKDOWN_PDFOUTPUT`, `make markdown`) — `%.groff.pdf` was left
   alone (already unambiguous, and not asked for). Verified: `make pdf`
   and `make markdown` both rebuild cleanly for every fixture under the
   new names, `make gemtext html groff hmm rst` are all unaffected
   (`GNUmakefile`-only change, no `Ova_Fmt` source touched this pass),
   and `build/Karis.md.ms.pdf`'s extracted text (`pdftotext`) matches
   `build/Karis.rst.ms.pdf`'s content line for line.

9. **Keys for the character generator** (2026-10-09). ova_cg_po
   (`~/Repos/RPG/Tools/ova_cg_po`), an OVA character generator built
   on ova_fmt_po, saves what the character sheet has (§5) and what
   its calculations need, which ova_fmt had no keys for. The user
   decided they are added here first, then to ova_fmt_po, rather than
   left for ova_fmt to ignore. All are optional:

   | Key | Where | What |
   |---|---|---|
   | `player` | entity | the Player Name |
   | `appearance` | entity | text, like `background` |
   | `other-notes` | entity | the sheet's Other Notes, text (`notes:` is the headed callouts already) |
   | `portrait` | entity | the portrait image's path, relative to the YAML file |
   | `notes` | `combat` | the sheet's Combat Notes, text |
   | `transformed` | `combat` | `true`: the block is the transformed form's (Fukiko's sheet) |
   | `telekinesis` | attack | `true`: made with Telekinesis, which adds to its DX (p. 62) |
   | `transformed` | attack | `true`: made in the transformed form (p. 63) |
   | `threat-value-half` | Ability, granted Ability | whether half its Level counts toward TV (p. 124) |
   | `starting-levels` | `options` | Power Ceiling's starting levels (p. 21) |
   | `half-cost-knowledge` | `options` | `true`: Knowledge and Ineptitude at half cost |
   | `overrides` | attack, `combat`, Ability, granted Ability, spell | the computed numbers the user set by hand |

   `overrides` is a sequence of key names, each one a number the
   generator computes in that mapping: an attack's `roll`, `dx`,
   `endurance`; `combat`'s `defense`, `defense-2` and `defense-3`
   (the second and third values of a `2/4/6` Defense; `defense-2` was
   `barrier` until a Defense could hold three, and `barrier` is still
   read as it), `health`, `endurance`, `threat-value`; an
   Ability's, granted Ability's or spell's `endurance`. Any other
   name, an item that isn't a scalar, or an `overrides` that isn't a
   sequence is a load error, recorded like a missing required key
   (`Load_Overrides`): a misspelled name would otherwise silently drop
   a mark. A listed key that is absent from the mapping is allowed.

   How each prints (the proposal the user accepted, made concrete
   here):
   - `player`: in the title, after the name and concept: `Hana Mori
     (Telekinetic Schoolgirl), played by Sam` (`Entity_Title`, shared
     with h-m-m). A Fragment has no title, so no player.
   - `appearance`: a section between Background and Personality, the
     sheet's order; `other-notes`: an "Other Notes" section after the
     Notes callouts (`Print_Notes`, so `-G` has it too). A Fragment
     prints neither Appearance nor Personality, as before.
   - combat `notes`: a "**Combat Notes:**" paragraph after the
     attacks, not a bullet (several lines would need indenting in a
     reST bullet); in the `-H` and `-G` tables, a `<p>` after the
     attacks table and a last full-width row of the combat box, on
     one line (`All_One_Line`, moved from Format_Hmm to Format_Common),
     since every line of a raw block must keep its indent. The `-G`
     row count for `.ne` adds a row per 80 characters.
   - `portrait`: an `.. image::` directive, with the name as its
     `:alt:`, after the title, in `-H` only. The path is the YAML
     file's, so the HTML must be made beside the YAML file to find it.
   - `threat-value-half`: "` (half TV)`" after the Level, only with
     `-O` and only when true, as the options are shown; in the `-G`
     tables after the name, since the Level column is too narrow.
     `starting-levels` and `half-cost-knowledge` join the Creation
     Rules: `Power Ceiling (30), Starting Levels (20), Half-Cost
     Knowledge` (`Options_Text`, shared with h-m-m).
   - an overridden number gets a `*` after it (`Override_Mark`): `3*
     dice`, `DX 3*`, `3*/4*` with both halves of the Defense listed.
     In reST and Markdown text it is written `\*`, so it can't open
     emphasis; in Gemtext and h-m-m, and in the raw HTML and groff
     tables, a plain `*`. An Ability's or granted Ability's own
     `endurance` is printed nowhere, so its override shows only in
     the generator.
   - `telekinesis` and `transformed` (attack and combat) are not
     printed: they are inputs to the generator's calculation, and the
     numbers printed already include them.

   The samples carry the keys that apply to them, each commented:
   Ai's attacks `telekinesis`, Fukiko's combat `transformed` (her
   sheet shows her transformed), Miho's Mode SP `transformed`, and the
   book's two rulings in `overrides`, Braun's First Day of Sale
   Shove!'s ROLL and Natsuki's Stiletto Kick's DX, which now print with
   `*`. With these, ova_cg_po computes every other number of every
   sample as the book prints it.

   `test-data/Sheet.yaml` uses every key: a synthetic character, with
   `overrides` on each kind of mapping, among them a fragment
   Companion's combat block (printed through the plain reST path even
   under `-H`/`-G`, so it gets `\*`), and Combat Notes holding `<`,
   `&` and a line starting with `.`. Every number it doesn't list in
   `overrides` is the rules', as ova_cg_po computes them: it loads
   there with no notices.

   Verified: before the samples gained their keys, every existing
   fixture's output, in all 368 of ova_fmt_po's golden cases (every
   format and flag), was byte-identical before and after; after, only
   Braun's and Natsuki's changed, by the `*`; `Sheet.yaml`'s reST outputs (`""`,
   `-H`, `-G`) pass `rst2html --halt=info`; pandoc's reST, Markdown
   and CommonMark readers all read each `\*` as a literal `*`, inside
   bold too (`**DX 3\***`), with no new emphasis; `make
   build/Sheet.groff.pdf` renders the stars, the Defense pair, the
   half-TV names and the Combat Notes row.
10. **Inline backend** (`Ova_Fmt.Format_Inline`, `-i`/`--inline`;
   2026-10-23). Asked for by the user, after liking the Cast of
   Lost-Worlds' `001-breakout.md`: each entity as one Markdown
   paragraph, a stat block for an adventure's cast list:

       **Name** (Secondary). Summary. Background. *Ability +2 (detail),
       ...; Weakness −1, ...* Attack (Perks; Flaws): Roll 4, DX 3, End
       0. Defense 3. Health 20, Endurance 20. TV 6.

   Written first in ova_fmt_po (its `OvaInline`) and ova_cg_po (the
   Markdown tab's Inline button), then ported here so ova_fmt_po's
   golden cases for it can come from this program like every other
   format's. It leaves out what a cast list doesn't need: the tagline,
   character hooks, notes, fluff, options, the player and the
   portrait. The prose (summary, background, appearance, personality)
   runs together, each part made a sentence (ending in `.`, `!` or
   `?`, perhaps before a closing quote or parenthesis), as do the
   combat notes. A Fragment with a background leads with it, then
   "Secondary NPC.". Each linked Ability (Transformation, Magic,
   Companion, Vehicle) follows as its own paragraph, led by its title
   in bold. Each paragraph is filled to 70 columns, counting
   characters, not bytes, and a word that would open a Markdown block
   at the start of a line (`#`, `>`, a lone `+`, `10.`, `1)`, `---`,
   `===` ...) stays with the word before it. Its own package, like
   Format_Hmm; `Format_Common.Format_Perk_Flaw` is now public for it.
   `make inline` builds `build/NAME.inline.md`.

   Later the same day the user asked for "Attack +2 (details)", the
   cast's order, rather than "Attack (details) +2", and for every
   Ability and Weakness, not only Attack. So the inline format uses the
   NPC Fragment order, "Name Level (detail)" (`Join_Fragment_Abilities`,
   `Join_Fragment_Weaknesses`, `Join_Fragment_Sub_Items`), for the
   entity's own, a Companion's or Vehicle's, and a Transformation's
   grants. A linked Ability's bold title keeps "Name (detail)".

   Verified: ova_fmt_po's 103 inline golden files, made with its own
   program, came out byte-identical when regenerated from this one
   (and 99 of them changed with the fill width planted at 80); the
   two agree on a summary built to test the block-opening rule and on
   Lost-Worlds' `001-cast.yaml`.

**`GNUmakefile` convention to keep as each new backend lands, per the
user:** every existing output-list variable (`TEST_TERSEOUTPUT`,
`TEST_PDFOUTPUT`, `TEST_GEMTEXTOUTPUT`, and now `TEST_HTMLOUTPUT`/
`TEST_HTMLRENDEROUTPUT`) is derived from the single wildcard-based
`TEST_DATA` (`$(foreach f,$(notdir $(TEST_DATA)),...)`, same shape
`besm2_fmt`'s own `GNUmakefile` uses for its several output variants),
not a hardcoded per-fixture list — confirmed this is why `test-data/
Fragment.yaml` got a `build/Fragment.ms.pdf` (and, once Gemtext/
HTML-in-reST landed, a `build/Fragment.gmi`/`build/Fragment.html`)
automatically the moment it was added, no `GNUmakefile` change needed
(`test-data/Escaping.yaml`, added for the HTML-in-reST work itself,
confirmed the same thing again). Each remaining backend's own
output-list variable (an eventual `TEST_HMMOUTPUT`, `TEST_LOUTOUTPUT`,
...) needs to follow the same derived-from-`TEST_DATA` shape, not
enumerate fixtures by hand, so every existing and future
`test-data/**/*.yaml` file keeps getting picked up for every format
automatically.

## Open questions

- **`Format_Terse`'s name is stretched thin, and there are two
  different things future backends might mean by "HTML"/"groff."**
  Raised by the user right after the Gemtext backend landed. Terse and
  Gemtext share `Ova_Fmt.Format_Terse`'s content-assembly logic because
  they're both members of the same family: plain-text lines with a
  sigil for emphasis/headings/bullets (`**bold**`/`*bold*` vs. no
  emphasis at all, reST's underline vs. `#`, `- ` vs. `* `) — the
  `Bold`/`Section_Header`/`Bullet` parameterization (this session's
  Gemtext work) fits that family cleanly, and would fit Markdown too
  if that were ever wanted. But "Terse" was originally BESM's name for
  one specific content *style* (as opposed to besm2_fmt's grid-table
  style) — stretching it to also mean "the whole reST/Gemtext
  plain-text-markup family" is already a bit of a reach, confirmed
  worth flagging rather than living with silently.

  Separately: **the HTML-in-reST and groff-in-reST backends already
  planned (§7/§9) are not "direct to HTML/groff" at all** — as
  designed, both are reST documents with one raw block spliced in
  (`.. raw:: html`/`.. raw:: ms`) for the one thing reST tables can't
  do (nesting), still run through Pandoc. That means they're
  extensions of the same reST/Gemtext family `Format_Terse` already
  covers (same headers, same emphasis, same bullets, just one extra
  block type for tables) — implementing them doesn't require
  reorganizing anything, just adding a third/fourth
  `Config.Output_Format` value.

  A **genuinely different** kind of backend — standalone HTML (real
  `<h1>`/`<strong>`/`<table>` tags) or raw groff/`ms` source, generated
  directly without going through reST/Pandoc at all — would NOT fit
  `Format_Terse`'s model, since HTML/groff are tag-or-macro-based, not
  plain-text-lines-with-a-sigil the way reST/Gemtext both are. That
  would need its own package(s), sharing only `Ova_Fmt.Entities`'s
  typed data underneath, not `Format_Terse`'s emphasis/heading/bullet
  helpers.

  **Superseded — reopened and resolved in a later session.** The user
  revisited this rather than waiting for a third family member: split
  by output *pipeline* rather than by code-sharing — `Ova_Fmt.
  Format_Rst` (Terse, Html_In_Rst, and the future groff-in-reST, all
  of which feed Pandoc's reST reader) and `Ova_Fmt.Format_Gemini`
  (Gemtext, which is not reST and never touches Pandoc). Confirmed
  during the discussion that this axis doesn't match the code's actual
  sharing pattern — Terse and Gemtext share far more content-assembly
  logic with each other (the whole bulleted-list rendering,
  `Print_Header_And_Prose`) than Terse shares with Html_In_Rst's own
  table renderers — so per the user, that shared logic was factored
  into a third package, `Ova_Fmt.Format_Common`, rather than either
  duplicated between `Format_Rst`/`Format_Gemini` or used as an excuse
  to keep Terse and Gemtext bundled together. `Format_Common` holds:
  `Bold`/`Italic`/`Section_Header`/`Bullet` (unchanged — they already
  gated on `Config.Format = Config.Gemtext` internally, so needed no
  parameterization to serve both new packages), the number/text/Perk-
  Flaw/attack-clause formatters, `Print_Header_And_Prose`, the new
  `Print_Tail` (Notes/Fluff/Creation-Rules, extracted from the old
  `Process_Entity`'s unconditional tail — shared across literally
  every format and entity kind, Fragment included), and
  `Process_Entity` (Fragment-or-flat-bulleted-list rendering, used
  directly by both `Format_Gemini.Process_Entity` and by
  `Format_Rst.Process_Entity` for Terse mode/any Fragment).
  `Format_Rst` keeps only what's actually Html_In_Rst-specific
  (`Html_Escape`, `Strip_Parens`, the `<table>` renderers) plus a
  three-line dispatch: Html_In_Rst-and-not-a-Fragment calls
  `Format_Common.Print_Header_And_Prose`/its own tables/
  `Format_Common.Print_Tail`; everything else delegates whole to
  `Format_Common.Process_Entity`. `Format_Gemini` is a one-line
  forwarding wrapper. `ova_fmt_main.adb` now dispatches between
  `Format_Rst.Process_Entity`/`Format_Gemini.Process_Entity` on
  `Config.Format = Config.Gemtext`, instead of calling one package
  unconditionally.

  Verified: a pre-refactor/post-refactor binary diff across every
  `test-data/**/*.yaml` fixture, in every output mode (`-g`, `-g -e`,
  `-H`, `-n`, `-O`, plain), is byte-identical — the split is fully
  behavior-preserving. `make rst gemtext html pdf` all rebuild clean
  with no warnings.
- **TODO: audit which fields are actually optional vs. required, and
  what happens when a required-looking one is absent.** `tagline` and
  `summary` are confirmed optional (`Ova_Fmt.Entities`'
  `Has_Tagline`/`Has_Summary`, checked before rendering — absence
  just skips that line). But most of `Ova_Fmt.Entities.adb`'s other
  `Load_*` functions use *required* accessors (`String_Value`/
  `Integer_Value` with no `Default`, raising `Libfyaml.Missing_Key`
  if absent) for fields that merely happen to be present in all
  twelve transcribed `test-data/sample-pcs/*.yaml` characters — that's not the
  same as confirming the game rules actually require them.

  ~~Every Ability/Weakness/Sub_Item/Spell's `level`~~ Resolved (per
  the user, prompted by the analogous BESM question — see
  `besm2_fmt`'s `PLAN.md`, where Defects turned out to have *no*
  Level at all, unlike Attributes/Skills): **there's no OVA analog to
  that BESM asymmetry.** BESM splits "Points" (always present, the
  point-buy currency) from "Level" (present on Attributes, sometimes
  absent; present on Skills, always; absent entirely on Defects) —
  three different fields serving three different roles depending on
  category. OVA has no such split: an Ability's Level *is* its Bonus,
  a Weakness's Level *is* its Penalty, with no separate points-style
  currency underneath at all — so both Abilities and Weaknesses (and
  every linked shape that carries a Level: `Sub_Item`, `Spell`) always
  require it structurally, not just in the twelve transcribed
  fixtures. Confirmed by checking the code: all four `Load_*` call
  sites that read `"level"` (`Load_Sub_Item`, `Load_Spell`,
  `Load_Ability`, `Load_Weakness`) already use the required accessor,
  correctly, with no optional/`Has_Key`-guarded case anywhere — this
  part of the audit needed no code change, only confirming the
  reasoning holds.

  ~~Every Attack's `roll`/`dx`/`endurance` (always present so far, but
  is it guaranteed...)~~ Resolved, in the same answer that settled the
  `combat:` block below: an Attacks *list* can be entirely absent
  (some NPCs have no Attacks at all — already handled, `Load_Combat`
  only iterates `attacks:` when the key is present), but once an
  Attack *is* present, all of its parts — `roll`/`dx`/`endurance`
  included, unlike `combat:`'s Threat Value — should be available.
  `Load_Attack`'s existing required accessors for all three are
  correct as-is; no code change needed.

  Still worth auditing: every Spell's `ability`/`level`/`endurance`
  (renamed from `mimics` — see "Decisions already made" below).

  ~~The `combat:` block's `defense`/`health`/`endurance`/`threat-value`
  as a set (could a Companion legitimately have Health/Endurance but
  no meaningful Threat Value?)~~ Resolved, per the user: an entity or
  Companion's `combat:` block itself stays fully optional (some NPCs
  have no combat stats or Attacks at all — `Load_Entity`/`Load_Companion`
  already only call `Load_Combat` when the `combat:` key is present).
  But once a `combat:` block *is* present, `defense`/`health`/
  `endurance` stay required — only `threat-value` may legitimately be
  left out (an author who didn't bother assigning one), rendered as an
  em dash ("—") rather than left blank or erroring. Implemented:
  `Combat_Stats` gained a `Has_Threat_Value` flag (mirroring
  `Has_Combat`'s own optionality pattern), `Load_Combat` now guards
  `threat-value` with `Has_Key` instead of a bare `Integer_Value`, and
  `Format_Terse.Print_Combat_And_Attacks` prints "—" when it's absent.
  Verified: all 12 `test-data/sample-pcs/*.yaml` fixtures already carry
  `threat-value`, so a pre-change/post-change binary diff is
  byte-identical across all of them; a synthetic no-`threat-value`
  fixture renders `**Threat Value (TV):** —` as intended, with
  Health/Endurance/Defense unaffected.

  ~~A Note's `header`/`text` (could one be header-only?)~~ Resolved,
  per the user: a Note always has both `header` and `text` when
  present — `Load_Note`'s current required accessors for both are
  correct as-is. (The *list* of notes is separately, and already
  correctly, optional: `Load_Entity` only iterates `notes:` when the
  key is present at all, via `Notes_Node.Is_Valid`.)

  **New finding, not originally part of this audit: Abilities/
  Weaknesses/Perks/Flaws should be alphabetized; `ova_fmt` wasn't doing
  it at all.** Surfaced by the user pointing out the rulebook's own
  "NPC Fragments" minor-NPC format (p. 142 — a compact `Attributes:
  <Abilities>; <Weaknesses>` line, Abilities and Weaknesses each
  independently alphabetized) and asking whether normal output does
  this too. It didn't — `Ova_Fmt.Entities` had no sorting anywhere.
  Checking every other `test-data/**/*.yaml` file confirmed the same
  convention holds beyond just Fragments: Entity-level Abilities/
  Weaknesses, Companion's own Abilities/Weaknesses, a Transformation-
  granting Ability's linked sub-Abilities/sub-Weaknesses, and every
  Ability/Attack's Perks and Flaws are alphabetized (each list
  independently) in the source data — but Attacks and Spells are NOT
  (Karis's Attack order, Auren's spell order both preserve a
  non-alphabetical given order). This had gone unnoticed because every
  transcribed fixture happened to already be alphabetized by hand.

  Implemented, mirroring `besm2_fmt.Entities`' own
  `CI_Less`/`Generic_Sorting` shape: `Ability_Sorting`/
  `Weakness_Sorting` (applied to `Entity.Abilities`/`Weaknesses` in
  `Load_Entity`), and `Perk_Flaw_Sorting`/`Sub_Item_Sorting` applied
  inside `Load_Perk_Flaw_List`/`Load_Sub_Item_List` themselves — single
  choke points, so one fix there covers every call site at once
  (Attack/Sub_Item/Ability's Perks and Flaws; Companion's Abilities/
  Weaknesses; a Transformation-granting Ability's sub-Abilities/
  sub-Weaknesses).

  One real bug surfaced while verifying against the existing fixtures:
  `Ada.Containers.Vectors.Generic_Sorting.Sort` is not guaranteed
  *stable*, so a plain by-Name comparator left same-named items (e.g.
  Braun's three "Knowledge" Abilities, distinguished only by `detail`:
  Computer Whiz/Cosplay/Games, Anime, & Manga; Auren's two "Quirk"
  Weaknesses) in an arbitrary, sort-algorithm-dependent relative order
  — confirmed by a pre-change/post-change binary diff across all 12
  fixtures, which reshuffled exactly those ties and nothing else.
  Fixed per the user: every comparator (`Ability_CI_Less`/
  `Weakness_CI_Less`/`Perk_Flaw_CI_Less`/`Sub_Item_CI_Less`) breaks a
  Name tie by comparing `Detail` next, deterministically. Re-verified:
  the same binary diff now shows exactly one remaining difference
  (Miho's attack Perks/Flaws, e.g. "Ranged, Overwhelming" →
  "Overwhelming, Ranged") — a genuine fix, since that fixture's source
  data was never actually alphabetized, unlike the others.

  Added `test-data/Unsorted.yaml`: a synthetic (non-rulebook, no
  copyright concern) fixture exercising every sorted list at once, all
  deliberately given out of order — top-level Abilities/Weaknesses, an
  Ability's Perks/Flaws, an Attack's Perks/Flaws, a Companion's own
  Abilities/Weaknesses, and a Transformation's granted sub-Abilities/
  sub-Weaknesses — plus an Attacks list and a Spells list also given
  out of order, to confirm those two are correctly left unsorted.
  `./ova_fmt test-data/Unsorted.yaml` verified by hand: every sorted
  list comes out alphabetical, Attacks/Spells preserve their given
  (non-alphabetical) order.

  ~~Also worth deciding, not just auditing: when a genuinely required
  field really is missing, is aborting the *whole file* with a
  `Missing_Key` error... the right failure mode?~~ Resolved, per the
  user: **every `Spell` field (`ability`/`level`/`endurance`) is
  confirmed required**, same as Attack's fields — no code change
  needed there, `Load_Spell` already used required accessors
  correctly. And the failure mode itself is settled too, a genuine
  design change from before: **collect every problem in the file and
  report them all, produce no output at all, exit non-zero** — not
  abort on the first one found, and not silently degrade per-field
  either.

  Implemented as a real architectural change, not just a message-text
  tweak. `Ova_Fmt.Entities` gained `Require_String`/`Require_Integer`
  (every previously-bare `String_Value`/`Integer_Value` required-field
  call site across `Load_Perk_Flaw`/`Load_Attack`/`Load_Combat`/
  `Load_Sub_Item`/`Load_Spell`/`Load_Companion`/`Load_Ability`/
  `Load_Weakness`/`Load_Note` now goes through one of these instead):
  each records a `Load_Error` (message, structural `Path`, and an
  optional approximate `Location`) and returns a placeholder value
  rather than raising, so loading keeps going and can turn up every
  other problem in the same entity/file rather than stopping at the
  first. `Load_Spell`/`Load_Note` were converted from aggregate
  expression-functions to sequential function bodies for this, since
  Ada doesn't guarantee a record aggregate's components evaluate in
  field-declaration order and these calls have the side effect of
  recording errors in that order. `Ova_Fmt_Main.Process_One` now loads
  every entity in a file into an `Entity_Vectors.Vector` (`Load_Entity`
  itself no longer renders inline) *before* checking `Error_Count`
  once — rendering only happens if it's zero — so a problem discovered
  in, say, the third entity of a file no longer leaves the first two
  already written to stdout/the output file; confirmed live with a
  synthetic file whose first entity is well-formed and second isn't
  (`test-data/Broken.yaml`), stdout genuinely empty (0 bytes) either
  way. Also fixed a real pre-existing gap while touching this: the
  `Process_One` exception handler (still used for hard parse errors,
  which stay a whole-file abort — reasonable, there's no tree to keep
  walking) never actually set a non-zero exit status before; it does
  now, same as the new required-field-error path.

  Two independent location primitives, per the user, added to
  `alibfyaml` first (`~/Repos/Ada/alibfyaml`, commit `a5ad89d`) rather
  than assumed to already exist: `Libfyaml.Nodes.Location` (pre-
  existing, scalar-only, a real source line/column) and the new
  `Libfyaml.Nodes.Path` (works on a node of any kind, mapping/sequence
  included — the inverse of the pre-existing `By_Path`). `ova_fmt`
  uses both together, per the user: every error's `Path` is exact
  (`N.Path & "/" & Key`, always available even when the missing key
  itself has no node/token of its own); `Location` is only ever an
  *approximation* here, via the problem's enclosing item's own "name"
  field (when present and itself a plain scalar with a real position)
  — `combat:` blocks and `Note`s have no "name" sibling to anchor to,
  so their errors get Path only, documented at each such call site
  rather than treated as a bug. Reported gcc-style
  (`file:line:column: error: path: message`) when a Location is
  available, `file: error: path: message` otherwise, followed by a
  `N error(s) in <file>; no output produced` summary line, all to
  standard error.

  One known, accepted cosmetic limitation, not chased further: with
  `-o`, the destination file still gets *created* (and, per a
  pre-existing GNAT `Ada.Text_IO` quirk unrelated to this feature, ends
  up 1 byte -- a bare trailing newline, confirmed live -- rather than
  0) even when errors suppress all real rendering, since `Ada.Text_IO.
  Create`/`Set_Output` happen before `Process_All` runs and there's no
  way to know yet whether any input file will error. Achieving a
  literal "file never created at all" guarantee would need buffering
  every file's rendered output in memory before ever touching the
  real output file/stdout, a bigger change not attempted here — "no
  character output was produced" already holds exactly either way.

  `test-data/Broken.yaml` added: a synthetic (non-rulebook) fixture,
  one well-formed entity followed by one with five distinct missing-
  required-field problems spread across top-level Abilities/
  Weaknesses and a nested Attack, verifying every one is reported
  together with the right Path/Location combination and that nothing
  renders for either entity. Excluded from `GNUmakefile`'s `TEST_DATA`
  (and so from `make rst`/`make pdf`) since it's supposed to fail --
  left in, it aborted those targets before every other, well-formed
  fixture got its turn.

  Verified: all `Require_String`/`Require_Integer` conversions are
  behavior-preserving when nothing's actually missing -- a
  pre-change/post-change binary diff across every real `test-data/
  **/*.yaml` fixture is byte-identical.
- ~~**Terse output format: Markdown or reST?**~~ Resolved (§2.3):
  reST. The user's Karis mockup was written in Markdown for an
  unrelated purpose (a customized game-session write-up, not the
  book's Karis) and translated to reST in the plan — only heading/list
  syntax differs, inline `**bold**`/`*italic*` markup is unchanged.
- ~~**Karis mockup's header tagline sentence**~~ Resolved (§2.3): a
  new, author-written schema field, tentatively named `summary`
  (§4) — not derived from `background`.
- ~~**Karis mockup's divergences from the primary rulebook text**~~
  Resolved/moot (§2.3): the user clarified the mockup was customized
  for a specific game session and its specific values (names,
  numbers, the trailing `(-5)` after TV) aren't meant to be accurate
  or literal — only its *structure* is the design target. No further
  investigation needed.
- ~~**Nested-table rendering**~~ Resolved (§7): terse-prose for the
  default text format (sidesteps the problem), hand-written nested
  `<table>` markup in raw HTML blocks, groff `hd` macros (not `tbl`)
  in raw-ms blocks, and a genuinely separate directly-rendered Lout
  backend (no Pandoc involvement) modeled on `Fukiko-experiment.lout`.
- ~~**YAML schema**: `name:`/`level:`-keyed items (`Fukiko.yaml`-style)
  vs. "key names the attribute" (`Auren.yaml`-style)~~ Resolved, per
  the user: **confirmed as final, matching what's already in use.**
  All 12 sample-character fixtures, `Unsorted.yaml`, and
  `Broken.yaml` already use the `name:`/`level:`-keyed form
  throughout (the old `Auren.yaml`-style was only ever a property of
  the *original*, since-superseded `Auren.yaml` transcription in the
  old Scheme project's test-data — this repo's from-scratch
  `test-data/sample-pcs/Auren.yaml` was written in the `name:`/`level:` form from
  the start, §9 step 1). Nothing to change in the schema or
  `Ova_Fmt.Entities`; this just closes out the "recommended but not
  committed" status.
- ~~**`options` block**: character-creation-limit metadata — rendered
  in any output format, or purely for the YAML author's own
  reference?~~ Resolved, per the user: **both** — useful to a player
  updating their character and to the GM, but not something every
  render needs, so it's gated behind a new `-O`/`--options` flag
  (`Config.Show_Options`), off by default.

  Checked the actual rulebook mechanics before designing the schema
  (`~/Reference/RPG/OVA/ova-rulebook.txt`, "Limiting the Character,"
  p. 20-21) rather than guessing from PLAN.md's own earlier candidate
  field list: there are exactly four named rules, not all simple
  flags. **Base Zero** (total Ability Bonuses minus Weakness
  Penalties should stay within a tolerance of zero — ±5 by rulebook
  default, "or another number at the GM's discretion") and **Power
  Ceiling** (total Ability Levels can never exceed a GM-set number)
  each carry a GM-set integer; **Scaled Cost** (a fixed 1/2/4/8/15
  point cost curve for Levels 1-5, not GM-adjustable) and **Combined
  Effectiveness** (a fixed guideline, rarely more than +5 total Bonus
  to any one roll) are just flags, nothing to parameterize.

  Implemented as `Ova_Fmt.Entities.Options_Block`
  (`Has_Base_Zero`/`Base_Zero`, `Has_Power_Ceiling`/`Power_Ceiling`,
  `Scaled_Cost`, `Combined_Effectiveness` — each of the four
  independently optional, matching `Fluff_Block`'s own per-field
  `Has_*` shape) and `Entity.Has_Options`/`Options`, loaded from a new
  `options:` block:
  ```yaml
  options:
    base-zero: 5
    power-ceiling: 15
    scaled-cost: true
    combined-effectiveness: true
  ```
  `Format_Terse` renders a `**Creation Rules:** Base Zero (±5), Power
  Ceiling (15), Scaled Cost, Combined Effectiveness.` line (only the
  rules actually present, comma-joined, same shape as the existing
  `Fluff` line) right after `Fluff`, but only when `Config.Show_Options`
  is set. Added `test-data/Options.yaml` (synthetic, not from the
  rulebook): one entity with all four rules set, a second with only
  `power-ceiling` set, confirming a partial `options:` block renders
  just that one rule rather than placeholders for the other three.
  Verified: a pre-change/post-change binary diff across every other
  `test-data/**/*.yaml` fixture is byte-identical (none of those use
  `options:`); `Options.yaml` itself renders both entities' rules
  correctly with `-O` and shows nothing options-related without it.
- ~~**TODO: NPC Fragment support**~~ Resolved and implemented. The
  rulebook's own minor-NPC format (p. 142, "NPC Fragments"), distinct
  from the full-character write-up every sample character and
  `Ova_Fmt.Entities`/`Format_Terse` were otherwise modeled on: the
  NPC's name bolded inline within `background`'s own prose ("The
  **Shady Teacher** is new to the school...") rather than a separate
  title/header; then a single compact `Attributes:` line — Abilities
  then Weaknesses, each list independently alphabetized (confirming,
  from a second source, the alphabetization already implemented per
  the audit above), comma-joined within each list, semicolon-separated
  between the two.

  Per the user: an explicit `fragment: true` schema marker, not
  auto-detected from a sparse field set — an NPC Fragment is otherwise
  the *same shape* as a full character (loaded through the exact same
  `Load_Entity`/`Load_Ability`/`Load_Weakness` path, same `Entity`
  type), just missing most of the optional fields a full write-up
  has. One thing does become required regardless of `fragment:`,
  though, per the user ("it has to have a name of course"): `Entity`'s
  `Name` — previously `Has_Name`-guarded like `Tagline`/`Summary`, now
  goes through `Require_String` like everything else genuinely
  required, so a nameless entity is now a reported error (Path
  `/<n>/name`) rather than a silently headerless render.

  Implemented: `Entities.Entity.Is_Fragment` (plain flag, loaded from
  `fragment:`, `Boolean_Value`). `Format_Terse.Process_Entity` branches
  on it — `Print_Fragment_Header` prints `Background` raw (the name is
  expected embedded and bolded by the author within it, matching the
  rulebook's own convention exactly, so no ova_fmt code tries to
  auto-generate the "The **X** is..." sentence) or falls back to a
  bare bolded `Name` if there's no `Background` prose to carry it;
  `Print_Fragment_Attributes` prints the combined line. Everything
  else (Combat/Attacks/linked-content sections/Notes/Fluff/Creation
  Rules) still renders exactly as it would for a full character if
  present, since a Fragment is only *typically* sparse, not
  structurally forbidden from having them.

  One real formatting difference found comparing against two
  independent rulebook examples, not just one (Shady Teacher and
  Snobbish Upperclassman): a Fragment's `Attributes:` line orders a
  `detail` *after* the Level (`Quirk −1 (Always Wears Sunglasses)`,
  `Knowledge +2 (Kendo)`) — the opposite of `Format_Ability_Line`/
  `Format_Weakness_Line`'s "Name (detail) Level" used everywhere else
  in this program. Added `Format_Fragment_Ability_Line`/
  `Format_Fragment_Weakness_Line` rather than reusing the existing
  formatters, confirmed correct against both examples.

  Added `test-data/Fragment.yaml`: both rulebook NPC Fragment examples
  above, transcribed (game-mechanical data faithfully, the short
  descriptions kept close to source as brief captions, same
  copyright-conscious policy as every other `test-data/**/*.yaml` file).
  Verified: `ova_fmt test-data/Fragment.yaml` output matches the
  rulebook page's own text exactly for both NPCs; a pre-change/
  post-change binary diff across every other `test-data/**/*.yaml`
  fixture is byte-identical (`Entity.Name` going from optional to
  required doesn't change anything since all of them already have
  one); a synthetic no-`name` fixture now reports `/0/name: missing
  required key "name"` and produces no output, as expected from the
  error-collection redesign.
- ~~**`combat.defense: "4/5"`**~~ Resolved (§2.2): the pair is the
  character's normal Defense Roll alongside their Barrier-Ability
  Defense Roll (Barrier's rules text: *"Instead of making a normal
  Defense Roll in combat, you may roll your Barrier dice"*) — present
  on any sample character with Barrier (confirmed on both Fukiko, who
  gets Barrier via Transformation, and Ai, who has Barrier as a plain
  top-level Ability with no Transformation at all), not a main-form/
  transformed-form split as first guessed. **Decided:** still render
  Defense verbatim as printed (`4/5` etc., an int-or-pair schema
  value, not two separately-named fields); add a short explanatory
  note on Barrier's own list entry instead, so the connection is
  documented where the Ability is, not computed/explained inline at
  the Defense field.
- ~~**Nested-ability rendering may need two distinct shapes, not
  one**~~ Resolved (§2.2): confirmed via the Magic, Arcane rules text.
  A "spell" has no Level of its own — it mimics another Ability at
  that Ability's Level, Endurance cost looked up from a table keyed on
  (mimicked Ability Level, caster's Magic Level). So Magic-linked
  items need a `{spell-name, mimicked-ability, mimicked-level,
  endurance-cost}`-shaped record, structurally different from a
  Transformation-linked sub-ability's plain `{name, level}`.
  `Ova_Fmt.Entities`' domain model needs (at least) these two distinct
  "linked ability content" shapes, not one reused everywhere.

  **Renamed, per the user: `mimics` → `ability` (schema key, `Spell`
  record field, and rendered text).** A spell doesn't *mimic* (copy or
  imitate) another Ability — it grants access, through Magic instead
  of buying it directly, to an Ability the caster already has; it
  literally *is* that Ability, just reached a different way. Every
  mention of `mimics` above is the historical term used while this was
  being worked out — current schema/code/rendering all say `ability`
  now. Changed: `Ova_Fmt.Entities.Spell.Mimics` → `.Ability`,
  `Load_Spell`'s `"mimics"` YAML key → `"ability"`,
  `Format_Terse.Format_Spell_Line`'s rendered `"(mimics X +N; ...)"` →
  `"(X +N; ...)"` (dropping the connecting word entirely, per the
  user). Updated `test-data/sample-pcs/Auren.yaml` and `test-data/Unsorted.yaml`
  (the only two fixtures using `spells:`), including Auren.yaml's
  header comment. Verified: builds clean (`Ability` as a `Spell`
  record component doesn't collide with the `Ability` *type* also
  declared in this package — Ada component names have their own
  scope); a pre-change/post-change binary diff shows only the expected
  wording change in both files' Spells line, nothing else.
- ~~**Vehicle (Mecha) may need its own nested `combat` sub-block**~~
  Resolved and implemented. Read the actual rulebook text before
  designing anything (`ova-rulebook.txt` ~2820-2833, "Vehicle
  (Mecha)"), rather than assuming from the Companion analogy alone:
  Vehicle is an Ability that lets you "build" its own Abilities/
  Weaknesses "much as you would a character," they're **not
  necessarily cumulative** with the pilot's own, and it has its own
  separate Health/Endurance (both default 40) — one rules nuance
  found along the way that's GM-adjudication, not data (unlike a
  character, a vehicle's Endurance-draining effects can never spill
  into Health once Endurance runs out — "no longer linked"). Net
  result: **Vehicle needs nothing new at all** — it's structurally
  identical to what Companion already provides.

  So the real question was just how `Ability` attaches one, given it
  already had a `Companion : Companion_Access` field hardcoded to
  that one concept. Per the user: generalized rather than adding a
  parallel field. `Companion_Record`/`Companion_Access` renamed to
  `Sub_Entity_Record`/`Sub_Entity_Access` (gained a `Label` field —
  "Companion" or "Vehicle" — used only so `Format_Terse` can print the
  right heading); `Ability.Companion` renamed to `Ability.Sub_Entity`;
  `Load_Companion` renamed to `Load_Sub_Entity (N, Label)`;
  `Load_Ability` now checks both `companion:` and `vehicle:` keys
  (mutually exclusive in practice) and calls it with the matching
  Label. `Print_Linked_Section` prints `**<Label>: <name>**` generically
  instead of a hardcoded `**Companion: ...**`.

  Added `test-data/Vehicle.yaml` (synthetic, since no worked example
  exists anywhere to transcribe from): a pilot with a Vehicle Ability
  granting a full nested sub-entity (its own Abilities/Weaknesses/
  combat block). Verified: renders `**Vehicle: Thunderhawk**` correctly
  through the same linked-content machinery Companion already uses; a
  pre-change/post-change binary diff across every other
  `test-data/**/*.yaml` fixture (Karis's Arasuni, Yuu's Fenrir included)
  is byte-identical, confirming the rename touched nothing observable.
- ~~**Which output formats are actually wanted**~~: §7/§8 cover terse,
  HTML-in-reST, groff-in-reST (`hd` tables), and Lout. **Confirmed, per
  the user: an h-m-m outline backend is also wanted** (no OVA attempt
  exists yet, unlike BESM, where `besm2_fmt.Format_Hmm` is the
  reference to follow). Now sequenced into §9's build order too, per
  the user: right after the HTML-in-reST backend (step 4, ahead of
  groff-in-reST/Lout) — see §9 for why. Still needs its own design
  pass against OVA's specific nesting shapes (Transformation/
  Companion/Magic-spell linked content, Perks/Flaws, paired Defense)
  the way terse's own outline got, once its turn in the build order
  comes up.
- **groff version/`hd` support** (§7): the `hd` table macros are
  reportedly not well supported in groff ~1.24 but are supported in
  1.23, which is what's actually installed here — confirm the
  installed version and re-verify `hd`'s nested-table (and color)
  support directly before committing real implementation time to the
  groff-in-reST backend.
- **`tbl` column/row spanning as a fallback**: floated in §7 as a
  "maybe something could be done" alternative to `hd` if `hd` support
  turns out to be inadequate — not investigated, likely inferior to
  real nesting, but worth a quick sanity check before ruling it out
  entirely if `hd` doesn't pan out.
- **Other files under `~/Reference/RPG/OVA/`** not yet reviewed
  (`OVA-Combat.odt`/`.pdf`, `OVA-ConversionGuide.pdf`, the various
  character-sheet variants, `OVA-CharacterSheet.zip`) — check these
  before finalizing the field set in §5, in case they show a different
  or more complete layout than the one fillable-PDF sheet reviewed so
  far.
- ~~**A Companion/Vehicle sub-entity should be able to opt into
  NPC-Fragment-style rendering**~~ Resolved and implemented, same
  session it was raised. `fragment: true` on the `companion:`/
  `vehicle:` block itself (`Entities.Sub_Entity_Record.Is_Fragment`,
  mirroring `Entity.Is_Fragment`'s own key/field exactly) lets a simple
  sub-entity (Fukiko's Azyrus is the first real user, retrofitted with
  the flag this session: a short Abilities/Weaknesses list, no
  `combat:` block) render flat instead of every backend's normal full
  treatment.

  Answers to the open design questions from when this was first
  raised: **yes, a fragment-style sub-entity can still carry a
  `combat:` block** — a top-level `Entity.Is_Fragment` already proves
  this is fine (`Process_Entity`'s Fragment branch calls the exact same
  `Print_Combat_And_Attacks`/`Print_Combat` every non-Fragment entity
  uses), so the sub-entity version does the same, unconditionally.
  **The flat rendering has no separate name/header line at all** —
  unlike a top-level Fragment's own bare-name fallback (there's no
  Background prose for a sub-entity to embed a bolded name in the way
  the rulebook's own Fragments do), a fragment-style sub-entity relies
  entirely on the granting Ability's own line already naming it via
  `detail:` (e.g. "Companion +2 (Azyrus)"); what follows is just one
  compact "Attributes: ..." line (comma-joined Abilities, semicolon,
  comma-joined Weaknesses — new `Format_Fragment_Sub_Item_Line`/
  `Join_Fragment_Sub_Items` in `Format_Common`, mirroring
  `Format_Fragment_Ability_Line`'s own "Name Level (detail)" reordering
  but for `Sub_Item`) then Combat/Attacks.

  Terse/Gemtext (`Format_Common.Print_Linked_Section`) and h-m-m
  (`Format_Hmm`'s own mirrored version, since its indentation-tracked
  structure needs `Header_Depth` threaded through every line) both
  just skip the normal `Section_Header`/nested-content branch and
  print the compact shape directly. Html_In_Rst and Groff_In_Rst needed
  genuinely different treatments because of how differently the two
  already lay out a (non-fragment) sub-entity's content: Html_In_Rst
  nests it *inside* the granting Ability's own `<td>` cell, so a
  fragment-style one still has to stay inside that cell as literal
  (flatter, escaped) HTML — one `<p>Attributes: ...</p>` instead of two
  nested `<table>`s, Combat left as its existing compact table (no
  print-pagination concern in HTML the way `hd` has, so no correctness
  reason to flatten that part too). Groff_In_Rst, since step 6 already
  moved sub-entities out to their own separate top-level section, can
  go all the way to genuinely format-invariant rendering: it closes its
  current `.. raw:: ms` block, calls a new shared `Format_Common.
  Print_Sub_Entity_Fragment_Style` (plain reST, no `hd` markup at all —
  the same content Terse/Gemtext print), then reopens a fresh raw block
  afterward if more raw content follows (a later, non-fragment
  sub-entity, say) — confirmed rendering correctly through the real
  `pandoc -r rst -w ms --template=tkb` pipeline, not just bare groff.

  Verified: pre/post binary diff of every format across every
  `test-data/**/*.yaml` fixture *except* Fukiko (the one file that gained
  `fragment: true`) is byte-identical; Fukiko's own output was
  hand-checked in each format (including a rendered groff PDF and a
  Python `html.parser` pass on the HTML-in-reST output) to confirm
  Azyrus renders flat and Karis/Arasuni's own (non-fragment, still
  full-treatment) rendering is completely unaffected.

## Decisions already made

- Project directory: `~/Repos/RPG/Tools/ova_fmt` (git initialized,
  `origin` set to `git@github.com:tkurtbond/ova_fmt.git`, `main`
  tracking `origin/main`).
- Program name: **ova_fmt** (following `besm2_fmt`'s naming pattern —
  not yet confirmed with the user beyond the directory name itself).
- This is a from-scratch design-and-port effort, not a mechanical
  translation — the Scheme source is an intentionally-unfinished
  skeleton (its own `README.rst`: "nothing in this repository works"),
  so `ova-rst.scm` is a *shape* reference (CLI option table, the
  general `process-file`/dispatch pattern, the terse-format prose
  sketch in its header comment) rather than a behavior oracle the way
  `besm2-rst.scm` was for `besm2_fmt`.
- **Nested-table output strategy (§7), given directly by the user:**
  reST's table syntax is unusable for OVA — no default reST
  grid-table format, unlike BESM. Default/primary text output is
  terse/prose-style. HTML output uses hand-written raw `<table>`
  markup (nests natively) inside `.. raw:: html` blocks. groff/`ms`
  output uses `hd` macros, not `tbl` (`tbl` can't nest tables), still
  via a `.. raw:: ms` block processed through Pandoc. Lout output is a
  separate, directly-generated (non-Pandoc) backend, since Pandoc has
  no Lout writer — `Fukiko-experiment.lout` is a confirmed working
  proof-of-concept for Lout's native nested-table support to model
  that backend on.
- **Build order (§9), given directly by the user:** (1) YAML test data
  for all twelve rulebook sample characters first, generalizing
  `Fukiko.yaml`'s schema to cover companion and transformation-
  description callouts seen on other characters' sheets; (2) terse
  backend; (3) HTML-in-reST backend; (4) groff-in-reST (`hd` table)
  backend; (5) direct-to-Lout backend last, using
  `~/Reference/Document-Tools/lout/`'s docs alongside
  `Fukiko-experiment.lout`.
- **Perks/Flaws are a general Ability modifier, not attack-specific**
  (correction, §4): attachable to any Ability — top-level, linked
  sub-ability, or Attack-typed combat entry alike — so the domain
  model represents them uniformly rather than per attachment point.
- **`combat.defense`'s slash-paired values (e.g. `4/5`) render
  verbatim** (§2.2, refined by the user): don't split or derive them
  at render time; instead add a short explanatory note on the
  Barrier Ability's own list entry, since that's the Ability that
  produces the second Defense option.
- **Terse output is reST** (§2.3), not Markdown — the user's Karis
  mockup was Markdown but written for an unrelated purpose and
  clarified as structure-only, not a literal or format-choice
  reference; a new `summary` field (§4) holds the author-written
  one-line synopsis under the header.
- **Companion (and likely Vehicle) can be a full nested sub-entity**
  (§2.3): confirmed from the primary rulebook (Karis's Arasuni has his
  own complete Abilities/Weaknesses/Attacks/Combat-stats block), not
  just the simpler prose-summary shape (Fukiko's Azyrus) — schema
  needs to support both.
- **No verbatim book prose in `background`/`personality`, confirmed by
  the user** (§9 step 1): this repo is believed public right now, so
  every sample-character transcription keeps those two fields as
  short original paraphrases, never the book's actual sentences —
  settled policy, not a per-file judgment call. Game-mechanical data,
  fluff, `tagline`, and short attack captions are still transcribed
  faithfully.
- **Markdown backend's entity-title heading is a flat `# Title` for
  every entity** (§9 step 8, asked directly of the user, offered
  alongside a heading-depth-nesting alternative and a literal-Setext
  alternative): matches Gemtext's own already-settled choice and for
  the same reason — no per-entity underline character to swap the way
  reST's `Underliner`/`Subunderliner` do, only a heading depth, and
  flat was preferred over nesting subsequent entities under `##`.
- **Keys for the character generator, in ova_fmt too** (§9 step 9,
  decided by the user, 2026-10-09), Ada first, then ova_fmt_po; and
  how they print, as proposed and accepted: `player` beside the name,
  `appearance`/`other-notes` as text sections, combat `notes` after
  the combat stats, `portrait` as an image in `-H` only, the new
  options as the existing ones, and an overridden number with `*`
  after it (`\*` in reST and Markdown). Not printing `telekinesis`
  and `transformed` was this port's choice, the proposal not having
  covered them: easy to revisit.
- **The rulebook's 12 Sample Characters live in `test-data/sample-pcs/`**
  (asked for by the user, 2026-10-10), the synthetic fixtures and
  `Fragment.yaml` (an NPC Fragment, not a Sample Character) directly
  in `test-data/`. The `GNUmakefile` collects both directories into
  `TEST_DATA` and finds inputs through `vpath`, so `build/` stays
  flat and its file names are unchanged. Paths elsewhere in this file
  were updated to match: `test-data/sample-pcs/*.yaml` for the twelve,
  `test-data/**/*.yaml` for every fixture.
- **The Sample NPCs chapter is transcribed** (asked for by the user,
  2026-10-10): its 8 Sample NPCs in `test-data/sample-npcs/`, its 22
  NPC Fragments one per file in `test-data/sample-npc-fragments/
  <subsection>/` (the subsection name with spaces replaced by dashes,
  so `High-Tech-Marvels-&-Outer-Space` has an `&`, which the
  `GNUmakefile`'s recipes now quote). Decided by the user: every
  description and background is a short original paraphrase, the
  fragments' included (`Fragment.yaml`'s near-verbatim two predate
  this); Acacia's demons and Zurkrieg's Men in Black are `fragment:
  true` entities after their master in the same file; and two new
  keys, `npc-type` (Heroic/Secondary, from "Attacks & Combat Stats
  (HEROIC)") and `character-hooks` (a paraphrase of each NPC's
  Character Hooks paragraph); how they print is the next entry. Also
  found:
  an Ability's `endurance` (Barrier's "5 End", the Venomous Killer's
  Attack) is loaded but no backend prints it; and the Dragon's one
  Attack Ability carries two attacks, which perks:/flaws: can't
  express, so its parenthetical is kept whole as the `detail`.
- **How `npc-type` and `character-hooks` print** (designed with the
  user from hand-edited mock-ups run through the real pipelines,
  2026-10-10). `npc-type` takes Heroic, Secondary, or Extra (the
  rulebook's three, p. 133), matched case-insensitively; anything
  else is a load error, like an unknown `overrides:` name. It prints
  where the book puts it, by the stats: leading the stats line in
  Terse/Gemtext/Markdown/h-m-m (`**NPC Type:** Secondary |
  **Health:** ...`); in Html_In_Rst's caption, `Combat (Secondary)`
  (and so `Combat (Secondary) — Attacks`); in Groff_In_Rst's box,
  the book's own `Attacks & Combat Stats (SECONDARY)`, in place of
  the name (a Companion/Vehicle box keeps its own name); and on a
  Fragment, the book's own `**Attributes (Secondary):**` (Acacia's
  demons). `character-hooks` is a "Character Hooks" section after
  Background/Appearance/Personality, as on the NPCs' pages (on a
  Fragment, after its Attributes line). Verified: outputs change only
  for the 8 Sample NPCs; every other fixture is byte-identical in
  every format.
- **Groff_In_Rst: prose no longer trails the tables** (found while
  mocking up the above, fixed first and separately, commit
  `7f50d3b`): Pandoc ends a paragraph without a break, so the
  paragraph's last output line printed after hd's tables. A `.br`
  at the top of each raw ms block flushes it.
- **How an Ability's (or Sub_Item's) `endurance` prints** (designed
  with the user from a mock-up of Ai's sheet run through the real
  pipelines, 2026-10-10; it was loaded but printed nowhere): inside
  the existing modifiers bracket, after the Perks/Flaws, worded like
  a Spell's -- `Barrier +3 [Perks: No Gesture; 5 Endurance]`,
  `Telekinesis +2 [5* Endurance]` -- since the book puts it in the
  same parenthetical as the Perks ("Barrier (no gesture; 5 end)").
  One change in Format_Modifiers_Bracket covers every backend;
  Html_In_Rst's column header became "Perks/Flaws/Endurance". Fixed
  alongside it, per the user: Html_In_Rst dropped an Ability's or
  Sub_Item's `note` (Ai's Barrier "provides an alternate Defense
  Roll..."), which every other backend prints; it now follows the
  bracket in the same cell. Verified: only the five fixtures with an
  `endurance` change outside Html_In_Rst; in Html_In_Rst, beyond
  those, only the header and the notes.
- **No more unhandled exceptions; matching ova_fmt_po's error reports**
  (from ova_fmt_po's PLAN.md "Differences from the Ada version", asked
  for by the user, 2026-10-10). YAML of the wrong shape (a list key
  that isn't a sequence, a list item or entity that isn't a mapping, a
  `combat:`/`fluff:`/`options:`/`companion:`/`vehicle:` that isn't a
  mapping) failed alibfyaml's preconditions (`ASSERTION_ERROR`); it is
  now `Ova_Fmt.Entities.Shape_Error`, `ova_fmt: error processing
  FILE: PATH: not a sequence` (or `not a mapping`), and the run goes
  on. So does it after an input file that can't be opened (`FILE:
  REASON`, GNAT's words), which ended the run with `NAME_ERROR`. An
  `-o` that can't be created is `ova_fmt: can't create PATH: REASON`,
  a write error (`-o /dev/full`, or standard output) `ova_fmt: error
  writing output: REASON`, status 1. Standard input is `(stdin)` in
  libfyaml's messages too (`Open_String`'s `Name`; it was
  `(string-in-memory)`), as in polibfyaml and olibfyaml, changed with
  it. Command-line errors were reported twice, by Arg_Parser and again
  by `ova_fmt_main`; now only by Arg_Parser, `-u`/`-U`'s message
  reworded to follow its prefix (`Invalid value for option
  -u/--underliner: takes exactly one character, got "xx"`). And
  Abilities/Weaknesses/sub-items/Perks/Flaws are sorted with a stable
  insertion sort (`Stable_Sort`), as the port does: `Generic_Sorting`
  needn't be stable. Verified: every fixture's output in every format
  is byte-identical, as are the port's error and edge fixtures but for
  the four `bad-shape-*`; the port's 400 golden cases (10 new) pass.
- **Up to three Defense values** (asked for by the user, 2026-10-10,
  so that ova_cg_po can save Incorporeal Form's alternate Defense
  Roll, p. 55, alongside Barrier's, p. 51; Nazo's and Acacia's books
  have it). `defense` stays a free string, now of up to three values,
  `D[/A[/A]]`, positional and generic: ova_fmt doesn't know which
  Ability gives which (the generator writes Barrier's first, then
  Incorporeal Form's, only those the character has). Four or more is
  a load error, `"2/3/4/5" has more than three values`. The override
  keys are `defense`, `defense-2`, `defense-3` (`Override_Key`'s
  `Barrier` became `Defense_2`, and `Defense_3` was added); `barrier`
  is still accepted as `defense-2`, for files written before.
  `Defense_Text` marks each value by its slot. Sheet.yaml says
  `defense-2` now; two new synthetic fixtures, `Defenses.yaml`
  (Barrier and Incorporeal Form, `2/4/6`, the third overridden) and
  `Wisp.yaml` (Incorporeal Form alone, `2/6`, overridden with the old
  `barrier` name), cover the rest. In the generator, a file giving
  one value where the rules give more means the best, with no notice
  (the Sample NPCs print only that), saved back as one value.
  Verified: every existing fixture's output in every format is
  byte-identical (539 runs).
- **`count`, one stat block for a group** (asked for by the user,
  2026-11-02, for the holdout guards of Lost-Worlds' `001-cast.yaml`,
  which a `sed` in that repo's makefile had been rewording). An
  optional entity key, read by `Load_Count`: an integer, default 1;
  under 1 is a recorded error, `"0" is not 1 or more`, and something
  that isn't an integer fails as any optional integer does. `Count` has
  no `Has_` flag: `count: 1` means the same as no `count`. Only the
  inline format shows it, since every other format is a sheet and a
  sheet describes one. Over 1 the lead is `**Guards** (three Extras).`,
  or `**Crowd** (three).` with no NPC type; a Fragment that leads with
  its background adds `Extra NPCs (three).` or `(three).`; and TV is
  `TV 1 each.` (`TV 1\* each.` overridden). A linked Companion's TV has
  no "each". Counts are words up to twelve, then digits; the plural is
  an `s`, except `Secondaries`. Synthetic fixture: `Group.yaml`.
- **Error lines are gcc style, the file named once** (the user,
  2026-11-12). alibfyaml `717b71e` put `LINE:COLUMN: PATH: ` at the
  front of a Missing_Key/Data_Error message, which a value of the
  wrong kind in an optional field raises through to `Process_One`;
  that location is kept, and the error is put as a recorded one is,
  `FILE:3:13: error: /0/fragment: not a valid boolean: "maybe"`, with
  no `ova_fmt: error processing FILE: ` before it. A Parse_Error that
  names the file (a YAML syntax error) is put the same way, as it
  comes, `FILE:4:1: error: flow sequence without a closing bracket`,
  without the blank line its two final line feeds made. Other errors
  keep `ova_fmt: error processing FILE: `. ova_fmt_po does the same.
- **`-S` sets `--` as an em dash** (the user, 2026-11-12: the YAML's
  `--` printed as two hyphens). `Format_Sheet.Dashes` turns each `--`
  into U+2014 in UTF-8, which groff reads through `preconv`
  (`ova_sheet.sh`'s `-k`) and the widths tables already measure. It is
  done where text comes in (`Add`, `Put_Text`, and `Put_Line_In`,
  `Fit_Block`, `Put_Block` and `Put_Clause` before they measure),
  because lines are broken with the dash's own width, and the
  procedures that compare a break with the text's length and slice it
  must use the dashed text: dashing only in `Add` raised
  Constraint_Error. Only `-S` changed; `-X` (the form fields) and the
  other formats still give `--` as written.
