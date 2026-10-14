# Playable Hill Orc Fighter

## Goal

Make Hill Orc the second playable species in the generated Dungeon run. A
player can select Hill Orc and Fighter, choose a legal Fighter weapon, play,
advance, save, restore, and see the correct species in the terminal. Human
Fighter behavior stays unchanged. Other species and jobs remain visible with
the existing unavailable response.

## Source rules

The pinned source is `crawl-ref/source` at
`e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.

- `skills.cc:224-275` assigns the Human cost of each job skill plus one point,
  then finds the species-adjusted starting level using a strict `>` comparison
  through level eight. The Fighter grants are in `jobs.cc:100-125`.
- `player.cc:3892-3934` gives a Fighter without magic skills or mutations
  `min(23, XL) + species MP modifier`. Hill Orc has no starting or level-up
  mutations, so the existing baseline MP rule applies.
- The committed species and job catalogs provide Hill Orc's base stats,
  +1 HP modifier, aptitude values, XP factor, and periodic Strength gain.
  These artifacts are runtime inputs; a C++ import is not part of the build.

## Design

The terminal passes the selected species and job to the game constructor.
The player ECS identity component remains authoritative for gameplay and
save/restore. Fixture constructors keep their explicit Human/Fighter fixture
choice; the live constructor accepts a `PlayerDef` for the selected character.
One internal scenario builder handles both.

`BuildStartProfile` supports Human and Hill Orc Fighters. Starting skills use
Human-priced points and the source reassessment algorithm. HP and MP are
projected from the chosen species. Save validation reconstructs the chosen
profile from the saved player identity and accepts only supported starts.
Equipment fit, HUD species label, weapon aptitude display, and welcome text
use the selected species. The existing Human-only barding guard becomes a
rule for the two supported humanoid species.

## Verification

Source-value tests cover Hill Orc attributes, skills, HP/MP, and a legal
weapon. A terminal path test selects Hill Orc through the menu and checks the
resulting ECS-backed view. A save/restore test checks identity and vitals.
Run the full Go suite, vet, build, style gate, and diff check at the category
boundary.
