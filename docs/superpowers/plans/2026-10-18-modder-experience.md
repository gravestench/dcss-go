# Lua readability and mod creation implementation plan

**Spec:** `docs/superpowers/specs/2026-10-18-modder-experience-design.md`

**Working checkout:** `/Users/dylanknuth/src/dcrawl-go`

**Commit boundary:** Keep this broad repository-wide modder experience change
in one category commit after the monster hex family is merged.

## 1. Inventory and preserve meaning

- Inventory all Lua by generated content, handwritten content, policy,
  systems, schemas, data, constants, IDs, vault hooks, and tests.
- Record the 2,171 numbered paths and check for collisions after removing
  prefixes. Identify where discovery order is observable in gameplay.
- Add an explicit order contract for source catalogs and regression tests
  before changing paths. Additive mod definitions follow source entries.

## 2. Descriptive paths and provenance

- Rename committed Lua, adjust exact-path tests and current docs, and
  remove original C++ line numbers from Lua comments while keeping useful
  source filenames.
- Remove the no-longer-needed C++ import commands, Lua regenerators, and
  their tool-specific tests. Audit intermediate JSON for consumers before
  removal. Keep live-code validation tools such as style checks.
- Verify representative ordered catalogs and sparse overlays.

## 3. Explain the Lua tree

- Handwritten modules: add file-level purpose/ownership/loading comments,
  then explain non-obvious decisions, source-specific formulas, schedule
  edges, saved state, and cross-module flow in place. Review by family.
- Imported definitions: add useful category-specific explanatory comments
  next to field groups. The committed Lua is maintained directly.
- Test Lua: describe fixtures and the behavior each assertion protects.
- Audit all files for a meaningful opening explanation; review a sample from
  every family for signal and accurate DCSS relationships.

## 4. Guide and scaffolder

- Add a root README with launch and modding quick start. Correct stale
  numbered paths and expand `docs/modding.md` with policy/system/component
  decision rules, all active content categories, vaults, testing, and saves.
- Build `cmd/dcrawl-mod`: explicit noninteractive flags and concise prompts
  for missing fields in a terminal. Keep Lua templates as files, never Go
  strings. Validate mod root, slugs, and IDs; preview paths; refuse overwrite.
- Add templates for all current content categories plus component, system,
  policy, effects, and `.des` vault. Named methods and multiline tables are
  the default style. Test representative generated mods through `modfs.Load`
  and the Lua runtime.

## 5. Verify and integrate

- Run Lua tests, full Go test, build, vet, style,
  and diff checks at this category boundary. Review the full diff for stale
  paths, unstable catalog traversal, misleading comments, and scaffold clobbering.
- Commit once and fast-forward local `main`. Continue gameplay domains from
  the updated Lua layout.
