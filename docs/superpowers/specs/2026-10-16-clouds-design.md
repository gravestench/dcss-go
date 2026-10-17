# Source-backed cloud field

## Intent and source boundary

The next domain slice makes clouds a complete Lua-owned world feature. A
modder should add a cloud by adding a definition file and, when it has an
effect, a focused effect file. The generic Go kernel continues to own Akara
storage, grid queries, line of sight, and save encoding. Cloud names, colors,
placement, interaction, damage, spread, dissipation, and attribution belong
to the effective layered Lua ruleset.

The reference is DCSS commit
`e60ba3568b0c26447ad36ec5c7b963eb04b2778f`, especially
`cloud-type.h`, `cloud.cc`, `cloud.h`, `beam.cc`, `spl-clouds.cc`, and
`main.cc:manage_clouds`. This slice covers the 34 concrete cloud types in
that pinned build, including its version-34 `CLOUD_GLOOM`. `CLOUD_NONE` and
the random/debug pseudo-types are selectors or sentinels, not placeable
saved cloud kinds. Existing spells and item effects must use the same cloud
policy, so there is one authoritative path.

The current port has 11 kinds in a hardwired table at
`policy/magic/effects/zaps/cloud.lua`. That module both exposes occupants and
ages the whole field from an actor-scoped system. With multiple actors, this
can dissipate a cloud more than once per player action. The replacement
must keep already playable fire, cold, poison, mephitic, smoke, dust, embers,
and translocation behavior while removing that table in the same change.

## Chosen ownership model

Three approaches are possible. A Go enum and switch would make the kernel
own game policy. One opaque component per cloud kind would make field
queries and saves harder to follow. The chosen approach is one discoverable
Lua definition per concrete kind, one generic saved `world.cloud` Akara
component per occupied cell, and small Lua modules for effects that differ.
Definitions carry source names, appearance, opacity, default spread rate,
terrain eligibility, harm category, and an effect module path. Shared
families such as smoke may point to the same effect module. The catalog
validates the effective files at startup, including mod-added kinds.

Committed generated Lua definitions are the runtime source of content. An
importer may refresh source metadata deliberately; normal build, launch,
and restore never read the C++ tree. Source provenance belongs in nearby
comments, not fields in gameplay tables. Common IDs live in `ids/clouds.lua`
and are imported where used. There is no central Go or Lua switch over all
kind IDs, and no inline Lua in Go.

The saved cloud component stores kind, cell, source actor when present,
attribution category, remaining decay in AUT, spread rate, and any special
state needed by source effects. Opacity remains a cached field for the Go
line-of-sight service and is checked against the Lua definition on restore.
At most one active cloud owns a cell. Terrain remains in its dense grid;
clouds can share a cell with an actor or item. A source actor may die before
its cloud, so validation must preserve attribution without requiring the
actor to remain live.

## Turn and field flow

Placement resolves random selectors once and applies source replacement,
sanctuary, occupancy, and terrain rules. It creates or changes a cloud entity
through one Lua policy. Spells, scrolls, traps, mutations, corpse rot, and
monster abilities call that policy instead of declaring their own cloud
rules. Special placement such as embers and forest fire uses a focused
effect file rather than a branch in a giant dispatcher.

An actor exposure system checks only the cloud under that actor when its
source-defined timing applies. Each cloud's effect module computes immunity,
resistance, armour-adjusted and time-scaled damage, status, and source
attribution. One Lua danger policy also answers whether a monster should
enter a cloud. It follows `cloud.cc:_mons_avoids_cloud`, including immunity,
intelligence, current HP, status risk, berserk behavior, and the source rule
that permits movement from one dangerous cloud to another. Monster path and
placement decisions use this policy instead of a duplicate hazard table.
A separate field system runs once per spent player action, after time
advances. It handles terrain interactions, spread, special emissions, and
dissipation in source order.
The field system iterates a stable snapshot so newly spread clouds do not
run their own field update in the same action. It consumes a named cloud RNG
stream and persists every random outcome through the normal save state.

Source behaviors include opacity changes, player-created nonopaque clouds
vanishing outside sight, ink restricted to water, steam beside fire and
water, forest fire consuming flammable terrain, rain sometimes leaving
temporary shallow or deep water when it dissipates, spectral and other
special effects, and source cloud replacement strengths. Acid clouds
apply the source corrosion duration and penalty to players as well as
monsters. The policy distinguishes
harmless clouds from clouds that have no direct damage but do have a negative
status effect. Wind, still-winds, and sanctuary rules must be represented as
explicit capabilities or conditions; they must not silently fall through to
a generic no-op. Where an adjacent
domain is not yet playable, a typed event and an inventory entry retain the
specific missing consumer.

## Presentation and saves

The terminal view reads the same cloud definition for name, glyph/color,
opacity, and remembered appearance. Opaque clouds affect line of sight at
placement, movement, replacement, and expiry. The old `magic.cloud` schema
and policy disappear; the new schema is authoritative with a save-version
bump, because the existing absolute-expiry state cannot express source
decay and spread. The port does not promise compatibility with its previous
experimental JSON saves. Restore rejects unknown kinds, invalid decay or
spread, duplicate cells, blocked terrain, forged cached opacity, and broken
attribution, without rerolling random selectors.

## Verification and completion

Lua `_test.lua` files import production definitions, schemas, and policies.
They cover all 34 source IDs, pseudo-selector boundaries, source placement
and replacement, field aging exactly once per player action, spread and
terrain interactions, immunity and damage families, monster avoidance,
rain flooding, player corrosion, opacity, and mod-added files. Integrated
Go scenarios cover existing
cloud-producing spells, actor/item coexistence, visibility, save
continuation, ruleset hash,
monster and player exposure, and a modded cloud. Run focused domain suites,
build, vet, style, and diff checks after the whole category changes. Make
one implementation commit for the cloud category and merge it into local
`main` once the integrated behavior is verified.
