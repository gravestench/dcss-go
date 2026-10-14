# Human/Fighter Skill Training Design

## Intent and boundary

Make experience from the currently playable Dungeon run improve the player's
skills as well as experience level. A reader should find the source arithmetic
in `character`, the mutable training state on the Akara player entity, and the
ordered spending step in one game system. The existing `m` screen should show
real training state and accept the source's basic no-time training controls.

This slice covers Human/Fighter, its available melee weapons, body armour,
shield, and the ordinary monsters already playable. It does not invent
practice for spells, ranged attacks, religion, manuals, mutations, or other
species. Their future systems will send practice events through the same
player-owned training path.

## Source contract

Pinned source: `crawl-ref/source` at `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.

- `player.cc:2470-2514`: one earned XP grants ten skill XP; skill spending
  precedes `level_change`.
- `skills.cc:148-175`: skill cost level follows total skill XP spent.
  The 27-entry per-point cost table starts `1, 2, 3, 4, 5, 7` and caps at 265.
  The next cost level begins at `13 * exp_needed(level, 1)`.
- `skills.cc:2047-2090`: Human's zero aptitude uses the base point thresholds:
  `25 * level * (level + 1)`, with extra half-cost terms above levels 9,
  18, and 26. Stored starting points remain 301 at level 3 and 151 at level 2.
- `skills.cc:587-817,832-1053,1260-1337`: automatic training uses two
  100-entry recent-practice queues; manual training gives equal weight to
  enabled skills and double weight to focused skills. A spending operation
  may add at most 2650 skill XP to one skill, cannot overdraw the pool, and
  stops at level 27.
- `exercise.cc:145-181,202-234`: current melee hits, incoming attacks,
  armour hits, and shield contests generate practice. Future action families
  will add their source practice rules as those actions become playable.

## Ownership and turn order

`ecs.Skills` remains the sole source of skill points and displayed levels.
An `ecs.SkillTraining` component on the player owns available and spent skill
XP, cost level, auto/manual mode, per-skill disabled/focused state, and both
recent-practice queues. It is not copied into `Game` or a UI model.

Combat and other action systems append transient practice events to
`TurnContext`. The death system credits both character XP and tenfold skill
XP to their respective player components. The ordered skill-training system
consumes practice, computes weights, spends available skill XP, updates
`ecs.Skills`, and emits level-up messages. It runs after death and before the
existing advancement system so Fighting gains affect HP at the correct level.
It uses a named, saved `skill` RNG stream for queue order, training order,
weighted draws, and source random rounding. Rendering reads a copied view.

The terminal's `m` screen shows actual levels, training percentages, and
enabled/focused state. `/` switches automatic/manual mode, `|` switches
between toggle and focus actions, and skill letters change the selected
training state without spending aut. Controls for targets and views that do
not yet have gameplay rules continue to explain their unavailability.

The first implementation spends one point at a time using the source's
practice-derived and manual weights, point costs, and cost-level boundaries.
The C++ first-phase allocation of a whole XP batch among several skills is
still a fidelity gap. Keep that gap explicit in the port inventory rather
than presenting the weighted selection as identical to source draw order.

## Persistence and validation

Bump the Go save schema once for this category. Save authoritative skills and
training state, including both queues and skill RNG state; deep-copy slices
in snapshots, restoration, and views. Validate unique known skill IDs,
Human point thresholds and levels, unspent plus spent skill XP equaling ten
times earned XP, cost level against spent XP, queue bounds, mode, and focus
settings before registering entities. Starting skill points are lower bounds.
No other entity may carry skill-training state. Restore then continues the
same training choice and RNG sequence as uninterrupted play.

## Acceptance checks

Pure rule tests pin point thresholds through level 27 and every cost boundary.
Gameplay tests compare an earned kill with and without training enabled,
verify training precedes character advancement, and check save continuation.
Terminal tests show real training values and prove mode/toggle/focus commands
spend no aut. Corrupt-save tests reject inconsistent skill points, XP pools,
cost levels, and queues. Full tests, vet, build, style, and read-only review
run before the category commit reaches local `main`.
