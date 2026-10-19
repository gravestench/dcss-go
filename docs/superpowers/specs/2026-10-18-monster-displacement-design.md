# Monster blink and recall design

## Purpose and scope

Port the complete displacement family still used by committed monster
spellbooks: Blink, Blink Range, Blink Away, Blink Close, Blink Other, Blink
Other Close, Blink Allies Away, Blink Allies Encircle, and Word of Recall.
Blinkbolt already has a resolver and stays with the beam family. The result
must let a monster choose and execute these spells in the current Dungeon,
move authoritative Akara actors, and resume a saved recall chant correctly.
This is one gameplay category, not a set of placeholders that merely makes
spellbook coverage pass.

The pinned reference is `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`
under `/Users/dylanknuth/src/crawl/crawl-ref/source`. Relevant owners are
`mon-cast.cc`, `teleport.cc`, `beam.cc`, `mon-ench.cc`, and `mon-util.cc`.
The Go port keeps its Lua-first boundary: Go supplies grid, movement, ECS,
saved RNG, and the VM; Lua owns spell eligibility, destination selection,
recallable followers, messages, and timer effects.

## Design choice

Each spell keeps a discoverable `policy/combat/monster_spells/<name>.lua`
effect with `plan` and `resolve`. Focused helpers under
`policy/combat/monster_displacement/` share legal landing, weighted
destination choice, relocation effects, and ally selection. A single
spell-ID switch would concentrate unrelated rules and become harder to
extend; copying the landing algorithm into each effect would let habitat,
anchor, and occupancy behavior drift. Shared helpers accept explicit mode
and actors, while the effect files own the source conditions and messages.

There is no new Go spell dispatcher or inline Lua. All identifiers come from
shared `ids` and `constants` modules imported at their use sites. Functions
explain both the source behavior and why their timing or candidate filtering
matters. New Lua functions receive comments, lines stay at most 120 columns,
and multi-field tables put fields on separate lines.

## Blink rules and flow

Planning is read-only with respect to actor position. Self blinks record
the caster; foe blinks record the selected entity; ally blinks record the
foe's cell to avoid silently retargeting after intent creation. A source
ineligibility condition rejects the plan before the action is spent:
no-tele or Dimension Anchor for moved monsters, an already adjacent foe for
Blink Close, no visible foe for range/close/away, and no eligible allies for
the two group spells. Once planned, a blocked destination may waste the
cast, matching the source's resolution-time search.

Ordinary Blink samples up to 150 offsets in a 13-by-13 square, excludes the
origin and adjacent cells, requires the mover's habitat and a clear line of
sight from origin, and leaves the actor in place if no candidate survives.
Range, Away, Close, and Other Close use source distance weighting over
legal cells in the mover's sight: far modes weight by distance from the foe,
Close weights by squared distance remaining inside sight. Range and Close
keep the foe's line of sight; Away may break it. Other is an enchantment
beam that moves its hit actor by an ordinary uncontrolled blink; Other Close
uses the close weighting around the caster. Both obey beam contact and
willpower rules, including player and monster resistance.

Ally spells enumerate aligned, visible, living, movable monsters, excluding
the caster and Dimension Anchored or no-tele actors. Encircle accepts allies
currently farther than one cell from the foe and places them adjacent to
the planned foe cell. Away accepts allies within two cells of the foe and
moves them farther away. Candidate order is shuffled by the saved
`monster_spell` stream. The source count is
`max(1, floor(spell_hd / 8) + random(spell_hd / 4))`; only successful moves
consume that limit. Encircling allies spend movement energy and seek the
original foe; failed moves do neither.

Every successful move uses `ctx:move_actor`, releases a trapping net, and
places a short translocation-energy cloud at the origin through the
existing cloud policy. Terrain compatibility, occupied cells, line of
sight, saved Dimension Anchor, and constriction are checked before moving.
Messages depend on whether the player can see the relevant origin or
destination. Nothing in Lua holds a position as module-global state.

## Word of Recall

The caster can start a chant when at least three recallable allies are
outside its current sight and it is not winded. A recallable actor is an
aligned, living, mobile, threatening, normally intelligent monster on the
same level, excluding ghosts and conjured actors. Nearby allied HD informs
the source's tactical desirability roll, so a caster with ample visible
support may choose another spell.

Resolution adds a saved `magic.monster_recall` component with 30 aut left.
A Lua system decrements it by actual spent aut and runs before the next
monster decision. Silence, incapacitation, confusion, fear, death, or a
breath cooldown interrupts the chant without recall. At completion it
shuffles eligible out-of-sight followers, draws a limit of three through
seven, and moves that many to habitable empty cells within radius three of
the caster. A successful follower seeks the caster's foe. The caster then
receives a saved breath cooldown of four through twelve turns. Restore
validates timer ranges, owner, and references without replaying the cast.

## Verification and limits

Lua `_test.lua` files run through the production schema/catalog harness and
cover every spell effect, source count and weighted choices, habitat and
occupancy rejection, player/monster enchant resistance, ally allegiance,
constriction, clouds, and recall interruption/completion. A live game test
overlays a monster book, observes a real spell intent and move, then checks
save/restore and deterministic continuation. Test the category at its
boundary with the affected game suite, Lua rules, build, vet, style, and
diff checks. The full 653-test game package may be sharded for wall time.

The current playable world has no sanctuary domain, so no destination can
currently be marked sanctuary. When that world rule arrives, the shared
landing owner must consult its live sanctuary state; the spell files should
not each acquire a separate sanctuary workaround. Other unported monster
spells remain explicitly absent and continue to block their books from
generated population.
