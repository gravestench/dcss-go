-- Source: mon-enum.h:mon_itemuse_type. Only the equipment-capable values
-- contribute carried item properties to monster resistances.
local item_use = {
    NOTHING = "MONUSE_NOTHING",
    OPEN_DOORS = "MONUSE_OPEN_DOORS",
    STARTING_EQUIPMENT = "MONUSE_STARTING_EQUIPMENT",
    WEAPONS_ARMOUR = "MONUSE_WEAPONS_ARMOUR",
}

return item_use
