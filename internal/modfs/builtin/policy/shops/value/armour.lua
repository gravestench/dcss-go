local egos = require("constants.armour_egos")
local artefacts = require("policy.shops.value.artefacts")

local armour = {}

-- Source: shopping.cc:item_value, OBJ_ARMOUR.
local ego_value = {
    [egos.ARCHMAGI] = 250,
    [egos.RESISTANCE] = 250,
    [egos.COLD_RESISTANCE] = 50,
    [egos.DEXTERITY] = 50,
    [egos.FIRE_RESISTANCE] = 50,
    [egos.SEE_INVISIBLE] = 50,
    [egos.INTELLIGENCE] = 50,
    [egos.FLYING] = 50,
    [egos.STEALTH] = 50,
    [egos.STRENGTH] = 50,
    [egos.INVISIBILITY] = 50,
    [egos.WILLPOWER] = 50,
    [egos.PROTECTION] = 50,
    [egos.HURLING] = 50,
    [egos.REPULSION] = 50,
    [egos.PRESERVATION] = 50,
    [egos.SHADOWS] = 50,
    [egos.RAMPAGING] = 50,
    [egos.INFUSION] = 50,
    [egos.LIGHT] = 50,
    [egos.ENERGY] = 50,
    [egos.POSITIVE_ENERGY] = 20,
    [egos.POISON_RESISTANCE] = 20,
    [egos.REFLECTION] = 20,
    [egos.SPIRIT_SHIELD] = 20,
    [egos.HARM] = 20,
    [egos.RAGE] = 20,
    [egos.MAYHEM] = 20,
    [egos.GUILE] = 20,
    [egos.PONDEROUSNESS] = -250,
}

function armour.value(kind, item, known, artefact)
    local value = kind.armour and kind.armour.price or 0

    if known.type then
        value = value + (ego_value[item.ego] or 0)
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

return armour
