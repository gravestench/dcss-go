-- An acquired item remembers the god that gave it. This source identity
-- belongs to the item instance and survives movement, pickup, and saves.
local component = require("constants.component")
local purpose = require("constants.item_generation_purpose")

local schema = {
    id = component.ITEM_PROVENANCE,
    version = 1,
    fields = {
        purpose = {
            type = "string",
            default = purpose.GOD_GIFT,
        },

        god_id = {
            type = "string",
            default = "",
        },
    },
}

register.component(schema)

return schema
