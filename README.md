# Dungeon Crawl Stone Soup

This repository ports **Dungeon Crawl Stone Soup (DCSS)** to a Go engine.
It is still Crawl: the goal is faithful gameplay and content, with the same
recognizable terminal game and authored vault maps. The port is in progress;
some DCSS mechanics are not playable yet. Its saves use a new Go format rather
than the original C++ save format.

## Why this port exists

The original game's C++ code carries decades of features, global state, and
rules spread across many call chains. That makes a small content change hard
to understand or extend. This port puts generic engine services in Go and
most game decisions in readable Lua files. The goal is to let a developer or
modder find one content definition, its focused rule, and its test without
learning the whole engine first. Go also gives this project a simpler build
and iteration loop for its maintainers.

The architecture differs from the original implementation in these ways:

| Concern | This engine |
| --- | --- |
| Live actors, items, and conditions | Akara ECS entities and saved components. |
| Terrain and level geometry | Dense grids with 17 active Dungeon layouts and authored vault maps using DCSS DES declarations plus named Lua hooks. D:1 exists at launch; deeper Dungeon floors are generated when their stairs are first used. |
| Game content and policy | Committed, auto-discovered Lua files under [`internal/modfs/builtin`](internal/modfs/builtin). |
| Modding | Sparse Lua and `.des` overlays add files or replace a bundled file at the same relative path. |
| Terminal client | Bubble Tea and Lip Gloss render the DCSS-style interface across the available terminal area. |
| Saves | A Go format records ECS state and a checksum of the effective Lua ruleset. |

Lua content is the source of truth for normal builds and play. An upstream
DCSS checkout is useful when tracing a rule, but the game does not import
C++ content during a build or launch. The [modding guide](docs/modding.md)
explains the Lua entry points, the live `ctx` object, file discovery, and
testing. The bundled source remains subject to its upstream attribution and
license notices in [LICENSE](LICENSE).

## Run

```sh
go run ./cmd/crawl
go run ./cmd/crawl --mod-dir=/path/to/my-mod
```

The terminal client uses the available terminal area and needs at least a
79×24 terminal. Run `go test ./...` to check the engine and bundled rules.

## Create a mod

This complete one-file overlay renames the bundled rat in the game:

```sh
mkdir -p my-mod/content/monsters
sed 's/name = "rat"/name = "moss rat"/' \
  internal/modfs/builtin/content/monsters/mons_rat.lua \
  > my-mod/content/monsters/mons_rat.lua
go run ./cmd/crawl --mod-dir=./my-mod
```

The matching relative path replaces the embedded rat definition. Edit that
file to make further changes; no rebuild or import step is needed for Lua
content. To add a new kind of content, use the wizard:

```sh
go run ./cmd/crawl-mod --mod-dir=/path/to/my-mod --kind=monster --name="moss wolf"
go run ./cmd/crawl-mod --mod-dir=/path/to/my-mod --kind=component --name="moss count"
go run ./cmd/crawl-mod --mod-dir=/path/to/my-mod --kind=vault --name="moss room" --with-hook
```

Omit `--mod-dir`, `--kind`, or `--name` to answer terminal prompts. The wizard
prints every path it will create and refuses to overwrite a file. It supports
species, jobs, monsters, spells, items, weapons, unique artefacts, branches,
clouds, traps, shops, mutations, monster spellbooks and beams, components,
systems, policies, spell effects, and vaults. A new content file is a starter:
fill its required fields and uncomment registration after comparing a bundled
definition of the same category.

Pass multiple `--mod-dir` flags to `crawl` for layered mods. Each layer can
contain one file or many. A later layer replaces an earlier file with the
same relative path; otherwise its files are added. For example, to change the
bundled rat, put a file at `content/monsters/mons_rat.lua` in your mod
directory. The effective file bytes identify the ruleset in saves.

Start with the [modding guide's `ctx` primer](docs/modding.md#ctx-in-one-minute)
to see when the engine passes live game state to Lua. The full
[modding guide](docs/modding.md) covers the `ctx` methods, field types,
content contracts, policy versus system decisions, vault hooks, testing, and
save behavior.
The committed Lua files are the source of truth; no C++ import or regeneration
step is needed to build or run the game.
