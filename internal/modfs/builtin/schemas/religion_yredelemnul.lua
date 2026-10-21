-- Source entry bonuses ask for friendly zombies rather than raw piety.
-- Keep the unfulfilled star target durable for the later soul owner.
local component = require("constants.component")

local schema = {
    id = component.RELIGION_YREDELEMNUL,
    version = 1,
    fields = {
        pending_bonus_stars = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
