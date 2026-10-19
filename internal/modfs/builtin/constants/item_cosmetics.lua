-- Cosmetic flags affect what the player sees before identification, not the item base kind.

-- Source: item-status-flag-type.h. These are physical appearance flags.
local cosmetics = {
    NONE = 0,
    GLOWING = 0x00010000,
    RUNED = 0x00020000,
    EMBROIDERED_SHINY = 0x00040000,
}

return cosmetics
