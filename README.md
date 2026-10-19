# DCrawl Go

DCrawl is a Go/ECS port of Dungeon Crawl Stone Soup. The Go engine owns the
world, save format, terminal, and Lua host API. The committed Lua tree in
[`internal/modfs/builtin`](internal/modfs/builtin) owns game content and most
game rules. You can change those files directly or add a sparse mod layer.

## Run

```sh
go run ./cmd/dcrawl
go run ./cmd/dcrawl --mod-dir=/path/to/my-mod
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
go run ./cmd/dcrawl --mod-dir=./my-mod
```

The matching relative path replaces the embedded rat definition. Edit that
file to make further changes; no rebuild or import step is needed for Lua
content. To add a new kind of content, use the wizard:

```sh
go run ./cmd/dcrawl-mod --mod-dir=/path/to/my-mod --kind=monster --name="moss wolf"
go run ./cmd/dcrawl-mod --mod-dir=/path/to/my-mod --kind=component --name="moss count"
go run ./cmd/dcrawl-mod --mod-dir=/path/to/my-mod --kind=vault --name="moss room" --with-hook
```

Omit `--mod-dir`, `--kind`, or `--name` to answer terminal prompts. The wizard
prints every path it will create and refuses to overwrite a file. It supports
species, jobs, monsters, spells, items, weapons, unique artefacts, branches,
clouds, traps, shops, mutations, monster spellbooks and beams, components,
systems, policies, spell effects, and vaults. A new content file is a starter:
fill its required fields and uncomment registration after comparing a bundled
definition of the same category.

Pass multiple `--mod-dir` flags to `dcrawl` for layered mods. Each layer can
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
