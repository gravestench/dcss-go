local ids = require("ids.items")
local artefacts = require("policy.shops.value.artefacts")

local jewellery = {}

-- Source: shopping.cc:item_value, OBJ_JEWELLERY.
local variable_factor = {
    [ids.RING_SLAYING] = 3,
    [ids.RING_PROTECTION] = 2,
    [ids.RING_EVASION] = 2,
}

local stat_ring = {
    [ids.RING_STRENGTH] = true,
    [ids.RING_DEXTERITY] = true,
    [ids.RING_INTELLIGENCE] = true,
}

local fixed_value = {
    [ids.AMU_FAITH] = 400,
    [ids.RING_WIZARDRY] = 300,
    [ids.AMU_REGENERATION] = 300,
    [ids.AMU_GUARDIAN_SPIRIT] = 300,
    [ids.AMU_MANA_REGENERATION] = 300,
    [ids.AMU_ACROBAT] = 300,
    [ids.AMU_REFLECTION] = 300,
    [ids.RING_FIRE] = 250,
    [ids.RING_ICE] = 250,
    [ids.RING_PROTECTION_FROM_COLD] = 250,
    [ids.RING_PROTECTION_FROM_FIRE] = 250,
    [ids.RING_WILLPOWER] = 250,
    [ids.RING_MAGICAL_POWER] = 200,
    [ids.RING_LIFE_PROTECTION] = 200,
    [ids.RING_POISON_RESISTANCE] = 200,
    [ids.RING_RESIST_CORROSION] = 200,
    [ids.RING_STEALTH] = 175,
    [ids.RING_FLIGHT] = 175,
    [ids.RING_SEE_INVISIBLE] = 150,
    [ids.AMU_NOTHING] = 75,
}

function jewellery.value(kind, item, known, artefact)
    if not known.type then
        return 50
    end

    local value = 0
    local variable = kind.jewellery and kind.jewellery.pluses

    if variable then
        local base = (variable_factor[kind.id] or 0) * item.plus

        if stat_ring[kind.id] then
            base = math.floor(item.plus * 4 / 3)
        end

        if base <= 0 then
            value = 25 * base
        else
            value = 5 * base * (base + 1)
        end
    else
        value = fixed_value[kind.id] or 0
    end

    if artefact then
        local bonus = 7 * artefacts.value(artefact)

        value = value < 0 and bonus - 35 or value + bonus
    end

    return math.max(20, value)
end

return jewellery
