local component = require("constants.component")

local schema = {
    id = component.POWERED_BY_DEATH,
    version = 1,
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
