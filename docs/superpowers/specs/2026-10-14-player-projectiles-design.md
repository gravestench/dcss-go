# Player projectiles in the Lua-first port

## Intent and boundary

Make player firing and throwing a complete, readable gameplay path rather
than another collection of per-monster or per-item Go handlers. The active
Dungeon slice must let a player aim, fire a wielded launcher, throw a carried
missile, see the projectile resolve, recover surviving ammunition, gain
practice and XP, and save or restore the resulting state. The eventual full
port will reuse this same path for later species, jobs, monsters, and floors.

The source reference is DCSS `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.
The core source anchors are `throw.cc`, `ranged-attack.cc`, `attack.cc`,
`player-act.cc`, `item-prop.cc`, `beam.cc`, and `quiver.cc`. This slice adds no
Go rule switch over launcher or missile IDs.

## Ownership

The terminal owns only input state: item choice, a target cursor, cancellation,
and rendering the targeting prompt. The game command carries a target cell
and optional item entity. Lua policy checks the selected item, equipped
launcher, body-size restrictions, range, and target legality without spending
time on rejection. Lua decides action cost and resolves attacks through one
ordered Akara system. The Go kernel may expose a reusable grid ray that lists
traversed cells and collision points; it does not interpret item or monster
types. Item stacks, positions, equipment, health, and practice remain Akara
state. No mutable projectile rule state lives in a Lua module global.

The two player actions are source-shaped: firing a launcher uses its synthetic
missile and does not consume an inventory ammo stack; throwing uses one item
from an inventory stack. The item catalog already records launcher `ammo_id`
and missile properties. The Lua path handles the active catalog's launcher
and throwable missile families, including dart and net effects and applicable
brands, rather than dispatching on a small list of named monsters. A rule
module may distinguish missile effect families, but the system registration
and command shape remain stable as content grows.

## Turn flow

1. The player chooses `f` for a wielded launcher or `F` for a carried missile,
   then selects a target in the DCSS-style aim view. Escape cancels without
   spending time. An invalid item or target explains why it cannot be used.
2. The command policy validates the selection and builds one ranged intent.
   Timing policy computes source-shaped throw or launcher delay, including
   skill, shield, armour, speed brand, and haste effects where applicable.
3. The projectile system walks the grid ray, applies the first eligible
   collision, resolves shield, evasion, AC, base damage, brand and missile
   effects in source order, and emits the player's action and result messages.
4. A thrown stack loses one item only after the action commits. Surviving
   a miss continues through the ray, and an ordinary hit or block stops it.
   The ray normally continues beyond the aimed cell to its range or a wall;
   ammunition lands in an eligible cell or merges with a matching stack;
   destruction, return, and special projectile outcomes use their source
   rules. Kills signal the existing XP and corpse systems, and successful
   use signals the existing practice system.
5. Save and restore preserve all authoritative item and status state. A
   canceled or failed action leaves the inventory, RNG, and turn clock
   unchanged where the existing runtime transaction can guarantee it.

## Error and mod behavior

The embedded Lua files are the only implementation of projectile gameplay.
The same-path overlay can replace a projectile policy or effect file. Missing
catalog records, invalid component shapes, and impossible item ownership
return contextual errors rather than silently using a fallback Go rule.
Content and policy files remain separate so a modder can find the rule from
the registration and follow one call chain.

## Verification

Use behavior tests for launcher fire, thrown stacks and landing, misses and
blocks, kill and practice signals, target cancellation, invalid selections,
mod overrides, and save continuation. Source-specific tests cover timing,
roll order, and unusual missile effects. Run the full Go suite, vet, build,
style check, and generated-content check after the integrated slice, then
review the branch and merge to local `main`.
