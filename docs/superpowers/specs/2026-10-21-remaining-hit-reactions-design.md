# Hit-Triggered Summons, Fog, and Artefact Drawbacks

## Purpose

Port the remaining summon, fog, and artefact effects in the surviving-hit
response block of pinned `crawl-ref/source/ouch.cc`. Ru retribution and
Xom's damage amusement belong to their later god-action owners. The
existing player-health policy already owns
final HP loss and the sorted callback boundary. Religion, unique artefacts,
and random artefact drawbacks keep their rules in focused Lua modules; no
content-specific Go branch or parallel health path is added.

## Source behavior

After a positive hit leaves the player alive, the source runs deterioration,
monster ejection, demonic guardian, fog, powered by pain, and then
`*Corrode` and `*Slow` unless the cause is poison. Jiyva slime ejection and
the mutation reactions already exist. This slice adds:

- Xom's monster-caused butterfly ejection: final damage at least one-quarter
  of maximum HP, then a `damage / (3 * max HP)` chance, two to six friendly
  butterflies, all aimed at a still-living damager. Jiyva's branch takes
  precedence when its passive applies. Emit the source god message only if
  at least one butterfly is placed.
- Dithmenos hit smoke: three-star worship without penance, source lower and
  upper thresholds derived from current piety starting at 75 piety, then
  a threshold chance that places four to eight black-smoke cells. The
  Shadow Form guaranteed trigger is
  represented by the current saved form if that form becomes available.
- The equipped cloak of the Thief: if damage exceeds one-tenth of maximum
  HP, a one-in-two chance places eight to fifteen cells of one randomly
  selected smoke colour. Dithmenos smoke takes precedence.
- Xom hit smoke: if the earlier fog branches did not trigger, a
  `damage / (30 * floor(max HP / 2))` chance places four to eight Xom-trail
  clouds. Its roll is allowed during Xom penance, matching `you_worship`.
- Worn `*Corrode`: each contributing artefact makes one 3% trial. A
  successful degree makes one corrosion application, with independent
  rCorr protection per degree and one duration increase. Worn `*Slow`:
  each contributing artefact makes one 1% trial; each degree applies
  a nominal 10–14 turns of Slow, converted to 15–21 turns by source
  three-halves rounding. Species or form stasis rejects Slow. Poison skips
  both artefact drawbacks.

All random draws use persisted named streams. God decisions use the religion
stream; artefact trials use a damage-reaction stream; cloud placement uses
the cloud stream. Source order between reactions remains explicit in the
priority table, independent of Lua file discovery order.

## State and extension

Butterflies use the ordinary ECS summon owner. Save validation accepts only
the source Xom butterfly identity for a player-owned god summon and validates
its optional living target. Clouds use the existing saved cloud entities;
corrosion and slow use their existing saved player components. The fog rule
reads worn equipment through the shared validated equipment view. An
overlay can replace a focused policy file or its source content definition.

The `player_health.damage` owner only registers the reaction modules. New
rules should register at the relevant source-order priority rather than
growing a god or item switch in the health function.

## Verification

Production-schema `_test.lua` cases go through `player_health.damage`.
They cover thresholds, source and penance gates, the fog precedence chain,
equipped versus carried artefacts, poison exclusions, saved summon/cloud/
status metadata, and save validation. Related Lua and game tests run at the
category boundary, followed by all-package compilation, style, and diff
checks. The full game suite is run when feasible; any incomplete run is
reported accurately.
