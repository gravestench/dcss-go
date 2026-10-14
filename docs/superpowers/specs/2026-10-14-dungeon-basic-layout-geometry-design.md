# Dungeon `layout_basic` geometry

## Intent and scope

Replace the hand-written map as the only available Dungeon geometry with a
reproducible implementation of the pinned tag-34 `layout_basic` rules for D:1
and D:2. This category produces terrain and stair coordinates. It does not yet
select this layout in live play, place entities, or claim that the port has the
full Dungeon layout distribution. `layout_basic` has weight 35 in Dungeon in
`crawl-ref/source/dat/des/builder/layout_cc.des:10-22`; other layouts and vaults
remain separate port work.

The generator reads no C++ files at build or runtime. Its source rules are
written as Go and are tested against geometry invariants. The pinned reference
is `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.

## Approaches considered

1. **Port the source geometry into a temporary Go builder (chosen).** It keeps
   terrain ownership outside ECS and exposes a compact grid result. Source
   rules remain visible beside the code that applies them.
2. Store pre-generated example maps. This would be deterministic, but it would
   not port the source's procedural rules or support fresh runs.
3. Use a generic random-room algorithm. This would be easy to write, but its
   corridor budgets, stair placement, and room acceptance would not match the
   pinned game.

## Ownership and interface

`internal/levelgen` owns one short-lived 80×70 byte grid while building a
level. It has no Akara dependency and creates no entities. The result contains
terrain rows and three ordered stair pairs. `game.Level` will later own those
rows, stair links, visibility, and occupancy; the game session will supply RNG
streams and choose when to build a floor.

The exported function is:

```go
func BasicDungeon(depth int, next func() uint64) (Layout, error)
```

`depth` is 1 or 2. `next` supplies the caller's deterministic random stream.
The builder maps each draw to a bounded value without modulo bias. A nil draw
source or unsupported depth is an error. `Layout` exposes `Rows []string` and
`Stairs [3]StairPair`; each pair has an `Up` and `Down` coordinate. `Rows` uses
`#` rock, `.` floor, `+` closed door, `<` up stair, and `>` down stair.

## Source rules in this category

`dgn_build_basic_level` in `dgn-layouts.cc:49-126` starts with rock and draws
the corridor length, corridor budget, and intersection chance. It makes three
trails using source start rectangles `(35,30,35,20)`, `(10,15,10,15)`, and
`(50,20,10,15)`. `_make_trail` in `dgn-layouts.cc:289-374` biases direction
inward near the map edge, keeps horizontal run length, stops some intersections,
and limits attempts. The three down-stair starts are connected pairwise with
orthogonal corridors, following the purpose of `join_the_dots` in
`dungeon.cc:5604-5743`.

Room count and size follow the weighted and averaged draws in
`dgn-layouts.cc:108-124`. `_make_room` and `_make_random_rooms` in
`dgn-layouts.cc:867-996` admit only rooms with the permitted perimeter
connections, carve their rock, and sometimes make a narrow opening a closed
door. D:1 and D:2 have `absdepth0` values 0 and 1
(`place.cc:31-34`, `branch-data.h:18-24`), so the big-room, diamond-room, and
water/lava extras branches cannot alter their terrain. A source-matching
non-geometric extras draw is retained so future rules can share the stream.

The C++ path finder uses a subgenerator and an unusual distance comparator.
Go uses a bounded, orthogonal shortest connection between stair starts. It
preserves the connectivity rule but does not promise tile-for-tile C++ map or
RNG-sequence equivalence. The Go save will store generated terrain, so later
runtime changes to generation cannot alter a saved floor.

## Invariants and failure handling

- All rows are 80 columns and there are 70 rows; the outer border stays rock.
- Exactly three distinct up stairs and three distinct down stairs exist.
- Every stair is on walkable terrain, and the six stairs share one connected
  floor/door region when doors are considered traversable.
- The same depth and random sequence produce the same rows and stair pairs.
- Generation has bounded trail and room attempts. A failed trail or invalid
  final layout causes a fresh source-shaped attempt. After 16 failed attempts,
  generation returns an error rather than an unrelated fallback map.
- Rejection sampling does not loop forever if the supplied random source is
  degenerate; it returns an error after 16 unusable draws.

## Next integration category

Live play will consume this result when it can represent closed and open doors,
three linked stair pairs between D:1 and D:2, and explicit unavailable exits
at the current port boundary. Population will use the committed Dungeon table
and source generation counts while dynamic monsters remain Akara entities.
The fixed scenario remains a test fixture until that integration replaces it.
