# Early Dungeon plain-bite monsters

## Intent and scope

Continue the faithful Go port's live D:1–2 population with the giant
cockroach and worm. Both definitions are already committed from the pinned
C++ revision `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`. Mutable actors,
health, AI, and corpses remain Akara entities. Terrain and population weights
remain level grids and immutable catalog data.

This slice covers source-backed single plain-bite actors that do not form
bands. Jackals require band placement (one to four followers per leader in
`mon-place.cc:1779,2107`), so they stay outside this category. The fixture
rat/quokka/lizard scenario keeps its original three actors. New populated
and generated games may select cockroaches on D:1–2 and worms on D:2 from
the committed Dungeon population table.

## Source rules

- `mon-data.h:2831–2841`: giant cockroach has one plain bite for 2 damage,
  HD 1, average HP ×10 of 50, speed 12, XP modifier 10, and
  `M_NO_SKELETON`.
- `mon-data.h:2381–2391`: worm has one plain bite for 12 damage, HD 4,
  average HP ×10 of 180, speed 6, XP modifier 3, `M_FAST_REGEN`, and
  `M_NO_SKELETON`.
- `mon-util.cc:2345–2535`: ordinary no-spell, no-item XP uses actual maximum
  HP, speed, and the fast-regeneration difficulty modifier. The existing
  pure XP rule already implements these stages.
- `mon-act.cc:125–160,1724`: a damaged fast-regenerating worm heals one HP
  before each of its actions. The existing HD-1 animals have a one-in-25
  natural regeneration chance while damaged.
- `monster.cc:2928–2955` and `timed-effects.cc:733–759`: a returning worm
  heals at 100 hundredths of HP per away turn; HD-1 ordinary animals use 10.
- `corpse.cc:44–61,93–107` and `mon-util.cc:2216–2219`: a body with
  `M_NO_SKELETON` disappears when its freshness expires, consuming no
  skeleton appearance draw.

## Ownership and flow

`character` validates the supported plain-bite catalog profile and projects
XP. The monster factory uses the catalog profile and source HP roll, then
creates the same Akara components as existing ordinary animals. An ordered
regeneration system reads the acting monster's Actor and Health before AI,
using a named RNG stream only for damaged HD-1 natural regeneration. The
existing catch-up system receives the monster's source off-level rate. The
corpse aging system reads the monster definition to decide whether a body
can become a skeleton. The saved run already stores actors, health, corpses,
RNG streams, and floor away clocks; no save-schema change is needed.

## Acceptance

Both kinds can be selected on their source-weighted floors, attack and be
attacked with their catalog stats, award source XP, drop named body corpses,
regenerate at the source rates, age without skeletons, and survive a
save/restore round trip. Existing fixture behavior and save continuation
remain intact. The full tests, vet, build, and style check pass.
