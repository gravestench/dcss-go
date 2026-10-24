# Yredelemnul wrath design

Yredelemnul's wrath has one direct draining spell and one undead branch.
The draining spell already uses the durable god avatar. This slice
completes the undead branch without adding a second monster owner.

## Source behavior

- On the undead half, a current Yredelemnul worshipper first has a
  coinflip chance to lose permanent friendly Yredelemnul undead gifts.
  At least one eligible gift is reclaimed. If none exists, wrath summons
  undead instead.
- The number of undead attempts scales with experience level. Each
  attempt has a one-in-level chance to select a Dungeon zombie or
  skeleton. Skeletons require a base that leaves bones. Other attempts
  select from the existing source-ordered servant roster.
- A zombie base is chosen from the effective Dungeon population at the
  source's level-based depth. Natural, generatable, fast-enough corpse
  monsters are eligible; the source's duplicate population rows retain
  their weights. A hostile permanent summon carries the base kind in the
  existing `magic.summon_undead` component.

## Ownership

The `magic.summon` ECS record owns a wrath servant's god source,
allegiance, and expiry. A permanent friendly Yredelemnul god record is a
reaped follower; finite spell summons are excluded from soul reclaim.
The existing summon owner handles placement and dismissal. The zombie
base selector reads committed Lua population content, so runtime play
never reads the C++ checkout.

## Verification

Production-schema Lua tests cover soul reclaim, empty reclaim fallback,
servant choice, zombie and skeleton bases, blocked placement, and source
RNG order. A game test saves and restores a god-owned derived undead.
The slice ends with a focused test run, build, line-width check, commit,
and push to `main`.
