-- A pacified monster keeps a durable neutral side and a one-time XP
-- marker. Killing it later cannot award the same experience again.
local component = require("constants.component")

local schema = {
    id = component.ELYVILON_PACIFIED,
    version = 1,
    fields = {
        pacified = {
            type = "bool",
            default = false,
        },
    },
}

register.component(schema)

return schema
