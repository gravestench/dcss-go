-- Source makeitem.cc:is_weapon_brand_ok determines whether a weapon may
-- carry an authored or generated brand. A base weapon's brand_weights are
-- only its random-roll distribution; they are not this legality rule.
local ammunition = require("ids.ammunition")
local brands = require("constants.weapon_brands")
local item_ids = require("ids.items")

local compatibility = {}

local universal = {
    [brands.VENOM] = true,
    [brands.PROTECTION] = true,
    [brands.SPEED] = true,
    [brands.VORPAL] = true,
    [brands.CHAOS] = true,
    [brands.HOLY_WRATH] = true,
    [brands.ELECTROCUTION] = true,
    [brands.FLAMING] = true,
    [brands.FREEZING] = true,
}

local melee = {
    [brands.DRAINING] = true,
    [brands.VAMPIRISM] = true,
    [brands.PAIN] = true,
    [brands.DISTORTION] = true,
    [brands.ANTIMAGIC] = true,
    [brands.SPECTRAL] = true,
    [brands.REAPING] = true,
}

local ranged = {
    [brands.PENETRATION] = true,
    [brands.ACID] = true,
}

-- Classify by the effective weapon's ammunition link, which also lets a
-- mod-added ranged base use the same source restriction without a name list.
function compatibility.valid(kind, brand)
    if not kind.weapon then
        return false
    end

    local is_ranged = kind.weapon.ammo_id ~= ammunition.NONE

    if brand == brands.SPEED and
        kind.id == item_ids.WPN_QUICK_BLADE then
        return false
    end

    return universal[brand] or
        (is_ranged and ranged[brand]) or
        (not is_ranged and melee[brand]) or false
end

return compatibility
