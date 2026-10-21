-- A source DES item mimic is an illusion of the authored item, not a second
-- collectible copy. Presence of this marker controls pickup behavior while
-- the ordinary item kind supplies the appearance before discovery.
local component = require("constants.component")

local schema = {
    id = component.VAULT_ITEM_MIMIC,
    version = 1,
    fields = {
        active = {
            type = "bool",
            default = true,
        },
    },
}

register.component(schema)

return schema
