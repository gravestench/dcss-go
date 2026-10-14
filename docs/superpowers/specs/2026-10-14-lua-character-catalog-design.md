# Lua character catalog and choice policy design

## Purpose and scope

The first Lua content migration moves every pinned species and job definition
(43 species, including 27 selectable; 31 jobs, including 25 selectable) out of
the runtime JSON authority and into committed, embedded `.lua` modules. A mod
changes a definition by replacing its file at the same relative path or adds
one by adding a new file. The terminal and game consume the same effective
Lua definitions. Source importers remain developer-run refresh tools; normal
builds and play need no C++ checkout or generator.

This category also moves species/job recommendation and ban policy to Lua. It
does not advertise all 25 jobs as playable yet: many need item use, spells,
religion, or generation behavior that is not implemented. The Lua policy
registers which currently supported starts are playable. Later whole-domain
migrations expand that registration and remove the corresponding Go start
rule code. Definitions for all species/jobs are available now so those future
rules do not require a second catalog migration.

## Ownership

`internal/modfs/builtin/content/species/*.lua` and `content/jobs/*.lua`
contain one source-traced definition per file. `internal/modfs/builtin/policy/
character_choice.lua` owns bans, recommendations, and supported-start
eligibility. The embedded entrypoint loads `policy/` after content. Lua
registrations are the authoritative runtime source. Go's `content.Catalog`
remains a read-only typed projection for existing engine and terminal code;
it is rebuilt from the effective Lua definitions before a session uses it.
The old JSON files remain committed as importer intermediates and for source
comparison, but live character choices read the Lua projection.

`internal/script` validates Lua tables, rejects duplicate IDs, records
registrations in deterministic path order, and exposes a read-only projection.
`content.Catalog.WithCharacterDefinitions` validates and replaces its species
and job maps as one operation. The game and pregame client use this one
projection; neither applies a second Go policy over Lua decisions. The Lua
policy receives read-only definition tables and returns a simple restriction
and a supported-start flag. No mod script receives raw Akara pointers.

## Generated files

A checked-in developer command converts the pinned `species.json` and
`jobs.json` artifacts to Lua table files. Every field survives, including
source path, aptitude maps, mutations, skills, recommendations, equipment,
and selectability. The generator writes deterministic file names and key
order, escapes strings, and records the pinned revision at the top of each
module. It only runs for intentional refreshes. Generated Lua is the runtime
authority; JSON is never loaded to repair a missing Lua definition.

## Rules and behavior

Definitions must have unique stable IDs. Override a definition by replacing
its exact path; a second file with the same ID is an error. A malformed or
incomplete definition fails startup with path and ID context. The policy
returns `banned`, `restricted`, or `recommended` for selectable pairs, with
source mutation and undead restrictions preserved. It separately reports
whether the pair has a complete playable start in the current engine. The
pregame menu displays all selectable source definitions and marks unsupported
starts unavailable. Mods can change recommendations and bans in Lua, but an
unsupported start cannot become playable until its required runtime
capabilities and start procedure exist.
Added selectable definitions appear on a modded menu page at the terminal's
minimum size. A definition can use `mod.null` for a required field whose
source value is null; omission is a startup error. A policy cannot advertise
an unimplemented start as playable because the engine still enforces the
currently complete start capabilities.

The same ruleset hash continues to identify exact bytes. Save and restore
project the effective definitions before validating player species/job and
before any turn system uses them. A save under altered definitions requires
the existing explicit mismatch policy. Existing tests for the four playable
Fighter species retain their outcomes and RNG draw order.

## Acceptance

- Every source species and job is represented by a separate committed Lua
  file with its source metadata and fields, and no Lua source is inline in Go.
- Replacing Human or Fighter's Lua file changes the in-game catalog and the
  ruleset hash without recompilation; duplicate or malformed IDs fail at
  startup.
- The menu uses Lua-defined restrictions and playable-start policy. Default
  Human/Hill Orc/Deep Elf/Minotaur Fighter starts continue to work; the other
  definitions are visible without claiming their starts work.
- The game and terminal share one effective projection. Exact-match saves
  continue; changed rules require explicit opt-in.
- Full Go test, vet, build, style, and diff checks pass at the category
  boundary, followed by a whole-branch review and one commit.
