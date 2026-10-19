# Dungeon Crawl Stone Soup Go engine: visibility and exploration

Date: 2026-10-13

## Purpose and scope

The Go port currently gives its terminal client every terrain tile and every positioned entity on the current floor. This slice makes ordinary Dungeon play reveal only what the player can see, remembers terrain already explored, and preserves that knowledge through a Go save. The result should behave like the pinned DCSS console for opaque walls and normal Human vision, including corner and gap cases. It remains part of the larger faithful DCSS-to-Go port: Akara owns dynamic entities, each level owns dense terrain and exploration grids, and Bubble Tea/Lip Gloss only render the read-only game view.

The slice keeps the playable Human/Fighter, two-floor fixed Dungeon scenario. It expands the fixed floors enough for the radius and wall occlusion to matter while retaining the current rat, potion, stairs, combat, and menu flow. It does not claim to implement procedurally generated levels, transparent or half-opaque clouds, see-invisible, terrain-changing effects, magical mapping, item/monster memory outside sight, or monster perception. Those require separate gameplay rules and map-knowledge content. This slice must not make those unported behaviors appear functional.

## Source basis

The pinned reference is `/Users/dylanknuth/src/crawl/crawl-ref/source` at `e60ba3568b0c26447ad36ec5c7b963eb04b2778f` (tag-34). `defines.h:112-119` sets normal sight range to 7 and maximum range to 8. `coord-circle.cc:100-107` bounds the normal view by `rdist`, so the relevant range is Chebyshev distance, not a Euclidean circle. `los.cc:696-824` describes and computes DCSS's precomputed ray-bundle visibility; opaque cells stop rays behind them, but the blocking wall can itself be visible. The 15 maps in `dat/des/test/suite-los.des` (SHA-256 `850a05146a96e8d778c3f666ee07d7b6a056afc499081e2ca30ecd631380ed10`), checked by `test/los_maps.lua`, specify expected empty, edge, wall, corner, gap, and diagonal results. `map-knowledge.cc:128-170` separates seen terrain from currently visible terrain, and `tags.cc:6325-6334` clears transient visibility after loading saved map knowledge.

A normalized copy of the 15 golden maps and expected masks lives in Go testdata with the source revision, relative path, and hash. Go tests read this committed testdata only; normal Go builds, tests, CI, saves, and gameplay never require the C++ checkout. A source refresh is deliberate and reviewed, consistent with the repository-wide content policy.

## Approaches considered

1. **Port the source ray semantics for opaque terrain (selected).** This takes more work than a generic field-of-view algorithm, but the goldens make corner behavior verifiable and later opacity modes can extend the same boundary.
2. **Use recursive shadowcasting.** This is compact and often fast, but its corner and diagonal behavior can differ from DCSS; passing a few visual examples would not establish faithful rules.
3. **Apply a terminal-only mask.** It would hide glyphs but leave full terrain and entities exposed to other clients and game logic, creating two conflicting definitions of what the player knows.

## Ownership and data flow

`internal/visibility` is a pure rule package. Given a read-only rectangular terrain grid, origin, and normal radius, it returns a dense row-major visibility mask. It has no Akara, terminal, save, or global-state dependency. The initial opacity rule treats `#` as opaque and `.`, `<`, and `>` as clear. The player cell is always visible. The mask has the grid's exact dimensions; out-of-bounds cells are never visible. Tests cover all quadrants and translations, not just the northwest source fixtures.

Each `game.Level` owns a dense remembered-terrain grid aligned with its live terrain rows. An unknown cell has no remembered glyph; a visible cell updates its remembered glyph to the live terrain. `Game` owns only the current player's derived visibility mask. On new-run creation, successful player movement, successful stair travel, and restore, the game recomputes visibility at the player's resulting position and updates remembered terrain only for visible cells. Failed movement, blocked stairs, modal navigation, resize, inspection, and other free commands change neither grid nor aut. A future terrain mutation must use the same refresh path; a mutation outside sight must not alter the player's remembered glyph. There is no ECS component for static terrain or exploration; dynamic actors and items remain Akara entities.

`game.View` becomes a knowledge-limited value. It returns a copied row-major cell view with terrain glyph plus one explicit state: unknown, explored, or visible. Unknown cells contain no true terrain glyph; explored cells contain the remembered terrain glyph; visible cells contain the current terrain glyph. Positioned monsters and floor items enter `View.Entities` only while their cells are visible. The player is always present. Inventory and player statistics retain their current behavior. The terminal renderer consumes this view only: unknown is blank, explored terrain is dim, visible terrain uses the normal DCSS-shaped palette, and the nearby-monster pane lists only visible monsters. A copied view cannot be mutated to alter game state.

The fixed floors become larger rectangular maps with interior opaque walls and a path to their stairs. Scenario coordinates for the player, rat, potion, and both stair destinations are explicit and validated against walkability. Existing interactions remain reachable. Stair travel refreshes the destination floor before the returned view is built; returning to a floor retains its explored cells without exposing live entities outside current sight.

## Save contract and error handling

The Go snapshot advances from version 4 to version 5. Each level record stores its live terrain and same-sized remembered-terrain rows in deterministic row order. An unknown cell uses a space in the saved remembered row; a known cell stores one of the supported terrain glyphs. Current visibility is derived and is not serialized. Restore validates level IDs, rectangular terrain, remembered-row dimensions and glyphs, entity positions, and the player's location before installing the new game; malformed map knowledge fails without replacing the live run. After a valid restore, current visibility is recomputed and visible cells update the saved remembered terrain for the player's floor. The existing source-revision and catalog checks remain.

Version-4 and C++ saves are rejected with a clear version error. This is a deliberate Go save-format change; the existing untracked `dcrawl-save.json` is neither rewritten nor removed during development. The terminal already handles a failed load without replacing its current state. Version 5 is written atomically through the existing save codec.

## Verification and acceptance

- All 15 normalized source golden maps produce the expected visibility masks, including wall cells, blocked cells behind walls, corners, gaps, diagonals, range-seven edges, quadrant reflections, and translated player origins. The tests fail on an algorithm that sees through an opaque wall or uses the wrong range shape.
- A new run reveals its initial sight only. Moving around an interior wall reveals new cells; leaving them makes only terrain persist as explored. Monsters and floor items outside current sight do not appear in `game.View` or the nearby-monster pane. A wall at the sight boundary can be visible while the cell behind it is not.
- Stairs keep exploration separate by floor. Return travel restores remembered terrain on the original floor and recomputes live sight on the destination. Visibility refreshes after the completed player action and before the returned view, without spending extra aut.
- Snapshot round trips preserve per-floor remembered terrain and deterministic continuation. Malformed or wrong-size remembered rows, unsupported save versions, and invalid positions fail without replacing the active game. The existing untracked user save file is untouched.
- The 79x24 terminal and an expanded viewport show blank unknown space, dim explored terrain, and normally colored visible terrain. Menu, resize, HUD, inventory, skills, combat, pickup, save, and load flows remain usable. The complete Go test suite, vet, build, and a PTY start/move/save/load run pass. No Go runtime or test command reads the C++ source checkout.

The inventory at `docs/port-inventory.md` is updated after implementation to record exactly which sight and map-knowledge behaviors are now ported and which remain outstanding.
