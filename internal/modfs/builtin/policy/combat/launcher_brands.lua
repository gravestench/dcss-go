local brands = require("constants.weapon_brands")

local launcher_brands = {}

-- makeitem.cc permits these brands on ranged weapons, even when the
-- ordinary launcher generation weights do not happen to choose one.
local legal = {
    [brands.NORMAL] = true,
    [brands.VENOM] = true,
    [brands.PROTECTION] = true,
    [brands.SPEED] = true,
    [brands.VORPAL] = true,
    [brands.CHAOS] = true,
    [brands.HOLY_WRATH] = true,
    [brands.ELECTROCUTION] = true,
    [brands.FLAMING] = true,
    [brands.FREEZING] = true,
    [brands.PENETRATION] = true,
    [brands.ACID] = true,
}

-- Speed and Penetration act before contact. Protection instead refreshes
-- a player aura on a hit, so it must reach the target brand owner.
local passive = {
    [brands.SPEED] = true,
    [brands.PENETRATION] = true,
}

local function normalized(id)
    return (id == nil or id == "") and brands.NORMAL or id
end

-- Validate by source eligibility before loading the focused effect file.
-- A mod cannot make a melee-only brand legal by adding a Lua module name.
function launcher_brands.check(id)
    local brand_id = normalized(id)

    if not legal[brand_id] then
        error("invalid launcher brand " .. tostring(id))
    end

    return brand_id
end

-- A passive brand has no post-hit handler; timing or trajectory owns it.
function launcher_brands.passive(id)
    return passive[launcher_brands.check(id)] == true
end

return launcher_brands
