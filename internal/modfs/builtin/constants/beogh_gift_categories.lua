-- A follower can receive one personal gift, even after losing its gear.
-- The category survives save/restore and records the source gift marker.
local categories = {
    MELEE_WEAPON = "melee_weapon",
    RANGED_WEAPON = "ranged_weapon",
    BODY_ARMOUR = "body_armour",
    SHIELD = "shield",
}

-- Validate stored markers without depending on a Lua table's key order.
function categories.valid(value)
    return value == categories.MELEE_WEAPON or
        value == categories.RANGED_WEAPON or
        value == categories.BODY_ARMOUR or
        value == categories.SHIELD
end

return categories
