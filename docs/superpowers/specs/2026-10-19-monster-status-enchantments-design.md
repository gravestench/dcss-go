# Monster status and enchantment spells

## Intent and boundary

Port the nine remaining non-ray monster spells whose primary effect is a
condition on an existing actor: Abjuration, Berserk Other, Black Mark, Brain
Feed, Corrupting Pulse, Dream Dust, Flay, Injury Bond, and Silence. This is
one gameplay category because each cast selects an actor or visible group,
changes a durable condition, and then relies on an existing action, damage,
or expiry owner to make that condition meaningful. Their source spellbook
slots are already committed. A live roster may use one of these spells only
when its effect is executable.

Keep one named Lua `plan`/`resolve` module per spell. The modules decide cast
eligibility, target, source roll order, and messages. They must not grow a
shared spell-ID switch. A small shared helper may enumerate actors in LOS or
write one condition when more than one rule truly needs it. Reuse existing
Lua owners for summon expiry, monster frenzy, stat loss, mutations, sleep,
health, and noise. Do not mirror condition state in Go.

Ray effects such as Malmutate and Concentrate Venom, terrain control,
construct creation, and projectile attacks belong to later categories.

## Source-shaped effects

- **Abjuration:** consider visible hostile summoned monsters, then shorten
  their saved abjuration lifetime using the monster's spell power. Source
  protection from sanctuary and relevant god passives is respected where
  those capabilities exist. A summon that expires is removed by the summon
  owner; the spell does not invent a second deletion path.
- **Berserk Other:** choose an eligible aligned monster within radius three
  and unobstructed sight. Preserve source exclusions for Queen Bee and Moth
  of Wrath and the rule that the target must be closer to its foe than the
  caster. The existing allegiance owner starts and later ends frenzy.
- **Black Mark:** mark eligible aligned melee allies in sight. A marked
  monster's successful melee hit chooses among applicable antimagic,
  weakness, and draining effects. The mark is saved and expires; its melee
  consumer belongs with other monster attack effects.
- **Brain Feed:** cast only on a player foe. Preserve the one-in-three stat
  drain attempt and one-through-three Intelligence loss; use the existing
  player stat-loss owner and source messages.
- **Corrupting Pulse:** affect vulnerable unaligned actors in LOS. The
  player receives one or sometimes two temporary corrupt mutations; a
  monster receives its own saved corruption state. Mutation protection and
  sanctuary apply through their owning rules.
- **Dream Dust:** count Dream Sheep near the foe, draw source sleep power,
  and let weak attempts fail. Player sleep and wake immunity use the existing
  sleep owner; monsters use their existing stasis owner. Messages use player
  perception rather than naming unseen actors.
- **Flay:** target a natural living foe, deal `max(0, floor(current HP / 4)
  - 1)` through the relevant health owner, and save the *actual* damage
  dealt as recoverable damage. The condition ages; source ghost death or
  expiry returns at most that amount without exceeding max HP. Repeated
  casts accumulate actual damage and extend the condition per source rules.
- **Injury Bond:** mark eligible aligned monsters in sight with a saved
  protector handle and duration. Before ordinary damage lowers protected
  monster HP, divert half to the living, still-aligned protector. Instant
  death bypasses the split. The bond ends when its protector dies or its
  timer expires.
- **Silence:** attach a saved aura to the caster. Its source-shaped radius
  shrinks as it ages. Spell choice, verbal abilities, scroll use, and noise
  query the combined player and monster silence field. The aura follows
  the caster and disappears on death or expiry.

All effects use typed ECS components for mutable state, including caster
handles where attribution or recovery depends on the original actor. Lua
systems age those components by action aut. The save rules validate and
restore them without rerolling cast decisions or durations.

## Runtime and mod contract

The monster spell registry continues resolving `SPELL_NAME` to
`policy/combat/monster_spells/name.lua`. Each new effect returns a local
object with separately commented `plan` and `resolve` methods. IDs, causes,
streams, and messages come from imported `constants.*` or `ids.*` modules.
New status schemas and systems are individual discoverable Lua files. A mod
may replace one effect at the same relative path or add its own spell file.
All Lua functions explain their why and how; systems include a theory of
operation. Keep lines within 120 columns and prefer 80.

Preflight does not mutate world state or consume a draw. Resolution checks
that a saved target still exists and is eligible; a changed target must not
silently redirect a cast. Actor-neutral rules handle player and monster
victims, including allied monster casters. Visual messages require player
perception of the actor or event.

## Verification

Lua `_test.lua` files import production IDs, schemas, and policies. Test
each spell's refusal and effective path, ally safety, random bounds and
roll order, status age, source death, and conditions on player and monster
targets. A live Go spellbook test casts representative effects and verifies
save/restore continuation of pending conditions, source handles, and RNG.
Run the full Lua suite once after the category is integrated, then focused
Go game tests, style checks, and whole-category code review before one
implementation commit and local merge.
