-- A monster's Chaos weapon redraws a melee brand on every landed blow.
-- This is attack.cc's weapon table; Chaos itself enters the smaller actor
-- effect table, shared with a chaotic missile's self-selected result.
local player_effects = require("policy.combat.monster_missile_egos.chaos")
local streams = require("constants.rng_streams")
local weapon_brands = require("constants.weapon_brands")

local brand = {
    after_death = true,
}

local choices = {
    { id = weapon_brands.FLAMING, weight = 10 },
    { id = weapon_brands.FREEZING, weight = 10 },
    { id = weapon_brands.ELECTROCUTION, weight = 10 },
    { id = weapon_brands.VENOM, weight = 10 },
    { id = weapon_brands.CHAOS, weight = 10 },
    { id = weapon_brands.DRAINING, weight = 5 },
    { id = weapon_brands.VAMPIRISM, weight = 5 },
    { id = weapon_brands.HOLY_WRATH, weight = 5 },
    { id = weapon_brands.ANTIMAGIC, weight = 5 },
    { id = weapon_brands.CONFUSE, weight = 2 },
    { id = weapon_brands.DISTORTION, weight = 2 },
}

-- Draw from named source weights instead of relying on a mod file order.
-- Actor eligibility is checked by the chosen ordinary brand's own policy.
function brand.choose(ctx)
    local draw = ctx:random(streams.MELEE, 74)

    for _, choice in ipairs(choices) do
        draw = draw - choice.weight

        if draw < 0 then
            return choice.id
        end
    end

    error("chaos melee brand table has no outcome")
end

-- The ordinary brand resolver already owns HP, poison, drain, and status.
-- Only the self-selected Chaos outcome enters its actor-effect table here.
function brand.apply(ctx, hit, brands)
    local chosen = brand.choose(ctx)

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
