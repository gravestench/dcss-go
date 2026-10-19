local brands = require("constants.weapon_brands")
local artefacts = require("policy.shops.value.artefacts")

local weapons = {}

-- Source: shopping.cc:item_value, OBJ_WEAPONS.
local multiplier = {
    [brands.SPEED] = 30,
    [brands.VAMPIRISM] = 30,
    [brands.ANTIMAGIC] = 30,
    [brands.DISTORTION] = 25,
    [brands.ELECTROCUTION] = 25,
    [brands.PAIN] = 25,
    [brands.ACID] = 25,
    [brands.PENETRATION] = 25,
    [brands.SPECTRAL] = 25,
    [brands.CHAOS] = 18,
    [brands.DRAINING] = 18,
    [brands.FLAMING] = 18,
    [brands.FREEZING] = 18,
    [brands.HOLY_WRATH] = 18,
    [brands.VORPAL] = 15,
    [brands.PROTECTION] = 12,
    [brands.VENOM] = 12,
}

-- Example: weapons.value(kind, sword, known, artefact) prices a revealed brand and plus.
-- Start with authored base price, then include only known brand, plus, and
-- artefact details so shop quotes do not expose hidden weapon properties.
function weapons.value(kind, item, known, artefact)
    local value = kind.weapon and kind.weapon.price or 0

    if known.type then
        value = math.floor(value * (multiplier[item.ego] or 10) / 10)
    end

    if known.pluses then
        value = value + 50 * item.plus
    end

    if artefact then
        value = value + (known.type and 7 * artefacts.value(artefact) or 50)
    elseif known.type and known.cosmetic and known.cosmetic ~= 0 then
        value = value + 20
    elseif not known.type and not known.pluses and
        known.cosmetic and known.cosmetic ~= 0 then
        value = value + 30
    end

    return value
end

return weapons
