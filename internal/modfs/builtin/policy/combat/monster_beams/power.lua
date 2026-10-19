local catalog = require("policy.catalog")
local component = require("constants.component")
local monster_stats = require("policy.combat.monster_stats")
local range = require("policy.magic.range")

local power = {}

-- Derive beam power from the caster's live HD and the spell profile's scale.
function power.caster_power(ctx, caster, profile)
    local actor = ctx:get(caster, component.ACTOR)

    if not actor then
        error("monster beam caster has no actor")
    end

    local definition = catalog.get("monsters", actor.kind_id)
    local hit_dice

    -- mon-cast.cc:mons_spell_is_spell makes natural breath and spit use
    -- ordinary HD. Aura of Brilliance changes spell HD, not lung power.
    if profile.natural_power then
        hit_dice = monster_stats.hit_dice(ctx, caster, definition)
    else
        hit_dice = monster_stats.spell_hit_dice(ctx, caster, definition)
    end

    -- Source mon-cast.cc:mons_power_for_hd. Profiles supply their HD factor.
    local scaled = hit_dice * profile.power_hd_factor

    -- Caster-specific source breath exceptions multiply the calculated
    -- power, after a mod has had a chance to override the base profile.
    if profile.power_multiplier then
        local modifier = profile.power_multiplier

        scaled = math.floor(scaled * modifier.numerator /
            modifier.denominator)
    end

    -- Pain has an exceptional source floor even for a weak caster. Keep
    -- the floor in its profile so both damage and willpower use it.
    return math.max(profile.minimum_power or 0, scaled)
end

-- Copy a fixed profile before one caster-specific source adjustment. The
-- catalog definition remains immutable and modded HD factors still apply.
function power.with_multiplier(profile, numerator, denominator)
    if denominator <= 0 then
        error("beam power multiplier needs a positive denominator")
    end

    local adjusted = {}

    for key, value in pairs(profile) do
        adjusted[key] = value
    end

    adjusted.power_multiplier = {
        numerator = numerator,
        denominator = denominator,
    }

    return adjusted
end

-- Example: with fixed-range spell profile,
-- power.spell_range(ctx, caster, profile) -> catalog constant without HD scaling
-- Fixed-range spells bypass power calculation, while variable-range beams use live monster HD.
function power.spell_range(ctx, caster, profile)
    local spell = catalog.get("spells", profile.id)

    if spell.min_range_expr == spell.max_range_expr then
        return range.for_power(spell, 0)
    end

    return range.for_power(spell, power.caster_power(ctx, caster, profile))
end

return power
