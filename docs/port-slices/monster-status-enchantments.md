# Monster status and enchantment spell slice

## Purpose

Nine non-ray monster spells now change an actor's condition through Lua:
Abjuration, Berserk Other, Black Mark, Brain Feed, Corrupting Pulse, Dream
Dust, Flay, Injury Bond, and Silence. They remain Dungeon Crawl spells with
source-shaped selection, duration, and effects. Each named spell file owns
its cast plan and resolution, while the actor policy that owns the affected
state handles later actions.

## Ownership

- Existing summon, frenzy, stat-loss, mutation, sleep, and health rules own
  effects for which they already hold durable state.
- Black Mark, Flay, Injury Bond, and monster Silence have focused Akara
  components. Lua systems age the conditions on actor actions, so save and
  restore preserves both the remaining time and referenced actors.
- Flay records the HP actually removed by the health owner. Its recovery
  heals at most that amount and cannot exceed the victim's missing HP.
- Injury Bond diverts damage before the victim loses HP, provided its saved
  protector is still alive and allied. A dead protector cannot absorb it.
- `policy/world/silence.lua` answers whether any player or monster silence
  aura covers a cell. Spells, scrolls, verbal abilities, and noise use that
  shared field, including overlapping auras.

The ordinary monster spellbook dispatcher finds the individual spell files.
The Go engine has no spell-specific behavior switch for this category.

## Verification

The Lua rule tests exercise cast eligibility, targeting, condition effects,
expiry, and owner interactions. A live game test casts Flay and Silence
through the monster spellbook, saves mid-condition, restores, and checks
deterministic continuation.
