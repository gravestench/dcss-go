-- Elyvilon's saved amount affects both derived resource maxima. The
-- remaining clock belongs to the player and is aged by active turns.
local component = require("constants.component")

local schema = {
    id = component.ELYVILON_VIGOUR,
    version = 1,
    fields = {
        amount = {
            type = "int64",
            default = 0,
        },
        remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
