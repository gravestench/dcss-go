# Monster Reach Attacks

## Intent

Monsters should choose and resolve source reaching melee from their current
natural attacks and equipped weapon. The beast slice introduced the shared
geometry and slot filter for Sting. This slice completes the same domain for
ordinary Reach, Tongue, Rift, polearms, the Lochaber axe, and the Rift
artefact. A monster must lose reach immediately after dropping its weapon.

## Source behavior

The source computes a monster's reach from each nonzero natural attack and
its primary weapon. Reach, Reach Sting, and Reach Tongue permit distance two;
Rift permits distance three. Polearms and the Lochaber axe permit distance
two; the Rift artefact permits distance three. Two-cell attacks need either
middle cell clear of solid or opaque furniture. Three-cell Rift attacks
need a solid-blocking line of sight. A distant melee round visits all source
slots but only a slot with its own reaching flavour or a reaching weapon on
`AT_HIT` can make contact. Other slots do not attack across the gap.
Tongue acid and Rift distortion on confirmed contact belong to the
separate attack-flavour domain; this slice covers reach choice and geometry.

## Ownership

The existing Lua equipment owner exposes active weapon kind, skill, and
unique artefact identity. The Lua reach policy derives current range and
each contact's eligibility from that weapon plus the projected attacks.
AI uses the policy when offering a distant intent, and the combat gate
checks geometry again on execution. The generic Go grid supplies solidity
and line of sight; no monster-specific Go branch is added.

## Verification

Use real ECS item equipment and monster bodies. Check natural Tongue/Rift,
inherited undead Reach, polearms, Lochaber, Rift artefact, unequipping,
two-cell furniture,
three-cell line of sight, and the complete attack round's per-slot filter.
Run adjacent monster equipment, routing, combat, and game checks once at
the category boundary.
