-- A monster's Chaos weapon redraws a melee brand on every landed blow.
-- This is attack.cc's weapon table; Chaos itself enters the smaller actor
-- effect table, shared with a chaotic missile's self-selected result.
local player_effects = require("policy.combat.monster_missile_egos.chaos")
local choice = require("policy.combat.chaos_choice")
local weapon_brands = require("constants.weapon_brands")

local brand = {
    after_death = true,
}

-- The same source eligibility and weight order serves both weapon Chaos
-- and natural Chaotic contact, before their different formulas run.
function brand.choose(ctx, hit)
    return choice.choose(ctx, hit)
end

-- The ordinary brand resolver already owns HP, poison, drain, and status.
-- Only the self-selected Chaos outcome enters its actor-effect table here.
function brand.apply(ctx, hit, brands)
    local chosen = brand.choose(ctx, hit)

    if chosen == weapon_brands.CHAOS then
        if hit.health.current > 0 then
            player_effects.apply(ctx, hit.attacker,
                nil, nil, hit.damage_done)
        end

        return
    end

    if hit.health.current <= 0 and
        chosen ~= weapon_brands.FLAMING and
        chosen ~= weapon_brands.FREEZING and
        chosen ~= weapon_brands.ELECTROCUTION and
        chosen ~= weapon_brands.VAMPIRISM then
        return
    end

    brands.apply(ctx, chosen, hit.damage_done, hit.source_id,
        hit.attacker_name, hit.health, hit.attacker,
        hit.player_moving)
end

return brand
