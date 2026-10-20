local component = require("constants.component")

-- An authored vault item can keep a custom name and source tile choices
-- without turning every cosmetic variant into a new item catalog kind.
-- The ASCII client uses the name; a tiles client can read the saved IDs.
local schema = {
    id = component.VAULT_ITEM_APPEARANCE,
    version = 1,
    fields = {
        name = { type = "string", default = "" },
        tile = { type = "string", default = "" },
        weapon_tile = { type = "string", default = "" },
    },
}

register.component(schema)

return schema
