local component = require("constants.component")

local schema = {
    id = component.DEMONIC_GUARDIAN,
    version = 1,
    fields = {
        cooldown_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
