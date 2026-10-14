# Source-Traced Spell Catalog for the Go Port

## Goal and source

Import every active tag-34 `spell_type` identity and its `spell_desc` row from pinned C++ revision `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`. The sources are `source/spell-type.h`, `spl-data.h`, `spl-util.cc` (the `removed_spells` set), `spl-util.h` (`spschool`), and `spl-cast.h` (`spflag`), with `tag-version.h` for the selected branch. The table has normal descriptor blocks and tag-34 `AXED_SPELL` rows. `SPELL_FIRST_SPELL` is an enum alias, not a distinct identity. A preliminary source scan finds 403 concrete identities and 86 axed rows; the importer must prove the exact counts through parsing and coverage checks rather than silently accepting this estimate.

## Artifact and importer

Add a developer-run `cmd/importspells` that accepts `-source`, `-out`, and `-check`, following the existing committed-content policy. It uses the narrow tag-34 scanner, records source file hashes and original line numbers, parses enum order into numeric identities, and requires exactly one descriptor for every concrete identity. It marks removed spells using the pinned `removed_spells` set and cross-checks the `AXED_SPELL` rows. The checked-in JSON artifact stores spell ID, numeric ID, display name, status, school IDs, flag IDs, level, power cap, raw min/max range expressions, cast/effect noise, tile ID, and source provenance. Range expressions remain source text where the table uses symbolic constants; gameplay rules can resolve only the expressions they need later. The importer rejects duplicate, missing, unknown, or malformed rows and unsupported field syntax with file/line errors.

## Runtime ownership

`content.Catalog` loads the committed artifact on ordinary startup, validates revision, hashes, exact identity coverage, status, and well-formed fields, and returns defensive copies. `Spell(id)` returns only usable defined spells; `SpellStatus(id)` and `SpellIDs()` expose all identities for menus and later rules. The spell importer never runs during normal build, tests, game start, save, or CI. This slice imports data only; casting, spellbooks, memorization, MP costs, spell failure, targeting, and monster casting remain separate gameplay work.

## Verification

Use synthetic source fixtures to test tag selection, enum alias, multiline school/flag expressions, symbolic ranges, axed rows, missing/duplicate identities, and removal mismatch. Test committed artifact coverage and representative spells against the pinned source. Require byte-identical `-check`, full Go tests, vet, build, and read-only whole-branch review before local-main merge.
