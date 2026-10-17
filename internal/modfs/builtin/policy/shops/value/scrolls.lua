local ids = require("ids.items")

local scrolls = {}

-- Source: shopping.cc:item_value, OBJ_SCROLLS.
local known_value = {
    [ids.SCR_ACQUIREMENT] = 520,
    [ids.SCR_SUMMONING] = 95,
    [ids.SCR_TORMENT] = 95,
    [ids.SCR_SILENCE] = 95,
    [ids.SCR_BRAND_WEAPON] = 95,
    [ids.SCR_BLINKING] = 75,
    [ids.SCR_ENCHANT_ARMOUR] = 75,
    [ids.SCR_ENCHANT_WEAPON] = 75,
    [ids.SCR_MAGIC_MAPPING] = 75,
    [ids.SCR_AMNESIA] = 40,
    [ids.SCR_FEAR] = 40,
    [ids.SCR_IMMOLATION] = 40,
    [ids.SCR_POISON] = 40,
    [ids.SCR_VULNERABILITY] = 40,
    [ids.SCR_FOG] = 40,
    [ids.SCR_BUTTERFLIES] = 40,
    [ids.SCR_TELEPORTATION] = 30,
    [ids.SCR_IDENTIFY] = 20,
    [ids.SCR_CURSE_ARMOUR] = 20,
    [ids.SCR_CURSE_WEAPON] = 20,
    [ids.SCR_CURSE_JEWELLERY] = 20,
    [ids.SCR_HOLY_WORD] = 20,
    [ids.SCR_NOISE] = 10,
}

function scrolls.value(kind, _, known)
    if kind.shop_value ~= nil then
        return kind.shop_value
    end

    return known.type and (known_value[kind.id] or 0) or 10
end

return scrolls
