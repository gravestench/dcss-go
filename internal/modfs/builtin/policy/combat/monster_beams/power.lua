local catalog = require("policy.catalog")
local component = require("constants.component")
local monster_stats = require("policy.combat.monster_stats")
local range = require("policy.magic.range")

local power = {}

function power.caster_power(ctx, caster, profile)
    local actor = ctx:get(caster, component.ACTOR)

    if not actor then
        error("monster beam caster has no actor")
    end

    local definition = catalog.get("monsters", actor.kind_id)
    local hit_dice = monster_stats.hit_dice(ctx, caster, definition)

    -- Source mon-cast.cc:mons_power_for_hd. Spell HD adjustments belong to
    -- the monster status domain once those enchantments are playable.
    return hit_dice * profile.power_hd_factor
end

function power.spell_range(ctx, caster, profile)
    local spell = catalog.get("spells", profile.id)

    if spell.min_range_expr == spell.max_range_expr then
        return range.for_power(spell, 0)
    end

    return range.for_power(spell, power.caster_power(ctx, caster, profile))
end

return power
