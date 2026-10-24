-- Channel Magic is saved on the player because it continues across actions,
-- saves, and level changes. Its duration is measured in logical aut.
local component = require("constants.component")

local schema = {
    id = component.RELIGION_SIF_CHANNEL,
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
