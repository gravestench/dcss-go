local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local spells = require("ids.spells")
local sticky = require("policy.combat.sticky_flame")

local sticky_flame_range = {}
-- Ranged Sticky Flame affects players before damage and monsters after a landed hit.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_STICKY_FLAME_RANGE)

-- Example: sticky_flame_range.plan(ctx, caster, foe) with reachable foe -> entity plan for the flame effect
-- Precedes the target-specific flame hook.
function sticky_flame_range.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- Players acquire sticky flame before beam damage, matching player-side timing.
function sticky_flame_range.before_damage(ctx, caster, defender)
    if ctx:has(defender, component.PLAYER) then
        sticky.apply_player(ctx, caster, defender)
    end
end

-- Monsters acquire sticky flame only after a landed hit with a known species profile.
function sticky_flame_range.after_hit(ctx, caster, defender, _, outcome)
    -- Player flame was already applied before damage; its ACTOR kind is
    -- not a monster catalog ID and must not enter the monster path.
    if ctx:has(defender, component.PLAYER) then
        return
    end

    local actor = ctx:get(defender, component.ACTOR)

    if not actor then
        return
    end

    local definition = catalog.get("monsters", actor.kind_id)

    sticky.apply(ctx, caster, defender, definition, outcome.damage)
end

-- The hook applies flame on the appropriate side of shared beam damage.
function sticky_flame_range.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile,
        plan, sticky_flame_range)
end

return sticky_flame_range
