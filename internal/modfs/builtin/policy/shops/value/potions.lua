local ids = require("ids.items")

local potions = {}

-- Source: shopping.cc:item_value, OBJ_POTIONS. Missing cases have source
-- value 1 after the common minimum, unless a mod definition supplies one.
local known_value = {
    [ids.POT_EXPERIENCE] = 500,
    [ids.POT_RESISTANCE] = 100,
    [ids.POT_HASTE] = 100,
    [ids.POT_MAGIC] = 80,
    [ids.POT_INVISIBILITY] = 80,
    [ids.POT_CANCELLATION] = 80,
    [ids.POT_AMBROSIA] = 80,
    [ids.POT_MUTATION] = 80,
    [ids.POT_BERSERK_RAGE] = 50,
    [ids.POT_HEAL_WOUNDS] = 50,
    [ids.POT_MIGHT] = 40,
    [ids.POT_BRILLIANCE] = 40,
    [ids.POT_CURING] = 30,
    [ids.POT_LIGNIFY] = 30,
    [ids.POT_ATTRACTION] = 30,
    [ids.POT_FLIGHT] = 30,
    [ids.POT_DEGENERATION] = 10,
}

-- Example: potions.value(kind, nil, known) hides the type premium for an unknown potion.
-- Use the generic unknown price until identification, preventing the quote
-- from revealing a potion's effect before the player knows it.
function potions.value(kind, _, known)
    if kind.shop_value ~= nil then
        return kind.shop_value
    end

    return known.type and (known_value[kind.id] or 0) or 9
end

return potions
