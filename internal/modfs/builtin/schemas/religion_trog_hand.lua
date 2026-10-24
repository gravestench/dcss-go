-- Trog's Hand has one durable clock shared by player regeneration,
-- willpower, expiration, and departure cleanup.
local component = require("constants.component")

local schema = {
    id = component.RELIGION_TROG_HAND,
    version = 1,
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
