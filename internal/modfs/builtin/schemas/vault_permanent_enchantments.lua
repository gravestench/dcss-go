-- A vault actor owns the source enchantments that do not decay with AUT.
-- The ordinary status components still make combat, vision, and AI react.
local component = require("constants.component")

local schema = {
    id = component.VAULT_PERMANENT_ENCHANTMENTS,
    version = 1,
    fields = {
        active = {
            type = "map<string,bool>",
            default = {},
        },
    },
}

register.component(schema)

return schema
