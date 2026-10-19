-- The early gear picker draws only from these ordinary weapon IDs.

-- Weapon kinds selected by the ordinary early monster gear policy.
local items = require("ids.items")

local catalog = {
    items.WPN_DAGGER,
    items.WPN_CLUB,
    items.WPN_SHORT_SWORD,
    items.WPN_WHIP,
    items.WPN_SLING,
}

return catalog
