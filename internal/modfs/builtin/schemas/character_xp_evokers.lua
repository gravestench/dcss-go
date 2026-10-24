-- XP evokers share charges by item subtype, even when the player carries
-- multiple copies. The debt therefore belongs to the player, not an item.
local component = require("constants.component")

local schema = {
    id = component.XP_EVOKERS,
    version = 1,
    fields = {
        debt = {
            type = "map<string,int64>",
        },
    },
}

register.component(schema)

return schema
