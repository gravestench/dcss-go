local brands = require("constants.missile_egos")

local missiles = {}

-- Source: shopping.cc:item_value, OBJ_MISSILES.
local multiplier = {
    [brands.CURARE] = 30,
    [brands.BLINDING] = 30,
    [brands.SILVER] = 30,
    [brands.DISPERSAL] = 30,
    [brands.POISONED] = 20,
    [brands.FRENZY] = 20,
}

-- Example: missiles.value(kind, stack, known) returns a per-missile price with a known brand multiplier.
-- Value one missile here and let the caller apply stack quantity; brand
-- premiums only enter the quote once that brand is identified.
function missiles.value(kind, item, known)
    local value = kind.missile and kind.missile.price or 0

    if known.type then
        value = math.floor(value * (multiplier[item.ego] or 10) / 10)
    end

    return value
end

return missiles
