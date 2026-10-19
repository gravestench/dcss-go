local streams = require("constants.rng_streams")
local brands = require("constants.weapon_brands")
local ids = require("ids.items")
local skills = require("ids.skills")
local source = require("policy.item_generation.source_roll")

local weapon_brand = {}

-- Source: crawl-ref/source/artefact.cc.
local ranged = {
    {
        id = brands.SPEED,
        weight = 2,
    },
    {
        id = brands.VENOM,
        weight = 4,
    },
    {
        id = brands.VORPAL,
        weight = 4,
    },
    {
        id = brands.FLAMING,
        weight = 4,
    },
    {
        id = brands.FREEZING,
        weight = 4,
    },
}

local demonic = {
    brands.DRAINING,
    brands.FLAMING,
    brands.FREEZING,
    brands.ELECTROCUTION,
    brands.VAMPIRISM,
    brands.PAIN,
    brands.VENOM,
}

local melee = {
    {
        id = brands.VORPAL,
        weight = 73,
    },
    {
        id = brands.FLAMING,
        weight = 34,
    },
    {
        id = brands.FREEZING,
        weight = 34,
    },
    {
        id = brands.VENOM,
        weight = 26,
    },
    {
        id = brands.DRAINING,
        weight = 26,
    },
    {
        id = brands.HOLY_WRATH,
        weight = 13,
    },
    {
        id = brands.ELECTROCUTION,
        weight = 13,
    },
    {
        id = brands.SPEED,
        weight = 13,
    },
    {
        id = brands.VAMPIRISM,
        weight = 13,
    },
    {
        id = brands.PAIN,
        weight = 13,
    },
    {
        id = brands.ANTIMAGIC,
        weight = 13,
    },
    {
        id = brands.PROTECTION,
        weight = 13,
    },
    {
        id = brands.SPECTRAL,
        weight = 13,
    },
    {
        id = brands.DISTORTION,
        weight = 3,
    },
    {
        id = brands.CHAOS,
        weight = 3,
    },
}

-- Example: weapon_brand.roll(ctx, sword) chooses a randart brand compatible with that weapon.
-- Crossbows get extra electrocution/penetration chances after the ranged draw; demon weapons use a separate gate.
function weapon_brand.roll(ctx, definition)
    local ranged_weapon = definition.weapon and
        definition.weapon.skill_id == skills.SK_RANGED_WEAPONS

    if ranged_weapon then
        local chosen = source.weighted_id(ctx, ranged)

        if definition.weapon.ammo_id == ids.MI_BOLT then
            if source.chance(ctx, 1, 5) then
                chosen = brands.ELECTROCUTION
            elseif source.chance(ctx, 1, 5) then
                chosen = brands.PENETRATION
            end
        end

        return chosen
    end

    -- Demonic bases first try their restricted pool; the general melee table remains a fallback.
    if definition.id:match("^WPN_DEMON_") and
        source.chance(ctx, 7, 9) then
        return demonic[ctx:random(streams.ITEM_GENERATION, #demonic) + 1]
    end

    local chosen = source.weighted_id(ctx, melee)

    if definition.id == ids.WPN_QUICK_BLADE and
        chosen == brands.SPEED then
        return ""
    end

    if definition.id:match("^WPN_DEMON_") and
        chosen == brands.HOLY_WRATH then
        return ""
    end

    return chosen
end

return weapon_brand
