-- Object class IDs distinguish item families before a concrete item kind is selected.

-- Source: crawl-ref/source/object-class-type.h.
-- Class IDs must be available while content files are still registering.
local classes = {
    OBJ_WEAPONS = "OBJ_WEAPONS",
    OBJ_MISSILES = "OBJ_MISSILES",
    OBJ_ARMOUR = "OBJ_ARMOUR",
    OBJ_WANDS = "OBJ_WANDS",
    OBJ_FOOD = "OBJ_FOOD",
    OBJ_SCROLLS = "OBJ_SCROLLS",
    OBJ_JEWELLERY = "OBJ_JEWELLERY",
    OBJ_POTIONS = "OBJ_POTIONS",
    OBJ_BOOKS = "OBJ_BOOKS",
    OBJ_STAVES = "OBJ_STAVES",
    OBJ_ORBS = "OBJ_ORBS",
    OBJ_MISCELLANY = "OBJ_MISCELLANY",
    OBJ_CORPSES = "OBJ_CORPSES",
    OBJ_GOLD = "OBJ_GOLD",
    OBJ_RODS = "OBJ_RODS",
    OBJ_RUNES = "OBJ_RUNES",

    OBJ_UNASSIGNED = "OBJ_UNASSIGNED",
    OBJ_RANDOM = "OBJ_RANDOM",
    OBJ_DETECTED = "OBJ_DETECTED",
}

-- Accept a new, well-formed class ID when a layered mod first references it.
-- This keeps classes extensible without permitting arbitrary misspelled keys.
local function mod_class(_, id)
    if type(id) ~= "string" or not id:match("^OBJ_[A-Z0-9_]+$") then
        error("invalid object class ID " .. tostring(id))
    end

    -- An overlay may add a new class without editing the base enum file.
    classes[id] = id

    return id
end

setmetatable(classes, { __index = mod_class })

return classes
