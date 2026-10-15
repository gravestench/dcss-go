# Lua-authoritative runtime content

## Purpose

The game loads registered Lua species and jobs, then projects them back into
the Go `content.Catalog` used by startup and save code. The Go catalog also
loads committed JSON import artifacts at every launch. That duplicates the
runtime source of truth and makes a new Lua definition depend on a Go type.
Remove that runtime mirror in one pass. Keep the Go import package as a
developer tool for deliberate upstream refreshes.

## Boundary

Lua registration owns game definitions, validation, selection, menu content,
and source-specific presentation. Go owns the Lua VM, immutable file access,
terminal drawing, Akara state, and save encoding. Go may receive a small
screen model from Lua, but it must not build or validate a second catalog of
DCSS species, jobs, or presentation rules. There is no legacy constructor or
catalog adapter left beside the new path.

The bundled `data/*.lua` and `content/{species,jobs}/*.lua` files remain
checked in. Normal launch, new game, and restore do not read the generated
JSON artifacts. The import commands and their JSON fixtures remain for
source-traced refreshes and importer tests.

## Registration and validation

`register.species` and `register.job` store copied Lua tables under unique
IDs. They enforce registration shape and ownership at the generic runtime
boundary; Lua bootstrap policy checks DCSS-specific required fields,
cross-references, selectable choices, and presentation groups. Additional
mod fields are allowed and remain visible to Lua policy. Duplicate IDs and
invalid table shapes fail during boot with a file path and definition ID.

Character choice and gameplay read the same registered tables. The menu
policy returns ordered species and job groups, descriptions, restriction
labels, and supported-start flags from those tables and committed Lua
presentation data. A same-path mod override changes the menu and gameplay
together. An override may set `description` on a species or job to replace
the imported menu prose. Go decodes only the finite screen fields it must draw.

## Game and save flow

New game and restore create a Lua runtime directly from the effective ruleset.
Their public constructors take the requested character IDs and ruleset, not
a Go `content.Catalog`. Test fixture scenarios choose their IDs explicitly.
The ruleset hash and manifest already identify exact effective Lua bytes;
remove the redundant `SourceRevision` save header. Bump the Go save version
because its schema changes. Keep deterministic RNG and ECS save continuation.
The user's current untracked save is not edited or migrated silently.

## Verification

Exercise startup, character choice, new game, save/restore, same-path
overrides, a mod-added selectable definition, malformed definitions, and
exact ruleset mismatch. Run the full Go suite, vet, build, style check,
catalog regeneration check, and whole-branch review after this integrated
category. Do not require a passing build during intermediate edits.
