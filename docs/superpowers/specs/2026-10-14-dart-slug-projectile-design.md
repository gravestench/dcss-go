# Dart slug projectile slice

Source: pinned `crawl-ref/source` at `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.

## Scope

Add the generated Dungeon's dart slug to the supported natural-monster roster.
Keep the fixed fixture unchanged. Its ECS actor owns position, health, action
energy, combat state, and AI. The committed monster, spell, spellbook, and
population catalogs provide its definition; no C++ files are read at runtime.

The decision system reads the slug's one-slot `MST_DART_SLUG` book. Its natural
`SPELL_SLUG_DART` frequency is 60, compared inclusively with a 0..199 roll.
The player must be visible within radius seven and reachable by a clear shot;
terrain and intervening actors stop the projectile. If the spell is not chosen,
the slug uses its ordinary seek, bite, or wait action.

The spell system validates the selected book and live ECS state, then resolves
the beam against the player's current equipment and attributes. At HD 1,
`zap-data.h` gives 14 to hit and 2d3 physical damage. A blockable beam rolls
shield before evasion; an unblocked hit rolls damage then ordinary AC without
melee GDR. The spell costs the catalog's spell action energy. All draws use the
saved `monster_spell` RNG stream. Combat messages distinguish block, miss, and
hit. Saves preserve health, shield blocks, actor state, and RNG continuation.

`mon-util.cc` does not halve XP for a slow monster that has a spellbook. Teach
the existing XP rule that distinction, while preserving non-caster values.

## Limits

This slice handles the slug's single targeted projectile. Other beam flavours,
reflection, lighting, species effects, and spellbooks remain separate domains.
The initial ray follows cell centres and stops on opaque terrain or actors;
the broader source tracer's aiming variants require a later beam domain.

## Verification

Test source profile/roster, XP, deterministic cast selection, clear and blocked
paths, shield/miss/hit phases, AC, energy, and save continuation. Run the full
Go test, vet, build, and style gates once at the category boundary.
