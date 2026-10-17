local component = require("constants.component")

local schema = {
    id = component.PLAYER_SLEEP,
    version = 1,
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
        immunity_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
