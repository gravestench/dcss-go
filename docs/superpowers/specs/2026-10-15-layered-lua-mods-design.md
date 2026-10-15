# Layered Lua mod directories

## Goal

Allow a player to compose the embedded game with several sparse mod
directories. Adding a file under a discoverable directory should register
new content without editing a central registry. Replacing a file at the
same relative path should override its entire source file. The effective
Lua tree must be immutable for the lifetime of a game and identifiable in
saves.

## Boundary and precedence

The embedded `internal/modfs/builtin/` tree is layer zero. Each supplied
mod directory is another layer, applied in the order supplied. The last
layer containing a relative path wins. A file found only in an overlay
joins the effective tree. Layers are sparse; no layer needs a manifest or
a copy of the base tree.

The command line accepts repeated `--mod-dir` flags. Zero flags mean the
embedded game. The loader accepts an ordered list of directories and
returns one resolved `Ruleset`. Both `require` and automatic discovery read
only that resolved tree, so an override has the same effect whether a file
is imported explicitly or discovered at boot. Sort effective paths before
loading within the existing bootstrap phases. A helper under `lib/` is
loaded only when required; content, schemas, policies, systems, generation,
and UI continue to use their existing discoverable directories.

The loader validates each layer before applying it: roots must be real
directories; files must be regular `.lua` files with valid relative paths;
symlinks and paths colliding only by case are errors. Report the layer path
and relative path in errors. A later layer may replace an earlier file but
must not change its path's case. No overlay Lua is executed during file
resolution.

## Identity and saves

Hash the sorted effective path and byte pairs after all layers are applied.
`Vanilla` means those effective bytes equal the embedded tree, even when a
layer contains byte-identical copies. Keep the existing effective-file
manifest and changed-path list. Save and restore compare effective ruleset
identity, not the names or locations of mod directories. Load copies file
bytes once so edits to a directory do not mutate a running session.

Two layer orders that produce the same effective bytes yield the same
ruleset identity. Different winning bytes yield different identities.
The save format does not change solely for this loader feature.

## Configuration and diagnostics

Document repeated `--mod-dir` use with an example that adds a new monster
in one layer and overrides a spell in another. On failure, report the
offending layer and path. On success, expose the final ruleset hash for
diagnostics. Avoid a second registration mechanism or
per-category Go dispatch table. Duplicate definition IDs from different
effective files remain a Lua registration error with source paths.

## Verification

Test new files from two sparse directories, replacement precedence,
reversed-order hashes, byte-identical replacements, exact effective-file
manifest, invalid layers and collisions, `require` and autoload reading the
winning bytes, and save/restore identity. Exercise the repeated CLI flag
without requiring a terminal session. Keep existing one-overlay behavior
covered through the same loader path.

## Related extension

Lua-defined component fields currently use Akara's scalar dynamic schema
types. Typed list and map fields are a separate extension to Akara, Lua
conversion, and save encoding. They do not need a new mod-loading path;
schema files from any layer register through the same effective tree.
