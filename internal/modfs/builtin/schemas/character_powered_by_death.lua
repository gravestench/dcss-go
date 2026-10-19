local component = require("constants.component")

local schema = {
    id = component.POWERED_BY_DEATH,
    version = 1,
    -- Kill-driven strength stacks and their decay timer advance independently between player actions.
    fields = {
        strength = {
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
