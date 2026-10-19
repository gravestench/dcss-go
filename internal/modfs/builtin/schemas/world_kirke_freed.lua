-- Restored hogs become good-neutral rather than resuming attacks against the
-- player. Keep that permanent attitude outside authored vault overrides,
-- which must still match the vault record during save validation.
local tactical = require("constants.monster_tactical")

local schema = {
    id = tactical.KIRKE_FREED,
    version = 1,
    fields = {
        freed = {
            type = "bool",
            default = true,
        },
        kind_id = {
            type = "string",
            default = "",
        },
        -- Later Polymorph changes the current kind but retains this original
        -- lineage; saves can still identify the freed monster without forcing
        -- it to remain in the same body forever.
        original_kind_id = {
            type = "string",
            default = "",
        },
    },
}

register.component(schema)

return schema
